// lib/features/live/presentation/providers/live_room_provider.dart
// Manages the live room state: stream metadata, viewer count, health, socket events.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/domain/stream_health_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class LiveRoomState {
  final LiveStreamDto? stream;
  final bool isLoading;
  final String? error;
  final int viewerCount;
  final StreamHealthDto? health;
  final SocketConnectionState connectionState;
  final bool isEnded;
  final String? vodUrl;

  const LiveRoomState({
    this.stream,
    this.isLoading = true,
    this.error,
    this.viewerCount = 0,
    this.health,
    this.connectionState = SocketConnectionState.connecting,
    this.isEnded = false,
    this.vodUrl,
  });

  LiveRoomState copyWith({
    LiveStreamDto? stream,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? viewerCount,
    StreamHealthDto? health,
    SocketConnectionState? connectionState,
    bool? isEnded,
    String? vodUrl,
  }) =>
      LiveRoomState(
        stream: stream ?? this.stream,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        viewerCount: viewerCount ?? this.viewerCount,
        health: health ?? this.health,
        connectionState: connectionState ?? this.connectionState,
        isEnded: isEnded ?? this.isEnded,
        vodUrl: vodUrl ?? this.vodUrl,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class LiveRoomNotifier extends StateNotifier<LiveRoomState> {
  final String _streamId;
  final LiveStreamingRepository _repo;
  final LiveSocketService _socket;
  final String? _token;

  final List<StreamSubscription> _subs = [];

  LiveRoomNotifier({
    required String streamId,
    required LiveStreamingRepository repo,
    required LiveSocketService socket,
    required String? token,
  })  : _streamId = streamId,
        _repo = repo,
        _socket = socket,
        _token = token,
        super(const LiveRoomState()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Load stream metadata via REST
    try {
      final stream = await _repo.getStreamById(_streamId);
      state = state.copyWith(stream: stream, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return;
    }

    // 2. Connect socket if token available
    if (_token != null) {
      await _socket.connect(_token!);
      _socket.joinStream(_streamId);
    }

    // 3. Subscribe to real-time events
    _subs.add(_socket.connectionState.listen((cs) {
      if (!mounted) return;
      state = state.copyWith(connectionState: cs);
      // Re-join room after reconnect
      if (cs == SocketConnectionState.connected) {
        _socket.joinStream(_streamId);
      }
    }));

    _subs.add(_socket.onViewerCount.listen((payload) {
      if (!mounted) return;
      final sid = payload['streamId'] as String?;
      if (sid == _streamId) {
        state = state.copyWith(viewerCount: payload['count'] as int? ?? 0);
      }
    }));

    _subs.add(_socket.onStreamUpdated.listen((updated) {
      if (!mounted) return;
      if (updated.id == _streamId) {
        state = state.copyWith(stream: updated);
      }
    }));

    _subs.add(_socket.onStreamEnded.listen((event) {
      if (!mounted) return;
      if (event.streamId == _streamId) {
        state = state.copyWith(
          isEnded: true,
          vodUrl: event.vodUrl,
          stream: state.stream?.copyWith(status: LiveStreamStatus.ended),
        );
      }
    }));

    _subs.add(_socket.onStreamHealth.listen((health) {
      if (!mounted) return;
      if (health.streamId == _streamId) {
        state = state.copyWith(health: health);
      }
    }));
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final stream = await _repo.getStreamById(_streamId);
      state = state.copyWith(stream: stream, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _socket.leaveStream(_streamId);
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final liveRoomProvider = StateNotifierProvider.family<LiveRoomNotifier,
    LiveRoomState, String>((ref, streamId) {
  final repo = ref.read(liveStreamingRepositoryProvider);
  final socket = ref.read(liveSocketServiceProvider);
  final authState = ref.read(authProvider);
  final token = authState.token;

  return LiveRoomNotifier(
    streamId: streamId,
    repo: repo,
    socket: socket,
    token: token,
  );
});
