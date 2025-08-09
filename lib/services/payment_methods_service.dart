import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:io' show File;
import 'dart:convert';
import '../models/payment_method.dart';
import '../models/payment_method_type.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PaymentMethodsService {
  final Dio _dio;
  final storage = const FlutterSecureStorage();

  PaymentMethodsService(this._dio);

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storage.read(key: 'accessToken');
    return {
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<PaymentMethod>> getPaymentMethods(BuildContext context) async {
    try {
      final response = await _dio.get(
        '/payment-methods',
        options: Options(
          headers: await _getAuthHeaders(),
          responseType: ResponseType.json,
        ),
      );

      if (response.data == null) {
        return [];
      }

      try {
        if (response.data is! List) {
          print('Unexpected response data type: ${response.data.runtimeType}');
          return [];
        }

        return (response.data as List).map((json) {
          if (json is! Map<String, dynamic>) {
            print('Invalid payment method data: $json');
            return null;
          }
          try {
            return PaymentMethod.fromJson(json);
          } catch (e) {
            print('Error parsing payment method');
            return null;
          }
        }).whereType<PaymentMethod>().toList();
        
      } catch (e) {
        print('Error parsing payment methods');
        print('Response data: ${response.data}');
        throw 'Failed to parse payment methods data';
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await Provider.of<AuthProvider>(context, listen: false)
              .handleUnauthorized(context);
          throw 'Session expired';
        }
        final message = e.response?.data['message'];
        throw message ?? 'Failed to fetch payment methods';
      }
      print('Error getting payment methods');
      throw 'Failed to fetch payment methods';
    }
  }

  Future<void> createPaymentMethod(
    Map<String, dynamic> data, 
    BuildContext context, {
    String? twoFactorCode,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (twoFactorCode != null) {
        headers['x-2fa-code'] = twoFactorCode;
      }

      await _dio.post(
        '/payment-methods',
        data: data,
        options: Options(headers: headers),
      );
    } catch (e) {
      if (e is DioException) {
        switch (e.response?.statusCode) {
          case 401:
            await Provider.of<AuthProvider>(context, listen: false)
                .handleUnauthorized(context);
            throw 'Session expired';
          case 413:
            throw 'Image size is too large. Please use a smaller image (max 10MB).';
          default:
            throw e.response?.data['message'] ?? 'Failed to create payment method';
        }
      }
      throw 'Failed to create payment method';
    }
  }

  Future<dynamic> updatePaymentMethod(String id, Map<String, dynamic> data, BuildContext context, {String? twoFactorCode}) async {
    try {
      final headers = await _getAuthHeaders();
      if (twoFactorCode != null) {
        headers['x-2fa-code'] = twoFactorCode;
      }

      final response = await _dio.patch(
        '/payment-methods/$id',
        data: data,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return PaymentMethod.fromJson(response.data);
      } else {
        throw 'Failed to update payment method';
      }
    } catch (e) {
      if (e is DioException) {
        switch (e.response?.statusCode) {
          case 400:
            if (e.response?.data['message'] == '2FA verification required') {
              return '2FA_REQUIRED';
            }
            throw e.response?.data['message'] ?? 'Failed to update payment method';
          case 401:
            await Provider.of<AuthProvider>(context, listen: false)
                .handleUnauthorized(context);
            throw 'Session expired';
          case 413:
            throw 'Image size is too large. Please use a smaller image (max 10MB).';
          default:
            print('Update error details: ${e.response?.data}');
            throw e.response?.data['message'] ?? 'Failed to update payment method';
        }
      }
      rethrow;
    }
  }

  Future<dynamic> deletePaymentMethod(String id, BuildContext context, {String? twoFactorCode}) async {
    try {
      final headers = await _getAuthHeaders();
      if (twoFactorCode != null) {
        headers['x-2fa-code'] = twoFactorCode;
      }

      final response = await _dio.delete(
        '/payment-methods/$id',
        options: Options(headers: headers),
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await Provider.of<AuthProvider>(context, listen: false)
              .handleUnauthorized(context);
          throw 'Session expired';
        }
        throw e.response?.data['message'] ?? 'Failed to delete payment method';
      }
      rethrow;
    }
  }

  Future<List<PaymentMethodType>> getPaymentMethodTypes(BuildContext context) async {
    try {
      final response = await _dio.get(
        '/payment-methods/types',
        options: Options(headers: await _getAuthHeaders()),
      );

      return (response.data as List).map((json) {
        // Convert the icon string to IconData if needed
        final type = PaymentMethodType.fromJson(json);
        return type;
      }).toList();
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await Provider.of<AuthProvider>(context, listen: false)
              .handleUnauthorized(context);
          throw 'Session expired';
        }
        final message = e.response?.data['message'];
        throw message ?? 'Failed to fetch payment method types';
      }
      throw 'Failed to fetch payment method types';
    }
  }

  Future<PaymentMethodType> getPaymentMethodType(String id, BuildContext context) async {
    try {
      final response = await _dio.get(
        '/payment-methods/types/$id',
        options: Options(headers: await _getAuthHeaders()),
      );

      return PaymentMethodType.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await Provider.of<AuthProvider>(context, listen: false)
              .handleUnauthorized(context);
          throw 'Session expired';
        }
        final message = e.response?.data['message'];
        throw message ?? 'Failed to fetch payment method type';
      }
      throw 'Failed to fetch payment method type';
    }
  }

  Future<String> getImageUrl(String filename, BuildContext context) async {
    try {
      final response = await _dio.get(
        '/payment-methods/images/$filename',
        options: Options(
          headers: await _getAuthHeaders(),
          responseType: ResponseType.bytes,
        ),
      );
      
      if (response.data == null) {
        throw 'Failed to load image data';
      }

      // Convert response to base64
      final bytes = response.data as List<int>;
      final base64Image = base64.encode(bytes);
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      print('Image loading error');
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await Provider.of<AuthProvider>(context, listen: false)
              .handleUnauthorized(context);
          throw 'Session expired';
        }
        throw e.response?.data['message'] ?? 'Failed to load image';
      }
      rethrow;
    }
  }

  Future<String> compressAndEncodeImage(String base64Image) async {
    try {
      // Extract image data
      final String mimeType = base64Image.split(',')[0].split(':')[1].split(';')[0];
      final String base64Data = base64Image.split(',')[1];
      
      // Decode base64 to bytes
      final bytes = base64.decode(base64Data);
      
      // Compress image
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 800,
        minWidth: 800,
        quality: 70,
      );
      
      // Convert back to base64
      final compressedBase64 = base64.encode(compressedBytes);
      return 'data:$mimeType;base64,$compressedBase64';
    } catch (e) {
      print('Error compressing image');
      return base64Image; // Return original if compression fails
    }
  }
} 