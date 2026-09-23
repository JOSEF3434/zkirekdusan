// lib/features/live/presentation/providers/live_discovery_provider.dart
// Paginated live, scheduled, and user-scheduled stream lists with category filtering.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/presentation/providers/scheduled_live_sync_provider.dart';

// ─── Categories Provider ──────────────────────────────────────────────────────

const List<String> kDefaultLiveCategories = [
  'All',
  'Church & Spiritual',
  'Education & Teaching',
  'Music & Chants',
  'Gospel & Preaching',
  'Youth & Culture',
  'Discussion & Q&A',
  'Technology',
  'News & Events',
  'General',
];

class LiveCategoriesNotifier extends StateNotifier<List<String>> {
  LiveCategoriesNotifier() : super(kDefaultLiveCategories);

  void addCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isNotEmpty && !state.contains(trimmed)) {
      state = [...state, trimmed];
    }
  }
}

final liveCategoriesProvider =
    StateNotifierProvider<LiveCategoriesNotifier, List<String>>((ref) {
      return LiveCategoriesNotifier();
    });

final selectedLiveCategoryProvider = StateProvider<String>((ref) => 'All');

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
  final Ref _ref;
  String? _category;
  bool _isFetching = false;

  LiveStreamsNotifier(this._repo, this._ref, {String? category})
      : _category = category,
        super(const LiveDiscoveryState()) {
    load();
    // Listen to real-time status transitions
    _ref.listen<Map<String, LiveStreamStatus>>(scheduledLiveSyncProvider, (prev, next) {
      if (next.values.any((s) => s == LiveStreamStatus.live)) {
        // Refresh live streams if any scheduled stream just transitioned to live
        refresh();
      }
    });
  }

  void updateCategory(String? category) {
    if (_category == category) return;
    _category = category;
    refresh();
  }

  Future<void> load() async {
    if (_isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final effectiveCat = (_category == null || _category == 'All') ? null : _category;
      final result = await _repo.getLiveStreams(page: 1, limit: 20, category: effectiveCat);
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
      final effectiveCat = (_category == null || _category == 'All') ? null : _category;
      final result = await _repo.getLiveStreams(page: next, limit: 20, category: effectiveCat);
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
      final repo = ref.read(liveStreamingRepositoryProvider);
      final selectedCategory = ref.watch(selectedLiveCategoryProvider);
      return LiveStreamsNotifier(repo, ref, category: selectedCategory);
    });

// ─── Scheduled Streams Notifier ───────────────────────────────────────────────

class ScheduledStreamsNotifier extends StateNotifier<LiveDiscoveryState> {
  final LiveStreamingRepository _repo;
  final Ref _ref;
  String? _category;
  bool _isFetching = false;

  ScheduledStreamsNotifier(this._repo, this._ref, {String? category})
      : _category = category,
        super(const LiveDiscoveryState()) {
    load();
    // Listen to real-time status transitions to remove streams that went live
    _ref.listen<Map<String, LiveStreamStatus>>(scheduledLiveSyncProvider, (prev, next) {
      final liveIds = next.entries
          .where((e) => e.value == LiveStreamStatus.live)
          .map((e) => e.key)
          .toSet();
      if (liveIds.isNotEmpty && state.streams.any((s) => liveIds.contains(s.id))) {
        state = state.copyWith(
          streams: state.streams.where((s) => !liveIds.contains(s.id)).toList(),
        );
      }
    });
  }

  void updateCategory(String? category) {
    if (_category == category) return;
    _category = category;
    refresh();
  }

  Future<void> load() async {
    if (_isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final effectiveCat = (_category == null || _category == 'All') ? null : _category;
      final result = await _repo.getScheduledStreams(page: 1, limit: 20, category: effectiveCat);
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
      final effectiveCat = (_category == null || _category == 'All') ? null : _category;
      final result = await _repo.getScheduledStreams(page: next, limit: 20, category: effectiveCat);
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
      final repo = ref.read(liveStreamingRepositoryProvider);
      final selectedCategory = ref.watch(selectedLiveCategoryProvider);
      return ScheduledStreamsNotifier(repo, ref, category: selectedCategory);
    });

// ─── My Scheduled Streams Notifier ────────────────────────────────────────────

class MyScheduledStreamsNotifier extends StateNotifier<LiveDiscoveryState> {
  final LiveStreamingRepository _repo;
  final String? _currentUserId;
  bool _isFetching = false;

  MyScheduledStreamsNotifier(this._repo, this._currentUserId)
      : super(const LiveDiscoveryState()) {
    load();
  }

  Future<void> load() async {
    if (_isFetching || _currentUserId == null) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getUserStreams(_currentUserId, page: 1, limit: 50);
      final filtered = result.items
          .where((s) => s.status == LiveStreamStatus.scheduled || s.scheduledAt != null)
          .toList();
      state = state.copyWith(
        streams: filtered,
        isLoading: false,
        hasMore: false,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    state = const LiveDiscoveryState();
    await load();
  }
}

final myScheduledStreamsProvider =
    StateNotifierProvider<MyScheduledStreamsNotifier, LiveDiscoveryState>((ref) {
      final repo = ref.read(liveStreamingRepositoryProvider);
      final user = ref.watch(authProvider).user;
      return MyScheduledStreamsNotifier(repo, user?.id);
    });
