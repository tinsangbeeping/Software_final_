import 'package:flutter/material.dart';

class LightTheme {

  static ThemeData theme = ThemeData(

    brightness: Brightness.light,

    scaffoldBackgroundColor:
        const Color(0xFFF5F7FA),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BFA6),
      brightness: Brightness.light,
    ),

    useMaterial3: true,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),

  );

}