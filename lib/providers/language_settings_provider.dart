import 'package:flutter/foundation.dart';
import '../services/language_settings_service.dart';

class LanguageSettingsProvider with ChangeNotifier {
  final LanguageSettingsService _service;
  String _currentLanguage = 'en';
  bool _isLoading = false;
  String? _error;

  LanguageSettingsProvider(this._service);

  String get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLanguage() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentLanguage = await _service.getCurrentLanguage();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLanguage(String language) async {
    final oldLanguage = _currentLanguage;
    
    try {
      // Optimistic update
      _currentLanguage = language;
      notifyListeners();

      await _service.updateLanguage(language);
    } catch (e) {
      // Revert on error
      _currentLanguage = oldLanguage;
      notifyListeners();
      rethrow;
    }
  }
} 