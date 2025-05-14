import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FormaScreen extends StatefulWidget {
  @override
  _FormaScreenState createState() => _FormaScreenState();
}

class _FormaScreenState extends State<FormaScreen> {
  List<Map<String, dynamic>> playersForma = [];
  Map<String, Map<String, List<int>>> playerPoints = {};

  @override
  void initState() {
    super.initState();
    _fetchPlayersForma();
  }

  Future<void> _fetchPlayersForma() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Obtener las ligas del usuario actual
      var leaguesSnapshot =
          await FirebaseFirestore.instance.collection('leagues').get();

      for (var league in leaguesSnapshot.docs) {
        var data = league.data();
        if (data['admin'] == user.uid ||
            (data['members'] ?? []).any(
              (member) => member['uid'] == user.uid,
            )) {
          // Obtener los partidos de la liga
          var matchesSnapshot =
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

          // Obtener las 5 fechas más recientes
          matchDates = matchDates.toSet().toList(); // Eliminar duplicados
          matchDates.sort(
            (a, b) => b.compareTo(a),
          ); // Ordenar por fecha descendente
          var lastFiveDates = matchDates.take(5).toList();

          // Agrupar por jugador y calcular la forma
          playerPoints = {};
          for (var player in players) {
            if (!playerPoints.containsKey(player['name'])) {
              playerPoints[player['name']] = {
                'totalPoints': List.filled(5, 0),
                'coachPoints': List.filled(5, 0),
              }; // Inicializar con 0
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

                // Pesos ajustados para dar más importancia a los partidos recientes
                List<int> weights = [5, 4, 3, 2, 1];

                // Calcular la media ponderada para totalPoints
                double weightedTotalPointsSum = 0;
                int totalWeight = 0;
                for (int i = 0; i < (lastFiveTotalPoints?.length ?? 0); i++) {
                  weightedTotalPointsSum +=
                      (lastFiveTotalPoints?[i] ?? 0) * weights[i];
                  totalWeight += weights[i];
                }
                double weightedTotalPointsAverage =
                    weightedTotalPointsSum / totalWeight;

                // Calcular la media ponderada para coachPoints
                double weightedCoachPointsSum = 0;
                for (int i = 0; i < (lastFiveCoachPoints?.length ?? 0); i++) {
                  weightedCoachPointsSum +=
                      (lastFiveCoachPoints?[i] ?? 0) * weights[i];
                }
                double weightedCoachPointsAverage =
                    weightedCoachPointsSum / totalWeight;

                // Calcular la media final combinada (70% coachPoints, 30% totalPoints)
                double finalAverage =
                    (weightedCoachPointsAverage * 0.7) +
                    (weightedTotalPointsAverage * 0.3);

                String forma = _classifyForma(finalAverage);

                return {
                  'name': entry.key,
                  'forma': forma,
                  'averagePoints': finalAverage,
                };
              }).toList();

          setState(() {
            playersForma = formaList;
          });

          break;
        }
      }
    } catch (e) {
      print('Error fetching players forma: $e');
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
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  String _classifyForma(double averagePoints) {
    if (averagePoints > 5) {
      return 'Muy buena';
    } else if (averagePoints >= 2.5) {
      return 'Buena';
    } else if (averagePoints >= 1) {
      return 'Normal';
    } else if (averagePoints > 0) {
      return 'Mala';
    } else {
      return 'Muy mala';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forma de los Jugadores'),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade50, Colors.blueGrey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          itemCount: playersForma.length,
          itemBuilder: (context, index) {
            var player = playersForma[index];
            var lastFivePoints =
                playerPoints[player['name']]?['totalPoints'] ?? [];
            Color arrowColor;

            // Determinar el color de la flecha según el promedio
            if (player['averagePoints'] > 5) {
              arrowColor = Colors.blue.shade600;
            } else if (player['averagePoints'] >= 2.5) {
              arrowColor = Colors.green.shade600;
            } else if (player['averagePoints'] >= 1) {
              arrowColor = Colors.yellow.shade600;
            } else if (player['averagePoints'] > 0) {
              arrowColor = Colors.orange.shade600;
            } else {
              arrowColor = Colors.red.shade600;
            }

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Columna izquierda: Nombre del jugador
                    Expanded(
                      flex: 1,
                      child: Text(
                        player['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Columna central: Puntuaciones de los últimos 5 partidos
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(lastFivePoints.length, (i) {
                          int point = lastFivePoints[i];
                          Color backgroundColor;

                          // Determinar el color del fondo según la puntuación específica
                          if (point < 0) {
                            backgroundColor =
                                Colors
                                    .red
                                    .shade600; // Puntuación negativa (intermedio)
                          } else if (point == 0) {
                            backgroundColor =
                                Colors
                                    .grey
                                    .shade300; // Puntuación igual a 0 (intermedio)
                          } else if (point > 0 && point <= 4) {
                            backgroundColor =
                                Colors
                                    .yellow
                                    .shade600; // Puntuación entre 1 y 4 (intermedio)
                          } else if (point >= 5 && point <= 9) {
                            backgroundColor =
                                Colors
                                    .green
                                    .shade600; // Puntuación entre 5 y 9 (intermedio)
                          } else {
                            backgroundColor =
                                Colors
                                    .blue
                                    .shade600; // Puntuación 10 o mayor (intermedio)
                          }

                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 2.0),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              point.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.bold, // Puntos en negrita
                                color:
                                    point == 0
                                        ? Colors.black
                                        : Colors.white, // Texto visible
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Columna derecha: Flecha con color y rotación
                    Expanded(
                      flex: 1,
                      child: Transform.rotate(
                        angle:
                            arrowColor == Colors.red.shade600
                                ? 90 *
                                    (3.14159265359 / 180) // -90º en radianes
                                : arrowColor == Colors.orange.shade600
                                ? 45 *
                                    (3.14159265359 / 180) // -45º en radianes
                                : arrowColor == Colors.yellow.shade600
                                ? 0 // 0º
                                : arrowColor == Colors.green.shade600
                                ? -45 *
                                    (3.14159265359 / 180) // 45º en radianes
                                : -90 *
                                    (3.14159265359 / 180), // 90º en radianes
                        child: Icon(Icons.double_arrow, color: arrowColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
