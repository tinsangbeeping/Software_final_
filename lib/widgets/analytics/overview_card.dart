import 'package:flutter/material.dart';

class OverviewCard extends StatelessWidget {
  final double monthlySpent;
  final double todaySpent;
  final double budgetLimit;

  const OverviewCard({
    super.key,
    required this.monthlySpent,
    required this.todaySpent,
    required this.budgetLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with trophy icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Overview",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFB300),
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2x2 grid of stat boxes
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: "Monthly Spent",
                  value: "\$${monthlySpent.toStringAsFixed(2)}",
                  bgColor: const Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: budgetLimit > 0
                    ? _StatBox(
                        label: "Budget Limit",
                        value: "\$${budgetLimit.toStringAsFixed(2)}",
                        bgColor: const Color(0xFFE8F5E9),
                      )
                    : _SetBudgetPrompt(),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: "Today's Spending",
                  value: "\$${todaySpent.toStringAsFixed(2)}",
                  bgColor: const Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: "vs Last Month",
                  value: "↓12%",
                  valueColor: const Color(0xFF00897B),
                  bgColor: const Color(0xFFE0F2F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color bgColor;
  final Color? valueColor;

  const _StatBox({
    required this.label,
    required this.value,
    required this.bgColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetBudgetPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to AI Chat tab (index 1 in the bottom nav)
        // Find the nearest HomePage state and switch tab
        // Since we can't easily do that, we'll just show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Go to AI Assistant and say "Set budget \$2000"'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF00BFA6).withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Budget Limit",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 18, color: const Color(0xFF00BFA6)),
                const SizedBox(width: 6),
                Text(
                  "Set a budget",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00BFA6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
