import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final Map<String, int> playerStats = {
  // Acciones ofensivas
  'Gol': 4,
  'Asistencia': 2,
  'Pase clave': 1,
  'Penalti provocado': 2,
  'Doble penalti provocado': 1,

  // Acciones negativas
  'Penalti fallado': -3,
  'Doble fallado': -1,
  'Autogol': -1,
  'Penalti cometido': -1,
  'Error de/en gol': -1,
  'Tarjeta amarilla innecesaria': -1,
  'Tarjeta roja': -3,

  //Impacto en el marcardor
  'Gol a favor': 2,
  'Gol en contra': -2,
  'Gol en contra (portero/jugador)': -1,

  //Entrenador
  'Puntos entrenador': 1,
};

final Map<String, int> goalkeeperStats = {
  // Acciones ofensivas
  'Gol': 8,
  'Asistencia': 4,
  'Pase clave': 1,
  'Penalti provocado': 2,
  'Doble penalti provocado': 1,

  // Acciones defensivas
  'Porteria a 0 (primera parte)': 5,
  'Porteria a 0 (segunda parte)': 5,
  'Gol encajado': -1,
  'Parar penalti': 4,
  'Parar doble penalti': 2,

  // Acciones negativas
  'Penalti fallado': -3,
  'Doble fallado': -1,
  'Autogol': -1,
  'Penalti cometido': -1,
  'Error de gol': -1,
  'Tarjeta amarilla innecesaria': -1,
  'Tarjeta roja': -3,

  //Entrenador
  'Puntos entrenador': 1,
};

class EstadisticasScreen extends StatefulWidget {
  @override
  _EstadisticasScreenState createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  String selectedJornada = '';
  List<String> jornadas = [];
  List<Map<String, dynamic>> jornadaParticipants = [];

  @override
  void initState() {
    super.initState();
    _fetchJornadas();
  }

