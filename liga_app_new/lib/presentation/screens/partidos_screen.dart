import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PartidosScreen extends StatefulWidget {
  @override
  _PartidosScreenState createState() => _PartidosScreenState();
}

class _PartidosScreenState extends State<PartidosScreen> {
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkUserAuthorization();
  }

  // Método que verifica si el usuario está autorizado, realiza llamadas a Firebase Authentication y Firestore.
  Future<void> _checkUserAuthorization() async {
    User? user =
        FirebaseAuth.instance.currentUser; // Llamada a Firebase Authentication.
    if (user == null) return;

    var leaguesSnapshot =
        await FirebaseFirestore.instance
            .collection('leagues')
            .get(); // Llamada a Firestore.
    for (var league in leaguesSnapshot.docs) {
      if (league['admin'] == user.uid) {
        setState(() {
          _isAuthorized = true;
        });
        return;
      }

      List<dynamic> members = league['members'] ?? [];
      for (var member in members) {
        if (member['uid'] == user.uid) {
          var roleField = member['role'];
          List<String> roles = [];

          if (roleField is String) {
            roles = [roleField];
          } else if (roleField is List) {
            roles = List<String>.from(roleField);
          } else {
            continue;
          }

          if (roles.contains('Delegado/Entrenador')) {
            setState(() {
              _isAuthorized = true;
            });
            return;
          }
        }
      }
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueGrey.shade900,
              onPrimary: Colors.white,
              surface: Colors.blueGrey.shade700,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.blueGrey.shade800,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueGrey.shade900,
              onPrimary: Colors.white,
              surface: Colors.blueGrey.shade700,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.blueGrey.shade800,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
            timePickerTheme: TimePickerThemeData(
              dialBackgroundColor: Colors.blueGrey.shade800,
              hourMinuteTextColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.blueGrey.shade900),
              ),
            ),
          ),
          child: child!,
        );
      },
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  // Método que obtiene los partidos, realiza llamadas a Firebase Authentication y Firestore.
  Future<List<Map<String, dynamic>>> _fetchMatches() async {
    User? user =
        FirebaseAuth.instance.currentUser; // Llamada a Firebase Authentication.
    if (user == null) return [];

    var leaguesSnapshot =
        await FirebaseFirestore.instance
            .collection('leagues')
            .get(); // Llamada a Firestore.
    for (var league in leaguesSnapshot.docs) {
      if (league['admin'] == user.uid ||
          (league['members'] ?? []).any(
            (member) => member['uid'] == user.uid,
          )) {
        var matchesSnapshot =
            await FirebaseFirestore.instance
                .collection('leagues')
                .doc(league.id)
                .collection('matches')
                .get(); // Llamada a Firestore.

        return matchesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'leagueName': league['name'],
            'opponent': data['opponent'],
            'matchDate': data['matchDate'],
            'matchTime': data['matchTime'],
            'matchLocation': data['matchLocation'],
            'callTime': data['callTime'],
            'callLocation': data['callLocation'],
            'porteros': data['porteros'] ?? [],
            'jugadores': data['jugadores'] ?? [],
            'jornada': data['jornada'],
            'resultado': data['resultado'],
          };
        }).toList();
      }
    }
    return [];
  }

  void _showMatchDialog(BuildContext context, {Map<String, dynamic>? match}) {
    final TextEditingController resultadoController = TextEditingController(
      text: match?['resultado'] ?? '',
    );
    final TextEditingController jornadaController = TextEditingController(
      text: match?['jornada'] ?? '',
    );
    final TextEditingController opponentController = TextEditingController(
      text: match?['opponent'] ?? '',
    );
    final TextEditingController matchDateController = TextEditingController(
      text: match?['matchDate'] ?? '',
    );
    final TextEditingController matchTimeController = TextEditingController(
      text: match?['matchTime'] ?? '',
    );
    final TextEditingController callTimeController = TextEditingController(
      text: match?['callTime'] ?? '',
    );
    final TextEditingController callLocationController = TextEditingController(
      text: match?['callLocation'] ?? '',
    );
    String matchLocation = match?['matchLocation'] ?? 'Casa';

    List<Map<String, dynamic>> porteros = [];
    List<Map<String, dynamic>> jugadores = [];
    Map<String, bool> convocados = {};

    // Método que obtiene los miembros de una liga, realiza llamadas a Firebase Authentication y Firestore.
    Future<void> _fetchMembers() async {
      User? user =
          FirebaseAuth
              .instance
              .currentUser; // Llamada a Firebase Authentication.
      if (user == null) return;

      var leaguesSnapshot =
          await FirebaseFirestore.instance
              .collection('leagues')
              .get(); // Llamada a Firestore.
      for (var league in leaguesSnapshot.docs) {
        if (league['admin'] == user.uid ||
            (league['members'] ?? []).any(
              (member) => member['uid'] == user.uid,
            )) {
          List<dynamic> members = league['members'] ?? [];
          for (var member in members) {
            if (member['role'] == 'Portero') {
              porteros.add(member);
            } else if (member['role'] == 'Jugador') {
              jugadores.add(member);
            }
          }
          break;
        }
      }

      for (var portero in porteros) {
        convocados[portero['uid']] = (match?['porteros'] ?? []).contains(
          portero['uid'],
        );
      }
      for (var jugador in jugadores) {
        convocados[jugador['uid']] = (match?['jugadores'] ?? []).contains(
          jugador['uid'],
        );
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder(
          future: _fetchMembers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
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
                        match == null ? 'Nuevo Partido' : 'Editar Partido',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Partido',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: jornadaController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'Número de la Jornada',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: opponentController,
                        decoration: InputDecoration(
                          hintText: 'Nombre del Rival',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: resultadoController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'Resultado del Partido',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onChanged: (value) {
                          if (!RegExp(r'^\d+-\d+$').hasMatch(value)) {
                            resultadoController.text = value.replaceAll(
                              RegExp(r'[^\d-]'),
                              '',
                            );
                            resultadoController
                                .selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: resultadoController.text.length,
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: matchDateController,
                        readOnly: true,
                        onTap: () => _selectDate(context, matchDateController),
                        decoration: InputDecoration(
                          hintText: 'Fecha del Partido',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: matchTimeController,
                        readOnly: true,
                        onTap: () => _selectTime(context, matchTimeController),
                        decoration: InputDecoration(
                          hintText: 'Hora del Partido',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      DefaultTabController(
                        length: 2,
                        initialIndex: matchLocation == 'Casa' ? 0 : 1,
                        child: Column(
                          children: [
                            TabBar(
                              onTap: (index) {
                                setState(() {
                                  matchLocation = index == 0 ? 'Casa' : 'Fuera';
                                });
                              },
                              tabs: [
                                Tab(
                                  icon: Icon(Icons.home, color: Colors.white),
                                ),
                                Tab(
                                  icon: Icon(
                                    Icons.airplanemode_active,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                              indicatorColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Convocatoria',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: callTimeController,
                        readOnly: true,
                        onTap: () => _selectTime(context, callTimeController),
                        decoration: InputDecoration(
                          hintText: 'Hora de la Convocatoria',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: callLocationController,
                        decoration: InputDecoration(
                          hintText: 'Lugar de la Convocatoria',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Convocados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Porteros',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      ...porteros.map(
                        (portero) => FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(portero['uid'])
                                  .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ListTile(
                                title: Text(
                                  'Cargando...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                            if (snapshot.hasError ||
                                !snapshot.hasData ||
                                snapshot.data == null) {
                              return ListTile(
                                title: Text(
                                  'Error al cargar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            final userName =
                                userData?['username'] ?? 'Sin nombre';
                            return ListTile(
                              title: Text(
                                userName,
                                style: TextStyle(color: Colors.white),
                              ),
                              trailing: StatefulBuilder(
                                builder: (context, setStateDialog) {
                                  return Checkbox(
                                    value: convocados[portero['uid']] ?? false,
                                    onChanged: (bool? value) {
                                      setStateDialog(() {
                                        convocados[portero['uid']] =
                                            value ?? false;
                                      });
                                    },
                                    checkColor: Colors.blueGrey.shade900,
                                    activeColor: Colors.white,
                                    side: BorderSide(color: Colors.white),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Jugadores',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      ...jugadores.map(
                        (jugador) => FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(jugador['uid'])
                                  .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ListTile(
                                title: Text(
                                  'Cargando...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                            if (snapshot.hasError ||
                                !snapshot.hasData ||
                                snapshot.data == null) {
                              return ListTile(
                                title: Text(
                                  'Error al cargar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            final userName =
                                userData?['username'] ?? 'Sin nombre';
                            return ListTile(
                              title: Text(
                                userName,
                                style: TextStyle(color: Colors.white),
                              ),
                              trailing: StatefulBuilder(
                                builder: (context, setStateDialog) {
                                  return Checkbox(
                                    value: convocados[jugador['uid']] ?? false,
                                    onChanged: (bool? value) {
                                      setStateDialog(() {
                                        convocados[jugador['uid']] =
                                            value ?? false;
                                      });
                                    },
                                    checkColor: Colors.blueGrey.shade900,
                                    activeColor: Colors.white,
                                    side: BorderSide(color: Colors.white),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            // Llamadas a Firebase Firestore para agregar o actualizar un partido.
                            onPressed: () async {
                              User? user =
                                  FirebaseAuth
                                      .instance
                                      .currentUser; // Llamada a Firebase Authentication.
                              if (user == null) return;

                              var leaguesSnapshot =
                                  await FirebaseFirestore.instance
                                      .collection('leagues')
                                      .get(); // Llamada a Firestore.
                              for (var league in leaguesSnapshot.docs) {
                                if (league['admin'] == user.uid ||
                                    (league['members'] ?? []).any(
                                      (member) => member['uid'] == user.uid,
                                    )) {
                                  List<String> selectedPorteros = [];
                                  List<String> selectedJugadores = [];

                                  convocados.forEach((uid, isSelected) {
                                    if (isSelected) {
                                      final member = porteros.firstWhere(
                                        (p) => p['uid'] == uid,
                                        orElse:
                                            () => jugadores.firstWhere(
                                              (j) => j['uid'] == uid,
                                              orElse: () => {},
                                            ),
                                      );
                                      if (member['role'] == 'Portero') {
                                        selectedPorteros.add(uid);
                                      } else if (member['role'] == 'Jugador') {
                                        selectedJugadores.add(uid);
                                      }
                                    }
                                  });

                                  if (resultadoController.text.trim().isEmpty) {
                                    resultadoController.text = '0-0';
                                  }

                                  if (match == null) {
                                    await FirebaseFirestore.instance
                                        .collection('leagues')
                                        .doc(league.id)
                                        .collection('matches')
                                        .add({
                                          'resultado': resultadoController.text,
                                          'jornada': jornadaController.text,
                                          'opponent': opponentController.text,
                                          'matchDate': matchDateController.text,
                                          'matchTime': matchTimeController.text,
                                          'matchLocation': matchLocation,
                                          'callTime': callTimeController.text,
                                          'callLocation':
                                              callLocationController.text,
                                          'porteros': selectedPorteros,
                                          'jugadores': selectedJugadores,
                                        }); // Llamada a Firestore.
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('leagues')
                                        .doc(league.id)
                                        .collection('matches')
                                        .doc(match['id'])
                                        .update({
                                          'resultado': resultadoController.text,
                                          'jornada': jornadaController.text,
                                          'opponent': opponentController.text,
                                          'matchDate': matchDateController.text,
                                          'matchTime': matchTimeController.text,
                                          'matchLocation': matchLocation,
                                          'callTime': callTimeController.text,
                                          'callLocation':
                                              callLocationController.text,
                                          'porteros': selectedPorteros,
                                          'jugadores': selectedJugadores,
                                        }); // Llamada a Firestore.
                                  }
                                  break;
                                }
                              }
                              Navigator.of(context).pop();
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
                            child: Text('Guardar'),
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

  DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      final formatter = DateFormat('dd/M/yyyy');
      return formatter.parse(dateStr);
    } catch (e) {
      print('Error al parsear la fecha: $dateStr - $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.blueGrey.shade100,
        child: Column(
          children: [
            Card(
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              shadowColor: Colors.black.withOpacity(0.3),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.shade900,
                      Colors.blueGrey.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FutureBuilder(
                  future: _fetchMatches(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Center(
                        child: Text(
                          'No hay partidos programados',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    DateTime? parseDate(String? dateStr) {
                      if (dateStr == null || dateStr.isEmpty) return null;

                      try {
                        List<String> parts = dateStr.split('/');
                        if (parts.length == 3) {
                          String day = parts[0].padLeft(2, '0');
                          String month = parts[1].padLeft(2, '0');
                          String year = parts[2];

                          return DateTime.parse("$year-$month-$day");
                        }
                      } catch (e) {
                        print("Error al parsear la fecha: $dateStr - $e");
                      }
                      return null;
                    }

                    final matches =
                        (snapshot.data as List<Map<String, dynamic>>)
                          ..sort((a, b) {
                            DateTime? dateA = parseDate(a['matchDate']);
                            DateTime? dateB = parseDate(b['matchDate']);
                            if (dateA == null && dateB == null) return 0;
                            if (dateA == null) return 1;
                            if (dateB == null) return -1;
                            return dateA.compareTo(dateB);
                          });

                    final now = DateTime.now();
                    final upcomingMatches =
                        matches.where((match) {
                          DateTime? matchDate = parseDate(match['matchDate']);
                          return matchDate != null && matchDate.isAfter(now);
                        }).toList();

                    final pastMatches =
                        matches.where((match) {
                          DateTime? matchDate = parseDate(match['matchDate']);
                          return matchDate != null && matchDate.isBefore(now);
                        }).toList();

                    if (upcomingMatches.isEmpty && pastMatches.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay partidos programados',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    final nextMatch =
                        upcomingMatches.isNotEmpty
                            ? upcomingMatches.first
                            : pastMatches.last;

                    final isUpcoming = upcomingMatches.isNotEmpty;

                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
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
                                padding: EdgeInsets.all(16),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nextMatch['matchLocation'] == 'Casa'
                                            ? "${nextMatch['leagueName']} vs ${nextMatch['opponent']}"
                                            : "${nextMatch['opponent']} vs ${nextMatch['leagueName']}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Detalles del Partido',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "Fecha: ${nextMatch['matchDate']}",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "Hora: ${nextMatch['matchTime']}",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Convocatoria',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "Hora: ${nextMatch['callTime']}",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "Lugar: ${nextMatch['callLocation']}",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Convocados',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Porteros:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      ...List<Widget>.from(
                                        (nextMatch['porteros'] as List<dynamic>)
                                            .map(
                                              (porteroId) => FutureBuilder<
                                                DocumentSnapshot
                                              >(
                                                future:
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(porteroId)
                                                        .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return Text(
                                                      "Cargando...",
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    );
                                                  }
                                                  if (snapshot.hasError ||
                                                      !snapshot.hasData ||
                                                      snapshot.data == null) {
                                                    return Text(
                                                      "Error al cargar",
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    );
                                                  }
                                                  final userData =
                                                      snapshot.data!.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >?;
                                                  final userName =
                                                      userData?['username'] ??
                                                      'Sin nombre';
                                                  return Text(
                                                    userName,
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Jugadores:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      ...List<Widget>.from(
                                        (nextMatch['jugadores']
                                                as List<dynamic>)
                                            .map(
                                              (jugadorId) => FutureBuilder<
                                                DocumentSnapshot
                                              >(
                                                future:
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(jugadorId)
                                                        .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return Text(
                                                      "Cargando...",
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    );
                                                  }
                                                  if (snapshot.hasError ||
                                                      !snapshot.hasData ||
                                                      snapshot.data == null) {
                                                    return Text(
                                                      "Error al cargar",
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    );
                                                  }
                                                  final userData =
                                                      snapshot.data!.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >?;
                                                  final userName =
                                                      userData?['username'] ??
                                                      'Sin nombre';
                                                  return Text(
                                                    userName,
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isUpcoming ? 'PRÓXIMO PARTIDO' : 'ÚLTIMO PARTIDO',
                            style: TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 110,
                                      height: 100,
                                      margin: EdgeInsets.only(
                                        left: 16,
                                        bottom: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          nextMatch['matchLocation'] == 'Casa'
                                              ? nextMatch['leagueName']
                                              : nextMatch['opponent'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      if (!isUpcoming)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            "Jornada ${nextMatch['jornada'] ?? 'N/A'}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      if (!isUpcoming) SizedBox(height: 8),
                                      if (isUpcoming) ...[
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            "${nextMatch['matchDate'] ?? 'N/A'}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            "${nextMatch['matchTime'] ?? 'N/A'}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                nextMatch['resultado']?.split(
                                                      '-',
                                                    )[0] ??
                                                    '0',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                nextMatch['resultado']?.split(
                                                      '-',
                                                    )[1] ??
                                                    '0',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 110,
                                      height: 100,
                                      margin: EdgeInsets.only(
                                        right: 16,
                                        bottom: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          nextMatch['matchLocation'] == 'Casa'
                                              ? nextMatch['opponent']
                                              : nextMatch['leagueName'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.blueGrey.shade100,
                child: Column(
                  children: [
                    Expanded(
                      child: FutureBuilder(
                        future: _fetchMatches(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data == null) {
                            return Center(
                              child: Text(
                                'Error al cargar los partidos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          }

                          final matches =
                              (snapshot.data as List<Map<String, dynamic>>)
                                ..sort((a, b) {
                                  DateTime? dateA = parseDate(a['matchDate']);
                                  DateTime? dateB = parseDate(b['matchDate']);
                                  if (dateA == null && dateB == null) return 0;
                                  if (dateA == null) return 1;
                                  if (dateB == null) return -1;
                                  return dateB.compareTo(dateA);
                                });

                          return ListView.builder(
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final match = matches[index];
                              return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 6,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blueGrey.shade900,
                                        Colors.blueGrey.shade600,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: ExpansionTile(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                match['matchLocation'] == 'Casa'
                                                    ? match['leagueName']
                                                    : match['opponent'],
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                match['matchLocation'] == 'Casa'
                                                    ? match['opponent']
                                                    : match['leagueName'],
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Column(
                                          children: [
                                            Container(
                                              width:
                                                  28, // Ajusta el ancho si es necesario
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  match['resultado']?.split(
                                                        '-',
                                                      )[0] ??
                                                      '0',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  match['resultado']?.split(
                                                        '-',
                                                      )[1] ??
                                                      '0',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    children: [
                                      Divider(color: Colors.white54),

                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              match['jornada']?.isNotEmpty ==
                                                      true
                                                  ? "Jornada ${match['jornada']}"
                                                  : 'Jornada no especificada',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Partido',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  color: Colors.white70,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Fecha: ${match['matchDate']}",
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  color: Colors.white70,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Hora: ${match['matchTime']}",
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16),

                                            Text(
                                              'Convocatoria',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  color: Colors.white70,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Hora: ${match['callTime']}",
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  color: Colors.white70,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Lugar: ${match['callLocation']}",
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16),

                                            Text(
                                              'Convocados',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Porteros:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            ...List<Widget>.from(
                                              (match['porteros'] as List<dynamic>).map(
                                                (porteroId) => FutureBuilder<
                                                  DocumentSnapshot
                                                >(
                                                  future:
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(porteroId)
                                                          .get(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .sports_handball,
                                                            color:
                                                                Colors.white70,
                                                            size: 16,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            "Cargando...",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white70,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                    if (snapshot.hasError ||
                                                        !snapshot.hasData ||
                                                        snapshot.data == null) {
                                                      return Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .sports_handball,
                                                            color:
                                                                Colors.white70,
                                                            size: 16,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            "Error al cargar",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white70,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                    final userData =
                                                        snapshot.data!.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >?;
                                                    final userName =
                                                        userData?['username'] ??
                                                        'Sin nombre';
                                                    return Row(
                                                      children: [
                                                        Icon(
                                                          Icons.sports_handball,
                                                          color: Colors.white70,
                                                          size: 16,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          userName,
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Jugadores:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            ...List<Widget>.from(
                                              (match['jugadores'] as List<dynamic>).map(
                                                (jugadorId) => FutureBuilder<
                                                  DocumentSnapshot
                                                >(
                                                  future:
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(jugadorId)
                                                          .get(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .directions_run,
                                                            color:
                                                                Colors.white70,
                                                            size: 16,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            "Cargando...",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white70,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                    if (snapshot.hasError ||
                                                        !snapshot.hasData ||
                                                        snapshot.data == null) {
                                                      return Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .directions_run,
                                                            color:
                                                                Colors.white70,
                                                            size: 16,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            "Error al cargar",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white70,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                    final userData =
                                                        snapshot.data!.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >?;
                                                    final userName =
                                                        userData?['username'] ??
                                                        'Sin nombre';
                                                    return Row(
                                                      children: [
                                                        Icon(
                                                          Icons.directions_run,
                                                          color: Colors.white70,
                                                          size: 16,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          userName,
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    _showMatchDialog(
                                                      context,
                                                      match: match,
                                                    );
                                                  },
                                                  icon: Icon(
                                                    Icons.edit,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                  label: Text(
                                                    'Editar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors
                                                            .blueGrey
                                                            .shade700,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    minimumSize: Size(0, 0),
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                ElevatedButton.icon(
                                                  // Llamada a Firebase Firestore para eliminar un partido.
                                                  onPressed: () async {
                                                    User? user =
                                                        FirebaseAuth
                                                            .instance
                                                            .currentUser; // Llamada a Firebase Authentication.
                                                    if (user == null) return;

                                                    var leaguesSnapshot =
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'leagues',
                                                            )
                                                            .get(); // Llamada a Firestore.
                                                    for (var league
                                                        in leaguesSnapshot
                                                            .docs) {
                                                      if (league['admin'] ==
                                                              user.uid ||
                                                          (league['members'] ??
                                                                  [])
                                                              .any(
                                                                (member) =>
                                                                    member['uid'] ==
                                                                    user.uid,
                                                              )) {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'leagues',
                                                            )
                                                            .doc(league.id)
                                                            .collection(
                                                              'matches',
                                                            )
                                                            .doc(match['id'])
                                                            .delete(); // Llamada a Firestore.
                                                        break;
                                                      }
                                                    }
                                                    Navigator.of(context).pop();
                                                  },
                                                  icon: Icon(
                                                    Icons.delete,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                  label: Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    minimumSize: Size(0, 0),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _isAuthorized
              ? FloatingActionButton(
                onPressed: () => _showMatchDialog(context),
                child: Icon(Icons.add, color: Colors.white),
                backgroundColor: Colors.blueGrey.shade900,
              )
              : null,
    );
  }
}
