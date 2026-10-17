// lib/features/calls/presentation/screens/call_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/calls/providers/call_state_provider.dart';
import 'package:mobile/features/calls/services/call_service.dart';
import 'package:mobile/core/utils/localization_service.dart';

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
  late Animation<double> _pulseAnimation;
  late Animation<double> _controlsAnimation;

  Offset _pipPosition = const Offset(16, 100);
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
    Future.delayed(const Duration(seconds: 5), () {
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callStateProvider);
    final callService = ref.watch(callServiceProvider);
    final tr = ref.watch(trProvider);

    ref.listen<CallState>(callStateProvider, (previous, next) {
      if (next.status == CallStatus.ended ||
          next.status == CallStatus.idle) {
        if (mounted && Navigator.canPop(context)) {
          context.pop();
        }
      }
      if (next.status != previous?.status) {
        _showControls();
      }
    });

    final isVideo = callState.isVideoCall;
    final isConnected = callState.status == CallStatus.connected;
    final displayName = callState.remoteDisplayName ?? 'User';
    final avatarUrl = callState.remoteAvatarUrl;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          callService.hangUp();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _showControls,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // Background
              Positioned.fill(
                child: isVideo && isConnected
                    ? RTCVideoView(
                        callService.remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : _buildAudioBackground(avatarUrl),
              ),

              // Animated wave rings (audio connected)
              if (!isVideo && isConnected)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) => CustomPaint(
                      painter: _WavePainter(
                        progress: _waveController.value,
                        color: const Color(0xFF00C6FF).withValues(alpha: 0.06),
                        center: Offset(size.width / 2, size.height * 0.40),
                      ),
                    ),
                  ),
                ),

              // Video vignette gradient
              if (isVideo && isConnected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x99000000),
                            Colors.transparent,
                            Colors.transparent,
                            Color(0xCC000000),
                          ],
                          stops: [0.0, 0.22, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

              // Center content (audio / pre-connect)
              if (!isVideo || !isConnected)
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: isConnected ? 1.0 : _pulseAnimation.value,
                          child: child,
                        ),
                        child: _buildCallerAvatar(
                          avatarUrl,
                          displayName,
                          isConnected: isConnected,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(color: Color(0x66000000), blurRadius: 12),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      _buildStatusBadge(callState, tr, isVideo),
                    ],
                  ),
                ),

              // Video: participant name overlay
              if (isVideo && isConnected)
                Positioned(
                  left: 20,
                  bottom: 130,
                  child: AnimatedOpacity(
                    opacity: _controlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  color: Color(0x99000000), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildCompactStatus(callState, _formatDuration, tr),
                      ],
                    ),
                  ),
                ),

              // Draggable local PiP
              if (isVideo && isConnected && callState.isVideoEnabled)
                Positioned(
                  right: _pipPosition.dx,
                  top: _pipPosition.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _pipPosition = Offset(
                          (_pipPosition.dx - details.delta.dx).clamp(
                              8.0, size.width - 120.0),
                          (_pipPosition.dy + details.delta.dy).clamp(
                              60.0, size.height - 250.0),
                        );
                      });
                    },
                    child: Container(
                      width: 108,
                      height: 156,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: RTCVideoView(
                        callService.localRenderer,
                        mirror: callState.isFrontCamera,
                        objectFit: RTCVideoViewObjectFit
                            .RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),

              // Top bar
              AnimatedBuilder(
                animation: _controlsAnimation,
                builder: (context, child) =>
                    Opacity(opacity: _controlsAnimation.value, child: child),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _glassButton(
                          icon: Icons.keyboard_arrow_down_rounded,
                          onTap: () {
                            if (mounted && Navigator.canPop(context)) {
                              context.pop();
                            }
                          },
                        ),
                        const Spacer(),
                        _encryptionBadge(),
                        const SizedBox(width: 8),
                        _signalBadge(callState),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom controls
              AnimatedBuilder(
                animation: _controlsAnimation,
                builder: (context, child) =>
                    Opacity(opacity: _controlsAnimation.value, child: child),
                child: Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomControls(
                      callState, callService, tr, isVideo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioBackground(String? avatarUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (avatarUrl != null && avatarUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: avatarUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _gradientBg(),
          )
        else
          _gradientBg(),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xCC0B0E18), Color(0xE60D1525)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0D1F3C), Color(0xFF071018)],
          ),
        ),
      );

  Widget _buildCallerAvatar(
    String? avatarUrl,
    String displayName, {
    required bool isConnected,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (!isConnected) ...[
          _pulseRing(160, _pulseController, 0.04),
          _pulseRing(135, _pulseController, 0.08),
        ],
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isConnected
                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                  : [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: (isConnected
                        ? const Color(0xFF10B981)
                        : const Color(0xFF00C6FF))
                    .withValues(alpha: 0.35),
                blurRadius: 36,
                spreadRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _avatarFallback(displayName),
                  )
                : _avatarFallback(displayName),
          ),
        ),
        if (isConnected)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child:
                  const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _pulseRing(double size, AnimationController ctl, double maxAlpha) {
    return AnimatedBuilder(
      animation: ctl,
      builder: (_, __) => Container(
        width: size * (1.0 + ctl.value * 0.18),
        height: size * (1.0 + ctl.value * 0.18),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF00C6FF)
                .withValues(alpha: maxAlpha * (1.0 - ctl.value)),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) => Container(
        color: const Color(0xFF1B2230),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  Widget _buildStatusBadge(
      CallState callState, String Function(String) tr, bool isVideo) {
    final isConnected = callState.status == CallStatus.connected;
    final text = _getStatusText(callState, tr);
    final color =
        isConnected ? const Color(0xFF10B981) : const Color(0xFF00C6FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isConnected)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          else
            Icon(
              isVideo ? Icons.videocam_rounded : Icons.phone_in_talk_rounded,
              color: color,
              size: 15,
            ),
          if (!isConnected) const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatus(
    CallState callState,
    String Function(Duration) fmt,
    String Function(String) tr,
  ) {
    final isConnected = callState.status == CallStatus.connected;
    final text = isConnected
        ? fmt(callState.callDuration)
        : _getStatusText(callState, tr);
    final color =
        isConnected ? const Color(0xFF10B981) : const Color(0xFF00C6FF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            shadows: const [Shadow(color: Color(0x88000000), blurRadius: 6)],
          ),
        ),
      ],
    );
  }

  String _getStatusText(CallState state, String Function(String) tr) {
    switch (state.status) {
      case CallStatus.calling:
        return tr('calls.calling');
      case CallStatus.ringing:
        return tr('calls.ringing');
      case CallStatus.connecting:
        return tr('calls.connecting');
      case CallStatus.connected:
        return _formatDuration(state.callDuration);
      case CallStatus.ended:
        return tr('calls.ended');
      case CallStatus.idle:
        return '';
    }
  }

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _encryptionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 11, color: Color(0xFF10B981)),
          const SizedBox(width: 4),
          Text(
            'Encrypted',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalBadge(CallState callState) {
    if (callState.status != CallStatus.connected) return const SizedBox.shrink();
    const bars = 4;
    const activeBars = 4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(bars, (i) {
            final isActive = i < activeBars;
            return Container(
              margin: const EdgeInsets.only(right: 2),
              width: 4,
              height: 6.0 + i * 2.5,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF10B981)
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
          const SizedBox(width: 5),
          Text(
            'HD',
            style: TextStyle(
              color: const Color(0xFF10B981).withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    CallState callState,
    CallService callService,
    String Function(String) tr,
    bool isVideo,
  ) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + safeBottom),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0A0F1A).withValues(alpha: 0.0),
                const Color(0xFF0A0F1A).withValues(alpha: 0.88),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallControlButton(
                    icon: callState.isMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    isActive: callState.isMuted,
                    activeColor: Colors.redAccent,
                    label: callState.isMuted ? 'Unmute' : tr('calls.mute'),
                    onTap: () => callService.toggleMute(),
                  ),
                  _CallControlButton(
                    icon: callState.isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.hearing_rounded,
                    isActive: callState.isSpeakerOn,
                    activeColor: const Color(0xFF00C6FF),
                    label: tr('calls.speaker'),
                    onTap: () => callService.toggleSpeaker(),
                  ),
                  if (isVideo) ...[
                    _CallControlButton(
                      icon: callState.isVideoEnabled
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      isActive: !callState.isVideoEnabled,
                      activeColor: Colors.orangeAccent,
                      label: tr('calls.video'),
                      onTap: () => callService.toggleVideo(),
                    ),
                    _CallControlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      isActive: false,
                      label: tr('calls.flip'),
                      onTap: () => callService.switchCamera(),
                    ),
                  ] else ...[
                    _CallControlButton(
                      icon: Icons.dialpad_rounded,
                      isActive: false,
                      label: 'Keypad',
                      onTap: () {},
                    ),
                    _CallControlButton(
                      icon: Icons.add_call,
                      isActive: false,
                      label: 'Add',
                      onTap: () {},
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  callService.hangUp();
                  if (mounted && Navigator.canPop(context)) {
                    context.pop();
                  }
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                        blurRadius: 22,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.call_end_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wave rings painter for audio call
// ─────────────────────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Offset center;

  _WavePainter({
    required this.progress,
    required this.color,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxRadius = size.shortestSide * 0.48;
    for (int i = 0; i < 4; i++) {
      final delay = i * 0.25;
      final phase = (progress + delay) % 1.0;
      final radius = size.shortestSide * 0.12 + maxRadius * phase;
      final alpha = (1.0 - phase).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = color.withValues(alpha: color.a * alpha * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Call control button
// ─────────────────────────────────────────────────────────────────────────────

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color? activeColor;
  final String label;
  final VoidCallback onTap;

  const _CallControlButton({
    required this.icon,
    required this.isActive,
    this.activeColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        isActive ? (activeColor ?? const Color(0xFF00C6FF)) : Colors.white;
    final bgColor = isActive
        ? (activeColor ?? const Color(0xFF00C6FF)).withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? (activeColor ?? const Color(0xFF00C6FF))
                        .withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: effectiveColor, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
