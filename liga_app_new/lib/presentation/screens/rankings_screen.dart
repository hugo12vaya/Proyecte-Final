import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RankingsScreen extends StatefulWidget {
  @override
  _RankingsScreenState createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen>
    with SingleTickerProviderStateMixin {
  bool isJugadoresSelected = true;
  late TabController _tabController;

  final List<String> estadisticas = [
    'Gol',
    'Asistencia',
    'Pase clave',
    'Error de/en gol',
    'Tarjeta amarilla innecesaria',
    'Tarjeta roja',
    'Gol a favor',
    'Gol en contra',
    'Gol en contra (portero/jugador)',
    'Puntos entrenador',
  ];

  final List<String> estadisticasPorteros = [
    'Porteria a 0 (primera parte)',
    'Porteria a 0 (segunda parte)',
    'Gol encajado',
    'Parar penalti',
    'Parar doble penalti',
  ];

  Map<String, List<Map<String, dynamic>>> _rankingsCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: estadisticas.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Método que obtiene el mapa de IDs de usuario a nombres de usuario, realiza una llamada a Firebase Firestore.
  Future<Map<String, String>> _fetchIdToUsernameMap() async {
    final usersSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .get(); // Llamada a Firestore.

    Map<String, String> idToUsername = {};
    for (var doc in usersSnapshot.docs) {
      final username = doc.data()['username'];
      if (username != null) {
        idToUsername[doc.id] = username;
      }
    }
    return idToUsername;
  }

  // Método que obtiene los rankings de una estadística, realiza múltiples llamadas a Firebase Firestore.
  Future<List<Map<String, dynamic>>> _fetchRankings(String estadistica) async {
    if (_rankingsCache.containsKey(estadistica)) {
      return _rankingsCache[estadistica]!;
    }

    try {
      final idToUsername =
          await _fetchIdToUsernameMap(); // Llamada a Firestore desde otro método.

      final leaguesSnapshot =
          await FirebaseFirestore.instance
              .collection('leagues')
              .get(); // Llamada a Firestore.

      Map<String, int> totalStatsMap = {};
      Map<String, int> convocatoriasMap = {};

      for (var league in leaguesSnapshot.docs) {
        final matchesSnapshot =
            await FirebaseFirestore.instance
                .collection('leagues')
                .doc(league.id)
                .collection('matches')
                .get(); // Llamada a Firestore.

        for (var match in matchesSnapshot.docs) {
          final data = match.data();
          final estadisticas = data['estadisticas'] ?? {};
          final jugadoresConvocados = List<String>.from(
            data['jugadores'] ?? [],
          );
          final porterosConvocados = List<String>.from(data['porteros'] ?? []);
          final todosConvocados = [
            ...jugadoresConvocados,
            ...porterosConvocados,
          ];

          estadisticas.forEach((username, stats) {
            final valor = stats[estadistica];
            if (valor != null) {
              totalStatsMap[username] =
                  (totalStatsMap[username] ?? 0) + (valor as int);
            }
          });

          for (var id in todosConvocados) {
            final username = idToUsername[id];
            if (username != null && totalStatsMap.containsKey(username)) {
              convocatoriasMap[username] =
                  (convocatoriasMap[username] ?? 0) + 1;
            }
          }
        }
      }

      List<Map<String, dynamic>> jugadores =
          totalStatsMap.entries.map((entry) {
            final username = entry.key;
            final total = entry.value;
            final convocado = convocatoriasMap[username] ?? 1;

            return {
              'username': username,
              'value': total,
              'convocado': convocado,
            };
          }).toList();

      jugadores.sort((a, b) => b['value'].compareTo(a['value']));
      _rankingsCache[estadistica] = jugadores;

      return jugadores;
    } catch (e) {
      print('Error fetching rankings: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.blueGrey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isJugadoresSelected = true;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isJugadoresSelected
                                    ? Colors.blueGrey.shade900
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Jugadores',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isJugadoresSelected
                                      ? Colors.white
                                      : Colors.blueGrey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isJugadoresSelected = false;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                !isJugadoresSelected
                                    ? Colors.blueGrey.shade900
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Porteros',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  !isJugadoresSelected
                                      ? Colors.white
                                      : Colors.blueGrey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isJugadoresSelected)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                          bottom: 8.0,
                          left: 16.0,
                          right: 16.0,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          child: Row(
                            children:
                                estadisticas.asMap().entries.map((entry) {
                                  final isSelected =
                                      _tabController.index == entry.key;
                                  return GestureDetector(
                                    onTap: () {
                                      _tabController.animateTo(entry.key);
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Colors.blueGrey.shade900
                                                : Colors.blueGrey.shade100,
                                        borderRadius: BorderRadius.circular(
                                          20.0,
                                        ),
                                      ),
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.blueGrey.shade900,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                        color: Colors.blueGrey.shade800,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 12.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '#',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Jugador',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Media',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children:
                            estadisticas.map((stat) {
                              return FutureBuilder<List<Map<String, dynamic>>>(
                                future: _fetchRankings(stat),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      !_rankingsCache.containsKey(stat)) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasError || !snapshot.hasData) {
                                    return Center(
                                      child: Text(
                                        'Error al cargar los datos',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    );
                                  }

                                  final jugadores = snapshot.data ?? [];

                                  if (jugadores.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No hay datos disponibles',
                                        style: TextStyle(
                                          color: Colors.blueGrey.shade600,
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    itemCount: jugadores.length,
                                    itemBuilder: (context, index) {
                                      final jugador = jugadores[index];
                                      final convocado =
                                          jugador['convocado'] ?? 1;
                                      final media =
                                          convocado > 0
                                              ? (jugador['value'] / convocado)
                                                  .toStringAsFixed(2)
                                              : '0.00';

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                        ),
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16.0,
                                            horizontal: 12.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  '${index + 1}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors
                                                            .blueGrey
                                                            .shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  jugador['username'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors
                                                            .blueGrey
                                                            .shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  media,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        Colors
                                                            .blueGrey
                                                            .shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  '${jugador['value']}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors
                                                            .blueGrey
                                                            .shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                          bottom: 8.0,
                          left: 16.0,
                          right: 16.0,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          child: Row(
                            children:
                                estadisticasPorteros.asMap().entries.map((
                                  entry,
                                ) {
                                  final isSelected =
                                      _tabController.index == entry.key;
                                  return GestureDetector(
                                    onTap: () {
                                      _tabController.animateTo(entry.key);
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Colors.blueGrey.shade900
                                                : Colors.blueGrey.shade100,
                                        borderRadius: BorderRadius.circular(
                                          20.0,
                                        ),
                                      ),
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.blueGrey.shade900,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                        color: Colors.blueGrey.shade800,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 12.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '#',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Portero',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Media',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children:
                            estadisticasPorteros.map((stat) {
                              return FutureBuilder<List<Map<String, dynamic>>>(
                                future: _fetchRankings(stat),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      !_rankingsCache.containsKey(stat)) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasError || !snapshot.hasData) {
                                    return Center(
                                      child: Text(
                                        'Error al cargar los datos',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    );
                                  }

                                  final porteros = snapshot.data ?? [];

                                  if (porteros.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No hay datos disponibles',
                                        style: TextStyle(
                                          color: Colors.blueGrey.shade600,
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    itemCount: porteros.length,
                                    itemBuilder: (context, index) {
                                      final portero = porteros[index];
                                      final convocado =
                                          portero['convocado'] ?? 1;
                                      final media =
                                          convocado > 0
                                              ? (portero['value'] / convocado)
                                                  .toStringAsFixed(2)
                                              : '0.00';

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                        ),
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16.0,
                                            horizontal: 12.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  '${index + 1}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors
                                                            .blueGrey
                                                            .shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  portero['username'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors
                                                            .blueGrey
                                                            .shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  media,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        Colors
                                                            .blueGrey
                                                            .shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  '${portero['value']}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors
                                                            .blueGrey
                                                            .shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
