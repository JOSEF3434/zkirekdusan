// lib/features/media_experience/data/playback_preferences_repository.dart
// Persists playback preferences (autoplay, speed, Wi-Fi-only) via SharedPreferences.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/media_experience/domain/playback_preferences.dart';

const _kPrefsKey = 'playback_preferences';

final playbackPreferencesRepositoryProvider =
    Provider<PlaybackPreferencesRepository>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return PlaybackPreferencesRepository(prefs);
    });

class PlaybackPreferencesRepository {
  final SharedPreferences _prefs;

  PlaybackPreferencesRepository(this._prefs);

  PlaybackPreferences load() {
    try {
      final raw = _prefs.getString(_kPrefsKey);
      if (raw == null) return const PlaybackPreferences();
      return PlaybackPreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const PlaybackPreferences();
    }
  }

  Future<void> save(PlaybackPreferences prefs) async {
    await _prefs.setString(_kPrefsKey, jsonEncode(prefs.toJson()));
  }
}
