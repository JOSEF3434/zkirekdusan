// lib/features/stories/presentation/widgets/story_viewer_controls.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mobile/features/stories/data/models/story_model.dart';

class StoryViewerControls extends StatelessWidget {
  final StoryModel story;
  final int storyIndex;
  final int totalStories;
  final bool isOwner;
  final bool isMuted;
  final VoidCallback onClose;
  final VoidCallback onToggleMute;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final VoidCallback? onRepost;

  const StoryViewerControls({
    super.key,
    required this.story,
    required this.storyIndex,
    required this.totalStories,
    required this.isOwner,
    required this.isMuted,
    required this.onClose,
    required this.onToggleMute,
    this.onDelete,
    this.onArchive,
    this.onUnarchive,
    this.onRepost,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = story.author.avatarUrl;
    final displayName = story.author.effectiveName;
    final timeStr = timeago.format(story.createdAt, locale: 'en_short');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          // Name and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 3),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (totalStories > 1) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${storyIndex + 1}/$totalStories',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Video Mute Toggle
          if (story.isVideo)
            IconButton(
              icon: Icon(
                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: onToggleMute,
              tooltip: isMuted ? 'Unmute' : 'Mute',
            ),

          // Options Menu
          if (isOwner)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 22,
              ),
              onSelected: (val) {
                if (val == 'archive') {
                  onArchive?.call();
                } else if (val == 'unarchive') {
                  onUnarchive?.call();
                } else if (val == 'repost') {
                  onRepost?.call();
                } else if (val == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                if (!story.isArchived && onArchive != null)
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text('Archive Story'),
                      ],
                    ),
                  ),
                if (story.isArchived && onUnarchive != null)
                  const PopupMenuItem(
                    value: 'unarchive',
                    child: Row(
                      children: [
                        Icon(Icons.unarchive_outlined, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text('Remove from Archive'),
                      ],
                    ),
                  ),
                if (onRepost != null)
                  const PopupMenuItem(
                    value: 'repost',
                    child: Row(
                      children: [
                        Icon(Icons.repeat_rounded, color: Color(0xFF00C6FF), size: 20),
                        SizedBox(width: 8),
                        Text('Repost Story'),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete Story', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),

          // Close button
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: onClose,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}
