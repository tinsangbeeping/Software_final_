import 'package:flutter/material.dart';

class AIInsightCard extends StatelessWidget {
  const AIInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),

        gradient: const LinearGradient(
          colors: [
            Color(0xFFDFF7F1),
            Color(0xFFECFFF9),
          ],
        ),
      ),

      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(
            "✨ AI Insights",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 16),

          Text("• Food accounts for 43% of spending."),

          SizedBox(height: 10),

          Text("• Weekend spending tends to be higher."),

          SizedBox(height: 10),

          Text("• You usually record expenses around 8 AM."),

          SizedBox(height: 20),

          Text(
            "Suggestion",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            "Allocate a separate entertainment budget.",
          ),

        ],
      ),
    );
  }
}