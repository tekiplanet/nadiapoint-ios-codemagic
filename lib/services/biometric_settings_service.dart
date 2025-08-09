import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../main.dart';

class BiometricSettingsService {
  late final Dio _dio;
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'biometric_token';
  static const String _refreshTokenKey = 'biometric_refresh_token';

  BiometricSettingsService() {
    final baseUrl = _authService.baseUrl;
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics');
      return [];
    }
  }

  Future<bool> authenticate() async {
    try {
      print('Showing biometric prompt...');
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      print('Error in authenticate()');
      return false;
    }
  }

  Future<bool> getBiometricStatus() async {
    try {
      final response = await _dio.get('/me');
      return response.data['biometricEnabled'] as bool;
    } catch (e) {
      print('Error fetching biometric status');
      rethrow;
    }
  }

  Future<void> storeBiometricTokens(String token, String refreshToken) async {
    try {
      print('Storing biometric tokens...');
      
      // Store tokens with encryption
      final encryptedToken = base64.encode(utf8.encode(token));
      final encryptedRefreshToken = base64.encode(utf8.encode(refreshToken));
      
      await _storage.write(key: _tokenKey, value: encryptedToken);
      await _storage.write(key: _refreshTokenKey, value: encryptedRefreshToken);
      
      print('Tokens stored successfully with keys: $_tokenKey, $_refreshTokenKey');
      
      // Verify storage
      final storedToken = await _storage.read(key: _tokenKey);
      final storedRefreshToken = await _storage.read(key: _refreshTokenKey);
      
      if (storedToken == null || storedRefreshToken == null) {
        throw 'Failed to verify token storage';
      }
      
      print('Token storage verified successfully');
    } catch (e) {
      print('Error storing biometric tokens');
      await clearBiometricTokens();
      rethrow;
    }
  }

  Future<Map<String, String?>> getBiometricTokens() async {
    try {
      print('Getting biometric tokens...');
      final encryptedToken = await _storage.read(key: _tokenKey);
      final encryptedRefreshToken = await _storage.read(key: _refreshTokenKey);
      
      print('Retrieved encrypted tokens - token exists: ${encryptedToken != null}, refresh exists: ${encryptedRefreshToken != null}');
      
      if (encryptedToken == null || encryptedRefreshToken == null) {
        print('Missing tokens, clearing storage');
        await clearBiometricTokens();
        return {'token': null, 'refreshToken': null};
      }
      
      // Decrypt tokens
      final token = utf8.decode(base64.decode(encryptedToken));
      final refreshToken = utf8.decode(base64.decode(encryptedRefreshToken));
      
      print('Tokens decrypted successfully');
      
      return {
        'token': token,
        'refreshToken': refreshToken,
      };
    } catch (e) {
      print('Error getting biometric tokens');
      await clearBiometricTokens();
      return {'token': null, 'refreshToken': null};
    }
  }

  Future<void> clearBiometricTokens() async {
    try {
      print('Clearing biometric tokens...');
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      print('Biometric tokens cleared successfully');
    } catch (e) {
      print('Error clearing biometric tokens');
    }
  }

  Future<bool> isTokenValid(String token) {
    try {
      // Parse the JWT token
      final parts = token.split('.');
      if (parts.length != 3) return Future.value(false);

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      
      // Check if token has expired
      final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      return Future.value(DateTime.now().isBefore(expiry));
    } catch (e) {
      print('Error checking token validity');
      return Future.value(false);
    }
  }

  Future<bool> authenticateAndGetTokens() async {
    try {
      // First check if we have valid biometric tokens
      final tokens = await getBiometricTokens();
      print('Checking stored biometric tokens: ${tokens['token'] != null}');
      
      if (tokens['token'] == null || tokens['refreshToken'] == null) {
        print('No stored biometric tokens found');
        return false;
      }

      // Then prompt for biometric
      final authenticated = await authenticate();
      print('Biometric authentication result: $authenticated');
      
      if (!authenticated) {
        print('Biometric authentication failed or cancelled');
        return false;
      }

      // Verify token validity
      final isValid = await isTokenValid(tokens['token']!);
      if (!isValid) {
        print('Stored biometric token is invalid or expired');
        await clearBiometricTokens();
        return false;
      }

      return true;
    } catch (e) {
      print('Error in authenticateAndGetTokens');
      return false;
    }
  }

  Future<void> updateBiometricStatus(bool enabled) async {
    try {
      print('Updating biometric status: $enabled');
      
      if (enabled) {
        // First update server before getting tokens
        await _dio.put(
          '/biometric',
          data: {
            'enabled': enabled,
          },
        );
        print('Server status updated');

        // Then get current auth tokens
        final token = await _authService.getAccessToken();
        final refreshToken = await _authService.getRefreshToken();
        
        if (token == null || refreshToken == null) {
          throw 'No valid tokens available to store';
        }

        // Store tokens in biometric storage
        await storeBiometricTokens(token, refreshToken);
        print('Tokens stored in biometric storage');
      } else {
        // For disable, first update server
        await _dio.put(
          '/biometric',
          data: {
            'enabled': enabled,
          },
        );
        print('Server status updated');

        // Clear biometric tokens
        await clearBiometricTokens();
        print('Biometric tokens cleared');
      }

      // Add this: Refresh user data after updating biometric status
      if (navigatorKey.currentContext != null) {
        final authProvider = Provider.of<AuthProvider>(
          navigatorKey.currentContext!, 
          listen: false
        );
        await authProvider.refreshUserData();
        print('User data refreshed after biometric update');
      } else {
        print('Warning: No context available to refresh user data');
      }

    } catch (e) {
      print('Error in updateBiometricStatus');
      if (!enabled) {
        await clearBiometricTokens();
      }
      rethrow;
    }
  }

  Future<void> storeTokensAfterLogin(String token, String refreshToken) async {
    try {
      // Check if biometric is enabled on server
      final status = await getBiometricStatus();
      if (status) {
        print('Biometric enabled, storing login tokens');
        await storeBiometricTokens(token, refreshToken);
      }
    } catch (e) {
      print('Error storing tokens after login');
    }
  }
} 