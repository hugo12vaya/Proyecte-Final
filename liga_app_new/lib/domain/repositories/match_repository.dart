import 'package:liga_app_new/domain/entities/match.dart';

abstract class MatchRepository {
  Future<List<Match>> getAllMatchesByLeagueId(String leagueId);
}
