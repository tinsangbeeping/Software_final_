import 'package:flutter/material.dart';

class OverspendingWarningCard extends StatelessWidget {
  final double monthlySpent;
  final double budgetLimit;
  final Map<String, double> categoryTotals;

  const OverspendingWarningCard({
    super.key,
    required this.monthlySpent,
    required this.budgetLimit,
    this.categoryTotals = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (budgetLimit <= 0) {
      return const SizedBox.shrink();
    }

    final usageRate = monthlySpent / budgetLimit;

    if (usageRate < 0.8) {
      return const SizedBox.shrink();
    }

    final remaining = budgetLimit - monthlySpent;
    final isOverBudget = usageRate >= 1.0;
    final topCategory = _getTopCategory();

    final title = isOverBudget
        ? "Budget exceeded"
        : "Almost over budget";

    final message = isOverBudget
        ? "You have exceeded your monthly budget by \$${remaining.abs().toStringAsFixed(0)}."
        : "You have used ${(usageRate * 100).toStringAsFixed(0)}% of your monthly budget. You have \$${remaining.toStringAsFixed(0)} left this month.";

    final suggestion = topCategory == null
        ? "Try reducing non-essential spending for the next few days."
        : "Your highest spending category is $topCategory. Try reducing $topCategory expenses this week.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isOverBudget
            ? const Color(0xFFFFE5E5)
            : const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isOverBudget
                ? Icons.warning_rounded
                : Icons.error_outline_rounded,
            color: isOverBudget
                ? Colors.redAccent
                : Colors.orange[800],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[850],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  suggestion,
                  style: TextStyle(
                    color: Colors.grey[850],
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _getTopCategory() {
    if (categoryTotals.isEmpty) {
      return null;
    }

    String? topCategory;
    double topAmount = 0;

    categoryTotals.forEach((category, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = category;
      }
    });

    return topCategory;
  }
}
