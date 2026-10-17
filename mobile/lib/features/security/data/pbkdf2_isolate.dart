// lib/features/security/data/pbkdf2_isolate.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

const kV1Iterations = 100000;
const kV2Iterations = 600000;

class Pbkdf2Params {
  final String password;
  final List<int> salt;
  final int iterations;

  const Pbkdf2Params(this.password, this.salt, this.iterations);
}

/// PBKDF2 with HMAC-SHA256 derivation.
List<int> pbkdf2Isolate(Pbkdf2Params params) {
  final passwordBytes = utf8.encode(params.password);
  final hmac = Hmac(sha256, passwordBytes);
  const keyLength = 32;
  final result = Uint8List(keyLength);

  final saltBlock = Uint8List(params.salt.length + 4);
  saltBlock.setRange(0, params.salt.length, params.salt);
  final bdata = ByteData.view(saltBlock.buffer, params.salt.length, 4);
  bdata.setUint32(0, 1, Endian.big);

  var u = hmac.convert(saltBlock).bytes;
  final t = Uint8List.fromList(u);

  for (var iter = 1; iter < params.iterations; iter++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < 32; j++) {
      t[j] ^= u[j];
    }
  }

  result.setRange(0, keyLength, t);
  return result.toList();
}
