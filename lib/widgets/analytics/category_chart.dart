import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryChart extends StatelessWidget {
  final Map<String, double> categoryTotals;

  const CategoryChart({
    super.key,
    required this.categoryTotals,
  });

  static const List<Color> _colors = [
    Color(0xFF00BFA6),
    Color(0xFF1976D2),
    Color(0xFFFFB300),
    Color(0xFFE91E63),
    Color(0xFF7C4DFF),
    Color(0xFFFF7043),
    Color(0xFF26A69A),
    Color(0xFF5C6BC0),
  ];

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "No category data yet",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    final entries = categoryTotals.entries.toList();
    final total = categoryTotals.values.fold<double>(0, (sum, value) => sum + value);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 36,
              sectionsSpace: 3,
              sections: List.generate(entries.length, (index) {
                final entry = entries[index];
                final percent = total == 0 ? 0 : (entry.value / total) * 100;
                return PieChartSectionData(
                  value: entry.value,
                  title: "${percent.toStringAsFixed(0)}%",
                  radius: 56,
                  color: _colors[index % _colors.length],
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(entries.length, (index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colors[index % _colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "\$${entry.value.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
