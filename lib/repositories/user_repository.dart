import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection("users")
        .doc(user.uid)
        .set(user.toMap());
  }
}