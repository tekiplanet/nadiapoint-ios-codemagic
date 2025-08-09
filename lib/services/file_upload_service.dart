import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import '../services/auth_service.dart';

class FileUploadService {
  late final Dio _dio;
  final storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  FileUploadService() {
    final baseUrl = _authService.baseUrl.replaceAll('/auth', '');
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
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
          print('Error Response: ${error.response?.data}');
          print('Error Status Code: ${error.response?.statusCode}');
          print('Error Headers: ${error.response?.headers}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Upload a file and return the file upload response
  Future<Map<String, dynamic>> uploadFile(File file, {String? folder}) async {
    try {
      // Debug: Print file information
      print('Uploading file: ${file.path}');
      print('File exists: ${await file.exists()}');
      print('File size: ${await file.length()} bytes');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'category': 'documents', // Default category for proof of payment
        'folder': folder ?? 'proof-of-payment',
      });

      print(
          'FormData created with fields: ${formData.fields.map((e) => '${e.key}: ${e.value}')}');
      print(
          'FormData files: ${formData.files.map((e) => '${e.key}: ${e.value.filename}')}');

      final response = await _dio.post('/file-upload', data: formData);
      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      print('Error uploading file: ${e.toString()}');
      rethrow;
    }
  }

  /// Upload multiple files
  Future<List<Map<String, dynamic>>> uploadFiles(List<File> files,
      {String? folder}) async {
    try {
      final formData = FormData();

      for (int i = 0; i < files.length; i++) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              files[i].path,
              filename: files[i].path.split('/').last,
            ),
          ),
        );
      }

      formData.fields.addAll([
        MapEntry('category', 'documents'),
        MapEntry('folder', folder ?? 'proof-of-payment'),
      ]);

      final response = await _dio.post('/file-upload/multiple', data: formData);
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      print('Error uploading files: ${e.toString()}');
      rethrow;
    }
  }
}
