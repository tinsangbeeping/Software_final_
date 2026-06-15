import 'package:flutter/material.dart';

class QuickActionChip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const QuickActionChip({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: onTap != null
                ? const Color(0xFF00BFA6).withOpacity(0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: onTap != null ? const Color(0xFF00BFA6) : Colors.grey,
          ),
        ),
      ),
    );
  }
}
