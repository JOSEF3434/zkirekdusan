// lib/features/live/presentation/screens/live_room_screen.dart
// YouTube Live-style viewer experience:
//   * 16:9 player pinned at the top
//   * Live badge + viewer count overlay on the player
//   * Floating animated emoji reactions
//   * Scrollable chat below the player
//   * Emoji reaction picker bar at the very bottom

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_dvr_state.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/presentation/providers/live_room_provider.dart';
import 'package:mobile/features/live/presentation/widgets/cast_panel_widget.dart';
import 'package:mobile/features/live/presentation/widgets/dvr_seek_bar.dart';
import 'package:mobile/features/live/presentation/widgets/live_badge_widget.dart';
import 'package:mobile/features/live/presentation/widgets/live_chat_widget.dart';
import 'package:mobile/features/live/presentation/widgets/live_player_controls_overlay.dart';
import 'package:mobile/features/live/presentation/widgets/live_stream_progress_bar.dart';
import 'package:mobile/features/live/presentation/widgets/responsive_video_stage.dart';
import 'package:mobile/features/live/presentation/widgets/viewer_count_widget.dart';
import 'package:mobile/features/live/presentation/widgets/web_hls_controller.dart';
import 'package:mobile/features/live/presentation/widgets/web_hls_player_shim.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/core/utils/ethiopian_calendar.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/security/presentation/providers/media_activity_provider.dart';

// ─── Reaction Particle ────────────────────────────────────────────────────────

class _Particle {
  final String emoji;
  final double xPos; // 0..1 relative to parent width
  final AnimationController ctrl;
  late final Animation<double> opacity;
  late final Animation<double> y;

  _Particle({required this.emoji, required this.xPos, required this.ctrl}) {
    opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: ctrl, curve: const Interval(0.5, 1.0)));
    y = Tween<double>(
      begin: 0,
      end: -200,
    ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
  }
}


// ─── Main Screen ──────────────────────────────────────────────────────────────

class LiveRoomScreen extends ConsumerStatefulWidget {
  final String streamId;
  const LiveRoomScreen({super.key, required this.streamId});

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Player & DVR state
  VideoPlayerController? _playerCtrl;
  String? _webHlsUrl;
  final WebHlsController _webHlsCtrl = WebHlsController();
  String? _activePlaybackUrl;
  DvrTimelineSnapshot? _dvrTimeline;
  bool _usingDvrOrigin = false;
  Size? _sourceVideoSize;
  VideoFitMode _fitMode = VideoFitMode.fill;
  LivePlaybackState _playbackState = LivePlaybackState.liveEdge;
  bool _isChatExpanded = true;
  bool _isScrubbing = false;
  bool _manualPaused = false;
  bool _dvrExpired = false;
  bool _isSwappingController = false;
  int _selectedQualityIndex = -1;
  double _mobileVolume = 1.0;
  bool _mobileMuted = false;
  DateTime? _lastSeekAt;
  LivePlaybackState? _transientSeekState;
  Timer? _dvrSyncTimer;
  bool _isDisposed = false;
  bool _isRefreshingDvrTimeline = false;
  bool _endCheckInFlight = false;
  final GlobalKey _playerStageKey = GlobalKey(debugLabel: 'live_player_stage');
  final GlobalKey _webPlayerKey = GlobalKey(debugLabel: 'web_hls_player');

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  bool _playerInitialized = false;
  bool _isPlayerInitializing = false;
  bool _playerError = false;
  // True when all retry attempts returned 404 (stream not yet publishing).
  bool _streamNotYetPublishing = false;
  int _initAttemptCount = 0;
  static const int _maxInitAttempts = 8;
  Timer? _playerRetryTimer;
  bool _controlsVisible = true;
  bool _isFullscreen = false;

  // Mini-player drag tracking
  double _dragOffset = 0;
  bool _isDragging = false;
  static const _kMiniDragThreshold = 60.0; // px to trigger minimize
  bool _redirectedToStudio = false;

  // Reactions
  final List<_Particle> _particles = [];
  final _rng = Random();
  StreamSubscription<ReactionBroadcastEvent>? _reactionSub;

  // Timer to hide controls
  Timer? _hideControlsTimer;

  // Media-session ID for App Lock inactivity exemption.
  String get _mediaSessionId => 'live-viewer:${widget.streamId}';

  // Cached notifier reference so we can call endSession in dispose() without
  // touching ref (which throws after widget disposal in Riverpod 2.x).
  late final Object _mediaActivityNotifier;

