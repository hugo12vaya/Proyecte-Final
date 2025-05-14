import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:liga_app_new/data/datasource/league_datasource.dart';
import 'package:liga_app_new/data/datasource/match_datasource.dart';
import 'package:liga_app_new/data/datasource/user_datasource.dart';
import 'package:liga_app_new/domain/entities/member.dart';
import 'package:liga_app_new/domain/usecases/player/get_user_by_id_use_case.dart';
import 'package:liga_app_new/domain/usecases/league/get_all_leagues_use_case.dart';
import 'package:liga_app_new/domain/usecases/match/get_all_matches_by_league_id_use_case.dart';
import 'package:liga_app_new/infrastructure/repositories/match_repository_impl.dart';
import 'package:liga_app_new/infrastructure/repositories/player_repository_impl.dart';
import 'package:liga_app_new/infrastructure/repositories/league_repository_impl.dart';
import 'package:liga_app_new/presentation/widgets/clasificacion/header_row_widget.dart';
import 'package:liga_app_new/presentation/widgets/clasificacion/member_row_widget.dart';

class ClasificacionScreen extends StatefulWidget {
  const ClasificacionScreen({super.key});

  @override
  State<ClasificacionScreen> createState() => _ClasificacionScreenState();
}

class _ClasificacionScreenState extends State<ClasificacionScreen> {
  bool isGeneralSelected = true;
  String selectedJornada = '';
  List<Member> members = [];
  List<String> jornadas = [];
  List<Member> jornadaParticipants = [];

  GetAllLeaguesUseCase getAllLeaguesUseCase = GetAllLeaguesUseCase(
    LeagueRepositoryImpl(LeagueDatasource(FirebaseFirestore.instance)),
  );

  GetUserByIdUseCase getUserByIdUseCase = GetUserByIdUseCase(
    PlayerRepositoryImpl(UserDatasource(FirebaseFirestore.instance)),
  );

  GetAllMatchesByLeagueIdUseCase getAllMatchesByLeagueIdUseCase =
      GetAllMatchesByLeagueIdUseCase(
        MatchRepositoryImpl(MatchDatasource(FirebaseFirestore.instance)),
      );

  @override
  void initState() {
    super.initState();
    _fetchLeagueMembers();
  }

  Future<void> _fetchLeagueMembers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Llamada a la base de datos para obtener las ligas
      var leaguesSnapshot =
          await FirebaseFirestore.instance.collection('leagues').get();

