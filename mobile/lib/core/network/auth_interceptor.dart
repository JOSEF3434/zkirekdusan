// lib/core/network/auth_interceptor.dart
// Attaches Bearer token to requests.
// On 401: attempts silent token refresh. On second 401: clears session + redirects.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // Skip token injection for requests tagged with skipAuth
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

    // Skip refresh retry for the refresh endpoint itself to avoid loops
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

      // Use a separate Dio instance (no interceptors) to avoid recursion
      final refreshDio = Dio(BaseOptions(baseUrl: err.requestOptions.baseUrl));
      final refreshResponse = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = refreshResponse.data as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await storage.saveToken(newAccessToken, key: _kAccessToken);
      await storage.saveToken(newRefreshToken, key: _kRefreshToken);

      appLogger.d('Token refreshed silently');

      // Retry original request with new token
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await Dio().fetch(err.requestOptions);
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
