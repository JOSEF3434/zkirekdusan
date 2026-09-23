// ignore_for_file: prefer_initializing_formals
// lib/features/live/presentation/providers/live_room_provider.dart
// Authoritative live room state machine covering the full stream lifecycle:
//   LOADING -> SCHEDULED -> STARTING -> LIVE -> INTERRUPTED -> RECONNECTING -> ENDED / ERROR
//
// Key design decisions:
// - LiveStreamPhase drives all UI. isEnded is derived from phase, not a separate flag.
// - Exponential-backoff HLS reconnect with REST poll to confirm backend status.
// - Separate signals: viewer socket connectivity vs broadcaster connectivity vs HLS health.
// - One reconnect loop at a time — _reconnectTimer guard.
// - stream:interrupted (backend grace period) vs stream:ended (definitive) are distinct.
// - Immediately shows ENDED when REST fetch returns an already-ended stream.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/domain/stream_health_model.dart';
import 'package:mobile/core/storage/secure_storage.dart';

// ---------------------------------------------------------------------------
// Lifecycle Phase Enum
// ---------------------------------------------------------------------------

enum LiveStreamPhase {
  /// Initial REST fetch in progress.
  loading,

  /// Stream is scheduled but not yet started.
  scheduled,

  /// Stream is live but HLS URL not yet available / player connecting.
  starting,

  /// Actively streaming — player healthy.
  live,

  /// Temporary disruption: socket/broadcaster disconnect within grace period.
  /// Retries are in progress; do NOT mark as ended yet.
  interrupted,

  /// Actively retrying HLS connection after interruption.
  reconnecting,

  /// Stream has definitively ended (confirmed by backend or REST).
  ended,

  /// Fatal error — not retryable.
  error,
}

