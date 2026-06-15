class BudgetModel {
  final String id;
  final String category;
  final double limit;
  final int month;
  final int year;
  final double spent;
  final int transactionCount;

  BudgetModel({
    this.id = '',
    required this.category,
    required this.limit,
    this.month = 0,
    this.year = 0,
    this.spent = 0,
    this.transactionCount = 0,
  });

  double get remaining => limit - spent;

  double get percentUsed {
    if (limit <= 0) return 0;
    return (spent / limit * 100).clamp(0.0, 999.0);
  }

  String get healthStatus {
    if (percentUsed > 100) return 'over_budget';
    if (percentUsed > 80) return 'over_pace';
    if (percentUsed > 50) return 'caution';
    return 'on_track';
  }

  BudgetModel withSpending({
    required double spent,
    required int transactionCount,
  }) {
    return BudgetModel(
      id: id,
      category: category,
      limit: limit,
      month: month,
      year: year,
      spent: spent,
      transactionCount: transactionCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limit': limit,
      'month': month,
      'year': year,
    };
  }

  factory BudgetModel.fromMap(
    Map<String, dynamic> map, {
    String docId = '',
  }) {
    double parseDouble(dynamic value) {
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int parseInt(dynamic value) {
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return BudgetModel(
      id: docId,
      category: map['category']?.toString() ?? 'Other',
      limit: parseDouble(
        map['limit'] ??
            map['amount'] ??
            map['budgetLimit'] ??
            map['budget_limit'] ??
            map['totalBudget'] ??
            map['total'] ??
            map['value'],
      ),
      month: parseInt(map['month']),
      year: parseInt(map['year']),
    );
  }
}
