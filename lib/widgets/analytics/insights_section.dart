import 'package:flutter/material.dart';
import '../../models/insight_model.dart';

class InsightsSection extends StatelessWidget {
  final List<InsightModel> insights;

  const InsightsSection({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

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
          const Text(
            "Insights",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InsightCard(insight: insight),
          )),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final InsightModel insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, iconColor, textColor) = switch (insight.type) {
      InsightType.positive => (
        const Color(0xFFE8F5E9),
        const Color(0xFFA5D6A7),
        const Color(0xFF2E7D32),
        const Color(0xFF1B5E20),
      ),
      InsightType.warning => (
        const Color(0xFFFFF3E0),
        const Color(0xFFFFCC80),
        const Color(0xFFE65100),
        const Color(0xFFBF360C),
      ),
      InsightType.neutral => (
        const Color(0xFFE3F2FD),
        const Color(0xFF90CAF9),
        const Color(0xFF1565C0),
        const Color(0xFF0D47A1),
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(insight.icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
