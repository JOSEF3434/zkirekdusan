// lib/features/creator_analytics/presentation/widgets/creator_video_tile.dart
import 'package:flutter/material.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/creator_analytics/domain/creator_video_dto.dart';
import 'package:mobile/features/creator_analytics/presentation/widgets/video_status_badge.dart';

class CreatorVideoTile extends StatelessWidget {
  final CreatorVideoDto video;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPublish;

  const CreatorVideoTile({
    super.key,
    required this.video,
    required this.onEdit,
    required this.onDelete,
    this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Open edit screen by default on tap
          onEdit();
        },
        onLongPress: () {
          onEdit();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 140,
                  height: 90,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: video.thumbnailUrl != null
                      ? AppNetworkImage(
                          imageUrl: video.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) =>
                              const Icon(Icons.broken_image),
                        )
                      : const Icon(Icons.video_file, size: 40),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title.isEmpty ? 'Untitled Video' : video.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            VideoStatusBadge(
                              status: video.status,
                              compact: true,
                            ),
                            const SizedBox(width: 8),
                            VisibilityBadge(visibility: video.visibility),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${video.viewsCount} views • ${video.likesCount} likes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                    if (val == 'publish') onPublish?.call();
                    if (val == 'comments') {
                      context.push(
                        '/creator/dashboard/video/${video.videoChannelId}/${video.id}/comments',
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'comments',
                      child: Row(
                        children: [
                          Icon(Icons.comment, size: 20),
                          SizedBox(width: 8),
                          Text('Moderate Comments'),
                        ],
                      ),
                    ),
                    if (video.status.canPublish &&
                        onPublish != null &&
                        video.visibility != CreatorVideoVisibility.public)
                      const PopupMenuItem(
                        value: 'publish',
                        child: Row(
                          children: [
                            Icon(Icons.public, size: 20),
                            SizedBox(width: 8),
                            Text('Publish Now'),
                          ],
                        ),
                      ),
                    if (video.status.canDelete)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
