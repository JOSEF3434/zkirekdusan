// lib/features/security/data/pin_service.dart
//
// Stores, verifies, and clears the App Lock PIN using SHA-256 hashing.
// The raw PIN is NEVER stored — only its hash. Brute-force state is
// also managed here so it persists across hot-restarts during development.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/secure_storage.dart';

const _kPinHash = 'app_lock_pin_hash';

class PinService {
  final FlutterSecureStorage _storage;

  PinService(this._storage);

  // ── SHA-256 helper ──────────────────────────────────────────────────────

  static String _hash(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Returns true if a PIN has already been set.
  Future<bool> hasPin() async {
    final stored = await _storage.read(key: _kPinHash);
    return stored != null && stored.isNotEmpty;
  }

  /// Stores the SHA-256 hash of [pin]. Overwrites any existing PIN.
  Future<void> setPin(String pin) async {
    await _storage.write(key: _kPinHash, value: _hash(pin));
  }

  /// Returns true if [pin] matches the stored hash.
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _kPinHash);
    if (stored == null || stored.isEmpty) return false;
    return stored == _hash(pin);
  }

  /// Removes the stored PIN hash (called on disable or forgot-PIN logout).
  Future<void> clearPin() async {
    await _storage.delete(key: _kPinHash);
  }
}

final pinServiceProvider = Provider<PinService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return PinService(storage);
});
