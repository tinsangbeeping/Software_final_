import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';

/// Pacing data for a single budget category.
class CategoryPacing {
  /// Budget category name.
  final String category;

  /// Allocated budget amount.
  final double allocated;

  /// Actual amount spent so far this month.
  final double spent;

  /// Remaining budget (allocated - spent).
  final double remaining;

  /// Percentage of budget used (spent / allocated * 100).
  final double percentUsed;

  /// Number of days elapsed in the current month (1-indexed, today inclusive).
  final int daysElapsed;

  /// Total number of days in the current month.
  final int daysInMonth;

  /// Expected percentage of budget used by now (daysElapsed / daysInMonth * 100).
  final double expectedPercent;

  /// Daily burn rate (spent / daysElapsed).
  final double burnRate;

  /// Allowed daily burn rate (allocated / daysInMonth).
  final double allowedBurnRate;

  /// Health status: 'on_track', 'caution', 'over_pace', or 'over_budget'.
  final String healthStatus;

  /// Number of days until the budget is exhausted at current burn rate.
  /// Returns -1 if burn rate is zero or budget is already exceeded.
  final int daysUntilExhausted;

  const CategoryPacing({
    required this.category,
    required this.allocated,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.expectedPercent,
    required this.burnRate,
    required this.allowedBurnRate,
    required this.healthStatus,
    required this.daysUntilExhausted,
  });

  @override
  String toString() =>
      'CategoryPacing($category: \$${spent.toStringAsFixed(2)}/\$${allocated.toStringAsFixed(2)} '
      '[${percentUsed.toStringAsFixed(1)}%] $healthStatus)';
}

/// Service that computes per-category pacing by comparing actual spending
/// against the allocated budget and the current timeline within the month.
class BudgetPacingService {
  /// Compute pacing for every budget category.
  ///
  /// [budgets] – list of [BudgetModel] entries for the current (or target) month.
  /// [transactions] – full transaction list; only current-month expenses are used.
  List<CategoryPacing> computePacing(
    List<BudgetModel> budgets,
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final today = now.day;

    // Days in the current month (handles leap years).
    final daysInMonth =
        DateTime(currentYear, currentMonth + 1, 0).day;

    // Days elapsed – today inclusive (so at least 1 on day 1).
    final daysElapsed = today;

    // Expected percent = linear pacing expectation.
    final expectedPercent = (daysElapsed / daysInMonth) * 100;

    // Filter transactions to the current month AND type == 'expense'.
    final monthTransactions = transactions.where((t) =>
        t.createdAt.month == currentMonth &&
        t.createdAt.year == currentYear &&
        t.type == 'expense');

    // Aggregate spending by category.
    final Map<String, double> spendingByCategory = {};
    for (final tx in monthTransactions) {
      final cat = tx.category;
      spendingByCategory[cat] = (spendingByCategory[cat] ?? 0) + tx.amount;
    }

    final List<CategoryPacing> results = [];

    for (final budget in budgets) {
      final category = budget.category;
      final allocated = budget.limit;
      final spent = spendingByCategory[category] ?? 0.0;
      final remaining = allocated - spent;
      final percentUsed =
          allocated > 0 ? (spent / allocated * 100).clamp(0.0, 999.0) : 0.0;

      // Burn rate – average spending per day so far.
      final burnRate = daysElapsed > 0 ? spent / daysElapsed : 0.0;

      // Allowed burn rate – what you can spend per day and stay on track.
      final allowedBurnRate =
          daysInMonth > 0 ? allocated / daysInMonth : 0.0;

      // Days until exhausted at current burn rate.
      int daysUntilExhausted;
      if (burnRate <= 0) {
        daysUntilExhausted = remaining > 0 ? daysInMonth - daysElapsed : 0;
      } else {
        daysUntilExhausted = (remaining / burnRate).floor();
        if (daysUntilExhausted < 0) daysUntilExhausted = 0;
      }

      // Health determination.
      final String healthStatus =
          _determineHealth(percentUsed, expectedPercent);

      results.add(CategoryPacing(
        category: category,
        allocated: allocated,
        spent: spent,
        remaining: remaining,
        percentUsed: percentUsed,
        daysElapsed: daysElapsed,
        daysInMonth: daysInMonth,
        expectedPercent: expectedPercent,
        burnRate: burnRate,
        allowedBurnRate: allowedBurnRate,
        healthStatus: healthStatus,
        daysUntilExhausted: daysUntilExhausted,
      ));
    }

    return results;
  }

