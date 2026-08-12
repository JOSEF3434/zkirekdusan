// lib/features/live/presentation/widgets/stream_health_indicator.dart

import 'package:flutter/material.dart';
import 'package:mobile/features/live/domain/stream_health_model.dart';

class StreamHealthIndicator extends StatelessWidget {
  final StreamHealthDto? health;
  final bool compact;

  const StreamHealthIndicator({
    super.key,
    required this.health,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (health == null) {
      return const SizedBox.shrink();
    }

    final (color, label, icon) = switch (health!.health) {
      StreamHealthLevel.good => (
          const Color(0xFF4CAF50),
          'Good',
          Icons.signal_wifi_4_bar
        ),
      StreamHealthLevel.fair => (
          const Color(0xFFFFC107),
          'Fair',
          Icons.network_wifi_3_bar
        ),
      StreamHealthLevel.poor => (
          const Color(0xFFE53935),
          'Poor',
          Icons.signal_wifi_bad
        ),
      StreamHealthLevel.unknown => (
          Colors.grey,
          'Unknown',
          Icons.signal_wifi_off
        ),
    };

    if (compact) {
      return Icon(icon, color: color, size: 18);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(health!.avgBandwidth / 1000).toStringAsFixed(1)} Mbps',
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
