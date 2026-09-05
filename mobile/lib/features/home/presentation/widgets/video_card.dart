// lib/features/home/presentation/widgets/video_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/social/presentation/widgets/like_button.dart';
import 'package:mobile/features/social/presentation/widgets/save_button.dart';
import 'package:mobile/features/social/presentation/comments_sheet.dart';
import 'package:mobile/features/social/presentation/widgets/share_button.dart';
import 'package:mobile/features/media_experience/presentation/widgets/download_button.dart';
import 'package:mobile/features/home/presentation/widgets/video_management_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class VideoCard extends StatelessWidget {
  final VideoResponseDto video;
  final bool showActions;
  final bool isCompact;
  final VoidCallback? onVideoDeleted;
  final VoidCallback? onVideoUpdated;

  const VideoCard({
    super.key,
    required this.video,
    this.showActions = true,
    this.isCompact = false,
    this.onVideoDeleted,
    this.onVideoUpdated,
  });

  /// Resolve possibly-relative or localhost thumbnail URLs to the real API base.
  String? _resolveUrl(String? raw) => MediaUrlResolver.resolve(raw);

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    }
    if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    }
    return '$views views';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        context.push('/video/${video.id}');
      },
      onLongPress: () {
        VideoManagementSheet.show(context, video: video);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(isCompact ? 10 : 0),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Builder(
                    builder: (context) {
                      final resolvedThumb = MediaUrlResolver.resolveThumbnail(
                        thumbnailUrl: video.thumbnailUrl,
                        hlsUrl: video.hlsUrl,
                        renditionUrls:
                            video.renditions.map((r) => r.url).toList(),
                      );

                      if (resolvedThumb != null && resolvedThumb.isNotEmpty) {
                        return CachedNetworkImage(
                          imageUrl: resolvedThumb,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.surfaceContainerHighest,
                              theme.colorScheme.surfaceContainerHigh,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white70,
                              size: 36,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Duration Badge
                  if (video.duration > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Video Info
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 4 : 12,
              vertical: isCompact ? 8 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: isCompact ? 16 : 20,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: video.author.avatarUrl != null
                      ? CachedNetworkImageProvider(
                          _resolveUrl(video.author.avatarUrl)!)
                      : null,
                  child: video.author.avatarUrl == null
                      ? Text(
                          video.author.displayName?.isNotEmpty == true
                              ? video.author.displayName![0].toUpperCase()
                              : (video.author.username?.isNotEmpty == true
                                    ? video.author.username![0].toUpperCase()
                                    : '?'),
                          style: TextStyle(fontSize: isCompact ? 12 : 14),
                        )
                      : null,
                ),
                SizedBox(width: isCompact ? 8 : 12),

                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: isCompact ? 13.5 : 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${video.channelName ?? (video.author.displayName?.isNotEmpty == true ? video.author.displayName! : (video.author.username?.isNotEmpty == true ? video.author.username! : "Creator"))} • ${_formatViews(video.viewsCount)} • ${timeago.format(video.publishedAt ?? video.createdAt)}',
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: isCompact ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // More button
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    VideoManagementSheet.show(
                      context,
                      video: video,
                      onVideoDeleted: onVideoDeleted,
                      onVideoUpdated: onVideoUpdated,
                    );
                  },
                ),
              ],
            ),
          ),

          // Action Row
          if (showActions)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                LikeButton(
                  postId: video.id,
                  initialLikesCount: video.likesCount,
                  initialIsLiked: video.isLiked ?? false,
                  iconSize: 22,
                  defaultColor: theme.colorScheme.onSurfaceVariant,
                  isVideo: true,
                ),
                GestureDetector(
                  onTap: () {
                    CommentsSheet.show(context, video.id, isVideo: true);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatViews(
                          video.commentsCount,
                        ).replaceAll(' views', ''),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SaveButton(
                  postId: video.id,
                  initialIsSaved: video.isSaved ?? false,
                  iconSize: 22,
                  defaultColor: theme.colorScheme.onSurfaceVariant,
                  isVideo: true,
                ),
                DownloadButton(
                  video: video,
                  iconSize: 22,
                  defaultColor: theme.colorScheme.onSurfaceVariant,
                ),
                ShareButton(
                  postId: video.id,
                  title: video.title,
                  iconSize: 22,
                  defaultColor: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