  /// Health logic:
  ///   over_budget  – percentUsed > 100
  ///   over_pace    – percentUsed > expectedPercent + 20
  ///   caution      – percentUsed > expectedPercent + 5
  ///   on_track     – otherwise
  String _determineHealth(double percentUsed, double expectedPercent) {
    if (percentUsed > 100) return 'over_budget';
    if (percentUsed > expectedPercent + 20) return 'over_pace';
    if (percentUsed > expectedPercent + 5) return 'caution';
    return 'on_track';
  }

  /// Return a human-readable text summary with health icons, suitable for
  /// passing to Gemini (or any AI) for further analysis.
  ///
  /// Health icons:
  ///   🟢  on_track
  ///   🟡  caution
  ///   🔴  over_pace / over_budget
  ///   ⚫  over_budget (explicitly distinguished from over_pace)
  String summarizeForAI(List<CategoryPacing> pacingData) {
    if (pacingData.isEmpty) {
      return 'No budget data available for the current month.';
    }

    final buf = StringBuffer();
    buf.writeln('📊 Budget Pacing Summary');
    buf.writeln('═══════════════════════════════════');

    // Use the first entry to report the timeline.
    final first = pacingData.first;
    buf.writeln(
        'Timeline: Day ${first.daysElapsed} of ${first.daysInMonth} '
        '(${first.expectedPercent.toStringAsFixed(1)}% of month elapsed)');
    buf.writeln('');

    // Overall stats.
    final totalAllocated =
        pacingData.fold<double>(0, (sum, p) => sum + p.allocated);
    final totalSpent =
        pacingData.fold<double>(0, (sum, p) => sum + p.spent);
    final totalRemaining =
        pacingData.fold<double>(0, (sum, p) => sum + p.remaining);

    buf.writeln(
        'Total Budget: \$${totalAllocated.toStringAsFixed(2)}');
    buf.writeln(
        'Total Spent:  \$${totalSpent.toStringAsFixed(2)}');
    buf.writeln(
        'Remaining:    \$${totalRemaining.toStringAsFixed(2)}');
    buf.writeln(
        'Overall:      ${(totalAllocated > 0 ? (totalSpent / totalAllocated * 100) : 0).toStringAsFixed(1)}% used');
    buf.writeln('');
    buf.writeln('Per-Category Breakdown:');
    buf.writeln('───────────────────────────────────');

    for (final p in pacingData) {
      final icon = _healthIcon(p.healthStatus);
      buf.writeln('');
      buf.writeln('$icon ${p.category}');
      buf.writeln(
          '   Budget: \$${p.allocated.toStringAsFixed(2)}  |  '
          'Spent: \$${p.spent.toStringAsFixed(2)}  |  '
          'Remaining: \$${p.remaining.toStringAsFixed(2)}');
      buf.writeln(
          '   Used: ${p.percentUsed.toStringAsFixed(1)}%  |  '
          'Expected: ${p.expectedPercent.toStringAsFixed(1)}%');
      buf.writeln(
          '   Burn Rate: \$${p.burnRate.toStringAsFixed(2)}/day  |  '
          'Allowed: \$${p.allowedBurnRate.toStringAsFixed(2)}/day');

      if (p.healthStatus == 'over_budget') {
        buf.writeln(
            '   ⚠️ OVER BUDGET by \$${(p.spent - p.allocated).toStringAsFixed(2)}');
      } else if (p.healthStatus == 'over_pace') {
        buf.writeln(
            '   ⚠️ Overspending by '
            '${(p.percentUsed - p.expectedPercent).toStringAsFixed(1)}% ahead of schedule');
      } else if (p.healthStatus == 'caution') {
        buf.writeln(
            '   ⚠️ Slightly ahead of schedule '
            '(${(p.percentUsed - p.expectedPercent).toStringAsFixed(1)}% over expected)');
      } else {
        buf.writeln(
            '   ✅ On track — '
            '${p.daysUntilExhausted > 0 ? "will last ~${p.daysUntilExhausted} more days at current rate" : "budget exhausted"}');
      }
    }

    buf.writeln('');
    buf.writeln('───────────────────────────────────');
    buf.writeln('Legend: 🟢 on_track | 🟡 caution | 🔴 over_pace | ⚫ over_budget');

    return buf.toString();
  }

  /// Map health status to a display icon.
  String _healthIcon(String status) {
    switch (status) {
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
}
