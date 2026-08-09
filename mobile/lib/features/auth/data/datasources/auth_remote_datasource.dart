// lib/features/auth/data/datasources/auth_remote_datasource.dart
// Calls real backend endpoints documented in auth.controller.ts

import 'package:dio/dio.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/auth/data/models/auth_user_model.dart';

class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  /// POST /auth/register
  /// Requires: email OR phoneNumber + password. username/firstName/lastName optional.
  Future<AuthResponseModel> register({
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    required String password,
  }) async {
    try {
      final body = <String, dynamic>{'password': password};
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phoneNumber != null && phoneNumber.isNotEmpty) body['phoneNumber'] = phoneNumber;
      if (username != null && username.isNotEmpty) body['username'] = username;
      if (firstName != null && firstName.isNotEmpty) body['firstName'] = firstName;
      if (lastName != null && lastName.isNotEmpty) body['lastName'] = lastName;

      final response = await _dio.post('/auth/register', data: body);
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e), code: e.response?.statusCode?.toString());
    }
  }

  /// POST /auth/login
  /// Supports: email + password, phoneNumber + password, or username + password
  Future<AuthResponseModel> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
  }) async {
    try {
      final body = <String, dynamic>{'password': password};
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phoneNumber != null && phoneNumber.isNotEmpty) body['phoneNumber'] = phoneNumber;
      if (username != null && username.isNotEmpty) body['username'] = username;

      final response = await _dio.post('/auth/login', data: body);
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e), code: e.response?.statusCode?.toString());
    }
  }

  /// POST /auth/refresh
  /// Returns new accessToken + refreshToken pair
  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuth': true}), // skip auth interceptor on this call
      );
      final data = response.data as Map<String, dynamic>;
      return {
        'accessToken': data['accessToken'] as String,
        'refreshToken': data['refreshToken'] as String,
      };
    } on DioException catch (e) {
      throw AppException(_parseDioError(e), code: e.response?.statusCode?.toString());
    }
  }

  /// POST /auth/logout  (requires Bearer token — sent automatically by interceptor)
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      // Ignore 401 on logout — session may already be expired
      if (e.response?.statusCode != 401) {
        throw AppException(_parseDioError(e));
      }
    }
  }

  String _parseDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List) return msg.join(', ');
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Could not connect to the server.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
