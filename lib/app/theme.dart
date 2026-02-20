import 'package:flutter/material.dart';

class HandiTheme {
  static const Color primary = Color(0xFF1565C0);
  static const Color accent = Color(0xFF42A5F5);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);

  static const double tileSize = 160.0;
  static const double buttonHeight = 72.0;
  static const double iconSize = 48.0;
  static const double fontSize = 20.0;
  static const double fontSizeLarge = 24.0;
  static const double borderRadius = 16.0;
  static const double padding = 24.0;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: onPrimary,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            textStyle: const TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(fontSize: fontSize, color: textPrimary),
          bodyMedium: TextStyle(fontSize: 18, color: textSecondary),
        ),
      );
}
