// lib/features/live/presentation/widgets/live_badge_widget.dart
// Animated pulsing LIVE badge for stream cards and player overlay.

import 'package:flutter/material.dart';

class LiveBadgeWidget extends StatefulWidget {
  final bool small;
  const LiveBadgeWidget({super.key, this.small = false});

  @override
  State<LiveBadgeWidget> createState() => _LiveBadgeWidgetState();
}

class _LiveBadgeWidgetState extends State<LiveBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double dotSize = widget.small ? 6 : 8;
    final double fontSize = widget.small ? 10 : 12;
    final double hPad = widget.small ? 5 : 7;
    final double vPad = widget.small ? 2 : 3;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Opacity(
              opacity: _pulse.value,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
