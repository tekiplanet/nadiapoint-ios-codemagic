import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_settings_service.dart';

class BiometricSettingsProvider with ChangeNotifier {
  final BiometricSettingsService _service;
  bool _isEnabled = false;
  bool _isAvailable = false;
  bool _isLoading = false;
  String? _error;
  List<BiometricType> _availableBiometrics = [];

  BiometricSettingsProvider(this._service) {
    // Check availability on creation
    checkAvailability();
  }

  bool get isEnabled => _isEnabled;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  Future<void> checkAvailability() async {
    try {
      _isLoading = true;
      notifyListeners();

      _isAvailable = await _service.isBiometricAvailable();
      _availableBiometrics = await _service.getAvailableBiometrics();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await checkAvailability();
      if (_isAvailable) {
        // Load both server status and check stored tokens
        final serverStatus = await _service.getBiometricStatus();
        final tokens = await _service.getBiometricTokens();
        
        // Only consider enabled if both server says yes and we have valid tokens
        _isEnabled = serverStatus && tokens['token'] != null;
      }
    } catch (e) {
      _error = e.toString();
      _isEnabled = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleBiometric() async {
    if (!_isAvailable) return false;

    try {
      final authenticated = await _service.authenticate();
      if (!authenticated) return false;

      final newStatus = !_isEnabled;
      await _service.updateBiometricStatus(newStatus);
      _isEnabled = newStatus;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
} 