import 'dart:convert';

import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import '../../models/saving_plan_model.dart';
import 'gemini_service.dart';

class FinancialInsightResult {
  final String quickSummary;
  final String spendingHabits;
  final String budgetWarning;
  final String actionableNextSteps;

  const FinancialInsightResult({
    required this.quickSummary,
    required this.spendingHabits,
    required this.budgetWarning,
    required this.actionableNextSteps,
  });

  factory FinancialInsightResult.fromJson(Map<String, dynamic> json) {
    return FinancialInsightResult(
      quickSummary: json["quickSummary"]?.toString().trim() ?? "",
      spendingHabits: json["spendingHabits"]?.toString().trim() ?? "",
      budgetWarning: json["budgetWarning"]?.toString().trim() ?? "",
      actionableNextSteps:
          json["actionableNextSteps"]?.toString().trim() ?? "",
    );
  }

  factory FinancialInsightResult.fallback(String text) {
    return FinancialInsightResult(
      quickSummary: text.trim().isEmpty
          ? "No insight available yet."
          : text.trim(),
      spendingHabits:
          "The AI response could not be separated automatically.",
      budgetWarning:
          "Please check your monthly spending and budget progress.",
      actionableNextSteps:
          "Review your recent transactions and adjust your spending plan if needed.",
    );
  }
}

class FinancialInsightService {
  final GeminiService gemini = GeminiService();

  Future<FinancialInsightResult> generateInsight({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    String? habitSummary,
    SavingPlanModel? savingPlan,
  }) async {
    double totalExpense = 0;
    double totalBudget = 0;

    final Map<String, double> categoryTotals = {};

    for (final t in transactions) {
      if (t.type == "expense") {
        totalExpense += t.amount;

        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0) + t.amount;
      }
    }

    String categoryText = "";

    categoryTotals.forEach((key, value) {
      categoryText += "$key : \$${value.toStringAsFixed(2)}\n";
    });

    String budgetText = "";

    for (final budget in budgets) {
      totalBudget += budget.limit;
      budgetText +=
          "${budget.category}: \$${budget.limit.toStringAsFixed(2)}\n";
    }

    final usedPercent = totalBudget == 0
        ? 0
        : (totalExpense / totalBudget * 100);

    String warningText;

    if (totalBudget == 0) {
      warningText =
          "No budget has been set yet. Ask the user to set a budget first.";
    } else if (usedPercent >= 100) {
      warningText =
          "The user has exceeded the budget. Give an urgent but friendly warning.";
    } else if (usedPercent >= 80) {
      warningText =
          "The user is close to overspending. Give a proactive warning before they exceed the budget.";
    } else {
      warningText =
          "The user is still within budget. Encourage them to keep the habit.";
    }

    final prompt = """
You are a proactive AI financial agent.

Your job is not only to describe charts. You must help the user decide what to do next.

Monthly spending:
\$${totalExpense.toStringAsFixed(2)}

Total budget:
\$${totalBudget.toStringAsFixed(2)}

Budget used:
${usedPercent.toStringAsFixed(1)}%

Budget warning:
$warningText

Category breakdown:
$categoryText

Budgets:
$budgetText

Detected spending habits:
${habitSummary ?? "No habit analysis available."}

Current saving goal plan:
${savingPlan?.toPromptText() ?? "No saving goal plan is currently set."}

Return ONLY valid JSON in this exact structure:
{
  "quickSummary": "one short paragraph",
  "spendingHabits": "one short paragraph or 2-3 bullet-like sentences",
  "budgetWarning": "one short paragraph",
  "actionableNextSteps": "three numbered practical next steps"
}

Rules:
- Do not wrap the JSON in markdown code fences.
- Be specific and practical.
- If a saving goal plan exists, make that plan the main focus of the insight.
- Mention whether the user's current spending supports or hurts the saving goal.
- Mention exact categories or amounts when useful.
- Do not only say "track your spending".
- Keep each JSON value concise.
""";

    final response = await gemini.analyzeSpending(prompt);

    try {
      final cleaned = response
          .replaceAll("```json", "")
          .replaceAll("```JSON", "")
          .replaceAll("```", "")
          .trim();

      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      return FinancialInsightResult.fromJson(decoded);
    } catch (_) {
      return FinancialInsightResult.fallback(response);
    }
  }
}
