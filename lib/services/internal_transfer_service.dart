import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'service_locator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InternalTransferService {
  late final Dio _dio;
  final storage = const FlutterSecureStorage();

  InternalTransferService() {
    _dio = GetIt.I<Dio>();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storage.read(key: 'accessToken');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Validate receiver by email or traderId
  Future<Map<String, dynamic>> validateReceiver(
    String receiver,
    String type, // 'email' or 'traderId'
  ) async {
    try {
      final response = await _dio.post(
        '/wallets/internal-transfer/validate-receiver',
        data: {
          'receiver': receiver,
          'type': type,
        },
        options: Options(headers: await _getAuthHeaders()),
      );

      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        final responseData = e.response?.data;
        final message = responseData?['message'] ?? 'Unknown error occurred';

        // Provide user-friendly error messages
        switch (e.response?.statusCode) {
          case 400:
            if (message.contains('Cannot transfer to yourself')) {
              throw 'You cannot transfer to yourself';
            } else if (message.contains('Invalid receiver')) {
              throw 'Invalid receiver format';
            } else {
              throw message;
            }
          case 404:
            throw 'Receiver not found';
          case 422:
            throw 'Invalid receiver format';
          default:
            throw 'Failed to validate receiver';
        }
      }
      throw 'An error occurred while validating receiver';
    }
  }

  /// Calculate internal transfer fee
  Future<Map<String, dynamic>> calculateInternalTransferFee({
    required String tokenId,
    required double amount,
    required String receiverId,
  }) async {
    try {
      final response = await _dio.post(
        '/wallets/internal-transfer/calculate-fee',
        data: {
          'tokenId': tokenId,
          'amount': amount,
          'receiverId': receiverId,
        },
        options: Options(headers: await _getAuthHeaders()),
      );

      print('🔐 Calculate Fee API Response:');
      print('   - Status code: ${response.statusCode}');
      print('   - Full response: ${response.data}');
      print('   - Data field: ${response.data['data']}');

      final data = response.data['data'];
      if (data == null) {
        throw 'Invalid response format: missing data field';
      }

      return Map<String, dynamic>.from(data);
    } catch (e) {
      print('🔐 Calculate Fee Error: $e');
      if (e is DioException) {
        final responseData = e.response?.data;
        final message = responseData?['message'] ?? 'Unknown error occurred';

        // Provide user-friendly error messages
        switch (e.response?.statusCode) {
          case 400:
            if (message.contains('Invalid transfer request')) {
              throw 'Invalid transfer request';
            } else if (message.contains('Insufficient balance')) {
              throw 'Insufficient balance for this transfer';
            } else {
              throw message;
            }
          case 404:
            throw 'Token configuration not found';
          case 422:
            throw 'Invalid transfer parameters';
          default:
            throw 'Failed to calculate transfer fee';
        }
      }
      throw 'An error occurred while calculating fee';
    }
  }

  /// Create internal transfer
  Future<Map<String, dynamic>> createInternalTransfer({
    required String tokenId,
    required String amount,
    String? receiverEmail,
    String? receiverTraderId,
    String? memo,
    String? tag,
    String? password,
    String? twoFactorCode,
  }) async {
    try {
      final requestData = {
        'tokenId': tokenId,
        'amount': double.parse(amount),
        if (receiverEmail != null) 'receiverEmail': receiverEmail,
        if (receiverTraderId != null) 'receiverTraderId': receiverTraderId,
        if (memo != null) 'memo': memo,
        if (tag != null) 'tag': tag,
        if (password != null) 'password': password,
        if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
      };

      print('🔐 Internal Transfer API Request:');
      print('   - tokenId: $tokenId');
      print('   - amount: $amount');
      print('   - receiverEmail: ${receiverEmail ?? "null"}');
      print('   - receiverTraderId: ${receiverTraderId ?? "null"}');
      print('   - password: ${password != null ? "provided" : "null"}');
      print(
          '   - twoFactorCode: ${twoFactorCode != null ? "provided" : "null"}');

      final response = await _dio.post(
        '/wallets/internal-transfer',
        data: requestData,
        options: Options(headers: await _getAuthHeaders()),
      );

      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      print('Error creating internal transfer: ${e.toString()}');

      if (e is DioException) {
        final responseData = e.response?.data;
        final message = responseData?['message'] ?? 'Unknown error occurred';

        // Provide user-friendly error messages
        switch (e.response?.statusCode) {
          case 400:
            if (message.contains('Cannot transfer to yourself')) {
              throw 'You cannot transfer to yourself';
            } else if (message.contains('Insufficient balance')) {
              throw 'Insufficient balance for this transfer';
            } else if (message.contains('Invalid amount')) {
              throw 'Invalid transfer amount';
            } else if (message.contains('Receiver not found')) {
              throw 'Receiver not found';
            } else if (message.contains('Receiver account is not active')) {
              throw 'Receiver account is not active';
            } else {
              throw message;
            }
          case 401:
            throw 'Authentication failed. Please log in again.';
          case 403:
            throw 'You are not authorized to perform this action';
          case 404:
            throw 'Transfer service not found';
          case 422:
            throw 'Invalid transfer request. Please check your input.';
          default:
            throw 'Failed to create transfer. Please try again.';
        }
      }

      throw 'An error occurred while creating the transfer';
    }
  }

  /// Get all internal transfers for the current user
  Future<List<Map<String, dynamic>>> getInternalTransfers({
    String? status,
    String? coin,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) queryParams['status'] = status;
      if (coin != null) queryParams['coin'] = coin;
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _dio.get(
        '/wallets/internal-transfer',
        queryParameters: queryParams,
        options: Options(headers: await _getAuthHeaders()),
      );

      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      print('Error fetching internal transfers: ${e.toString()}');
      rethrow;
    }
  }

  /// Get specific internal transfer by ID
  Future<Map<String, dynamic>> getInternalTransferById(
      String transferId) async {
    try {
      final response = await _dio.get(
        '/wallets/internal-transfer/$transferId',
        options: Options(headers: await _getAuthHeaders()),
      );

      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'];
        switch (e.response?.statusCode) {
          case 404:
            throw 'Transfer not found';
          default:
            throw 'Failed to get transfer details';
        }
      }
      throw 'An error occurred while getting transfer details';
    }
  }

  /// Cancel internal transfer (if allowed)
  Future<Map<String, dynamic>> cancelInternalTransfer(String transferId) async {
    try {
      final response = await _dio.post(
        '/wallets/internal-transfer/$transferId/cancel',
        options: Options(headers: await _getAuthHeaders()),
      );

      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'];
        switch (e.response?.statusCode) {
          case 400:
            throw message ?? 'Cannot cancel this transfer';
          case 404:
            throw 'Transfer not found';
          default:
            throw 'Failed to cancel transfer';
        }
      }
      throw 'An error occurred while cancelling transfer';
    }
  }

  /// Get transfer statistics
  Future<Map<String, dynamic>> getTransferStatistics() async {
    try {
      final response = await _dio.get(
        '/wallets/internal-transfer/statistics/summary',
        options: Options(headers: await _getAuthHeaders()),
      );

      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      print('Error fetching transfer statistics: ${e.toString()}');
      rethrow;
    }
  }
}
