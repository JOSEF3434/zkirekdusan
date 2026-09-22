// lib/features/security/data/pattern_service.dart
//
// Stores and verifies an app-level lock pattern.
// The pattern is encoded as a comma-separated sequence of node indices
// (e.g., "0,1,4,3,6") from a 3×3 grid.  Only the SHA-256 hash is persisted;
// the raw pattern is never stored.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/secure_storage.dart';

const _kPatternHash = 'app_lock_pattern_hash';

/// Minimum number of nodes that must be connected to form a valid pattern.
const kMinPatternNodes = 4;

class PatternService {
  final FlutterSecureStorage _storage;

  PatternService(this._storage);

  // ── SHA-256 helper ──────────────────────────────────────────────────────

  static String _hash(List<int> nodes) {
    final encoded = nodes.join(',');
    final bytes = utf8.encode(encoded);
    return sha256.convert(bytes).toString();
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Returns true if a pattern has been stored.
  Future<bool> hasPattern() async {
    final stored = await _storage.read(key: _kPatternHash);
    return stored != null && stored.isNotEmpty;
  }

  /// Stores the SHA-256 hash of [nodes].  Overwrites any existing pattern.
  Future<void> setPattern(List<int> nodes) async {
    await _storage.write(key: _kPatternHash, value: _hash(nodes));
  }

  /// Returns true if [nodes] matches the stored pattern hash.
  Future<bool> verifyPattern(List<int> nodes) async {
    final stored = await _storage.read(key: _kPatternHash);
    if (stored == null || stored.isEmpty) return false;
    return stored == _hash(nodes);
  }

  /// Removes the stored pattern (called on disable or method change).
  Future<void> clearPattern() async {
    await _storage.delete(key: _kPatternHash);
  }
}

final patternServiceProvider = Provider<PatternService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return PatternService(storage);
});
