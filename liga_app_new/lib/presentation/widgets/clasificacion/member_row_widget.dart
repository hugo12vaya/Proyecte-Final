import 'package:flutter/material.dart';

class MemberRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> member;
  final bool isGeneral;

  const MemberRow({
    super.key,
    required this.index,
    required this.member,
    required this.isGeneral,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isGeneral) {
          _showPlayerDetailsDialog(context, member);
        } else {
          _showJornadaPlayerDetailsDialog(context, member);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 12.0,
            ),
            child: Row(
              children: [
                _buildMemberCell('${index + 1}', flex: 1),
                _buildMemberCell(member['username'] ?? '', flex: 3),
                if (isGeneral) ...[
                  _buildMemberCell(
                    member['partidosJugados']?.toString() ?? '',
                    flex: 1,
                    isBold: false,
                  ),
                  _buildMemberCell(
                    member['partidosGanados']?.toString() ?? '',
                    flex: 1,
                    isBold: false,
                  ),
                  _buildMemberCell(
                    member['partidosEmpatados']?.toString() ?? '',
                    flex: 1,
                    isBold: false,
                  ),
                  _buildMemberCell(
                    member['partidosPerdidos']?.toString() ?? '',
                    flex: 1,
                    isBold: false,
                  ),
                ] else ...[
                  _buildMemberCell(member['goles']?.toString() ?? '', flex: 1),
                  _buildMemberCell(
                    member['asistencias']?.toString() ?? '',
                    flex: 1,
                  ),
                  _buildMemberCell(
                    member['golesFavor']?.toString() ?? '',
                    flex: 1,
                    isBold: false,
                  ),
                  _buildMemberCell(
                    member['golesContra']?.toString() ?? '',
                    flex: 1,
                    isBold: false,
                  ),
                ],
                _buildMemberCell(member['puntos']?.toString() ?? '', flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlayerDetailsDialog(
    BuildContext context,
    Map<String, dynamic> member,
  ) {
    final isGoalkeeper = member['role'] == 'Portero';

    // Define las estadísticas según el rol
    final stats = isGoalkeeper
        ? {
            'Gol': member['goles'] ?? 0,
            'Asistencia': member['asistencias'] ?? 0,
            'Pase clave': member['pasesClave'] ?? 0,
            'Penalti provocado': member['penaltisProvocados'] ?? 0,
            'Doble penalti provocado': member['doblePenaltiProvocado'] ?? 0,
            'Porteria a 0 (primera parte)': member['porteriasCeroPrimera'] ?? 0,
            'Porteria a 0 (segunda parte)': member['porteriasCeroSegunda'] ?? 0,
            'Gol encajado': member['golesEncajados'] ?? 0,
            'Gol en contra (portero/jugador)':
                member['golEnContraPorteroJugador'] ?? 0, // Nueva estadística
            'Parar penalti': member['penaltisParados'] ?? 0,
            'Parar doble penalti': member['doblesPenaltisParados'] ?? 0,
            'Penalti fallado': member['penaltiFallado'] ?? 0,
            'Doble fallado': member['dobleFallado'] ?? 0,
            'Autogol': member['autogoles'] ?? 0,
            'Penalti cometido': member['penaltiCometido'] ?? 0,
            'Error de gol': member['erroresGol'] ?? 0,
            'Tarjeta amarilla innecesaria': member['tarjetasAmarillas'] ?? 0,
            'Tarjeta roja': member['tarjetasRojas'] ?? 0,
            'Puntos entrenador': member['puntosEntrenador'] ?? 0,
          }
        : {
            'Gol': member['goles'] ?? 0,
            'Asistencia': member['asistencias'] ?? 0,
            'Pase clave': member['pasesClave'] ?? 0,
            'Penalti provocado': member['penaltisProvocados'] ?? 0,
            'Doble penalti provocado': member['doblePenaltiProvocado'] ?? 0,
            'Penalti fallado': member['penaltiFallado'] ?? 0,
            'Doble fallado': member['dobleFallado'] ?? 0,
            'Autogol': member['autogoles'] ?? 0,
            'Penalti cometido': member['penaltiCometido'] ?? 0,
            'Error de gol': member['erroresGol'] ?? 0,
            'Tarjeta amarilla innecesaria': member['tarjetasAmarillas'] ?? 0,
            'Tarjeta roja': member['tarjetasRojas'] ?? 0,
            'Gol a favor': member['golesFavor'] ?? 0,
            'Gol en contra': member['golesContra'] ?? 0,
            'Gol en contra (portero/jugador)':
                member['golEnContraPorteroJugador'] ?? 0, // Nueva estadística
            'Puntos entrenador': member['puntosEntrenador'] ?? 0,
          };

    // Categorizar estadísticas
    final Map<String, List<MapEntry<String, dynamic>>> categorizedStats = {
      'Acciones ofensivas': stats.entries
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
        'Acciones defensivas': stats.entries
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
      'Acciones negativas': stats.entries
          .where(
            (entry) => [
              'Penalti fallado',
              'Doble fallado',
              'Autogol',
              'Penalti cometido',
              'Error de gol',
              'Tarjeta amarilla innecesaria',
              'Tarjeta roja',
            ].contains(entry.key),
          )
          .toList(),
      if (!isGoalkeeper)
        'Impacto en el marcador': stats.entries
            .where(
              (entry) => [
                'Gol a favor',
                'Gol en contra',
                'Gol en contra (portero/jugador)',
              ].contains(entry.key),
            )
            .toList(),
      'Entrenador': stats.entries
          .where((entry) => ['Puntos entrenador'].contains(entry.key))
          .toList(),
    };

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
                colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
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
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estadísticas de ${member['username']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ...categorizedStats.entries.map((category) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            category.key,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ...category.value.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '${entry.value}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                  SizedBox(height: 16),
                  // Removed the "Cerrar" button here
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showJornadaPlayerDetailsDialog(
    BuildContext context,
    Map<String, dynamic> member,
  ) {
    final isGoalkeeper = member['role'] == 'Portero';

    // Define las estadísticas según el rol
    final stats = isGoalkeeper
        ? {
            'Gol': member['goles'] ?? 0,
            'Asistencia': member['asistencias'] ?? 0,
            'Pase clave': member['pasesClave'] ?? 0,
            'Penalti provocado': member['penaltisProvocados'] ?? 0,
            'Doble penalti provocado': member['doblePenaltiProvocado'] ?? 0,
            'Porteria a 0 (primera parte)': member['porteriasCeroPrimera'] ?? 0,
            'Porteria a 0 (segunda parte)': member['porteriasCeroSegunda'] ?? 0,
            'Gol encajado': member['golesEncajados'] ?? 0,
            'Gol en contra (portero/jugador)':
                member['golEnContraPorteroJugador'] ?? 0,
            'Parar penalti': member['penaltisParados'] ?? 0,
            'Parar doble penalti': member['doblesPenaltisParados'] ?? 0,
            'Penalti fallado': member['penaltiFallado'] ?? 0,
            'Doble fallado': member['dobleFallado'] ?? 0,
            'Autogol': member['autogoles'] ?? 0,
            'Penalti cometido': member['penaltiCometido'] ?? 0,
            'Error de gol': member['erroresGol'] ?? 0,
            'Tarjeta amarilla innecesaria': member['tarjetasAmarillas'] ?? 0,
            'Tarjeta roja': member['tarjetasRojas'] ?? 0,
            'Puntos entrenador': member['puntosEntrenador'] ?? 0,
          }
        : {
            'Gol': member['goles'] ?? 0,
            'Asistencia': member['asistencias'] ?? 0,
            'Pase clave': member['pasesClave'] ?? 0,
            'Penalti provocado': member['penaltisProvocados'] ?? 0,
            'Doble penalti provocado': member['doblePenaltiProvocado'] ?? 0,
            'Penalti fallado': member['penaltiFallado'] ?? 0,
            'Doble fallado': member['dobleFallado'] ?? 0,
            'Autogol': member['autogoles'] ?? 0,
            'Penalti cometido': member['penaltiCometido'] ?? 0,
            'Error de gol': member['erroresGol'] ?? 0,
            'Tarjeta amarilla innecesaria': member['tarjetasAmarillas'] ?? 0,
            'Tarjeta roja': member['tarjetasRojas'] ?? 0,
            'Gol a favor': member['golesFavor'] ?? 0,
            'Gol en contra': member['golesContra'] ?? 0,
            'Gol en contra (portero/jugador)':
                member['golEnContraPorteroJugador'] ?? 0,
            'Puntos entrenador': member['puntosEntrenador'] ?? 0,
          };

    // Filtrar estadísticas que sean distintas de 0, excepto "Puntos entrenador"
    final filteredStats = stats.entries.where(
      (entry) => entry.value != 0 || entry.key == 'Puntos entrenador',
    );

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
                colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
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
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estadísticas de ${member['username']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ...filteredStats.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 16),
                  // Removed the "Cerrar" button here
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberCell(
    String text, {
    required int flex,
    bool isBold = true,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.blueGrey.shade900,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