  void _checkCreatorRedirect(LiveRoomState roomState) {
    // Guard: never call ref.read after the widget element is disposed.
    if (!mounted) return;
    if (_redirectedToStudio) return;
    final stream = roomState.stream;
    if (stream == null ||
        roomState.phase == LiveStreamPhase.ended ||
        stream.status == LiveStreamStatus.ended ||
        stream.status == LiveStreamStatus.vodReady ||
        stream.status == LiveStreamStatus.cancelled ||
        stream.status == LiveStreamStatus.failed) {
      return;
    }

    final authUser = ref.read(authProvider).user;
    if (authUser == null) return;

    final isCreator = stream.createdById == authUser.id ||
        (stream.createdBy?.username != null &&
         stream.createdBy!.username == authUser.username);

    if (isCreator) {
      _redirectedToStudio = true;
      WakelockPlus.disable().ignore();
      _playerCtrl?.pause();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement(
            '/live/studio?streamId=${stream.id}&channelId=${stream.videoChannelId}',
          );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Cache the notifier reference NOW (before any async work) so dispose() can
    // call endSession without invoking ref.read on a disposed element.
    _mediaActivityNotifier =
        ref.read(mediaActivityProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable().ignore();
    _webHlsCtrl.addListener(_onWebHlsChanged);
    _scheduleHideControls();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reactionSub = ref
          .read(liveSocketServiceProvider)
          .onReactionBroadcast
          .listen(_onReactionReceived);

      // Reclaim controller from mini player if we're re-entering the same stream.
      final mini = ref.read(miniPlayerProvider);
      if (mini.contentId == widget.streamId &&
          mini.controller != null &&
          mini.controller!.value.isInitialized) {
        final wasPlaying = mini.isPlaying ||
            mini.wasPlayingBeforeHandoff ||
            ref.read(miniPlayerProvider.notifier).lastReclaimedWasPlaying;
        final reclaimed = ref
            .read(miniPlayerProvider.notifier)
            .reclaimController(widget.streamId);
        if (reclaimed != null) {
          if (wasPlaying) {
            reclaimed.play().catchError((_) {});
          }
          debugPrint(
            '[LiveRoomScreen] Fullscreen player mounted; controller reclaimed '
            'for ${widget.streamId} position=${reclaimed.value.position} '
            'playing=${reclaimed.value.isPlaying}',
          );
          final reclaimedSize = _orientedVideoSize(reclaimed.value);
          setState(() {
            _playerCtrl = reclaimed;
            _playerInitialized = true;
            _manualPaused = !reclaimed.value.isPlaying;
            if (reclaimedSize != null) {
              _sourceVideoSize = reclaimedSize;
            }
          });
          _attachPlayerListeners(reclaimed);
          _startDvrTimelineSync();
          ref.read(liveRoomProvider(widget.streamId).notifier).notifyPlayerReady();
        }
      } else if (mini.hasContent && mini.contentId != widget.streamId) {
        // Dismiss previous mini player if entering a different stream
        ref.read(miniPlayerProvider.notifier).dismiss();
      }

      // Check initial state: if starting or live and HLS is available, initialize
      final initialRoom = ref.read(liveRoomProvider(widget.streamId));
      _checkCreatorRedirect(initialRoom);

      if (!initialRoom.phase.isTerminal &&
          initialRoom.phase != LiveStreamPhase.ended &&
          initialRoom.stream?.hlsUrl != null &&
          initialRoom.stream!.hlsUrl!.isNotEmpty &&
          !_playerInitialized &&
          !_isPlayerInitializing) {
        _initPlayer(initialRoom.stream!.hlsUrl!);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _reactionSub?.cancel();
    _playerRetryTimer?.cancel();
    _dvrSyncTimer?.cancel();
    _webHlsCtrl.removeListener(_onWebHlsChanged);
    _webHlsCtrl.dispose();
    // Use the cached notifier — never call ref.read here; the element is being
    // disposed and Riverpod will throw "Cannot use ref after disposal".
    // We defer via Future.microtask to avoid modifying providers during widget teardown.
    final notifier = _mediaActivityNotifier;
    final sessionId = _mediaSessionId;
    Future.microtask(() {
      try {
        (notifier as dynamic).endSession(sessionId);
      } catch (_) {}
    });
    // Note: _playerCtrl may have been transferred to miniPlayerProvider
    // (in that case it's null here because we call _minimizeToMiniPlayer).
    _playerCtrl?.dispose();
    _hideControlsTimer?.cancel();
    for (final p in _particles) {
      p.ctrl.dispose();
    }
    _particles.clear();
    WakelockPlus.disable().ignore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _playerCtrl?.pause();
    } else if (state == AppLifecycleState.resumed) {
      final roomState = ref.read(liveRoomProvider(widget.streamId));
      if (roomState.phase == LiveStreamPhase.live &&
          !_manualPaused &&
          _playerCtrl != null &&
          _playerCtrl!.value.isInitialized) {
        _playerCtrl?.play();
      }
    }
  }

  Size? _orientedVideoSize(VideoPlayerValue val) {
    final sz = val.size;
    if (sz.width <= 0 || sz.height <= 0) return null;
    return val.rotationCorrection % 180 != 0
        ? Size(sz.height, sz.width)
        : sz;
  }

  void _attachPlayerListeners(VideoPlayerController ctrl) {
    ctrl.addListener(() {
      if (!mounted || _isDisposed) return;
      if (ctrl != _playerCtrl) return;
      if (ctrl.value.hasError) {
        debugPrint(
          '[LiveRoom] Player error detected during playback: ${ctrl.value.errorDescription}',
        );
        _handlePlaybackError();
        return;
      }

      final sz = _orientedVideoSize(ctrl.value);
      if (sz != null && sz != _sourceVideoSize) {
        _safeSetState(() => _sourceVideoSize = sz);
      } else {
        _syncPlaybackState();
      }
    });
  }

  void _onWebHlsChanged() {
    if (!mounted || _isDisposed) return;
    final snap = _webHlsCtrl.value;
    bool stateDirty = false;
    if (snap.videoSize != null &&
        !snap.videoSize!.isEmpty &&
        snap.videoSize != _sourceVideoSize) {
      _sourceVideoSize = snap.videoSize;
      stateDirty = true;
    }
    if (snap.dvrExpired && !_dvrExpired) {
      _dvrExpired = true;
      stateDirty = true;
    }
    if (stateDirty) {
      _safeSetState(() {});
    }
    _syncPlaybackState();
  }

  DvrWindowMath _currentWindowMath() {
    if (kIsWeb && _webHlsUrl != null) {
      final snap = _webHlsCtrl.value;
      return computeDvrWindowMath(
        currentPosition: snap.position,
        reportedDuration: snap.seekableEnd,
        seekableStart: snap.seekableStart,
        seekableEnd: snap.seekableEnd,
        bufferedEnd: snap.bufferedEnd,
        liveSyncPosition: snap.liveSyncPosition,
        serverTimeline: _dvrTimeline,
      );
    }

    final ctrl = _playerCtrl;
    final val = ctrl?.value;
    final bufferedEnd = (val != null && val.buffered.isNotEmpty)
        ? val.buffered.last.end
        : null;
    return computeDvrWindowMath(
      currentPosition: val?.position ?? Duration.zero,
      reportedDuration: val?.duration ?? Duration.zero,
      bufferedEnd: bufferedEnd,
      serverTimeline: _dvrTimeline,
    );
  }

  bool get _isDvrAvailable {
    if (_usingDvrOrigin) return true;
    if (_dvrTimeline != null && _dvrTimeline!.hasSegments) return true;
    if (kIsWeb && _webHlsUrl != null) {
      final snap = _webHlsCtrl.value;
      return snap.seekableEnd - snap.seekableStart > const Duration(seconds: 20);
    }
    return false;
  }

  void _syncPlaybackState() {
    if (!mounted || _isDisposed) return;
    final roomState = ref.read(liveRoomProvider(widget.streamId));
    LivePlaybackState next;

    if (roomState.phase == LiveStreamPhase.ended) {
      next = LivePlaybackState.ended;
    } else if (_dvrExpired) {
      next = LivePlaybackState.dvrExpired;
    } else if (roomState.phase == LiveStreamPhase.reconnecting ||
        roomState.phase == LiveStreamPhase.interrupted) {
      next = LivePlaybackState.reconnecting;
    } else if (_playerError) {
      next = LivePlaybackState.error;
    } else if (_isSwappingController || _isPlayerInitializing) {
      next = LivePlaybackState.seeking;
    } else if (_lastSeekAt != null &&
        DateTime.now().difference(_lastSeekAt!) <
            const Duration(milliseconds: 900) &&
        _transientSeekState != null) {
      next = _transientSeekState!;
    } else if (kIsWeb && _webHlsUrl != null) {
      final snap = _webHlsCtrl.value;
      if (snap.isEnded) {
        next = LivePlaybackState.ended;
        _triggerEndVerification();
      } else if (snap.isSeeking) {
        next = LivePlaybackState.seeking;
      } else if (!snap.isPlaying && _manualPaused) {
        next = LivePlaybackState.paused;
      } else if (snap.isBuffering) {
        next = LivePlaybackState.buffering;
      } else if (!snap.isPlaying) {
        next = LivePlaybackState.paused;
      } else {
        final w = _currentWindowMath();
        next = w.isAtLiveEdge
            ? LivePlaybackState.liveEdge
            : LivePlaybackState.playing;
      }
    } else if (_playerCtrl != null && _playerCtrl!.value.isInitialized) {
      final val = _playerCtrl!.value;
      final atEndOfPlaylist =
          val.isCompleted ||
          (!val.isPlaying &&
              !_manualPaused &&
              val.duration > Duration.zero &&
              val.position >= val.duration - const Duration(milliseconds: 500));
      if (atEndOfPlaylist) {
        next = LivePlaybackState.ended;
        _triggerEndVerification();
      } else if (!val.isPlaying && _manualPaused) {
        next = LivePlaybackState.paused;
      } else if (val.isBuffering) {
        next = LivePlaybackState.buffering;
      } else if (!val.isPlaying) {
        next = LivePlaybackState.paused;
      } else {
        final w = _currentWindowMath();
        next = w.isAtLiveEdge
            ? LivePlaybackState.liveEdge
            : LivePlaybackState.playing;
      }
    } else {
      next = LivePlaybackState.buffering;
    }

    // Avoid redundant 4x/sec full-widget rebuilds when state hasn't changed and
    // no visible time-shift/seekbar UI needs position updates.
    if (next == _playbackState &&
        !_controlsVisible &&
        !_isScrubbing &&
        next == LivePlaybackState.liveEdge) {
      return;
    }
    _safeSetState(() => _playbackState = next);
  }

  void _triggerEndVerification() {
    if (_endCheckInFlight || _isDisposed || !mounted) return;
    _endCheckInFlight = true;
    Future.microtask(() async {
      try {
        if (_dvrTimeline?.ended == true) {
          ref.read(liveRoomProvider(widget.streamId).notifier).markStreamEnded();
        } else {
          await ref
              .read(liveRoomProvider(widget.streamId).notifier)
              .checkStreamStatusForEnd();
        }
      } finally {
        _endCheckInFlight = false;
      }
    });
  }

  void _startDvrTimelineSync() {
    _dvrSyncTimer?.cancel();
    _dvrSyncTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshDvrTimeline(),
    );
  }

  Future<void> _refreshDvrTimeline() async {
    if (!mounted || _isDisposed || _isRefreshingDvrTimeline) return;
    _isRefreshingDvrTimeline = true;
    try {
      final room = ref.read(liveRoomProvider(widget.streamId));
      if (room.phase == LiveStreamPhase.ended || room.phase.isTerminal) {
        _dvrSyncTimer?.cancel();
        return;
      }
      final timeline = await ref
          .read(liveStreamingRepositoryProvider)
          .getDvrTimeline(widget.streamId);
      if (!mounted || _isDisposed || timeline == null) return;

      _safeSetState(() => _dvrTimeline = timeline);

      // Transition watcher UI out of PAUSED/LIVE to Stream Ended when backend
      // DVR origin confirms broadcast stopped (handles missed Socket.IO events).
      if (timeline.ended) {
        _dvrSyncTimer?.cancel();
        ref.read(liveRoomProvider(widget.streamId).notifier).markStreamEnded();
        return;
      }

      // Upgrade seamlessly once from short-window CDN HLS to 30-min DVR origin
      // if user has not manually paused or started seeking yet.
      if (!_usingDvrOrigin &&
          timeline.dvrEnabled &&
          timeline.hasSegments &&
          timeline.masterPlaylistPath.isNotEmpty &&
          !_manualPaused &&
          !_isScrubbing &&
          _playerInitialized) {
        final dvrUrl = MediaUrlResolver.resolve(timeline.masterPlaylistPath);
        if (dvrUrl != null && dvrUrl != _activePlaybackUrl) {
          _usingDvrOrigin = true;
          _activePlaybackUrl = dvrUrl;
          if (kIsWeb) {
            _safeSetState(() => _webHlsUrl = dvrUrl);
          } else {
            unawaited(_swapMobileControllerToUrl(dvrUrl));
          }
        }
      }

      // Check whether a paused mobile viewer drifted older than retained window.
      if (!kIsWeb &&
          _manualPaused &&
          _playerCtrl != null &&
          timeline.hasSegments &&
          timeline.dvrStartOffsetSec > 10) {
        final posSec = _playerCtrl!.value.position.inMilliseconds / 1000.0;
        if (posSec < timeline.dvrStartOffsetSec - 4) {
          _safeSetState(() {
            _dvrExpired = true;
            _playbackState = LivePlaybackState.dvrExpired;
          });
        }
      }
    } finally {
      _isRefreshingDvrTimeline = false;
    }
  }

  void _handlePlaybackError() {
    if (!mounted || _isDisposed || _isPlayerInitializing) return;
    final currentPhase = ref.read(liveRoomProvider(widget.streamId)).phase;
    if (currentPhase.isTerminal || currentPhase == LiveStreamPhase.ended) return;

    final oldCtrl = _playerCtrl;
    _playerCtrl = null;
    _webHlsUrl = null;
    _playerInitialized = false;
    oldCtrl?.dispose().ignore();

    unawaited(() async {
      final ended = await ref
          .read(liveRoomProvider(widget.streamId).notifier)
          .checkStreamStatusForEnd();
      if (ended || !mounted || _isDisposed) return;

      ref
          .read(liveRoomProvider(widget.streamId).notifier)
          .notifyPlayerInterruption();

      final hls = ref.read(liveRoomProvider(widget.streamId)).stream?.hlsUrl;
      if (hls != null && hls.isNotEmpty) {
        _initPlayer(hls);
      }
    }());
  }

  // ── Player Initialization & DVR Swap ───────────────────────────────────────

  Future<void> _initPlayer(
    String hlsUrl, {
    bool force = false,
    bool warmupRetry = false,
  }) async {
    if (!mounted || _isDisposed) return;
    final currentPhase = ref.read(liveRoomProvider(widget.streamId)).phase;
    if (currentPhase == LiveStreamPhase.ended || currentPhase.isTerminal) return;
    if ((_playerInitialized && !force) || _isPlayerInitializing) return;

    final fallbackResolved =
        MediaUrlResolver.resolve(hlsUrl.trim()) ?? hlsUrl.trim();
    if (fallbackResolved.isEmpty) return;

    // Acquire initialization lock immediately before awaiting timeline metadata
    // so concurrent ref.listen updates do not double-fetch or double-init.
    _isPlayerInitializing = true;
    if (!warmupRetry) {
      _playerRetryTimer?.cancel();
    }

    // Query backend DVR origin state: use retained 30-min playlist immediately
    // when available, preserving instant CDN fallback otherwise.
    DvrTimelineSnapshot? timeline;
    final streamDto = ref.read(liveRoomProvider(widget.streamId)).stream;
    if (streamDto?.isDvrEnabled ?? true) {
      try {
        timeline = await ref
            .read(liveStreamingRepositoryProvider)
            .getDvrTimeline(widget.streamId);
      } catch (_) {}
    }
    if (!mounted || _isDisposed) {
      _isPlayerInitializing = false;
      return;
    }

    String resolved = fallbackResolved;
    bool usingDvr = false;
    if (timeline != null &&
        timeline.dvrEnabled &&
        timeline.hasSegments &&
        timeline.masterPlaylistPath.isNotEmpty) {
      final dvrResolved = MediaUrlResolver.resolve(timeline.masterPlaylistPath);
      if (dvrResolved != null && dvrResolved.isNotEmpty) {
        resolved = dvrResolved;
        usingDvr = true;
      }
    }

    _dvrTimeline = timeline ?? _dvrTimeline;
    _usingDvrOrigin = usingDvr;
    _activePlaybackUrl = resolved;

    if (kIsWeb && resolved.toLowerCase().contains('.m3u8')) {
      final oldCtrl = _playerCtrl;
      _playerCtrl = null;
      oldCtrl?.dispose().ignore();
      _safeSetState(() {
        _webHlsUrl = resolved;
        _playerInitialized = true;
        _isPlayerInitializing = false;
        _playerError = false;
        _streamNotYetPublishing = false;
        _dvrExpired = false;
        _initAttemptCount = 0;
      });
      _isPlayerInitializing = false;
      _startDvrTimelineSync();
      return;
    }
    if (force) {
      _initAttemptCount = 0;
      if (mounted) {
        setState(() {
          _playerError = false;
        });
      }
    }

    try {
      while (_initAttemptCount < _maxInitAttempts && mounted) {
        final phaseNow = ref.read(liveRoomProvider(widget.streamId)).phase;
        if (phaseNow == LiveStreamPhase.ended || phaseNow.isTerminal) {
          _isPlayerInitializing = false;
          return;
        }

        _initAttemptCount++;
        if (mounted) {
          setState(() {
            _playerError = false;
          });
        }

        debugPrint(
          '[LiveRoom] Connecting player (attempt $_initAttemptCount/$_maxInitAttempts) to: $resolved',
        );

        VideoPlayerController? testCtrl;
        try {
          final uri = Uri.parse(resolved);
          testCtrl = VideoPlayerController.networkUrl(
            uri,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: false,
              allowBackgroundPlayback: true,
            ),
          );

          await testCtrl.initialize().timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw TimeoutException('Timed out connecting to stream');
            },
          );

          if (testCtrl.value.hasError) {
            throw Exception(
              testCtrl.value.errorDescription ?? 'Controller reported error',
            );
          }

          await testCtrl.setVolume(_mobileMuted ? 0.0 : _mobileVolume);
          if (!_manualPaused) {
            await testCtrl.play();
          }

          if (!mounted) {
            await testCtrl.dispose();
            return;
          }

          final oldCtrl = _playerCtrl;
          _playerCtrl = null;
          oldCtrl?.dispose().ignore();

          final detectedSize = _orientedVideoSize(testCtrl.value);
          setState(() {
            _playerCtrl = testCtrl;
            _playerInitialized = true;
            _playerError = false;
            _isPlayerInitializing = false;
            _dvrExpired = false;
            _initAttemptCount = 0;
            if (detectedSize != null) {
              _sourceVideoSize = detectedSize;
            }
          });

          _attachPlayerListeners(testCtrl);
          _startDvrTimelineSync();
          ref.read(liveRoomProvider(widget.streamId).notifier).notifyPlayerReady();
          debugPrint('[LiveRoom] Connected to live stream successfully!');
          return;
        } catch (attemptErr) {
          final errMsg = attemptErr.toString();
          final is404 = errMsg.contains('404') ||
              errMsg.contains('Response code: 404') ||
              errMsg.contains('InvalidResponseCodeException');
          debugPrint(
            '[LiveRoom] Player attempt $_initAttemptCount failed '
            '(is404=$is404): $attemptErr',
          );
          if (testCtrl != null) {
            try {
              await testCtrl.dispose();
            } catch (_) {}
            testCtrl = null;
          }

          // If more attempts remain, delay before next attempt while HLS stream warms up.
          // Use a longer delay on 404 (Cloudinary HLS not yet available) to reduce
          // BLASTBufferQueue surface churn.
          if (_initAttemptCount < _maxInitAttempts && mounted) {
            final delayMs = is404 ? 4000 : 2500;
            await Future<void>.delayed(Duration(milliseconds: delayMs));
          }
        }
      }

