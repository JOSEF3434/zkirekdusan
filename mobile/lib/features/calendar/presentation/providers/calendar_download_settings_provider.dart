// lib/features/calendar/presentation/providers/calendar_download_settings_provider.dart
// Global toggle: Super-Admin controls whether calendar media can be downloaded.
// Persisted to SharedPreferences so the setting survives app restarts.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCalendarDownloadEnabled = 'calendar_download_enabled';

/// Exposes the current global download-enabled state.
/// Reads from SharedPreferences; defaults to false.
final calendarDownloadEnabledProvider =
    StateNotifierProvider<CalendarDownloadSettingsNotifier, bool>((ref) {
  return CalendarDownloadSettingsNotifier();
});

class CalendarDownloadSettingsNotifier extends StateNotifier<bool> {
  CalendarDownloadSettingsNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kCalendarDownloadEnabled) ?? false;
  }

  /// Toggles the download setting and persists the new value.
  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCalendarDownloadEnabled, value);
  }
}