      for (var league in leaguesSnapshot.docs) {
        if (league['admin'] == user.uid ||
            (league['members'] ?? []).any(
              (member) => member['uid'] == user.uid,
            )) {
          List<dynamic> leagueMembers = league['members'] ?? [];

          List<Member> fetchedMembers = [];
          for (var member in leagueMembers) {
            if (member['role'] == 'Jugador' || member['role'] == 'Portero') {
              // Llamada a la base de datos para obtener datos del usuario
              var userDoc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(member['uid'])
                      .get();

              if (userDoc.exists) {
                fetchedMembers.add(
                  Member(
                    uid: member['uid'],
                    username: userDoc.data()?['username'] ?? 'Sin nombre',
                    role: member['role'],
                  ),
                );
              }
            }
          }

          // Llamada a la base de datos para obtener los partidos de la liga
          var matchesSnapshot =
              await FirebaseFirestore.instance
                  .collection('leagues')
                  .doc(league.id)
                  .collection('matches')
                  .get();

          List<String> fetchedJornadas =
              matchesSnapshot.docs
                  .map((doc) => doc['jornada'].toString())
                  .toSet()
                  .toList();

          fetchedJornadas.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

          for (var match in matchesSnapshot.docs) {
            List<dynamic> jugadores = match.data()['jugadores'] ?? [];
            List<dynamic> porteros = match.data()['porteros'] ?? [];
            String resultado = match.data()['resultado'] ?? '';
            String matchLocation = match.data()['matchLocation'] ?? '';
            Map<String, dynamic> estadisticas =
                match.data()['estadisticas'] ?? {};

            for (var member in fetchedMembers) {
              if (jugadores.contains(member.uid) ||
                  porteros.contains(member.uid)) {
                member.partidosJugados += 1;

                if (resultado.contains('-')) {
                  List<String> scores = resultado.split('-');
                  int scoreLeft = int.tryParse(scores[0]) ?? 0;
                  int scoreRight = int.tryParse(scores[1]) ?? 0;

                  if ((matchLocation == 'Casa' && scoreLeft > scoreRight) ||
                      (matchLocation == 'Fuera' && scoreLeft < scoreRight)) {
                    member.partidosGanados += 1;
                  } else if (scoreLeft == scoreRight) {
                    member.partidosEmpatados += 1;
                  } else {
                    member.partidosPerdidos += 1;
                  }
                }

                String username = member.username;
                if (estadisticas.containsKey(username)) {
                  Map<String, dynamic> stats = estadisticas[username];

                  member.puntos += ((stats['totalPoints'] ?? 0) as num).toInt();
                  member.goles += ((stats['Gol'] ?? 0) as num).toInt();
                  member.asistencias +=
                      ((stats['Asistencia'] ?? 0) as num).toInt();
                  member.golesFavor +=
                      ((stats['Gol a favor'] ?? 0) as num).toInt();
                  member.golesContra +=
                      ((stats['Gol en contra'] ?? 0) as num).toInt();
                  member.penaltisProvocados +=
                      ((stats['Penalti provocado'] ?? 0) as num).toInt();
                  member.puntosEntrenador +=
                      ((stats['Puntos entrenador'] ?? 0) as num).toInt();
                  member.pasesClave +=
                      ((stats['Pase clave'] ?? 0) as num).toInt();
                  member.doblePenaltiProvocado +=
                      ((stats['Doble penalti provocado'] ?? 0) as num).toInt();
                  member.penaltiFallado +=
                      ((stats['Penalti fallado'] ?? 0) as num).toInt();
                  member.dobleFallado +=
                      ((stats['Doble fallado'] ?? 0) as num).toInt();
                  member.autogoles += ((stats['Autogol'] ?? 0) as num).toInt();
                  member.penaltiCometido +=
                      ((stats['Penalti cometido'] ?? 0) as num).toInt();
                  member.erroresGol +=
                      ((stats['Error de gol'] ?? 0) as num).toInt();
                  member.tarjetasAmarillas +=
                      ((stats['Tarjeta amarilla innecesaria'] ?? 0) as num)
                          .toInt();
                  member.tarjetasRojas +=
                      ((stats['Tarjeta roja'] ?? 0) as num).toInt();
                  member.golEnContraPorteroJugador +=
                      ((stats['Gol en contra (portero/jugador)'] ?? 0) as num)
                          .toInt();

                  member.porteriasCeroPrimera +=
                      ((stats['Porteria a 0 (primera parte)'] ?? 0) as num)
                          .toInt();
                  member.porteriasCeroSegunda +=
                      ((stats['Porteria a 0 (segunda parte)'] ?? 0) as num)
                          .toInt();
                  member.golesEncajados +=
                      ((stats['Gol encajado'] ?? 0) as num).toInt();
                  member.penaltisParados +=
                      ((stats['Parar penalti'] ?? 0) as num).toInt();
                  member.doblesPenaltisParados +=
                      ((stats['Parar doble penalti'] ?? 0) as num).toInt();
                }
              }
            }
          }

          fetchedMembers.sort((a, b) => b.puntos.compareTo(a.puntos));

          setState(() {
            members = fetchedMembers;
            jornadas = fetchedJornadas;
            if (jornadas.isNotEmpty) {
              selectedJornada = jornadas.first;
              _fetchJornadaParticipants(
                league.id,
                selectedJornada,
              ); // Llamada a otro método que usa Firebase
            }
          });
          break;
        }
      }
    } catch (e) {
      print('Error fetching league members or jornadas: $e');
    }
  }

  Future<void> _fetchJornadaParticipants(
    String leagueId,
    String jornada,
  ) async {
    try {
      // Llamada a la base de datos para obtener los partidos de una jornada específica
      var matchesSnapshot =
          await FirebaseFirestore.instance
              .collection('leagues')
              .doc(leagueId)
              .collection('matches')
              .where('jornada', isEqualTo: jornada)
              .get();

      if (matchesSnapshot.docs.isNotEmpty) {
        var match = matchesSnapshot.docs.first;
        List<dynamic> jugadores = match['jugadores'] ?? [];
        List<dynamic> porteros = match['porteros'] ?? [];
        Map<String, dynamic> estadisticas = match['estadisticas'] ?? {};

        List<Member> participants = [];

        for (var jugadorId in jugadores) {
          // Llamada a la base de datos para obtener datos del jugador
          var userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(jugadorId)
                  .get();

          if (userDoc.exists) {
            final username = userDoc.data()?['username'] ?? 'Sin nombre';
            final stats = estadisticas[username] ?? {};

            participants.add(
              Member(
                uid: jugadorId,
                username: username,
                role: 'Jugador',
                goles: stats['Gol'] ?? 0,
                asistencias: stats['Asistencia'] ?? 0,
                golesFavor: stats['Gol a favor'] ?? 0,
                golesContra: stats['Gol en contra'] ?? 0,
                golEnContraPorteroJugador:
                    stats['Gol en contra (portero/jugador)'] ?? 0,
                pasesClave: stats['Pase clave'] ?? 0,
                penaltisProvocados: stats['Penalti provocado'] ?? 0,
                doblePenaltiProvocado: stats['Doble penalti provocado'] ?? 0,
                penaltiFallado: stats['Penalti fallado'] ?? 0,
                dobleFallado: stats['Doble fallado'] ?? 0,
                autogoles: stats['Autogol'] ?? 0,
                penaltiCometido: stats['Penalti cometido'] ?? 0,
                erroresGol: stats['Error de gol'] ?? 0,
                tarjetasAmarillas: stats['Tarjeta amarilla innecesaria'] ?? 0,
                tarjetasRojas: stats['Tarjeta roja'] ?? 0,
                puntosEntrenador: stats['Puntos entrenador'] ?? 0,
                puntos: stats['totalPoints'] ?? 0,
              ),
            );
          }
        }

        for (var porteroId in porteros) {
          // Llamada a la base de datos para obtener datos del portero
          var userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(porteroId)
                  .get();

          if (userDoc.exists) {
            final username = userDoc.data()?['username'] ?? 'Sin nombre';
            final stats = estadisticas[username] ?? {};

            participants.add(
              Member(
                uid: porteroId,
                username: username,
                role: 'Portero',
                goles: stats['Gol'] ?? 0,
                asistencias: stats['Asistencia'] ?? 0,
                golesFavor: stats['Gol a favor'] ?? 0,
                golesContra: stats['Gol en contra'] ?? 0,
                golEnContraPorteroJugador:
                    stats['Gol en contra (portero/jugador)'] ?? 0,
                porteriasCeroPrimera:
                    stats['Porteria a 0 (primera parte)'] ?? 0,
                porteriasCeroSegunda:
                    stats['Porteria a 0 (segunda parte)'] ?? 0,
                golesEncajados: stats['Gol encajado'] ?? 0,
                penaltisParados: stats['Parar penalti'] ?? 0,
                doblesPenaltisParados: stats['Parar doble penalti'] ?? 0,
                penaltisProvocados: stats['Penalti provocado'] ?? 0,
                doblePenaltiProvocado: stats['Doble penalti provocado'] ?? 0,
                penaltiFallado: stats['Penalti fallado'] ?? 0,
                dobleFallado: stats['Doble fallado'] ?? 0,
                autogoles: stats['Autogol'] ?? 0,
                penaltiCometido: stats['Penalti cometido'] ?? 0,
                erroresGol: stats['Error de gol'] ?? 0,
                tarjetasAmarillas: stats['Tarjeta amarilla innecesaria'] ?? 0,
                tarjetasRojas: stats['Tarjeta roja'] ?? 0,
                puntosEntrenador: stats['Puntos entrenador'] ?? 0,
                puntos: stats['totalPoints'] ?? 0,
              ),
            );
          }
        }

        participants.sort((a, b) => b.puntos.compareTo(a.puntos));

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
                                isGeneralSelected = true;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    isGeneralSelected
                                        ? Colors.blueGrey.shade900
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'General',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isGeneralSelected
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
                                isGeneralSelected = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    !isGeneralSelected
                                        ? Colors.blueGrey.shade900
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Jornada',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      !isGeneralSelected
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
                  SizedBox(height: 16),
                  if (!isGeneralSelected)
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
                                    var user =
                                        FirebaseAuth.instance.currentUser;
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
                                                        member['uid'] ==
                                                        user.uid,
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
                                style: TextStyle(
                                  color: Colors.blueGrey.shade900,
                                ),
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
              child:
                  isGeneralSelected
                      ? Column(
                        children: [
                          HeaderRow(isGeneral: true),
                          Expanded(
                            child: ListView.builder(
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                return MemberRow(
                                  index: index,
                                  member: members[index].toMap(),
                                  isGeneral: true,
                                );
                              },
                            ),
                          ),
                        ],
                      )
                      : Column(
                        children: [
                          HeaderRow(isGeneral: false),
                          Expanded(
                            child: ListView.builder(
                              itemCount: jornadaParticipants.length,
                              itemBuilder: (context, index) {
                                return MemberRow(
                                  index: index,
                                  member: jornadaParticipants[index].toMap(),
                                  isGeneral: false,
                                );
                              },
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
