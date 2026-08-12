// lib/features/live/presentation/screens/live_room_screen.dart
// Production-quality live viewer experience: HLS player + chat + reactions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/presentation/providers/live_room_provider.dart';
import 'package:mobile/features/live/presentation/widgets/live_badge_widget.dart';
import 'package:mobile/features/live/presentation/widgets/live_chat_widget.dart';
import 'package:mobile/features/live/presentation/widgets/viewer_count_widget.dart';
import 'package:mobile/features/live/presentation/widgets/reaction_animation_widget.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';

class LiveRoomScreen extends ConsumerStatefulWidget {
  final String streamId;
  const LiveRoomScreen({super.key, required this.streamId});

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen> {
  VideoPlayerController? _playerCtrl;
  bool _isFullscreen = false;
  bool _controlsVisible = true;
  bool _playerInitialized = false;
  bool _playerError = false;
  bool _chatVisible = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().ignore();
  }

  @override
  void dispose() {
    _playerCtrl?.dispose();
    WakelockPlus.disable().ignore();
    super.dispose();
  }

  Future<void> _initPlayer(String hlsUrl) async {
    if (_playerInitialized) return;
    try {
      final ctrl =
          VideoPlayerController.networkUrl(Uri.parse(hlsUrl));
      await ctrl.initialize();
      await ctrl.play();
      if (mounted) {
        setState(() {
          _playerCtrl = ctrl;
          _playerInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _playerError = true);
    }
  }

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

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(liveRoomProvider(widget.streamId));
    final theme = Theme.of(context);

    // Init player when HLS URL becomes available
    final hlsUrl = roomState.stream?.hlsUrl;
    if (hlsUrl != null && !_playerInitialized && !_playerError) {
      _initPlayer(hlsUrl);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: roomState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : roomState.error != null
                ? _buildError(roomState.error!, theme)
                : _buildRoom(roomState, theme),
      ),
    );
  }

  Widget _buildRoom(LiveRoomState state, ThemeData theme) {
    final isLandscape = MediaQuery.of(context).orientation ==
        Orientation.landscape;

    if (isLandscape || _isFullscreen) {
      return _buildLandscapeLayout(state, theme);
    }
    return _buildPortraitLayout(state, theme);
  }

  Widget _buildPortraitLayout(LiveRoomState state, ThemeData theme) {
    return Column(
      children: [
        // Player section (16:9)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildPlayer(state),
        ),

        // Stream info
        _StreamInfoBar(state: state),

        // Chat
        Expanded(
          child: state.stream?.isChatEnabled != false
              ? LiveChatWidget(streamId: widget.streamId)
              : const Center(
                  child: Text('Chat is disabled for this stream.')),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(LiveRoomState state, ThemeData theme) {
    return Row(
      children: [
        // Player (left side)
        Expanded(
          flex: _chatVisible ? 3 : 5,
          child: _buildPlayer(state),
        ),
        // Chat (right side)
        if (_chatVisible && state.stream?.isChatEnabled != false)
          Expanded(
            flex: 2,
            child: Container(
              color: theme.colorScheme.surface,
              child: LiveChatWidget(streamId: widget.streamId),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayer(LiveRoomState state) {
    final socket = ref.read(liveSocketServiceProvider);

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (_playerInitialized && _playerCtrl != null)
            VideoPlayer(_playerCtrl!)
          else if (_playerError)
            _buildPlayerError()
          else if (state.isEnded)
            _buildStreamEndedOverlay(state)
          else
            _buildBufferingState(),

          // Controls overlay
          if (_controlsVisible) _buildControls(state),

          // Reaction animations
          ReactionAnimationWidget(
            reactionStream: socket.onReactionBroadcast,
          ),

          // Reconnect overlay
          if (state.connectionState ==
              SocketConnectionState.reconnecting)
            _buildReconnectBanner(),
        ],
      ),
    );
  }

  Widget _buildControls(LiveRoomState state) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent, Colors.black45],
            ),
          ),
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_isFullscreen) _toggleFullscreen();
                        context.pop();
                      },
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white),
                    ),
                    const LiveBadgeWidget(small: true),
                    const SizedBox(width: 8),
                    ViewerCountWidget(
                        count: state.viewerCount, light: true),
                    const Spacer(),
                    // Toggle chat visibility in landscape
                    IconButton(
                      onPressed: () =>
                          setState(() => _chatVisible = !_chatVisible),
                      icon: Icon(
                        _chatVisible
                            ? Icons.chat_bubble
                            : Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleFullscreen,
                      icon: Icon(
                        _isFullscreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Bottom: volume + title
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.stream?.title ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Volume
                    IconButton(
                      onPressed: () {
                        final v = _playerCtrl?.value.volume ?? 1.0;
                        _playerCtrl
                            ?.setVolume(v > 0 ? 0.0 : 1.0);
                        setState(() {});
                      },
                      icon: Icon(
                        (_playerCtrl?.value.volume ?? 1.0) > 0
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBufferingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 12),
          Text('Connecting to stream…',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildPlayerError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          const Text('Unable to load stream',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _playerError = false;
                _playerInitialized = false;
              });
            },
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamEndedOverlay(LiveRoomState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.live_tv_outlined, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text('Stream has ended',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          if (state.vodUrl != null) ...[
            const SizedBox(height: 12),
            const Text('Recording is processing...',
                style: TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30)),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildReconnectBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.orange.withValues(alpha: 0.9),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Text('Reconnecting…',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text('Failed to load stream',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(color: Colors.white60),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(liveRoomProvider(widget.streamId).notifier).refresh(),
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stream info bar ─────────────────────────────────────────────────────────

class _StreamInfoBar extends StatelessWidget {
  final LiveRoomState state;
  const _StreamInfoBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final stream = state.stream;
    if (stream == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (stream.videoChannel?.name != null)
                  Text(
                    stream.videoChannel!.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          ViewerCountWidget(count: state.viewerCount),
        ],
      ),
    );
  }
}
