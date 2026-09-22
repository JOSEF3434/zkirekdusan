// lib/features/security/presentation/providers/app_lock_provider.dart
//
// Controls the locked/unlocked state of the app.
// Integrates with AppLifecycleObserver to auto-lock after a configurable
// inactivity timeout.  Also tracks brute-force failed attempts.
// Supports PIN, biometric, and pattern authentication methods.
//
// Biometric auto-switch rule: after [kMaxBiometricAttempts] consecutive
// biometric failures the lock screen silently switches to PIN/pattern entry.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_settings_provider.dart';
import 'package:mobile/features/security/data/pin_service.dart';
import 'package:mobile/features/security/data/biometric_service.dart';
import 'package:mobile/features/security/data/pattern_service.dart';
import 'package:mobile/features/security/data/secure_window_service.dart';

// Re-export biometric helpers so the lock screen only imports this file.
export 'package:mobile/features/security/data/biometric_service.dart'
    show BiometricHardwareType, biometricHardwareTypeProvider, biometricAvailableProvider;

const _kLastActive = 'app_lock_last_active';
const _kFailedAttempts = 'app_lock_failed_attempts';
const _kCooldownUntil = 'app_lock_cooldown_until';

/// Maximum wrong PIN/pattern attempts before a 30-second cooldown.
const kMaxAttempts = 5;

/// After [kMaxAttemptsForceLogout] consecutive PIN/pattern failures → force logout.
const kMaxAttemptsForceLogout = 10;

/// After this many consecutive biometric failures the screen switches to the
/// configured PIN or pattern fallback automatically.
const kMaxBiometricAttempts = 5;

enum AppLockStatus { disabled, unlocked, locked }

class AppLockState {
  final AppLockStatus status;
  final int failedAttempts;
  final int biometricFailures;

  /// When set, the lock screen shows PIN/pattern instead of the biometric prompt.
  final bool biometricExhausted;
  final DateTime? cooldownUntil;

  const AppLockState({
    this.status = AppLockStatus.disabled,
    this.failedAttempts = 0,
    this.biometricFailures = 0,
    this.biometricExhausted = false,
    this.cooldownUntil,
  });

  bool get isInCooldown =>
      cooldownUntil != null && DateTime.now().isBefore(cooldownUntil!);

  bool get shouldForceLogout => failedAttempts >= kMaxAttemptsForceLogout;

  AppLockState copyWith({
    AppLockStatus? status,
    int? failedAttempts,
    int? biometricFailures,
    bool? biometricExhausted,
    DateTime? cooldownUntil,
    bool clearCooldown = false,
  }) =>
      AppLockState(
        status: status ?? this.status,
        failedAttempts: failedAttempts ?? this.failedAttempts,
        biometricFailures: biometricFailures ?? this.biometricFailures,
        biometricExhausted: biometricExhausted ?? this.biometricExhausted,
        cooldownUntil:
            clearCooldown ? null : (cooldownUntil ?? this.cooldownUntil),
      );
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  final Ref _ref;
  final SharedPreferences _prefs;
  final PinService _pinService;
  final BiometricService _biometricService;
  final PatternService _patternService;

  AppLockSettings get _settings => _ref.read(appLockSettingsProvider);
  SecureWindowService get _secureWindowService =>
      _ref.read(secureWindowServiceProvider);

  AppLockNotifier({
    required Ref ref,
    required SharedPreferences prefs,
    required PinService pinService,
    required BiometricService biometricService,
    required PatternService patternService,
  })  : _ref = ref,
        _prefs = prefs,
        _pinService = pinService,
        _biometricService = biometricService,
        _patternService = patternService,
        super(const AppLockState()) {
    _init();
    _ref.listen<AppLockSettings>(appLockSettingsProvider, (prev, next) {
      if (!next.isEnabled && state.status != AppLockStatus.disabled) {
        state = const AppLockState(status: AppLockStatus.disabled);
        _secureWindowService.setSecureMode(false);
      }
    });
  }

  Future<void> _init() async {
    if (!_settings.isEnabled) {
      state = const AppLockState(status: AppLockStatus.disabled);
      return;
    }

    final failedAttempts = _prefs.getInt(_kFailedAttempts) ?? 0;
    final cooldownMillis = _prefs.getInt(_kCooldownUntil);
    final cooldownUntil = cooldownMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(cooldownMillis)
        : null;

    state = AppLockState(
      status: AppLockStatus.locked,
      failedAttempts: failedAttempts,
      // Reset biometric failure count on fresh app start
      biometricFailures: 0,
      biometricExhausted: false,
      cooldownUntil: cooldownUntil,
    );
    _secureWindowService.setSecureMode(true);
  }

  // ── AppLifecycleObserver callbacks ──────────────────────────────────────

  Future<void> onPaused() async {
    if (!_settings.isEnabled) return;
    await _prefs.setInt(_kLastActive, DateTime.now().millisecondsSinceEpoch);
    _secureWindowService.setSecureMode(true);
  }

