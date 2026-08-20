// lib/core/error/exceptions.dart
import 'dart:developer' as developer;
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
  final int? statusCode;
  final String? path;

  Failure(this.message, {this.statusCode, this.path});

  @override
  String toString() => message;

  factory Failure.fromException(dynamic exception) {
    if (exception is Failure) {
      return exception;
    }

    if (exception is AppException) {
      return Failure(exception.message);
    }

    if (exception is DioException) {
      final statusCode = exception.response?.statusCode;
      final path = exception.requestOptions.path;
      final data = exception.response?.data;

      String? serverMessage;
      if (data is Map<String, dynamic>) {
        final rawMsg = data['message'] ?? data['error'];
        if (rawMsg is List) {
          serverMessage = rawMsg.join(', ');
        } else if (rawMsg != null) {
          serverMessage = rawMsg.toString();
        }
      }

      developer.log(
        '[DioFailure] $path | status: $statusCode | type: ${exception.type} | msg: $serverMessage',
      );

      switch (exception.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutFailure(
            'Connection timed out. Please check your network.',
            statusCode: statusCode,
            path: path,
          );

        case DioExceptionType.connectionError:
          return NetworkFailure(
            'Unable to connect to server. Please check your connection.',
            statusCode: statusCode,
            path: path,
          );

        case DioExceptionType.badResponse:
          if (statusCode == 401) {
            return UnauthorizedFailure(
              serverMessage ?? 'Session expired. Please sign in again.',
              statusCode: statusCode,
              path: path,
            );
          } else if (statusCode == 403) {
            return ForbiddenFailure(
              serverMessage ?? 'You do not have permission to access this resource.',
              statusCode: statusCode,
              path: path,
            );
          } else if (statusCode == 404) {
            return NotFoundFailure(
              serverMessage ?? 'Resource not found.',
              statusCode: statusCode,
              path: path,
            );
          } else if (statusCode != null && statusCode >= 500) {
            return ServerFailure(
              serverMessage ?? 'Server is temporarily unavailable. Please try again later.',
              statusCode: statusCode,
              path: path,
            );
          }
          return Failure(
            serverMessage ?? 'Request failed ($statusCode)',
            statusCode: statusCode,
            path: path,
          );

        case DioExceptionType.cancel:
          return Failure('Request cancelled', statusCode: statusCode, path: path);

        default:
          return NetworkFailure(
            'Network communication error. Please try again.',
            statusCode: statusCode,
            path: path,
          );
      }
    }

    return Failure(exception.toString());
  }
}

class UnauthorizedFailure extends Failure {
  UnauthorizedFailure(super.message, {super.statusCode, super.path});
}

class ForbiddenFailure extends Failure {
  ForbiddenFailure(super.message, {super.statusCode, super.path});
}

class NotFoundFailure extends Failure {
  NotFoundFailure(super.message, {super.statusCode, super.path});
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message, {super.statusCode, super.path});
}

class TimeoutFailure extends Failure {
  TimeoutFailure(super.message, {super.statusCode, super.path});
}

class ServerFailure extends Failure {
  ServerFailure(super.message, {super.statusCode, super.path});
}
