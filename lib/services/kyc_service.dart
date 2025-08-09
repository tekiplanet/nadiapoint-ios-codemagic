import 'package:dio/dio.dart';
import '../models/kyc_level.dart';
import '../models/kyc_details.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KYCService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  KYCService(Dio dio) : _dio = dio {
    _dio.options.baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<KYCDetails> getUserKYCDetails() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '/kyc/details',
        options: Options(headers: headers),
      );
      
      if (response.statusCode == 200) {
        return KYCDetails.fromJson(response.data);
      } else {
        throw Exception('Failed to load KYC details: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('Connection timeout. Please check your internet connection.');
        } else if (e.response?.statusCode == 401) {
          throw Exception('Unauthorized. Please log in again.');
        }
        throw Exception('Network error: ${e.message}');
      }
      rethrow;
    }
  }

  Future<List<KYCLevel>> getAllKYCLevels() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '/kyc/levels',
        options: Options(headers: headers),
      );
      
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((level) => KYCLevel.fromJson(level))
            .toList();
      } else {
        throw Exception('Failed to load KYC levels');
      }
    } catch (e) {
      print('Error getting KYC levels');
      rethrow;
    }
  }

  Future<Map<String, String>> startDocumentVerification() async {
    try {
      final token = await getAccessToken();
      
      return {
        'token': token,
        'status': 'pending',
        'message': 'Please complete your verification',
      };
    } catch (e) {
      print('Error starting document verification');
      rethrow;
    }
  }

  Future<void> startAddressVerification() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '/kyc/access-token',
        options: Options(headers: headers),
      );
      
      if (response.statusCode == 200) {
        return response.data['token'];
      }
      
      throw Exception('Failed to get access token');
    } catch (e) {
      print('Address verification error');
      rethrow;
    }
  }

  Future<Map<String, String>> getVerificationStatus() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      final response = await _dio.get(
        '/kyc/verification-status',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return {
        'status': response.data['status'],
        'message': response.data['message'],
      };
    } catch (e) {
      print('Error getting verification status');
      rethrow;
    }
  }

  Future<void> submitIdentityDetails({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String address,
    required String city,
    required String state,
    required String country,
  }) async {
    try {
      // Validate all fields are present
      if (firstName.isEmpty || lastName.isEmpty || dateOfBirth.isEmpty || 
          address.isEmpty || city.isEmpty || state.isEmpty || country.isEmpty) {
        throw Exception('All fields are required');
      }

      // Validate date format (should be YYYY-MM-DD)
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateOfBirth)) {
        throw Exception('Invalid date format. Expected YYYY-MM-DD');
      }

      final headers = await _getAuthHeaders();
      final response = await _dio.put(
        '/auth/identity-details',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'dateOfBirth': dateOfBirth,
          'address': address,
          'city': city,
          'state': state,
          'country': country,
        },
        options: Options(
          headers: headers,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      return response.data;
    } catch (e) {
      print('Technical error details');
      
      if (e is DioException) {
        // Add detailed error logging
        print('Status code: ${e.response?.statusCode}');
        print('Response data: ${e.response?.data}');
        print('Error message: ${e.message}');
        print('Error type: ${e.type}');
        print('Stack trace: ${e.stackTrace}');
        
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.sendTimeout || 
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Unable to connect to server. Please check your internet connection and try again.');
        }
        
        if (e.response?.statusCode == 500) {
          throw Exception('We\'re experiencing technical difficulties. Please try again later.');
        }

        final responseData = e.response?.data;
        final errorMessage = responseData is Map ? responseData['message'] ?? 'Unknown error' : 'Unknown error';
        throw Exception('Unable to submit your details. Please try again later.');
      }
      rethrow;
    }
  }

  Future<String> getAccessToken() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '/kyc/access-token',
        options: Options(headers: headers),
      );
      
      return response.data['token'];
    } catch (e) {
      print('Error getting access token');
      rethrow;
    }
  }

  Future<String> startAdvancedVerification() async {
    try {
      // Get auth headers with token
      final headers = await _getAuthHeaders();
      
      final response = await _dio.post(
        '/kyc/advanced-verification',
        options: Options(headers: headers),  // Add auth headers
      );
      
      if (response.data['token'] != null) {
        return response.data['token'];
      }
      
      throw Exception('Failed to get verification token');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('Please complete Level 2 verification first');
      }
      throw Exception('Failed to start advanced verification: ${e.toString()}');
    }
  }
}