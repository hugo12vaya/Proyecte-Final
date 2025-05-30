import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InicioScreen extends StatefulWidget {
  const InicioScreen({Key? key}) : super(key: key);

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  List<Map<String, dynamic>> topScorers = [];
  List<Map<String, dynamic>> topAssists = [];
  List<Map<String, dynamic>> topForma = [];
  bool loading = true;

  // Cambia la lista de notificaciones para guardar texto y fecha
  List<Map<String, dynamic>> notifications = [];

  // Nueva lista para noticias
  List<Map<String, dynamic>> news = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _fetchNotifications();
    _fetchNews(); // Añadido para cargar noticias al iniciar
  }

  Future<void> _fetchAll() async {
    final scorers = await _fetchRankings('Gol');
    final assists = await _fetchRankings('Asistencia');
    final forma = await _fetchTopForma();

    setState(() {
      topScorers = scorers.take(5).toList();
      topAssists = assists.take(5).toList();
      topForma = forma.take(5).toList();
      loading = false;
    });
  }

  // Copiado/adaptado de rankings_screen.dart
  Future<List<Map<String, dynamic>>> _fetchRankings(String estadistica) async {
    try {
      // Obtener el mapa de username a valor
      final leaguesSnapshot =
          await FirebaseFirestore.instance.collection('leagues').get();
      Map<String, int> totalStatsMap = {};

      for (var league in leaguesSnapshot.docs) {
        final matchesSnapshot =
            await FirebaseFirestore.instance
                .collection('leagues')
                .doc(league.id)
                .collection('matches')
                .get();

        for (var match in matchesSnapshot.docs) {
          final data = match.data();
          final estadisticas = data['estadisticas'] ?? {};
          estadisticas.forEach((username, stats) {
            final valor = stats[estadistica];
            if (valor != null) {
              totalStatsMap[username] =
                  (totalStatsMap[username] ?? 0) + (valor as int);
            }
          });
        }
      }

      List<Map<String, dynamic>> jugadores =
          totalStatsMap.entries
              .map((entry) => {'name': entry.key, 'value': entry.value})
              .toList();

      jugadores.sort((a, b) => b['value'].compareTo(a['value']));
      return jugadores;
    } catch (e) {
      print('Error fetching rankings: $e');
      return [];
    }
  }

  // Copiado/adaptado de forma_screen.dart
  Future<List<Map<String, dynamic>>> _fetchTopForma() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final leaguesSnapshot =
          await FirebaseFirestore.instance.collection('leagues').get();

      for (var league in leaguesSnapshot.docs) {
        final data = league.data();
        if (data['admin'] == user.uid ||
            (data['members'] ?? []).any(
              (member) => member['uid'] == user.uid,
            )) {
          final matchesSnapshot =
              await FirebaseFirestore.instance
                  .collection('leagues')
                  .doc(league.id)
                  .collection('matches')
                  .orderBy('matchDate', descending: true)
                  .get();

          List<Map<String, dynamic>> players = [];
          List<DateTime> matchDates = [];

          for (var match in matchesSnapshot.docs) {
            var matchData = match.data();
            var estadisticas = matchData['estadisticas'] ?? {};
            var matchDate = _parseDate(matchData['matchDate']);

            if (matchDate != null) {
              matchDates.add(matchDate);
              estadisticas.forEach((playerName, stats) {
                var totalPoints = stats['totalPoints'] ?? 0;
                var coachPoints = stats['coachPoints'] ?? 0;
                players.add({
                  'name': playerName,
                  'totalPoints': totalPoints,
                  'coachPoints': coachPoints,
                  'date': matchDate,
                });
              });
            }
          }

          matchDates = matchDates.toSet().toList();
          matchDates.sort((a, b) => b.compareTo(a));
          var lastFiveDates = matchDates.take(5).toList();

          Map<String, Map<String, List<int>>> playerPoints = {};
          for (var player in players) {
            if (!playerPoints.containsKey(player['name'])) {
              playerPoints[player['name']] = {
                'totalPoints': List.filled(5, 0),
                'coachPoints': List.filled(5, 0),
              };
            }
            var dateIndex = lastFiveDates.indexOf(player['date']);
            if (dateIndex != -1) {
              playerPoints[player['name']]!['totalPoints']![dateIndex] =
                  player['totalPoints'];
              playerPoints[player['name']]!['coachPoints']![dateIndex] =
                  player['coachPoints'];
            }
          }

          List<Map<String, dynamic>> formaList =
              playerPoints.entries.map((entry) {
                var lastFiveTotalPoints = entry.value['totalPoints'];
                var lastFiveCoachPoints = entry.value['coachPoints'];
                List<int> weights = [5, 4, 3, 2, 1];

                double weightedTotalPointsSum = 0;
                int totalWeight = 0;
                for (int i = 0; i < (lastFiveTotalPoints?.length ?? 0); i++) {
                  weightedTotalPointsSum +=
                      (lastFiveTotalPoints?[i] ?? 0) * weights[i];
                  totalWeight += weights[i];
                }
                double weightedTotalPointsAverage =
                    weightedTotalPointsSum / totalWeight;

                double weightedCoachPointsSum = 0;
                for (int i = 0; i < (lastFiveCoachPoints?.length ?? 0); i++) {
                  weightedCoachPointsSum +=
                      (lastFiveCoachPoints?[i] ?? 0) * weights[i];
                }
                double weightedCoachPointsAverage =
                    weightedCoachPointsSum / totalWeight;

                double finalAverage =
                    (weightedCoachPointsAverage * 0.7) +
                    (weightedTotalPointsAverage * 0.3);

                return {'name': entry.key, 'value': finalAverage};
              }).toList();

          formaList.sort(
            (a, b) => (b['value'] as double).compareTo(a['value'] as double),
          );
          return formaList;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching forma: $e');
      return [];
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      var parts = dateStr.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  // Añade esta función para obtener color y ángulo de la flecha
  Map<String, dynamic> _getArrowStyle(double averagePoints) {
    Color arrowColor;
    double angle;

    if (averagePoints > 5) {
      arrowColor = Colors.blue.shade600;
      angle = -90 * (3.14159265359 / 180);
    } else if (averagePoints >= 2.5) {
      arrowColor = Colors.green.shade600;
      angle = -45 * (3.14159265359 / 180);
    } else if (averagePoints >= 1) {
      arrowColor = Colors.yellow.shade600;
      angle = 0;
    } else if (averagePoints > 0) {
      arrowColor = Colors.orange.shade600;
      angle = 45 * (3.14159265359 / 180);
    } else {
      arrowColor = Colors.red.shade600;
      angle = 90 * (3.14159265359 / 180);
    }
    return {'color': arrowColor, 'angle': angle};
  }

  Widget _buildNotificationCenter() {
    if (notifications.isEmpty) return SizedBox.shrink();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.15),
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.blueGrey.shade900,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'NOTIFICACIONES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    color: Colors.blueGrey.shade900,
                    letterSpacing: 0.5,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.blueGrey.shade900),
                  tooltip: 'Añadir notificación',
                  onPressed: _showAddNotificationDialog,
                ),
              ],
            ),
            Divider(
              thickness: 1.2,
              height: 20,
              color: Colors.blueGrey.shade100,
            ),
            // Aquí empieza el scroll
            Container(
              constraints: BoxConstraints(maxHeight: 350),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is OverscrollNotification) {
                    PrimaryScrollController.of(context).jumpTo(
                      PrimaryScrollController.of(context).offset +
                          notification.overscroll,
                    );
                  }
                  return false;
                },
                child: Scrollbar(
                  child: ListView(
                    physics: ClampingScrollPhysics(),
                    shrinkWrap: true,
                    children:
                        notifications.asMap().entries.map((entry) {
                          final notif = entry.value;
                          final date = notif['date'] as DateTime;
                          final formatted =
                              "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                          final username = notif['username'] ?? '';
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.blueGrey.shade100,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueGrey.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.notifications,
                                    color: Colors.amber.shade700,
                                    size: 22,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif['text'],
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey.shade900,
                                          letterSpacing: 0.1,
                                        ),
                                        maxLines: null,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "$formatted  —  $username",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blueGrey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(
    String title,
    List<Map<String, dynamic>> data, {
    bool isForma = false,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.15),
      color: Colors.blueGrey.shade50, // Cambiado para igualar todos los cards
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isForma
                      ? Icons.trending_up_rounded
                      : (title.contains('GOLEADORES')
                          ? Icons.sports_soccer_rounded
                          : Icons.assistant_rounded),
                  color: Colors.blueGrey.shade900,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    color: Colors.blueGrey.shade900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Divider(
              thickness: 1.2,
              height: 20,
              color: Colors.blueGrey.shade100,
            ),
            ...data.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    if (!isForma)
                      if (idx < 3)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color:
                                idx == 0
                                    ? Colors.amber.shade400
                                    : idx == 1
                                    ? Colors.grey.shade400
                                    : Colors.brown.shade300,
                            size: 22,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blueGrey.shade200,
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                color: Colors.blueGrey.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    Expanded(
                      child: Text(
                        item['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade900,
                          letterSpacing: 0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    isForma
                        ? Builder(
                          builder: (_) {
                            final style = _getArrowStyle(
                              item['value'] as double,
                            );
                            return Transform.rotate(
                              angle: style['angle'],
                              child: Icon(
                                Icons.double_arrow_rounded,
                                color: style['color'],
                                size: 18,
                              ),
                            );
                          },
                        )
                        : Text(
                          item['value'].toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Función para añadir una notificación en Firestore
  Future<void> _addNotification(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Obtener el nombre de usuario
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final username = userDoc.data()?['username'] ?? 'Sin nombre';

    // Buscar la liga del usuario
    final leaguesSnapshot =
        await FirebaseFirestore.instance.collection('leagues').get();
    String? leagueId;
    for (var league in leaguesSnapshot.docs) {
      final data = league.data();
      if (data['admin'] == user.uid ||
          (data['members'] ?? []).any((member) => member['uid'] == user.uid)) {
        leagueId = league.id;
        break;
      }
    }
    if (leagueId == null) return;

    final now = DateTime.now();

    // Guardar la notificación en la subcolección 'notifications' de la liga
    await FirebaseFirestore.instance
        .collection('leagues')
        .doc(leagueId)
        .collection('notifications')
        .add({'text': text, 'date': now, 'username': username});

    // Recargar notificaciones locales
    await _fetchNotifications();
  }

  // Obtener notificaciones de la liga desde Firestore
  Future<void> _fetchNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final leaguesSnapshot =
        await FirebaseFirestore.instance.collection('leagues').get();
    String? leagueId;
    for (var league in leaguesSnapshot.docs) {
      final data = league.data();
      if (data['admin'] == user.uid ||
          (data['members'] ?? []).any((member) => member['uid'] == user.uid)) {
        leagueId = league.id;
        break;
      }
    }
    if (leagueId == null) return;

    final notifSnapshot =
        await FirebaseFirestore.instance
            .collection('leagues')
            .doc(leagueId)
            .collection('notifications')
            .orderBy('date', descending: true)
            .get();

    setState(() {
      notifications =
          notifSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'text': data['text'] ?? '',
              'date': (data['date'] as Timestamp).toDate(),
              'username': data['username'] ?? '',
            };
          }).toList();
    });
  }

  // Diálogo para introducir una nueva notificación
  Future<void> _showAddNotificationDialog() async {
    String newNotification = '';
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nueva notificación',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Escribe la notificación',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onChanged: (value) => newNotification = value,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (newNotification.trim().isNotEmpty) {
                          await _addNotification(newNotification.trim());
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Añadir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Obtener noticias de la liga desde Firestore
  Future<void> _fetchNews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final leaguesSnapshot =
        await FirebaseFirestore.instance.collection('leagues').get();
    String? leagueId;
    for (var league in leaguesSnapshot.docs) {
      final data = league.data();
      if (data['admin'] == user.uid ||
          (data['members'] ?? []).any((member) => member['uid'] == user.uid)) {
        leagueId = league.id;
        break;
      }
    }
    if (leagueId == null) return;

    final newsSnapshot =
        await FirebaseFirestore.instance
            .collection('leagues')
            .doc(leagueId)
            .collection('news')
            .orderBy('date', descending: true)
            .get();

    setState(() {
      news =
          newsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'docId': doc.id, // <--- Añadido
              'title': data['title'] ?? '',
              'text': data['text'] ?? '',
              'imageUrl': data['imageUrl'] ?? '',
              'deletehash': data['deletehash'] ?? '', // <--- Añadido
              'date': (data['date'] as Timestamp).toDate(),
            };
          }).toList();
    });
  }

  // Añadir noticia a Firestore
  Future<void> _addNews(
    String title,
    String text,
    String imageUrl,
    String deleteHash,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final leaguesSnapshot =
        await FirebaseFirestore.instance.collection('leagues').get();
    String? leagueId;
    for (var league in leaguesSnapshot.docs) {
      final data = league.data();
      if (data['admin'] == user.uid ||
          (data['members'] ?? []).any((member) => member['uid'] == user.uid)) {
        leagueId = league.id;
        break;
      }
    }
    if (leagueId == null) return;

    final now = DateTime.now();

    await FirebaseFirestore.instance
        .collection('leagues')
        .doc(leagueId)
        .collection('news')
        .add({
          'title': title,
          'text': text,
          'imageUrl': imageUrl,
          'deletehash': deleteHash, // <-- Añadido aquí
          'date': now,
        });

    await _fetchNews();
  }

  // Diálogo para añadir noticia
  Future<void> _showAddNewsDialog() async {
    String title = '';
    String text = '';
    File? imageFile;
    final picker = ImagePicker();
    bool uploading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImage() async {
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null) {
                setState(() {
                  imageFile = File(picked.path);
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.shade900,
                      Colors.blueGrey.shade700,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nueva noticia',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Título',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onChanged: (value) => title = value,
                      ),
                      SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Texto',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        maxLines: 3,
                        onChanged: (value) => text = value,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: pickImage,
                            icon: Icon(Icons.image),
                            label: Text('Seleccionar imagen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                      if (imageFile != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              imageFile!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                      if (uploading)
                        CircularProgressIndicator()
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (title.trim().isNotEmpty &&
                                    text.trim().isNotEmpty) {
                                  setState(() => uploading = true);
                                  Map<String, String>? imgurData;
                                  if (imageFile != null) {
                                    imgurData = await uploadImageToImgur(
                                      imageFile!,
                                    );
                                    if (imgurData == null) {
                                      setState(() => uploading = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error subiendo la imagen a Imgur',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                  await _addNews(
                                    title.trim(),
                                    text.trim(),
                                    imgurData?['link'] ?? '',
                                    imgurData?['deletehash'] ?? '',
                                  );
                                  setState(() => uploading = false);
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text('Añadir'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.15),
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  color: Colors.blueGrey.shade900,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'NOTICIAS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 17,
                    color: Colors.blueGrey.shade900,
                    letterSpacing: 0.5,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.blueGrey.shade900),
                  tooltip: 'Añadir noticia',
                  onPressed: _showAddNewsDialog,
                ),
              ],
            ),
            Divider(
              thickness: 1.2,
              height: 20,
              color: Colors.blueGrey.shade100,
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: 800, // Aumenta la altura máxima del card de noticias
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is OverscrollNotification) {
                    PrimaryScrollController.of(context).jumpTo(
                      PrimaryScrollController.of(context).offset +
                          notification.overscroll,
                    );
                  }
                  return false;
                },
                child: Scrollbar(
                  child: ListView(
                    physics: ClampingScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      if (news.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'No hay noticias aún.',
                              style: TextStyle(
                                color: Colors.blueGrey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ...news.map((item) {
                        final date = item['date'] as DateTime;
                        final formatted =
                            "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                        return GestureDetector(
                          onLongPress: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('Eliminar noticia'),
                                    content: Text(
                                      '¿Seguro que quieres eliminar esta noticia?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: Text(
                                          'Eliminar',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                            if (shouldDelete == true) {
                              await _deleteNews(
                                item['docId'],
                                item['deletehash'],
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.blueGrey.shade100,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueGrey.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...(item['imageUrl'] as String).isNotEmpty
                                    ? [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          item['imageUrl'],
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                height: 160,
                                                color: Colors.blueGrey.shade100,
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color:
                                                      Colors.blueGrey.shade300,
                                                  size: 50,
                                                ),
                                              ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                    ]
                                    : [],
                                Text(
                                  item['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blueGrey.shade900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  item['text'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blueGrey.shade900,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    formatted,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>?> uploadImageToImgur(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('https://api.imgur.com/3/image'),
      headers: {'Authorization': 'Client-ID 7598ab18d2b8cd8'},
      body: {'image': base64Image, 'type': 'base64'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'link': data['data']['link'],
        'deletehash': data['data']['deletehash'],
      };
    }
    return null;
  }

  // Eliminar noticia de Firestore
  Future<void> _deleteNews(String docId, String? deleteHash) async {
    // Eliminar imagen de Imgur si hay deleteHash
    if (deleteHash != null && deleteHash.isNotEmpty) {
      await http.delete(
        Uri.parse('https://api.imgur.com/3/image/$deleteHash'),
        headers: {'Authorization': 'Client-ID 7598ab18d2b8cd8'},
      );
    }

    // Eliminar noticia de Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final leaguesSnapshot =
        await FirebaseFirestore.instance.collection('leagues').get();
    String? leagueId;
    for (var league in leaguesSnapshot.docs) {
      final data = league.data();
      if (data['admin'] == user.uid ||
          (data['members'] ?? []).any((member) => member['uid'] == user.uid)) {
        leagueId = league.id;
        break;
      }
    }
    if (leagueId == null) return;

    await FirebaseFirestore.instance
        .collection('leagues')
        .doc(leagueId)
        .collection('news')
        .doc(docId)
        .delete();

    await _fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade100,
      body:
          loading
              ? Center(child: CircularProgressIndicator())
              : SafeArea(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  children: [
                    _buildNewsSection(), // NUEVA SECCIÓN PRINCIPAL
                    _buildNotificationCenter(),
                    _buildTable('MÁXIMOS GOLEADORES', topScorers),
                    _buildTable('MÁXIMOS ASISTENTES', topAssists),
                    _buildTable('JUGADORES EN FORMA', topForma, isForma: true),
                  ],
                ),
              ),
    );
  }
}
