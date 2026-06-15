import 'package:flutter/material.dart';

import '../../core/services/financial_insight_service.dart';
import '../../core/services/habit_analyzer_service.dart';
import '../../core/services/weekly_report_service.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/saving_plan_repository.dart';

class AIFinancialInsightPage extends StatefulWidget {
  const AIFinancialInsightPage({super.key});

  @override
  State<AIFinancialInsightPage> createState() => _AIFinancialInsightPageState();
}

class _AIFinancialInsightPageState extends State<AIFinancialInsightPage> {
  final FinancialInsightService insightService = FinancialInsightService();
  final HabitAnalyzerService habitAnalyzerService = HabitAnalyzerService();
  final WeeklyReportService weeklyReportService = WeeklyReportService();
  final TransactionRepository transactionRepo = TransactionRepository();
  final BudgetRepository budgetRepo = BudgetRepository();
  final SavingPlanRepository savingPlanRepo = SavingPlanRepository();

  late final Future<_InsightPageData> insightFuture = loadInsight();

  Future<_InsightPageData> loadInsight() async {
    final transactions = await transactionRepo.fetchTransactions();
    final budgets = await budgetRepo.fetchBudgets();
    final savingPlan = await savingPlanRepo.fetchCurrentPlan();

    final habitResult =
        habitAnalyzerService.analyzeSpendingHabits(transactions);

    final insight = await insightService.generateInsight(
      transactions: transactions,
      budgets: budgets,
      habitSummary: habitResult.toPromptText(),
      savingPlan: savingPlan,
    );

    final weeklyReport = await weeklyReportService.generateGoalReport(
      transactions: transactions,
      budgets: budgets,
      savingPlan: savingPlan,
    );

    return _InsightPageData(
      insight: insight,
      weeklyReport: weeklyReport,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Financial Insight"),
      ),
      body: SafeArea(
        child: FutureBuilder<_InsightPageData>(
          future: insightFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "Failed to generate AI financial insight.\n${snapshot.error}",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final data = snapshot.data;

            if (data == null) {
              return const Center(
                child: Text("No insight available yet."),
              );
            }

            final insight = data.insight;
            final weeklyReport = data.weeklyReport;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "✨ AI Financial Insight",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Personalized suggestions based on your transactions, budget, habits, and saving goal plan.",
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InsightSectionCard(
                    icon: Icons.auto_awesome,
                    title: "Quick Summary",
                    content: insight.quickSummary,
                  ),
                  const SizedBox(height: 16),
                  _InsightSectionCard(
                    icon: Icons.psychology_alt_outlined,
                    title: "Spending Habits Detected",
                    content: insight.spendingHabits,
                  ),
                  const SizedBox(height: 16),
                  _InsightSectionCard(
                    icon: Icons.warning_amber_rounded,
                    title: "Budget Warning",
                    content: insight.budgetWarning,
                  ),
                  const SizedBox(height: 16),
                  _InsightSectionCard(
                    icon: Icons.checklist_rounded,
                    title: "Three Actionable Next Steps",
                    content: insight.actionableNextSteps,
                  ),
                  const SizedBox(height: 16),
                  _WeeklyReportCard(
                    report: weeklyReport,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InsightPageData {
  final FinancialInsightResult insight;
  final WeeklyGoalReportResult weeklyReport;

  const _InsightPageData({
    required this.insight,
    required this.weeklyReport,
  });
}

class _InsightSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InsightSectionCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF7F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF00BFA5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content.isEmpty ? "No insight available for this section." : content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyReportCard extends StatelessWidget {
  final WeeklyGoalReportResult report;

  const _WeeklyReportCard({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2D9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFE59B00),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Weekly Goal Report",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WeeklyReportItem(
            title: "This week",
            content: report.weeklySummary,
          ),
          const SizedBox(height: 12),
          _WeeklyReportItem(
            title: "Goal progress",
            content: report.goalProgress,
          ),
          const SizedBox(height: 12),
          _WeeklyReportItem(
            title: "Biggest issue",
            content: report.spendingProblem,
          ),
          const SizedBox(height: 12),
          _WeeklyReportItem(
            title: "Next week action",
            content: report.nextWeekAction,
          ),
        ],
      ),
    );
  }
}

class _WeeklyReportItem extends StatelessWidget {
  final String title;
  final String content;

  const _WeeklyReportItem({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00BFA5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content.isEmpty ? "No report available for this section." : content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
