import 'package:flutter/foundation.dart';
import '../services/notification_settings_service.dart';

class NotificationSettingsProvider with ChangeNotifier {
  final NotificationSettingsService _service;
  Map<String, Map<String, bool>> _settings = {};
  bool _isLoading = false;
  String? _error;

  NotificationSettingsProvider(this._service);

  Map<String, Map<String, bool>> get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSettings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _settings = await _service.getNotificationSettings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSingleSetting(
    String category,
    String setting,
    bool value,
  ) async {
    final oldValue = _settings[category]![setting];
    _settings[category]![setting] = value;
    notifyListeners();

    try {
      await _service.updateNotificationSettings(_settings);
    } catch (e) {
      _settings[category]![setting] = oldValue!;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategorySettings(
    String category,
    bool value,
  ) async {
    final oldValues = Map<String, bool>.from(_settings[category]!);
    
    _settings[category]!.updateAll((_, __) => value);
    notifyListeners();

    try {
      await _service.updateNotificationSettings(_settings);
    } catch (e) {
      _settings[category] = oldValues;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAllSettings(bool value) async {
    final oldSettings = Map<String, Map<String, bool>>.from(_settings);
    
    for (var category in _settings.keys) {
      _settings[category]!.updateAll((_, __) => value);
    }
    notifyListeners();

    try {
      await _service.updateNotificationSettings(_settings);
    } catch (e) {
      _settings = oldSettings;
      notifyListeners();
      rethrow;
    }
  }
} 