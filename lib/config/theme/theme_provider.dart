import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dark_theme.dart';
import 'light_theme.dart';
import 'colors.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  SharedPreferences? _prefs;
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;
  ThemeData get theme => _isDarkMode ? DarkTheme.theme : LightTheme.theme;
  Color get backgroundColor => _isDarkMode 
    ? SafeJetColors.primaryBackground 
    : SafeJetColors.lightBackground;

  void init(SharedPreferences prefs) {
    _prefs = prefs;
    _isDarkMode = _prefs?.getBool(_themeKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    try {
      await _prefs?.setBool(_themeKey, _isDarkMode);
      // Use a post-frame callback to notify listeners after the current frame is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error saving theme mode');
    }
  }

  bool get isDark => _isDarkMode == ThemeMode.dark;
} 