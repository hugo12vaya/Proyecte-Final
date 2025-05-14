import 'package:liga_app_new/domain/entities/player.dart';
import 'package:liga_app_new/domain/repositories/player_repository.dart';

class GetUserByIdUseCase {
  final PlayerRepository repository;

  GetUserByIdUseCase(this.repository);

  Future<Player?> execute(String userId) => repository.getUserById(userId);
}
