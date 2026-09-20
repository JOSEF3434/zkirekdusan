// lib/features/security/presentation/providers/app_lock_settings_provider.dart
//
// Persists user's App Lock preferences to SharedPreferences.
// Controls: enabled, method (pin/biometric/biometric_pin), timeout minutes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';

const _kLockEnabled = 'app_lock_enabled';
const _kLockMethod = 'app_lock_method';
const _kLockTimeout = 'app_lock_timeout_minutes';

enum AppLockMethod { none, pin, biometric, biometricWithPin }

class AppLockSettings {
  final bool isEnabled;
  final AppLockMethod method;
  final int timeoutMinutes; // 0 = immediately, -1 = never

  const AppLockSettings({
    this.isEnabled = false,
    this.method = AppLockMethod.pin,
    this.timeoutMinutes = 1,
  });

  AppLockSettings copyWith({
    bool? isEnabled,
    AppLockMethod? method,
    int? timeoutMinutes,
  }) =>
      AppLockSettings(
        isEnabled: isEnabled ?? this.isEnabled,
        method: method ?? this.method,
        timeoutMinutes: timeoutMinutes ?? this.timeoutMinutes,
      );
}

class AppLockSettingsNotifier extends StateNotifier<AppLockSettings> {
  final SharedPreferences _prefs;

  AppLockSettingsNotifier(this._prefs) : super(const AppLockSettings()) {
    _load();
  }

  void _load() {
    final enabled = _prefs.getBool(_kLockEnabled) ?? false;
    final methodStr = _prefs.getString(_kLockMethod) ?? 'pin';
    final timeout = _prefs.getInt(_kLockTimeout) ?? 1;

    AppLockMethod method;
    switch (methodStr) {
      case 'biometric':
        method = AppLockMethod.biometric;
        break;
      case 'biometric_pin':
        method = AppLockMethod.biometricWithPin;
        break;
      default:
        method = AppLockMethod.pin;
    }

    state = AppLockSettings(
      isEnabled: enabled,
      method: method,
      timeoutMinutes: timeout,
    );
  }

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(_kLockEnabled, value);
    state = state.copyWith(isEnabled: value);
  }

  Future<void> setMethod(AppLockMethod method) async {
    String methodStr;
    switch (method) {
      case AppLockMethod.biometric:
        methodStr = 'biometric';
        break;
      case AppLockMethod.biometricWithPin:
        methodStr = 'biometric_pin';
        break;
      default:
        methodStr = 'pin';
    }
    await _prefs.setString(_kLockMethod, methodStr);
    state = state.copyWith(method: method);
  }

  Future<void> setTimeout(int minutes) async {
    await _prefs.setInt(_kLockTimeout, minutes);
    state = state.copyWith(timeoutMinutes: minutes);
  }

  Future<void> disable() async {
    await _prefs.remove(_kLockEnabled);
    await _prefs.remove(_kLockMethod);
    await _prefs.remove(_kLockTimeout);
    state = const AppLockSettings();
  }
}

final appLockSettingsProvider =
    StateNotifierProvider<AppLockSettingsNotifier, AppLockSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppLockSettingsNotifier(prefs);
});