extension LiveStreamPhaseX on LiveStreamPhase {
  bool get isTerminal => this == LiveStreamPhase.ended || this == LiveStreamPhase.error;
  bool get isActive => this == LiveStreamPhase.live || this == LiveStreamPhase.starting;
  bool get showPlayer => this == LiveStreamPhase.live;
  bool get isRetrying => this == LiveStreamPhase.interrupted || this == LiveStreamPhase.reconnecting;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class LiveRoomState {
  final LiveStreamDto? stream;
  final LiveStreamPhase phase;
  final String? error;
  final int viewerCount;
  final StreamHealthDto? health;
  final SocketConnectionState connectionState;
  final String? vodUrl;
  final int retryCount;
  final DateTime? interruptedAt;

  const LiveRoomState({
    this.stream,
    this.phase = LiveStreamPhase.loading,
    this.error,
    this.viewerCount = 0,
    this.health,
    this.connectionState = SocketConnectionState.connecting,
    this.vodUrl,
    this.retryCount = 0,
    this.interruptedAt,
  });

  // Legacy compatibility: screens that read isEnded / isLoading
  bool get isLoading => phase == LiveStreamPhase.loading;
  bool get isEnded => phase == LiveStreamPhase.ended;

  LiveRoomState copyWith({
    LiveStreamDto? stream,
    LiveStreamPhase? phase,
    String? error,
    bool clearError = false,
    int? viewerCount,
    StreamHealthDto? health,
    SocketConnectionState? connectionState,
    String? vodUrl,
    int? retryCount,
    DateTime? interruptedAt,
    bool clearInterruptedAt = false,
  }) => LiveRoomState(
    stream: stream ?? this.stream,
    phase: phase ?? this.phase,
    error: clearError ? null : (error ?? this.error),
    viewerCount: viewerCount ?? this.viewerCount,
    health: health ?? this.health,
    connectionState: connectionState ?? this.connectionState,
    vodUrl: vodUrl ?? this.vodUrl,
    retryCount: retryCount ?? this.retryCount,
    interruptedAt: clearInterruptedAt ? null : (interruptedAt ?? this.interruptedAt),
  );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class LiveRoomNotifier extends StateNotifier<LiveRoomState> {
  final String _streamId;
  final LiveStreamingRepository _repo;
  final LiveSocketService _socket;
  final StorageService _storage;

  final List<StreamSubscription> _subs = [];

  // Reconnect loop
  Timer? _reconnectTimer;
  bool _reconnectCancelled = false;
  static const _maxRetries = 6;
  // Backoff delays: 2, 4, 8, 16, 32, 60 seconds
  static const _backoffDelays = [2, 4, 8, 16, 32, 60];

  // Guard: prevents duplicate joinStream calls
  bool _hasJoined = false;

  LiveRoomNotifier({
    required String streamId,
    required LiveStreamingRepository repo,
    required LiveSocketService socket,
    required StorageService storage,
  }) : _streamId = streamId,
       _repo = repo,
       _socket = socket,
       _storage = storage,
       super(const LiveRoomState()) {
    _init();
  }

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    // 1. Load stream metadata via REST
    LiveStreamDto stream;
    try {
      stream = await _repo.getStreamById(_streamId);
      state = state.copyWith(stream: stream);
    } catch (e) {
      state = state.copyWith(
        phase: LiveStreamPhase.error,
        error: e.toString(),
      );
      return;
    }

    // 2. If already ended, show ended state immediately without connecting player/socket
    if (stream.status == LiveStreamStatus.ended ||
        stream.status == LiveStreamStatus.cancelled ||
        stream.status == LiveStreamStatus.failed) {
      state = state.copyWith(phase: LiveStreamPhase.ended);
      return;
    }

    // 3. Determine initial phase from REST status
    final initialPhase = _phaseFromStatus(stream.status, stream.hlsUrl);
    state = state.copyWith(phase: initialPhase);

    // 4. Connect socket
    final token = await _storage.getToken();
    if (token != null) {
      await _socket.connect(token);
      _joinStream();
    }

    // 5. Subscribe to real-time events
    _subscribeToSocketEvents();
  }

  LiveStreamPhase _phaseFromStatus(
    LiveStreamStatus status,
    String? hlsUrl,
  ) {
    switch (status) {
      case LiveStreamStatus.scheduled:
      case LiveStreamStatus.draft:
        return LiveStreamPhase.scheduled;
      case LiveStreamStatus.live:
        return (hlsUrl != null && hlsUrl.isNotEmpty)
            ? LiveStreamPhase.live
            : LiveStreamPhase.starting;
      case LiveStreamStatus.ended:
      case LiveStreamStatus.cancelled:
      case LiveStreamStatus.failed:
        return LiveStreamPhase.ended;
      case LiveStreamStatus.processing:
      case LiveStreamStatus.vodReady:
        return LiveStreamPhase.ended;
    }
  }

  void _joinStream() {
    if (_hasJoined) return;
    _hasJoined = true;
    _socket.joinStream(_streamId);
  }

  // ── Socket subscriptions ───────────────────────────────────────────────────

  void _subscribeToSocketEvents() {
    _subs.add(
      _socket.connectionState.listen((cs) {
        if (!mounted) return;
        state = state.copyWith(connectionState: cs);
        if (cs == SocketConnectionState.connected) {
          // Re-join after socket reconnect
          _hasJoined = false;
          _joinStream();
          // If we were interrupted at socket level but phase is still interrupted/reconnecting,
          // the player layer will drive retries. If stream was restored at socket level, refresh.
          if (state.phase == LiveStreamPhase.interrupted ||
              state.phase == LiveStreamPhase.reconnecting) {
            _startReconnectRetry();
          }
        }
      }),
    );

    _subs.add(
      _socket.onViewerCount.listen((payload) {
        if (!mounted) return;
        final sid = payload['streamId'] as String?;
        if (sid == _streamId) {
          state = state.copyWith(viewerCount: payload['count'] as int? ?? 0);
        }
      }),
    );

    _subs.add(
      _socket.onStreamUpdated.listen((updated) {
        if (!mounted) return;
        if (updated.id == _streamId) {
          final newPhase = _phaseFromStatus(updated.status, updated.hlsUrl);
          state = state.copyWith(stream: updated, phase: newPhase);
          // If stream has been resumed (broadcaster reconnected), cancel retry loop
          if (newPhase == LiveStreamPhase.live || newPhase == LiveStreamPhase.starting) {
            _cancelReconnect();
          }
        }
      }),
    );

    // stream:started — SCHEDULED/STARTING -> LIVE transition
    _subs.add(
      _socket.onStreamStarted.listen((started) {
        if (!mounted) return;
        if (started.id == _streamId) {
          final phase = (started.hlsUrl != null && started.hlsUrl!.isNotEmpty)
              ? LiveStreamPhase.live
              : LiveStreamPhase.starting;
          state = state.copyWith(
            stream: started,
            phase: phase,
            clearError: true,
            retryCount: 0,
            clearInterruptedAt: true,
          );
          _cancelReconnect();
        }
      }),
    );

    // stream:interrupted — broadcaster disconnected within grace period
    _subs.add(
      _socket.onStreamInterrupted.listen((event) {
        if (!mounted) return;
        if (event.streamId == _streamId) {
          // Only move to interrupted if stream was live
          if (state.phase == LiveStreamPhase.live ||
              state.phase == LiveStreamPhase.starting) {
            state = state.copyWith(
              phase: LiveStreamPhase.interrupted,
              interruptedAt: DateTime.now(),
              clearError: true,
            );
            // Start retrying HLS with backoff while waiting for backend confirmation
            _startReconnectRetry();
          }
        }
      }),
    );

    // stream:ended — definitive end (explicit end or grace period expired)
    _subs.add(
      _socket.onStreamEnded.listen((event) {
        if (!mounted) return;
        if (event.streamId == _streamId) {
          _cancelReconnect();
          state = state.copyWith(
            phase: LiveStreamPhase.ended,
            vodUrl: event.vodUrl,
            stream: state.stream?.copyWith(
              status: LiveStreamStatus.ended,
              duration: event.duration,
            ),
          );
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
  }

  // ── Player interruption (called by LiveRoomScreen when HLS stalls/errors) ──

  /// Called by LiveRoomScreen when the video player reports an error or stall.
  /// Only triggers recovery if the stream is not definitively ended.
  void notifyPlayerInterruption() {
    if (!mounted) return;
    if (state.phase.isTerminal) return;
    if (state.phase == LiveStreamPhase.interrupted ||
        state.phase == LiveStreamPhase.reconnecting) {
      return;
    }

    state = state.copyWith(
      phase: LiveStreamPhase.interrupted,
      interruptedAt: DateTime.now(),
    );
    _startReconnectRetry();
  }

  // ── Exponential backoff reconnect loop ────────────────────────────────────

  void _startReconnectRetry() {
    if (_reconnectTimer != null) return; // Already retrying
    _reconnectCancelled = false;
    _doRetry(0);
  }

  void _doRetry(int attempt) {
    if (_reconnectCancelled || !mounted) return;
    if (state.phase.isTerminal) return;

    if (attempt >= _maxRetries) {
      // Max retries reached — poll REST one final time
      _pollBackendStatus(isFinal: true);
      return;
    }

    final delaySecs = attempt < _backoffDelays.length
        ? _backoffDelays[attempt]
        : _backoffDelays.last;

    state = state.copyWith(
      phase: LiveStreamPhase.reconnecting,
      retryCount: attempt + 1,
    );

    _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
      _reconnectTimer = null;
      if (_reconnectCancelled || !mounted) return;
      _pollBackendStatus(attempt: attempt);
    });
  }

  Future<void> _pollBackendStatus({int attempt = 0, bool isFinal = false}) async {
    if (_reconnectCancelled || !mounted) return;

    try {
      final stream = await _repo.getStreamById(_streamId);
      if (!mounted) return;

      if (stream.status == LiveStreamStatus.ended ||
          stream.status == LiveStreamStatus.cancelled ||
          stream.status == LiveStreamStatus.failed) {
        // Backend confirms stream is definitively ended
        _cancelReconnect();
        state = state.copyWith(
          phase: LiveStreamPhase.ended,
          stream: stream,
          clearInterruptedAt: true,
        );
        return;
      }

      if (stream.status == LiveStreamStatus.live) {
        // Stream is still live — update stream metadata (new HLS URL if changed)
        state = state.copyWith(
          stream: stream,
          // Phase stays reconnecting/interrupted — player layer will try to reconnect
          // and call back here or receive socket event when successful
        );

        if (isFinal) {
          // Ran out of retries but stream is still live — signal error
          state = state.copyWith(
            phase: LiveStreamPhase.error,
            error: 'Could not restore stream connection. Please try again.',
          );
        } else {
          // Keep retrying with backoff
          _doRetry(attempt + 1);
        }
        return;
      }

      // Scheduled or other non-live status
      if (isFinal) {
        state = state.copyWith(
          phase: LiveStreamPhase.interrupted,
          stream: stream,
        );
      } else {
        _doRetry(attempt + 1);
      }
    } catch (_) {
      if (!mounted) return;
      if (isFinal) {
        state = state.copyWith(
          phase: LiveStreamPhase.error,
          error: 'Connection failed. Check your network and try again.',
        );
      } else {
        _doRetry(attempt + 1);
      }
    }
  }

  void _cancelReconnect() {
    _reconnectCancelled = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // ── Player successfully restored ──────────────────────────────────────────

  /// Called by LiveRoomScreen when the video player successfully resumes after
  /// an interruption. Transitions phase back to live.
  void notifyPlayerRestored() {
    if (!mounted) return;
    if (state.phase == LiveStreamPhase.interrupted ||
        state.phase == LiveStreamPhase.reconnecting) {
      _cancelReconnect();
      state = state.copyWith(
        phase: LiveStreamPhase.live,
        retryCount: 0,
        clearInterruptedAt: true,
        clearError: true,
      );
    }
  }

  // ── Player successfully initialized (first time) ──────────────────────────

  /// Called by LiveRoomScreen when the video player initializes for the first time.
  void notifyPlayerReady() {
    if (!mounted) return;
    if (state.phase == LiveStreamPhase.starting) {
      state = state.copyWith(phase: LiveStreamPhase.live);
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = state.copyWith(phase: LiveStreamPhase.loading, clearError: true);
    try {
      final stream = await _repo.getStreamById(_streamId);
      final phase = _phaseFromStatus(stream.status, stream.hlsUrl);
      state = state.copyWith(stream: stream, phase: phase);
      if (!phase.isTerminal && !_hasJoined) {
        _joinStream();
      }
    } catch (e) {
      state = state.copyWith(
        phase: LiveStreamPhase.error,
        error: e.toString(),
      );
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _cancelReconnect();
    _socket.leaveStream(_streamId);
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final liveRoomProvider =
    StateNotifierProvider.family<LiveRoomNotifier, LiveRoomState, String>((
      ref,
      streamId,
    ) {
      final repo = ref.read(liveStreamingRepositoryProvider);
      final socket = ref.read(liveSocketServiceProvider);
      final storage = ref.read(storageServiceProvider);

      return LiveRoomNotifier(
        streamId: streamId,
        repo: repo,
        socket: socket,
        storage: storage,
      );
    });
