// lib/features/security/data/pin_service.dart
//
// Stores, verifies, and clears the App Lock PIN using SHA-256 hashing.
// The raw PIN is NEVER stored — only its hash.  Supports 4-digit, 6-digit
// and alphanumeric passcode types.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/secure_storage.dart';

const _kPinHash = 'app_lock_pin_hash';
const _kPinType = 'app_lock_pin_type';

/// The type of passcode the user has configured.
enum PinType {
  /// Classic 4-digit numeric PIN.
  pin4,

  /// Extended 6-digit numeric PIN (default).
  pin6,

  /// Alphanumeric password of any length.
  password,
}

extension PinTypeX on PinType {
  String get key {
    switch (this) {
      case PinType.pin4:
        return 'pin4';
      case PinType.pin6:
        return 'pin6';
      case PinType.password:
        return 'password';
    }
  }

  static PinType fromKey(String? key) {
    switch (key) {
      case 'pin4':
        return PinType.pin4;
      case 'password':
        return PinType.password;
      default:
        return PinType.pin6;
    }
  }

  int? get length {
    switch (this) {
      case PinType.pin4:
        return 4;
      case PinType.pin6:
        return 6;
      case PinType.password:
        return null; // variable length
    }
  }

  String get label {
    switch (this) {
      case PinType.pin4:
        return '4-Digit PIN';
      case PinType.pin6:
        return '6-Digit PIN';
      case PinType.password:
        return 'Alphanumeric Password';
    }
  }
}

class PinService {
  final FlutterSecureStorage _storage;

  PinService(this._storage);

  // ── SHA-256 helper ──────────────────────────────────────────────────────

  static String _hash(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Returns true if a PIN/passcode has already been set.
  Future<bool> hasPin() async {
    final stored = await _storage.read(key: _kPinHash);
    return stored != null && stored.isNotEmpty;
  }

  /// Returns the stored [PinType], defaulting to [PinType.pin6].
  Future<PinType> getPinType() async {
    final typeStr = await _storage.read(key: _kPinType);
    return PinTypeX.fromKey(typeStr);
  }

  /// Stores the SHA-256 hash of [pin] with the given [type].
  /// Overwrites any existing PIN.
  Future<void> setPin(String pin, {PinType type = PinType.pin6}) async {
    await _storage.write(key: _kPinHash, value: _hash(pin));
    await _storage.write(key: _kPinType, value: type.key);
  }

  /// Returns true if [pin] matches the stored hash.
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _kPinHash);
    if (stored == null || stored.isEmpty) return false;
    return stored == _hash(pin);
  }

  /// Removes the stored PIN hash and type (called on disable or forgot-PIN logout).
  Future<void> clearPin() async {
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kPinType);
  }
}

final pinServiceProvider = Provider<PinService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return PinService(storage);
});
