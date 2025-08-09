import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env/env_config.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';

class AuthService {
  final String baseUrl = EnvConfig.authBaseUrl;
  final storage = const FlutterSecureStorage();
  late final Dio _dio;
  final navigatorKey = GlobalKey<NavigatorState>();

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // print('🔐 Auth Service: Attempting login for $email');
      final response = await _dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      // print('✅ Auth Service: Login response received: ${response.statusCode}');

      // Handle 2FA requirement (403)
      if (data['requires2FA'] == true) {
        // print('🔒 Auth Service: 2FA required, storing temp token');
        if (data['tempToken'] == null) {
          throw 'Server error: No temporary token provided';
        }
        await storage.write(key: 'tempToken', value: data['tempToken']);
        return {'requires2FA': true, 'email': email};
      }

      // print('✅ Auth Service: Login successful, storing tokens');
      await storage.write(key: 'accessToken', value: data['accessToken']);
      await storage.write(key: 'refreshToken', value: data['refreshToken']);
      await storage.write(key: 'user', value: json.encode(data['user']));

      return data;
    } catch (e) {
      print('❌ Auth Service: Login error');

      if (e is DioException) {
        // Handle connection timeouts
        if (e.type == DioExceptionType.connectionTimeout) {
          throw 'Connection timed out. Please check your internet connection.';
        }

        // Handle no internet connection
        if (e.type == DioExceptionType.connectionError) {
          throw 'No internet connection. Please check your network.';
        }

        // Handle server errors with status codes
        if (e.response != null) {
          print('❌ Auth Service: Server response: ${e.response?.data}');

          switch (e.response?.statusCode) {
            case 400:
              throw 'Invalid email or password format';
            case 401:
              // Check if it's actually an invalid credentials error
              if (e.response?.data['message'] == 'Invalid credentials') {
                throw 'Invalid email or password';
              }
              // For actual session expired cases
              if (e.response?.data['message']
                      ?.toString()
                      .toLowerCase()
                      .contains('session expired') ==
                  true) {
                throw 'Session expired. Please try again.';
              }
              throw e.response?.data['message'] ?? 'Authentication failed';
            case 403:
              if (e.response?.data['requires2FA'] == true) {
                // print('🔒 Auth Service: 2FA required from error response');
                return {
                  'requires2FA': true,
                  'email': email,
                  'tempToken': e.response?.data['tempToken']
                };
              }
              throw 'Access denied';
            case 429:
              throw 'Too many attempts. Please try again later';
            default:
              throw e.response?.data['message'] ??
                  'Login failed. Please try again';
          }
        }

        // Handle other Dio errors
        switch (e.type) {
          case DioExceptionType.receiveTimeout:
            throw 'Server is not responding. Please try again later.';
          case DioExceptionType.sendTimeout:
            throw 'Unable to send request. Please check your connection.';
          default:
            throw 'Connection error. Please check your internet.';
        }
      }

      // Handle any other errors
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> logout() async {
    try {
      final token = await storage.read(key: 'accessToken');

      // Call backend logout endpoint
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Clear all stored data
      await storage.deleteAll();
    } catch (e) {
      print('Logout error');
      // Still clear local storage even if backend call fails
      await storage.deleteAll();
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await storage.read(key: 'accessToken');
      if (token == null) return false;

      // Verify token by making a request to a protected endpoint
      final response = await _dio.get(
        '/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error checking login status: $e');
      // If there's any error, clear the tokens
      await storage.deleteAll();
      return false;
    }
  }

  Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String phone,
    String password,
    String countryCode,
    String countryName,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'countryCode': countryCode,
        'countryName': countryName,
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Store tokens
      await storage.write(key: 'accessToken', value: data['accessToken']);
      await storage.write(key: 'refreshToken', value: data['refreshToken']);
      await storage.write(key: 'user', value: json.encode(data['user']));
      // Store userId for verification
      await storage.write(key: 'pendingUserId', value: data['user']['id']);
      return data;
    } else {
      throw data['message'] ?? 'Registration failed';
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String code) async {
    try {
      final userId = await storage.read(key: 'pendingUserId');
      final accessToken = await storage.read(key: 'accessToken');

      // Debug logs
      print('DEBUG: pendingUserId value: '
          ' [33m$userId [0m (type:  [36m${userId.runtimeType} [0m)');
      print('DEBUG: accessToken value: '
          ' [33m$accessToken [0m (type:  [36m${accessToken.runtimeType} [0m)');
      print('DEBUG: verifyEmail request body: '
          '{userId: $userId, code: $code}');

      if (userId == null && accessToken == null) {
        throw 'Session expired. Please try logging in again.';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'userId': userId,
          'code': code,
        }),
      );

      final data = json.decode(response.body);
      print('Backend Response: $data');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Store tokens
        await storage.write(key: 'accessToken', value: data['accessToken']);
        await storage.write(key: 'refreshToken', value: data['refreshToken']);
        await storage.write(key: 'user', value: json.encode(data['user']));
        await storage.delete(key: 'pendingUserId');
        return data;
      }

      throw data['message'] ?? 'Email verification failed';
    } catch (e) {
      print('Verification error');
      if (e.toString().contains('verified successfully')) {
        return {'status': 'success', 'message': e.toString()};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw data['message'] ?? 'Failed to resend verification code';
      }
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Failed to resend verification code';
    }
  }

  Future<Map<String, dynamic>> verify2FA(String email, String code) async {
    try {
      final tempToken = await storage.read(key: 'tempToken');
      print(
          '🔐 2FA Service: Verifying with temp token: ${tempToken?.substring(0, 10)}...');

      if (tempToken == null) {
        print('❌ 2FA Service: No temp token found');
        throw 'Session expired. Please restart login process.';
      }

      try {
        final response = await _dio.post(
          '/verify-2fa',
          data: {
            'email': email,
            'code': code,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $tempToken',
            },
          ),
        );

        print('✅ 2FA Service: Verification successful');
        print('🔑 2FA Service: Received new tokens');

        await storage.delete(key: 'tempToken');
        return response.data;
      } on DioException catch (e) {
        print(
            '❌ 2FA Service: Verification failed with status ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');

        final errorMessage = e.response?.data['message'] as String?;

        if (e.response?.statusCode == 401) {
          // Check specific error messages
          if (errorMessage == 'Invalid 2FA code') {
            throw 'Incorrect verification code. Please try again.';
          } else if (errorMessage?.toLowerCase().contains('session expired') ==
              true) {
            await storage.delete(key: 'tempToken');
            throw 'Your session has expired. Please restart the login process.';
          }
          // Default 401 error
          throw errorMessage ?? 'Authentication failed';
        }

        throw errorMessage ?? 'Failed to verify 2FA code';
      }
    } catch (e) {
      print('❌ 2FA Service: Error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      final data = json.decode(response.body);
      print('Forgot password response: $data');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      }

      throw data['message'] ?? 'Failed to send reset code';
    } catch (e) {
      print('Forgot password error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);
      print('Reset password response: $data');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      }

      throw data['message'] ?? 'Failed to reset password';
    } catch (e) {
      print('Reset password error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generate2FASecret() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/2fa/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await storage.read(key: 'accessToken')}',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      }

      throw data['message'] ?? 'Failed to generate 2FA secret';
    } catch (e) {
      print('Generate 2FA secret error');
      rethrow;
    }
  }

  Future<void> storeTemp2FASecret(String secret) async {
    await storage.write(key: 'temp2FASecret', value: secret);
  }

  Future<Map<String, dynamic>> enable2FA(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/enable'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await storage.read(key: 'accessToken')}',
        },
        body: json.encode({
          'code': code,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (navigatorKey.currentContext != null) {
          final authProvider = Provider.of<AuthProvider>(
              navigatorKey.currentContext!,
              listen: false);
          await authProvider.refreshUserData();
          print('User data refreshed after enabling 2FA');
        }
        return data;
      }

      throw data['message'] ?? 'Failed to enable 2FA';
    } catch (e) {
      print('Enable 2FA error');
      rethrow;
    }
  }

  Future<void> disable2FA(String code, String codeType) async {
    try {
      print('=== Disable 2FA Debug ===');
      print('Attempting to disable 2FA with:');
      print('Code: $code');
      print('Code Type: $codeType');
      print('Endpoint: ${_dio.options.baseUrl}/disable-2fa');

      if (code.isEmpty) {
        throw 'Please enter the 2FA code';
      }
      if (code.length != 6) {
        throw '2FA code must be 6 digits';
      }

      final response = await _dio.post(
        '/disable-2fa',
        data: {
          'code': code,
          'codeType': codeType,
        },
        options: Options(headers: await _getAuthHeaders()),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw response.data['message'] ?? 'Failed to disable 2FA';
      }

      if (navigatorKey.currentContext != null) {
        final authProvider = Provider.of<AuthProvider>(
            navigatorKey.currentContext!,
            listen: false);
        await authProvider.refreshUserData();
        print('User data refreshed after disabling 2FA');
      }
    } catch (e) {
      print('Disable 2FA error');
      if (e is DioException) {
        print('DioError type: ${e.type}');
        print('DioError message: ${e.message}');
        print('DioError response: ${e.response?.data}');

        final message = e.response?.data['message'];
        switch (e.response?.statusCode) {
          case 400:
            throw message ?? 'Invalid code';
          case 401:
            throw 'Invalid or expired code';
          case 429:
            throw 'Too many attempts. Please try again later';
          default:
            print('Disable 2FA error details: ${e.response?.data}');
            throw 'Unable to disable 2FA. Please try again later';
        }
      }
      if (e is String) throw e;
      throw 'Unable to disable 2FA';
    }
  }

  Future<Map<String, dynamic>> getBackupCodes() async {
    try {
      final response = await _dio.get(
        '/2fa/backup-codes',
        options: Options(
          headers: await _getAuthHeaders(),
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw response.data['message'] ?? 'Failed to get backup codes';
      }
    } catch (e) {
      print('Get backup codes error');
      if (e is DioException) {
        // Handle specific error cases
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            throw 'Connection timed out. Please try again.';
          case DioExceptionType.connectionError:
            throw 'Connection error. Please check your internet connection.';
          default:
            if (e.response?.statusCode == 401) {
              throw 'Session expired. Please login again.';
            } else if (e.response?.statusCode == 403) {
              throw '2FA is not enabled for this account';
            } else if (e.response?.statusCode == 404) {
              throw 'Backup codes not available';
            }
            throw e.response?.data?['message'] ?? 'Failed to get backup codes';
        }
      }
      throw 'Unable to connect to server. Please try again.';
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      // First try to get from storage
      final userJson = await storage.read(key: 'user');
      if (userJson != null) {
        final localUser = json.decode(userJson);

        // Try to get fresh data from server
        try {
          final response = await _dio.get(
            '/me',
            options: Options(headers: await _getAuthHeaders()),
          );

          // Update stored user data
          final freshUserData = response.data;
          await storage.write(key: 'user', value: json.encode(freshUserData));
          return freshUserData;
        } catch (e) {
          print('Error fetching fresh user data');
          // Return cached data if server request fails
          return localUser;
        }
      }

      // If no local data, must get from server
      final response = await _dio.get(
        '/me',
        options: Options(headers: await _getAuthHeaders()),
      );

      final userData = response.data;
      await storage.write(key: 'user', value: json.encode(userData));
      return userData;
    } catch (e) {
      print('Get current user error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updatePhone({
    required String phone,
    required String countryCode,
    required String countryName,
    required String phoneWithoutCode,
  }) async {
    try {
      final token = await storage.read(key: 'accessToken');
      if (token == null) {
        throw 'Authentication token not found';
      }

      final response = await http.put(
        Uri.parse('$baseUrl/update-phone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'phone': phone,
          'countryCode': countryCode,
          'countryName': countryName,
          'phoneWithoutCode': phoneWithoutCode,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 401) {
        await _handleTokenRefresh();
        return updatePhone(
          phone: phone,
          countryCode: countryCode,
          countryName: countryName,
          phoneWithoutCode: phoneWithoutCode,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update stored user data
        final currentUser = await getCurrentUser();
        currentUser['phone'] = phone;
        currentUser['countryCode'] = countryCode;
        currentUser['countryName'] = countryName;
        currentUser['phoneWithoutCode'] = phoneWithoutCode;
        await storage.write(key: 'user', value: json.encode(currentUser));

        return data;
      }

      // Handle error responses
      if (response.statusCode == 409) {
        throw 'This phone number is already in use by another account';
      }

      throw data['message'] ?? 'Failed to update phone number';
    } catch (e) {
      print('Update phone error: $e');
      rethrow;
    }
  }

  Future<void> sendPhoneVerification() async {
    try {
      final token = await storage.read(key: 'accessToken');
      if (token == null) {
        throw 'Authentication token not found';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/send-phone-verification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 401) {
        await _handleTokenRefresh();
        return sendPhoneVerification(); // Retry with new token
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw data['message'] ?? 'Failed to send verification code';
      }
    } catch (e) {
      print('Send phone verification error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyPhone(String code) async {
    try {
      final token = await storage.read(key: 'accessToken');
      if (token == null) {
        throw 'Authentication token not found';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/verify-phone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'code': code}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 401) {
        await _handleTokenRefresh();
        return verifyPhone(code); // Retry with new token
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw data['message'] ?? 'Failed to verify phone';
      }

      return data;
    } catch (e) {
      print('Verify phone error');
      rethrow;
    }
  }

  Future<bool> verifyCurrentPassword(String currentPassword) async {
    try {
      if (currentPassword.isEmpty) {
        throw Exception('Please enter your current password');
      }

      final response = await _dio.post(
        '/verify-password',
        data: {
          'password': currentPassword,
        },
        options: Options(headers: await _getAuthHeaders()),
      );

      return response.data['valid'] == true;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'];
        switch (e.response?.statusCode) {
          case 401:
            throw Exception('Current password is incorrect. Please try again.');
          case 400:
            throw Exception(message ?? 'Please enter a valid password');
          case 429:
            throw Exception('Too many attempts. Please try again later.');
          default:
            print('Verify password error details: ${e.response?.data}');
            throw Exception(
                'Unable to verify password. Please try again later.');
        }
      }
      throw Exception(e.toString());
    }
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      if (currentPassword.isEmpty) {
        throw Exception('Please enter your current password');
      }
      if (newPassword.isEmpty) {
        throw Exception('Please enter a new password');
      }

      await _dio.post(
        '/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        options: Options(headers: await _getAuthHeaders()),
      );
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'];
        switch (e.response?.statusCode) {
          case 401:
            throw Exception('Current password is incorrect. Please try again.');
          case 400:
            if (message?.contains('must be different') ?? false) {
              throw Exception(
                  'New password must be different from current password');
            }
            throw Exception(
                message ?? 'Please check your password requirements');
          case 429:
            throw Exception('Too many attempts. Please try again later.');
          default:
            print('Change password error details: ${e.response?.data}');
            throw Exception(
                'Unable to change password. Please try again later.');
        }
      }
      throw Exception(e.toString());
    }
  }

  // New method for social users to set their first password
  Future<void> setInitialPassword(String newPassword) async {
    try {
      if (newPassword.isEmpty) {
        throw Exception('Please enter a new password');
      }

      await _dio.post(
        '/set-initial-password',
        data: {
          'newPassword': newPassword,
        },
        options: Options(headers: await _getAuthHeaders()),
      );
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'];
        switch (e.response?.statusCode) {
          case 400:
            throw Exception(
                message ?? 'Please check your password requirements');
          case 429:
            throw Exception('Too many attempts. Please try again later.');
          default:
            print('Set initial password error details: ${e.response?.data}');
            throw Exception('Unable to set password. Please try again later.');
        }
      }
      throw Exception(e.toString());
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storage.read(key: 'accessToken');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<void> verify2FAForAction(String code) async {
    try {
      if (code.isEmpty) {
        throw 'Please enter the 2FA code';
      }
      if (code.length != 6) {
        throw '2FA code must be 6 digits';
      }

      final response = await _dio.post(
        '/verify-2fa-action',
        data: {
          'code': code,
        },
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw response.data['message'] ?? 'Failed to verify 2FA code';
      }
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'];
        switch (e.response?.statusCode) {
          case 400:
            throw message ?? 'Invalid 2FA code';
          case 401:
            throw 'Invalid or expired 2FA code';
          case 404:
            throw '2FA verification not available';
          case 429:
            throw 'Too many attempts. Please try again later';
          default:
            print('2FA verification error details: ${e.response?.data}');
            throw 'Unable to verify 2FA code. Please try again later';
        }
      }
      if (e is String) throw e;
      throw 'Unable to verify 2FA code';
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refreshToken');
      if (refreshToken == null) throw 'No refresh token found';

      print('Refreshing token with: $refreshToken');
      final response = await _dio.post(
        '/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      print('Refresh token response: ${response.data}');
      if (response.data == null) {
        throw 'Invalid response from server';
      }

      // Store new tokens
      await storage.write(
          key: 'accessToken', value: response.data['accessToken']);
      if (response.data['refreshToken'] != null) {
        await storage.write(
            key: 'refreshToken', value: response.data['refreshToken']);
      }

      return response.data;
    } catch (e) {
      print('Error refreshing token');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }
      throw 'Failed to refresh token';
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await storage.read(key: 'accessToken');
      await _dio.patch(
        '/profile',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleTokenRefresh() async {
    try {
      print('Handling token refresh...');
      final refreshResponse = await refreshToken();
      print('Token refresh successful');

      if (refreshResponse['accessToken'] == null) {
        throw 'No access token in refresh response';
      }

      await storage.write(
        key: 'accessToken',
        value: refreshResponse['accessToken'],
      );
    } catch (e) {
      print('Token refresh failed');
      await storage.deleteAll(); // Clear all stored data
      throw 'Session expired. Please login again.';
    }
  }

  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refreshToken');
  }

  Future<String?> getAccessToken() async {
    return await storage.read(key: 'accessToken');
  }

  Future<String?> getUserId() async {
    try {
      final userJson = await storage.read(key: 'user');
      if (userJson != null) {
        final userData = json.decode(userJson);
        return userData['id'];
      }
      return null;
    } catch (e) {
      print('Get user ID error');
      return null;
    }
  }

  Future<void> _saveToken(String token) async {
    print('Saving token...');
    try {
      await storage.write(key: 'token', value: token);
      print('Token saved successfully');
      final savedToken = await storage.read(key: 'token');
      print('Verified saved token: ${savedToken != null ? 'Yes' : 'No'}');
    } catch (e) {
      print('Error saving token');
      throw Exception('Failed to save authentication token');
    }
  }

  Future<Map<String, dynamic>> socialLoginWithFirebaseIdToken(String idToken,
      {required String provider}) async {
    try {
      final response = await _dio.post(
        '/social/firebase',
        data: {
          'idToken': idToken,
          'provider': provider,
        },
      );
      final data = response.data;
      // Store tokens if present
      if (data['accessToken'] != null) {
        await storage.write(key: 'accessToken', value: data['accessToken']);
      }
      if (data['refreshToken'] != null) {
        await storage.write(key: 'refreshToken', value: data['refreshToken']);
      }
      if (data['user'] != null) {
        await storage.write(key: 'user', value: json.encode(data['user']));
      }
      return data;
    } catch (e) {
      print('❌ Auth Service: Firebase social login error');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAccountRequests() async {
    try {
      final token = await storage.read(key: 'accessToken');
      final response = await _dio.get(
        '/account-request',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw 'Failed to fetch account requests.';
      }
    } catch (e) {
      print('Error fetching account requests: $e');
      rethrow;
    }
  }

  Future<void> submitAccountRequest(String type, String details) async {
    try {
      final token = await storage.read(key: 'accessToken');
      final response = await _dio.post(
        '/account-request',
        data: {'type': type, 'details': details},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw response.data['message'] ?? 'Failed to submit request.';
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw e.response?.data['message'] ??
            'You already have a pending request.';
      }
      rethrow;
    } catch (e) {
      print('Error submitting account request: $e');
      rethrow;
    }
  }
}
