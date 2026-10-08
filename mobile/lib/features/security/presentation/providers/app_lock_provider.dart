// lib/features/security/presentation/providers/app_lock_provider.dart
//
// Controls the locked/unlocked state of the app.
// Integrates with AppLifecycleObserver to auto-lock after a configurable
// inactivity timeout.  Also tracks brute-force failed attempts.
// Supports PIN, biometric, and pattern authentication methods.
//
// Inactivity auto-lock:
//   • When unlocked, a Dart timer fires after [timeoutMinutes].
//   • On any user interaction (pointer/keyboard), [recordActivity()] resets it.
//   • On app-pause, timestamp is persisted; on resume elapsed time is compared
//     to the setting so OS-suspended timers never cause incorrect behavior.
//
// Biometric auto-switch rule: after [kMaxBiometricAttempts] consecutive
// biometric failures the lock screen silently switches to PIN/pattern entry.
//
// Duplicate-prompt guard: [_biometricAuthInProgress] ensures only one
// biometric prompt is open at any time, preventing dialog stacking.

import 'dart:async';
import 'package:flutter/foundation.dart';
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
const _kLastBackground = 'app_lock_last_background';
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
  }) => AppLockState(
    status: status ?? this.status,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    biometricFailures: biometricFailures ?? this.biometricFailures,
    biometricExhausted: biometricExhausted ?? this.biometricExhausted,
    cooldownUntil: clearCooldown ? null : (cooldownUntil ?? this.cooldownUntil),
  );
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  final Ref _ref;
  final SharedPreferences _prefs;
  final PinService _pinService;
  final BiometricService _biometricService;
  final PatternService _patternService;

  // ── Inactivity timer ──────────────────────────────────────────────────────
  // A single timer; never more than one is active at once.
  Timer? _inactivityTimer;

  // ── Biometric duplicate-prompt guard ─────────────────────────────────────
  // True while a biometric OS prompt is open; prevents stacking two prompts.
  bool _biometricAuthInProgress = false;

  AppLockSettings get _settings => _ref.read(appLockSettingsProvider);
  SecureWindowService get _secureWindowService =>
      _ref.read(secureWindowServiceProvider);

  AppLockNotifier({
    required Ref ref,
    required SharedPreferences prefs,
    required PinService pinService,
    required BiometricService biometricService,
    required PatternService patternService,
  }) : _ref = ref,
       _prefs = prefs,
       _pinService = pinService,
       _biometricService = biometricService,
       _patternService = patternService,
       super(const AppLockState()) {
    _init();

    // Listen for settings changes: disable lock OR update the running timer.
    _ref.listen<AppLockSettings>(appLockSettingsProvider, (prev, next) {
      if (prev == null) return;
      if (!next.isEnabled && state.status != AppLockStatus.disabled) {
        _cancelInactivityTimer();
        state = const AppLockState(status: AppLockStatus.disabled);
        _secureWindowService.setSecureMode(false);
        return;
      }
      // Timeout changed while unlocked → restart timer with new duration.
      if (next.isEnabled &&
          state.status == AppLockStatus.unlocked &&
          prev.timeoutMinutes != next.timeoutMinutes) {
        _restartInactivityTimer();
      }
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _cancelInactivityTimer();
    super.dispose();
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
      biometricFailures: 0,
      biometricExhausted: false,
      cooldownUntil: cooldownUntil,
    );
    _secureWindowService.setSecureMode(true);
    // Do NOT start inactivity timer — app starts locked.
  }

  // ── Inactivity timer API ─────────────────────────────────────────────────

  /// Called by [AppActivityTracker] on any meaningful pointer/keyboard event.
  /// Resets the countdown without ever creating duplicate timers.
  void recordActivity() {
    if (state.status != AppLockStatus.unlocked) return;
    _restartInactivityTimer();
    _prefs.setInt(_kLastActive, DateTime.now().millisecondsSinceEpoch);
  }

  void _restartInactivityTimer() {
    _cancelInactivityTimer();
    final minutes = _settings.timeoutMinutes;
    if (minutes < 0) return; // -1 = never auto-lock
    if (minutes == 0) {
      // "Immediately" → lock on background (handled in onPaused).
      // Do not lock instantly in the foreground after unlock.
      return;
    }
    _inactivityTimer = Timer(Duration(minutes: minutes), _onInactivityTimeout);
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _onInactivityTimeout() {
    if (state.status == AppLockStatus.unlocked) {
      debugPrint('[AppLock] Inactivity timeout fired — locking.');
      _lock();
    }
  }

  // ── AppLifecycleObserver callbacks ───────────────────────────────────────

  Future<void> onPaused() async {
    if (!_settings.isEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt(_kLastBackground, now);
    await _prefs.setInt(_kLastActive, now);
    // Stop foreground timer — Dart timers don't fire while the OS suspends.
    _cancelInactivityTimer();
    _secureWindowService.setSecureMode(true);

    // "Immediately" mode: lock the moment the app backgrounds.
    if (_settings.timeoutMinutes == 0 &&
        state.status == AppLockStatus.unlocked) {
      _lock();
    }
  }

  Future<void> onResumed() async {
    if (!_settings.isEnabled) return;
    if (state.status == AppLockStatus.locked) {
      // Already locked — nothing to do; lock screen is shown by the router.
      return;
    }

    final backgroundMs = _prefs.getInt(_kLastBackground);
    if (backgroundMs == null) {
      // No timestamp stored — treat as cold start while unlocked; lock.
      _lock();
      return;
    }

    final timeoutMinutes = _settings.timeoutMinutes;
    if (timeoutMinutes < 0) {
      // "Never" mode — resume without locking, restart foreground timer.
      _secureWindowService.setSecureMode(false);
      _restartInactivityTimer();
      return;
    }

    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(backgroundMs),
    );

    if (timeoutMinutes == 0 || elapsed.inMinutes >= timeoutMinutes) {
      _lock();
    } else {
      _secureWindowService.setSecureMode(false);
      // Resume with remaining time so combined background+foreground
      // inactivity is correctly honoured.
      final remaining = Duration(minutes: timeoutMinutes) - elapsed;
      _cancelInactivityTimer();
      if (remaining > Duration.zero) {
        _inactivityTimer = Timer(remaining, _onInactivityTimeout);
      } else {
        _lock();
      }
    }
  }

  // ── Internal lock ─────────────────────────────────────────────────────────

  void _lock() {
    if (!_settings.isEnabled) return;
    _cancelInactivityTimer();
    state = state.copyWith(
      status: AppLockStatus.locked,
      biometricFailures: 0,
      biometricExhausted: false,
    );
    _secureWindowService.setSecureMode(true);
  }

  void lock() => _lock();

  // ── Biometric authentication ──────────────────────────────────────────────

  /// True while the OS biometric prompt is open; prevents duplicate dialogs.
  bool get isBiometricAuthInProgress => _biometricAuthInProgress;

  Future<bool> authenticateWithBiometric() async {
    if (_biometricAuthInProgress) {
      debugPrint('[AppLock] Biometric auth already in progress — skipping.');
      return false;
    }
    _biometricAuthInProgress = true;

    bool success = false;
    try {
      success = await _biometricService.authenticate(
        reason: 'Unlock ዝክረ ቅዱሳን',
      );
    } finally {
      _biometricAuthInProgress = false;
    }

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
      _restartInactivityTimer();
      return true;
    }

    final newBiometricFailures = state.biometricFailures + 1;
    final exhausted = newBiometricFailures >= kMaxBiometricAttempts;
    state = state.copyWith(
      biometricFailures: newBiometricFailures,
      biometricExhausted: exhausted,
    );
    return false;
  }

  // ── PIN verification ──────────────────────────────────────────────────────

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
      _restartInactivityTimer();
      return true;
    }

    return _handleFailedAttempt();
  }

  // ── Pattern verification ──────────────────────────────────────────────────

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
      _restartInactivityTimer();
      return true;
    }

    return _handleFailedAttempt();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
    _cancelInactivityTimer();
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
    _restartInactivityTimer();
  }

  void onPatternSet() {
    state = state.copyWith(
      status: AppLockStatus.unlocked,
      failedAttempts: 0,
      clearCooldown: true,
    );
    _secureWindowService.setSecureMode(false);
    _restartInactivityTimer();
  }

  bool get shouldForceLogout => state.failedAttempts >= kMaxAttemptsForceLogout;
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
