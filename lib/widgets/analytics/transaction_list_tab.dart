import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';

class TransactionListTab extends StatefulWidget {
  final List<TransactionModel> transactions;

  const TransactionListTab({super.key, required this.transactions});

  @override
  State<TransactionListTab> createState() => _TransactionListTabState();
}

class _TransactionListTabState extends State<TransactionListTab> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = widget.transactions
        .where((t) => t.createdAt.isAfter(weekAgo))
        .toList();
    final total = recent.fold<double>(0, (sum, t) => sum + t.amount);

    if (recent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("No recent transactions",
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Last 7 Days summary (clickable) ──
            GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Last 7 Days",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          "${recent.length} transaction${recent.length > 1 ? 's' : ''} · \$${total.toStringAsFixed(2)}",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "\$${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_less,
                        color: Colors.grey[400], size: 24),
                  ),
                ],
              ),
            ),
          ),

          // ── Transaction items (expandable) ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  for (final t in recent) ...[
                    _TransactionRow(
                      transaction: t,
                      onDelete: () => _deleteTransaction(t),
                    ),
                    if (t != recent.last)
                      Divider(height: 1, color: Colors.grey[200]),
                  ],
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Transaction?"),
        content: Text(
            "Remove \"${transaction.description}\" (\$${transaction.amount.toStringAsFixed(2)})?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TransactionRepository().deleteTransaction(transaction.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Transaction deleted"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to delete: $e"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    }
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;

  const _TransactionRow({required this.transaction, required this.onDelete});

  IconData _icon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('food') || c.contains('lunch') || c.contains('dinner'))
      return Icons.restaurant_rounded;
    if (c.contains('transport')) return Icons.directions_car_rounded;
    if (c.contains('shopping')) return Icons.shopping_bag_rounded;
    if (c.contains('entertainment')) return Icons.movie_rounded;
    if (c.contains('bills')) return Icons.receipt_long_rounded;
    if (c.contains('health')) return Icons.local_hospital_rounded;
    return Icons.attach_money_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon(transaction.category),
                color: Colors.deepPurple, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  "${transaction.category} · ${DateFormat('MMM d').format(transaction.createdAt)}",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            "-\$${transaction.amount.toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child:
                  Icon(Icons.delete_outline, color: Colors.grey.shade600, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
