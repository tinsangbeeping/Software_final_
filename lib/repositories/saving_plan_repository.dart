import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/saving_plan_model.dart';

class SavingPlanRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _currentPlanDoc([
    String? userId,
  ]) {
    final uid = userId ?? currentUserId;

    if (uid == null) {
      return firestore.collection('savingPlans').doc('current');
    }

    return firestore
        .collection('savingPlans')
        .doc(uid)
        .collection('items')
        .doc('current');
  }

  Future<void> saveCurrentPlan(
    dynamic first, [
    SavingPlanModel? second,
  ]) async {
    String? userId;
    late final SavingPlanModel plan;

    if (first is String) {
      userId = first;
      if (second == null) {
        throw ArgumentError('Saving plan is required.');
      }
      plan = second;
    } else if (first is SavingPlanModel) {
      plan = first;
    } else {
      throw ArgumentError('Invalid saveCurrentPlan arguments.');
    }

    await _currentPlanDoc(userId).set(
      plan.toMap(),
      SetOptions(merge: true),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getCurrentPlanStream([
    String? userId,
  ]) {
    return _currentPlanDoc(userId).snapshots();
  }

  Future<SavingPlanModel?> fetchCurrentPlan([
    String? userId,
  ]) async {
    final snapshot = await _currentPlanDoc(userId).get();

    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return SavingPlanModel.fromMap(data);
  }

  Future<void> deleteCurrentPlan([
    String? userId,
  ]) async {
    await _currentPlanDoc(userId).delete();
  }
}
