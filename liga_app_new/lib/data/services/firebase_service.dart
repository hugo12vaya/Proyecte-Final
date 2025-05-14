import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<List<QueryDocumentSnapshot>> getLeagues() async {
    final leaguesSnapshot = await _firestore.collection('leagues').get();
    return leaguesSnapshot.docs;
  }

  Future<List<QueryDocumentSnapshot>> getMatches(String leagueId) async {
    final matchesSnapshot =
        await _firestore
            .collection('leagues')
            .doc(leagueId)
            .collection('matches')
            .get();
    return matchesSnapshot.docs;
  }

  Future<DocumentSnapshot> getUserById(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  Future<List<QueryDocumentSnapshot>> getMatchesByJornada(
    String leagueId,
    String jornada,
  ) async {
    final matchesSnapshot =
        await _firestore
            .collection('leagues')
            .doc(leagueId)
            .collection('matches')
            .where('jornada', isEqualTo: jornada)
            .get();
    return matchesSnapshot.docs;
  }
}
