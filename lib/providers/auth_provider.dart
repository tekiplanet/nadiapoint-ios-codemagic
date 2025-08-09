import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/social_auth_service.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../services/biometric_settings_service.dart';
import 'package:flutter/widgets.dart'; // Added for navigatorKey
import 'package:provider/provider.dart'; // Added for Provider
import '../providers/notification_provider.dart'; // Added for NotificationProvider
import '../main.dart'; // Added for navigatorKey
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../config/env/env_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SocialAuthService _socialAuthService = SocialAuthService();
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;
  BuildContext? _context;
  User? _user;
  Timer? _refreshTimer;
  Timer? _tokenRefreshTimer;
  DateTime? _tokenExpiryTime;
  String? _lastVerificationToken;

  AuthProvider() {
    // Check auth status and start refresh timer on startup
    checkAuthStatus().then((_) {
      if (_isLoggedIn) {
        _startPeriodicRefresh();
        _scheduleTokenRefresh(); // Add this line to schedule initial token refresh
      }
    });
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel(); // Cancel existing timer if any
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isLoggedIn) {
        checkAuthStatus();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthenticated => _isLoggedIn; // Alias for isLoggedIn
  String? get error => _error;
  User? get user => _user;

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> handleSessionExpiration() async {
    print('Handling session expiration...');
    await logout();
    if (_context != null && _context!.mounted) {
      Navigator.of(_context!).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      // Debug log: print raw user JSON after login
      print('DEBUG: Raw user JSON after login: \\n' +
          json.encode(response['user']));

      _isLoading = false;
      notifyListeners();

      // If 2FA is required, don't store tokens yet
      if (response['requires2FA'] == true) {
        return response;
      }

      // Store tokens
      await _authService.storage
          .write(key: 'accessToken', value: response['accessToken']);
      await _authService.storage
          .write(key: 'refreshToken', value: response['refreshToken']);

      // Store for biometric if enabled (with error handling)
      try {
        final biometricService = BiometricSettingsService();
        final biometricEnabled = await biometricService.getBiometricStatus();
        if (biometricEnabled) {
          print('Storing tokens for biometric auth...');
          await biometricService.storeBiometricTokens(
            response['accessToken'],
            response['refreshToken'],
          );
        }
      } catch (e) {
        print('Error handling biometric storage');
      }

      // Store user data only if 2FA is not required or after 2FA verification
      await _authService.storage
          .write(key: 'user', value: json.encode(response['user']));

      _user = User.fromJson(response['user']);
      // Debug log: print parsed User object after login
      print('DEBUG: Parsed User object after login: emailVerified=' +
          _user!.emailVerified.toString());

      // Store pendingUserId if email is not verified
      if (_user != null && _user!.emailVerified == false) {
        await _authService.storage
            .write(key: 'pendingUserId', value: _user!.id);
        print('DEBUG: Stored pendingUserId after login:  [33m${_user!.id} [0m');
      }

      _startPeriodicRefresh(); // Start refresh timer after login
      notifyListeners();

      // Track token expiry
      _updateTokenExpiry(response['accessToken']);

      // Register device for push notifications after successful login
      try {
        await _registerDeviceForNotifications();
        print('Device registered for notifications after login');
      } catch (e) {
        print('Error registering device for notifications: $e');
      }

      // Initialize notification provider for the new user
      try {
        if (navigatorKey.currentContext != null) {
          final notificationProvider = Provider.of<NotificationProvider>(
              navigatorKey.currentContext!,
              listen: false);
          await notificationProvider.initialize();
          await notificationProvider.fetchNotifications();
          print('Notification provider initialized for new user');
        }
      } catch (e) {
        print('Error initializing notification provider: $e');
      }

      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      print('Starting logout...');
      _refreshTimer?.cancel();
      _tokenRefreshTimer?.cancel();

      // Deregister device for push notifications before logout
      try {
        await _deregisterDeviceForNotifications();
        print('Device deregistered for notifications during logout');
      } catch (e) {
        print('Error deregistering device for notifications: $e');
      }

      // Dispose notification socket and clear notifications
      try {
        // Get notification provider from the global navigator context
        if (navigatorKey.currentContext != null) {
          final notificationProvider = Provider.of<NotificationProvider>(
              navigatorKey.currentContext!,
              listen: false);
          notificationProvider.disposeSocket();
          print('Notification socket disposed during logout');
        }
      } catch (e) {
        print('Error disposing notification socket during logout: $e');
      }

      // Only clear auth tokens, not biometric tokens
      await _authService.storage.delete(key: 'accessToken');
      await _authService.storage.delete(key: 'refreshToken');
      await _authService.storage.delete(key: 'user');

      _isLoggedIn = false;
      _user = null;
      _error = null;

      print('Logout complete - auth tokens cleared');
      notifyListeners();
    } catch (e) {
      print('Error during logout');
      rethrow;
    }
  }

  // Register device for push notifications
  Future<void> _registerDeviceForNotifications() async {
    try {
      final storage = const FlutterSecureStorage();
      final jwt = await storage.read(key: 'accessToken');
      if (jwt == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final apiBase = EnvConfig.apiUrl;
      final url = Uri.parse('$apiBase/user-devices/register');
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'web';

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200) {
        print('Device registered for notifications successfully');
      } else {
        print('Failed to register device: ${response.body}');
      }
    } catch (e) {
      print('Error registering device for notifications: $e');
    }
  }

  // Deregister device for push notifications
  Future<void> _deregisterDeviceForNotifications() async {
    try {
      final storage = const FlutterSecureStorage();
      final jwt = await storage.read(key: 'accessToken');
      if (jwt == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final apiBase = EnvConfig.apiUrl;
      final url = Uri.parse('$apiBase/user-devices/deregister');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print('Device deregistered for notifications successfully');
      } else {
        print('Failed to deregister device: ${response.body}');
      }
    } catch (e) {
      print('Error deregistering device for notifications: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    print('AuthProvider: checking auth status...');
    try {
      _isLoading = true;
      notifyListeners();

      final token = await _authService.storage.read(key: 'accessToken');
      print('[AuthProvider] checkAuthStatus: token=$token');
      final userJson = await _authService.storage.read(key: 'user');
      print('[AuthProvider] checkAuthStatus: userJson=$userJson');

      if (token != null) {
        try {
          final freshUserData = await _authService.getCurrentUser();
          // Debug log: print raw user JSON after loading from storage/server
          print(
              'DEBUG: Raw user JSON after app relaunch: \n${json.encode(freshUserData)}');
          _user = User.fromJson(freshUserData);
          // Debug log: print parsed User object after app relaunch
          print(
              'DEBUG: Parsed User object after app relaunch: emailVerified=${_user!.emailVerified}');
          _isLoggedIn = true;
          print(
              '[AuthProvider] checkAuthStatus: _isLoggedIn=$_isLoggedIn, _user=$_user');
          _updateTokenExpiry(token);
          print(
              '[AuthProvider] Fresh user data loaded and logged in. emailVerified=${_user?.emailVerified}');
        } catch (e) {
          print('[AuthProvider] Failed to fetch fresh user data: $e');
          _isLoggedIn = false;
          _user = null;
          print(
              '[AuthProvider] checkAuthStatus: _isLoggedIn=$_isLoggedIn, _user=$_user');
          await logout();
        }
      } else {
        print('[AuthProvider] No token found. Not logged in.');
        _isLoggedIn = false;
        _user = null;
        print(
            '[AuthProvider] checkAuthStatus: _isLoggedIn=$_isLoggedIn, _user=$_user');
      }
    } catch (e) {
      print('Error checking auth status: $e');
      _isLoggedIn = false;
      _user = null;
      print(
          '[AuthProvider] checkAuthStatus: _isLoggedIn=$_isLoggedIn, _user=$_user');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    print('AuthProvider: done checking auth status');
  }

  Future<void> fetchFreshUserData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final token = await _authService.storage.read(key: 'accessToken');

      if (token == null) {
        _isLoggedIn = false;
        _user = null;
        notifyListeners();
        return;
      }

      final userData = await _authService.getCurrentUser();
      _user = User.fromJson(userData);
      _isLoggedIn = true;
    } catch (e) {
      print('Error fetching fresh user data');
      if (e is DioException && e.response?.statusCode == 401) {
        _isLoggedIn = false;
        _user = null;
        await _authService.storage.delete(key: 'accessToken');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String fullName, String email, String phone,
      String password, String countryCode, String countryName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        fullName,
        email,
        phone,
        password,
        countryCode,
        countryName,
      );
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.verifyEmail(code);
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resendVerificationCode(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resendVerificationCode(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verify2FA(String code, [String? email]) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (email == null) {
        print('🔐 Auth Provider: Verifying action with 2FA');
        await _authService.verify2FAForAction(code);
      } else {
        print('🔐 Auth Provider: Verifying login with 2FA');
        final response = await _authService.verify2FA(email, code);

        if (response['accessToken'] == null) {
          throw 'Invalid server response: No access token provided';
        }

        // Store tokens after successful 2FA verification
        await _authService.storage
            .write(key: 'accessToken', value: response['accessToken']);
        await _authService.storage
            .write(key: 'refreshToken', value: response['refreshToken']);
        await _authService.storage
            .write(key: 'user', value: json.encode(response['user']));

        _isLoggedIn = true;
        _user = User.fromJson(response['user']);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Auth Provider: 2FA verification failed');
      _error =
          e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetPassword(
      String email, String code, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email, code, newPassword);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generate2FASecret() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.generate2FASecret();
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> enable2FA(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.enable2FA(code);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disable2FA(String code, String codeType) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.disable2FA(code, codeType);
      await loadUser(); // Refresh user data after disable

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error =
          e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<String>> getBackupCodes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.getBackupCodes();
      _isLoading = false;
      notifyListeners();
      return List<String>.from(result['backupCodes']);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      return await _authService.getCurrentUser();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> storeTemp2FASecret(String secret) async {
    await _authService.storeTemp2FASecret(secret);
  }

  Future<void> updatePhone({
    required String phone,
    required String countryCode,
    required String countryName,
    required String phoneWithoutCode,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.updatePhone(
        phone: phone,
        countryCode: countryCode,
        countryName: countryName,
        phoneWithoutCode: phoneWithoutCode,
      );

      // Update local user data
      final updatedUser = await _authService.getCurrentUser();
      await _updateStoredUser(updatedUser);
    } catch (e) {
      _error =
          e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '');
      if (e.toString().contains('Session expired')) {
        await handleSessionExpiration();
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to update stored user data
  Future<void> _updateStoredUser(Map<String, dynamic> user) async {
    final storage = const FlutterSecureStorage();
    await storage.write(key: 'user', value: json.encode(user));
  }

  Future<void> sendPhoneVerification() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.sendPhoneVerification();
    } catch (e) {
      _error = e.toString();
      if (e.toString().contains('Session expired')) {
        await handleSessionExpiration();
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyPhone(String code) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _authService.verifyPhone(code);
      await _updateStoredUser(response['user']);
    } catch (e) {
      _error = e.toString();
      if (e.toString().contains('Session expired')) {
        await handleSessionExpiration();
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyCurrentPassword(String currentPassword) async {
    try {
      final response =
          await _authService.verifyCurrentPassword(currentPassword);
      return response;
    } catch (e) {
      print('Error verifying password');
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(currentPassword, newPassword);
      await refreshUserData(); // Refresh user data after password change
    } catch (e) {
      print('Error changing password');
      rethrow;
    }
  }

  // New method for social users to set their first password
  Future<void> setInitialPassword(String newPassword) async {
    try {
      await _authService.setInitialPassword(newPassword);
      await refreshUserData(); // Refresh user data after setting initial password
    } catch (e) {
      print('Error setting initial password');
      rethrow;
    }
  }

  Future<void> loadUser() async {
    try {
      final userData = await _authService.getCurrentUser();
      _user = User.fromJson(userData); // You'll need to create this model
      notifyListeners();
    } catch (e) {
      print('Error loading user');
      rethrow;
    }
  }

  Future<void> verify2FAForAction(String code) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.verify2FAForAction(code);

      _isLoading = false;
      notifyListeners();
      _lastVerificationToken =
          code; // Store the code after successful verification
    } catch (e) {
      _error =
          e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> handleUnauthorized(BuildContext context) async {
    print('Handling unauthorized access...');
    await logout();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> loadUserData() async {
    try {
      // First try to load from storage
      final storage = const FlutterSecureStorage();
      final userJson = await storage.read(key: 'user');
      final token = await storage.read(key: 'accessToken');

      if (userJson != null && token != null) {
        final userData = json.decode(userJson);
        _user = User.fromJson(userData);
        _isLoggedIn = true;
        notifyListeners();
      } else {
        _isLoggedIn = false;
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data');
      _isLoggedIn = false;
      _user = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshUserData() async {
    try {
      final userData = await _authService.getCurrentUser();
      if (userData != null) {
        _user = User.fromJson(userData);
        await _authService.storage.write(
          key: 'user',
          value: json.encode(userData),
        );
        notifyListeners();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        // Let the interceptor handle it
        rethrow;
      }
      print('Error refreshing user data');
    } catch (e) {
      print('Error refreshing user data');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _authService.updateProfile(data);
      await refreshUserData(); // Refresh after profile update
    } catch (e) {
      // ... error handling
    }
  }

  // Parse JWT to get expiration time
  void _updateTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      // exp is in seconds, convert to DateTime
      _tokenExpiryTime =
          DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);

      // Schedule token refresh
      _scheduleTokenRefresh();
    } catch (e) {
      print('Error parsing token: $e');
    }
  }

  void _scheduleTokenRefresh() {
    _tokenRefreshTimer?.cancel();

    try {
      if (_tokenExpiryTime == null) {
        print('No token expiry time set');
        return;
      }

      final timeUntilExpiry = _tokenExpiryTime!.difference(DateTime.now());
      if (timeUntilExpiry.isNegative) {
        print('Token already expired');
        handleSessionExpiration();
        return;
      }

      // Refresh 5 minutes before expiry
      final refreshTime = timeUntilExpiry - const Duration(minutes: 5);
      if (refreshTime.isNegative) {
        print('Token too close to expiry');
        handleSessionExpiration();
        return;
      }

      print('Scheduling token refresh in ${refreshTime.inMinutes} minutes');
      _tokenRefreshTimer = Timer(refreshTime, () async {
        await refreshToken();
      });
    } catch (e) {
      print('Error scheduling token refresh: $e');
      handleSessionExpiration();
    }
  }

  Future<void> refreshToken() async {
    try {
      final refreshToken = await _authService.storage.read(key: 'refreshToken');
      if (refreshToken == null) {
        await handleSessionExpiration();
        return;
      }

      final response = await _authService.refreshToken();

      if (response['accessToken'] == null) {
        throw 'No access token in refresh response';
      }

      // Update stored tokens
      await _authService.storage.write(
        key: 'accessToken',
        value: response['accessToken'],
      );

      if (response['refreshToken'] != null) {
        await _authService.storage.write(
          key: 'refreshToken',
          value: response['refreshToken'],
        );
      }

      // Update token expiry
      _updateTokenExpiry(response['accessToken']);

      // Reschedule token refresh
      _scheduleTokenRefresh();
    } catch (e) {
      print('Error refreshing token: $e');
      await handleSessionExpiration();
    }
  }

  String? getLastVerificationToken() {
    final token = _lastVerificationToken;
    _lastVerificationToken = null; // Clear it after use
    return token;
  }

  Future<void> loginWithTokens(String token, String refreshToken) async {
    try {
      print('Starting biometric login...');
      // Store in normal auth storage
      await _authService.storage.write(key: 'accessToken', value: token);
      await _authService.storage
          .write(key: 'refreshToken', value: refreshToken);

      print('Auth tokens stored, fetching user data...');
      final userData = await _authService.getCurrentUser();
      if (userData != null) {
        _user = User.fromJson(userData);
        await _authService.storage.write(
          key: 'user',
          value: json.encode(userData),
        );
      }

      _isLoggedIn = true;
      _startPeriodicRefresh();
      notifyListeners();

      print('Biometric login successful');
    } catch (e) {
      print('Error in biometric login');
      rethrow;
    }
  }

  /// Social Authentication Methods

  /// Google Sign In
  Future<Map<String, dynamic>> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _socialAuthService.signInWithGoogle();

      // Handle the response similar to regular login
      if (response['requires2FA'] == true) {
        _isLoading = false;
        notifyListeners();
        return response;
      }

      // Store tokens
      await _authService.storage
          .write(key: 'accessToken', value: response['accessToken']);
      await _authService.storage
          .write(key: 'refreshToken', value: response['refreshToken']);

      // Store for biometric if enabled
      try {
        final biometricService = BiometricSettingsService();
        final biometricEnabled = await biometricService.getBiometricStatus();
        if (biometricEnabled) {
          await biometricService.storeBiometricTokens(
            response['accessToken'],
            response['refreshToken'],
          );
        }
      } catch (e) {
        print('Error handling biometric storage');
      }

      // Store user data
      await _authService.storage
          .write(key: 'user', value: json.encode(response['user']));

      _user = User.fromJson(response['user']);
      _isLoggedIn = true;
      _startPeriodicRefresh();
      _updateTokenExpiry(response['accessToken']);

      // Register device for push notifications after successful login
      try {
        await _registerDeviceForNotifications();
        print('Device registered for notifications after Google login');
      } catch (e) {
        print('Error registering device for notifications: $e');
      }

      // Initialize notification provider for the new user
      try {
        if (navigatorKey.currentContext != null) {
          final notificationProvider = Provider.of<NotificationProvider>(
              navigatorKey.currentContext!,
              listen: false);
          await notificationProvider.initialize();
          await notificationProvider.fetchNotifications();
          print('Notification provider initialized for new Google user');
        }
      } catch (e) {
        print('Error initializing notification provider: $e');
      }

      _isLoading = false;
      notifyListeners();

      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Facebook Sign In
  Future<Map<String, dynamic>> signInWithFacebook() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _socialAuthService.signInWithFacebook();

      // Handle the response similar to regular login
      if (response['requires2FA'] == true) {
        _isLoading = false;
        notifyListeners();
        return response;
      }

      // Store tokens
      await _authService.storage
          .write(key: 'accessToken', value: response['accessToken']);
      await _authService.storage
          .write(key: 'refreshToken', value: response['refreshToken']);

      // Store for biometric if enabled
      try {
        final biometricService = BiometricSettingsService();
        final biometricEnabled = await biometricService.getBiometricStatus();
        if (biometricEnabled) {
          await biometricService.storeBiometricTokens(
            response['accessToken'],
            response['refreshToken'],
          );
        }
      } catch (e) {
        print('Error handling biometric storage');
      }

      // Store user data
      await _authService.storage
          .write(key: 'user', value: json.encode(response['user']));

      _user = User.fromJson(response['user']);
      _isLoggedIn = true;
      _startPeriodicRefresh();
      _updateTokenExpiry(response['accessToken']);

      // Register device for push notifications after successful login
      try {
        await _registerDeviceForNotifications();
        print('Device registered for notifications after Facebook login');
      } catch (e) {
        print('Error registering device for notifications: $e');
      }

      // Initialize notification provider for the new user
      try {
        if (navigatorKey.currentContext != null) {
          final notificationProvider = Provider.of<NotificationProvider>(
              navigatorKey.currentContext!,
              listen: false);
          await notificationProvider.initialize();
          await notificationProvider.fetchNotifications();
          print('Notification provider initialized for new Facebook user');
        }
      } catch (e) {
        print('Error initializing notification provider: $e');
      }

      _isLoading = false;
      notifyListeners();

      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sign out from social accounts
  Future<void> signOutFromSocial() async {
    try {
      await _socialAuthService.signOut();
    } catch (e) {
      print('Error signing out from social accounts: $e');
    }
  }

  Future<Map<String, dynamic>> socialLoginWithFirebaseIdToken(String idToken,
      {required String provider}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.socialLoginWithFirebaseIdToken(
        idToken,
        provider: provider,
      );

      // Handle the response similar to regular login
      if (response['requires2FA'] == true) {
        _isLoading = false;
        notifyListeners();
        return response;
      }

      // Store tokens
      await _authService.storage
          .write(key: 'accessToken', value: response['accessToken']);
      await _authService.storage
          .write(key: 'refreshToken', value: response['refreshToken']);

      // Store for biometric if enabled
      try {
        final biometricService = BiometricSettingsService();
        final biometricEnabled = await biometricService.getBiometricStatus();
        if (biometricEnabled) {
          await biometricService.storeBiometricTokens(
            response['accessToken'],
            response['refreshToken'],
          );
        }
      } catch (e) {
        print('Error handling biometric storage');
      }

      // Store user data
      await _authService.storage
          .write(key: 'user', value: json.encode(response['user']));

      _user = User.fromJson(response['user']);
      _isLoggedIn = true;
      _startPeriodicRefresh();
      _updateTokenExpiry(response['accessToken']);

      // Register device for push notifications after successful login
      try {
        await _registerDeviceForNotifications();
        print(
            'Device registered for notifications after Firebase social login');
      } catch (e) {
        print('Error registering device for notifications: $e');
      }

      // Initialize notification provider for the new user
      try {
        if (navigatorKey.currentContext != null) {
          final notificationProvider = Provider.of<NotificationProvider>(
              navigatorKey.currentContext!,
              listen: false);
          await notificationProvider.initialize();
          await notificationProvider.fetchNotifications();
          print(
              'Notification provider initialized for new Firebase social user');
        }
      } catch (e) {
        print('Error initializing notification provider: $e');
      }

      _isLoading = false;
      notifyListeners();

      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}

class User {
  final String id;
  final String email;
  final String fullName;
  final bool emailVerified;
  final bool phoneVerified;
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final String? phone;
  final String? countryCode;
  final String? countryName;
  final int kycLevel;
  final Map<String, dynamic>? kycData;
  final String? socialProvider;
  final String? socialProviderId;
  final bool hasPassword;
  final String? traderId;
  final String? createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.emailVerified,
    required this.phoneVerified,
    required this.twoFactorEnabled,
    this.biometricEnabled = false,
    this.phone,
    this.countryCode,
    this.countryName,
    required this.kycLevel,
    this.kycData,
    this.socialProvider,
    this.socialProviderId,
    this.hasPassword = true,
    this.traderId,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print(
        'User.fromJson Debug: hasPassword_raw:  [33m${json['hasPassword']} [0m, hasPassword_type:  [36m${json['hasPassword']?.runtimeType} [0m, socialProvider: ${json['socialProvider']}, email: ${json['email']}');

    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      emailVerified: json['emailVerified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? false,
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      biometricEnabled: json['biometricEnabled'] ?? false,
      phone: json['phone'],
      countryCode: json['countryCode'],
      countryName: json['countryName'],
      kycLevel: json['kycLevel'] ?? 0,
      kycData: json['kycData'],
      socialProvider: json['socialProvider'],
      socialProviderId: json['socialProviderId'],
      hasPassword: _parseHasPassword(json['hasPassword']),
      traderId: json['traderId'],
      createdAt: json['createdAt'],
    );
  }

  // Helper function to parse hasPassword field which might be string or bool
  static bool _parseHasPassword(dynamic value) {
    print('_parseHasPassword Debug: value=$value, type=${value.runtimeType}');

    if (value == null) {
      print('_parseHasPassword: null value, defaulting to true');
      return true; // Default to true for backward compatibility
    }

    if (value is bool) {
      print('_parseHasPassword: boolean value $value');
      return value;
    }

    if (value is String) {
      final lowerValue = value.toLowerCase();
      final result = lowerValue == 'true';
      print('_parseHasPassword: string value "$value" -> $result');
      return result;
    }

    if (value is int) {
      final result = value != 0;
      print('_parseHasPassword: int value $value -> $result');
      return result;
    }

    print(
        '_parseHasPassword: unknown type ${value.runtimeType}, defaulting to true');
    return true; // Default to true for any other type
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'biometricEnabled': biometricEnabled,
      'phone': phone,
      'countryCode': countryCode,
      'countryName': countryName,
      'kycLevel': kycLevel,
      'kycData': kycData,
      'socialProvider': socialProvider,
      'socialProviderId': socialProviderId,
      'hasPassword': hasPassword,
      'traderId': traderId,
      'createdAt': createdAt,
    };
  }

  bool get needsToSetPassword => isSocialUser && !hasPassword;
  bool get isSocialUser => socialProvider != null && socialProvider!.isNotEmpty;
}
