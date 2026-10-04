// lib/features/security/data/pbkdf2_isolate.dart
//
// Shared PBKDF2-HMAC-SHA256 computation for PinService and PatternService.
// Exported so both services can use compute() with the same function reference.
// Private-named (_) functions cannot be passed to compute() across file
// boundaries, so these are package-level public symbols.

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Length of the derived key in bytes.
const kPbkdf2KeyLength = 32;

/// Current PBKDF2 iteration count — OWASP 2023 recommendation.
const kCurrentIterations = 600000;

/// Legacy iteration count from v1 credentials.
const kV1Iterations = 100000;

/// Parameters for the PBKDF2 computation.
/// Must be serializable for use with Flutter compute().
class Pbkdf2Params {
  final String password;
  final List<int> salt;
  final int iterations;

  const Pbkdf2Params(this.password, this.salt, this.iterations);
}

/// Top-level PBKDF2-HMAC-SHA256 function.
/// Top-level so it can be used with Flutter's compute() in a background isolate.
Uint8List pbkdf2Isolate(Pbkdf2Params p) {
  final passwordBytes = utf8.encode(p.password);
  final salt = Uint8List.fromList(p.salt);
  final hmac = Hmac(sha256, passwordBytes);

  // U1 = PRF(Password, Salt || INT(1))
  final block = Uint8List(salt.length + 4);
  block.setRange(0, salt.length, salt);
  block[salt.length] = 0;
  block[salt.length + 1] = 0;
  block[salt.length + 2] = 0;
  block[salt.length + 3] = 1; // block index = 1

  var u = Uint8List.fromList(hmac.convert(block).bytes);
  final result = Uint8List.fromList(u);

  for (int i = 1; i < p.iterations; i++) {
    u = Uint8List.fromList(hmac.convert(u).bytes);
    for (int j = 0; j < kPbkdf2KeyLength; j++) {
      result[j] ^= u[j];
    }
  }

  return result.sublist(0, kPbkdf2KeyLength);
}

/// Constant-time comparison for two byte arrays.
bool constantTimeEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  int diff = 0;
  for (int i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
