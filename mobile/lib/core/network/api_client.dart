// lib/core/network/api_client.dart
// Central Dio client with envelope parsing utility exposed for all repositories.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/env/env.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/network/auth_interceptor.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));

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

/// Unwraps the NestJS `{success, data, timestamp}` envelope.
///
/// If the response is already a plain map (no `success` key), it is returned
/// as-is for backwards compatibility. Throws [AppException] when
/// `success != true` or when the payload cannot be interpreted as a map.
Map<String, dynamic> parseEnvelope(dynamic raw) {
  if (raw == null) {
    throw AppException('Empty response from server.');
  }

  Map<String, dynamic> map;
  if (raw is Map<String, dynamic>) {
    map = raw;
  } else if (raw is Map) {
    map = raw.cast<String, dynamic>();
  } else {
    throw AppException('Unexpected response format (not a JSON object).');
  }

  // Envelope present – unwrap it
  if (map.containsKey('success')) {
    if (map['success'] != true) {
      final msg = map['message'];
      throw AppException(
        msg is List ? (msg).join(', ') : (msg?.toString() ?? 'Request failed.'),
      );
    }
    final payload = map['data'];
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return payload.cast<String, dynamic>();
    // Some endpoints return data: null on success (e.g., logout)
    if (payload == null) return {};
    throw AppException('Unexpected data payload type in response envelope.');
  }

  // No envelope – return as-is (fallback)
  return map;
}

/// Unwraps a list payload from the envelope.
///
/// Accepts: `{success, data:[...]}` or a bare list.
List<dynamic> parseEnvelopeList(dynamic raw) {
  if (raw == null) {
    throw AppException('Empty response from server.');
  }

  if (raw is List) return raw;

  Map<String, dynamic> map;
  if (raw is Map<String, dynamic>) {
    map = raw;
  } else if (raw is Map) {
    map = raw.cast<String, dynamic>();
  } else {
    throw AppException('Unexpected response format (not JSON).');
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
    // Some backends wrap list under data.data
    if (payload is Map &&
        payload.containsKey('data') &&
        payload['data'] is List) {
      return payload['data'] as List;
    }
    throw AppException('Expected a list in response data.');
  }

  if (map.containsKey('data') && map['data'] is List) {
    return map['data'] as List;
  }

  throw AppException('Cannot extract list from response.');
}

/// Parses a paginated list response.
/// Returns a map with `items` (List) and `meta` (Map).
Map<String, dynamic> parsePaginatedEnvelope(dynamic raw) {
  if (raw == null) throw AppException('Empty response from server.');

  Map<String, dynamic> map;
  if (raw is Map<String, dynamic>) {
    map = raw;
  } else if (raw is Map) {
    map = map = raw.cast<String, dynamic>();
  } else {
    throw AppException('Unexpected response format.');
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
    if (payload is Map<String, dynamic>) {
      dataMap = payload;
    } else if (payload is Map) {
      dataMap = payload.cast<String, dynamic>();
    } else {
      throw AppException('Expected paginated data in response.');
    }
  } else {
    dataMap = map;
  }

  return dataMap;
}
