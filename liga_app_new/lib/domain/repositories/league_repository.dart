import 'package:liga_app_new/domain/entities/league.dart';

abstract class LeagueRepository {
  Future<List<League>> getAllLeagues();
  Future<League?> getLeagueById(String leagueId);
}