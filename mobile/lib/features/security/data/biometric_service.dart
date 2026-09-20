// lib/features/security/data/biometric_service.dart
//
// Platform-safe wrapper around `local_auth`.
// Returns false gracefully on platforms that don't support biometrics
// (Web, Windows, Linux) so callers never need to check the platform themselves.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService(this._auth);

  /// Returns true if the device supports biometric authentication AND
  /// the user has enrolled at least one biometric credential.
  Future<bool> isAvailable() async {
    // Web & Windows do not support local_auth
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return false;
    }
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) return false;

      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types (face, fingerprint, iris).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return [];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Triggers the OS biometric prompt with [reason] shown to the user.
  /// Returns true on successful authentication.
  Future<bool> authenticate({required String reason}) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return false;
    }
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow device PIN as OS-level fallback
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] PlatformException: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Error: $e');
      return false;
    }
  }

  /// Cancels any ongoing biometric prompt.
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(LocalAuthentication());
});
