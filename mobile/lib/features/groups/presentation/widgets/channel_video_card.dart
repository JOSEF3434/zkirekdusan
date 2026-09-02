// lib/features/groups/presentation/widgets/channel_video_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/groups/domain/channel_video_dto.dart';

import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/home/presentation/widgets/video_management_sheet.dart';

class ChannelVideoCard extends StatelessWidget {
  final ChannelVideoDto video;
  final VoidCallback? onTap;
  final VoidCallback? onVideoDeleted;
  final VoidCallback? onVideoUpdated;

  const ChannelVideoCard({
    super.key,
    required this.video,
    this.onTap,
    this.onVideoDeleted,
    this.onVideoUpdated,
  });

  VideoResponseDto _toVideoResponseDto() {
    return VideoResponseDto(
      id: video.id,
      title: video.title,
      description: video.description,
      status: video.isReady
          ? VideoStatus.ready
          : (video.isProcessing ? VideoStatus.processing : VideoStatus.failed),
      visibility: video.visibility,
      duration: video.duration?.toInt() ?? 0,
      thumbnailUrl: video.thumbnailUrl,
      hlsUrl: video.hlsUrl,
      viewsCount: video.viewsCount,
      likesCount: video.likesCount,
      commentsCount: video.commentsCount,
      author: PostAuthorDto(
        id: video.uploadedById,
        username: video.uploaderUsername ?? 'channel',
        displayName: video.uploaderDisplayName ?? video.channelName ?? 'Channel',
      ),
      channelId: video.videoChannelId,
      channelName: video.channelName,
      createdAt: video.createdAt,
      updatedAt: video.createdAt,
    );
  }

  void _openManagementSheet(BuildContext context) {
    VideoManagementSheet.show(
      context,
      video: _toVideoResponseDto(),
      onVideoDeleted: onVideoDeleted,
      onVideoUpdated: onVideoUpdated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap ?? () => context.push('/video/${video.id}'),
      onLongPress: () => _openManagementSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with Duration & Status Badge
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: video.thumbnailUrl != null
                      ? Image.network(
                          video.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(theme),
                        )
                      : _buildPlaceholder(theme),
                ),
                // Status badge (Processing/Failed)
                if (video.isProcessing)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Processing',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Duration chip
                if (video.duration != null && video.duration! > 0)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.formattedDuration,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Video Title & Meta with 3-dots Menu Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${video.viewsCount} views • ${_formatDate(video.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                  onPressed: () => _openManagementSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 40,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
