// lib/features/security/data/pattern_service.dart
//
// Stores and verifies an app-level lock pattern.
//
// Security model:
//   • Pattern encoded as comma-separated node indices (e.g., "0,1,4,3,6").
//   • Random 16-byte salt per credential.
//   • PBKDF2-HMAC-SHA256 with 600,000 iterations (OWASP 2023).
//   • Versioned migration: v1 (100k) → v2 (600k) on next successful unlock.
//   • Runs in a background isolate via compute() — no UI jank.
//   • Constant-time comparison; raw pattern NEVER stored or logged.

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/security/data/pbkdf2_isolate.dart';

const _kPatternVerifier = 'app_lock_pattern_verifier';
const _kPatternSalt = 'app_lock_pattern_salt';
const _kPatternVersion = 'app_lock_pattern_version';


/// Minimum number of nodes that must be connected for a valid pattern.
const kMinPatternNodes = 4;

class PatternService {
  final FlutterSecureStorage _storage;

  PatternService(this._storage);

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

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<bool> hasPattern() async {
    final stored = await _storage.read(key: _kPatternVerifier);
    return stored != null && stored.isNotEmpty;
  }

  /// Stores the PBKDF2 verifier for [nodes].
  /// Runs in a background isolate — safe to await on the UI thread.
  Future<void> setPattern(List<int> nodes) async {
    final encoded = nodes.join(',');
    final salt = _generateSalt();
    final verifier = await compute(
      pbkdf2Isolate,
      Pbkdf2Params(encoded, salt.toList(), kCurrentIterations),
    );
    await _storage.write(key: _kPatternSalt, value: _bytesToHex(salt));
    await _storage.write(
        key: _kPatternVerifier, value: _bytesToHex(verifier));
    await _storage.write(key: _kPatternVersion, value: '2');
  }

  /// Verifies [nodes] against the stored PBKDF2 verifier.
  /// Transparently migrates v1 (100k) credentials to v2 (600k) on success.
  Future<bool> verifyPattern(List<int> nodes) async {
    final saltHex = await _storage.read(key: _kPatternSalt);
    final verifierHex = await _storage.read(key: _kPatternVerifier);
    if (saltHex == null || verifierHex == null) return false;
    if (saltHex.isEmpty || verifierHex.isEmpty) return false;

    final versionStr = await _storage.read(key: _kPatternVersion);
    final isV1 = versionStr == null || versionStr == '1';
    final iterations = isV1 ? kV1Iterations : kCurrentIterations;

    final salt = _hexToBytes(saltHex);
    final expected = _hexToBytes(verifierHex);
    final actual = await compute(
      pbkdf2Isolate,
      Pbkdf2Params(nodes.join(','), salt.toList(), iterations),
    );

    final match = constantTimeEquals(actual, expected);

    if (match && isV1) {
      unawaited(setPattern(nodes));
    }

    return match;
  }

  Future<void> clearPattern() async {
    await _storage.delete(key: _kPatternVerifier);
    await _storage.delete(key: _kPatternSalt);
    await _storage.delete(key: _kPatternVersion);
  }
}

final patternServiceProvider = Provider<PatternService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return PatternService(storage);
});
