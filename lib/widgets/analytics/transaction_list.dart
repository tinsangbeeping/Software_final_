import 'package:flutter/material.dart';

import 'transaction_tile.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {

    return Column(
      children: const [

        TransactionTile(
          title: "McDonald's",
          category: "Food",
          date: "June 13",
          amount: 15,
        ),

        TransactionTile(
          title: "Coffee",
          category: "Food",
          date: "June 12",
          amount: 10,
        ),

        TransactionTile(
          title: "Bus Fare",
          category: "Transport",
          date: "June 11",
          amount: 5,
        ),

      ],
    );
  }
}