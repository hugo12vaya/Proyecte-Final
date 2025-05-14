class Member {
  final String uid;
  final String username;
  final String role;
  int puntos;
  int partidosJugados;
  int partidosGanados;
  int partidosEmpatados;
  int partidosPerdidos;
  int penaltisProvocados;
  int puntosEntrenador;
  int goles;
  int asistencias;
  int golesFavor;
  int golesContra;
  int pasesClave;
  int doblePenaltiProvocado;
  int penaltiFallado;
  int dobleFallado;
  int autogoles;
  int penaltiCometido;
  int erroresGol;
  int tarjetasAmarillas;
  int tarjetasRojas;
  int porteriasCeroPrimera;
  int porteriasCeroSegunda;
  int golesEncajados;
  int penaltisParados;
  int doblesPenaltisParados;
  int golEnContraPorteroJugador;

  Member({
    required this.uid,
    required this.username,
    required this.role,
    this.puntos = 0,
    this.partidosJugados = 0,
    this.partidosGanados = 0,
    this.partidosEmpatados = 0,
    this.partidosPerdidos = 0,
    this.penaltisProvocados = 0,
    this.puntosEntrenador = 0,
    this.goles = 0,
    this.asistencias = 0,
    this.golesFavor = 0,
    this.golesContra = 0,
    this.pasesClave = 0,
    this.doblePenaltiProvocado = 0,
    this.penaltiFallado = 0,
    this.dobleFallado = 0,
    this.autogoles = 0,
    this.penaltiCometido = 0,
    this.erroresGol = 0,
    this.tarjetasAmarillas = 0,
    this.tarjetasRojas = 0,
    this.porteriasCeroPrimera = 0,
    this.porteriasCeroSegunda = 0,
    this.golesEncajados = 0,
    this.penaltisParados = 0,
    this.doblesPenaltisParados = 0,
    this.golEnContraPorteroJugador = 0,
  });

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      uid: map['uid'],
      username: map['username'] ?? 'Sin nombre',
      role: map['role'],
      puntos: map['puntos'] ?? 0,
      partidosJugados: map['partidosJugados'] ?? 0,
      partidosGanados: map['partidosGanados'] ?? 0,
      partidosEmpatados: map['partidosEmpatados'] ?? 0,
      partidosPerdidos: map['partidosPerdidos'] ?? 0,
      penaltisProvocados: map['penaltisProvocados'] ?? 0,
      puntosEntrenador: map['puntosEntrenador'] ?? 0,
      goles: map['goles'] ?? 0,
      asistencias: map['asistencias'] ?? 0,
      golesFavor: map['golesFavor'] ?? 0,
      golesContra: map['golesContra'] ?? 0,
      pasesClave: map['pasesClave'] ?? 0,
      doblePenaltiProvocado: map['doblePenaltiProvocado'] ?? 0,
      penaltiFallado: map['penaltiFallado'] ?? 0,
      dobleFallado: map['dobleFallado'] ?? 0,
      autogoles: map['autogoles'] ?? 0,
      penaltiCometido: map['penaltiCometido'] ?? 0,
      erroresGol: map['erroresGol'] ?? 0,
      tarjetasAmarillas: map['tarjetasAmarillas'] ?? 0,
      tarjetasRojas: map['tarjetasRojas'] ?? 0,
      porteriasCeroPrimera: map['porteriasCeroPrimera'] ?? 0,
      porteriasCeroSegunda: map['porteriasCeroSegunda'] ?? 0,
      golesEncajados: map['golesEncajados'] ?? 0,
      penaltisParados: map['penaltisParados'] ?? 0,
      doblesPenaltisParados: map['doblesPenaltisParados'] ?? 0,
      golEnContraPorteroJugador: map['golEnContraPorteroJugador'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'role': role,
      'puntos': puntos,
      'partidosJugados': partidosJugados,
      'partidosGanados': partidosGanados,
      'partidosEmpatados': partidosEmpatados,
      'partidosPerdidos': partidosPerdidos,
      'penaltisProvocados': penaltisProvocados,
      'puntosEntrenador': puntosEntrenador,
      'goles': goles,
      'asistencias': asistencias,
      'golesFavor': golesFavor,
      'golesContra': golesContra,
      'pasesClave': pasesClave,
      'doblePenaltiProvocado': doblePenaltiProvocado,
      'penaltiFallado': penaltiFallado,
      'dobleFallado': dobleFallado,
      'autogoles': autogoles,
      'penaltiCometido': penaltiCometido,
      'erroresGol': erroresGol,
      'tarjetasAmarillas': tarjetasAmarillas,
      'tarjetasRojas': tarjetasRojas,
      'porteriasCeroPrimera': porteriasCeroPrimera,
      'porteriasCeroSegunda': porteriasCeroSegunda,
      'golesEncajados': golesEncajados,
      'penaltisParados': penaltisParados,
      'doblesPenaltisParados': doblesPenaltisParados,
      'golEnContraPorteroJugador': golEnContraPorteroJugador,
    };
  }
}
