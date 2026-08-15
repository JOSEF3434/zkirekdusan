// lib/features/creator_analytics/presentation/widgets/video_status_badge.dart
import 'package:flutter/material.dart';
import 'package:mobile/features/creator_analytics/domain/creator_video_dto.dart';

class VideoStatusBadge extends StatelessWidget {
  final CreatorVideoStatus status;
  final bool compact;

  const VideoStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.isProcessing) ...[
            SizedBox(
              width: compact ? 8 : 12,
              height: compact ? 8 : 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            status.value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 9 : 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case CreatorVideoStatus.uploading:
      case CreatorVideoStatus.queued:
        return Colors.orange;
      case CreatorVideoStatus.processing:
        return Colors.blue;
      case CreatorVideoStatus.ready:
        return Colors.green;
      case CreatorVideoStatus.failed:
      case CreatorVideoStatus.deleted:
        return Colors.red;
    }
  }
}

class VisibilityBadge extends StatelessWidget {
  final CreatorVideoVisibility visibility;

  const VisibilityBadge({super.key, required this.visibility});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getIcon(), size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          visibility.value,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  IconData _getIcon() {
    switch (visibility) {
      case CreatorVideoVisibility.public:
        return Icons.public;
      case CreatorVideoVisibility.private:
        return Icons.lock;
      case CreatorVideoVisibility.unlisted:
        return Icons.link;
      case CreatorVideoVisibility.groupOnly:
        return Icons.group;
      case CreatorVideoVisibility.scheduled:
        return Icons.schedule;
    }
  }
}
