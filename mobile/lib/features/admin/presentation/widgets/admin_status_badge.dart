// lib/features/admin/presentation/widgets/admin_status_badge.dart

import 'package:flutter/material.dart';

class AdminStatusBadge extends StatelessWidget {
  final String status;

  const AdminStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _getBadgeConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (String, Color) _getBadgeConfig(String rawStatus) {
    switch (rawStatus.toUpperCase()) {
      case 'ACTIVE':
      case 'PUBLISHED':
      case 'RESOLVED':
        return (rawStatus, Colors.green);
      case 'PENDING':
      case 'PENDING_APPROVAL':
      case 'REVIEWING':
        return (rawStatus, Colors.orange);
      case 'SUSPENDED':
      case 'DISMISSED':
      case 'ARCHIVED':
        return (rawStatus, Colors.blueGrey);
      case 'BANNED':
      case 'REJECTED':
      case 'ENDED':
      case 'DELETED':
        return (rawStatus, Colors.red);
      default:
        return (rawStatus, Colors.grey);
    }
  }
}
