// lib/features/chats/presentation/widgets/chat_activity_indicator.dart
//
// Telegram-style animated activity indicators for chat:
// - typing (edit/pencil + animated bouncing dots)
// - recording audio (mic + animated bouncing dots)
// - sending photo (image + animated bouncing dots)
// - sending video (videocam + animated bouncing dots)
// - sending audio (audiotrack + animated bouncing dots)
// - sending file (insert_drive_file + animated bouncing dots)

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Centralized mapping and normalization of activity types.
class ChatActivityHelper {
  ChatActivityHelper._();

  static const Color primaryColor = Color(0xFF00C6FF);

  /// Normalizes any raw activity string into a user-friendly label.
  /// Guarantees that generic 'active...' is NEVER shown.
  static String getLabel(String? rawActivity, {bool includeEllipsis = false}) {
    final activity = (rawActivity ?? 'typing').trim().toLowerCase();
    final suffix = includeEllipsis ? '...' : '';

    if (activity == 'typing' || activity == 'text') {
      return 'typing$suffix';
    }
    if (activity == 'recording_audio' ||
        activity == 'recording_voice' ||
        activity == 'recording' ||
        activity == 'voice_recording' ||
        activity.contains('record') ||
        activity.contains('voice')) {
      return 'recording audio$suffix';
    }
    if (activity == 'uploading_photo' ||
        activity == 'sending_photo' ||
        activity == 'uploading_image' ||
        activity == 'sending_image' ||
        activity.contains('photo') ||
        activity.contains('image')) {
      return 'sending photo$suffix';
    }
    if (activity == 'uploading_video' ||
        activity == 'sending_video' ||
        activity.contains('video')) {
      return 'sending video$suffix';
    }
    if (activity == 'uploading_audio' ||
        activity == 'sending_audio' ||
        activity.contains('audio') ||
        activity.contains('music')) {
      return 'sending audio$suffix';
    }
    if (activity == 'uploading_file' ||
        activity == 'uploading_media' ||
        activity == 'sending_file' ||
        activity == 'sending_document' ||
        activity == 'uploading_document' ||
        activity.contains('file') ||
        activity.contains('doc')) {
      return 'sending file$suffix';
    }

    // Fallback: If unknown, default to typing rather than ambiguous 'active...'
    return 'typing$suffix';
  }

  /// Returns the corresponding Telegram-style icon for the activity.
  static IconData getIcon(String? rawActivity) {
    final activity = (rawActivity ?? 'typing').trim().toLowerCase();

    if (activity == 'recording_audio' ||
        activity == 'recording_voice' ||
        activity == 'recording' ||
        activity == 'voice_recording' ||
        activity.contains('record') ||
        activity.contains('voice')) {
      return Icons.mic_rounded;
    }
    if (activity == 'uploading_photo' ||
        activity == 'sending_photo' ||
        activity == 'uploading_image' ||
        activity == 'sending_image' ||
        activity.contains('photo') ||
        activity.contains('image')) {
      return Icons.image_rounded;
    }
    if (activity == 'uploading_video' ||
        activity == 'sending_video' ||
        activity.contains('video')) {
      return Icons.videocam_rounded;
    }
    if (activity == 'uploading_audio' ||
        activity == 'sending_audio' ||
        activity.contains('audio') ||
        activity.contains('music')) {
      return Icons.audiotrack_rounded;
    }
    if (activity == 'uploading_file' ||
        activity == 'uploading_media' ||
        activity == 'sending_file' ||
        activity == 'sending_document' ||
        activity == 'uploading_document' ||
        activity.contains('file') ||
        activity.contains('doc')) {
      return Icons.insert_drive_file_rounded;
    }

    return Icons.edit_note_rounded;
  }
}

/// A lightweight, 60fps 3-dot bouncing animation widget.
class BouncingDotsIndicator extends StatefulWidget {
  final double dotSize;
  final double bounceHeight;
  final Color color;
  final Duration duration;

  const BouncingDotsIndicator({
    super.key,
    this.dotSize = 3.5,
    this.bounceHeight = 3.5,
    this.color = const Color(0xFF00C6FF),
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<BouncingDotsIndicator> createState() => _BouncingDotsIndicatorState();
}

class _BouncingDotsIndicatorState extends State<BouncingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            // Sinusoidal phase offset for each dot (0, pi/3, 2*pi/3)
            final phase = i * (math.pi / 3);
            final value = math.sin((_controller.value * 2 * math.pi) + phase);
            final offsetY = -widget.bounceHeight * math.max(0.0, value);

            return Transform.translate(
              offset: Offset(0, offsetY),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                margin: const EdgeInsets.symmetric(horizontal: 1.2),
                decoration: BoxDecoration(
                  color: widget.color.withValues(
                    alpha: 0.6 + 0.4 * math.max(0.0, value),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// A compact row displaying an activity icon, formatted label, and animated bouncing dots.
/// Perfect for conversation list item subtitles, AppBar subtitles, and user headers.
class ChatActivityRow extends StatelessWidget {
  final String activity;
  final double fontSize;
  final double iconSize;
  final Color color;
  final FontWeight fontWeight;
  final bool isDark;

  const ChatActivityRow({
    super.key,
    required this.activity,
    this.fontSize = 13,
    this.iconSize = 14,
    this.color = const Color(0xFF00C6FF),
    this.fontWeight = FontWeight.w600,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final icon = ChatActivityHelper.getIcon(activity);
    final label = ChatActivityHelper.getLabel(activity, includeEllipsis: false);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontStyle: FontStyle.italic,
            fontWeight: fontWeight,
          ),
        ),
        const SizedBox(width: 3),
        BouncingDotsIndicator(
          dotSize: fontSize * 0.28,
          bounceHeight: fontSize * 0.28,
          color: color,
        ),
      ],
    );
  }
}

/// Telegram-style floating activity bubble displayed above the message composer.
class ChatActivityBubble extends StatelessWidget {
  final String activity;
  final bool isDark;

  const ChatActivityBubble({
    super.key,
    required this.activity,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final icon = ChatActivityHelper.getIcon(activity);
    final label = ChatActivityHelper.getLabel(activity, includeEllipsis: false);
    const color = Color(0xFF00C6FF);

    return Container(
      key: ValueKey('activity_bubble_$activity'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      margin: const EdgeInsets.only(left: 16, bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: color,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const BouncingDotsIndicator(
            dotSize: 3.5,
            bounceHeight: 3.5,
            color: color,
          ),
        ],
      ),
    );
  }
}
