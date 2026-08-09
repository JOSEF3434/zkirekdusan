// lib/core/storage/secure_storage.dart
// Expanded StorageService — supports named keys for multiple token types

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
});

class StorageService {
  final FlutterSecureStorage _storage;

  // Default key kept for backward compatibility with the original AuthInterceptor
  static const String _defaultTokenKey = 'access_token';

  StorageService(this._storage);

  // ── Keyed API (used by AuthRepositoryImpl) ─────────────────────────────

  Future<void> saveToken(String token, {String? key}) async {
    await _storage.write(key: key ?? _defaultTokenKey, value: token);
  }

  Future<String?> getToken({String? key}) async {
    return _storage.read(key: key ?? _defaultTokenKey);
  }

  Future<void> deleteToken({String? key}) async {
    await _storage.delete(key: key ?? _defaultTokenKey);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return StorageService(storage);
});
