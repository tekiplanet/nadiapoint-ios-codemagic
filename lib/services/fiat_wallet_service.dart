import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class FiatWalletService {
  late final Dio _dio;
  final storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  FiatWalletService() {
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

  Future<List<Map<String, dynamic>>> getUserFiatWallets() async {
    try {
      final response = await _dio.get('/fiat-wallets');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching fiat wallets: \\${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableFiatCurrencies() async {
    try {
      final response = await _dio.get('/fiat-wallets/available-currencies');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching available fiat currencies: \\${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createFiatWallet(String currencyId) async {
    try {
      final response =
          await _dio.post('/fiat-wallets', data: {'currencyId': currencyId});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      print('Error creating fiat wallet: \\${e.toString()}');
      rethrow;
    }
  }

  /// Fetch all active fiat payment methods for a given currencyId
  Future<List<Map<String, dynamic>>> getFiatPaymentMethods(
      String currencyId) async {
    try {
      final response = await _dio.get('/fiat-payment-methods',
          queryParameters: {'currencyId': currencyId});
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      print('Error fetching fiat payment methods: \\${e.toString()}');
      rethrow;
    }
  }

  /// Fetch a single fiat payment method by ID
  Future<Map<String, dynamic>> getFiatPaymentMethodById(String id) async {
    try {
      final response = await _dio.get('/fiat-payment-methods/$id');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      print('Error fetching fiat payment method by ID: \\${e.toString()}');
      rethrow;
    }
  }

  /// Create a new fiat deposit
  Future<Map<String, dynamic>> createFiatDeposit({
    required String fiatWalletId,
    required String fiatPaymentMethodId,
    required double amount,
    String? proofOfPaymentFileId,
  }) async {
    try {
      final response = await _dio.post('/fiat-deposits', data: {
        'fiatWalletId': fiatWalletId,
        'fiatPaymentMethodId': fiatPaymentMethodId,
        'amount': amount,
        if (proofOfPaymentFileId != null)
          'proofOfPaymentFileId': proofOfPaymentFileId,
      });
      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      print('Error creating fiat deposit: ${e.toString()}');
      rethrow;
    }
  }

  /// Get all fiat deposits for the current user
  Future<List<Map<String, dynamic>>> getFiatDeposits() async {
    try {
      final response = await _dio.get('/fiat-deposits');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      print('Error fetching fiat deposits: ${e.toString()}');
      rethrow;
    }
  }

  /// Get a specific fiat deposit by ID
  Future<Map<String, dynamic>> getFiatDeposit(String id) async {
    try {
      final response = await _dio.get('/fiat-deposits/$id');
      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      print('Error fetching fiat deposit: ${e.toString()}');
      rethrow;
    }
  }

  /// Update a fiat deposit (e.g., add proof of payment)
  Future<Map<String, dynamic>> updateFiatDeposit({
    required String id,
    String? proofOfPaymentFileId,
  }) async {
    try {
      final response = await _dio.put('/fiat-deposits/$id', data: {
        if (proofOfPaymentFileId != null)
          'proofOfPaymentFileId': proofOfPaymentFileId,
      });
      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      print('Error updating fiat deposit: ${e.toString()}');
      rethrow;
    }
  }

  /// Fetch all active fiat withdrawal methods for a given currencyId
  Future<List<Map<String, dynamic>>> getFiatWithdrawalMethods(
      String currencyId) async {
    try {
      final response = await _dio.get('/fiat-payment-methods',
          queryParameters: {'currencyId': currencyId, 'type': 'withdraw'});
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      print('Error fetching fiat withdrawal methods: \\${e.toString()}');
      rethrow;
    }
  }

  /// Create a new fiat withdrawal
  Future<Map<String, dynamic>> createFiatWithdrawal({
    required String fiatWalletId,
    required String fiatPaymentMethodId,
    required double amount,
    Map<String, dynamic>? paymentMethodFields,
    String? password,
    String? twoFactorCode,
  }) async {
    try {
      final requestData = {
        'fiatWalletId': fiatWalletId,
        'fiatPaymentMethodId': fiatPaymentMethodId,
        'amount': amount,
        if (paymentMethodFields != null)
          'paymentMethodFields': paymentMethodFields,
        if (password != null) 'password': password,
        if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
      };

      print('🔐 Fiat Withdrawal API Request:');
      print('   - fiatWalletId: $fiatWalletId');
      print('   - fiatPaymentMethodId: $fiatPaymentMethodId');
      print('   - amount: $amount');
      print('   - password: ${password != null ? "provided" : "null"}');
      print(
          '   - twoFactorCode: ${twoFactorCode != null ? "provided (${twoFactorCode.length} chars)" : "null"}');
      print(
          '   - paymentMethodFields: ${paymentMethodFields != null ? "provided" : "null"}');

      final response = await _dio.post('/fiat-withdrawals', data: requestData);
      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      print('Error creating fiat withdrawal: ${e.toString()}');
      rethrow;
    }
  }

  /// Get all fiat withdrawals for the current user
  Future<List<Map<String, dynamic>>> getFiatWithdrawals() async {
    try {
      final response = await _dio.get('/fiat-withdrawals');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      print('Error fetching fiat withdrawals: ${e.toString()}');
      rethrow;
    }
  }

  /// Get a specific fiat withdrawal by ID
  Future<Map<String, dynamic>> getFiatWithdrawal(String id) async {
    try {
      final response = await _dio.get('/fiat-withdrawals/$id');
      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      print('Error fetching fiat withdrawal: ${e.toString()}');
      rethrow;
    }
  }
}
