import 'package:dio/dio.dart';
import '../services/auth_service.dart';

class LanguageSettingsService {
  late final Dio _dio;
  final AuthService _authService = AuthService();

  LanguageSettingsService() {
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

  Future<String> getCurrentLanguage() async {
    try {
      final response = await _dio.get('/me');
      return response.data['language'] as String;
    } catch (e) {
      print('Error fetching language setting');
      rethrow;
    }
  }

  Future<void> updateLanguage(String language) async {
    try {
      await _dio.put(
        '/language',
        data: {
          'language': language,
        },
      );
    } catch (e) {
      print('Error updating language');
      rethrow;
    }
  }
} 