  Future<void> onResumed() async {
    if (!_settings.isEnabled) return;
    if (state.status == AppLockStatus.locked) return;

    final lastActiveMs = _prefs.getInt(_kLastActive);
    if (lastActiveMs == null) {
      _lock();
      return;
    }

    final timeoutMinutes = _settings.timeoutMinutes;
    if (timeoutMinutes < 0) return; // -1 = never auto-lock

    final elapsed = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastActiveMs));

    if (elapsed.inMinutes >= timeoutMinutes) {
      _lock();
    } else {
      _secureWindowService.setSecureMode(false);
    }
  }

  void _lock() {
    if (!_settings.isEnabled) return;
    state = state.copyWith(
      status: AppLockStatus.locked,
      // Reset biometric exhaustion on each new lock cycle
      biometricFailures: 0,
      biometricExhausted: false,
    );
    _secureWindowService.setSecureMode(true);
  }

  void lock() => _lock();

  // ── Biometric authentication ────────────────────────────────────────────

  Future<bool> authenticateWithBiometric() async {
    final success = await _biometricService.authenticate(
      reason: 'Unlock ዝክረ ቅዱሳን',
    );

    if (success) {
      await _resetAttempts();
      state = state.copyWith(
        status: AppLockStatus.unlocked,
        failedAttempts: 0,
        biometricFailures: 0,
        biometricExhausted: false,
        clearCooldown: true,
      );
      await _prefs.setInt(_kLastActive, DateTime.now().millisecondsSinceEpoch);
      _secureWindowService.setSecureMode(false);
      return true;
    }

    // Track biometric failures; exhaust after kMaxBiometricAttempts
    final newBiometricFailures = state.biometricFailures + 1;
    final exhausted = newBiometricFailures >= kMaxBiometricAttempts;
    state = state.copyWith(
      biometricFailures: newBiometricFailures,
      biometricExhausted: exhausted,
    );

    return false;
  }

  // ── PIN verification ────────────────────────────────────────────────────

  Future<bool> verifyPin(String pin) async {
    if (state.isInCooldown) return false;

    final valid = await _pinService.verifyPin(pin);
    if (valid) {
      await _resetAttempts();
      state = state.copyWith(
        status: AppLockStatus.unlocked,
        failedAttempts: 0,
        clearCooldown: true,
      );
      await _prefs.setInt(_kLastActive, DateTime.now().millisecondsSinceEpoch);
      _secureWindowService.setSecureMode(false);
      return true;
    }

    return _handleFailedAttempt();
  }

  // ── Pattern verification ────────────────────────────────────────────────

  Future<bool> verifyPattern(List<int> nodes) async {
    if (state.isInCooldown) return false;

    final valid = await _patternService.verifyPattern(nodes);
    if (valid) {
      await _resetAttempts();
      state = state.copyWith(
        status: AppLockStatus.unlocked,
        failedAttempts: 0,
        clearCooldown: true,
      );
      await _prefs.setInt(_kLastActive, DateTime.now().millisecondsSinceEpoch);
      _secureWindowService.setSecureMode(false);
      return true;
    }

    return _handleFailedAttempt();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<bool> _handleFailedAttempt() async {
    final newAttempts = state.failedAttempts + 1;
    await _prefs.setInt(_kFailedAttempts, newAttempts);

    if (newAttempts >= kMaxAttemptsForceLogout) {
      state = state.copyWith(
        status: AppLockStatus.locked,
        failedAttempts: newAttempts,
      );
      return false;
    }

    if (newAttempts >= kMaxAttempts) {
      final cooldownUntil = DateTime.now().add(const Duration(seconds: 30));
      await _prefs.setInt(
          _kCooldownUntil, cooldownUntil.millisecondsSinceEpoch);
      state = state.copyWith(
        failedAttempts: newAttempts,
        cooldownUntil: cooldownUntil,
      );
    } else {
      state = state.copyWith(failedAttempts: newAttempts);
    }

    return false;
  }

  Future<void> _resetAttempts() async {
    await _prefs.remove(_kFailedAttempts);
    await _prefs.remove(_kCooldownUntil);
  }

  void clearCooldown() {
    state = state.copyWith(clearCooldown: true);
  }

  Future<void> disable() async {
    await _resetAttempts();
    await _pinService.clearPin();
    await _patternService.clearPattern();
    state = const AppLockState(status: AppLockStatus.disabled);
    _secureWindowService.setSecureMode(false);
  }

  void onPinSet() {
    state = state.copyWith(
      status: AppLockStatus.unlocked,
      failedAttempts: 0,
      clearCooldown: true,
    );
    _secureWindowService.setSecureMode(false);
  }

  void onPatternSet() {
    state = state.copyWith(
      status: AppLockStatus.unlocked,
      failedAttempts: 0,
      clearCooldown: true,
    );
    _secureWindowService.setSecureMode(false);
  }

  bool get shouldForceLogout =>
      state.failedAttempts >= kMaxAttemptsForceLogout;
}

final appLockProvider =
    StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final pinService = ref.watch(pinServiceProvider);
  final biometricService = ref.watch(biometricServiceProvider);
  final patternService = ref.watch(patternServiceProvider);
  return AppLockNotifier(
    ref: ref,
    prefs: prefs,
    pinService: pinService,
    biometricService: biometricService,
    patternService: patternService,
  );
});
