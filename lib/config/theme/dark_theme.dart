import 'package:flutter/material.dart';
import 'colors.dart';

class DarkTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SafeJetColors.primaryBackground,
    primaryColor: SafeJetColors.primaryAccent,
    colorScheme: const ColorScheme.dark(
      primary: SafeJetColors.primaryAccent,
      secondary: SafeJetColors.secondaryHighlight,
      background: SafeJetColors.primaryBackground,
      surface: SafeJetColors.secondaryBackground,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Colors.white,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Colors.grey,
        fontSize: 14,
      ),
    ),
    cardTheme: CardThemeData(
      color: SafeJetColors.secondaryBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
} 