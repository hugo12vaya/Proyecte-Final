class Multa {
  int cantidad;
  DateTime fecha;
  String motivo;
  bool pagado;
  String usuario;

  Multa(this.cantidad, this.fecha, this.motivo, this.pagado, this.usuario);

  // TODO: añadir combrobantes null
  // Método fromJson
  factory Multa.fromJson(Map<String, dynamic> json) {
    return Multa(
      json['cantidad'],
      DateTime.parse(json['fecha']),
      json['motivo'],
      json['pagado'],
      json['usuario'],
    );
  }
}
