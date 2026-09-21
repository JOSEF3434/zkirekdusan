// lib/features/notifications/presentation/widgets/notification_tile.dart
// Reusable notification tile with type-specific icon, unread indicator,
// timestamp, and dismiss/swipe actions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/notifications/domain/notification_model.dart';

class NotificationTile extends ConsumerWidget {
  final NotificationResponseDto notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final languageCode = ref.watch(
      preferencesProvider.select((state) => state.languageCode),
    );

    final icon = _getIconForType(notification.type);
    final iconColor = _getColorForType(notification.type, cs);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: cs.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead
              ? null
              : cs.primaryContainer.withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with colored background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.localizedTitle(languageCode),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.localizedBody(languageCode),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(notification.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'LIKE':
        return Icons.favorite_rounded;
      case 'COMMENT':
        return Icons.comment_rounded;
      case 'FOLLOW':
        return Icons.person_add_rounded;
      case 'MESSAGE':
        return Icons.chat_bubble_rounded;
      case 'MENTION':
        return Icons.alternate_email_rounded;
      case 'REACTION':
        return Icons.emoji_emotions_rounded;
      case 'GROUP_INVITE':
      case 'GROUP_JOIN_REQUEST':
      case 'GROUP_APPROVE':
        return Icons.group_rounded;
      case 'STREAM_LIVE':
        return Icons.live_tv_rounded;
      case 'VIDEO_READY':
        return Icons.video_library_rounded;
      case 'SYSTEM':
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type, ColorScheme cs) {
    switch (type.toUpperCase()) {
      case 'LIKE':
        return Colors.pink;
      case 'COMMENT':
        return cs.secondary;
      case 'FOLLOW':
        return cs.primary;
      case 'MESSAGE':
      case 'MENTION':
        return Colors.teal;
      case 'REACTION':
        return Colors.orange;
      case 'GROUP_INVITE':
      case 'GROUP_JOIN_REQUEST':
      case 'GROUP_APPROVE':
        return Colors.purple;
      case 'STREAM_LIVE':
        return cs.error;
      case 'VIDEO_READY':
        return Colors.indigo;
      case 'SYSTEM':
      default:
        return cs.primary;
    }
  }
}

// ── Notification Skeleton ─────────────────────────────────────────────────────

class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmer = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);

    Widget block({double w = double.infinity, double h = 12}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Column(
      children: List.generate(
        6,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 22, backgroundColor: shimmer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(w: 200),
                    const SizedBox(height: 6),
                    block(w: double.infinity, h: 10),
                    const SizedBox(height: 4),
                    block(w: 100, h: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
