import 'package:liga_app_new/domain/entities/multa.dart';
import 'package:liga_app_new/domain/entities/player_role.dart';

class League {
  String id;
  String admin;
  DateTime createdAt;
  String description;
  List<PlayerRole>? members;
  List<Multa> multas;
  String name;

  // Constructor
  League({
    required this.id,
    required this.admin,
    required this.createdAt,
    required this.description,
    required this.members,
    required this.multas,
    required this.name,
  });

  // TODO: añadir combrobantes null
  // Método fromJson
  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id'],
      admin: json['admin'],
      createdAt: DateTime.parse(json['createdAt']),
      description: json['description'],
      members:
          (json['members'] as List)
              .map((member) => PlayerRole.fromJson(member))
              .toList(),
      multas:
          (json['multas'] as List)
              .map((multa) => Multa.fromJson(multa))
              .toList(),
      name: json['name'],
    );
  }
}
