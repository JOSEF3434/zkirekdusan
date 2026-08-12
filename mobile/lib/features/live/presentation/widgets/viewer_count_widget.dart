// lib/features/live/presentation/widgets/viewer_count_widget.dart

import 'package:flutter/material.dart';

class ViewerCountWidget extends StatelessWidget {
  final int count;
  final bool light;

  const ViewerCountWidget({super.key, required this.count, this.light = false});

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : Colors.black87;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.visibility, size: 14, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 3),
        Text(
          _format(count),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
