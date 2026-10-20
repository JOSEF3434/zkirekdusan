// lib/features/media_experience/presentation/providers/playback_preferences_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/media_experience/data/playback_preferences_repository.dart';
import 'package:mobile/features/media_experience/domain/playback_preferences.dart';

final playbackPreferencesProvider =
    StateNotifierProvider<PlaybackPreferencesNotifier, PlaybackPreferences>((
      ref,
    ) {
      final repo = ref.watch(playbackPreferencesRepositoryProvider);
      return PlaybackPreferencesNotifier(repo);
    });

class PlaybackPreferencesNotifier extends StateNotifier<PlaybackPreferences> {
  final PlaybackPreferencesRepository _repo;

  PlaybackPreferencesNotifier(this._repo) : super(_repo.load());

  Future<void> setAutoplay(bool value) async {
    state = state.copyWith(autoplay: value);
    await _repo.save(state);
  }

  Future<void> setDefaultSpeed(double value) async {
    if (!PlaybackPreferences.allowedSpeeds.contains(value)) return;
    state = state.copyWith(defaultSpeed: value);
    await _repo.save(state);
  }

  Future<void> setDownloadOnWifiOnly(bool value) async {
    state = state.copyWith(downloadOnWifiOnly: value);
    await _repo.save(state);
  }

  Future<void> setDoubleTapSeekEnabled(bool value) async {
    state = state.copyWith(doubleTapSeekEnabled: value);
    await _repo.save(state);
  }

  Future<void> setSeekForwardSeconds(int value) async {
    if (!PlaybackPreferences.allowedSeekIntervals.contains(value)) return;
    state = state.copyWith(seekForwardSeconds: value);
    await _repo.save(state);
  }

  Future<void> setSeekBackwardSeconds(int value) async {
    if (!PlaybackPreferences.allowedSeekIntervals.contains(value)) return;
    state = state.copyWith(seekBackwardSeconds: value);
    await _repo.save(state);
  }

  Future<void> setAutoHideControls(bool value) async {
    state = state.copyWith(autoHideControls: value);
    await _repo.save(state);
  }

  Future<void> setAutoHideDelaySeconds(int value) async {
    if (!PlaybackPreferences.allowedAutoHideDelays.contains(value)) return;
    state = state.copyWith(autoHideDelaySeconds: value);
    await _repo.save(state);
  }
}
