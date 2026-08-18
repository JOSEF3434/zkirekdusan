import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, PreferencesState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return PreferencesNotifier(prefs);
    });

class PreferencesState {
  final ThemeMode themeMode;
  final String languageCode;
  final bool isFirstLaunch;

  const PreferencesState({
    required this.themeMode,
    required this.languageCode,
    required this.isFirstLaunch,
  });

  PreferencesState copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? isFirstLaunch,
  }) {
    return PreferencesState(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
    );
  }
}

class PreferencesNotifier extends StateNotifier<PreferencesState> {
  final SharedPreferences _prefs;

  PreferencesNotifier(this._prefs)
    : super(
        PreferencesState(
          themeMode: _loadThemeMode(_prefs),
          languageCode: _prefs.getString('languageCode') ?? 'en',
          isFirstLaunch: _prefs.getBool('isFirstLaunch') ?? true,
        ),
      );

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final mode = prefs.getString('themeMode');
    if (mode == 'light') return ThemeMode.light;
    if (mode == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    String modeString = 'system';
    if (mode == ThemeMode.light) modeString = 'light';
    if (mode == ThemeMode.dark) modeString = 'dark';
    await _prefs.setString('themeMode', modeString);
  }

  Future<void> setLanguageCode(String code) async {
    state = state.copyWith(languageCode: code);
    await _prefs.setString('languageCode', code);
  }

  Future<void> completeFirstLaunch() async {
    state = state.copyWith(isFirstLaunch: false);
    await _prefs.setBool('isFirstLaunch', false);
  }
}
