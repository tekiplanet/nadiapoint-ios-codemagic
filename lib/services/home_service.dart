import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeService {
  late final Dio _dio;
  final storage = const FlutterSecureStorage();
  late final String baseUrl;
  final AuthService _authService = getIt<AuthService>();

  HomeService() {
    baseUrl = _authService.baseUrl.replaceAll('/auth', '');
    print('HomeService initializing with base URL: $baseUrl');
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
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
            print('Request to ${options.path} with auth token');
          } else {
            print(
                'WARNING: No auth token available for request to ${options.path}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              'Response from ${response.requestOptions.path}: Status ${response.statusCode}');
          print('Response data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          print('Error Response: ${error.response?.data}');
          print('Error Status Code: ${error.response?.statusCode}');
          print('Error URL: ${error.requestOptions.path}');
          print('Error Message: ${error.message}');

          if (error.response?.statusCode == 401) {
            print('Unauthorized error - token may be invalid');
            // Handle token refresh or logout
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getPortfolioSummary({
    String currency = 'USD',
    String timeframe = '24h',
  }) async {
    try {
      print(
          'Fetching portfolio summary with currency: $currency, timeframe: $timeframe');
      final response = await _dio.get(
        '/home/portfolio-summary',
        queryParameters: {
          'currency': currency,
          'timeframe': timeframe,
        },
      );

      print('Portfolio data received: ${response.data}');

      // Validate response data
      if (response.data == null) {
        print('ERROR: Null response data received');
        throw 'Invalid response data';
      }

      if (response.data is! Map) {
        print(
            'ERROR: Response data is not a map: ${response.data.runtimeType}');
        throw 'Invalid response format';
      }

      // Add default values for missing fields
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(response.data);

      if (!data.containsKey('portfolio')) {
        print('WARNING: Portfolio data missing, adding default');
        data['portfolio'] = {
          'usdValue': 0,
          'localCurrencyValue': 0,
          'currency': currency,
          'exchangeRate': 1.0,
          'change': {
            'value': 0,
            'valueInLocalCurrency': 0,
            'percent': 0,
            'timeframe': timeframe,
          },
        };
      }

      if (!data.containsKey('allocation')) {
        print('WARNING: Allocation data missing, adding default');
        data['allocation'] = [];
      }

      if (!data.containsKey('chartData')) {
        print('WARNING: Chart data missing, adding default');
        data['chartData'] = [];
      }

      return data;
    } catch (e, stack) {
      print('Error fetching portfolio summary');
      print('Stack trace: $stack');

      if (e is DioException) {
        final message = e.response?.data?['message'];
        if (message != null) {
          throw message;
        }
      }
      throw 'Failed to load portfolio data: $e';
    }
  }

  String formatCurrency(double value, String currency) {
    if (value == 0) {
      return '\$0.00';
    }

    // Format based on currency
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$${_formatNumber(value)}';
      case 'EUR':
        return '€${_formatNumber(value)}';
      case 'GBP':
        return '£${_formatNumber(value)}';
      case 'NGN':
        return '₦${_formatNumber(value)}';
      case 'BTC':
        // Show more decimal places for BTC
        return '${value.toStringAsFixed(8)} BTC';
      default:
        return '${_formatNumber(value)} $currency';
    }
  }

  String _formatNumber(double value) {
    // For large values, use K/M/B notation
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }

    // Standard formatting for values under 1000
    if (value < 0.01) {
      return value.toStringAsFixed(6);
    }
    return value.toStringAsFixed(2);
  }

  Future<Map<String, dynamic>> getMarketOverview() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/home/market-overview'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load market overview');
      }
    } catch (e) {
      throw Exception('Error getting market overview');
    }
  }

  Future<Map<String, dynamic>> getTrending() async {
    try {
      print('[getTrending] Requesting: $baseUrl/home/trending');
      final response = await http.get(
        Uri.parse('$baseUrl/home/trending'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      print('[getTrending] Response status: \\${response.statusCode}');
      print('[getTrending] Response body: \\${response.body}');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('[getTrending] Decoded response: \\${decoded}');
        return decoded;
      } else {
        print(
            '[getTrending] Failed to load trending tokens, status: \\${response.statusCode}');
        throw Exception('Failed to load trending tokens');
      }
    } catch (e) {
      print('[getTrending] Error: \\${e.toString()}');
      throw Exception('Error getting trending tokens');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentNews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/home/news'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['news']);
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      throw Exception('Failed to load news');
    }
  }

  Future<Map<String, dynamic>> getPaginatedNews(
      {int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/news?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      throw Exception('Failed to load news');
    }
  }

  Future<Map<String, dynamic>> getNewsById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/news/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load news details');
      }
    } catch (e) {
      throw Exception('Failed to load news details');
    }
  }

  Future<Map<String, dynamic>> getMarketTokens() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/home/market-tokens'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load market tokens');
      }
    } catch (e) {
      throw Exception('Error getting market tokens');
    }
  }

  Future<Map<String, dynamic>> getContactInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/home/contact'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load contact information');
      }
    } catch (e) {
      throw Exception('Error getting contact information');
    }
  }
}
