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
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phoneNumber'] = phoneNumber;
      }
      if (username != null && username.isNotEmpty) {
        body['username'] = username;
      }
      if (firstName != null && firstName.isNotEmpty) {
        body['firstName'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        body['lastName'] = lastName;
      }

      final response = await _dio.post('/auth/register', data: body);
      return AuthResponseModel.fromJson(_parseEnvelope(response.data));
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
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
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phoneNumber'] = phoneNumber;
      }
      if (username != null && username.isNotEmpty) {
        body['username'] = username;
      }

      // Login can be the first request after the production service wakes up.
      // Use a longer timeout for this request only so a cold start is not shown
      // as an internet failure.
      final response = await _dio.post(
        '/auth/login',
        data: body,
        options: Options(
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      return AuthResponseModel.fromJson(_parseEnvelope(response.data));
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }

  /// GET /auth/login-config
  /// Fetches the active login policy (publicly accessible)
  Future<Map<String, dynamic>> getLoginPolicyConfig() async {
    try {
      final response = await _dio.get(
        '/auth/login-config',
        options: Options(
          extra: {'skipAuth': true},
        ),
      );
      final raw = _parseEnvelope(response.data);
      return Map<String, dynamic>.from(raw);
    } catch (_) {
      // Graceful fallback to default single identifier
      return {
        'activePolicy': 'SINGLE_IDENTIFIER',
        'allowEmail': true,
        'allowPhone': true,
        'allowUsername': true,
      };
    }
  }

  /// POST /auth/refresh
  /// Returns new accessToken + refreshToken pair
  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {'skipAuth': true},
        ), // skip auth interceptor on this call
      );
      final data = _parseEnvelope(response.data);
      return {
        'accessToken': data['accessToken'] as String,
        'refreshToken': data['refreshToken'] as String,
      };
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
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

  /// GET /auth/me
  /// Retrieves the current user's details
  Future<AuthUserModel> me() async {
    try {
      final response = await _dio.get('/auth/me');
      final data = _parseEnvelope(response.data);
      return AuthUserModel.fromJson(data);
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }

  /// POST /auth/google
  /// Authenticates with a verified Google ID token
  Future<AuthResponseModel> loginWithGoogle({required String idToken}) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {'idToken': idToken},
        options: Options(
          extra: {'skipAuth': true},
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      return AuthResponseModel.fromJson(_parseEnvelope(response.data));
    } on DioException catch (e) {
      String? errorCode;
      final data = e.response?.data;
      if (data is Map) {
        errorCode = data['code']?.toString();
      }
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
        details: errorCode,
      );
    }
  }

  /// POST /auth/google/link-account
  /// Links a Google identity to an existing account using password credentials
  Future<AuthResponseModel> linkGoogleAccount({
    required String idToken,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/google/link-account',
        data: {'idToken': idToken, 'password': password},
        options: Options(
          extra: {'skipAuth': true},
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      return AuthResponseModel.fromJson(_parseEnvelope(response.data));
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }

  /// GET /auth/identities
  /// Fetches external authentication identities and password status
  Future<Map<String, dynamic>> getIdentities() async {
    try {
      final response = await _dio.get('/auth/identities');
      final data = _parseEnvelope(response.data);
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }

  /// POST /auth/google/connect
  /// Links Google identity to current authenticated session
  Future<void> connectGoogle({required String idToken}) async {
    try {
      await _dio.post(
        '/auth/google/connect',
        data: {'idToken': idToken},
      );
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }

  /// POST /auth/google/disconnect
  /// Disconnects Google identity from current authenticated account
  Future<void> disconnectGoogle() async {
    try {
      await _dio.post('/auth/google/disconnect');
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }

  String _parseDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['error'] ?? data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      if (msg is List && msg.isNotEmpty) return msg.join(', ');
      final details = data['details'];
      if (details is String && details.isNotEmpty) return details;
      if (details is List && details.isNotEmpty) return details.join(', ');
    }
    final status = e.response?.statusCode;
    if (status == 401) {
      return 'Invalid credentials';
    }
    if (status == 403) {
      return 'Access forbidden. Please check your permissions.';
    }
    if (status == 404) {
      return 'Account or resource not found.';
    }
    if (status == 409) {
      return 'An account with this email, phone, or username already exists.';
    }
    if (status == 422) {
      return 'Validation failed. Please check the information provided.';
    }
    if (status == 429) {
      return 'Too many attempts. Please try again in a few minutes.';
    }
    if (status != null && status >= 500) {
      return 'Server is temporarily unavailable. Please try again later.';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Could not connect to the server. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  Map<String, dynamic> _parseEnvelope(dynamic data) {
    Map<String, dynamic> map;
    if (data is Map<String, dynamic>) {
      map = data;
    } else if (data is Map) {
      map = data.cast<String, dynamic>();
    } else {
      throw AppException(
        'Unexpected response format from server (not JSON map).',
      );
    }

    if (map.containsKey('success') && map.containsKey('data')) {
      if (map['success'] != true) {
        throw AppException(map['message']?.toString() ?? 'Request failed');
      }
      final payload = map['data'];
      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) return payload.cast<String, dynamic>();
      throw AppException(
        'Unexpected payload format in envelope (data is not a JSON map).',
      );
    }

    // Fallback if the backend stops using the envelope format
    return map;
  }

  // ── Password Recovery Methods ──────────────────────────────────────────────

  /// POST /auth/forgot-password
  Future<Map<String, dynamic>> requestPasswordRecovery({
    String? method,
    String? identifier,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (method != null) body['method'] = method;
      if (identifier != null && identifier.isNotEmpty) {
        body['identifier'] = identifier;
      }
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phoneNumber'] = phoneNumber;
      }

      final response = await _dio.post(
        '/auth/forgot-password',
        data: body,
        options: Options(extra: {'skipAuth': true}),
      );
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }

  /// POST /auth/recovery/verify
  Future<Map<String, dynamic>> verifyRecoveryCode({
    required String method,
    required String destination,
    String? code,
    String? token,
  }) async {
    try {
      final body = <String, dynamic>{
        'method': method,
        'destination': destination,
      };
      if (code != null) body['code'] = code;
      if (token != null) body['token'] = token;

      final response = await _dio.post(
        '/auth/recovery/verify',
        data: body,
        options: Options(extra: {'skipAuth': true}),
      );
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }

  /// GET /auth/recovery/validate-token
  Future<Map<String, dynamic>> validateRecoveryToken(String token) async {
    try {
      final response = await _dio.get(
        '/auth/recovery/validate-token',
        queryParameters: {'token': token},
        options: Options(extra: {'skipAuth': true}),
      );
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }

  /// POST /auth/recovery/resend
  Future<Map<String, dynamic>> resendRecoveryCode({
    required String method,
    required String identifier,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/recovery/resend',
        data: {'method': method, 'identifier': identifier},
        options: Options(extra: {'skipAuth': true}),
      );
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }

  /// POST /auth/reset-password
  Future<Map<String, dynamic>> resetPassword({
    String? method,
    String? destination,
    String? code,
    String? token,
    String? resetToken,
    required String password,
  }) async {
    try {
      final body = <String, dynamic>{'password': password};
      if (method != null) body['method'] = method;
      if (destination != null) body['destination'] = destination;
      if (code != null) body['code'] = code;
      if (token != null) body['token'] = token;
      if (resetToken != null) body['resetToken'] = resetToken;

      final response = await _dio.post(
        '/auth/reset-password',
        data: body,
        options: Options(extra: {'skipAuth': true}),
      );
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw AppException(
        _parseDioError(e),
        code: e.response?.statusCode?.toString(),
      );
    }
  }
}
