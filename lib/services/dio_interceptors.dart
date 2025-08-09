import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';

class AuthInterceptor extends Interceptor {
  final AuthProvider authProvider;
  final BuildContext? context;

  AuthInterceptor(this.authProvider, [this.context]);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    print('🔒 Auth Interceptor: Received error ${err.response?.statusCode}');
    print('Error response: ${err.response?.data}');
    
    // Only handle 401s that are actually session expired
    if (err.response?.statusCode == 401 && 
        err.response?.data['message']?.toString().toLowerCase().contains('session expired') == true) {
      print('🔄 Auth Interceptor: Handling session expiration');
      try {
        await authProvider.refreshToken();
        print('✅ Auth Interceptor: Token refresh successful');
        
        final options = err.requestOptions;
        print('🔄 Auth Interceptor: Retrying original request to ${options.path}');
        final response = await Dio().fetch(options);
        return handler.resolve(response);
      } catch (e) {
        print('❌ Auth Interceptor: Token refresh failed');
        if (context != null && context!.mounted) {
          await authProvider.handleUnauthorized(context!);
        } else {
          await authProvider.logout();
        }
      }
    }
    
    // Let other error codes pass through
    print('➡️ Auth Interceptor: Passing through error ${err.response?.statusCode}');
    handler.next(err);
  }
} 