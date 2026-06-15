import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {

  final String title;

  final String category;

  final String date;

  final double amount;

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: ListTile(

        leading: CircleAvatar(
          backgroundColor: Colors.green[50],

          child: const Icon(
            Icons.fastfood,
            color: Color(0xFF00BFA6),
          ),
        ),

        title: Text(title),

        subtitle: Text(
          "$category\n$date",
        ),

        trailing: Text(
          "-\$${amount.toStringAsFixed(2)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}