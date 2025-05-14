import 'package:liga_app_new/data/datasource/user_datasource.dart';
import 'package:liga_app_new/domain/entities/player.dart';
import 'package:liga_app_new/domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final UserDatasource datasource;

  PlayerRepositoryImpl(this.datasource);
  @override
  Future<List<Player>> getAllUsers() async {
    try {
      var snap = await datasource.getAllUsers();
      return snap.docs.map((doc) {
        final data = doc.data();
        return Player(doc.id, data['email'], data['username']);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Player?> getUserById(String userId) async {
    try {
      var docSnapshot = await datasource.getUserById(userId);
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return Player(docSnapshot.id, data['email'], data['username']);
      }
      throw Exception('User not found');
    } catch (e) {
      return null;
    }
  }
}
