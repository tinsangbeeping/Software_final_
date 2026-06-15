import 'package:flutter/material.dart';

enum InsightType { positive, warning, neutral }

class InsightModel {
  final IconData icon;
  final String title;
  final String description;
  final InsightType type;

  const InsightModel({
    required this.icon,
    required this.title,
    required this.description,
    required this.type,
  });
}
