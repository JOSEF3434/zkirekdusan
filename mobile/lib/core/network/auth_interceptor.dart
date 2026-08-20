// lib/core/network/auth_interceptor.dart
// Attaches Bearer token to requests.
// On 401: executes single in-flight silent token refresh with mutex.
// On second 401 / missing refresh token: clears session once and redirects to /login.

import 'dart:async';
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

  // Single in-flight refresh mutex to prevent parallel refresh loops
  static Future<String?>? _inFlightRefresh;

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

    try {
      // If a refresh is already in progress, wait for it
      String? newAccessToken;
      if (_inFlightRefresh != null) {
        newAccessToken = await _inFlightRefresh;
      } else {
        _inFlightRefresh = _performSilentRefresh();
        newAccessToken = await _inFlightRefresh;
        _inFlightRefresh = null;
      }

      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _clearSessionAndRedirect();
        return handler.next(err);
      }

      // Retry original request with the fresh access token
      final retryDio = Dio(
        BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await retryDio.fetch(err.requestOptions);
      return handler.resolve(retryResponse);
    } catch (e) {
      _inFlightRefresh = null;
      appLogger.w('Silent refresh failed: $e — clearing session');
      await _clearSessionAndRedirect();
      return handler.next(err);
    }
  }

  Future<String?> _performSilentRefresh() async {
    try {
      final storage = _ref.read(storageServiceProvider);
      final refreshToken = await storage.getToken(key: _kRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

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

      final data = parseEnvelope(refreshResponse.data);
      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        return null;
      }

      await storage.saveToken(newAccessToken, key: _kAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await storage.saveToken(newRefreshToken, key: _kRefreshToken);
      }

      appLogger.d('Token refreshed successfully');
      return newAccessToken;
    } catch (e) {
      appLogger.e('Error during _performSilentRefresh: $e');
      return null;
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
      // Router may not be mounted during startup
    }
  }
}
