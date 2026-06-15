import 'package:flutter/material.dart';
import '../../models/insight_model.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import 'budget_pacing_service.dart';

class InsightsService {
  List<InsightModel> generateInsights(
    List<TransactionModel> transactions,
    List<BudgetModel> budgets, {
    List<CategoryPacing>? pacingData,
  }) {
    final insights = <InsightModel>[];

    if (transactions.isEmpty) {
      return [
        const InsightModel(
          icon: Icons.lightbulb_outline_rounded,
          title: "Start Tracking",
          description: "Record your first transaction to see personalized insights.",
          type: InsightType.neutral,
        ),
      ];
    }

    final trend = _calcSpendingTrend(transactions);
    if (trend != null) insights.add(trend);

    final pacing = _calcBudgetPacing(transactions, budgets);
    if (pacing != null) insights.add(pacing);

    final topCategory = _calcTopCategory(transactions);
    if (topCategory != null) insights.add(topCategory);

    final dailyAvg = _calcDailyAverage(transactions);
    if (dailyAvg != null) insights.add(dailyAvg);

    // Pacing-based insights
    if (pacingData != null && pacingData.isNotEmpty) {
      final pacingWarning = _calcPacingWarning(pacingData);
      if (pacingWarning != null) insights.add(pacingWarning);

      final onTrackCount = pacingData.where((p) => p.healthStatus == 'on_track').length;
      if (onTrackCount == pacingData.length && pacingData.length > 1) {
        insights.add(InsightModel(
          icon: Icons.check_circle_rounded,
          title: "All Categories On Track",
          description: "Great job! All ${pacingData.length} categories are within pace.",
          type: InsightType.positive,
        ));
      }
    }

    if (insights.isEmpty) {
      insights.add(const InsightModel(
        icon: Icons.insights_rounded,
        title: "Keep Going",
        description: "More data means better insights. Keep tracking!",
        type: InsightType.neutral,
      ));
    }

    return insights;
  }

  InsightModel? _calcSpendingTrend(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    double thisMonth = 0;
    double lastMonth = 0;

    for (final t in transactions) {
      if (t.type == "income") continue;
      if (t.createdAt.isAfter(thisMonthStart)) {
        thisMonth += t.amount;
      } else if (t.createdAt.isAfter(lastMonthStart) && t.createdAt.isBefore(thisMonthStart)) {
        lastMonth += t.amount;
      }
    }

    if (lastMonth == 0) {
      if (thisMonth == 0) return null;
      return InsightModel(
        icon: Icons.auto_graph_rounded,
        title: "First Month",
        description: "You've spent \$${thisMonth.toStringAsFixed(0)} this month. Next month we can compare!",
        type: InsightType.neutral,
      );
    }

    final percentChange = ((lastMonth - thisMonth) / lastMonth * 100);
    final isDown = percentChange > 0;

    if (percentChange.abs() < 1) {
      return InsightModel(
        icon: Icons.trending_flat_rounded,
        title: "Steady Spending",
        description: "Your spending is about the same as last month.",
        type: InsightType.neutral,
      );
    }

    return InsightModel(
      icon: isDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
      title: isDown ? "Great Progress!" : "Spending Up",
      description: isDown
          ? "You spent ${percentChange.abs().toStringAsFixed(0)}% less than last month. Keep up the good work!"
          : "You spent ${percentChange.abs().toStringAsFixed(0)}% more than last month. Watch your budget.",
      type: isDown ? InsightType.positive : InsightType.warning,
    );
  }

  InsightModel? _calcBudgetPacing(
    List<TransactionModel> transactions,
    List<BudgetModel> budgets,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.limit);

    double monthSpent = 0;
    for (final t in transactions) {
      if (t.type == "income") continue;
      if (t.createdAt.isAfter(monthStart)) {
        monthSpent += t.amount;
      }
    }

    // Default budget if none set
    final effectiveBudget = totalBudget > 0 ? totalBudget : 1600;
    final percent = (monthSpent / effectiveBudget * 100).clamp(0, 999);

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;
    final expectedPercent = (dayOfMonth / daysInMonth * 100);

    if (percent > 100) {
      return InsightModel(
        icon: Icons.warning_amber_rounded,
        title: "Over Budget",
        description: "You've spent ${(percent - 100).toStringAsFixed(0)}% over your monthly budget.",
        type: InsightType.warning,
      );
    }

    final isOnTrack = percent <= expectedPercent + 10;

    return InsightModel(
      icon: isOnTrack ? Icons.track_changes_rounded : Icons.speed_rounded,
      title: isOnTrack ? "On Track" : "Ahead of Pace",
      description: isOnTrack
          ? "You're ${percent.toStringAsFixed(0)}% through your monthly budget with great pacing."
          : "You're ${percent.toStringAsFixed(0)}% through your budget but only ${dayOfMonth}/${daysInMonth} days in.",
      type: isOnTrack ? InsightType.positive : InsightType.warning,
    );
  }

  InsightModel? _calcTopCategory(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final Map<String, double> categories = {};

    for (final t in transactions) {
      if (t.type == "income") continue;
      if (t.createdAt.isAfter(monthStart)) {
        categories[t.category] = (categories[t.category] ?? 0) + t.amount;
      }
    }

    if (categories.isEmpty) return null;

    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final total = categories.values.fold<double>(0, (sum, v) => sum + v);
    final percent = (top.value / total * 100).round();

    return InsightModel(
      icon: Icons.pie_chart_rounded,
      title: "${top.key} Leads",
      description: "${top.key} is your biggest expense at \$${top.value.toStringAsFixed(0)} ($percent% of total).",
      type: InsightType.neutral,
    );
  }

  InsightModel? _calcDailyAverage(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    double monthSpent = 0;

    for (final t in transactions) {
      if (t.type == "income") continue;
      if (t.createdAt.isAfter(monthStart)) {
        monthSpent += t.amount;
      }
    }

    if (monthSpent == 0) return null;

    final dayOfMonth = now.day;
    final dailyAvg = monthSpent / dayOfMonth;

    return InsightModel(
      icon: Icons.calendar_today_rounded,
      title: "Daily Average",
      description: "You're averaging \$${dailyAvg.toStringAsFixed(0)}/day this month.",
      type: dailyAvg > 60 ? InsightType.warning : InsightType.positive,
    );
  }

  /// Pacing-based insight: find the most at-risk category
  InsightModel? _calcPacingWarning(List<CategoryPacing> pacing) {
    CategoryPacing? worst;
    for (final p in pacing) {
      if (p.healthStatus == 'over_pace' || p.healthStatus == 'over_budget') {
        if (worst == null || p.percentUsed > worst.percentUsed) {
          worst = p;
        }
      }
    }
    if (worst == null) return null;

    final icon = worst.healthStatus == 'over_budget'
        ? Icons.error_rounded
        : Icons.warning_amber_rounded;

    return InsightModel(
      icon: icon,
      title: '${worst.category} Over Pace',
      description: worst.healthStatus == 'over_budget'
          ? '${worst.category} budget exceeded! \$${worst.spent.toStringAsFixed(0)} of \$${worst.allocated.toStringAsFixed(0)} spent.'
          : '${worst.category} at ${worst.percentUsed.toStringAsFixed(0)}% with ${worst.daysUntilExhausted} days left.',
      type: InsightType.warning,
    );
  }
}
