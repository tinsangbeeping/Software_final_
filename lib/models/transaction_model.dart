import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String type;
  final String category;
  final double amount;
  final String description;
  final DateTime createdAt;

  TransactionModel({
    this.id = '',
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'createdAt': createdAt,
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map, {
    String docId = '',
  }) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    double parseDouble(dynamic value) {
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final rawType = map['type']?.toString();
    final isExpense = map['isExpense'];
    final type = rawType ??
        (isExpense is bool
            ? (isExpense ? 'expense' : 'income')
            : 'expense');

    return TransactionModel(
      id: docId,
      type: type,
      category: map['category']?.toString() ?? 'Other',
      amount: parseDouble(map['amount']),
      description: map['description']?.toString() ??
          map['title']?.toString() ??
          map['merchant']?.toString() ??
          'Transaction',
      createdAt: parseDate(map['createdAt'] ?? map['date']),
    );
  }
}
