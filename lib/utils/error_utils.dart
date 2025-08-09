import 'package:dio/dio.dart';

String getFriendlyErrorMessage(dynamic error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }
    switch (error.response?.statusCode) {
      case 502:
      case 503:
      case 504:
        return 'The server is currently unavailable. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
    }
    // Try to extract backend message
    final responseData = error.response?.data;
    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }
  }
  if (error is String) {
    if (error.toLowerCase().contains('already exists')) {
      return 'This item already exists.';
    }
    if (error.toLowerCase().contains('network')) {
      return 'Network error. Please check your connection.';
    }
    if (error.toLowerCase().contains('timeout')) {
      return 'Connection timed out. Please try again.';
    }
    if (!error.contains('Exception:') && !error.contains('Error:')) {
      return error;
    }
  }
  return 'Something went wrong. Please check your connection and try again.';
}
