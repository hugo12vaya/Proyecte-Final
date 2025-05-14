import 'package:cloud_firestore/cloud_firestore.dart';

class MatchDatasource {
  final FirebaseFirestore firestore;
  MatchDatasource(this.firestore);
  //Cambiar a objeto 'League'
  Future<QuerySnapshot<Map<String, dynamic>>> getMatchesByLeagueIdRaw(
    String leagueId,
  ) async {
    return await firestore
        .collection('leagues')
        .doc(leagueId)
        .collection('matches')
        .get();
  }
}
