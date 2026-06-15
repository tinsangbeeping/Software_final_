import 'dart:convert';

import '../../models/budget_model.dart';
import '../../models/saving_plan_model.dart';
import '../../models/transaction_model.dart';
import 'gemini_service.dart';

class WeeklyGoalReportResult {
  final String weeklySummary;
  final String goalProgress;
  final String spendingProblem;
  final String nextWeekAction;

  const WeeklyGoalReportResult({
    required this.weeklySummary,
    required this.goalProgress,
    required this.spendingProblem,
    required this.nextWeekAction,
  });

  factory WeeklyGoalReportResult.fromJson(Map<String, dynamic> json) {
    return WeeklyGoalReportResult(
      weeklySummary: json['weeklySummary']?.toString().trim() ?? '',
      goalProgress: json['goalProgress']?.toString().trim() ?? '',
      spendingProblem: json['spendingProblem']?.toString().trim() ?? '',
      nextWeekAction: json['nextWeekAction']?.toString().trim() ?? '',
    );
  }

  factory WeeklyGoalReportResult.fallback(String text) {
    return WeeklyGoalReportResult(
      weeklySummary: text.trim().isEmpty
          ? 'No weekly report available yet.'
          : text.trim(),
      goalProgress:
          'The AI response could not be separated automatically.',
      spendingProblem:
          'Review your highest spending category this week.',
      nextWeekAction:
          'Keep recording your transactions and follow your saving goal plan next week.',
    );
  }

  factory WeeklyGoalReportResult.noData() {
    return const WeeklyGoalReportResult(
      weeklySummary:
          'No expense transactions were recorded in the last 7 days.',
      goalProgress:
          'There is not enough weekly data to compare your spending with the saving goal yet.',
      spendingProblem:
          'No clear weekly spending problem was detected because there is not enough data.',
      nextWeekAction:
          'Record expenses every day this week so the agent can give a more accurate weekly report.',
    );
  }
}

class WeeklyReportService {
  final GeminiService gemini = GeminiService();

  String generateSummary(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return 'No transactions this week.';
    }

    String summary = '';

    for (final t in transactions) {
      summary +=
          '${_weekdayName(t.createdAt.weekday)} | '
          '${t.category} | '
          '\$${t.amount.toStringAsFixed(2)} | '
          '${t.description}\n';
    }

    return summary;
  }

  Future<WeeklyGoalReportResult> generateGoalReport({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    SavingPlanModel? savingPlan,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 6));

    final weeklyExpenses = transactions.where((transaction) {
      final isExpense = transaction.type.toLowerCase() == 'expense';
      final transactionDay = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );

      return isExpense &&
          !transactionDay.isBefore(startDate) &&
          !transactionDay.isAfter(today);
    }).toList();

    if (weeklyExpenses.isEmpty) {
      return WeeklyGoalReportResult.noData();
    }

    double weeklyTotal = 0;
    final Map<String, double> categoryTotals = {};
    final Map<String, double> dailyTotals = {};

    for (final transaction in weeklyExpenses) {
      weeklyTotal += transaction.amount;

      categoryTotals[transaction.category] =
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;

      final date = transaction.createdAt;
      final dateKey = '${date.month}/${date.day}';
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + transaction.amount;
    }

    String topCategory = 'None';
    double topCategoryAmount = 0;

    categoryTotals.forEach((category, amount) {
      if (amount > topCategoryAmount) {
        topCategory = category;
        topCategoryAmount = amount;
      }
    });

    String categoryText = '';
    categoryTotals.forEach((category, amount) {
      categoryText += '$category: \$${amount.toStringAsFixed(2)}\n';
    });

    String dailyText = '';
    dailyTotals.forEach((day, amount) {
      dailyText += '$day: \$${amount.toStringAsFixed(2)}\n';
    });

    double totalBudget = 0;
    String budgetText = '';

    for (final budget in budgets) {
      totalBudget += budget.limit;
      budgetText += '${budget.category}: \$${budget.limit.toStringAsFixed(2)}\n';
    }

    final weeklyBudgetEstimate = totalBudget <= 0 ? 0 : totalBudget / 4;
    final weeklyBudgetUsedPercent = weeklyBudgetEstimate <= 0
        ? 0
        : weeklyTotal / weeklyBudgetEstimate * 100;

    final prompt = '''
You are a proactive AI financial agent.

Create a Weekly Goal Report for the user. The report must focus on whether the user is moving toward the current saving goal plan.

Last 7 days total spending:
\$${weeklyTotal.toStringAsFixed(2)}

Top category this week:
$topCategory \$${topCategoryAmount.toStringAsFixed(2)}

Category breakdown this week:
$categoryText

Daily spending this week:
$dailyText

Monthly budget total:
\$${totalBudget.toStringAsFixed(2)}

Estimated weekly budget:
\$${weeklyBudgetEstimate.toStringAsFixed(2)}

Weekly budget used:
${weeklyBudgetUsedPercent.toStringAsFixed(1)}%

Budgets:
$budgetText

Current saving goal plan:
${savingPlan?.toPromptText() ?? 'No saving goal plan is currently set.'}

Return ONLY valid JSON in this exact structure:
{
  "weeklySummary": "short summary of this week's spending",
  "goalProgress": "explain whether this week supports or hurts the saving goal",
  "spendingProblem": "identify the biggest issue this week, preferably with category or amount",
  "nextWeekAction": "one concrete action plan for next week"
}

Rules:
- Do not wrap the JSON in markdown code fences.
- Be specific and practical.
- If a saving goal plan exists, make it the main focus.
- If there is no saving goal plan, ask the user to create one in AI Chat.
- Keep each JSON value concise.
''';

    final response = await gemini.sendMessage(prompt);

    try {
      final cleaned = response
          .replaceAll('```json', '')
          .replaceAll('```JSON', '')
          .replaceAll('```', '')
          .trim();

      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      return WeeklyGoalReportResult.fromJson(decoded);
    } catch (_) {
      return WeeklyGoalReportResult.fallback(response);
    }
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }
}
