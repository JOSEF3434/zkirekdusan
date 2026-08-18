// lib/features/media_experience/presentation/providers/continue_watching_provider.dart
// Exposes a list of in-progress videos from local progress storage.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/media_experience/data/playback_progress_repository.dart';
import 'package:mobile/features/media_experience/domain/playback_progress.dart';

class ContinueWatchingState {
  final List<PlaybackProgress> items;
  final bool isLoading;
  final String? error;

  const ContinueWatchingState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ContinueWatchingState copyWith({
    List<PlaybackProgress>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => ContinueWatchingState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

final continueWatchingProvider =
    StateNotifierProvider<ContinueWatchingNotifier, ContinueWatchingState>((
      ref,
    ) {
      final repo = ref.watch(playbackProgressRepositoryProvider);
      return ContinueWatchingNotifier(repo);
    });

class ContinueWatchingNotifier extends StateNotifier<ContinueWatchingState> {
  final PlaybackProgressRepository _repo;

  ContinueWatchingNotifier(this._repo) : super(const ContinueWatchingState()) {
    _load();
  }

  void _load() {
    try {
      final items = _repo.getInProgress();
      state = state.copyWith(items: items, clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void refresh() => _load();

  Future<void> removeItem(String videoId) async {
    await _repo.remove(videoId);
    _load();
  }

  /// Called by player to update local progress. Does not rebuild unnecessarily
  /// if the item is not in the current list — player provider handles persistence.
  void onProgressUpdated() => _load();
}
