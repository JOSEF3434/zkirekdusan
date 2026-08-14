// lib/features/live/presentation/providers/live_discovery_provider.dart
// Paginated live & scheduled stream lists.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class LiveDiscoveryState {
  final List<LiveStreamDto> streams;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const LiveDiscoveryState({
    this.streams = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  LiveDiscoveryState copyWith({
    List<LiveStreamDto>? streams,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool clearError = false,
  }) => LiveDiscoveryState(
    streams: streams ?? this.streams,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    currentPage: currentPage ?? this.currentPage,
    error: clearError ? null : (error ?? this.error),
  );
}

// ─── Live Streams Notifier ────────────────────────────────────────────────────

class LiveStreamsNotifier extends StateNotifier<LiveDiscoveryState> {
  final LiveStreamingRepository _repo;
  bool _isFetching = false;

  LiveStreamsNotifier(this._repo) : super(const LiveDiscoveryState()) {
    load();
  }

  Future<void> load() async {
    if (_isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getLiveStreams(page: 1, limit: 20);
      // Deduplicate by id
      final seen = <String>{};
      final unique = result.items.where((s) => seen.add(s.id)).toList();
      state = state.copyWith(
        streams: unique,
        isLoading: false,
        hasMore: result.hasNext,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore() async {
    if (_isFetching || !state.hasMore || state.isLoadingMore) return;
    _isFetching = true;
    state = state.copyWith(isLoadingMore: true);
    try {
      final next = state.currentPage + 1;
      final result = await _repo.getLiveStreams(page: next, limit: 20);
      final existing = {for (final s in state.streams) s.id};
      final newItems = result.items
          .where((s) => !existing.contains(s.id))
          .toList();
      state = state.copyWith(
        streams: [...state.streams, ...newItems],
        isLoadingMore: false,
        hasMore: result.hasNext,
        currentPage: next,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    state = const LiveDiscoveryState();
    await load();
  }
}

final liveStreamsProvider =
    StateNotifierProvider<LiveStreamsNotifier, LiveDiscoveryState>((ref) {
      return LiveStreamsNotifier(ref.read(liveStreamingRepositoryProvider));
    });

// ─── Scheduled Streams Notifier ───────────────────────────────────────────────

class ScheduledStreamsNotifier extends StateNotifier<LiveDiscoveryState> {
  final LiveStreamingRepository _repo;
  bool _isFetching = false;

  ScheduledStreamsNotifier(this._repo) : super(const LiveDiscoveryState()) {
    load();
  }

  Future<void> load() async {
    if (_isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getScheduledStreams(page: 1, limit: 20);
      final seen = <String>{};
      final unique = result.items.where((s) => seen.add(s.id)).toList();
      state = state.copyWith(
        streams: unique,
        isLoading: false,
        hasMore: result.hasNext,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore() async {
    if (_isFetching || !state.hasMore || state.isLoadingMore) return;
    _isFetching = true;
    state = state.copyWith(isLoadingMore: true);
    try {
      final next = state.currentPage + 1;
      final result = await _repo.getScheduledStreams(page: next, limit: 20);
      final existing = {for (final s in state.streams) s.id};
      final newItems = result.items
          .where((s) => !existing.contains(s.id))
          .toList();
      state = state.copyWith(
        streams: [...state.streams, ...newItems],
        isLoadingMore: false,
        hasMore: result.hasNext,
        currentPage: next,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    state = const LiveDiscoveryState();
    await load();
  }
}

final scheduledStreamsProvider =
    StateNotifierProvider<ScheduledStreamsNotifier, LiveDiscoveryState>((ref) {
      return ScheduledStreamsNotifier(
        ref.read(liveStreamingRepositoryProvider),
      );
    });
