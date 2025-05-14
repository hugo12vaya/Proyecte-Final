import 'package:liga_app_new/domain/entities/league.dart';
import 'package:liga_app_new/domain/repositories/league_repository.dart';

class GetAllLeaguesUseCase {
  final LeagueRepository repository;

  GetAllLeaguesUseCase(this.repository);

  Future<List<League>> exceute() => repository.getAllLeagues();
}
