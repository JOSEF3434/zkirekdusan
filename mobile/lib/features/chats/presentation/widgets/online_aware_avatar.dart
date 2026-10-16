// lib/features/chats/presentation/widgets/online_aware_avatar.dart
//
// Telegram-style animated online status avatar.
// Shows a breathing green ring border when the contact is online and a
// subtle grey ring when offline. Optionally renders a small dot badge on the
// bottom-right corner of the avatar (Telegram-like).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A premium avatar widget that visually communicates online/offline status
/// using animated ring borders and an optional dot badge — inspired by Telegram.
class OnlineAwareAvatar extends StatefulWidget {
  final String name;
  final String? avatarUrl;
  final bool isOnline;

  /// Diameter of the avatar circle.
  final double size;

  /// If true, shows a small dot badge at bottom-right (Telegram-style).
  final bool showDotBadge;

  /// If true, shows the animated ring (broader ring style — good for headers).
  final bool showRing;

  /// Background color used for the dot badge border (should match list/header bg).
  final Color backgroundHighlightColor;

  const OnlineAwareAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.isOnline,
    this.size = 52,
    this.showDotBadge = true,
    this.showRing = false,
    this.backgroundHighlightColor = const Color(0xFF0E1621),
  });

  @override
  State<OnlineAwareAvatar> createState() => _OnlineAwareAvatarState();
}

class _OnlineAwareAvatarState extends State<OnlineAwareAvatar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late AnimationController _rippleController;
  late Animation<double> _rippleAnim;
  late Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    if (widget.isOnline) {
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(OnlineAwareAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline) {
        _pulseController.repeat(reverse: true);
        _rippleController.repeat();
      } else {
        _pulseController.stop();
        _rippleController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSize = widget.size + (widget.showRing ? 8 : 6);

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Ripple ring (online + ring mode only)
          if (widget.isOnline && widget.showRing)
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                final scale = 1.0 + _rippleAnim.value * 0.18;
                final r = (widget.size / 2) * scale;
                return Opacity(
                  opacity: _rippleOpacity.value,
                  child: Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Ring border
          AnimatedBuilder(
            animation: widget.isOnline
                ? _pulseAnim
                : const AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              final ringColor = widget.isOnline
                  ? Color.lerp(
                      const Color(0xFF10B981),
                      const Color(0xFF34D399),
                      _pulseAnim.value,
                    )!
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.10));

              final ringW =
                  widget.isOnline ? (widget.showRing ? 2.5 : 2.0) : 1.2;
              final glow =
                  widget.isOnline ? (_pulseAnim.value * (widget.showRing ? 10 : 6)) : 0.0;

              return Container(
                width: totalSize,
                height: totalSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: ringW),
                  boxShadow: widget.isOnline
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: _pulseAnim.value * 0.45),
                            blurRadius: glow,
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.all(2),
                child: child,
              );
            },
            child: _buildImage(isDark),
          ),

          // Dot badge
          if (widget.showDotBadge && widget.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: _PulsingDot(bg: widget.backgroundHighlightColor),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.avatarUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorWidget: (c, u, e) => _buildInitials(isDark),
        ),
      );
    }
    return _buildInitials(isDark);
  }

  Widget _buildInitials(bool isDark) {
    const gradients = [
      [Color(0xFF00C6FF), Color(0xFF0072FF)],
      [Color(0xFFF857A6), Color(0xFFFF5858)],
      [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      [Color(0xFF43E97B), Color(0xFF38F9D7)],
      [Color(0xFFFA709A), Color(0xFFFEE140)],
      [Color(0xFF667EEA), Color(0xFF764BA2)],
      [Color(0xFFFDA085), Color(0xFFF6D365)],
    ];
    final idx = widget.name.hashCode.abs() % gradients.length;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradients[idx],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'U',
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.size * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Pulsing dot badge ─────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color bg;
  const _PulsingDot({required this.bg});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10B981),
          border: Border.all(color: widget.bg, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.65),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Online status chip (for chat screen AppBar subtitle) ──────────────────────

/// Blinking "• online" or static "last seen Xm ago" for the chat header.
class OnlineStatusChip extends StatefulWidget {
  final bool isOnline;
  final String? lastSeen;

  const OnlineStatusChip({
    super.key,
    required this.isOnline,
    this.lastSeen,
  });

  @override
  State<OnlineStatusChip> createState() => _OnlineStatusChipState();
}

class _OnlineStatusChipState extends State<OnlineStatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isOnline) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(OnlineStatusChip old) {
    super.didUpdateWidget(old);
    if (widget.isOnline && !old.isOnline) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isOnline && old.isOnline) {
      _ctrl
        ..stop()
        ..value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt() {
    if (widget.lastSeen == null) return 'offline';
    try {
      final dt = DateTime.parse(widget.lastSeen!);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'last seen just now';
      if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'last seen ${diff.inHours}h ago';
      if (diff.inDays == 1) return 'last seen yesterday';
      return 'last seen ${diff.inDays}d ago';
    } catch (_) {
      return 'offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOnline) {
      return AnimatedBuilder(
        animation: _opacity,
        builder: (context, child) => Opacity(opacity: _opacity.value, child: child),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 5, top: 1),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF10B981),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF10B981),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const Text(
              'online',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      _fmt(),
      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
    );
  }
}

// Alias for math import suppression
// ignore: unused_element
const _kPi = math.pi;
