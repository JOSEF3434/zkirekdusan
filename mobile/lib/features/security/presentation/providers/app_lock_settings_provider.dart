// lib/features/security/presentation/providers/app_lock_settings_provider.dart
//
// Persists user's App Lock preferences to SharedPreferences.
// Controls: enabled, method (pin/biometric/biometricWithPin/pattern),
// timeout minutes, and PIN type (4-digit / 6-digit / password).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/security/data/pin_service.dart';

const _kLockEnabled = 'app_lock_enabled';
const _kLockMethod = 'app_lock_method';
const _kLockTimeout = 'app_lock_timeout_minutes';
const _kPinTypeKey = 'app_lock_pin_type_settings';

/// The authentication method used at the lock screen.
enum AppLockMethod {
  /// No lock (app lock disabled — internal use only).
  none,

  /// 4- or 6-digit PIN, or alphanumeric password. One method at a time.
  pin,

  /// Biometric-first (fingerprint / face ID) with device-credential OS fallback.
  biometric,

  /// Biometric shown first; after 5 biometric failures, switches to PIN entry.
  biometricWithPin,

  /// Android/iOS-style drawn 3×3 pattern lock. One method at a time.
  pattern,
}

extension AppLockMethodX on AppLockMethod {
  String get _key {
    switch (this) {
      case AppLockMethod.biometric:
        return 'biometric';
      case AppLockMethod.biometricWithPin:
        return 'biometric_pin';
      case AppLockMethod.pattern:
        return 'pattern';
      case AppLockMethod.none:
        return 'none';
      default:
        return 'pin';
    }
  }

  static AppLockMethod fromKey(String? key) {
    switch (key) {
      case 'biometric':
        return AppLockMethod.biometric;
      case 'biometric_pin':
        return AppLockMethod.biometricWithPin;
      case 'pattern':
        return AppLockMethod.pattern;
      case 'none':
        return AppLockMethod.none;
      default:
        return AppLockMethod.pin;
    }
  }

  bool get usesBiometric =>
      this == AppLockMethod.biometric ||
      this == AppLockMethod.biometricWithPin;

  bool get usesPin =>
      this == AppLockMethod.pin || this == AppLockMethod.biometricWithPin;

  bool get usesPattern => this == AppLockMethod.pattern;
}

class AppLockSettings {
  final bool isEnabled;
  final AppLockMethod method;
  final int timeoutMinutes; // 0 = immediately, -1 = never
  final PinType pinType;

  const AppLockSettings({
    this.isEnabled = false,
    this.method = AppLockMethod.pin,
    this.timeoutMinutes = 1,
    this.pinType = PinType.pin6,
  });

  AppLockSettings copyWith({
    bool? isEnabled,
    AppLockMethod? method,
    int? timeoutMinutes,
    PinType? pinType,
  }) =>
      AppLockSettings(
        isEnabled: isEnabled ?? this.isEnabled,
        method: method ?? this.method,
        timeoutMinutes: timeoutMinutes ?? this.timeoutMinutes,
        pinType: pinType ?? this.pinType,
      );
}

class AppLockSettingsNotifier extends StateNotifier<AppLockSettings> {
  final SharedPreferences _prefs;

  AppLockSettingsNotifier(this._prefs) : super(const AppLockSettings()) {
    _load();
  }

  void _load() {
    final enabled = _prefs.getBool(_kLockEnabled) ?? false;
    final methodStr = _prefs.getString(_kLockMethod);
    final timeout = _prefs.getInt(_kLockTimeout) ?? 1;
    final pinTypeStr = _prefs.getString(_kPinTypeKey);

    state = AppLockSettings(
      isEnabled: enabled,
      method: AppLockMethodX.fromKey(methodStr),
      timeoutMinutes: timeout,
      pinType: PinTypeX.fromKey(pinTypeStr),
    );
  }

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(_kLockEnabled, value);
    state = state.copyWith(isEnabled: value);
  }

  Future<void> setMethod(AppLockMethod method) async {
    await _prefs.setString(_kLockMethod, method._key);
    state = state.copyWith(method: method);
  }

  Future<void> setTimeout(int minutes) async {
    await _prefs.setInt(_kLockTimeout, minutes);
    state = state.copyWith(timeoutMinutes: minutes);
  }

  Future<void> setPinType(PinType type) async {
    await _prefs.setString(_kPinTypeKey, type.key);
    state = state.copyWith(pinType: type);
  }

  Future<void> disable() async {
    await _prefs.remove(_kLockEnabled);
    await _prefs.remove(_kLockMethod);
    await _prefs.remove(_kLockTimeout);
    await _prefs.remove(_kPinTypeKey);
    state = const AppLockSettings();
  }
}

final appLockSettingsProvider =
    StateNotifierProvider<AppLockSettingsNotifier, AppLockSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppLockSettingsNotifier(prefs);
});
