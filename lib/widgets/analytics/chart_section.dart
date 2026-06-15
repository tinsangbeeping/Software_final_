import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../core/services/budget_pacing_service.dart';
import 'budget_chart.dart';
import 'category_chart.dart';
import 'transaction_list_tab.dart';

class ChartSection extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final List<TransactionModel> transactions;
  final List<CategoryPacing> pacingData;

  const ChartSection({
    super.key,
    required this.categoryTotals,
    required this.transactions,
    this.pacingData = const [],
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            TabBar(
              labelColor: const Color(0xFF00BFA6),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF00BFA6),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: const [
                Tab(text: "Budget vs Spent"),
                Tab(text: "Category"),
                Tab(text: "Transactions"),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: TabBarView(
                children: [
                  BudgetChart(pacingData: pacingData),
                  CategoryChart(categoryTotals: categoryTotals),
                  TransactionListTab(transactions: transactions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
