import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklySnapshotModel {
  final String? id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalSpent;
  final int transactionCount;
  final Map<String, double> dailyBreakdown;
  final Map<String, double> categoryBreakdown;
  final double averageTransactionSize;

  WeeklySnapshotModel({
    this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.totalSpent,
    required this.transactionCount,
    required this.dailyBreakdown,
    required this.categoryBreakdown,
    required this.averageTransactionSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekStart': Timestamp.fromDate(weekStart),
      'weekEnd': Timestamp.fromDate(weekEnd),
      'totalSpent': totalSpent,
      'transactionCount': transactionCount,
      'dailyBreakdown': dailyBreakdown,
      'categoryBreakdown': categoryBreakdown,
      'averageTransactionSize': averageTransactionSize,
    };
  }

  factory WeeklySnapshotModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return WeeklySnapshotModel(
      id: docId,
      weekStart: (map['weekStart'] as Timestamp).toDate(),
      weekEnd: (map['weekEnd'] as Timestamp).toDate(),
      totalSpent: (map['totalSpent'] as num).toDouble(),
      transactionCount: (map['transactionCount'] as num).toInt(),
      dailyBreakdown: Map<String, double>.from(
        (map['dailyBreakdown'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      categoryBreakdown: Map<String, double>.from(
        (map['categoryBreakdown'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      averageTransactionSize: (map['averageTransactionSize'] as num).toDouble(),
    );
  }

  /// Build a snapshot from a list of transactions for a given week
  factory WeeklySnapshotModel.fromTransactions({
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<TransactionData> transactions,
  }) {
    final dailyBreakdown = <String, double>{};
    final categoryBreakdown = <String, double>{};
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (final t in transactions) {
      final dayName = dayNames[t.date.weekday - 1];
      dailyBreakdown[dayName] = (dailyBreakdown[dayName] ?? 0) + t.amount;
      categoryBreakdown[t.category] = (categoryBreakdown[t.category] ?? 0) + t.amount;
    }

    final totalSpent = transactions.fold<double>(0, (sum, t) => sum + t.amount);
    final count = transactions.length;

    return WeeklySnapshotModel(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalSpent: totalSpent,
      transactionCount: count,
      dailyBreakdown: dailyBreakdown,
      categoryBreakdown: categoryBreakdown,
      averageTransactionSize: count > 0 ? totalSpent / count : 0,
    );
  }
}

/// Lightweight transaction data for building snapshots
class TransactionData {
  final double amount;
  final String category;
  final DateTime date;

  TransactionData({
    required this.amount,
    required this.category,
    required this.date,
  });
}
