// lib/features/security/presentation/providers/app_lock_provider.dart
//
// Controls the locked/unlocked state of the app.
// Integrates with AppLifecycleObserver to auto-lock after a configurable
// inactivity timeout.  Also tracks brute-force failed attempts.
// Supports PIN, biometric, and pattern authentication methods.
//
// Biometric auto-switch rule: after [kMaxBiometricAttempts] consecutive
// biometric failures the lock screen silently switches to PIN/pattern entry.
//
// Security note: failed-attempt counters and cooldown timestamps are stored
// in SharedPreferences (not secure storage) because they are not secrets —
// they are simply counters. Resetting SharedPreferences does not grant access
// because the verifier (derived key) lives in secure storage.

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
    show
        BiometricHardwareType,
        biometricHardwareTypeProvider,
        biometricAvailableProvider;

const _kLastActive = 'app_lock_last_active';
const _kFailedAttempts = 'app_lock_failed_attempts';
const _kCooldownUntil = 'app_lock_cooldown_until';
const _kIsLocked = 'app_lock_is_locked';

/// Maximum wrong PIN/pattern attempts before a 30-second cooldown.
const kMaxAttempts = 5;

/// After this many failures the lock screen requires device biometric /
/// device-credential re-authentication as an additional hurdle, without
/// destroying the user's account session.
/// IMPORTANT: we deliberately do NOT force logout — App Lock protects local
/// access; destroying the authenticated session is a denial-of-service risk.
const kMaxAttemptsRequireBiometric = 10;

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

  /// When true (>=10 PIN failures), the lock screen must present biometric/
  /// device-credential challenge before allowing PIN re-entry.
  final bool requireBiometricFallback;

  const AppLockState({
    this.status = AppLockStatus.disabled,
    this.failedAttempts = 0,
    this.biometricFailures = 0,
    this.biometricExhausted = false,
    this.cooldownUntil,
    this.requireBiometricFallback = false,
  });

  bool get isInCooldown =>
      cooldownUntil != null && DateTime.now().isBefore(cooldownUntil!);

  /// Always false — we never destroy the account session from local lock failures.
  bool get shouldForceLogout => false;

  AppLockState copyWith({
    AppLockStatus? status,
    int? failedAttempts,
    int? biometricFailures,
    bool? biometricExhausted,
    DateTime? cooldownUntil,
    bool clearCooldown = false,
    bool? requireBiometricFallback,
  }) =>
      AppLockState(
        status: status ?? this.status,
        failedAttempts: failedAttempts ?? this.failedAttempts,
        biometricFailures: biometricFailures ?? this.biometricFailures,
        biometricExhausted: biometricExhausted ?? this.biometricExhausted,
        cooldownUntil:
            clearCooldown ? null : (cooldownUntil ?? this.cooldownUntil),
        requireBiometricFallback:
            requireBiometricFallback ?? this.requireBiometricFallback,
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

    // Avoid mutating this provider while it is still initializing.
    _ref.listen<AppLockSettings>(appLockSettingsProvider, (prev, next) {
      if (prev == null) return;

      // If App Lock was disabled, update the lock state
      if (!next.isEnabled && state.status != AppLockStatus.disabled) {
        state = const AppLockState(status: AppLockStatus.disabled);
        _secureWindowService.setSecureMode(false);
      }

      // Sync screenshot protection on settings change
      if (next.screenshotProtectionEnabled != prev.screenshotProtectionEnabled) {
        final shouldSecure = next.screenshotProtectionEnabled ||
            (next.isEnabled && state.status == AppLockStatus.locked);
        _secureWindowService.setSecureMode(shouldSecure);
      }
    }, fireImmediately: false);
  }

  Future<void> _init() async {
    if (!_settings.isEnabled) {
      await _prefs.setBool(_kIsLocked, false);
      state = const AppLockState(status: AppLockStatus.disabled);
      // Respect screenshot protection even when app lock is disabled
      _secureWindowService
          .setSecureMode(_settings.screenshotProtectionEnabled);
      return;
    }

    await _prefs.setBool(_kIsLocked, true);
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
    if (!_settings.isEnabled) {
      // Even when app lock is disabled, respect screenshot protection
      if (_settings.screenshotProtectionEnabled) {
        _secureWindowService.setSecureMode(true);
      }
      return;
    }
    await _prefs.setInt(_kLastActive, DateTime.now().millisecondsSinceEpoch);
    if (_settings.timeoutMinutes == 0) {
      _lock();
    }
    // Always secure the window when backgrounded (task switcher protection)
    _secureWindowService.setSecureMode(true);
  }

  Future<void> onResumed() async {
    if (!_settings.isEnabled) {
      // Restore screenshot setting on resume
      _secureWindowService
          .setSecureMode(_settings.screenshotProtectionEnabled);
      return;
    }
    if (state.status == AppLockStatus.locked) return;

    final lastActiveMs = _prefs.getInt(_kLastActive);
    if (lastActiveMs == null) {
      _lock();
      return;
    }

    final timeoutMinutes = _settings.timeoutMinutes;
    if (timeoutMinutes < 0) {
      // Never auto-lock — restore secure mode based on screenshot setting
      _secureWindowService
          .setSecureMode(_settings.screenshotProtectionEnabled);
      return;
    }

    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastActiveMs),
    );

    if (timeoutMinutes == 0 || elapsed.inMinutes >= timeoutMinutes) {
      _lock();
    } else {
      _secureWindowService
          .setSecureMode(_settings.screenshotProtectionEnabled);
    }
  }

  void _lock() {
    if (!_settings.isEnabled) return;
    _prefs.setBool(_kIsLocked, true);
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
      await _prefs.setBool(_kIsLocked, false);
      state = state.copyWith(
        status: AppLockStatus.unlocked,
        failedAttempts: 0,
        biometricFailures: 0,
        biometricExhausted: false,
        clearCooldown: true,
      );
      await _prefs.setInt(_kLastActive, DateTime.now().millisecondsSinceEpoch);
      _secureWindowService
          .setSecureMode(_settings.screenshotProtectionEnabled);
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
      await _prefs.setBool(_kIsLocked, false);
      state = state.copyWith(
        status: AppLockStatus.unlocked,
        failedAttempts: 0,
        clearCooldown: true,
      );
      await _prefs.setInt(_kLastActive, DateTime.now().millisecondsSinceEpoch);
      _secureWindowService
          .setSecureMode(_settings.screenshotProtectionEnabled);
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
      await _prefs.setBool(_kIsLocked, false);
      state = state.copyWith(
        status: AppLockStatus.unlocked,
        failedAttempts: 0,
        clearCooldown: true,
      );
      await _prefs.setInt(_kLastActive, DateTime.now().millisecondsSinceEpoch);
      _secureWindowService
          .setSecureMode(_settings.screenshotProtectionEnabled);
      return true;
    }

    return _handleFailedAttempt();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<bool> _handleFailedAttempt() async {
    final newAttempts = state.failedAttempts + 1;
    await _prefs.setInt(_kFailedAttempts, newAttempts);

    // >=10 failures: require biometric/device-credential challenge.
    // Account session is NEVER destroyed — App Lock is local protection only.
    if (newAttempts >= kMaxAttemptsRequireBiometric) {
      // Apply 10-minute local cooldown + flag to require biometric challenge.
      final cooldownUntil = DateTime.now().add(const Duration(minutes: 10));
      await _prefs.setInt(
          _kCooldownUntil, cooldownUntil.millisecondsSinceEpoch);
      state = state.copyWith(
        status: AppLockStatus.locked,
        failedAttempts: newAttempts,
        cooldownUntil: cooldownUntil,
        requireBiometricFallback: true,
      );
      return false;
    }

    if (newAttempts >= kMaxAttempts) {
      // Progressive cooldown: 30s after 5, 60s after 7, 120s after 9
      final cooldownSeconds = newAttempts >= 9
          ? 120
          : newAttempts >= 7
              ? 60
              : 30;
      final cooldownUntil =
          DateTime.now().add(Duration(seconds: cooldownSeconds));
      await _prefs.setInt(
        _kCooldownUntil,
        cooldownUntil.millisecondsSinceEpoch,
      );
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
    await _prefs.setBool(_kIsLocked, false);
    await _pinService.clearPin();
    await _patternService.clearPattern();
    state = const AppLockState(status: AppLockStatus.disabled);
    _secureWindowService
        .setSecureMode(_settings.screenshotProtectionEnabled);
  }

  void onPinSet() {
    _prefs.setBool(_kIsLocked, false);
    state = state.copyWith(
      status: AppLockStatus.unlocked,
      failedAttempts: 0,
      clearCooldown: true,
    );
    _secureWindowService
        .setSecureMode(_settings.screenshotProtectionEnabled);
  }

  void onPatternSet() {
    _prefs.setBool(_kIsLocked, false);
    state = state.copyWith(
      status: AppLockStatus.unlocked,
      failedAttempts: 0,
      clearCooldown: true,
    );
    _secureWindowService
        .setSecureMode(_settings.screenshotProtectionEnabled);
  }

  /// Always false — account session is never destroyed by local lock failures.
  bool get shouldForceLogout => false;
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((
  ref,
) {
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
