// lib/features/security/data/pin_service.dart
//
// Stores, verifies, and clears the App Lock PIN / password.
//
// Security model:
//   • Raw PIN / password is NEVER stored or logged.
//   • Random 16-byte salt per credential.
//   • PBKDF2-HMAC-SHA256 with 600,000 iterations (OWASP 2023 guidance).
//   • Versioned migration: v1 (100k) → v2 (600k) on next successful unlock.
//   • Both salt and verifier stored in platform-backed secure storage.
//   • Constant-time comparison prevents timing side-channels.
//   • PBKDF2 runs in a background isolate via compute() — no UI jank.

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/security/data/pbkdf2_isolate.dart';

const _kPinVerifier = 'app_lock_pin_verifier';
const _kPinSalt = 'app_lock_pin_salt';
const _kPinType = 'app_lock_pin_type';
const _kPinVersion = 'app_lock_pin_version';


// ── Weak PIN lists ─────────────────────────────────────────────────────────

const _kWeakPins4 = {
  '0000', '1111', '2222', '3333', '4444', '5555', '6666',
  '7777', '8888', '9999', '1234', '4321', '2345', '3456',
  '4567', '5678', '6789', '9876', '8765', '7654', '6543',
  '5432', '0123', '3210', '1212', '2121', '1122', '2211',
};

const _kWeakPins6 = {
  '000000', '111111', '222222', '333333', '444444', '555555',
  '666666', '777777', '888888', '999999', '123456', '654321',
  '112233', '332211', '121212', '212121', '102030', '246810',
  '123123', '456456', '789789',
};

// ── PinType ────────────────────────────────────────────────────────────────

enum PinType { pin4, pin6, password }

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
        return null;
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

// ── Validation result ──────────────────────────────────────────────────────

enum PinValidationError { tooShort, tooWeak, none }

// ── PinService ─────────────────────────────────────────────────────────────

class PinService {
  final FlutterSecureStorage _storage;

  PinService(this._storage);

  // ── Utilities ─────────────────────────────────────────────────────────────

  static String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  static Uint8List _generateSalt() {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => rng.nextInt(256)));
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  PinValidationError validate(String pin, PinType type) {
    if (type == PinType.pin4) {
      if (pin.length < 4) return PinValidationError.tooShort;
      if (_kWeakPins4.contains(pin)) return PinValidationError.tooWeak;
    } else if (type == PinType.pin6) {
      if (pin.length < 6) return PinValidationError.tooShort;
      if (_kWeakPins6.contains(pin)) return PinValidationError.tooWeak;
    } else {
      if (pin.length < 6) return PinValidationError.tooShort;
    }
    return PinValidationError.none;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<bool> hasPin() async {
    final stored = await _storage.read(key: _kPinVerifier);
    return stored != null && stored.isNotEmpty;
  }

  Future<PinType> getPinType() async {
    final typeStr = await _storage.read(key: _kPinType);
    return PinTypeX.fromKey(typeStr);
  }

  /// Derives and stores a PBKDF2 verifier using the current iteration count.
  /// Runs in a background isolate — safe to await on the UI thread.
  Future<void> setPin(String pin, {PinType type = PinType.pin6}) async {
    final salt = _generateSalt();
    final verifier = await compute(
      pbkdf2Isolate,
      Pbkdf2Params(pin, salt.toList(), kCurrentIterations),
    );
    await _storage.write(key: _kPinSalt, value: _bytesToHex(salt));
    await _storage.write(key: _kPinVerifier, value: _bytesToHex(verifier));
    await _storage.write(key: _kPinType, value: type.key);
    await _storage.write(key: _kPinVersion, value: '2');
  }

  /// Verifies [pin] against the stored PBKDF2 verifier.
  ///
  /// Transparent migration: if stored credentials were created with v1 (100k)
  /// iterations, a successful verification automatically upgrades them to
  /// v2 (600k) in the background. The PIN is not changed.
  Future<bool> verifyPin(String pin) async {
    final saltHex = await _storage.read(key: _kPinSalt);
    final verifierHex = await _storage.read(key: _kPinVerifier);
    if (saltHex == null || verifierHex == null) return false;
    if (saltHex.isEmpty || verifierHex.isEmpty) return false;

    final versionStr = await _storage.read(key: _kPinVersion);
    final isV1 = versionStr == null || versionStr == '1';
    final iterations = isV1 ? kV1Iterations : kCurrentIterations;

    final salt = _hexToBytes(saltHex);
    final expected = _hexToBytes(verifierHex);
    final actual = await compute(
      pbkdf2Isolate,
      Pbkdf2Params(pin, salt.toList(), iterations),
    );

    final match = constantTimeEquals(actual, expected);

    // Transparent migration on success
    if (match && isV1) {
      final currentType = await getPinType();
      unawaited(setPin(pin, type: currentType));
    }

    return match;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _kPinVerifier);
    await _storage.delete(key: _kPinSalt);
    await _storage.delete(key: _kPinType);
    await _storage.delete(key: _kPinVersion);
  }
}

final pinServiceProvider = Provider<PinService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return PinService(storage);
});
