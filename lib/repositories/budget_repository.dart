import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _collection([String? userId]) {
    final uid = userId ?? currentUserId;

    if (uid == null) {
      return firestore.collection('budgets');
    }

    return firestore.collection('budgets').doc(uid).collection('items');
  }

  Future<void> saveBudget(
    BudgetModel budget, [
    String? userId,
  ]) async {
    final query = await _collection(userId)
        .where('category', isEqualTo: budget.category)
        .where('month', isEqualTo: budget.month)
        .where('year', isEqualTo: budget.year)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update(budget.toMap());
    } else {
      await _collection(userId).add(budget.toMap());
    }
  }

  Future<void> setBudget(
    BudgetModel budget, [
    String? userId,
  ]) async {
    await saveBudget(budget, userId);
  }

  Future<void> incrementBudget(
    BudgetModel budget, [
    String? userId,
  ]) async {
    final query = await _collection(userId)
        .where('category', isEqualTo: budget.category)
        .where('month', isEqualTo: budget.month)
        .where('year', isEqualTo: budget.year)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final existing = BudgetModel.fromMap(
        query.docs.first.data(),
        docId: query.docs.first.id,
      );
      await query.docs.first.reference.update(
        BudgetModel(
          id: existing.id,
          category: existing.category,
          limit: existing.limit + budget.limit,
          month: existing.month,
          year: existing.year,
        ).toMap(),
      );
    } else {
      await _collection(userId).add(budget.toMap());
    }
  }

  Future<void> addBudget(
    BudgetModel budget, [
    String? userId,
  ]) async {
    await saveBudget(budget, userId);
  }

  Future<void> saveMonthlyBudgets(
    List<BudgetModel> budgets, [
    String? userId,
  ]) async {
    for (final b in budgets) {
      await saveBudget(b, userId);
    }
  }

  Future<List<BudgetModel>> fetchBudgetsForMonth(
    int month,
    int year, [
    String? userId,
  ]) async {
    final snapshot = await _collection(userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    return snapshot.docs
        .map((doc) => BudgetModel.fromMap(doc.data(), docId: doc.id))
        .toList();
  }

  Future<List<BudgetModel>> fetchBudgets([
    String? userId,
  ]) async {
    final snapshot = await _collection(userId).get();
    return snapshot.docs
        .map((doc) => BudgetModel.fromMap(doc.data(), docId: doc.id))
        .toList();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getBudgets([
    String? userId,
  ]) {
    return _collection(userId).snapshots();
  }

  Stream<List<BudgetModel>> streamBudgetsForMonth(
    int month,
    int year, [
    String? userId,
  ]) {
    return _collection(userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BudgetModel.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  Future<void> deleteBudget(
    String docId, [
    String? userId,
  ]) async {
    if (docId.isEmpty) return;
    await _collection(userId).doc(docId).delete();
  }

  Future<int> deleteBudgetsForMonth(
    int month,
    int year, [
    String? userId,
  ]) async {
    final snapshot = await _collection(userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    int count = 0;
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
      count++;
    }
    return count;
  }

  Future<int> deleteAllBudgets([
    String? userId,
  ]) async {
    final snapshot = await _collection(userId).get();
    int count = 0;
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
      count++;
    }
    return count;
  }
}
