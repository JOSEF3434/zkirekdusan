// lib/features/chats/presentation/widgets/telegram_call_dialog.dart

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TelegramCallDialog extends StatefulWidget {
  final String name;
  final String? avatarUrl;
  final bool isVideoCall;
  final bool isGroup;

  const TelegramCallDialog({
    super.key,
    required this.name,
    this.avatarUrl,
    this.isVideoCall = false,
    this.isGroup = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String name,
    String? avatarUrl,
    bool isVideoCall = false,
    bool isGroup = false,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Call',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      pageBuilder: (context, anim1, anim2) => TelegramCallDialog(
        name: name,
        avatarUrl: avatarUrl,
        isVideoCall: isVideoCall,
        isGroup: isGroup,
      ),
    );
  }

  @override
  State<TelegramCallDialog> createState() => _TelegramCallDialogState();
}

class _TelegramCallDialogState extends State<TelegramCallDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _callTimer;
  int _seconds = 0;
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  late bool _isVideoActive;

  @override
  void initState() {
    super.initState();
    _isVideoActive = widget.isVideoCall;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Simulate connection after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Background ambient glow
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 280 + (_pulseController.value * 40),
                    height: 280 + (_pulseController.value * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00C6FF).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Top Status Bar info
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'End-to-end encrypted',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Main Content: Avatar, Name, Status
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar with pulsing ring
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.all(4 + _pulseController.value * 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00C6FF).withValues(
                              alpha: 0.3 + (_pulseController.value * 0.4),
                            ),
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFF17212B),
                          backgroundImage: widget.avatarUrl != null &&
                                  widget.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(widget.avatarUrl!)
                              : null,
                          child: widget.avatarUrl == null ||
                                  widget.avatarUrl!.isEmpty
                              ? Text(
                                  widget.name.isNotEmpty
                                      ? widget.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Color(0xFF00C6FF),
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Name
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Status / Duration
                  Text(
                    _isConnected
                        ? _formatDuration(_seconds)
                        : (widget.isGroup ? 'Connecting room...' : 'Ringing...'),
                    style: TextStyle(
                      color: _isConnected
                          ? const Color(0xFF10B981)
                          : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Controls (Telegram Call UI)
            Positioned(
              bottom: 36,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  // Secondary Controls row (Mute, Speaker, Video)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRoundButton(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        isActive: _isMuted,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      _buildRoundButton(
                        icon: _isSpeakerOn
                            ? Icons.volume_up_rounded
                            : Icons.volume_down_rounded,
                        label: 'Speaker',
                        isActive: _isSpeakerOn,
                        onTap: () =>
                            setState(() => _isSpeakerOn = !_isSpeakerOn),
                      ),
                      _buildRoundButton(
                        icon: _isVideoActive
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        label: 'Video',
                        isActive: _isVideoActive,
                        onTap: () =>
                            setState(() => _isVideoActive = !_isVideoActive),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // End Call Button (Big Red Circle)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
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

  Widget _buildRoundButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
