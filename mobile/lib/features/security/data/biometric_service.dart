// lib/features/security/data/biometric_service.dart
//
// Platform-safe wrapper around `local_auth`.
// Returns false gracefully on platforms that don't support biometrics
// (Web, Windows, Linux) so callers never need to check the platform themselves.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The type of biometric hardware available on the device.
enum BiometricHardwareType {
  /// Face unlock (Face ID on iOS, Face Unlock on Android).
  face,

  /// Fingerprint sensor.
  fingerprint,

  /// Both face and fingerprint are enrolled; fingerprint takes visual priority.
  both,

  /// No biometric hardware / enrollment found.
  none,
}

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

  /// Returns the dominant biometric hardware type enrolled on this device.
  ///
  /// Priority: if the device has BOTH face and fingerprint enrolled, returns
  /// [BiometricHardwareType.both]. Otherwise returns the singular type, or
  /// [BiometricHardwareType.none] when nothing is enrolled.
  Future<BiometricHardwareType> getBiometricHardwareType() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return BiometricHardwareType.none;
    }
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      if (biometrics.isEmpty) return BiometricHardwareType.none;

      final hasFace = biometrics.contains(BiometricType.face) ||
          biometrics.contains(BiometricType.iris);
      final hasFingerprint = biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.weak);

      if (hasFace && hasFingerprint) return BiometricHardwareType.both;
      if (hasFace) return BiometricHardwareType.face;
      return BiometricHardwareType.fingerprint;
    } catch (_) {
      return BiometricHardwareType.none;
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
          biometricOnly: false, // allow device PIN/pattern as OS-level fallback
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

/// Convenience provider: true if biometrics are available on this device.
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) return false;
  final service = ref.watch(biometricServiceProvider);
  return service.isAvailable();
});

/// Provides the type of biometric hardware enrolled (face / fingerprint / both / none).
final biometricHardwareTypeProvider =
    FutureProvider<BiometricHardwareType>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return service.getBiometricHardwareType();
});
