import 'package:flutter/material.dart';

class AppColors {
  static const revenue = Color(0xFF0D9488);   // Teal
  static const expense = Color(0xFFE53E3E);   // Red
  static const savings = Color(0xFFF6AD55);   // Amber
  static const balance = Color(0xFF4299E1);   // Sky blue
  static const excellent = Color(0xFF48BB78); // Green
  static const warning = Color(0xFFED8936);   // Orange
  static const danger = Color(0xFFFC8181);    // Light red
}

class AppTheme {
  static const _seed = Color(0xFF1A56DB);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
      );
}
