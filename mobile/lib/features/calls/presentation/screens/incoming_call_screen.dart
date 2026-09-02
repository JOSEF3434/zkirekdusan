// lib/features/calls/presentation/screens/incoming_call_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/calls/providers/call_state_provider.dart';
import 'package:mobile/features/calls/services/call_service.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callStateProvider);
    final callService = ref.watch(callServiceProvider);

    // If caller cancels or call changes status, pop
    ref.listen<CallState>(callStateProvider, (previous, next) {
      if (next.status == CallStatus.ended || next.status == CallStatus.idle) {
        if (mounted && Navigator.canPop(context)) {
          context.pop();
        }
      } else if (next.status == CallStatus.connected || next.status == CallStatus.connecting) {
        if (mounted) {
          context.pushReplacement('/call/active');
        }
      }
    });

    final displayName = callState.remoteDisplayName ?? 'Unknown Caller';
    final avatarUrl = callState.remoteAvatarUrl;
    final isVideo = callState.isVideoCall;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          callService.rejectCall();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Stack(
          children: [
            // Background Layer: Blurred Avatar or Gradient
            Positioned.fill(
              child: Stack(
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
                          center: Alignment(0, -0.2),
                          radius: 1.2,
                          colors: [Color(0xFF1E293B), Color(0xFF090D16)],
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Call Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVideo ? Icons.videocam_rounded : Icons.phone_in_talk_rounded,
                          color: const Color(0xFF00C6FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isVideo ? 'INCOMING VIDEO CALL' : 'INCOMING AUDIO CALL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Center Ripple Waves + Avatar
                  Center(
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple 1
                          AnimatedBuilder(
                            animation: _rippleController,
                            builder: (context, child) {
                              final progress = _rippleController.value;
                              return Container(
                                width: 140 + (120 * progress),
                                height: 140 + (120 * progress),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00C6FF)
                                        .withValues(alpha: (1.0 - progress) * 0.5),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Ripple 2
                          AnimatedBuilder(
                            animation: _rippleController,
                            builder: (context, child) {
                              final progress = (_rippleController.value + 0.5) % 1.0;
                              return Container(
                                width: 140 + (120 * progress),
                                height: 140 + (120 * progress),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00C6FF)
                                        .withValues(alpha: (1.0 - progress) * 0.4),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Avatar
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C6FF).withValues(alpha: 0.4),
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
                                          _buildFallbackAvatar(displayName),
                                    )
                                  : _buildFallbackAvatar(displayName),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zikre Kidusan Call',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bottom Action Buttons: Decline (Red) & Accept (Green)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Decline Button
                        _ActionColumn(
                          icon: Icons.call_end_rounded,
                          color: const Color(0xFFEF4444),
                          label: 'Decline',
                          onTap: () {
                            callService.rejectCall();
                            if (mounted && Navigator.canPop(context)) {
                              context.pop();
                            }
                          },
                        ),

                        // Accept Button
                        _ActionColumn(
                          icon: isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                          color: const Color(0xFF10B981),
                          label: 'Accept',
                          onTap: () async {
                            await callService.acceptCall();
                            if (!context.mounted) return;
                            context.pushReplacement('/call/active');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return Container(
      color: const Color(0xFF1B2230),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ActionColumn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionColumn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
