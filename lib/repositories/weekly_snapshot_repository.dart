import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weekly_snapshot_model.dart';

class WeeklySnapshotRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String collectionName = 'weekly_snapshots';

  Future<void> saveSnapshot(WeeklySnapshotModel snapshot) async {
    await firestore.collection(collectionName).add(snapshot.toMap());
  }

  Future<List<WeeklySnapshotModel>> fetchSnapshots({int limit = 8}) async {
    final snapshot = await firestore
        .collection(collectionName)
        .orderBy('weekStart', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => WeeklySnapshotModel.fromMap(doc.data(), docId: doc.id))
        .toList();
  }

  Future<bool> hasCurrentWeek() async {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    final snapshot = await firestore
        .collection(collectionName)
        .where('weekStart', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }
}
