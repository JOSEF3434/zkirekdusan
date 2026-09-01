// ignore_for_file: prefer_initializing_formals
// lib/features/live/presentation/providers/broadcaster_provider.dart
// Broadcaster studio state: stream key, elapsed timer, health, end stream.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/domain/stream_health_model.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class BroadcasterState {
  final LiveStreamDto? stream;
  final StreamKeyDto? streamKey;
  final bool isLoadingKey;
  final bool isGoingLive;
  final bool isEndingStream;
  final String? error;
  final Duration elapsed;
  final int viewerCount;
  final StreamHealthDto? health;

  const BroadcasterState({
    this.stream,
    this.streamKey,
    this.isLoadingKey = false,
    this.isGoingLive = false,
    this.isEndingStream = false,
    this.error,
    this.elapsed = Duration.zero,
    this.viewerCount = 0,
    this.health,
  });

  BroadcasterState copyWith({
    LiveStreamDto? stream,
    StreamKeyDto? streamKey,
    bool? isLoadingKey,
    bool? isGoingLive,
    bool? isEndingStream,
    String? error,
    bool clearError = false,
    Duration? elapsed,
    int? viewerCount,
    StreamHealthDto? health,
  }) => BroadcasterState(
    stream: stream ?? this.stream,
    streamKey: streamKey ?? this.streamKey,
    isLoadingKey: isLoadingKey ?? this.isLoadingKey,
    isGoingLive: isGoingLive ?? this.isGoingLive,
    isEndingStream: isEndingStream ?? this.isEndingStream,
    error: clearError ? null : (error ?? this.error),
    elapsed: elapsed ?? this.elapsed,
    viewerCount: viewerCount ?? this.viewerCount,
    health: health ?? this.health,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class BroadcasterNotifier extends StateNotifier<BroadcasterState> {
  final String _streamId;
  final String _channelId;
  final LiveStreamingRepository _repo;
  final LiveSocketService _socket;

  Timer? _elapsedTimer;
  final List<StreamSubscription> _subs = [];

  BroadcasterNotifier({
    required String streamId,
    required String channelId,
    required LiveStreamingRepository repo,
    required LiveSocketService socket,
    LiveStreamDto? initialStream,
  }) : _streamId = streamId,
       _channelId = channelId,
       _repo = repo,
       _socket = socket,
       super(BroadcasterState(stream: initialStream)) {
    _init();
  }

  Future<void> _init() async {
    // Load stream key info (prefix only)
    await _loadStreamKey();

    // Load stream if not provided
    if (state.stream == null) {
      try {
        final s = await _repo.getStreamById(_streamId);
        state = state.copyWith(stream: s);
        _maybeStartTimer(s);
      } catch (e) {
        state = state.copyWith(error: e.toString());
      }
    } else {
      _maybeStartTimer(state.stream!);
    }

    // Subscribe to socket events
    _subs.add(
      _socket.onViewerCount.listen((payload) {
        if (!mounted) return;
        if (payload['streamId'] == _streamId) {
          state = state.copyWith(viewerCount: payload['count'] as int? ?? 0);
        }
      }),
    );

    _subs.add(
      _socket.onStreamHealth.listen((health) {
        if (!mounted) return;
        if (health.streamId == _streamId) {
          state = state.copyWith(health: health);
        }
      }),
    );

    _subs.add(
      _socket.onStreamUpdated.listen((updated) {
        if (!mounted) return;
        if (updated.id == _streamId) {
          state = state.copyWith(stream: updated);
          _maybeStartTimer(updated);
        }
      }),
    );
  }

  void _maybeStartTimer(LiveStreamDto s) {
    if (s.status == LiveStreamStatus.live && _elapsedTimer == null) {
      DateTime start;
      if (s.startedAt != null) {
        start = DateTime.tryParse(s.startedAt!) ?? DateTime.now();
      } else {
        start = DateTime.now();
      }
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        state = state.copyWith(elapsed: DateTime.now().difference(start));
      });
    }
  }

  Future<void> _loadStreamKey() async {
    state = state.copyWith(isLoadingKey: true);
    try {
      final key = await _repo.getStreamKey(_channelId);
      state = state.copyWith(streamKey: key, isLoadingKey: false);
    } catch (_) {
      state = state.copyWith(isLoadingKey: false);
    }
  }

  Future<void> regenerateStreamKey() async {
    state = state.copyWith(isLoadingKey: true);
    try {
      final key = await _repo.regenerateStreamKey(_channelId);
      state = state.copyWith(streamKey: key, isLoadingKey: false);
    } catch (e) {
      state = state.copyWith(isLoadingKey: false, error: e.toString());
    }
  }

  Future<void> goLive() async {
    state = state.copyWith(isGoingLive: true, clearError: true);
    try {
      final updated = await _repo.startStream(_streamId);
      state = state.copyWith(stream: updated, isGoingLive: false);
      _maybeStartTimer(updated);
    } catch (e) {
      state = state.copyWith(isGoingLive: false, error: e.toString());
    }
  }

  Future<void> endStream() async {
    state = state.copyWith(isEndingStream: true, clearError: true);
    try {
      final updated = await _repo.endStream(_streamId);
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
      state = state.copyWith(stream: updated, isEndingStream: false);
    } catch (e) {
      state = state.copyWith(isEndingStream: false, error: e.toString());
    }
  }

  Future<void> publishVod() async {
    try {
      final updated = await _repo.publishVod(_streamId);
      state = state.copyWith(stream: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

// Param: streamId|channelId
final broadcasterProvider =
    StateNotifierProvider.family<
      BroadcasterNotifier,
      BroadcasterState,
      (String, String)
    >((ref, ids) {
      final (streamId, channelId) = ids;
      return BroadcasterNotifier(
        streamId: streamId,
        channelId: channelId,
        repo: ref.read(liveStreamingRepositoryProvider),
        socket: ref.read(liveSocketServiceProvider),
      );
    });
