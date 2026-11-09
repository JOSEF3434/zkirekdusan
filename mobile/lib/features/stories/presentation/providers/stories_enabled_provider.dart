// lib/features/stories/presentation/providers/stories_enabled_provider.dart
//
// Global admin toggle: Super-Admin controls whether the Stories service is
// available across the entire platform.
// Persisted to SharedPreferences so the setting survives app restarts.
// Default: true (stories enabled).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kStoriesEnabled = 'stories_enabled';

/// Exposes the current global stories-enabled state.
/// Reads from SharedPreferences; defaults to true (stories ON).
final storiesEnabledProvider =
    StateNotifierProvider<StoriesEnabledNotifier, bool>((ref) {
  return StoriesEnabledNotifier();
});

class StoriesEnabledNotifier extends StateNotifier<bool> {
  StoriesEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kStoriesEnabled) ?? true;
  }

  /// Persists and applies the new enabled value.
  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStoriesEnabled, value);
  }
}
