import 'package:cloud_firestore/cloud_firestore.dart';

class UserDatasource {
  final FirebaseFirestore firestore;

  UserDatasource(this.firestore);

  // Método para obtener todos los usuarios como objetos Player
  Future<QuerySnapshot<Map<String, dynamic>>> getAllUsers() async {
    return await firestore.collection('users').get();
  }

  // Método para obtener un usuario por ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserById(
    String userId,
  ) async {
    return await firestore.collection('users').doc(userId).get();
  }
}
