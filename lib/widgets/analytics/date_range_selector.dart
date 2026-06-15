import 'package:flutter/material.dart';

class DateRangeSelector extends StatelessWidget {
  final String selected;
  final DateTimeRange? customRange;
  final ValueChanged<String> onPresetSelected;
  final ValueChanged<DateTimeRange> onCustomRangeSelected;

  const DateRangeSelector({
    super.key,
    required this.selected,
    required this.customRange,
    required this.onPresetSelected,
    required this.onCustomRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _Chip(
            label: 'This Week',
            isSelected: selected == 'This Week',
            onTap: () => onPresetSelected('This Week'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'This Month',
            isSelected: selected == 'This Month',
            onTap: () => onPresetSelected('This Month'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'This Year',
            isSelected: selected == 'This Year',
            onTap: () => onPresetSelected('This Year'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'All Time',
            isSelected: selected == 'All Time',
            onTap: () => onPresetSelected('All Time'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: selected == 'Custom'
                ? '${customRange!.start.month}/${customRange!.start.day} - ${customRange!.end.month}/${customRange!.end.day}'
                : 'Custom',
            isSelected: selected == 'Custom',
            isCustom: true,
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: now,
                initialDateRange: customRange ?? DateTimeRange(
                  start: now.subtract(const Duration(days: 30)),
                  end: now,
                ),
              );
              if (picked != null) onCustomRangeSelected(picked);
            },
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCustom;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    this.isCustom = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BFA6) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF00BFA6) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF00BFA6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCustom) ...[
              Icon(
                Icons.date_range_rounded,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
