import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _collection([String? userId]) {
    final uid = userId ?? currentUserId;

    if (uid == null) {
      return firestore.collection('transactions');
    }

    return firestore
        .collection('transactions')
        .doc(uid)
        .collection('items');
  }

  Future<void> addTransaction(
    TransactionModel transaction, [
    String? userId,
  ]) async {
    await _collection(userId).add(transaction.toMap());
  }

  Future<void> deleteTransaction(
    String docId, [
    String? userId,
  ]) async {
    if (docId.isEmpty) return;
    await _collection(userId).doc(docId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getTransactions([
    String? userId,
  ]) {
    return _collection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<TransactionModel>> fetchTransactions([
    String? userId,
  ]) async {
    final snapshot = await _collection(userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => TransactionModel.fromMap(
            doc.data(),
            docId: doc.id,
          ),
        )
        .toList();
  }
}
