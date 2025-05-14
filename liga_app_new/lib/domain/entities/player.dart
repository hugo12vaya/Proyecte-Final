class Player {
  String id;
  String email;
  String name;

  Player(this.id, this.email, this.name);

  // TODO: añadir combrobantes null
  // Method fromJson
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      json['id'],
      json['email'],
      json['name'],
    );
  }
}