      // All attempts exhausted.
      debugPrint(
        '[LiveRoom] All $_maxInitAttempts connection attempts failed for: $resolved',
      );
      if (!mounted) return;

      // Re-check the current phase: if the backend still reports the stream as
      // LIVE but Cloudinary returned 404 on every attempt, the broadcaster has
      // not yet started pushing video (or just started and HLS isn't warm yet).
      // Show a friendly "Waiting for broadcast to begin" screen rather than
      // crashing the ExoPlayer surface in a tight loop.
      final phaseAfterFail = ref.read(liveRoomProvider(widget.streamId)).phase;
      if (phaseAfterFail == LiveStreamPhase.live ||
          phaseAfterFail == LiveStreamPhase.starting) {
        debugPrint(
          '[LiveRoom] Stream is LIVE in DB but HLS is not yet available — '
          'showing "waiting for broadcast" standby screen.',
        );
        setState(() {
          _streamNotYetPublishing = true;
          _playerError = false;
          _isPlayerInitializing = false;
          _initAttemptCount = 0;
        });

        if (!warmupRetry) {
          _scheduleWarmupRetry();
        }
      } else {
        setState(() {
          _playerError = true;
          _streamNotYetPublishing = false;
          _isPlayerInitializing = false;
        });
        ref.read(liveRoomProvider(widget.streamId).notifier).notifyPlayerInterruption();
      }
    } catch (e) {
      debugPrint('[LiveRoom] Unexpected error in _initPlayer: $e');
      if (mounted) {
        setState(() {
          _playerError = true;
          _streamNotYetPublishing = false;
          _isPlayerInitializing = false;
        });
        ref.read(liveRoomProvider(widget.streamId).notifier).notifyPlayerInterruption();
      }
    }
  }

  void _scheduleWarmupRetry() {
    if (_playerRetryTimer != null && _playerRetryTimer!.isActive) return;
    _playerRetryTimer = Timer.periodic(const Duration(seconds: 10), (t) {
      if (!mounted || _playerInitialized) {
        t.cancel();
        return;
      }
      final phase = ref.read(liveRoomProvider(widget.streamId)).phase;
      if (phase.isTerminal || phase == LiveStreamPhase.ended) {
        t.cancel();
        return;
      }
      if (_isPlayerInitializing) return;
      ref.read(liveRoomProvider(widget.streamId).notifier).refresh();
      final hls = ref.read(liveRoomProvider(widget.streamId)).stream?.hlsUrl;
      if (hls != null && hls.isNotEmpty && mounted) {
        setState(() => _streamNotYetPublishing = false);
        _initPlayer(hls, force: true, warmupRetry: true);
      }
    });
  }

  // ── Seamless Mobile Controller Swap & DVR Transport Actions ───────────────

  Future<void> _swapMobileControllerToUrl(
    String nextUrl, {
    Duration? seekAfterInit,
  }) async {
    if (kIsWeb || _isSwappingController || nextUrl.isEmpty) return;
    _isSwappingController = true;
    _syncPlaybackState();

    VideoPlayerController? nextCtrl;
    try {
      nextCtrl = VideoPlayerController.networkUrl(
        Uri.parse(nextUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: true,
        ),
      );
      await nextCtrl.initialize().timeout(const Duration(seconds: 8));
      await nextCtrl.setVolume(_mobileMuted ? 0.0 : _mobileVolume);

      if (seekAfterInit != null) {
        final dur = nextCtrl.value.duration;
        final clamped = seekAfterInit > dur ? dur : seekAfterInit;
        if (clamped >= Duration.zero) {
          await nextCtrl.seekTo(clamped);
        }
      }
      if (!_manualPaused) {
        await nextCtrl.play();
      }
      if (!mounted) {
        await nextCtrl.dispose();
        return;
      }

      final oldCtrl = _playerCtrl;
      final sz = _orientedVideoSize(nextCtrl.value);
      setState(() {
        _playerCtrl = nextCtrl;
        _playerInitialized = true;
        _dvrExpired = false;
        _isSwappingController = false;
        if (sz != null) {
          _sourceVideoSize = sz;
        }
      });
      _attachPlayerListeners(nextCtrl);
      oldCtrl?.dispose().ignore();
    } catch (e) {
      debugPrint('[LiveRoom] Controller swap skipped ($e)');
      await nextCtrl?.dispose();
      if (mounted) {
        setState(() => _isSwappingController = false);
      }
    }
    _syncPlaybackState();
  }

  Future<void> _togglePlayPause() async {
    _revealControls();
    if (kIsWeb && _webHlsUrl != null) {
      final playing = _webHlsCtrl.value.isPlaying;
      _manualPaused = playing;
      if (playing) {
        _webHlsCtrl.pause();
      } else {
        await _webHlsCtrl.play();
      }
      _syncPlaybackState();
      return;
    }

    final ctrl = _playerCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (ctrl.value.isPlaying) {
      _manualPaused = true;
      await ctrl.pause();
    } else {
      _manualPaused = false;
      await ctrl.play();
    }
    _syncPlaybackState();
  }

  Future<void> _seekTo(
    Duration target, {
    LivePlaybackState? transientState,
  }) async {
    _revealControls();
    final window = _currentWindowMath();
    final clamped = target < window.windowStart
        ? window.windowStart
        : (target > window.windowEnd ? window.windowEnd : target);

    _lastSeekAt = DateTime.now();
    _transientSeekState = transientState ?? LivePlaybackState.seeking;
    _dvrExpired = false;
    _syncPlaybackState();

    if (kIsWeb && _webHlsUrl != null) {
      _webHlsCtrl.seekTo(clamped);
      return;
    }

    final ctrl = _playerCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    // Work around video_player's Dart-side clamp (`position > value.duration`)
    // when ExoPlayer/AVPlayer was initialized early in a growing live window.
    if (clamped <= ctrl.value.duration) {
      await ctrl.seekTo(clamped);
      if (!_manualPaused && !ctrl.value.isPlaying) {
        await ctrl.play();
      }
    } else if (_activePlaybackUrl != null) {
      await _swapMobileControllerToUrl(
        _activePlaybackUrl!,
        seekAfterInit: clamped,
      );
    }
    _syncPlaybackState();
  }

  Future<void> _rewind10() async {
    final w = _currentWindowMath();
    await _seekTo(
      w.currentPosition - const Duration(seconds: 10),
      transientState: LivePlaybackState.rewinding,
    );
  }

  Future<void> _forward10() async {
    final w = _currentWindowMath();
    await _seekTo(
      w.currentPosition + const Duration(seconds: 10),
      transientState: LivePlaybackState.fastForwarding,
    );
  }

  Future<void> _goLive() async {
    _revealControls();
    _manualPaused = false;
    _dvrExpired = false;
    _lastSeekAt = DateTime.now();
    _transientSeekState = LivePlaybackState.fastForwarding;
    _syncPlaybackState();

    if (kIsWeb && _webHlsUrl != null) {
      _webHlsCtrl.seekToLiveEdge();
      return;
    }

    final ctrl = _playerCtrl;
    final w = _currentWindowMath();
    if (ctrl != null &&
        ctrl.value.isInitialized &&
        w.windowEnd <= ctrl.value.duration) {
      final liveTarget = w.windowEnd > const Duration(seconds: 6)
          ? w.windowEnd - const Duration(seconds: 6)
          : Duration.zero;
      await ctrl.seekTo(liveTarget);
      await ctrl.play();
      _syncPlaybackState();
    } else if (_activePlaybackUrl != null) {
      await _swapMobileControllerToUrl(_activePlaybackUrl!);
    }
  }

  void _toggleFitMode() {
    _revealControls();
    final next =
        _fitMode == VideoFitMode.fit ? VideoFitMode.fill : VideoFitMode.fit;
    setState(() => _fitMode = next);
    if (kIsWeb && _webHlsUrl != null) {
      _webHlsCtrl.setFitMode(next);
    }
  }

  void _toggleMute() {
    _revealControls();
    if (kIsWeb && _webHlsUrl != null) {
      final nextMuted = !_webHlsCtrl.value.isMuted;
      _webHlsCtrl.setMuted(nextMuted);
      return;
    }
    _mobileMuted = !_mobileMuted;
    _playerCtrl?.setVolume(_mobileMuted ? 0.0 : _mobileVolume);
    setState(() {});
  }

  void _setVolume(double vol) {
    _revealControls();
    if (kIsWeb && _webHlsUrl != null) {
      _webHlsCtrl.setVolume(vol);
      return;
    }
    _mobileVolume = vol.clamp(0.0, 1.0);
    _mobileMuted = _mobileVolume == 0.0;
    _playerCtrl?.setVolume(_mobileVolume);
    setState(() {});
  }

  Future<void> _selectQuality(int levelIndex) async {
    _revealControls();
    setState(() => _selectedQualityIndex = levelIndex);
    if (kIsWeb && _webHlsUrl != null) {
      _webHlsCtrl.setQualityLevel(levelIndex);
      return;
    }

    final timeline = _dvrTimeline;
    if (timeline == null || !timeline.hasSegments) return;
    String? nextRelativePath;
    if (levelIndex == -1) {
      nextRelativePath = timeline.masterPlaylistPath;
    } else {
      final match = timeline.variants.where((v) => v.id == levelIndex);
      if (match.isNotEmpty) {
        nextRelativePath = match.first.playlistPath;
      }
    }
    final nextUrl = MediaUrlResolver.resolve(nextRelativePath);
    if (nextUrl != null && nextUrl.isNotEmpty) {
      final w = _currentWindowMath();
      _activePlaybackUrl = nextUrl;
      await _swapMobileControllerToUrl(
        nextUrl,
        seekAfterInit: w.isAtLiveEdge ? null : w.currentPosition,
      );
    }
  }

  void _openCastSheet(LiveRoomState state) {
    final stream = state.stream;
    if (stream == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CastPanelWidget(
        streamId: widget.streamId,
        hlsUrl: _activePlaybackUrl ?? stream.hlsUrl,
        streamTitle: stream.title,
        thumbnailUrl: stream.thumbnailUrl,
      ),
    );
  }

  // ── Controls visibility ────────────────────────────────────────────────────

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (_manualPaused || _isScrubbing || _playbackState == LivePlaybackState.dvrExpired) {
      return;
    }
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_manualPaused && !_isScrubbing) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _revealControls() {
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _scheduleHideControls();
  }

  void _onTapPlayer() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _scheduleHideControls();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  // ── Mini-player minimise ────────────────────────────────────────────────

  void _minimizeToMiniPlayer(LiveRoomState roomState) {
    _dvrSyncTimer?.cancel();
    final stream = roomState.stream;
    final hlsUrl = stream?.hlsUrl ?? '';

    if (roomState.phase == LiveStreamPhase.ended) {
      ref.read(miniPlayerProvider.notifier).showLive(
        streamId: widget.streamId,
        title: stream?.title ?? 'Live Stream',
        channelName:
            stream?.videoChannel?.name ?? stream?.createdBy?.username,
        thumbnailUrl: stream?.thumbnailUrl,
        avatarUrl:
            stream?.videoChannel?.avatarUrl ?? stream?.createdBy?.avatarUrl,
        hlsUrl: hlsUrl,
        controller: null,
      );
      ref.read(miniPlayerProvider.notifier).markEnded(
        durationSeconds: stream?.duration,
      );
      WakelockPlus.disable().ignore();
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
      return;
    }

    final ctrl = _playerCtrl;
    _playerCtrl =
        null; // transfer ownership — prevents dispose() from killing it
    _playerInitialized = false;

    final wasPlaying = ctrl?.value.isPlaying ?? true;
    ref
        .read(miniPlayerProvider.notifier)
        .showLive(
          streamId: widget.streamId,
          title: stream?.title ?? 'Live Stream',
          channelName:
              stream?.videoChannel?.name ?? stream?.createdBy?.username,
          thumbnailUrl: stream?.thumbnailUrl,
          avatarUrl:
              stream?.videoChannel?.avatarUrl ?? stream?.createdBy?.avatarUrl,
          hlsUrl: hlsUrl,
          controller: ctrl,
          wasPlaying: wasPlaying,
        );

    WakelockPlus.disable().ignore();
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  // ── Fullscreen ─────────────────────────────────────────────────────────────

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      final isPortraitSource = _sourceVideoSize != null &&
          _sourceVideoSize!.height > _sourceVideoSize!.width;
      if (!kIsWeb) {
        SystemChrome.setPreferredOrientations(
          isPortraitSource
              ? [DeviceOrientation.portraitUp]
              : [
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ],
        );
      }
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (!kIsWeb) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
    _revealControls();
  }

  // ── Reactions ──────────────────────────────────────────────────────────────



  void _onReactionReceived(ReactionBroadcastEvent event) {
    if (!mounted) return;
    _spawnParticles(event.emoji, min(event.count, 4));
  }

  void _spawnParticles(String emoji, int count) {
    for (int i = 0; i < count; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      );
      final particle = _Particle(
        emoji: emoji,
        xPos: 0.1 + _rng.nextDouble() * 0.8,
        ctrl: ctrl,
      );
      _safeSetState(() => _particles.add(particle));
      ctrl.forward().then((_) {
        if (mounted && !_isDisposed) {
          setState(() => _particles.remove(particle));
          ctrl.dispose();
        }
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(liveRoomProvider(widget.streamId));
    final theme = Theme.of(context);

    // Listen to stream lifecycle phase changes
    ref.listen<LiveRoomState>(liveRoomProvider(widget.streamId), (previous, next) {
      _checkCreatorRedirect(next);
      if (next.phase == LiveStreamPhase.ended) {
        _playerRetryTimer?.cancel();
        _dvrSyncTimer?.cancel();
        _playerCtrl?.pause();
        if (_webHlsUrl != null ||
            _playerInitialized ||
            _playbackState != LivePlaybackState.ended) {
          _safeSetState(() {
            _webHlsUrl = null;
            _playerInitialized = false;
            _isPlayerInitializing = false;
            _playbackState = LivePlaybackState.ended;
            _controlsVisible = false;
          });
        }
      }
      final hls = next.stream?.hlsUrl;
      if ((next.phase == LiveStreamPhase.live ||
              next.phase == LiveStreamPhase.starting ||
              next.phase == LiveStreamPhase.reconnecting) &&
          hls != null &&
          hls.isNotEmpty &&
          !_playerInitialized &&
          !_isPlayerInitializing) {
        // Reset the warmup state when the phase changes so the player
        // tries again immediately rather than waiting for the timer.
        if (_streamNotYetPublishing) {
          setState(() => _streamNotYetPublishing = false);
        }
        _initPlayer(hls);
      }

      // Media-session policy: suspend App Lock inactivity timer while the
      // viewer is actively watching (live or starting). Restore the countdown
      // on terminal / error / interrupted states so a failed stream cannot
      // hold the timer suspended indefinitely.
      final isActivePhase =
          next.phase == LiveStreamPhase.live ||
          next.phase == LiveStreamPhase.starting;
      final wasActivePhase =
          previous?.phase == LiveStreamPhase.live ||
          previous?.phase == LiveStreamPhase.starting;

      if (isActivePhase && !wasActivePhase) {
        ref.read(mediaActivityProvider.notifier).startSession(
          _mediaSessionId,
          MediaSessionKind.liveViewer,
        );
      } else if (!isActivePhase && wasActivePhase) {
        ref.read(mediaActivityProvider.notifier).endSession(_mediaSessionId);
      }
    });

    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final screenW = media.size.width;
    // Breakpoint by viewport width (not kIsWeb) so narrow mobile browsers get vertical layout.
    final isWideScreen = screenW >= 900;
    final isLandscapeMobile = !isWideScreen && isLandscape;
    final pad = media.padding;
    final canDragMinimize = !_isFullscreen && !isWideScreen && !isLandscapeMobile;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_isFullscreen) {
            _toggleFullscreen();
          } else {
            _minimizeToMiniPlayer(roomState);
          }
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: canDragMinimize
            ? (_) => _safeSetState(() {
                _isDragging = true;
                _dragOffset = 0;
              })
            : null,
        onVerticalDragUpdate: canDragMinimize
            ? (details) {
                if (!_isDragging) return;
                final next = _dragOffset + details.delta.dy;
                _safeSetState(() => _dragOffset = next < 0 ? 0 : next);
              }
            : null,
        onVerticalDragEnd: canDragMinimize
            ? (details) {
                final velocity = details.primaryVelocity ?? 0.0;
                if (_dragOffset > _kMiniDragThreshold ||
                    (velocity > 250 && _dragOffset > 20)) {
                  _minimizeToMiniPlayer(roomState);
                }
                _safeSetState(() {
                  _isDragging = false;
                  _dragOffset = 0;
                });
              }
            : null,
        child: Transform.translate(
          offset: Offset(
            0,
            (canDragMinimize && _isDragging) ? _dragOffset.clamp(0.0, 300.0) : 0,
          ),
          child: Scaffold(
            backgroundColor: (_isFullscreen || isLandscapeMobile)
                ? Colors.black
                : theme.colorScheme.surface,
            body: roomState.isLoading
                ? SafeArea(child: _buildLoading())
                : roomState.error != null
                ? SafeArea(child: _buildError(roomState.error!, theme))
                : LayoutBuilder(
                    builder: (context, outer) {
                      final totalW = outer.maxWidth;
                      final totalH = outer.maxHeight;
                      final safeTop = _isFullscreen ? 0.0 : pad.top;
                      final safeLeft = _isFullscreen ? 0.0 : pad.left;
                      final safeRight = _isFullscreen ? 0.0 : pad.right;
                      final safeBottom = _isFullscreen ? 0.0 : pad.bottom;
                      final usableW =
                          (totalW - safeLeft - safeRight).clamp(120.0, totalW);
                      final usableH =
                          (totalH - safeTop - safeBottom).clamp(120.0, totalH);

                      late final double playerLeft;
                      late final double playerTop;
                      late final double playerW;
                      late final double playerH;
                      late final double wideChatW;

                      if (_isFullscreen) {
                        playerLeft = 0;
                        playerTop = 0;
                        playerW = totalW;
                        playerH = totalH;
                        wideChatW = 0;
                      } else if (isWideScreen) {
                        wideChatW = (usableW * 0.28).clamp(320.0, 400.0);
                        final colW = usableW - wideChatW;
                        final maxStageH =
                            (usableH - 88.0).clamp(260.0, usableH);
                        final frame = computeResponsiveVideoFrame(
                          maxWidth: colW,
                          maxHeight: maxStageH,
                          sourceVideoSize: _sourceVideoSize,
                          isWideScreen: true,
                          isFullscreen: false,
                        );
                        playerLeft = safeLeft;
                        playerTop = safeTop;
                        playerW = colW;
                        playerH = frame.stageHeight;
                      } else if (isLandscapeMobile) {
                        wideChatW = usableW * 0.4;
                        playerLeft = safeLeft;
                        playerTop = safeTop;
                        playerW = usableW - wideChatW;
                        playerH = usableH;
                      } else {
                        wideChatW = 0;
                        final maxVideoH = _isChatExpanded
                            ? usableH * 0.56
                            : usableH * 0.80;
                        final frame = computeResponsiveVideoFrame(
                          maxWidth: usableW,
                          maxHeight: maxVideoH,
                          sourceVideoSize: _sourceVideoSize,
                          isWideScreen: false,
                          isFullscreen: false,
                        );
                        playerLeft = safeLeft;
                        playerTop = safeTop;
                        playerW = usableW;
                        playerH = frame.stageHeight;
                      }

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!_isFullscreen && isWideScreen) ...[
                            Positioned(
                              left: safeLeft,
                              top: safeTop + playerH,
                              width: playerW,
                              bottom: safeBottom,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: _buildStreamMeta(roomState, theme),
                              ),
                            ),
                            Positioned(
                              left: safeLeft + playerW,
                              top: safeTop,
                              width: wideChatW,
                              bottom: safeBottom,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildDelayedChatNotice(roomState, theme),
                                    Expanded(
                                      child: roomState.stream?.isChatEnabled !=
                                              false
                                          ? LiveChatWidget(
                                              streamId: widget.streamId,
                                            )
                                          : Center(
                                              child: Text(
                                                'Chat is disabled',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else if (!_isFullscreen && isLandscapeMobile) ...[
                            Positioned(
                              left: safeLeft + playerW,
                              top: safeTop,
                              width: wideChatW,
                              bottom: safeBottom,
                              child: Column(
                                children: [
                                  _buildDelayedChatNotice(
                                    roomState,
                                    theme,
                                    dark: true,
                                  ),
                                  Expanded(
                                    child: roomState.stream?.isChatEnabled !=
                                            false
                                        ? LiveChatWidget(
                                            streamId: widget.streamId,
                                          )
                                        : Center(
                                            child: Text(
                                              ref.read(trProvider)(
                                                'live.chat_disabled_short',
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (!_isFullscreen) ...[
                            Positioned(
                              left: safeLeft,
                              top: safeTop + playerH,
                              right: safeRight,
                              bottom: safeBottom,
                              child: Column(
                                children: [
                                  _buildStreamMeta(
                                    roomState,
                                    theme,
                                    showChatToggle:
                                        roomState.stream?.isChatEnabled !=
                                            false,
                                  ),
                                  if (_isChatExpanded) ...[
                                    _buildDelayedChatNotice(roomState, theme),
                                    Expanded(
                                      child: roomState.stream?.isChatEnabled !=
                                              false
                                          ? LiveChatWidget(
                                              streamId: widget.streamId,
                                            )
                                          : Center(
                                              child: Text(
                                                ref.read(trProvider)(
                                                  'live.chat_disabled',
                                                ),
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ] else
                                    const Spacer(),
                                ],
                              ),
                            ),
                          ],

                          // Single persistent player slot: never unmounts/reloads
                          // WebHlsPlayer or VideoPlayer across fullscreen/resize.
                          Positioned(
                            key: _playerStageKey,
                            left: playerLeft,
                            top: playerTop,
                            width: playerW,
                            height: playerH,
                            child: _buildPlayerStage(
                              roomState,
                              isWideScreen: isWideScreen || isLandscapeMobile,
                              isFullscreen: _isFullscreen,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDelayedChatNotice(
    LiveRoomState state,
    ThemeData theme, {
    bool dark = false,
  }) {
    if (state.phase != LiveStreamPhase.live || !_isDvrAvailable) {
      return const SizedBox.shrink();
    }
    final w = _currentWindowMath();
    if (w.isAtLiveEdge && _playbackState != LivePlaybackState.paused) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: dark
          ? Colors.white.withValues(alpha: 0.08)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: dark ? Colors.amberAccent : theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Chat is real-time · Video is ${w.formattedBehindLive}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: _goLive,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Go Live',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Adaptive Player Stage + Controls + DVR Bar ─────────────────────

  List<VideoQualityOption> _availableQualities() {
    if (kIsWeb && _webHlsUrl != null) {
      return _webHlsCtrl.value.qualities;
    }
    final variants = _dvrTimeline?.variants ?? const [];
    if (variants.length <= 1) return const [VideoQualityOption.auto];
    return [
      VideoQualityOption.auto,
      ...variants.map(
        (v) => VideoQualityOption(
          index: v.id,
          label: v.label,
          bitrate: v.bandwidth,
          width: v.width,
          height: v.height,
        ),
      ),
    ];
  }

  Widget _buildPlayerStage(
    LiveRoomState state, {
    required bool isWideScreen,
    bool isFullscreen = false,
  }) {
    final window = _currentWindowMath();
    final dvrActive = _isDvrAvailable && state.phase == LiveStreamPhase.live;
    final qualities = _availableQualities();
    final activeQualityIdx = kIsWeb && _webHlsUrl != null
        ? _webHlsCtrl.value.currentQualityIndex
        : _selectedQualityIndex;
    final volume = kIsWeb && _webHlsUrl != null
        ? _webHlsCtrl.value.volume
        : _mobileVolume;
    final muted = kIsWeb && _webHlsUrl != null
        ? _webHlsCtrl.value.isMuted
        : _mobileMuted;

    final showRichControls =
        state.phase != LiveStreamPhase.ended &&
        !state.phase.isTerminal &&
        (state.phase == LiveStreamPhase.live ||
            state.phase == LiveStreamPhase.starting ||
            _playerInitialized);

    return MouseRegion(
      onHover: (_) => _revealControls(),
      onEnter: (_) => _revealControls(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTapPlayer,
            onDoubleTapDown: dvrActive
                ? (details) {
                    final dx = details.localPosition.dx;
                    if (dx < constraints.maxWidth * 0.38) {
                      unawaited(_rewind10());
                    } else if (dx > constraints.maxWidth * 0.62) {
                      unawaited(_forward10());
                    } else {
                      unawaited(_togglePlayPause());
                    }
                  }
                : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full-width black video stage (crop-to-fill wraps active video only)
                ColoredBox(
                  color: Colors.black,
                  child: ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox.expand(
                      child: _buildPlayerContent(state),
                    ),
                  ),
                ),

                // Professional YouTube-style overlay or lightweight phase header
                if (showRichControls)
                  LivePlayerControlsOverlay(
                    streamTitle: state.stream?.title ?? 'Live Stream',
                    playbackState: _playbackState,
                    window: window,
                    visible: _controlsVisible,
                    isFullscreen: isFullscreen,
                    dvrEnabled: dvrActive,
                    viewerCount: state.viewerCount,
                    fitMode: _fitMode,
                    volume: volume,
                    isMuted: muted,
                    qualities: qualities,
                    currentQualityIndex: activeQualityIdx,
                    showVolumeSlider: isWideScreen || isFullscreen,
                    onMinimize: () {
                      if (_isFullscreen) _toggleFullscreen();
                      _minimizeToMiniPlayer(state);
                    },
                    onTogglePlayPause: () => unawaited(_togglePlayPause()),
                    onRewind10: () => unawaited(_rewind10()),
                    onForward10: () => unawaited(_forward10()),
                    onSeek: (target) => unawaited(_seekTo(target)),
                    onGoLive: () => unawaited(_goLive()),
                    onToggleFullscreen: _toggleFullscreen,
                    onToggleFitMode: _toggleFitMode,
                    onToggleMute: _toggleMute,
                    onVolumeChanged: _setVolume,
                    onQualitySelected: (idx) => unawaited(_selectQuality(idx)),
                    onOpenCast: state.stream?.hlsUrl != null
                        ? () => _openCastSheet(state)
                        : null,
                    onInteraction: () {
                      _isScrubbing = false;
                      _scheduleHideControls();
                    },
                  )
                else if (state.phase != LiveStreamPhase.ended &&
                    !state.phase.isTerminal)
                  AnimatedOpacity(
                    opacity: _controlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: _buildControls(state),
                  ),

                // Floating reactions
                _buildParticleLayer(),

                // Reconnect banner
                if (state.phase == LiveStreamPhase.reconnecting ||
                    state.connectionState == SocketConnectionState.reconnecting)
                  _buildReconnectBanner(state),

                // Subtle persistent hairline bar while controls are auto-hidden
                if (state.phase == LiveStreamPhase.live && !_controlsVisible)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: dvrActive
                          ? DvrSeekBar(
                              window: window,
                              enabled: false,
                              compact: true,
                              onSeek: (_) {},
                              onGoLive: () {},
                            )
                          : LiveStreamProgressBar(
                              startedAt: state.stream?.startedAt,
                            ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveVideoSurface() {
    if (kIsWeb && _webHlsUrl != null) {
      return ResponsiveVideoStage(
        sourceVideoSize: _sourceVideoSize,
        fitMode: _fitMode,
        showAmbientBackdrop: false,
        child: WebHlsPlayer(
          key: _webPlayerKey,
          url: _webHlsUrl!,
          controller: _webHlsCtrl,
          fitMode: _fitMode,
          onVideoSizeChanged: (sz) {
            if (!mounted || _isDisposed || sz.isEmpty || sz == _sourceVideoSize) {
              return;
            }
            _safeSetState(() => _sourceVideoSize = sz);
          },
          onReady: () {
            if (!mounted || _isDisposed) return;
            _safeSetState(() {
              _playerError = false;
              _streamNotYetPublishing = false;
              _dvrExpired = false;
            });
            ref
                .read(liveRoomProvider(widget.streamId).notifier)
                .notifyPlayerReady();
            _syncPlaybackState();
          },
          onStreamEnded: () {
            if (!mounted || _isDisposed) return;
            ref.read(liveRoomProvider(widget.streamId).notifier).markStreamEnded();
          },
          onWaitingForStream: () {
            if (!mounted || _isDisposed) return;
            unawaited(() async {
              final ended = await ref
                  .read(liveRoomProvider(widget.streamId).notifier)
                  .checkStreamStatusForEnd();
              if (ended || !mounted || _isDisposed) return;
              _safeSetState(() {
                _playerInitialized = false;
                _webHlsUrl = null;
                _streamNotYetPublishing = true;
                _playerError = false;
              });
              _scheduleWarmupRetry();
            }());
          },
          onDvrExpired: () {
            if (!mounted || _isDisposed) return;
            _safeSetState(() {
              _dvrExpired = true;
              _playbackState = LivePlaybackState.dvrExpired;
              _controlsVisible = true;
            });
          },
          onFatalError: (err) {
            debugPrint('[LiveRoom][WebHLS] fatal error: $err');
            if (!mounted || _isDisposed) return;
            unawaited(() async {
              final ended = await ref
                  .read(liveRoomProvider(widget.streamId).notifier)
                  .checkStreamStatusForEnd();
              if (ended || !mounted || _isDisposed) return;
              final phaseNow = ref.read(liveRoomProvider(widget.streamId)).phase;
              if (phaseNow == LiveStreamPhase.live ||
                  phaseNow == LiveStreamPhase.starting) {
                _safeSetState(() {
                  _playerInitialized = false;
                  _webHlsUrl = null;
                  _streamNotYetPublishing = true;
                  _playerError = false;
                });
                _scheduleWarmupRetry();
              } else {
                _safeSetState(() {
                  _playerInitialized = false;
                  _webHlsUrl = null;
                  _playerError = true;
                });
                ref
                    .read(liveRoomProvider(widget.streamId).notifier)
                    .notifyPlayerInterruption();
              }
            }());
          },
        ),
      );
    }
    if (_playerCtrl != null) {
      return ResponsiveVideoStage(
        sourceVideoSize: _sourceVideoSize ?? _orientedVideoSize(_playerCtrl!.value),
        fitMode: _fitMode,
        showAmbientBackdrop: false,
        child: VideoPlayer(_playerCtrl!),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPlayerContent(LiveRoomState state) {
    final hasActivePlayer =
        _playerInitialized && (_playerCtrl != null || (kIsWeb && _webHlsUrl != null));
    switch (state.phase) {
      case LiveStreamPhase.loading:
        return _buildBuffering();
      case LiveStreamPhase.scheduled:
        return _buildStreamScheduled(state);
      case LiveStreamPhase.starting:
        if (hasActivePlayer) {
          return _buildActiveVideoSurface();
        } else if (_isPlayerInitializing) {
          return _buildBuffering();
        } else if (_streamNotYetPublishing) {
          return _buildWaitingForBroadcast();
        } else {
          return _buildStreamStarting(state);
        }
      case LiveStreamPhase.live:
        if (hasActivePlayer) {
          return _buildActiveVideoSurface();
        } else if (_streamNotYetPublishing) {
          return _buildWaitingForBroadcast();
        } else if (_playerError) {
          return _buildPlayerError();
        } else {
          return _buildBuffering();
        }
      case LiveStreamPhase.interrupted:
        return _buildInterrupted(state);
      case LiveStreamPhase.reconnecting:
        return _buildReconnecting(state);
      case LiveStreamPhase.ended:
        return _buildStreamEnded(state);
      case LiveStreamPhase.error:
        if (_streamNotYetPublishing) return _buildWaitingForBroadcast();
        return _playerError ? _buildPlayerError() : _buildBuffering();
    }
  }

  Widget _buildControls(LiveRoomState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.35, 0.65, 1],
          colors: [
            Color(0xCC000000),
            Colors.transparent,
            Colors.transparent,
            Color(0xAA000000),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              IconButton(
                tooltip: 'Minimize',
                onPressed: () {
                  if (_isFullscreen) _toggleFullscreen();
                  // Minimize to mini player instead of hard-popping.
                  _minimizeToMiniPlayer(state);
                },
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: Colors.white),
              ),
              _buildPhaseBadge(state),
              if (state.phase == LiveStreamPhase.live) ...[
                const SizedBox(width: 6),
                ViewerCountWidget(count: state.viewerCount, light: true),
              ],
              const Spacer(),
              IconButton(
                onPressed: _toggleFullscreen,
                icon: Icon(
                  _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Bottom: stream title + volume
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.stream?.title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_playerInitialized && _playerCtrl != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final v = _playerCtrl?.value.volume ?? 1.0;
                      _playerCtrl?.setVolume(v > 0 ? 0.0 : 1.0);
                      setState(() {});
                    },
                    child: Icon(
                      (_playerCtrl?.value.volume ?? 1.0) > 0
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseBadge(LiveRoomState state) {
    switch (state.phase) {
      case LiveStreamPhase.live:
        return LiveBadgeWidget(
          small: true,
          startedAt: state.stream?.startedAt,
        );
      case LiveStreamPhase.scheduled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 10, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'SCHEDULED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case LiveStreamPhase.interrupted:
      case LiveStreamPhase.reconnecting:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.amber.shade800,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_problem_rounded, size: 10, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'RECONNECTING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case LiveStreamPhase.ended:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stop_circle_outlined, size: 10, color: Colors.white70),
              SizedBox(width: 4),
              Text(
                'ENDED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildParticleLayer() {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            children: _particles.map((p) {
              return Positioned(
                left: p.xPos * w - 18,
                bottom: 24,
                child: AnimatedBuilder(
                  animation: p.ctrl,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, p.y.value),
                    child: Opacity(
                      opacity: p.opacity.value.clamp(0.0, 1.0),
                      child: Text(
                        p.emoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildStreamStarting(LiveRoomState state) {
    final tr = ref.read(trProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tr('live.broadcast_badge'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              state.stream?.title ?? 'Live Stream',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tr('live.preparing'),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamScheduled(LiveRoomState state) {
    final stream = state.stream;
    final scheduledDate = stream?.scheduledAt != null
        ? DateTime.tryParse(stream!.scheduledAt!)
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (stream?.thumbnailUrl != null)
          AppNetworkImage(
            imageUrl: stream!.thumbnailUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        Container(
          color: Colors.black.withValues(alpha: 0.82),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'SCHEDULED LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  stream?.title ?? 'Live Stream',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (scheduledDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${EthiopianCalendar.formatDateAm(scheduledDate)} • ${EthiopianCalendar.formatTimeAm(scheduledDate)}',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'The broadcast will begin once the host goes live.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuffering([String? customMessage]) {
    final tr = ref.read(trProvider);
    final String message;
    if (customMessage != null) {
      message = customMessage;
    } else if (_initAttemptCount > 1) {
      message = '${tr('live.connecting')} ($_initAttemptCount/$_maxInitAttempts)...';
    } else {
      message = tr('live.connecting');
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerError() {
    final tr = ref.read(trProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          Text(
            tr('live.load_stream_failed'),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _playerError = false;
                _playerInitialized = false;
                _webHlsUrl = null;
                _isPlayerInitializing = false;
                _initAttemptCount = 0;
              });
              final stream = ref.read(liveRoomProvider(widget.streamId)).stream;
              if (stream?.hlsUrl != null && stream!.hlsUrl!.isNotEmpty) {
                _initPlayer(stream.hlsUrl!, force: true);
              }
              ref.read(liveRoomProvider(widget.streamId).notifier).refresh();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
            ),
            child: Text(tr('common.retry')),
          ),
        ],
      ),
    );
  }

  /// Shown when the backend confirms the stream is LIVE but Cloudinary's HLS
  /// manifest returns HTTP 404 — the broadcaster has not yet begun publishing
  /// video to the ingest endpoint.  Auto-retries via `_playerRetryTimer`.
  Widget _buildWaitingForBroadcast() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Broadcaster is getting ready…',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The live stream will begin shortly.\nThis screen refreshes automatically.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                _playerRetryTimer?.cancel();
                setState(() {
                  _streamNotYetPublishing = false;
                  _webHlsUrl = null;
                  _initAttemptCount = 0;
                });
                final hls =
                    ref.read(liveRoomProvider(widget.streamId)).stream?.hlsUrl;
                if (hls != null && hls.isNotEmpty) {
                  _initPlayer(hls, force: true);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterrupted(LiveRoomState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 40),
            const SizedBox(height: 10),
            const Text(
              'Stream Interrupted',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Broadcaster connection temporarily lost. Waiting for stream to resume...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconnecting(LiveRoomState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 12),
            Text(
              'Reconnecting to stream...${state.retryCount > 0 ? ' (Attempt ${state.retryCount})' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Checking stream status with server...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamEnded(LiveRoomState state) {
    final tr = ref.read(trProvider);
    final stream = state.stream;
    final channelName = stream?.videoChannel?.name ??
        stream?.createdBy?.username ??
        'Broadcaster';
    final avatarUrl = stream?.videoChannel?.avatarUrl ??
        stream?.createdBy?.avatarUrl;
    final durationSeconds = stream?.duration;

    String? durationFormatted;
    if (durationSeconds != null && durationSeconds > 0) {
      final hours = durationSeconds ~/ 3600;
      final minutes = (durationSeconds % 3600) ~/ 60;
      if (hours > 0) {
        durationFormatted = '${hours}h ${minutes}m';
      } else {
        durationFormatted = '${minutes}m';
      }
    }

    final vodUrl = state.vodUrl;
    final hasVod = vodUrl != null && vodUrl.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail backdrop with dark tint
        if (stream?.thumbnailUrl != null)
          AppNetworkImage(
            imageUrl: stream!.thumbnailUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        Container(
          color: Colors.black.withValues(alpha: 0.85),
        ),

        // Content
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ended status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stop_circle_outlined, size: 13, color: Colors.white70),
                      const SizedBox(width: 5),
                      Text(
                        tr('live.stream_ended'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Channel avatar + name
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white24,
                      backgroundImage: avatarUrl != null
                          ? AppNetworkImage.provider(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              channelName.isNotEmpty ? channelName[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      channelName,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Title
                Text(
                  stream?.title ?? 'Live Stream',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Ended message
                const SizedBox(height: 6),
                const Text(
                  'This live stream has ended.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thank you for watching. The broadcaster has finished this live session.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),

                if (durationFormatted != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Duration: $durationFormatted',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (hasVod)
                      ElevatedButton.icon(
                        onPressed: () {
                          context.push('/video/${widget.streamId}');
                        },
                        icon: const Icon(Icons.play_circle_outline, size: 16),
                        label: const Text('Watch Replay'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: () {
                        _dvrSyncTimer?.cancel();
                        _playerRetryTimer?.cancel();
                        if (_isFullscreen) {
                          SystemChrome.setEnabledSystemUIMode(
                            SystemUiMode.edgeToEdge,
                          );
                          if (!kIsWeb) {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                          }
                        }
                        WakelockPlus.disable().ignore();
                        ref.read(miniPlayerProvider.notifier).dismiss();
                        if (mounted) {
                          context.go('/home');
                        }
                      },
                      icon: const Icon(Icons.home_rounded, size: 16),
                      label: const Text('Back to Home'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_isFullscreen) _toggleFullscreen();
                        ref.read(miniPlayerProvider.notifier).dismiss();
                        if (mounted) {
                          context.go('/live');
                        }
                      },
                      icon: const Icon(Icons.live_tv_rounded, size: 15),
                      label: const Text('Browse Live'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReconnectBanner(LiveRoomState state) {
    final tr = ref.read(trProvider);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.orange.withValues(alpha: 0.9),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              state.retryCount > 0
                  ? '${tr('live.reconnecting')} (Attempt ${state.retryCount})'
                  : tr('live.reconnecting'),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stream meta bar ────────────────────────────────────────────────────────

  Widget _buildStreamMeta(
    LiveRoomState state,
    ThemeData theme, {
    bool showChatToggle = false,
  }) {
    final stream = state.stream;
    if (stream == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stream.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (stream.videoChannel?.name != null)
                  Text(
                    stream.videoChannel!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ViewerCountWidget(count: state.viewerCount),
          if (showChatToggle) ...[
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: _isChatExpanded ? 'Hide chat (expand video)' : 'Show chat',
              onPressed: () =>
                  setState(() => _isChatExpanded = !_isChatExpanded),
              icon: Icon(
                _isChatExpanded
                    ? Icons.chat_bubble_rounded
                    : Icons.chat_bubble_outline_rounded,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Generic states ──────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(String error, ThemeData theme) {
    final tr = ref.read(trProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              tr('live.failed_load'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref
                  .read(liveRoomProvider(widget.streamId).notifier)
                  .refresh(),
              child: Text(tr('common.retry')),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(tr('common.go_back')),
            ),
          ],
        ),
      ),
    );
  }
}
