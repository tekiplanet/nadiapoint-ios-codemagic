import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class P2PSettingsService {
  late final Dio _dio;
  final storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  P2PSettingsService() {
    final baseUrl = _authService.baseUrl.replaceAll('/auth', '');
    
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
          final token = await storage.read(key: 'accessToken');
          // print('Request URL: ${options.baseUrl}${options.path}');
          // print('Request Headers: ${options.headers}');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          print('Error Response: ${error.response?.data}');
          print('Error Status Code: ${error.response?.statusCode}');
          print('Error Headers: ${error.response?.headers}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getCurrencies() async {
    try {
      print('Fetching currencies from /currencies endpoint...');
      final response = await _dio.get('/currencies');
      print('Currencies response: \\nStatus: \\${response.statusCode}\\nData: \\${response.data}');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      print('Error fetching currencies: \\${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    try {
      // print('Fetching settings...');
      final response = await _dio.get('/p2p-settings');
      // print('Response: ${response.data}');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      print('Error fetching settings');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    try {
      print('Updating settings with data: $settings');
      final response = await _dio.put('/p2p-settings', 
        data: settings,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      print('Update response: ${response.data}');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      print('Error updating settings');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAutoResponses() async {
    try {
      final settings = await getSettings();
      return List<Map<String, dynamic>>.from(settings['autoResponses'] ?? []);
    } catch (e) {
      print('Error fetching auto responses');
      rethrow;
    }
  }

  Future<void> updateAutoResponses(List<Map<String, dynamic>> responses) async {
    try {
      await _dio.put(
        '/p2p-settings/auto-responses',
        data: {
          'autoResponses': responses.map((response) => {
            'id': response['id'],
            'message': response['message'],
            'type': response['type'],
          }).toList(),
        },
      );
    } catch (e) {
      print('Error updating auto responses');
      rethrow;
    }
  }
} 