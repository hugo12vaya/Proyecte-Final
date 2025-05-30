// Importació de paquets necessaris per a la pantalla
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pantalla principal per mostrar la forma dels jugadors
class FormaScreen extends StatefulWidget {
  @override
  _FormaScreenState createState() => _FormaScreenState();
}

class _FormaScreenState extends State<FormaScreen> {
  // Llista de jugadors amb la seva forma calculada
  List<Map<String, dynamic>> playersForma = [];
  // Diccionari amb els punts de cada jugador per partit
  Map<String, Map<String, List<int>>> playerPoints = {};

  @override
  void initState() {
    super.initState();
    _fetchPlayersForma(); // Carrega les dades al començar la pantalla
  }

  // Funció per obtenir i calcular la forma dels jugadors des de Firestore
  Future<void> _fetchPlayersForma() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Si no hi ha usuari autenticat, surt

    try {
      // Obté totes les lligues de la base de dades
      var leaguesSnapshot =
          await FirebaseFirestore.instance.collection('leagues').get();

      // Recorre cada lliga per veure si l'usuari hi participa
      for (var league in leaguesSnapshot.docs) {
        var data = league.data();
        // Comprova si l'usuari és admin o membre de la lliga
        if (data['admin'] == user.uid ||
            (data['members'] ?? []).any(
              (member) => member['uid'] == user.uid,
            )) {
          // Obté els partits de la lliga ordenats per data descendent
          var matchesSnapshot =
              await FirebaseFirestore.instance
                  .collection('leagues')
                  .doc(league.id)
                  .collection('matches')
                  .orderBy('matchDate', descending: true)
                  .get();

          List<Map<String, dynamic>> players =
              []; // Llista temporal de jugadors
          List<DateTime> matchDates = []; // Llista de dates dels partits

          // Recorre cada partit per recollir estadístiques
          for (var match in matchesSnapshot.docs) {
            var matchData = match.data();
            var estadisticas = matchData['estadisticas'] ?? {};
            var matchDate = _parseDate(matchData['matchDate']);

            if (matchDate != null) {
              matchDates.add(matchDate);
              // Afegeix les estadístiques de cada jugador d'aquest partit
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

          // Selecciona les 5 dates més recents (sense duplicats)
          matchDates = matchDates.toSet().toList();
          matchDates.sort((a, b) => b.compareTo(a));
          var lastFiveDates = matchDates.take(5).toList();

          // Inicialitza el diccionari de punts per jugador
          playerPoints = {};
          for (var player in players) {
            if (!playerPoints.containsKey(player['name'])) {
              playerPoints[player['name']] = {
                'totalPoints': List.filled(5, 0),
                'coachPoints': List.filled(5, 0),
              };
            }
            // Assigna els punts a la posició corresponent segons la data
            var dateIndex = lastFiveDates.indexOf(player['date']);
            if (dateIndex != -1) {
              playerPoints[player['name']]!['totalPoints']![dateIndex] =
                  player['totalPoints'];
              playerPoints[player['name']]!['coachPoints']![dateIndex] =
                  player['coachPoints'];
            }
          }

          // Calcula la forma de cada jugador amb mitjana ponderada
          List<Map<String, dynamic>> formaList =
              playerPoints.entries.map((entry) {
                var lastFiveTotalPoints = entry.value['totalPoints'];
                var lastFiveCoachPoints = entry.value['coachPoints'];

                // Pesos per donar més importància als partits recents
                List<int> weights = [5, 4, 3, 2, 1];

                // Calcula la mitjana ponderada de totalPoints
                double weightedTotalPointsSum = 0;
                int totalWeight = 0;
                for (int i = 0; i < (lastFiveTotalPoints?.length ?? 0); i++) {
                  weightedTotalPointsSum +=
                      (lastFiveTotalPoints?[i] ?? 0) * weights[i];
                  totalWeight += weights[i];
                }
                double weightedTotalPointsAverage =
                    weightedTotalPointsSum / totalWeight;

                // Calcula la mitjana ponderada de coachPoints
                double weightedCoachPointsSum = 0;
                for (int i = 0; i < (lastFiveCoachPoints?.length ?? 0); i++) {
                  weightedCoachPointsSum +=
                      (lastFiveCoachPoints?[i] ?? 0) * weights[i];
                }
                double weightedCoachPointsAverage =
                    weightedCoachPointsSum / totalWeight;

                // Calcula la mitjana final combinada (70% coachPoints, 30% totalPoints)
                double finalAverage =
                    (weightedCoachPointsAverage * 0.7) +
                    (weightedTotalPointsAverage * 0.3);

                // Classifica la forma segons la mitjana final
                String forma = _classifyForma(finalAverage);

                // Retorna el mapa amb el nom, la forma i la mitjana
                return {
                  'name': entry.key,
                  'forma': forma,
                  'averagePoints': finalAverage,
                };
              }).toList();

          // Actualitza l'estat amb la nova llista de formes
          setState(() {
            playersForma = formaList;
          });

          break; // Només carrega la primera lliga on l'usuari participa
        }
      }
    } catch (e) {
      print('Error fetching players forma: $e'); // Mostra error per consola
    }
  }

  // Converteix una data en format string (dd/MM/yyyy) a DateTime
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

  // Classifica la forma segons la mitjana de punts
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
    // Construcció de la interfície d'usuari
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forma de los Jugadores',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade50, Colors.blueGrey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Card fix a la part superior amb els títols de les columnes
            Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              color: Colors.blueGrey.shade900,
              child: Container(
                height: 40.0,
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Columna: Nom del jugador
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          'Nombre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Columna: Últims 5 partits
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'Últimos 5 partidos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Columna: Forma
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          'Forma',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Llista de jugadors amb la seva forma i punts
            Expanded(
              child: ListView.builder(
                itemCount: playersForma.length,
                itemBuilder: (context, index) {
                  var player = playersForma[index];
                  // Obté els punts dels últims 5 partits del jugador
                  var lastFivePoints =
                      playerPoints[player['name']]?['totalPoints'] ?? [];
                  Color arrowColor;

                  // Determina el color de la fletxa segons la mitjana de punts
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

                  // Card per cada jugador
                  return Card(
                    margin: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Columna esquerra: Nom i suma de punts
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Nom del jugador
                                  Text(
                                    player['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 4.0),
                                  // Suma de punts dels últims 5 partits
                                  Text(
                                    'Puntos: ${lastFivePoints.reduce((a, b) => a + b)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Columna central: Punts dels últims 5 partits (amb colors)
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(lastFivePoints.length, (
                                  i,
                                ) {
                                  int point = lastFivePoints[i];
                                  Color backgroundColor;

                                  // Determina el color del fons segons la puntuació
                                  if (point < 0) {
                                    backgroundColor = Colors.red.shade600;
                                  } else if (point == 0) {
                                    backgroundColor = Colors.grey.shade300;
                                  } else if (point > 0 && point <= 4) {
                                    backgroundColor = Colors.yellow.shade600;
                                  } else if (point >= 5 && point <= 9) {
                                    backgroundColor = Colors.green.shade600;
                                  } else {
                                    backgroundColor = Colors.blue.shade600;
                                  }

                                  // Mostra cada puntuació en una caixa de color
                                  return Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 2.0,
                                    ),
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
                                        fontWeight: FontWeight.bold,
                                        color:
                                            point == 0
                                                ? Colors.black
                                                : Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),

                          // Columna dreta: Fletxa amb color i rotació segons la forma
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Transform.rotate(
                                // Rotació de la fletxa segons la forma
                                angle:
                                    arrowColor == Colors.red.shade600
                                        ? 90 *
                                            (3.14159265359 / 180) // Cap avall
                                        : arrowColor == Colors.orange.shade600
                                        ? 45 *
                                            (3.14159265359 /
                                                180) // Diagonal avall
                                        : arrowColor == Colors.yellow.shade600
                                        ? 0 // Recte
                                        : arrowColor == Colors.green.shade600
                                        ? -45 *
                                            (3.14159265359 /
                                                180) // Diagonal amunt
                                        : -90 *
                                            (3.14159265359 / 180), // Cap amunt
                                child: Icon(
                                  Icons.double_arrow,
                                  color: arrowColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
