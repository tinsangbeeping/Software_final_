import 'package:flutter/material.dart';

import '../../core/services/budget_pacing_service.dart';

class BudgetChart extends StatelessWidget {
  final List<CategoryPacing> pacingData;

  const BudgetChart({
    super.key,
    this.pacingData = const [],
  });

  // Category-specific colors
  static const Map<String, Color> _categoryColors = {
    'Food': Color(0xFF00BFA6),
    'Transport': Color(0xFF1976D2),
    'Shopping': Color(0xFFFFB300),
    'Entertainment': Color(0xFFE91E63),
    'Bills': Color(0xFF7C4DFF),
    'Health': Color(0xFFFF7043),
    'Other': Color(0xFF5C6BC0),
  };

  Color _getCategoryColor(String category) {
    return _categoryColors[category] ?? _categoryColors['Other']!;
  }

  Color _getHealthColor(String healthStatus) {
    switch (healthStatus) {
      case 'on_track':
        return const Color(0xFF4CAF50);
      case 'caution':
        return const Color(0xFFFFC107);
      case 'over_pace':
        return const Color(0xFFF44336);
      case 'over_budget':
        return const Color(0xFF212121);
      default:
        return Colors.grey;
    }
  }

  String _getHealthIcon(String healthStatus) {
    switch (healthStatus) {
      case 'on_track':
        return '🟢';
      case 'caution':
        return '🟡';
      case 'over_pace':
        return '🔴';
      case 'over_budget':
        return '⚫';
      default:
        return '⚪';
    }
  }

  String _getHealthLabel(String healthStatus) {
    switch (healthStatus) {
      case 'on_track':
        return 'On track';
      case 'caution':
        return 'Caution';
      case 'over_pace':
        return 'Over pace';
      case 'over_budget':
        return 'Over budget';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Budget Progress",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 16),
        if (pacingData.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    "Set a budget to see progress",
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 4),
              itemCount: pacingData.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final p = pacingData[index];
                final catColor = _getCategoryColor(p.category);
                final healthColor = _getHealthColor(p.healthStatus);
                final progress = p.allocated > 0
                    ? (p.spent / p.allocated).clamp(0.0, 1.0)
                    : 0.0;
                final daysLeftText = p.burnRate > 0 && p.daysUntilExhausted > 0
                    ? '${p.daysUntilExhausted} days left at \$${p.burnRate.toStringAsFixed(0)}/day'
                    : p.burnRate <= 0
                        ? 'No spending yet'
                        : 'Budget exhausted';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category header: dot + name + spent/allocated + health icon
                    Row(
                      children: [
                        // Category color dot
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Category name
                        Expanded(
                          child: Text(
                            p.category,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        // Spent / Allocated
                        Text(
                          '\$${p.spent.toStringAsFixed(0)} / \$${p.allocated.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Health icon + label
                        Text(
                          '${_getHealthIcon(p.healthStatus)} ${_getHealthLabel(p.healthStatus)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: healthColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Days left text
                    Text(
                      daysLeftText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
