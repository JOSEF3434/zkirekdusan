// lib/features/live/presentation/screens/live_room_screen.dart
// YouTube Live-style viewer experience:
//   • 16:9 player pinned at the top
//   • Live badge + viewer count overlay on the player
//   • Floating animated emoji reactions
//   • Scrollable chat below the player
//   • Emoji reaction picker bar at the very bottom

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';
import 'package:mobile/features/live/presentation/providers/live_room_provider.dart';
import 'package:mobile/features/live/presentation/widgets/live_badge_widget.dart';
import 'package:mobile/features/live/presentation/widgets/live_chat_widget.dart';
import 'package:mobile/features/live/presentation/widgets/live_stream_progress_bar.dart';
import 'package:mobile/features/live/presentation/widgets/viewer_count_widget.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/core/utils/ethiopian_calendar.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

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

// ─── Emoji reaction picker emojis ─────────────────────────────────────────────

const _kPickerEmojis = ['❤️', '🔥', '👏', '😂', '😮', '💯', '🎉', '👍'];

// ─── Main Screen ──────────────────────────────────────────────────────────────

class LiveRoomScreen extends ConsumerStatefulWidget {
  final String streamId;
  const LiveRoomScreen({super.key, required this.streamId});

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Player
  VideoPlayerController? _playerCtrl;
  bool _playerInitialized = false;
  bool _isPlayerInitializing = false;
  bool _playerError = false;
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

