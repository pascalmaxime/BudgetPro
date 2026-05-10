import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF1E88E5);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        fontFamily: 'Roboto',
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      );
}
