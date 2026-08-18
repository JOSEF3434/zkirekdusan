// lib/features/media_experience/data/playback_progress_repository.dart
// Persists per-video playback positions locally via SharedPreferences.
// This supplements (does not replace) the backend PATCH /videos/:id/progress.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/media_experience/domain/playback_progress.dart';

const _kProgressKey = 'local_playback_progress';

final playbackProgressRepositoryProvider = Provider<PlaybackProgressRepository>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return PlaybackProgressRepository(prefs);
  },
);

class PlaybackProgressRepository {
  final SharedPreferences _prefs;

  PlaybackProgressRepository(this._prefs);

  /// Load all persisted progress entries.
  Map<String, PlaybackProgress> loadAll() {
    try {
      final raw = _prefs.getString(_kProgressKey);
      if (raw == null) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, PlaybackProgress>{};
      decoded.forEach((key, value) {
        try {
          result[key] = PlaybackProgress.fromJson(
            value as Map<String, dynamic>,
          );
        } catch (_) {
          // Skip malformed entries
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Load progress for a single video. Returns null if not found.
  PlaybackProgress? load(String videoId) => loadAll()[videoId];

  /// Persist progress for a video.
  Future<void> save(PlaybackProgress progress) async {
    final all = loadAll();
    all[progress.videoId] = progress;
    await _persist(all);
  }

  /// Remove a video's progress entry (e.g. when user removes from CW).
  Future<void> remove(String videoId) async {
    final all = loadAll();
    all.remove(videoId);
    await _persist(all);
  }

  /// Clear all progress entries.
  Future<void> clearAll() async {
    await _prefs.remove(_kProgressKey);
  }

  /// Returns only in-progress (not complete, not trivial) entries sorted newest first.
  List<PlaybackProgress> getInProgress() {
    return loadAll().values.where((p) => !p.isComplete && !p.isTrivial).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _persist(Map<String, PlaybackProgress> all) async {
    final map = <String, dynamic>{};
    all.forEach((key, value) => map[key] = value.toJson());
    await _prefs.setString(_kProgressKey, jsonEncode(map));
  }
}
