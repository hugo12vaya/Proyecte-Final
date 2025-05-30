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
import 'package:liga_app_new/presentation/widgets/clasificacion/toggle_buttons_widget.dart';
import 'package:liga_app_new/presentation/widgets/clasificacion/jornada_dropdown_widget.dart';

// Widget principal de la pantalla de classificació
class ClasificacionScreen extends StatefulWidget {
  const ClasificacionScreen({super.key});

  @override
  State<ClasificacionScreen> createState() => _ClasificacionScreenState();
}

// Estat de la pantalla de classificació
class _ClasificacionScreenState extends State<ClasificacionScreen> {
  bool isGeneralSelected = true;
  String selectedJornada = '';
  List<Member> members = [];
  List<String> jornadas = [];
  List<Member> jornadaParticipants = [];

  // UseCases per accedir a les dades de la lliga, usuaris i partits
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
    _fetchLeagueMembers(); // Carrega els membres i jornades al començar la pantalla
  }

  // Obté els membres de la lliga i les jornades disponibles
  Future<void> _fetchLeagueMembers() async {
    User? user = FirebaseAuth.instance.currentUser; // Usuari autenticat
    if (user == null) return; // Si no hi ha usuari autenticat, ix

    try {
      // Obté totes les lligues de la base de dades
      var leaguesSnapshot =
          await FirebaseFirestore.instance.collection('leagues').get();

      for (var league in leaguesSnapshot.docs) {
        // Comprova si l'usuari és admin o membre de la lliga
        if (league['admin'] == user.uid ||
            (league['members'] ?? []).any(
              (member) => member['uid'] == user.uid,
            )) {
          List<dynamic> leagueMembers = league['members'] ?? [];

          List<Member> fetchedMembers = [];
          for (var member in leagueMembers) {
            // Només afegeix jugadors i porters
            if (member['role'] == 'Jugador' || member['role'] == 'Portero') {
              // Obté dades de l'usuari de la col·lecció users
              var userDoc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(member['uid'])
                      .get();

              if (userDoc.exists) {
                // Crea l'objecte Member amb les dades bàsiques
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

          // Obté tots els partits de la lliga
          var matchesSnapshot =
              await FirebaseFirestore.instance
                  .collection('leagues')
                  .doc(league.id)
                  .collection('matches')
                  .get();

          // Obté totes les jornades úniques presents als partits
          List<String> fetchedJornadas =
              matchesSnapshot.docs
                  .map((doc) => doc['jornada'].toString())
                  .toSet()
                  .toList();

          // Ordena les jornades numèricament (de menor a major)
          fetchedJornadas.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

          // Actualitza estadístiques dels membres segons els partits jugats
          for (var match in matchesSnapshot.docs) {
            List<dynamic> jugadores = match.data()['jugadores'] ?? [];
            List<dynamic> porteros = match.data()['porteros'] ?? [];
            String resultado = match.data()['resultado'] ?? '';
            String matchLocation = match.data()['matchLocation'] ?? '';
            Map<String, dynamic> estadisticas =
                match.data()['estadisticas'] ?? {};

            for (var member in fetchedMembers) {
              // Si el membre ha participat com a jugador o porter
              if (jugadores.contains(member.uid) ||
                  porteros.contains(member.uid)) {
                member.partidosJugados += 1;

                // Calcula partits guanyats, empatats i perduts segons el resultat i la localització
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

                // Suma estadístiques individuals si existeixen per a l'usuari
                String username = member.username;
                if (estadisticas.containsKey(username)) {
                  Map<String, dynamic> stats = estadisticas[username];

                  // Suma cada estadística individualment
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
                      ((stats['Doble penalti provocat'] ?? 0) as num).toInt();
                  member.penaltiFallado +=
                      ((stats['Penalti fallat'] ?? 0) as num).toInt();
                  member.dobleFallado +=
                      ((stats['Doble fallat'] ?? 0) as num).toInt();
                  member.autogoles += ((stats['Autogol'] ?? 0) as num).toInt();
                  member.penaltiCometido +=
                      ((stats['Penalti comès'] ?? 0) as num).toInt();
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

          // Ordena els membres per punts de major a menor
          fetchedMembers.sort((a, b) => b.puntos.compareTo(a.puntos));

          setState(() {
            members = fetchedMembers; // Actualitza la llista de membres
            jornadas = fetchedJornadas; // Actualitza la llista de jornades
            if (jornadas.isNotEmpty) {
              selectedJornada =
                  jornadas.first; // Selecciona la primera jornada per defecte
              _fetchJornadaParticipants(
                league.id,
                selectedJornada,
              ); // Carrega participants de la primera jornada
            }
          });
          break; // Només carrega la primera lliga on l'usuari participa
        }
      }
    } catch (e) {
      print(
        'Error fetching league members or jornadas: $e',
      ); // Mostra error per consola
    }
  }

  // Obté els participants d'una jornada concreta i les seues estadístiques
  Future<void> _fetchJornadaParticipants(
    String leagueId,
    String jornada,
  ) async {
    try {
      // Obté els partits de la jornada seleccionada
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

        // Afegeix jugadors amb les seues estadístiques de la jornada
        for (var jugadorId in jugadores) {
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
                doblePenaltiProvocado: stats['Doble penalti provocat'] ?? 0,
                penaltiFallado: stats['Penalti fallat'] ?? 0,
                dobleFallado: stats['Doble fallat'] ?? 0,
                autogoles: stats['Autogol'] ?? 0,
                penaltiCometido: stats['Penalti comès'] ?? 0,
                erroresGol: stats['Error de gol'] ?? 0,
                tarjetasAmarillas: stats['Tarjeta amarilla innecesaria'] ?? 0,
                tarjetasRojas: stats['Tarjeta roja'] ?? 0,
                puntosEntrenador: stats['Puntos entrenador'] ?? 0,
                puntos: stats['totalPoints'] ?? 0,
              ),
            );
          }
        }

        // Afegeix porters amb les seues estadístiques de la jornada
        for (var porteroId in porteros) {
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
                porteriasCeroSegunda: stats['Porteria a 0 (segona parte)'] ?? 0,
                golesEncajados: stats['Gol encajado'] ?? 0,
                penaltisParados: stats['Parar penalti'] ?? 0,
                doblesPenaltisParados: stats['Parar doble penalti'] ?? 0,
                penaltisProvocados: stats['Penalti provocado'] ?? 0,
                doblePenaltiProvocado: stats['Doble penalti provocat'] ?? 0,
                penaltiFallado: stats['Penalti fallat'] ?? 0,
                dobleFallado: stats['Doble fallat'] ?? 0,
                autogoles: stats['Autogol'] ?? 0,
                penaltiCometido: stats['Penalti comès'] ?? 0,
                erroresGol: stats['Error de gol'] ?? 0,
                tarjetasAmarillas: stats['Tarjeta amarilla innecesaria'] ?? 0,
                tarjetasRojas: stats['Tarjeta roja'] ?? 0,
                puntosEntrenador: stats['Puntos entrenador'] ?? 0,
                puntos: stats['totalPoints'] ?? 0,
              ),
            );
          }
        }

        // Ordena participants per punts de major a menor
        participants.sort((a, b) => b.puntos.compareTo(a.puntos));

        setState(() {
          jornadaParticipants =
              participants; // Actualitza la llista de participants de la jornada
        });
      } else {
        setState(() {
          jornadaParticipants =
              []; // Si no hi ha partits, la llista queda buida
        });
      }
    } catch (e) {
      print(
        'Error fetching participants for jornada $jornada: $e',
      ); // Mostra error per consola
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estructura principal de la pantalla
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Fons amb degradat vertical
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
                  // Botons per canviar entre classificació general i per jornada
                  ToggleButtonsWidget(
                    isGeneralSelected: isGeneralSelected,
                    onToggle: (bool isSelected) {
                      setState(() {
                        isGeneralSelected = isSelected;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  // Si es mostra per jornada, mostra el desplegable de jornades
                  if (!isGeneralSelected)
                    JornadaDropdownWidget(
                      jornadas: jornadas,
                      selectedJornada: selectedJornada,
                      onJornadaChanged: (String newJornada) {
                        setState(() {
                          selectedJornada = newJornada;
                          var user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // Busca la lliga de l'usuari i carrega els participants de la jornada seleccionada
                            FirebaseFirestore.instance
                                .collection('leagues')
                                .get()
                                .then((leaguesSnapshot) {
                                  for (var league in leaguesSnapshot.docs) {
                                    if (league['admin'] == user.uid ||
                                        (league['members'] ?? []).any(
                                          (member) => member['uid'] == user.uid,
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
                    ),
                ],
              ),
            ),
            Expanded(
              child:
                  isGeneralSelected
                      // Mostra la classificació general
                      ? Column(
                        children: [
                          HeaderRow(isGeneral: true), // Capçalera general
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
                      // Mostra la classificació per jornada
                      : Column(
                        children: [
                          HeaderRow(isGeneral: false), // Capçalera per jornada
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
