import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/budget_repository.dart';
import '../../core/services/insights_service.dart';
import '../../core/services/budget_pacing_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/analytics/overview_card.dart';
import '../../widgets/analytics/monthly_progress_card.dart';
import '../../widgets/analytics/insights_section.dart';
import '../../widgets/analytics/chart_section.dart';
import '../../widgets/analytics/date_range_selector.dart';
import '../../widgets/analytics/overspending_warning_card.dart';
import 'ai_financial_insight_page.dart';
import 'saving_goal_plan_page.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedPreset = 'This Month';
  DateTimeRange? _customRange;
  final BudgetRepository _budgetRepository = BudgetRepository();
  final DateTime _now = DateTime.now();

  DateTimeRange _getSelectedRange() {
    switch (_selectedPreset) {
      case 'This Week':
        final daysFromMonday = _now.weekday - 1;
        final start = DateTime(_now.year, _now.month, _now.day).subtract(Duration(days: daysFromMonday));
        return DateTimeRange(start: start, end: _now);

      case 'This Month':
        return DateTimeRange(
          start: DateTime(_now.year, _now.month, 1),
          end: _now,
        );

      case 'This Year':
        return DateTimeRange(
          start: DateTime(_now.year, 1, 1),
          end: _now,
        );

      case 'Custom':
        return _customRange ?? DateTimeRange(
          start: DateTime(_now.year, _now.month, 1),
          end: _now,
        );

      case 'All Time':
      default:
        return DateTimeRange(
          start: DateTime(2020),
          end: _now,
        );
    }
  }


  String _getSelectedRangeLabel() {
    if (_selectedPreset == 'Custom' && _customRange != null) {
      return '${_customRange!.start.month}/${_customRange!.start.day} - ${_customRange!.end.month}/${_customRange!.end.day}';
    }

    return _selectedPreset;
  }
  @override
  Widget build(BuildContext context) {
    final repository = TransactionRepository();
    final insightsService = InsightsService();
    final range = _getSelectedRange();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: repository.getTransactions(),
          builder: (context, snapshot) {
            final Map<String, double> categoryTotals = {};
            final List<TransactionModel> allTransactions = [];
            double totalSpent = 0;
            double todaySpent = 0;

            if (snapshot.hasData) {
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final transaction = TransactionModel.fromMap(data, docId: doc.id);

                if (transaction.createdAt.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
                    transaction.createdAt.isBefore(range.end.add(const Duration(days: 1)))) {
                  allTransactions.add(transaction);

                  if (transaction.type != "income") {
                    categoryTotals[transaction.category] =
                        (categoryTotals[transaction.category] ?? 0) + transaction.amount;

                    totalSpent += transaction.amount;
                    if (transaction.createdAt.year == _now.year &&
                        transaction.createdAt.month == _now.month &&
                        transaction.createdAt.day == _now.day) {
                      todaySpent += transaction.amount;
                    }
                  }
                }
              }
            }

            // StreamBuilder for budgets — reacts to Firestore changes in real-time
            return StreamBuilder<List<BudgetModel>>(
              stream: _budgetRepository.streamBudgetsForMonth(_now.month, _now.year),
              builder: (context, budgetSnapshot) {
                final monthlyBudgets = budgetSnapshot.data ?? [];

                // Use only this month's budgets for the dashboard.
                // Do not fall back to legacy/all-month budget records; otherwise
                // a deleted current-month budget can still appear as Budget Limit.
                return _buildContent(
                  context,
                  monthlyBudgets,
                  allTransactions,
                  categoryTotals,
                  totalSpent,
                  todaySpent,
                  insightsService,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<BudgetModel> budgets,
    List<TransactionModel> allTransactions,
    Map<String, double> categoryTotals,
    double totalSpent,
    double todaySpent,
    InsightsService insightsService,
  ) {
    final budgetLimit = budgets.fold<double>(0, (sum, b) => sum + b.limit);

    final pacingService = BudgetPacingService();
    final pacingData = pacingService.computePacing(
      budgets,
      allTransactions.where((t) => t.type != 'income').toList(),
    );

    final insights = insightsService.generateInsights(allTransactions, budgets, pacingData: pacingData);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dark navy header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B2447), Color(0xFF19376D)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Builder(
              builder: (context) {
                final loc = AppLocalizations.of(context);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.analytics, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(loc.financialInsights, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15)),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── Overview Card ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OverviewCard(monthlySpent: totalSpent, todaySpent: todaySpent, budgetLimit: budgetLimit),
          ),

          const SizedBox(height: 16),

          // ── Monthly Progress Card ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MonthlyProgressCard(totalSpent: totalSpent, budgetLimit: budgetLimit),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OverspendingWarningCard(
              monthlySpent: totalSpent,
              budgetLimit: budgetLimit,
              categoryTotals: categoryTotals,
            ),
          ),

          if (budgetLimit > 0 && totalSpent / budgetLimit >= 0.8)
            const SizedBox(height: 16),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ActionCard(
              icon: Icons.auto_awesome_rounded,
              title: "AI Financial Insight",
              subtitle: "Goal-aware advice based on your spending, budgets, and saving plan.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIFinancialInsightPage(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ActionCard(
              icon: Icons.flag_rounded,
              title: "Saving Goal Plan",
              subtitle: "View your current goal plan or create one from AI Chat.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SavingGoalPlanPage(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Insights Section ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InsightsSection(insights: insights),
          ),

          const SizedBox(height: 20),

          // ── Date Range Filter ──
          DateRangeSelector(
            selected: _selectedPreset,
            customRange: _customRange,
            onPresetSelected: (preset) => setState(() {
              _selectedPreset = preset;
              if (preset != 'Custom') _customRange = null;
            }),
            onCustomRangeSelected: (range) => setState(() {
              _selectedPreset = 'Custom';
              _customRange = range;
            }),
          ),

          const SizedBox(height: 20),

          // ── Chart Section ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ChartSection(
              categoryTotals: categoryTotals,
              transactions: allTransactions,
              pacingData: pacingData,
              transactionRangeLabel: _getSelectedRangeLabel(),
            ),
          ),
        ],
      ),
    );
  }


}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF7F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00BFA6),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
