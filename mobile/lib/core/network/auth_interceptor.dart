// lib/core/network/auth_interceptor.dart
// Attaches Bearer token to requests.
// On 401: attempts silent token refresh using the backend envelope format.
// On second 401 / missing refresh token: clears session and redirects to /login.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/env/env.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:go_router/go_router.dart';

const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }

    final storage = _ref.read(storageServiceProvider);
    final token = await storage.getToken(key: _kAccessToken);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;
    if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
      await _clearSessionAndRedirect();
      return handler.next(err);
    }

    // Attempt silent token refresh
    try {
      final storage = _ref.read(storageServiceProvider);
      final refreshToken = await storage.getToken(key: _kRefreshToken);
      if (refreshToken == null) {
        await _clearSessionAndRedirect();
        return handler.next(err);
      }

      // Use a dedicated Dio (no interceptors) to avoid recursive 401 loops
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final refreshResponse = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      // Unwrap envelope – backend wraps tokens inside {success, data:{accessToken,refreshToken}}
      final data = parseEnvelope(refreshResponse.data);
      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw Exception('Refresh response missing accessToken');
      }

      await storage.saveToken(newAccessToken, key: _kAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await storage.saveToken(newRefreshToken, key: _kRefreshToken);
      }

      appLogger.d('Token refreshed silently');

      // Retry original request with new token
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await refreshDio.fetch(err.requestOptions);
      return handler.resolve(retryResponse);
    } catch (e) {
      appLogger.w('Silent refresh failed: $e — redirecting to login');
      await _clearSessionAndRedirect();
      return handler.next(err);
    }
  }

  Future<void> _clearSessionAndRedirect() async {
    final storage = _ref.read(storageServiceProvider);
    await storage.deleteToken(key: _kAccessToken);
    await storage.deleteToken(key: _kRefreshToken);

    try {
      if (rootNavigatorKey.currentContext != null) {
        rootNavigatorKey.currentContext!.go('/login');
      }
    } catch (_) {
      // Router may not be ready (e.g., during startup)
    }
  }
}
