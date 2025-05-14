import 'package:liga_app_new/domain/entities/league.dart';
import 'package:liga_app_new/domain/repositories/league_repository.dart';

class GetLeagueByIdUseCase {
  final LeagueRepository repository;

  GetLeagueByIdUseCase(this.repository);

  Future<League?> execute(String leagueId) =>
      repository.getLeagueById(leagueId);
}