  Future<void> _fetchJornadas() async {
    // Método que realiza múltiples llamadas a Firebase
    User? user = FirebaseAuth.instance.currentUser; // Firebase Auth
    if (user == null) return;

    try {
      var leaguesSnapshot =
          await FirebaseFirestore.instance
              .collection('leagues')
              .get(); // Firebase Firestore

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
                  .get(); // Firebase Firestore

          List<String> fetchedJornadas =
              matchesSnapshot.docs
                  .map((doc) => doc['jornada'].toString())
                  .toSet()
                  .toList();

          fetchedJornadas.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

          setState(() {
            jornadas = fetchedJornadas;
            if (jornadas.isNotEmpty) {
              selectedJornada = jornadas.first;
              _fetchJornadaParticipants(league.id, selectedJornada);
            }
          });
          break;
        }
      }
    } catch (e) {
      print('Error fetching jornadas: $e');
    }
  }

  Future<void> _fetchJornadaParticipants(
    String leagueId,
    String jornada,
  ) async {
    // Método que realiza múltiples llamadas a Firebase
    try {
      var matchesSnapshot =
          await FirebaseFirestore.instance
              .collection('leagues')
              .doc(leagueId)
              .collection('matches')
              .where('jornada', isEqualTo: jornada)
              .get(); // Firebase Firestore

      if (matchesSnapshot.docs.isNotEmpty) {
        var match = matchesSnapshot.docs.first;
        List<dynamic> jugadores = match['jugadores'] ?? [];
        List<dynamic> porteros = match['porteros'] ?? [];
        Map<String, dynamic> estadisticas =
            match.data().containsKey('estadisticas')
                ? match['estadisticas']
                : {};

        List<Map<String, dynamic>> participants = [];

        for (var jugadorId in jugadores) {
          var userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(jugadorId)
                  .get(); // Firebase Firestore

          if (userDoc.exists) {
            final username = userDoc.data()?['username'] ?? 'Sin nombre';
            final stats = estadisticas[username] ?? {};
            final totalPoints = stats['totalPoints'] ?? 0;

            participants.add({
              'username': username,
              'role': 'Jugador',
              'totalPoints': totalPoints,
            });
          }
        }

        for (var porteroId in porteros) {
          var userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(porteroId)
                  .get(); // Firebase Firestore

          if (userDoc.exists) {
            final username = userDoc.data()?['username'] ?? 'Sin nombre';
            final stats = estadisticas[username] ?? {};
            final totalPoints = stats['totalPoints'] ?? 0;

            participants.add({
              'username': username,
              'role': 'Portero',
              'totalPoints': totalPoints,
            });
          }
        }

        setState(() {
          jornadaParticipants = participants;
        });
      } else {
        setState(() {
          jornadaParticipants = [];
        });
      }
    } catch (e) {
      print('Error fetching participants for jornada $jornada: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ingresar Estadísticas',
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
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueGrey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: DropdownButton<String>(
                              value:
                                  selectedJornada.isNotEmpty
                                      ? selectedJornada
                                      : null,
                              onChanged: (value) {
                                setState(() {
                                  selectedJornada = value!;

                                  var user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    FirebaseFirestore.instance
                                        .collection('leagues')
                                        .get()
                                        .then((leaguesSnapshot) {
                                          for (var league
                                              in leaguesSnapshot.docs) {
                                            if (league['admin'] == user.uid ||
                                                (league['members'] ?? []).any(
                                                  (member) =>
                                                      member['uid'] == user.uid,
                                                )) {
                                              _fetchJornadaParticipants(
                                                league.id,
                                                selectedJornada,
                                              );
                                              break;
                                            }
                                          }
                                        });
                                  }
                                });
                              },
                              items:
                                  jornadas
                                      .map(
                                        (jornada) => DropdownMenuItem(
                                          value: jornada,
                                          child: Text('Jornada $jornada'),
                                        ),
                                      )
                                      .toList(),
                              underline: SizedBox(),
                              style: TextStyle(color: Colors.blueGrey.shade900),
                              dropdownColor: Colors.blueGrey.shade50,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.blueGrey.shade900,
                              ),
                              isExpanded: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: jornadaParticipants.length,
                itemBuilder: (context, index) {
                  final participant = jornadaParticipants[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueGrey.shade900,
                            Colors.blueGrey.shade600,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        title: Text(
                          participant['username'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          participant['role'] ?? '',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          '${participant['totalPoints'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            print('Usuario no autenticado');
                            return;
                          }

                          try {
                            final leaguesSnapshot =
                                await FirebaseFirestore.instance
                                    .collection('leagues')
                                    .get();

                            for (var league in leaguesSnapshot.docs) {
                              if (league['admin'] == user.uid ||
                                  (league['members'] ?? []).any(
                                    (member) => member['uid'] == user.uid,
                                  )) {
                                final matchesSnapshot =
                                    await FirebaseFirestore.instance
                                        .collection('leagues')
                                        .doc(league.id)
                                        .collection('matches')
                                        .where(
                                          'jornada',
                                          isEqualTo: selectedJornada,
                                        )
                                        .get();

                                if (matchesSnapshot.docs.isNotEmpty) {
                                  final matchDoc = matchesSnapshot.docs.first;

                                  final savedStats =
                                      matchDoc
                                          .data()['estadisticas']?[participant['username']] ??
                                      {};

                                  final Map<String, TextEditingController>
                                  controllers = {
                                    for (var key
                                        in (participant['role'] == 'Portero'
                                                ? goalkeeperStats
                                                : playerStats)
                                            .keys)
                                      key: TextEditingController(
                                        text:
                                            savedStats[key]?.toString() ?? '0',
                                      ),
                                  };

                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      final isGoalkeeper =
                                          participant['role'] == 'Portero';
                                      final stats =
                                          isGoalkeeper
                                              ? goalkeeperStats
                                              : playerStats;

                                      final Map<
                                        String,
                                        List<MapEntry<String, int>>
                                      >
                                      categorizedStats = {
                                        'Acciones ofensivas':
                                            stats.entries
                                                .where(
                                                  (entry) => [
                                                    'Gol',
                                                    'Asistencia',
                                                    'Pase clave',
                                                    'Penalti provocado',
                                                    'Doble penalti provocado',
                                                  ].contains(entry.key),
                                                )
                                                .toList(),
                                        if (isGoalkeeper)
                                          'Acciones defensivas':
                                              stats.entries
                                                  .where(
                                                    (entry) => [
                                                      'Porteria a 0 (primera parte)',
                                                      'Porteria a 0 (segunda parte)',
                                                      'Gol encajado',
                                                      'Parar penalti',
                                                      'Parar doble penalti',
                                                    ].contains(entry.key),
                                                  )
                                                  .toList(),
                                        'Acciones negativas':
                                            stats.entries
                                                .where(
                                                  (entry) => [
                                                    'Penalti fallado',
                                                    'Doble fallado',
                                                    'Autogol',
                                                    'Penalti cometido',
                                                    'Error de gol',
                                                    'Error de/en gol',
                                                    'Tarjeta amarilla innecesaria',
                                                    'Tarjeta roja',
                                                  ].contains(entry.key),
                                                )
                                                .toList(),
                                        if (!isGoalkeeper)
                                          'Impacto en el marcador':
                                              stats.entries
                                                  .where(
                                                    (entry) => [
                                                      'Gol a favor',
                                                      'Gol en contra',
                                                      'Gol en contra (portero/jugador)',
                                                    ].contains(entry.key),
                                                  )
                                                  .toList(),
                                        'Entrenador':
                                            stats.entries
                                                .where(
                                                  (entry) => [
                                                    'Puntos entrenador',
                                                  ].contains(entry.key),
                                                )
                                                .toList(),
                                      };

                                      return StatefulBuilder(
                                        builder: (context, setDialogState) {
                                          int calculateTotalPoints() {
                                            return stats.entries.fold(0, (
                                              total,
                                              entry,
                                            ) {
                                              final count =
                                                  int.tryParse(
                                                    controllers[entry.key]!
                                                        .text,
                                                  ) ??
                                                  0;
                                              return total +
                                                  (count * entry.value);
                                            });
                                          }

                                          int totalPoints =
                                              calculateTotalPoints();

                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
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
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.all(
                                                16.0,
                                              ),
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.bar_chart,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            'Estadísticas de ${participant['username']}',
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 16),
                                                    ...categorizedStats.entries.map((
                                                      category,
                                                    ) {
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 8.0,
                                                                ),
                                                            child: Text(
                                                              category.key,
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                          ),
                                                          Table(
                                                            columnWidths: {
                                                              0: FixedColumnWidth(
                                                                80.0,
                                                              ),
                                                              1: FlexColumnWidth(
                                                                3,
                                                              ),
                                                              2: FixedColumnWidth(
                                                                80.0,
                                                              ),
                                                            },
                                                            border: TableBorder(
                                                              horizontalInside:
                                                                  BorderSide(
                                                                    color:
                                                                        Colors
                                                                            .white54,
                                                                    width: 1,
                                                                  ),
                                                            ),
                                                            children:
                                                                category.value.map((
                                                                  entry,
                                                                ) {
                                                                  final controller =
                                                                      controllers[entry
                                                                          .key]!;
                                                                  return TableRow(
                                                                    children: [
                                                                      TableCell(
                                                                        verticalAlignment:
                                                                            TableCellVerticalAlignment.middle,
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.all(
                                                                            8.0,
                                                                          ),
                                                                          child: TextField(
                                                                            controller:
                                                                                controller,
                                                                            keyboardType:
                                                                                TextInputType.number,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            decoration: InputDecoration(
                                                                              filled:
                                                                                  true,
                                                                              fillColor:
                                                                                  Colors.white,
                                                                              border: OutlineInputBorder(
                                                                                borderRadius: BorderRadius.circular(
                                                                                  8.0,
                                                                                ),
                                                                              ),
                                                                              contentPadding: EdgeInsets.symmetric(
                                                                                vertical:
                                                                                    8.0,
                                                                                horizontal:
                                                                                    4.0,
                                                                              ),
                                                                              hintText:
                                                                                  '0',
                                                                            ),
                                                                            onChanged: (
                                                                              value,
                                                                            ) async {
                                                                              setDialogState(
                                                                                () {
                                                                                  totalPoints =
                                                                                      calculateTotalPoints();
                                                                                },
                                                                              );

                                                                              final updatedStats = {
                                                                                for (var key in controllers.keys)
                                                                                  key:
                                                                                      int.tryParse(
                                                                                        controllers[key]!.text,
                                                                                      ) ??
                                                                                      0,
                                                                                'totalPoints':
                                                                                    totalPoints,
                                                                              };

                                                                              try {
                                                                                await FirebaseFirestore.instance
                                                                                    .collection(
                                                                                      'leagues',
                                                                                    )
                                                                                    .doc(
                                                                                      league.id,
                                                                                    )
                                                                                    .collection(
                                                                                      'matches',
                                                                                    )
                                                                                    .doc(
                                                                                      matchDoc.id,
                                                                                    )
                                                                                    .update(
                                                                                      {
                                                                                        'estadisticas.${participant['username']}':
                                                                                            updatedStats,
                                                                                      },
                                                                                    );

                                                                                setState(
                                                                                  () {
                                                                                    final index = jornadaParticipants.indexWhere(
                                                                                      (
                                                                                        p,
                                                                                      ) =>
                                                                                          p['username'] ==
                                                                                          participant['username'],
                                                                                    );
                                                                                    if (index !=
                                                                                        -1) {
                                                                                      jornadaParticipants[index] = {
                                                                                        ...jornadaParticipants[index],
                                                                                        'totalPoints':
                                                                                            totalPoints,
                                                                                      };
                                                                                    }
                                                                                  },
                                                                                );
                                                                              } catch (
                                                                                e
                                                                              ) {
                                                                                print(
                                                                                  'Error al guardar estadísticas automáticamente: $e',
                                                                                );
                                                                              }
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      TableCell(
                                                                        verticalAlignment:
                                                                            TableCellVerticalAlignment.middle,
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.all(
                                                                            8.0,
                                                                          ),
                                                                          child: Text(
                                                                            entry.key,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style: TextStyle(
                                                                              color:
                                                                                  Colors.white70,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      TableCell(
                                                                        verticalAlignment:
                                                                            TableCellVerticalAlignment.middle,
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.all(
                                                                            8.0,
                                                                          ),
                                                                          child: Text(
                                                                            (() {
                                                                              final count =
                                                                                  int.tryParse(
                                                                                    controller.text,
                                                                                  ) ??
                                                                                  0;
                                                                              final points =
                                                                                  count *
                                                                                  entry.value;
                                                                              return points.toString();
                                                                            })(),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style: TextStyle(
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                              color:
                                                                                  Colors.white,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  );
                                                                }).toList(),
                                                          ),
                                                        ],
                                                      );
                                                    }).toList(),
                                                    SizedBox(height: 16),
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
                                break;
                              }
                            }
                          } catch (e) {
                            print('Error al obtener estadísticas: $e');
                          }
                        },
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