  void _checkCreatorRedirect(LiveRoomState roomState) {
    if (_redirectedToStudio) return;
    final stream = roomState.stream;
    if (stream == null || roomState.phase == LiveStreamPhase.ended) return;

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
          context.go(
            '/live/studio?streamId=${stream.id}&channelId=${stream.videoChannelId}',
          );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable().ignore();
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
        final reclaimed = ref
            .read(miniPlayerProvider.notifier)
            .reclaimController(widget.streamId);
        if (reclaimed != null) {
          debugPrint(
            '[LiveRoomScreen] Fullscreen player mounted; controller reclaimed '
            'for ${widget.streamId} position=${reclaimed.value.position} '
            'playing=${reclaimed.value.isPlaying}',
          );
          setState(() {
            _playerCtrl = reclaimed;
            _playerInitialized = true;
          });
          _attachPlayerListeners(reclaimed);
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
    WidgetsBinding.instance.removeObserver(this);
    _reactionSub?.cancel();
    // Note: _playerCtrl may have been transferred to miniPlayerProvider
    // (in that case it's null here because we call _minimizeToMiniPlayer).
    _playerCtrl?.dispose();
    _hideControlsTimer?.cancel();
    for (final p in _particles) {
      p.ctrl.dispose();
    }
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
          _playerCtrl != null &&
          _playerCtrl!.value.isInitialized) {
        _playerCtrl?.play();
      }
    }
  }

  void _attachPlayerListeners(VideoPlayerController ctrl) {
    ctrl.addListener(() {
      if (!mounted) return;
      if (ctrl.value.hasError) {
        ref.read(liveRoomProvider(widget.streamId).notifier).notifyPlayerInterruption();
      }
    });
  }

  // ── Player ─────────────────────────────────────────────────────────────────

  Future<void> _initPlayer(String hlsUrl) async {
    final currentPhase = ref.read(liveRoomProvider(widget.streamId)).phase;
    if (currentPhase == LiveStreamPhase.ended || currentPhase.isTerminal) return;
    if (_playerInitialized || _isPlayerInitializing || hlsUrl.trim().isEmpty) return;

    _isPlayerInitializing = true;
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(hlsUrl.trim()));
      await ctrl.initialize();
      await ctrl.play();
      if (mounted) {
        setState(() {
          _playerCtrl = ctrl;
          _playerInitialized = true;
          _playerError = false;
          _isPlayerInitializing = false;
        });
        _attachPlayerListeners(ctrl);
        ref.read(liveRoomProvider(widget.streamId).notifier).notifyPlayerReady();
      }
    } catch (e) {
      debugPrint('[LiveRoom] Failed to init player: $e');
      if (mounted) {
        setState(() {
          _playerError = true;
          _isPlayerInitializing = false;
        });
        ref.read(liveRoomProvider(widget.streamId).notifier).notifyPlayerInterruption();
      }
    }
  }

  // ── Controls visibility ────────────────────────────────────────────────────

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _onTapPlayer() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHideControls();
  }

  // ── Mini-player minimise ────────────────────────────────────────────────

  void _minimizeToMiniPlayer(LiveRoomState roomState) {
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
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  // ── Reactions ──────────────────────────────────────────────────────────────

  void _sendReaction(String emoji) {
    final socket = ref.read(liveSocketServiceProvider);
    socket.sendReaction(streamId: widget.streamId, emoji: emoji);
    _spawnParticles(emoji, 3);
  }

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
      setState(() => _particles.add(particle));
      ctrl.forward().then((_) {
        if (mounted) {
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
        _playerCtrl?.pause();
      }
      final hls = next.stream?.hlsUrl;
      if ((next.phase == LiveStreamPhase.live || next.phase == LiveStreamPhase.starting) &&
          hls != null &&
          hls.isNotEmpty &&
          !_playerInitialized &&
          !_isPlayerInitializing) {
        _initPlayer(hls);
      }
    });

    // Subscribe to incoming reactions
    final socket = ref.read(liveSocketServiceProvider);

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (isLandscape || _isFullscreen) {
      return _buildLandscape(roomState, socket, theme);
    }
    return _buildPortrait(roomState, socket, theme);
  }

  // ── Portrait layout (YouTube-style) ──────────────────────────────────────

  Widget _buildPortrait(
    LiveRoomState roomState,
    LiveSocketService socket,
    ThemeData theme,
  ) {
    return PopScope(
      // Intercept back: minimize instead of leaving.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _minimizeToMiniPlayer(roomState);
      },
      child: GestureDetector(
        // Drag-down on the player area to minimize.
        onVerticalDragStart: (_) => setState(() {
          _isDragging = true;
          _dragOffset = 0;
        }),
        onVerticalDragUpdate: (details) {
          if (!_isDragging) return;
          final next = _dragOffset + details.delta.dy;
          setState(() => _dragOffset = next < 0 ? 0 : next);
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0.0;
          if (_dragOffset > _kMiniDragThreshold || (velocity > 250 && _dragOffset > 20)) {
            _minimizeToMiniPlayer(roomState);
          }
          setState(() {
            _isDragging = false;
            _dragOffset = 0;
          });
        },
        child: Transform.translate(
          offset: Offset(0, _isDragging ? _dragOffset.clamp(0.0, 300.0) : 0),
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: SafeArea(
              child: roomState.isLoading
                  ? _buildLoading()
                  : roomState.error != null
                  ? _buildError(roomState.error!, theme)
                  : Column(
                      children: [
                        // ── 16:9 Player ──────────────────────────────────────
                        _buildPlayerSection(roomState, socket),

                        // ── Stream meta ──────────────────────────────────────
                        _buildStreamMeta(roomState, theme),

                        // ── Chat list ────────────────────────────────────────
                        Expanded(
                          child: roomState.stream?.isChatEnabled != false
                              ? LiveChatWidget(streamId: widget.streamId)
                              : Center(
                                  child: Text(
                                    ref.read(trProvider)('live.chat_disabled'),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                        ),

                        // ── Emoji reaction picker (hidden when keyboard is active) ──
                        if (MediaQuery.of(context).viewInsets.bottom == 0)
                          _buildEmojiBar(),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Landscape layout ───────────────────────────────────────────────────────

  Widget _buildLandscape(
    LiveRoomState roomState,
    LiveSocketService socket,
    ThemeData theme,
  ) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_isFullscreen) _toggleFullscreen();
          _minimizeToMiniPlayer(roomState);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildPlayerSection(roomState, socket, dark: true),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: roomState.stream?.isChatEnabled != false
                          ? LiveChatWidget(streamId: widget.streamId)
                          : Center(
                              child: Text(
                                ref.read(trProvider)(
                                  'live.chat_disabled_short',
                                ),
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ),
                    ),
                    _buildEmojiBar(dark: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Player section ─────────────────────────────────────────────────────────

  Widget _buildPlayerSection(
    LiveRoomState state,
    LiveSocketService socket, {
    bool dark = false,
  }) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTapPlayer,
        onVerticalDragStart: (_) => setState(() {
          _isDragging = true;
          _dragOffset = 0;
        }),
        onVerticalDragUpdate: (details) {
          if (!_isDragging) return;
          final next = _dragOffset + details.delta.dy;
          setState(() => _dragOffset = next < 0 ? 0 : next);
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0.0;
          if (_dragOffset > _kMiniDragThreshold || (velocity > 250 && _dragOffset > 20)) {
            _minimizeToMiniPlayer(state);
          }
          setState(() {
            _isDragging = false;
            _dragOffset = 0;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Black backdrop
            Container(color: Colors.black),

            // Phase-driven player content
            _buildPlayerContent(state),

            // Controls overlay (gradient + top bar)
            AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: _buildControls(state),
            ),

            // Floating reactions
            _buildParticleLayer(),

            // Reconnect banner
            if (state.phase == LiveStreamPhase.reconnecting ||
                state.connectionState == SocketConnectionState.reconnecting)
              _buildReconnectBanner(state),

            // Persistent live-position progress bar beneath the video player
            if (state.phase == LiveStreamPhase.live)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LiveStreamProgressBar(
                  startedAt: state.stream?.startedAt,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerContent(LiveRoomState state) {
    switch (state.phase) {
      case LiveStreamPhase.loading:
        return _buildBuffering();
      case LiveStreamPhase.scheduled:
        return _buildStreamScheduled(state);
      case LiveStreamPhase.starting:
        return _buildStreamStarting(state);
      case LiveStreamPhase.live:
        if (_playerInitialized && _playerCtrl != null) {
          return VideoPlayer(_playerCtrl!);
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
        return _buildPlayerError();
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

  Widget _buildBuffering() {
    final tr = ref.read(trProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 12),
          Text(
            tr('live.connecting'),
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
              });
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

                if (durationFormatted != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Duration: $durationFormatted',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],

                const SizedBox(height: 14),

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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_isFullscreen) _toggleFullscreen();
                        _minimizeToMiniPlayer(state);
                      },
                      icon: const Icon(Icons.arrow_back, size: 14),
                      label: Text(tr('common.go_back')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildStreamMeta(LiveRoomState state, ThemeData theme) {
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
        ],
      ),
    );
  }

  // ── Emoji reaction picker bar ──────────────────────────────────────────────

  Widget _buildEmojiBar({bool dark = false}) {
    final bg = dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade100;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _kPickerEmojis
              .map(
                (e) => GestureDetector(
                  onTap: () => _sendReaction(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              )
              .toList(),
        ),
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
