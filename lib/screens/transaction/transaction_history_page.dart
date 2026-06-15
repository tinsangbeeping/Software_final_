import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/transaction_repository.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Records'),
          backgroundColor: const Color(0xFF00BFA6),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Transactions'),
              Tab(text: 'Budgets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TransactionsTab(),
            _BudgetsTab(),
          ],
        ),
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    final repository = TransactionRepository();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.getTransactions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            subtitle: 'Start recording expenses from AI Chat.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final transaction = TransactionModel.fromMap(
              docs[index].data(),
              docId: docs[index].id,
            );

            return _TransactionTile(
              transaction: transaction,
              onDelete: () async {
                final confirmed = await _confirmDelete(
                  context,
                  title: 'Delete Transaction',
                  message:
                      'Remove "${transaction.description}" (\$${transaction.amount.toStringAsFixed(2)})?',
                );

                if (confirmed) {
                  await repository.deleteTransaction(transaction.id);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _BudgetsTab extends StatelessWidget {
  const _BudgetsTab();

  @override
  Widget build(BuildContext context) {
    final repository = BudgetRepository();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.getBudgets(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final budgets = snapshot.data!.docs
            .map((doc) => BudgetModel.fromMap(doc.data(), docId: doc.id))
            .toList();

        if (budgets.isEmpty) {
          return const _EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No budgets yet',
            subtitle: 'Tell AI Chat to create or adjust a budget.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            return _BudgetTile(
              budget: budget,
              onDelete: () async {
                final confirmed = await _confirmDelete(
                  context,
                  title: 'Delete Budget',
                  message:
                      'Remove ${budget.category} budget (\$${budget.limit.toStringAsFixed(0)})?',
                );

                if (confirmed) {
                  await repository.deleteBudget(budget.id);
                }
              },
            );
          },
        );
      },
    );
  }
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  return result == true;
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type.toLowerCase() != 'income';
    final amountColor = isExpense ? Colors.red.shade400 : Colors.green.shade600;
    final prefix = isExpense ? '-' : '+';

    return _RecordCard(
      icon: Icons.receipt_long_rounded,
      title: transaction.description,
      subtitle:
          '${transaction.category} · ${DateFormat('MMM d').format(transaction.createdAt)}',
      trailing: '$prefix\$${transaction.amount.toStringAsFixed(2)}',
      trailingColor: amountColor,
      onDelete: onDelete,
    );
  }
}

class _BudgetTile extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onDelete;

  const _BudgetTile({
    required this.budget,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final monthText = budget.month == 0 || budget.year == 0
        ? 'All months'
        : '${budget.month}/${budget.year}';

    return _RecordCard(
      icon: Icons.account_balance_wallet_rounded,
      title: budget.category,
      subtitle: monthText,
      trailing: '\$${budget.limit.toStringAsFixed(0)}',
      trailingColor: const Color(0xFF00BFA6),
      onDelete: onDelete,
    );
  }
}

class _RecordCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF00BFA6), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              trailing,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: trailingColor,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
