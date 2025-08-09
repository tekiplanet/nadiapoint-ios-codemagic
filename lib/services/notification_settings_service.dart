import 'package:dio/dio.dart';
import '../services/auth_service.dart';

class NotificationSettingsService {
  late final Dio _dio;
  final AuthService _authService = AuthService();

  NotificationSettingsService() {
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

  Future<Map<String, Map<String, bool>>> getNotificationSettings() async {
    try {
      final response = await _dio.get('/me');
      final notificationSettings = response.data['notificationSettings'] as Map<String, dynamic>;
      
      // Convert the nested dynamic map to the correct type
      return notificationSettings.map((key, value) {
        final innerMap = (value as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as bool),
        );
        return MapEntry(key, innerMap);
      });
    } catch (e) {
      print('Error fetching notification settings');
      rethrow;
    }
  }

  Future<void> updateNotificationSettings(
    Map<String, Map<String, bool>> settings,
  ) async {
    try {
      await _dio.put(
        '/notification-settings',
        data: {
          'notificationSettings': settings,
        },
      );
    } catch (e) {
      print('Error updating notification settings');
      rethrow;
    }
  }
} 