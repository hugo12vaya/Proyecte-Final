import 'package:liga_app_new/domain/entities/player.dart';

abstract class PlayerRepository {
  Future<List<Player>> getAllUsers();
  Future<Player?> getUserById(String userId);
}