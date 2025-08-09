import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class FiatCryptoPurchaseService {
  late final Dio _dio;
  final storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  FiatCryptoPurchaseService() {
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
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          print('Error Response: \\${error.response?.data}');
          print('Error Status Code: \\${error.response?.statusCode}');
          print('Error Headers: \\${error.response?.headers}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> createPurchase({
    required String fiatWalletId,
    required String tokenId,
    required double fiatAmount,
  }) async {
    try {
      final response = await _dio.post(
        '/fiat-crypto-purchases',
        data: {
          'fiatWalletId': fiatWalletId,
          'tokenId': tokenId,
          'fiatAmount': fiatAmount,
        },
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          final errorData = e.response?.data;
          final message = errorData?['message'] ?? 'Invalid request';
          throw Exception(message);
        } else if (e.response?.statusCode == 404) {
          throw Exception('Wallet or token not found');
        } else if (e.response?.statusCode == 403) {
          throw Exception('Insufficient balance');
        }
      }
      throw Exception('Failed to create purchase. Please try again.');
    }
  }

  Future<Map<String, dynamic>> getPurchases({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/fiat-crypto-purchases',
        queryParameters: queryParams,
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch purchases. Please try again.');
    }
  }

  Future<Map<String, dynamic>> getPurchaseById(String purchaseId) async {
    try {
      final response = await _dio.get('/fiat-crypto-purchases/$purchaseId');
      return response.data;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Purchase not found');
      }
      throw Exception('Failed to fetch purchase details. Please try again.');
    }
  }
}
