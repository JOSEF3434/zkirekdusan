// lib/features/security/data/pattern_service.dart
//
// Stores and verifies an app-level lock pattern using PBKDF2 (HMAC-SHA256).
// The pattern is encoded as a comma-separated sequence of node indices
// (e.g., "0,1,4,3,6") from a 3×3 grid. Only the salted verifier is persisted;
// the raw pattern is never stored. Transparently migrates v1 verifiers to v2.

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

const _kPatternHash = 'app_lock_pattern_hash';
const _kPatternSalt = 'app_lock_pattern_salt';
const _kPatternVerifier = 'app_lock_pattern_verifier';
const _kPatternVersion = 'app_lock_pattern_version';

/// Minimum number of nodes that must be connected to form a valid pattern.
const kMinPatternNodes = 4;

class PatternService {
  final FlutterSecureStorage _storage;

  PatternService(this._storage);

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

  static String _sha256Hash(List<int> nodes) {
    final encoded = nodes.join(',');
    final bytes = utf8.encode(encoded);
    return sha256.convert(bytes).toString();
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Returns true if a pattern has been stored.
  Future<bool> hasPattern() async {
    final verifier = await _storage.read(key: _kPatternVerifier);
    if (verifier != null && verifier.isNotEmpty) return true;

    final legacyHash = await _storage.read(key: _kPatternHash);
    return legacyHash != null && legacyHash.isNotEmpty;
  }

  /// Stores the PBKDF2 verifier (v2) of [nodes]. Overwrites any existing pattern.
  Future<void> setPattern(List<int> nodes) async {
    final salt = _generateSalt();
    final saltHex = _bytesToHex(salt);
    final encoded = nodes.join(',');

    final verifierBytes = await Isolate.run(
      () => pbkdf2Isolate(Pbkdf2Params(encoded, salt.toList(), kV2Iterations)),
    );
    final verifierHex = _bytesToHex(verifierBytes);

    await _storage.write(key: _kPatternSalt, value: saltHex);
    await _storage.write(key: _kPatternVerifier, value: verifierHex);
    await _storage.write(key: _kPatternVersion, value: '2');
    await _storage.delete(key: _kPatternHash);
  }

  /// Returns true if [nodes] matches the stored pattern.
  Future<bool> verifyPattern(List<int> nodes) async {
    final storedVerifier = await _storage.read(key: _kPatternVerifier);
    if (storedVerifier != null && storedVerifier.isNotEmpty) {
      final saltHex = await _storage.read(key: _kPatternSalt);
      if (saltHex == null || saltHex.isEmpty) return false;

      final version = await _storage.read(key: _kPatternVersion) ?? '2';
      final salt = _hexToBytes(saltHex);
      final iterations = (version == '1') ? kV1Iterations : kV2Iterations;
      final encoded = nodes.join(',');

      final computedBytes = await Isolate.run(
        () => pbkdf2Isolate(Pbkdf2Params(encoded, salt, iterations)),
      );
      final computedHex = _bytesToHex(computedBytes);

      if (computedHex == storedVerifier) {
        if (version == '1') {
          unawaited(setPattern(nodes));
        }
        return true;
      }
      return false;
    }

    // Check legacy SHA-256 hash
    final legacyHash = await _storage.read(key: _kPatternHash);
    if (legacyHash != null && legacyHash.isNotEmpty) {
      if (legacyHash == _sha256Hash(nodes)) {
        unawaited(setPattern(nodes));
        return true;
      }
    }

    return false;
  }

  /// Removes the stored pattern (called on disable or method change).
  Future<void> clearPattern() async {
    await _storage.delete(key: _kPatternSalt);
    await _storage.delete(key: _kPatternVerifier);
    await _storage.delete(key: _kPatternVersion);
    await _storage.delete(key: _kPatternHash);
  }
}

final patternServiceProvider = Provider<PatternService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return PatternService(storage);
});
