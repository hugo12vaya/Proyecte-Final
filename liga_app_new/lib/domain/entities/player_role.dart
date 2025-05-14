class PlayerRole {
  String role;
  String uid;

  PlayerRole({required this.role, required this.uid});

  // TODO: añadir combrobantes null
  // Método fromJson
  factory PlayerRole.fromJson(Map<String, dynamic> json) {
    return PlayerRole(role: json['role'], uid: json['uid']);
  }
}
