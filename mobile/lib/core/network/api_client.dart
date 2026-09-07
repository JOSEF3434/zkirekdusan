// lib/core/network/api_client.dart
// Central Dio client with envelope parsing utility exposed for all repositories.

import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/env/env.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/network/auth_interceptor.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(PrefixFallbackInterceptor(dio));

  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ),
  );

  return dio;
});

/// Interceptor that handles backend routing discrepancies between environments
/// where some routes (such as `/videos/*`) are mounted without the global `/api` prefix.
///
/// If a request to an `/api/...` endpoint returns a 404 with a routing error
/// (e.g. `Cannot GET /api/...`) or is a route known to be mounted at root
/// (e.g. `/videos`), this interceptor automatically strips the `/api` prefix
/// and retries the request against the root host.
///
/// Once confirmed working, the route prefix is memorized in memory so subsequent
/// requests skip the failed `/api` attempt and execute immediately.
class PrefixFallbackInterceptor extends Interceptor {
  final Dio _dio;

  PrefixFallbackInterceptor(this._dio);

  /// Set of route prefixes that have been detected to be mounted at root (without /api)
  static final Set<String> _rootMountedPrefixes = {};

  /// Resets cached prefixes for testing
  static void resetRootMountedPrefixes() {
    _rootMountedPrefixes.clear();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    final isRootMounted = _rootMountedPrefixes.any(
      (prefix) => path.startsWith(prefix) || path.startsWith('/$prefix'),
    );

    if (isRootMounted && options.baseUrl.endsWith('/api')) {
      options.baseUrl = options.baseUrl.substring(
        0,
        options.baseUrl.length - 4,
      );
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final reqOptions = err.requestOptions;

    // Only retry on 404 routing error if not already retried
    if (response?.statusCode == 404 &&
        reqOptions.extra['prefix_fallback_retried'] != true) {
      final uri = reqOptions.uri;
      final uriPath = uri.path;

      // Check if URL currently has /api
      if (uriPath.startsWith('/api/') || uriPath == '/api') {
        final bodyStr = response?.data?.toString() ?? '';
        final isRoutingNotFound = bodyStr.contains('Cannot GET /api/') ||
            bodyStr.contains('Cannot POST /api/') ||
            bodyStr.contains('Cannot PATCH /api/') ||
            bodyStr.contains('Cannot DELETE /api/') ||
            bodyStr.contains('Cannot PUT /api/');

        final isKnownRootRoute = reqOptions.path.startsWith('/videos') ||
            reqOptions.path.startsWith('videos');

        if (isRoutingNotFound || isKnownRootRoute) {
          final newPath = uriPath.replaceFirst(RegExp(r'^/api(?=/|$)'), '');
          final fallbackUrl = uri.replace(path: newPath).toString();

          try {
            developer.log(
              '[PrefixFallback] 404 on ${reqOptions.uri} -> Retrying without /api: $fallbackUrl',
            );

            final retryResponse = await _dio.fetch(
              reqOptions.copyWith(
                baseUrl: '',
                path: fallbackUrl,
                queryParameters: const {},
                extra: {
                  ...reqOptions.extra,
                  'prefix_fallback_retried': true,
                },
              ),
            );

            // Remember that this prefix succeeds without /api
            if (reqOptions.path.startsWith('/videos') ||
                reqOptions.path.startsWith('videos')) {
              _rootMountedPrefixes.add('/videos');
            }

            return handler.resolve(retryResponse);
          } catch (retryErr) {
            developer.log(
              '[PrefixFallback] Retry failed for $fallbackUrl: $retryErr',
            );
            if (retryErr is DioException) {
              return handler.next(retryErr);
            }
          }
        }
      }
    }

    handler.next(err);
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Safely casts [raw] to `Map<String, dynamic>`. Returns null on failure.
Map<String, dynamic>? _tryAsMap(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    try {
      return raw.cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Public envelope helpers
// ---------------------------------------------------------------------------

/// Unwraps the NestJS `{success, data, timestamp}` envelope.
///
/// Handles:
/// - `{success: true, data: {...}}` → returns the data map
/// - `{success: true, data: null}` → returns `{}`
/// - `{success: true, data: [...]}` → returns `{'items': [...]}`
/// - No envelope → returns map as-is
/// Throws [AppException] only when `success == false`.
Map<String, dynamic> parseEnvelope(dynamic raw) {
  if (raw == null) {
    developer.log('[parseEnvelope] null response → returning {}');
    return {};
  }

  final map = _tryAsMap(raw);
  if (map == null) {
    if (raw is List) return {'items': raw};
    developer.log('[parseEnvelope] unexpected type ${raw.runtimeType} → {}');
    return {};
  }

  if (map.containsKey('success')) {
    if (map['success'] != true) {
      final msg = map['message'] ?? map['error'];
      throw AppException(
        msg is List ? (msg).join(', ') : (msg?.toString() ?? 'Request failed.'),
      );
    }
    final payload = map['data'];
    final payloadMap = _tryAsMap(payload);
    if (payloadMap != null) return payloadMap;
    if (payload == null) return {};
    if (payload is List) return {'items': payload};
    developer.log('[parseEnvelope] data is ${payload.runtimeType} → {}');
    return {};
  }

  return map;
}

/// Unwraps a list payload from the envelope.
///
/// Accepts:
/// - `{success: true, data: [...]}` → returns list
/// - `{success: true, data: null}` → returns `[]`
/// - Bare list → returns as-is
/// - `{success: true, data: {data: [...]}}` → extracts nested list
List<dynamic> parseEnvelopeList(dynamic raw) {
  if (raw == null) {
    developer.log('[parseEnvelopeList] null response → []');
    return [];
  }

  if (raw is List) return raw;

  final map = _tryAsMap(raw);
  if (map == null) {
    developer.log(
      '[parseEnvelopeList] unexpected type ${raw.runtimeType} → []',
    );
    return [];
  }

  if (map.containsKey('success')) {
    if (map['success'] != true) {
      final msg = map['message'];
      throw AppException(
        msg is List ? (msg).join(', ') : (msg?.toString() ?? 'Request failed.'),
      );
    }
    final payload = map['data'];
    if (payload is List) return payload;
    if (payload == null) return [];
    final payloadMap = _tryAsMap(payload);
    if (payloadMap != null) {
      if (payloadMap['data'] is List) return payloadMap['data'] as List;
      if (payloadMap['items'] is List) return payloadMap['items'] as List;
    }
    developer.log('[parseEnvelopeList] cannot extract list → []');
    return [];
  }

  if (map['data'] is List) return map['data'] as List;
  if (map['items'] is List) return map['items'] as List;

  developer.log('[parseEnvelopeList] no list in response → []');
  return [];
}

/// Parses a paginated response into a normalized map:
/// `{'data': List<dynamic>, 'meta': Map<String, dynamic>}`.
///
/// Safely handles all backend response shapes:
/// - `{success, data: {data: [...], meta: {...}}}` — standard paginated
/// - `{success, data: [...]}` — bare list in envelope
/// - `{success, data: null}` — empty result
/// - `[...]` — bare list
/// - `{data: [...], meta: {...}}` — no envelope wrapper
Map<String, dynamic> parsePaginatedEnvelope(dynamic raw) {
  if (raw == null) {
    developer.log('[parsePaginatedEnvelope] null → empty result');
    return {'data': [], 'meta': {}};
  }

  if (raw is List) {
    return {'data': raw, 'meta': {}};
  }

  final map = _tryAsMap(raw);
  if (map == null) {
    developer.log(
      '[parsePaginatedEnvelope] unexpected type ${raw.runtimeType} → empty',
    );
    return {'data': [], 'meta': {}};
  }

  Map<String, dynamic> dataMap;
  if (map.containsKey('success')) {
    if (map['success'] != true) {
      final msg = map['message'];
      throw AppException(
        msg is List ? (msg).join(', ') : (msg?.toString() ?? 'Request failed.'),
      );
    }
    final payload = map['data'];
    if (payload == null) {
      developer.log('[parsePaginatedEnvelope] data is null → empty');
      return {'data': [], 'meta': {}};
    }
    if (payload is List) {
      return {'data': payload, 'meta': {}};
    }
    final payloadMap = _tryAsMap(payload);
    if (payloadMap == null) {
      developer.log(
        '[parsePaginatedEnvelope] data is ${payload.runtimeType} → empty',
      );
      return {'data': [], 'meta': {}};
    }
    dataMap = payloadMap;
  } else {
    dataMap = map;
  }

  // Normalise: extract items list
  final rawData = dataMap['data'];
  final rawItems = dataMap['items'];
  List<dynamic> items;
  if (rawData is List) {
    items = rawData;
  } else if (rawItems is List) {
    items = rawItems;
  } else {
    items = [];
    if (rawData != null) {
      developer.log(
        '[parsePaginatedEnvelope] data field is ${rawData.runtimeType}, expected List → []',
      );
    }
  }

  // Normalise: extract meta
  final rawMeta = dataMap['meta'] ?? dataMap['pagination'];
  Map<String, dynamic> meta = _tryAsMap(rawMeta) ?? {};
  if (meta.isEmpty) {
    if (dataMap.containsKey('page') ||
        dataMap.containsKey('limit') ||
        dataMap.containsKey('total')) {
      meta = {
        'page': dataMap['page'] ?? 1,
        'limit': dataMap['limit'] ?? (items.isNotEmpty ? items.length : 20),
        'total': dataMap['total'] ?? items.length,
        'totalPages': dataMap['totalPages'] ?? (items.isNotEmpty ? 1 : 0),
        'hasNext': dataMap['hasNext'] ?? false,
        'hasPrev': dataMap['hasPrev'] ?? false,
      };
    }
  }

  return {'data': items, 'meta': meta};
}
