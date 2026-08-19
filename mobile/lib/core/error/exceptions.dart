import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class Failure {
  final String message;

  Failure(this.message);

  @override
  String toString() => message;

  factory Failure.fromException(dynamic exception) {
    if (exception is AppException) {
      return Failure(exception.message);
    } else if (exception is DioException) {
      // Handle standard Dio errors
      if (exception.type == DioExceptionType.connectionTimeout ||
          exception.type == DioExceptionType.receiveTimeout) {
        return Failure('Connection timeout');
      } else if (exception.type == DioExceptionType.badResponse) {
        final data = exception.response?.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          return Failure(data['message']);
        }
        return Failure('Server error: ${exception.response?.statusCode}');
      }
      return Failure('Network error occurred');
    }
    return Failure(exception.toString());
  }
}
