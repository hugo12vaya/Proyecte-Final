import 'package:liga_app_new/data/datasource/match_datasource.dart';
import 'package:liga_app_new/domain/repositories/match_repository.dart';
import 'package:liga_app_new/domain/entities/match.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchDatasource datasource;

  MatchRepositoryImpl(this.datasource);
  @override
  Future<List<Match>> getAllMatchesByLeagueId(String leagueId) async {
    var snap = await datasource.getMatchesByLeagueIdRaw(leagueId);
    return snap.docs.map((doc) => Match.fromJson(doc.data())).toList();
  }
}
