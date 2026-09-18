// lib/features/calls/presentation/screens/call_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Offset _pipPosition = const Offset(20, 60);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
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

    // If call has ended, pop the screen
    ref.listen<CallState>(callStateProvider, (previous, next) {
      if (next.status == CallStatus.ended || next.status == CallStatus.idle) {
        if (mounted && Navigator.canPop(context)) {
          context.pop();
        }
      }
    });

    final isVideo = callState.isVideoCall;
    final isConnected = callState.status == CallStatus.connected;
    final displayName = callState.remoteDisplayName ?? 'User';
    final avatarUrl = callState.remoteAvatarUrl;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Stack(
          children: [
            // Background Layer: Video Stream OR Blurred Background for Audio Call
            if (isVideo && isConnected)
              Positioned.fill(
                child: RTCVideoView(
                  callService.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              _buildBlurredBackground(avatarUrl),

            // Top Header: Back button + Call Status & Duration
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        if (mounted && Navigator.canPop(context)) {
                          context.pop();
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVideo ? Icons.videocam : Icons.phone_in_talk,
                            color: const Color(0xFF00C6FF),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(callState),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), // balance header
                  ],
                ),
              ),
            ),

            // Center Content: Avatar & Caller Info (when Audio or not yet connected)
            if (!isVideo || !isConnected)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing Avatar
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: isConnected ? 1.0 : _pulseAnimation.value,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00C6FF),
                                    Color(0xFF0072FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00C6FF,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipOval(
                                child: avatarUrl != null && avatarUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: avatarUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            _buildAvatarFallback(displayName),
                                      )
                                    : _buildAvatarFallback(displayName),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStatusSubtitle(callState),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Video Call: Local PiP Preview (Draggable)
            if (isVideo && isConnected && callState.isVideoEnabled)
              Positioned(
                right: _pipPosition.dx,
                bottom: _pipPosition.dy + 120,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _pipPosition = Offset(
                        (_pipPosition.dx - details.delta.dx).clamp(16.0, 200.0),
                        (_pipPosition.dy - details.delta.dy).clamp(16.0, 400.0),
                      );
                    });
                  },
                  child: Container(
                    width: 110,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RTCVideoView(
                      callService.localRenderer,
                      mirror: callState.isFrontCamera,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // Bottom Controls Bar (Glassmorphic)
            Positioned(
              left: 20,
              right: 20,
              bottom: 36,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161C28).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute Mic
                        _CallControlButton(
                          icon: callState.isMuted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          isActive: callState.isMuted,
                          activeColor: Colors.redAccent,
                          label: tr('calls.mute'),
                          onTap: () => callService.toggleMute(),
                        ),

                        // Speakerphone
                        _CallControlButton(
                          icon: callState.isSpeakerOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_down_rounded,
                          isActive: callState.isSpeakerOn,
                          activeColor: const Color(0xFF00C6FF),
                          label: tr('calls.speaker'),
                          onTap: () => callService.toggleSpeaker(),
                        ),

                        // Video Toggle (if Video Call)
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
                        ],

                        // End Call (Red Button)
                        GestureDetector(
                          onTap: () {
                            callService.hangUp();
                            if (mounted && Navigator.canPop(context)) {
                              context.pop();
                            }
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x66EF4444),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredBackground(String? avatarUrl) {
    return Stack(
      children: [
        if (avatarUrl != null && avatarUrl.isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: avatarUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  Container(color: const Color(0xFF0F141C)),
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF1E293B), Color(0xFF090D16)],
              ),
            ),
          ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.black.withValues(alpha: 0.65)),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFF1B2230),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getStatusText(CallState state) {
    final tr = ref.read(trProvider);
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

  String _getStatusSubtitle(CallState state) {
    final tr = ref.read(trProvider);
    switch (state.status) {
      case CallStatus.calling:
        return tr('calls.waiting');
      case CallStatus.ringing:
        return tr('calls.incoming');
      case CallStatus.connecting:
        return tr('calls.establishing');
      case CallStatus.connected:
        return tr('calls.encrypted');
      case CallStatus.ended:
        return state.endReason == 'offline'
            ? tr('calls.offline')
            : state.endReason == 'busy'
            ? tr('calls.busy')
            : tr('calls.completed');
      case CallStatus.idle:
        return '';
    }
  }
}

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
    final effectiveColor = isActive
        ? (activeColor ?? const Color(0xFF00C6FF))
        : Colors.white.withValues(alpha: 0.85);

    final bgColor = isActive
        ? (activeColor ?? const Color(0xFF00C6FF)).withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: effectiveColor, size: 22),
          ),
          const SizedBox(height: 4),
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
