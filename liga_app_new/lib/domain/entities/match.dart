class Match {
  String callLocation;
  //TODO: Cambiar a Datetime Firebase
  String callTime;
  int jornada;
  List<String> jugadores;
  //TODO: Cambiar a Date en Firebase
  String matchDate;
  String matchLocation;
  String matchTime;
  String opponent;
  List<String> porteros;
  String resultado;

  // Constructor
  Match({
    required this.callLocation,
    required this.callTime,
    required this.jornada,
    required this.jugadores,
    required this.matchDate,
    required this.matchLocation,
    required this.matchTime,
    required this.opponent,
    required this.porteros,
    required this.resultado,
  });

  // TODO: añadir combrobantes null
  // Método fromJson
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      callLocation: json['callLocation'],
      callTime: json['callTime'],
      jornada: json['jornada'],
      jugadores: List<String>.from(json['jugadores']),
      matchDate: json['matchDate'],
      matchLocation: json['matchLocation'],
      matchTime: json['matchTime'],
      opponent: json['opponent'],
      porteros: List<String>.from(json['porteros']),
      resultado: json['resultado'],
    );
  }
}
