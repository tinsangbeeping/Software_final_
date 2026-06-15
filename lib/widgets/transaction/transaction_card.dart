import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';

class TransactionCard extends StatelessWidget {

  final TransactionModel transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 2,

      child: ListTile(

        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,

          child: const Icon(
            Icons.attach_money,
            color: Colors.teal,
          ),
        ),

        title: Text(
          transaction.description,
        ),

        subtitle: Text(
          transaction.category,
        ),

        trailing: Text(
          "\$${transaction.amount}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}