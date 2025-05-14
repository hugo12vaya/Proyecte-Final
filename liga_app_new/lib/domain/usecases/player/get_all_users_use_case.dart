import 'package:liga_app_new/domain/entities/player.dart';
import 'package:liga_app_new/domain/repositories/player_repository.dart';

class GetAllUsersUseCase {
  final PlayerRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<List<Player>> execute() => repository.getAllUsers();
}
