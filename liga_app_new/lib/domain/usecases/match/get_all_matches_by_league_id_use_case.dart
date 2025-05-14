import 'package:liga_app_new/domain/repositories/match_repository.dart';
import 'package:liga_app_new/domain/entities/match.dart';

class GetAllMatchesByLeagueIdUseCase {
  final MatchRepository repository;

  GetAllMatchesByLeagueIdUseCase(this.repository);

  Future<List<Match>> execute(String leagueId) =>
      repository.getAllMatchesByLeagueId(leagueId);
}
