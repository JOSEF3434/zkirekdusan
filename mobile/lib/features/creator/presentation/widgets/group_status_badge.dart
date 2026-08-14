// lib/features/creator/presentation/widgets/group_status_badge.dart
import 'package:flutter/material.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';

class GroupStatusBadge extends StatelessWidget {
  final GroupStatus status;

  const GroupStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    IconData icon;

    switch (status) {
      case GroupStatus.pendingApproval:
        label = 'Pending Review';
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case GroupStatus.active:
        label = 'Active';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case GroupStatus.suspended:
        label = 'Suspended';
        color = Colors.red;
        icon = Icons.block;
        break;
      case GroupStatus.archived:
        label = 'Archived';
        color = Colors.grey;
        icon = Icons.archive;
        break;
      case GroupStatus.rejected:
        label = 'Rejected';
        color = Colors.red.shade900;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
