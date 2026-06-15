import 'package:cloud_firestore/cloud_firestore.dart';

class SavingPlanModel {
  final String goalText;
  final double targetAmount;
  final String timeframe;
  final String planSummary;
  final String weeklyTarget;
  final String focusCategories;
  final String actionSteps;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingPlanModel({
    required this.goalText,
    required this.targetAmount,
    required this.timeframe,
    required this.planSummary,
    required this.weeklyTarget,
    required this.focusCategories,
    required this.actionSteps,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'goalText': goalText,
      'targetAmount': targetAmount,
      'timeframe': timeframe,
      'planSummary': planSummary,
      'weeklyTarget': weeklyTarget,
      'focusCategories': focusCategories,
      'actionSteps': actionSteps,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory SavingPlanModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    double parseDouble(dynamic value) {
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return SavingPlanModel(
      goalText: map['goalText']?.toString() ?? '',
      targetAmount: parseDouble(map['targetAmount']),
      timeframe: map['timeframe']?.toString() ?? 'Not specified',
      planSummary: map['planSummary']?.toString() ?? '',
      weeklyTarget: map['weeklyTarget']?.toString() ?? '',
      focusCategories: map['focusCategories']?.toString() ?? '',
      actionSteps: map['actionSteps']?.toString() ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  String toPromptText() {
    if (planSummary.trim().isEmpty && goalText.trim().isEmpty) {
      return 'No saving goal plan is currently set.';
    }

    return '''
Current saving goal plan:
Goal: $goalText
Target amount: ${targetAmount <= 0 ? 'Not specified' : '\$${targetAmount.toStringAsFixed(0)}'}
Timeframe: $timeframe
Plan summary: $planSummary
Weekly target: $weeklyTarget
Focus categories: $focusCategories
Action steps: $actionSteps
''';
  }
}
