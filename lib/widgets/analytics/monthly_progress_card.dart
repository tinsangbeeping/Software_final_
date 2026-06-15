import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyProgressCard extends StatelessWidget {
  final double totalSpent;
  final double budgetLimit;

  const MonthlyProgressCard({
    super.key,
    required this.totalSpent,
    required this.budgetLimit,
  });

  @override
  Widget build(BuildContext context) {
    final String dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());

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
      child: budgetLimit > 0
          ? _buildProgressContent(context, dateStr)
          : _buildNoBudgetContent(context, dateStr),
    );
  }

  Widget _buildNoBudgetContent(BuildContext context, String dateStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Monthly Progress",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dateStr,
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Go to AI Assistant and say "Set budget \$2000"'),
                action: SnackBarAction(label: 'OK', onPressed: () {}),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF00BFA6).withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 20, color: const Color(0xFF00BFA6)),
                const SizedBox(width: 8),
                Text(
                  "Set a budget to track progress",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00BFA6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressContent(BuildContext context, String dateStr) {
    final double progress = (totalSpent / budgetLimit).clamp(0.0, 1.0);
    final int percentUsed = (progress * 100).round();
    final double remaining = budgetLimit - totalSpent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with % pill
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Monthly Progress",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$percentUsed% used",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: percentUsed > 80
                      ? Colors.red.shade400
                      : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Date
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),

        const SizedBox(height: 18),

        // Amount row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "\$${totalSpent.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "of \$${budgetLimit.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.green.shade600,
                      size: 18,
                    ),
                    Text(
                      "\$${remaining.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  "remaining",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: const Color(0xFFE0E0E0),
            color: percentUsed > 80
                ? Colors.red.shade400
                : const Color(0xFF00BFA6),
          ),
        ),
      ],
    );
  }
}
