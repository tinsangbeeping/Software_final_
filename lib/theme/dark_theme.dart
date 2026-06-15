import 'package:flutter/material.dart';

class DarkTheme {
  static ThemeData theme = ThemeData(
    brightness: Brightness.dark,

    scaffoldBackgroundColor:
        const Color(0xFF08162D),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BFA6),
      brightness: Brightness.dark,
    ),

    useMaterial3: true,
  );
}