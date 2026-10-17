// lib/features/calls/presentation/screens/call_screen.dart

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/features/calls/providers/call_state_provider.dart';
import 'package:mobile/features/calls/services/call_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/chats/presentation/providers/chat_messages_provider.dart';

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _controlsController;
  late AnimationController _floatingReactionController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _controlsAnimation;

  Offset _pipPosition = const Offset(16, 90);
  bool _controlsVisible = true;
  bool _isPipSwapped = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _controlsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _floatingReactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controlsAnimation = CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeOutCubic,
    );

    _scheduleAutoHideControls();
  }

  void _scheduleAutoHideControls() {
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        final callState = ref.read(callStateProvider);
        if (callState.isVideoCall && callState.status == CallStatus.connected) {
          _hideControls();
        }
      }
    });
  }

  void _hideControls() {
    if (mounted && _controlsController.isCompleted) {
      _controlsController.reverse();
      setState(() => _controlsVisible = false);
    }
  }

  void _showControls() {
    if (mounted) {
      _controlsController.forward();
      setState(() => _controlsVisible = true);
      _scheduleAutoHideControls();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _controlsController.dispose();
    _floatingReactionController.dispose();
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _collapseCall() {
    ref.read(callStateProvider.notifier).setCollapsed(true);
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        ref.read(routerProvider).go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callStateProvider);
    final callService = ref.watch(callServiceProvider);
    final tr = ref.watch(trProvider);

    // Listen for call termination
    ref.listen<CallState>(callStateProvider, (previous, next) {
      if (next.status == CallStatus.ended || next.status == CallStatus.idle) {
        if (mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            ref.read(routerProvider).go('/home');
          }
        }
      }
      if (next.status != previous?.status) {
        _showControls();
      }
      if (next.activeReaction != null && next.activeReaction != previous?.activeReaction) {
        _floatingReactionController.forward(from: 0.0);
      }
    });

    final isVideo = callState.isVideoCall;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          // If popped by system gesture, keep call active in collapsed overlay
          if (callState.isActive) {
            ref.read(callStateProvider.notifier).setCollapsed(true);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: SafeArea(
          top: !isVideo,
          bottom: false,
          child: isVideo
              ? _buildVideoLayout(context, callState, callService, tr, isDesktop, size)
              : _buildAudioCallView(context, callState, callService, tr, isDesktop, size),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // AUDIO CALL SCREEN (Matches Screenshot 3)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildAudioCallView(
    BuildContext context,
    CallState callState,
    CallService callService,
    String Function(String) tr,
    bool isDesktop,
    Size size,
  ) {
    final displayName = callState.remoteDisplayName ?? 'User';
    final avatarUrl = callState.remoteAvatarUrl;
    final isConnected = callState.status == CallStatus.connected;

    Widget content = Stack(
      children: [
        // Background Gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 1.25,
                colors: [
                  Color(0xFF162036),
                  Color(0xFF0B101D),
                  Color(0xFF070A12),
                ],
              ),
            ),
          ),
        ),

        // Ethereal Pulsing Halos (Ringing / Connecting / Active)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) => CustomPaint(
              painter: _AudioRingsPainter(
                progress: _waveController.value,
                color: const Color(0xFF00C6FF),
                center: Offset(
                  (isDesktop ? 480 : size.width) / 2,
                  (isDesktop ? 680 : size.height) * 0.32,
                ),
                isConnected: isConnected,
              ),
            ),
          ),
        ),

        // Floating Reaction Animation
        if (callState.activeReaction != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 240,
            child: AnimatedBuilder(
              animation: _floatingReactionController,
              builder: (context, _) {
                final val = _floatingReactionController.value;
                final reaction = callState.activeReaction;
                if (reaction == null) return const SizedBox.shrink();
                return Opacity(
                  opacity: (1.0 - val).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, -120 * val),
                    child: Center(
                      child: Text(
                        reaction,
                        style: const TextStyle(fontSize: 54),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Main Column
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Top Bar: Reactions Pill + Options Menu
                _buildAudioTopBar(context, callState, callService),

                const Spacer(flex: 2),

                // Center Avatar with Speaking Indicator
                _buildAudioAvatar(avatarUrl, displayName, isConnected),
                const SizedBox(height: 24),

                // Contact Name
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Call Duration / Status
                _buildAudioStatusText(callState, tr),

                const Spacer(flex: 3),

                // 2-Row Control Grid (Mute, Chat, Speaker / Add, Record, End)
                _buildAudioControlsGrid(context, callState, callService, tr),
                const SizedBox(height: 28),

                // Bottom Collapse Button
                GestureDetector(
                  onTap: _collapseCall,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr('calls.collapse'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withValues(alpha: 0.75),
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Center(
        child: Container(
          width: 480,
          height: 740,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildAudioTopBar(
    BuildContext context,
    CallState callState,
    CallService callService,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Quick Emoji Status / Reaction Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _reactionTap('✋', callService),
              const SizedBox(width: 6),
              _reactionTap('❤️', callService),
              const SizedBox(width: 6),
              _reactionTap('👏', callService),
              const SizedBox(width: 6),
              _reactionTap('😂', callService),
            ],
          ),
        ),

        // Triple-Dot Options Menu
        GestureDetector(
          onTap: () => _showMoreActionsSheet(context, callState, callService),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _reactionTap(String emoji, CallService callService) {
    return GestureDetector(
      onTap: () => callService.sendReaction(emoji),
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildAudioAvatar(String? avatarUrl, String displayName, bool isConnected) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: isConnected ? 1.0 : _pulseAnimation.value,
        child: child,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Soft Glow Halo
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isConnected
                      ? const Color(0xFF10B981).withValues(alpha: 0.35)
                      : const Color(0xFF00C6FF).withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),

          // Main Avatar
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isConnected
                    ? const Color(0xFF10B981)
                    : const Color(0xFF00C6FF),
                width: 2.5,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _buildFallbackAvatar(displayName),
                    )
                  : _buildFallbackAvatar(displayName),
            ),
          ),

          // Speaking Green Indicator Badge on Bottom Right
          if (isConnected)
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0B101D), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioStatusText(CallState callState, String Function(String) tr) {
    final isConnected = callState.status == CallStatus.connected;
    String statusStr = '';
    Color statusColor = const Color(0xFF00C6FF);

    switch (callState.status) {
      case CallStatus.calling:
        statusStr = tr('calls.calling');
        break;
      case CallStatus.ringing:
        statusStr = tr('calls.ringing');
        break;
      case CallStatus.connecting:
        statusStr = tr('calls.connecting');
        break;
      case CallStatus.connected:
        statusStr = _formatDuration(callState.callDuration);
        statusColor = Colors.white.withValues(alpha: 0.85);
        break;
      case CallStatus.ended:
        statusStr = tr('calls.ended');
        statusColor = const Color(0xFFEF4444);
        break;
      case CallStatus.idle:
        statusStr = '';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isConnected) ...[
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          statusStr,
          style: TextStyle(
            color: statusColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioControlsGrid(
    BuildContext context,
    CallState callState,
    CallService callService,
    String Function(String) tr,
  ) {
    return Column(
      children: [
        // Row 1: Mute | Chat | Speaker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _AudioActionButton(
              icon: callState.isMuted
                  ? Icons.mic_off_rounded
                  : Icons.mic_rounded,
              label: callState.isMuted ? tr('calls.unmute') : tr('calls.mute'),
              isActive: callState.isMuted,
              activeColor: const Color(0xFFEF4444),
              onTap: () => callService.toggleMute(),
            ),
            _AudioActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: tr('calls.chat'),
              isActive: false,
              onTap: () => _showInCallChatSheet(context, callState),
            ),
            _AudioActionButton(
              icon: callState.isSpeakerOn
                  ? Icons.volume_up_rounded
                  : Icons.hearing_rounded,
              label: tr('calls.speaker'),
              isActive: callState.isSpeakerOn,
              activeColor: const Color(0xFF00C6FF),
              onTap: () => callService.toggleSpeaker(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Row 2: Add | Record | End
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _AudioActionButton(
              icon: Icons.person_add_alt_1_rounded,
              label: tr('calls.add'),
              isActive: false,
              onTap: () => _showInviteDialog(context, tr),
            ),
            _AudioActionButton(
              icon: callState.isRecording
                  ? Icons.fiber_manual_record_rounded
                  : Icons.radio_button_checked_rounded,
              label: callState.isRecording ? tr('calls.recording') : tr('calls.record'),
              isActive: callState.isRecording,
              activeColor: const Color(0xFFEF4444),
              onTap: () => ref.read(callStateProvider.notifier).toggleRecording(),
            ),
            _AudioActionButton(
              icon: Icons.call_end_rounded,
              label: tr('calls.end'),
              isEndCall: true,
              onTap: () {
                callService.hangUp();
                if (mounted) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    ref.read(routerProvider).go('/home');
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // VIDEO CALL SCREEN (Matches Screenshot 4)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildVideoLayout(
    BuildContext context,
    CallState callState,
    CallService callService,
    String Function(String) tr,
    bool isDesktop,
    Size size,
  ) {
    if (isDesktop && !_isFullscreen) {
      return Center(
        child: Container(
          width: (size.width * 0.88).clamp(720.0, 1120.0),
          height: (size.height * 0.88).clamp(520.0, 780.0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F1D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: _buildVideoFrame(context, callState, callService, tr, isDesktop, size),
        ),
      );
    }

    return _buildVideoFrame(context, callState, callService, tr, isDesktop, size);
  }

  Widget _buildVideoFrame(
    BuildContext context,
    CallState callState,
    CallService callService,
    String Function(String) tr,
    bool isDesktop,
    Size size,
  ) {
    final displayName = callState.remoteDisplayName ?? 'User';
    final avatarUrl = callState.remoteAvatarUrl;
    final isConnected = callState.status == CallStatus.connected;

    return GestureDetector(
      onTap: _showControls,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // ── Main Video Layer ──────────────────────────────────────────────
          Positioned.fill(
            child: isConnected
                ? (_isPipSwapped
                    ? RTCVideoView(
                        callService.localRenderer,
                        mirror: callState.isFrontCamera,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : RTCVideoView(
                        callService.remoteRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ))
                : _buildVideoConnectingPlaceholder(avatarUrl, displayName, callState, tr),
          ),

          // Vignette Gradient Overlays for Video
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.0, 0.22, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Top-Left Resolution / HD Badge
          Positioned(
            top: 20,
            left: 20,
            child: AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '1080P',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Audio Indicators: "ılı You" (Bottom-Left)
          Positioned(
            left: 20,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    callState.isMuted ? Icons.mic_off_rounded : Icons.graphic_eq_rounded,
                    color: callState.isMuted
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    tr('calls.you'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Reaction Animation
          if (callState.activeReaction != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 200,
              child: AnimatedBuilder(
                animation: _floatingReactionController,
                builder: (context, _) {
                  final val = _floatingReactionController.value;
                  final reaction = callState.activeReaction;
                  if (reaction == null) return const SizedBox.shrink();
                  return Opacity(
                    opacity: (1.0 - val).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -140 * val),
                      child: Center(
                        child: Text(
                          reaction,
                          style: const TextStyle(fontSize: 58),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Draggable Local PiP Preview ──────────────────────────────────
          if (isConnected)
            Positioned(
              right: _pipPosition.dx,
              bottom: _pipPosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pipPosition = Offset(
                      (_pipPosition.dx - details.delta.dx).clamp(12.0, size.width - 150.0),
                      (_pipPosition.dy - details.delta.dy).clamp(100.0, size.height - 220.0),
                    );
                  });
                },
                onTap: () {
                  setState(() => _isPipSwapped = !_isPipSwapped);
                },
                child: Container(
                  width: 120,
                  height: 168,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _isPipSwapped
                            ? RTCVideoView(
                                callService.remoteRenderer,
                                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                              )
                            : (callState.isVideoEnabled
                                ? RTCVideoView(
                                    callService.localRenderer,
                                    mirror: callState.isFrontCamera,
                                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                  )
                                : Container(
                                    color: const Color(0xFF1E293B),
                                    child: Center(
                                      child: Icon(
                                        Icons.videocam_off_rounded,
                                        color: Colors.white.withValues(alpha: 0.6),
                                        size: 28,
                                      ),
                                    ),
                                  )),
                      ),
                      // Mini PiP Name Tag
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.graphic_eq_rounded, color: Color(0xFF10B981), size: 10),
                              const SizedBox(width: 3),
                              Text(
                                _isPipSwapped ? displayName : tr('calls.you'),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Top Header Bar ──────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: AnimatedBuilder(
              animation: _controlsAnimation,
              builder: (context, child) =>
                  Opacity(opacity: _controlsAnimation.value, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    // Collapse / Minimize
                    GestureDetector(
                      onTap: _collapseCall,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Active dot + Duration
                    if (isConnected) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(callState.callDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Center Contact Name & Subtitle
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                          ),
                        ),
                        Text(
                          tr('calls.realtime_video'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Switch Camera / PiP Flip
                    GestureDetector(
                      onTap: () {
                        setState(() => _isPipSwapped = !_isPipSwapped);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Fullscreen Toggle
                    GestureDetector(
                      onTap: () {
                        setState(() => _isFullscreen = !_isFullscreen);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Icon(
                          _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Floating Dock ─────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _controlsAnimation,
              builder: (context, child) =>
                  Opacity(opacity: _controlsAnimation.value, child: child),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 16 : 10,
                          vertical: isDesktop ? 10 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1424).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Microphone
                              _VideoDockButton(
                                icon: callState.isMuted
                                    ? Icons.mic_off_rounded
                                    : Icons.mic_rounded,
                                label: tr('calls.microphone'),
                                isActive: callState.isMuted,
                                activeColor: const Color(0xFFEF4444),
                                onTap: () => callService.toggleMute(),
                                size: isDesktop ? 44 : 38,
                                iconSize: isDesktop ? 20 : 18,
                              ),
                              SizedBox(width: isDesktop ? 12 : 8),

                              // Camera
                              _VideoDockButton(
                                icon: callState.isVideoEnabled
                                    ? Icons.videocam_rounded
                                    : Icons.videocam_off_rounded,
                                label: tr('calls.camera'),
                                isActive: !callState.isVideoEnabled,
                                activeColor: const Color(0xFFEF4444),
                                onTap: () => callService.toggleVideo(),
                                size: isDesktop ? 44 : 38,
                                iconSize: isDesktop ? 20 : 18,
                              ),
                              SizedBox(width: isDesktop ? 12 : 8),

                              // Speaker
                              _VideoDockButton(
                                icon: callState.isSpeakerOn
                                    ? Icons.volume_up_rounded
                                    : Icons.hearing_rounded,
                                label: tr('calls.speaker'),
                                isActive: callState.isSpeakerOn,
                                activeColor: const Color(0xFF00C6FF),
                                onTap: () => callService.toggleSpeaker(),
                                size: isDesktop ? 44 : 38,
                                iconSize: isDesktop ? 20 : 18,
                              ),
                              SizedBox(width: isDesktop ? 16 : 10),

                              // End Call (Prominent Red Pill)
                              GestureDetector(
                                onTap: () {
                                  callService.hangUp();
                                  if (mounted) {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    } else {
                                      ref.read(routerProvider).go('/home');
                                    }
                                  }
                                },
                                child: Container(
                                  width: isDesktop ? 56 : 48,
                                  height: isDesktop ? 44 : 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                        blurRadius: 14,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.white,
                                    size: isDesktop ? 24 : 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: isDesktop ? 16 : 10),

                              // Invite
                              _VideoDockButton(
                                icon: Icons.person_add_alt_1_rounded,
                                label: tr('calls.invite'),
                                isActive: false,
                                onTap: () => _showInviteDialog(context, tr),
                                size: isDesktop ? 44 : 38,
                                iconSize: isDesktop ? 20 : 18,
                              ),
                              SizedBox(width: isDesktop ? 12 : 8),

                              // Chat
                              _VideoDockButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: tr('calls.chat'),
                                isActive: false,
                                onTap: () => _showInCallChatSheet(context, callState),
                                size: isDesktop ? 44 : 38,
                                iconSize: isDesktop ? 20 : 18,
                              ),
                              SizedBox(width: isDesktop ? 12 : 8),

                              // More
                              _VideoDockButton(
                                icon: Icons.more_horiz_rounded,
                                label: tr('calls.more'),
                                isActive: false,
                                onTap: () => _showMoreActionsSheet(context, callState, callService),
                                size: isDesktop ? 44 : 38,
                                iconSize: isDesktop ? 20 : 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoConnectingPlaceholder(
    String? avatarUrl,
    String displayName,
    CallState callState,
    String Function(String) tr,
  ) {
    return Container(
      color: const Color(0xFF0B101D),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient blurred avatar background
          if (avatarUrl != null && avatarUrl.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
              child: Container(color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) =>
                    Transform.scale(scale: _pulseAnimation.value, child: child),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00C6FF), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C6FF).withValues(alpha: 0.4),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => _buildFallbackAvatar(displayName),
                          )
                        : _buildFallbackAvatar(displayName),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                callState.status == CallStatus.calling
                    ? tr('calls.calling')
                    : (callState.status == CallStatus.ringing
                        ? tr('calls.ringing')
                        : tr('calls.connecting')),
                style: const TextStyle(
                  color: Color(0xFF00C6FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // IN-CALL SHEETS & MODALS (Screenshot 5)
  // ═════════════════════════════════════════════════════════════════════════════

  void _showMoreActionsSheet(
    BuildContext context,
    CallState callState,
    CallService callService,
  ) {
    final tr = ref.read(trProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet Grab Bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // Emoji Reactions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['✋', '😍', '🎉', '😂', '😭'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      callService.sendReaction(emoji);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),

              // Action Items List
              _sheetTile(
                icon: Icons.front_hand_rounded,
                title: tr('calls.raise_hand'),
                isActive: callState.isHandRaised,
                onTap: () {
                  ref.read(callStateProvider.notifier).toggleHandRaised();
                  callService.sendReaction('✋', action: 'raise_hand');
                  Navigator.pop(ctx);
                },
              ),
              _sheetTile(
                icon: Icons.screen_share_rounded,
                title: tr('calls.screen_share'),
                isActive: callState.isScreenSharing,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (callState.isScreenSharing) {
                    await callService.stopScreenShare();
                  } else {
                    await callService.startScreenShare();
                  }
                },
              ),
              if (!kIsWeb)
                _sheetTile(
                  icon: Icons.flip_camera_ios_rounded,
                  title: tr('calls.flip'),
                  onTap: () {
                    callService.switchCamera();
                    Navigator.pop(ctx);
                  },
                ),
              _sheetTile(
                icon: Icons.noise_control_off_rounded,
                title: tr('calls.noise_reduction'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              _sheetTile(
                icon: Icons.dialpad_rounded,
                title: tr('calls.keypad'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showKeypadDialog(context);
                },
              ),
              _sheetTile(
                icon: Icons.settings_rounded,
                title: tr('calls.settings'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required String title,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFF00C6FF) : Colors.white,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? const Color(0xFF00C6FF) : Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showInCallChatSheet(BuildContext context, CallState callState) {
    final convId = callState.conversationId;
    if (convId == null) return;

    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'In-Call Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Message List
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final messagesAsync = ref.watch(chatMessagesProvider(convId));
                    return messagesAsync.when(
                      data: (messages) {
                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'No messages yet',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          );
                        }
                        return ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.sender.id == callState.callerId ||
                                msg.sender.id != callState.remoteUserId;
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF0072FF).withValues(alpha: 0.75)
                                      : Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  msg.content ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('$err', style: const TextStyle(color: Colors.white54))),
                    );
                  },
                ),
              ),
              // Input Field
              Container(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
                color: Colors.black.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF00C6FF)),
                      onPressed: () {
                        final text = textController.text.trim();
                        if (text.isNotEmpty) {
                          ref.read(chatMessagesProvider(convId).notifier).sendMessage(content: text);
                          textController.clear();
                        }
                      },
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

  void _showKeypadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.94),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dialpad',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Table(
                  children: [
                    TableRow(children: [_keypadKey('1'), _keypadKey('2'), _keypadKey('3')]),
                    TableRow(children: [_keypadKey('4'), _keypadKey('5'), _keypadKey('6')]),
                    TableRow(children: [_keypadKey('7'), _keypadKey('8'), _keypadKey('9')]),
                    TableRow(children: [_keypadKey('*'), _keypadKey('0'), _keypadKey('#')]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _keypadKey(String digit) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTap: () => HapticFeedback.lightImpact(),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, String Function(String) tr) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: Text(
            tr('calls.invite'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share this link with participants to join the call:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'zikrekedusan.com/call/join',
                        style: TextStyle(color: Color(0xFF00C6FF), fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'https://zikrekedusan.com/call/join'));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied to clipboard')),
                        );
                      },
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

  Widget _buildFallbackAvatar(String name) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// AUDIO ACTION BUTTON (Matches Screenshot 3)
// ═════════════════════════════════════════════════════════════════════════════

class _AudioActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final bool isEndCall;
  final VoidCallback onTap;

  const _AudioActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    this.isEndCall = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isEndCall) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final effectiveColor =
        isActive ? (activeColor ?? const Color(0xFF00C6FF)) : Colors.white;
    final bgColor = isActive
        ? (activeColor ?? const Color(0xFF00C6FF)).withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.10);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? (activeColor ?? const Color(0xFF00C6FF)).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.14),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: effectiveColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VIDEO DOCK BUTTON (Matches Screenshot 4)
// ═════════════════════════════════════════════════════════════════════════════

class _VideoDockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _VideoDockButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.activeColor,
    required this.onTap,
    this.size = 44,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        isActive ? (activeColor ?? const Color(0xFF00C6FF)) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isActive
                  ? (activeColor ?? const Color(0xFF00C6FF)).withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? (activeColor ?? const Color(0xFF00C6FF)).withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: effectiveColor, size: iconSize),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// AUDIO RINGS PAINTER
// ═════════════════════════════════════════════════════════════════════════════

class _AudioRingsPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Offset center;
  final bool isConnected;

  _AudioRingsPainter({
    required this.progress,
    required this.color,
    required this.center,
    required this.isConnected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = isConnected ? 2 : 4;
    final maxRadius = size.shortestSide * 0.45;

    for (int i = 0; i < count; i++) {
      final delay = i * (1.0 / count);
      final phase = (progress + delay) % 1.0;
      final radius = 68.0 + maxRadius * phase;
      final alpha = (1.0 - phase).clamp(0.0, 1.0) * (isConnected ? 0.08 : 0.18);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AudioRingsPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.center != center ||
      old.isConnected != isConnected;
}
