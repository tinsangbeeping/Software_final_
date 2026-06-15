import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile_model.dart';

class UserProfileRepository {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> saveProfile(
      UserProfileModel profile) async {

    await firestore
        .collection("user_profile")
        .doc("default")
        .set(
          profile.toMap(),
        );

  }

}