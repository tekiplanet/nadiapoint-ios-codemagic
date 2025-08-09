import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/p2p_settings.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(
    baseURL: ApiConfig.baseUrl,
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  Future<P2PSettings> getP2PSettings() async {
    try {
      final response = await _dio.get('/p2p-settings/me');
      return P2PSettings.fromJson(response.data);
    } on DioError catch (e) {
      throw Exception('Failed to load settings: ${e.message}');
    }
  }
} 