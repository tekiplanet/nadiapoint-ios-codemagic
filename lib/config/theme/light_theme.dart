import 'package:flutter/material.dart';
import 'colors.dart';

class LightTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: SafeJetColors.lightBackground,
    primaryColor: SafeJetColors.primaryAccent,
    colorScheme: const ColorScheme.light(
      primary: SafeJetColors.primaryAccent,
      secondary: SafeJetColors.secondaryHighlight,
      background: SafeJetColors.lightBackground,
      surface: SafeJetColors.lightSecondaryBackground,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: SafeJetColors.lightText,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: SafeJetColors.lightText,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: SafeJetColors.lightText,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: SafeJetColors.lightTextSecondary,
        fontSize: 14,
      ),
    ),
    cardTheme: CardThemeData(
      color: SafeJetColors.lightSecondaryBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
} 