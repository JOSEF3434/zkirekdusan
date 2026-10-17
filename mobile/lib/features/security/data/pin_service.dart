// lib/features/security/data/pin_service.dart
//
// Stores, verifies, and clears the App Lock PIN using PBKDF2 (HMAC-SHA256).
// The raw PIN is NEVER stored — only its salted verifier. Supports 4-digit,
// 6-digit and alphanumeric passcode types. Transparently migrates v1 to v2.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/security/data/pbkdf2_isolate.dart';

const _kPinHash = 'app_lock_pin_hash';
const _kPinSalt = 'app_lock_pin_salt';
const _kPinVerifier = 'app_lock_pin_verifier';
const _kPinVersion = 'app_lock_pin_version';
const _kPinType = 'app_lock_pin_type';

/// Validation errors when setting up a new PIN.
enum PinValidationError {
  none,
  tooShort,
  tooWeak,
}

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

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  static Uint8List _generateSalt([int length = 16]) {
    final rnd = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rnd.nextInt(256)));
  }

  static String _sha256Hash(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  // ── PIN Strength Validation ──────────────────────────────────────────────

  PinValidationError validate(String pin, PinType type) {
    switch (type) {
      case PinType.pin4:
        if (pin.length < 4) return PinValidationError.tooShort;
        if (_isWeakNumericPin(pin)) return PinValidationError.tooWeak;
        return PinValidationError.none;
      case PinType.pin6:
        if (pin.length < 6) return PinValidationError.tooShort;
        if (_isWeakNumericPin(pin)) return PinValidationError.tooWeak;
        return PinValidationError.none;
      case PinType.password:
        if (pin.length < 8) return PinValidationError.tooShort;
        return PinValidationError.none;
    }
  }

  static bool _isWeakNumericPin(String pin) {
    if (pin.isEmpty) return true;

    // 1. All identical digits (e.g. 0000, 1111, 000000)
    if (Set.from(pin.split('')).length == 1) return true;

    // 2. Sequential ascending or descending (e.g. 1234, 123456, 4321, 654321)
    bool isAscending = true;
    bool isDescending = true;
    for (int i = 1; i < pin.length; i++) {
      final diff = pin.codeUnitAt(i) - pin.codeUnitAt(i - 1);
      if (diff != 1) isAscending = false;
      if (diff != -1) isDescending = false;
    }
    if (isAscending || isDescending) return true;

    // 3. Repeated blocks (e.g. 1212, 123123)
    for (int len = 1; len <= pin.length ~/ 2; len++) {
      if (pin.length % len == 0) {
        final block = pin.substring(0, len);
        final repeated = List.filled(pin.length ~/ len, block).join();
        if (pin == repeated) return true;
      }
    }

    // 4. Repeated pairs in sequence (e.g. 1122, 112233)
    if (pin.length >= 4 && pin.length % 2 == 0) {
      bool allPairs = true;
      for (int i = 0; i < pin.length; i += 2) {
        if (pin[i] != pin[i + 1]) {
          allPairs = false;
          break;
        }
      }
      if (allPairs) return true;
    }

    return false;
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Returns true if a PIN/passcode has already been set.
  Future<bool> hasPin() async {
    final verifier = await _storage.read(key: _kPinVerifier);
    if (verifier != null && verifier.isNotEmpty) return true;

    final legacyHash = await _storage.read(key: _kPinHash);
    return legacyHash != null && legacyHash.isNotEmpty;
  }

  /// Returns the stored [PinType], defaulting to [PinType.pin6].
  Future<PinType> getPinType() async {
    final typeStr = await _storage.read(key: _kPinType);
    return PinTypeX.fromKey(typeStr);
  }

  /// Stores the PBKDF2 verifier (v2) of [pin] with the given [type].
  /// Overwrites any existing PIN.
  Future<void> setPin(String pin, {PinType type = PinType.pin6}) async {
    final salt = _generateSalt();
    final saltHex = _bytesToHex(salt);

    final verifierBytes = await Isolate.run(
      () => pbkdf2Isolate(Pbkdf2Params(pin, salt.toList(), kV2Iterations)),
    );
    final verifierHex = _bytesToHex(verifierBytes);

    await _storage.write(key: _kPinSalt, value: saltHex);
    await _storage.write(key: _kPinVerifier, value: verifierHex);
    await _storage.write(key: _kPinVersion, value: '2');
    await _storage.write(key: _kPinType, value: type.key);
    await _storage.delete(key: _kPinHash);
  }

  /// Returns true if [pin] matches the stored PIN.
  Future<bool> verifyPin(String pin) async {
    final storedVerifier = await _storage.read(key: _kPinVerifier);
    if (storedVerifier != null && storedVerifier.isNotEmpty) {
      final saltHex = await _storage.read(key: _kPinSalt);
      if (saltHex == null || saltHex.isEmpty) return false;

      final version = await _storage.read(key: _kPinVersion) ?? '2';
      final salt = _hexToBytes(saltHex);
      final iterations = (version == '1') ? kV1Iterations : kV2Iterations;

      final computedBytes = await Isolate.run(
        () => pbkdf2Isolate(Pbkdf2Params(pin, salt, iterations)),
      );
      final computedHex = _bytesToHex(computedBytes);

      if (computedHex == storedVerifier) {
        if (version == '1') {
          final type = await getPinType();
          unawaited(setPin(pin, type: type));
        }
        return true;
      }
      return false;
    }

    // Check legacy SHA-256 hash
    final legacyHash = await _storage.read(key: _kPinHash);
    if (legacyHash != null && legacyHash.isNotEmpty) {
      if (legacyHash == _sha256Hash(pin)) {
        final type = await getPinType();
        unawaited(setPin(pin, type: type));
        return true;
      }
    }

    return false;
  }

  /// Removes the stored PIN verifier and type (called on disable or forgot-PIN logout).
  Future<void> clearPin() async {
    await _storage.delete(key: _kPinSalt);
    await _storage.delete(key: _kPinVerifier);
    await _storage.delete(key: _kPinVersion);
    await _storage.delete(key: _kPinType);
    await _storage.delete(key: _kPinHash);
  }
}

final pinServiceProvider = Provider<PinService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return PinService(storage);
});
