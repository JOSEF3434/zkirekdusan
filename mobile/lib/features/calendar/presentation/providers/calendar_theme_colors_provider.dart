// lib/features/calendar/presentation/providers/calendar_theme_colors_provider.dart
// Riverpod state notifier for user-customizable Ethiopian calendar colors with SharedPreferences persistence.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/calendar/domain/calendar_theme_colors.dart';

class CalendarThemeColorsNotifier extends StateNotifier<CalendarThemeColors> {
  final SharedPreferences? _prefs;

  static const String prefFastColor = 'calendar_theme_fast_color';
  static const String prefHolidayColor = 'calendar_theme_holiday_color';
  static const String prefFeastColor = 'calendar_theme_feast_color';

  CalendarThemeColorsNotifier(this._prefs) : super(_loadInitialColors(_prefs));

  static CalendarThemeColors _loadInitialColors(SharedPreferences? prefs) {
    if (prefs == null) return const CalendarThemeColors();
    final fast = prefs.getString(prefFastColor) ?? CalendarThemeColors.defaultFastHex;
    final holiday = prefs.getString(prefHolidayColor) ?? CalendarThemeColors.defaultHolidayHex;
    final feast = prefs.getString(prefFeastColor) ?? CalendarThemeColors.defaultFeastHex;
    return CalendarThemeColors(
      fastColorHex: fast,
      holidayColorHex: holiday,
      feastColorHex: feast,
    );
  }

  Future<void> setFastColor(String hex) async {
    state = state.copyWith(fastColorHex: hex);
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(prefFastColor, hex);
  }

  Future<void> setHolidayColor(String hex) async {
    state = state.copyWith(holidayColorHex: hex);
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(prefHolidayColor, hex);
  }

  Future<void> setFeastColor(String hex) async {
    state = state.copyWith(feastColorHex: hex);
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(prefFeastColor, hex);
  }

  Future<void> applyPreset(CalendarColorPreset preset) async {
    state = CalendarThemeColors(
      fastColorHex: preset.fastColorHex,
      holidayColorHex: preset.holidayColorHex,
      feastColorHex: preset.feastColorHex,
    );
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(prefFastColor, preset.fastColorHex);
    await p.setString(prefHolidayColor, preset.holidayColorHex);
    await p.setString(prefFeastColor, preset.feastColorHex);
  }

  Future<void> resetToDefault() async {
    state = const CalendarThemeColors();
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.remove(prefFastColor);
    await p.remove(prefHolidayColor);
    await p.remove(prefFeastColor);
  }
}

final calendarThemeColorsProvider =
    StateNotifierProvider<CalendarThemeColorsNotifier, CalendarThemeColors>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    // Allows testing without providing sharedPreferencesProvider override
  }
  return CalendarThemeColorsNotifier(prefs);
});
