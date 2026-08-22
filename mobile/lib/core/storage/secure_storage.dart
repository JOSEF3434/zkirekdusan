// lib/core/storage/secure_storage.dart
// Expanded StorageService — supports named keys for multiple token types
// with dual-storage synchronization (FlutterSecureStorage for Native, SharedPreferences for Web)
// for 100% reliable Web and Mobile token persistence.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(aOptions: AndroidOptions());
});

class StorageService {
  final FlutterSecureStorage _storage;
  final SharedPreferences? _prefs;

  // Default key kept for backward compatibility with the original AuthInterceptor
  static const String _defaultTokenKey = 'access_token';

  StorageService(this._storage, [this._prefs]);

  // ── Keyed API (used by AuthRepositoryImpl) ─────────────────────────────

  Future<void> saveToken(String token, {String? key}) async {
    final effectiveKey = key ?? _defaultTokenKey;
    if (!kIsWeb) {
      try {
        await _storage.write(key: effectiveKey, value: token);
      } catch (e) {
        debugPrint('[StorageService] secure storage write warning: $e');
      }
    }

    // Synchronize to SharedPreferences (primary for Web, backup for native)
    try {
      await _prefs?.setString('sec_$effectiveKey', token);
    } catch (e) {
      debugPrint('[StorageService] shared preferences write warning: $e');
    }
  }

  Future<String?> getToken({String? key}) async {
    final effectiveKey = key ?? _defaultTokenKey;
    if (kIsWeb) {
      return _prefs?.getString('sec_$effectiveKey');
    }

    String? value;
    try {
      value = await _storage.read(key: effectiveKey);
    } catch (e) {
      debugPrint('[StorageService] secure storage read warning: $e');
    }

    if (value != null && value.isNotEmpty) {
      return value;
    }

    // Fallback to SharedPreferences if secure storage returned null/failed
    try {
      value = _prefs?.getString('sec_$effectiveKey');
    } catch (_) {}

    return value;
  }

  Future<void> deleteToken({String? key}) async {
    final effectiveKey = key ?? _defaultTokenKey;
    if (!kIsWeb) {
      try {
        await _storage.delete(key: effectiveKey);
      } catch (_) {}
    }
    try {
      await _prefs?.remove('sec_$effectiveKey');
    } catch (_) {}
  }

  Future<void> deleteAll() async {
    if (!kIsWeb) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
    try {
      final keys = _prefs?.getKeys() ?? {};
      for (final k in keys) {
        if (k.startsWith('sec_')) {
          await _prefs?.remove(k);
        }
      }
    } catch (_) {}
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {}
  return StorageService(storage, prefs);
});
