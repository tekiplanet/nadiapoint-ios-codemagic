import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../models/fiat_transaction.dart';

class FiatTransactionService {
  late final Dio _dio;
  final storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  FiatTransactionService() {
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

  List _safeList(dynamic value) {
    if (value is List) return value;
    return [];
  }

  Future<List<FiatTransaction>> fetchAllTransactions() async {
    try {
      final responses = await Future.wait([
        _dio.get('/fiat-deposits'),
        _dio.get('/fiat-withdrawals'),
        _dio.get('/fiat-crypto-purchases'),
      ]);

      final deposits = _safeList(responses[0].data['data'])
          .map((e) => FiatTransaction.fromDepositJson(e))
          .toList();
      final withdrawals = _safeList(responses[1].data['data'])
          .map((e) => FiatTransaction.fromWithdrawJson(e))
          .toList();
      final purchases = _safeList(responses[2].data['purchases'])
          .map((e) => FiatTransaction.fromPurchaseJson(e))
          .toList();

      final all = [...deposits, ...withdrawals, ...purchases];
      all.sort((a, b) => b.date.compareTo(a.date)); // Most recent first
      return all;
    } catch (e) {
      print('Error fetching transactions: \\${e.toString()}');
      rethrow;
    }
  }

  Future<(List<FiatTransaction>, bool)> fetchDepositsPage(
      {int page = 1, int limit = 20}) async {
    print(
        '[fetchDepositsPage] page=$page (${page.runtimeType}), limit=$limit (${limit.runtimeType})');
    final response = await _dio
        .get('/fiat-deposits', queryParameters: {'page': page, 'limit': limit});
    final data = response.data['data'];
    final pagination = response.data['pagination'] ?? {};
    final total = pagination['total'] ?? 0;
    final currentPage = pagination['page'] ?? 1;
    final pageLimit = pagination['limit'] ?? limit;
    final hasMore = (data is List) &&
        (data.length > 0) &&
        (total > currentPage * pageLimit);
    final txs =
        _safeList(data).map((e) => FiatTransaction.fromDepositJson(e)).toList();
    return (txs, hasMore);
  }

  Future<(List<FiatTransaction>, bool)> fetchWithdrawalsPage(
      {int page = 1, int limit = 20}) async {
    print(
        '[fetchWithdrawalsPage] page=$page (${page.runtimeType}), limit=$limit (${limit.runtimeType})');
    final response = await _dio.get('/fiat-withdrawals',
        queryParameters: {'page': page, 'limit': limit});
    final data = response.data['data'];
    final pagination = response.data['pagination'] ?? {};
    final total = pagination['total'] ?? 0;
    final currentPage = pagination['page'] ?? 1;
    final pageLimit = pagination['limit'] ?? limit;
    final hasMore = (data is List) &&
        (data.length > 0) &&
        (total > currentPage * pageLimit);
    final txs = _safeList(data)
        .map((e) => FiatTransaction.fromWithdrawJson(e))
        .toList();
    return (txs, hasMore);
  }

  Future<(List<FiatTransaction>, bool)> fetchPurchasesPage(
      {int page = 1, int limit = 20}) async {
    print('[fetchPurchasesPage] page=$page, limit=$limit');
    final response = await _dio.get('/fiat-crypto-purchases',
        queryParameters: {'page': page, 'limit': limit});
    print('Raw purchases response: \\${response.data}');
    final data = response.data['data'];
    print('Parsed purchases count: \\${data?.length}');
    final pagination = response.data['pagination'] ?? {};
    final total = pagination['total'] ?? 0;
    final currentPage = pagination['page'] ?? 1;
    final pageLimit = pagination['limit'] ?? limit;
    final hasMore = (data is List) &&
        (data.length > 0) &&
        (total > currentPage * pageLimit);
    final txs = _safeList(data)
        .map((e) => FiatTransaction.fromPurchaseJson(e))
        .toList();
    return (txs, hasMore);
  }

  Future<(List<FiatTransaction>, bool)> fetchDepositsPageByCurrency(
      {required String currency, int page = 1, int limit = 10}) async {
    final response = await _dio.get('/fiat-deposits',
        queryParameters: {'page': page, 'limit': limit, 'currency': currency});
    final data = response.data['data'];
    final pagination = response.data['pagination'] ?? {};
    final total = pagination['total'] ?? 0;
    final currentPage = pagination['page'] ?? 1;
    final pageLimit = pagination['limit'] ?? limit;
    final hasMore = (data is List) &&
        (data.length > 0) &&
        (total > currentPage * pageLimit);
    final txs =
        _safeList(data).map((e) => FiatTransaction.fromDepositJson(e)).toList();
    return (txs, hasMore);
  }

  Future<(List<FiatTransaction>, bool)> fetchWithdrawalsPageByCurrency(
      {required String currency, int page = 1, int limit = 10}) async {
    final response = await _dio.get('/fiat-withdrawals',
        queryParameters: {'page': page, 'limit': limit, 'currency': currency});
    final data = response.data['data'];
    final pagination = response.data['pagination'] ?? {};
    final total = pagination['total'] ?? 0;
    final currentPage = pagination['page'] ?? 1;
    final pageLimit = pagination['limit'] ?? limit;
    final hasMore = (data is List) &&
        (data.length > 0) &&
        (total > currentPage * pageLimit);
    final txs = _safeList(data)
        .map((e) => FiatTransaction.fromWithdrawJson(e))
        .toList();
    return (txs, hasMore);
  }

  Future<(List<FiatTransaction>, bool)> fetchPurchasesPageByCurrency(
      {required String currency, int page = 1, int limit = 10}) async {
    print(
        '[fetchPurchasesPageByCurrency] currency=$currency, page=$page, limit=$limit');
    final response = await _dio.get('/fiat-crypto-purchases',
        queryParameters: {'page': page, 'limit': limit, 'currency': currency});
    print('Raw purchases response: \\${response.data}');
    final data = response.data['data'];
    print('Parsed purchases count: \\${data?.length}');
    final pagination = response.data['pagination'] ?? {};
    final total = pagination['total'] ?? 0;
    final currentPage = pagination['page'] ?? 1;
    final pageLimit = pagination['limit'] ?? limit;
    final hasMore = (data is List) &&
        (data.length > 0) &&
        (total > currentPage * pageLimit);
    final txs = _safeList(data)
        .map((e) => FiatTransaction.fromPurchaseJson(e))
        .toList();
    return (txs, hasMore);
  }
}
