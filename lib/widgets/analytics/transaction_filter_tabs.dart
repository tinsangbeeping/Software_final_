import 'package:flutter/material.dart';

class TransactionFilterTabs extends StatelessWidget {

  final int selectedIndex;

  final Function(int) onTap;

  const TransactionFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    const labels = [
      "Today",
      "7 Days",
      "30 Days",
      "Custom",
    ];

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,

      children: List.generate(
        labels.length,
        (index) {

          final selected =
              index == selectedIndex;

          return GestureDetector(
            onTap: () => onTap(index),

            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),

              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF00BFA6)
                    : Colors.white,

                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Text(
                labels[index],
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}