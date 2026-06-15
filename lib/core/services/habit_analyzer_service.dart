import '../../models/transaction_model.dart';
import '../../models/user_profile_model.dart';

class SpendingHabitResult {
  final double weekdayAverage;
  final double weekendAverage;
  final String topCategory;
  final double topCategoryAmount;
  final bool spendsMoreOnWeekends;
  final bool recentSpendingIncreased;
  final List<String> insights;

  SpendingHabitResult({
    required this.weekdayAverage,
    required this.weekendAverage,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.spendsMoreOnWeekends,
    required this.recentSpendingIncreased,
    required this.insights,
  });

  String toPromptText() {
    return """
Weekday average spending: \$${weekdayAverage.toStringAsFixed(2)}
Weekend average spending: \$${weekendAverage.toStringAsFixed(2)}
Top spending category: $topCategory \$${topCategoryAmount.toStringAsFixed(2)}
Spends more on weekends: ${spendsMoreOnWeekends ? "Yes" : "No"}
Recent spending increased: ${recentSpendingIncreased ? "Yes" : "No"}
Detected habits:
${insights.map((insight) => "- $insight").join("\n")}
""";
  }
}

class HabitAnalyzerService {
  UserProfileModel analyze(
    List<TransactionModel> transactions,
  ) {
    final expenses = transactions
        .where((t) => t.type == "expense")
        .toList();

    if (expenses.isEmpty) {
      return UserProfileModel(
        averageDailySpending: 0,
        weekdayBudget: 0,
        weekendBudget: 0,
        wakeHour: 0,
        sleepHour: 0,
      );
    }

    double total = 0;

    int earliestHour = 23;
    int latestHour = 0;

    double weekdayTotal = 0;
    double weekendTotal = 0;

    int weekdayCount = 0;
    int weekendCount = 0;

    for (final t in expenses) {
      total += t.amount;

      final hour = t.createdAt.hour;

      if (hour < earliestHour) {
        earliestHour = hour;
      }

      if (hour > latestHour) {
        latestHour = hour;
      }

      final day = t.createdAt.weekday;

      if (day == DateTime.saturday ||
          day == DateTime.sunday) {
        weekendTotal += t.amount;
        weekendCount++;
      } else {
        weekdayTotal += t.amount;
        weekdayCount++;
      }
    }

    return UserProfileModel(
      averageDailySpending: total / expenses.length,
      weekdayBudget: weekdayCount == 0
          ? 0
          : weekdayTotal / weekdayCount,
      weekendBudget: weekendCount == 0
          ? 0
          : weekendTotal / weekendCount,
      wakeHour: earliestHour,
      sleepHour: latestHour + 1,
    );
  }

  SpendingHabitResult analyzeSpendingHabits(
    List<TransactionModel> transactions,
  ) {
    final expenses = transactions
        .where((t) => t.type == "expense")
        .toList();

    if (expenses.isEmpty) {
      return SpendingHabitResult(
        weekdayAverage: 0,
        weekendAverage: 0,
        topCategory: "None",
        topCategoryAmount: 0,
        spendsMoreOnWeekends: false,
        recentSpendingIncreased: false,
        insights: [
          "Not enough spending data to detect habits yet.",
        ],
      );
    }

    double weekdayTotal = 0;
    int weekdayCount = 0;

    double weekendTotal = 0;
    int weekendCount = 0;

    final Map<String, double> categoryTotals = {};

    final now = DateTime.now();
    double recent7DaysTotal = 0;
    double previous7DaysTotal = 0;

    for (final t in expenses) {
      final date = t.createdAt;
      final amount = t.amount;

      categoryTotals[t.category] =
          (categoryTotals[t.category] ?? 0) + amount;

      final isWeekend = date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;

      if (isWeekend) {
        weekendTotal += amount;
        weekendCount++;
      } else {
        weekdayTotal += amount;
        weekdayCount++;
      }

      final difference = now.difference(date).inDays;

      if (difference >= 0 && difference < 7) {
        recent7DaysTotal += amount;
      } else if (difference >= 7 && difference < 14) {
        previous7DaysTotal += amount;
      }
    }

    final weekdayAverage = weekdayCount == 0
        ? 0.0
        : weekdayTotal / weekdayCount;

    final weekendAverage = weekendCount == 0
        ? 0.0
        : weekendTotal / weekendCount;

    String topCategory = "None";
    double topCategoryAmount = 0;

    categoryTotals.forEach((category, amount) {
      if (amount > topCategoryAmount) {
        topCategory = category;
        topCategoryAmount = amount;
      }
    });

    final spendsMoreOnWeekends =
        weekendAverage > weekdayAverage * 1.3 &&
        weekendAverage > 0;

    final recentSpendingIncreased =
        previous7DaysTotal > 0 &&
        recent7DaysTotal > previous7DaysTotal * 1.2;

    final List<String> insights = [];

    if (spendsMoreOnWeekends) {
      insights.add(
        "You tend to spend more on weekends than weekdays.",
      );
    } else {
      insights.add(
        "Your weekday and weekend spending are relatively balanced.",
      );
    }

    if (topCategory != "None") {
      insights.add(
        "Your largest spending category is $topCategory, with \$${topCategoryAmount.toStringAsFixed(0)} spent.",
      );
    }

    if (recentSpendingIncreased) {
      insights.add(
        "Your spending in the last 7 days is higher than the previous week.",
      );
    } else {
      insights.add(
        "Your recent spending is not significantly higher than last week.",
      );
    }

    return SpendingHabitResult(
      weekdayAverage: weekdayAverage,
      weekendAverage: weekendAverage,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      spendsMoreOnWeekends: spendsMoreOnWeekends,
      recentSpendingIncreased: recentSpendingIncreased,
      insights: insights,
    );
  }
}
