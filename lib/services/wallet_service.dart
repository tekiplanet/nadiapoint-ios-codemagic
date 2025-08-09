import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/coin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  late final Dio _dio;
  final storage = const FlutterSecureStorage();
  final AuthService _authService = getIt<AuthService>();
  final _cache = <String, CacheEntry>{};
  final _cacheDuration = const Duration(minutes: 5);

  WalletService() {
    final baseUrl = _authService.baseUrl.replaceAll('/auth', '');
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
          print('\n=== Request Details ===');
          print('URL: ${options.baseUrl}${options.path}');
          print('Method: ${options.method}');
          print('Query Parameters: ${options.queryParameters}');
          print('Headers: ${options.headers}');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('\n=== Response Details ===');
          print('Status Code: ${response.statusCode}');
          print('Headers: ${response.headers}');
          print('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          print('\n=== Error Details ===');
          print('Error Type: ${error.type}');
          print('Error Message: ${error.message}');
          print('Error Response: ${error.response?.data}');
          print('Error Status Code: ${error.response?.statusCode}');
          print('Error Headers: ${error.response?.headers}');
          print('Request Path: ${error.requestOptions.path}');
          print(
              'Request Query Parameters: ${error.requestOptions.queryParameters}');
          print('Request Headers: ${error.requestOptions.headers}');

          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.unknown) {
            RequestOptions requestOptions = error.requestOptions;

            try {
              print('\nRetrying request to: ${requestOptions.path}');
              final response = await _dio.request(
                requestOptions.path,
                data: requestOptions.data,
                queryParameters: requestOptions.queryParameters,
                options: Options(
                  method: requestOptions.method,
                  headers: requestOptions.headers,
                ),
              );
              return handler.resolve(response);
            } catch (e) {
              print('Retry failed');
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getBalances({
    String? type,
    String? currency,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/wallets/balances',
        queryParameters: {
          if (type != null) 'type': type,
          'page': page,
          'limit': limit,
        },
      );

      final balances = response.data['balances'] as List<dynamic>;
      balances.forEach((balance) {
        final token = balance['token'] as Map<String, dynamic>?;
        if (token == null) {
          debugPrint('Warning: Token data missing for balance: $balance');
          return;
        }

        final networks = balance['networks'] as List<dynamic>?;
        if (networks != null) {
          networks.forEach((network) {
            if (network is Map<String, dynamic>) {
              // Process network data silently
            }
          });
        }
      });

      return response.data;
    } on DioException catch (e) {
      debugPrint('Network error in getBalances: ${e.message}');
      if (e.response?.statusCode == 502) {
        throw 'Service is temporarily unavailable. Please try again in a few moments.';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw 'Connection timed out. Please check your internet connection.';
      } else {
        throw 'Unable to load balances. Please try again.';
      }
    } catch (e) {
      debugPrint('Error in getBalances');
      throw 'Unable to load balances. Please try again.';
    }
  }

  String _formatBalance(String balance, int decimals) {
    try {
      // print('\nFormatting balance:');
      // print('Input balance: $balance');
      // print('Decimals: $decimals');

      double rawValue = double.parse(balance);
      // print('Parsed raw value: $rawValue');

      BigInt baseUnits = BigInt.from(rawValue * math.pow(10, decimals));
      // print('Base units: $baseUnits');

      BigInt wholePart = baseUnits ~/ BigInt.from(math.pow(10, decimals));
      BigInt fractionalPart = baseUnits % BigInt.from(math.pow(10, decimals));

      String fractionalStr = fractionalPart.toString().padLeft(decimals, '0');

      // Trim trailing zeros while keeping at least one decimal place
      while (fractionalStr.endsWith('0') && fractionalStr.length > 1) {
        fractionalStr = fractionalStr.substring(0, fractionalStr.length - 1);
      }

      String result = '$wholePart.$fractionalStr';
      // print('Formatted result: $result');
      return result;
    } catch (e) {
      // print('Error formatting balance: $balance with decimals: $decimals');
      // print('Error details');
      return '0.0';
    }
  }

  Future<Map<String, dynamic>> updateTokenMarketData(String tokenId,
      {String? timeframe}) async {
    try {
      final response = await _dio.post(
        '/wallets/token/$tokenId/market-data',
        queryParameters: timeframe != null ? {'timeframe': timeframe} : null,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      }

      return {
        'success': false,
        'message': 'Failed to update token market data',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getDepositAddress(
    String tokenId, {
    required String network,
    required String blockchain,
    required String version,
  }) async {
    try {
      final response = await _dio.get(
        '/wallets/deposit-address/$tokenId',
        queryParameters: {
          'network': network,
          'blockchain': blockchain,
          'version': version,
        },
      );
      return response.data;
    } catch (e) {
      debugPrint('Error getting deposit address');
      rethrow;
    }
  }

  Future<List<Coin>> getAvailableCoins() async {
    try {
      final response = await _dio.get('/wallets/tokens/available');

      final List<dynamic> tokens = response.data['tokens'];
      return tokens.map((token) {
        final metadata = token['metadata'] as Map<String, dynamic>;
        final networks = List<Map<String, dynamic>>.from(token['networks']);

        // Deduplicate networks based on blockchain, version and network
        final uniqueNetworks =
            networks.fold<List<Map<String, dynamic>>>([], (unique, network) {
          if (!unique.any((n) =>
              n['blockchain'] == network['blockchain'] &&
              n['version'] == network['version'] &&
              n['network'] == network['network'])) {
            unique.add(network);
          }
          return unique;
        });

        return Coin(
          id: token['id'],
          symbol: token['symbol'],
          name: token['name'],
          iconUrl: metadata['icon'],
          networks: uniqueNetworks
              .map((network) => Network(
                    name: network['blockchain'],
                    blockchain: network['blockchain'],
                    version: network['version'],
                    arrivalTime: network['arrivalTime'],
                    network: network['network'],
                    requiresMemo: network['requiredFields']?['memo'] ?? false,
                    requiresTag: network['requiredFields']?['tag'] ?? false,
                  ))
              .toList(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting available coins');
      rethrow;
    }
  }

  // New method specifically for fiat buy crypto screen that includes currentPrice
  Future<List<Map<String, dynamic>>> getAvailableCoinsWithPrices() async {
    try {
      final response = await _dio.get('/wallets/tokens/available');

      final List<dynamic> tokens = response.data['tokens'];
      return tokens.map((token) {
        final metadata = token['metadata'] as Map<String, dynamic>;
        final networks = List<Map<String, dynamic>>.from(token['networks']);

        // Deduplicate networks based on blockchain, version and network
        final uniqueNetworks =
            networks.fold<List<Map<String, dynamic>>>([], (unique, network) {
          if (!unique.any((n) =>
              n['blockchain'] == network['blockchain'] &&
              n['version'] == network['version'] &&
              n['network'] == network['network'])) {
            unique.add(network);
          }
          return unique;
        });

        // Return raw token data with currentPrice for fiat buy crypto screen
        return {
          'id': token['id'],
          'symbol': token['symbol'],
          'name': token['name'],
          'currentPrice': token['currentPrice'] ?? 0.0,
          'metadata': metadata,
          'networks': uniqueNetworks,
          'iconUrl': metadata['icon'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting available coins with prices');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> calculateWithdrawalFee({
    required String tokenId,
    required double amount,
    required String networkVersion,
    required String network,
  }) async {
    try {
      final response = await _dio.post(
        '/wallets/calculate-withdrawal-fee',
        data: {
          'tokenId': tokenId,
          'amount': amount,
          'networkVersion': networkVersion,
          'network': network,
        },
        options: Options(headers: await _getAuthHeaders()),
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'];
        switch (e.response?.statusCode) {
          case 400:
            throw message ?? 'Invalid withdrawal request';
          case 404:
            throw 'Token or network configuration not found';
          default:
            throw 'Failed to calculate withdrawal fee';
        }
      }
      throw 'An error occurred while calculating fee';
    }
  }

  Future<Map<String, dynamic>> createWithdrawal({
    required String tokenId,
    required String amount,
    required String address,
    required String networkVersion,
    required String network,
    String? memo,
    String? tag,
    String? password,
    String? twoFactorCode,
  }) async {
    try {
      // Add only debug logs
      print('Withdrawal request network config:');
      print('  Network: $network');
      print('  Version: $networkVersion');
      print('  Token ID: $tokenId');

      final response = await _dio.post(
        '/wallets/withdraw',
        data: {
          'tokenId': tokenId,
          'amount': double.parse(amount),
          'address': address,
          'networkVersion': networkVersion,
          'network': network,
          'memo': memo,
          'tag': tag,
          if (password != null) 'password': password,
          if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
        },
      );
      return response.data;
    } catch (e) {
      print('Error creating withdrawal');
      rethrow;
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> createAddressBookEntry({
    required String name,
    required String address,
    required String blockchain,
    required String network,
    String? memo,
    String? tag,
  }) async {
    final token = await storage.read(key: 'token');

    await _dio.post(
      '/wallets/address-book',
      data: {
        'name': name,
        'address': address,
        'blockchain': blockchain,
        'network': network,
        'memo': memo,
        'tag': tag,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<bool> checkAddressExists(
      String address, String blockchain, String network) async {
    final token = await storage.read(key: 'accessToken');

    try {
      final response = await _dio.post(
        '/wallets/address-book/check',
        data: {
          'address': address,
          'blockchain': blockchain,
          'network': network,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data is bool) {
        return response.data as bool;
      } else if (response.data is Map) {
        return response.data['exists'] as bool;
      }
      return false;
    } catch (e) {
      print('Error checking address');
      return false;
    }
  }

  Future<List<dynamic>> getAddressBook() async {
    final token = await storage.read(key: 'accessToken');

    try {
      final response = await _dio.get(
        '/wallets/address-book',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response
          .data; // Assuming the response contains the list of addresses
    } catch (e) {
      print('Error fetching address book');
      throw e; // Rethrow the error for handling in the UI
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      // Handle Dio specific errors
      if (error.response != null) {
        return error.response?.data['message'] ?? 'An error occurred';
      } else {
        return 'Network error: ${error.message}';
      }
    }
    return 'An unexpected error occurred';
  }

  Future<Map<String, dynamic>> getWalletBalances(String tokenId) async {
    try {
      // Use the existing getBalances method
      final response = await getBalances();
      final balances = response['balances'] as List<dynamic>;

      // Filter and transform balances for the specific token
      double spotBalance = 0.0;
      double fundingBalance = 0.0;

      for (var balance in balances) {
        if (balance['token']['id'] == tokenId) {
          if (balance['type'] == 'spot') {
            spotBalance = double.tryParse(balance['balance'].toString()) ?? 0.0;
          } else if (balance['type'] == 'funding') {
            fundingBalance =
                double.tryParse(balance['balance'].toString()) ?? 0.0;
          }
        }
      }

      return {
        'spot': spotBalance.toString(),
        'funding': fundingBalance.toString(),
      };
    } catch (e) {
      print('Error getting wallet balances');
      throw 'Failed to load balances';
    }
  }

  Future<void> transferBalance({
    required String tokenId,
    required double amount,
    required String fromType,
    required String toType,
  }) async {
    try {
      await _dio.post(
        '/wallets/transfer',
        data: {
          'tokenId': tokenId,
          'amount': amount,
          'fromType': fromType,
          'toType': toType,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<double> getExchangeRate({
    required String fromTokenId,
    required String toTokenId,
  }) async {
    try {
      print('Fetching exchange rate for tokens:');
      print('From Token ID: $fromTokenId');
      print('To Token ID: $toTokenId');

      final response = await _dio.get(
        '/wallets/exchange-rate',
        queryParameters: {
          'fromTokenId': fromTokenId,
          'toTokenId': toTokenId,
        },
      );

      print('Exchange rate response: ${response.data}');

      if (response.data == null || response.data['exchangeRate'] == null) {
        print('Invalid exchange rate response: ${response.data}');
        throw Exception('Invalid exchange rate response');
      }

      final rate =
          double.tryParse(response.data['exchangeRate'].toString()) ?? 0.0;
      print('Calculated exchange rate: $rate');
      return rate;
    } catch (e) {
      print('Error getting exchange rate');
      return 0.0;
    }
  }

  Future<void> convertToken({
    required String fromTokenId,
    required String toTokenId,
    required double amount,
  }) async {
    try {
      await _dio.post('/wallets/convert', data: {
        'fromTokenId': fromTokenId,
        'toTokenId': toTokenId,
        'amount': amount,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>> getConversionFee({
    required String tokenId,
    required double amount,
  }) async {
    try {
      final response = await _dio.get(
        '/wallets/conversion-fee',
        queryParameters: {
          'tokenId': tokenId,
          'amount': amount,
        },
      );
      return {
        'type': response.data['type'] ?? 'percentage',
        'value': response.data['value']?.toString() ?? '0',
      };
    } catch (e) {
      print('Error getting conversion fee');
      return {
        'type': 'percentage',
        'value': '0',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAllWalletBalances() async {
    try {
      final response = await _dio.get('/wallets/balances');
      return List<Map<String, dynamic>>.from(response.data['balances']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactionHistory({
    int page = 1,
    int limit = 10,
    String? type,
  }) async {
    try {
      print('\n=== Getting Transaction History ===');
      print('Page: $page');
      print('Limit: $limit');
      print('Type: ${type ?? 'all'}');

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      };

      print('Query Parameters: $queryParams');
      print('Endpoint: /wallets/transactions');

      final response = await _dio.get(
        '/wallets/transactions',
        queryParameters: queryParams,
      );

      print('\n=== Transaction History Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Error: Non-200 status code received');
        throw Exception('Failed to fetch transaction history');
      }
    } catch (e) {
      print('\n=== Transaction History Error ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Details');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactionDetails(
      String transactionId) async {
    try {
      print('\n=== Getting Transaction Details ===');
      print('Transaction ID: $transactionId');
      print('Endpoint: /wallets/transactions/$transactionId');

      final response = await _dio.get('/wallets/transactions/$transactionId');

      print('\n=== Transaction Details Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Error: Non-200 status code received');
        throw Exception('Failed to fetch transaction details');
      }
    } catch (e) {
      print('\n=== Transaction Details Error ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Details');
      rethrow;
    }
  }
}

class CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration validity;

  CacheEntry({
    required this.data,
    required this.timestamp,
    this.validity = const Duration(minutes: 1),
  });

  bool get isExpired => DateTime.now().difference(timestamp) > validity;
}
