import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../main.dart';  // for navigatorKey

class ApiClient {
  final Dio _dio;
  final AuthProvider _authProvider;

  // Add getter for dio
  Dio get dio => _dio;

  ApiClient(this._dio, this._authProvider) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            // Log out user on 401 Unauthorized
            await _authProvider.logout();
            
            // Show message to user
            if (navigatorKey.currentContext != null) {
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                const SnackBar(
                  content: Text('Your session has expired. Please sign in again to continue.'),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                  duration: Duration(seconds: 4),
                ),
              );
            }

            // Navigate to login screen
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
          return handler.next(error);
        },
      ),
    );
  }
} 