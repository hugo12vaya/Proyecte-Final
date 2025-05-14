import 'package:cloud_firestore/cloud_firestore.dart';

class LeagueDatasource {
  final FirebaseFirestore firestore;

  LeagueDatasource(this.firestore);

  Future<QuerySnapshot<Map<String, dynamic>>> getAllLeaguesRaw() async {
    return await firestore.collection('leagues').get();
  }

  //TODO: Comprobar
  Future<DocumentSnapshot<Map<String, dynamic>>> getLeagueByIdRaw(String leagueId) async {
    return await firestore.collection('leagues').doc(leagueId).get();
  }
}
