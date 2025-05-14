import 'package:liga_app_new/data/datasource/league_datasource.dart';
import 'package:liga_app_new/domain/entities/league.dart';
import 'package:liga_app_new/domain/repositories/league_repository.dart';

class LeagueRepositoryImpl implements LeagueRepository {
  final LeagueDatasource datasource;

  LeagueRepositoryImpl(this.datasource);

  //TODO: Comprobar
  @override
  Future<List<League>> getAllLeagues() async {
    try {
      var snap = await datasource.getAllLeaguesRaw();
      return snap.docs.map((doc) {
        var data = doc.data();
        return League.fromJson({
          'id': doc.id, // Añadir el id del documento
          ...data, // Incluir los demás datos del documento
        });
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<League?> getLeagueById(String leagueId) async {
    try {
      var docSnapshot = await datasource.getLeagueByIdRaw(leagueId);
      if (docSnapshot.exists) {
        var data = docSnapshot.data()!;
        return League.fromJson({
          'id': docSnapshot.id, // Añadir el id del documento
          ...data, // Incluir los demás datos del documento
        });
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
