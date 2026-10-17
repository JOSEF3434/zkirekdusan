// lib/features/calls/presentation/widgets/floating_call_overlay.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/features/calls/providers/call_state_provider.dart';
import 'package:mobile/features/calls/services/call_service.dart';
import 'package:mobile/core/utils/localization_service.dart';

class FloatingCallOverlay extends ConsumerStatefulWidget {
  const FloatingCallOverlay({super.key});

  @override
  ConsumerState<FloatingCallOverlay> createState() => _FloatingCallOverlayState();
}

class _FloatingCallOverlayState extends ConsumerState<FloatingCallOverlay> {
  Offset _position = const Offset(16, 70);

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

    // Only display when a call is active and in collapsed mode
    if (!callState.isActive || !callState.isCollapsed) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final isVideo = callState.isVideoCall;
    final isConnected = callState.status == CallStatus.connected;
    final displayName = callState.remoteDisplayName ?? 'User';
    final avatarUrl = callState.remoteAvatarUrl;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final double newX =
                (_position.dx + details.delta.dx).clamp(8.0, screenSize.width - 240.0);
            final double newY =
                (_position.dy + details.delta.dy).clamp(40.0, screenSize.height - 120.0);
            _position = Offset(newX, newY);
          });
        },
        onTap: () {
          ref.read(callStateProvider.notifier).setCollapsed(false);
          ref.read(routerProvider).push('/call/active');
        },
        child: Material(
          color: Colors.transparent,
          elevation: 12,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: isVideo ? 200 : 220,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00C6FF).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: isVideo && isConnected
                    ? _buildVideoMini(callService, displayName)
                    : _buildAudioMini(
                        callService,
                        displayName,
                        avatarUrl,
                        isConnected,
                        callState,
                        tr,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioMini(
    CallService callService,
    String displayName,
    String? avatarUrl,
    bool isConnected,
    CallState callState,
    String Function(String) tr,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with speaking dot
        Stack(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                ),
              ),
              padding: const EdgeInsets.all(1.5),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _fallbackAvatar(displayName),
                      )
                    : _fallbackAvatar(displayName),
              ),
            ),
            if (isConnected)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        // Name & timer
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isConnected
                    ? _formatDuration(callState.callDuration)
                    : tr('calls.calling'),
                style: TextStyle(
                  color: isConnected
                      ? const Color(0xFF10B981)
                      : const Color(0xFF00C6FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // Mute toggle
        GestureDetector(
          onTap: () => callService.toggleMute(),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: callState.isMuted
                  ? Colors.redAccent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: callState.isMuted ? Colors.redAccent : Colors.white,
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 6),
        // End call button
        GestureDetector(
          onTap: () {
            callService.hangUp();
            ref.read(callStateProvider.notifier).setCollapsed(false);
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoMini(CallService callService, String displayName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: RTCVideoView(
              callService.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => callService.toggleMute(),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                callService.hangUp();
                ref.read(callStateProvider.notifier).setCollapsed(false);
              },
              child: const Icon(
                Icons.call_end_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fallbackAvatar(String name) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
