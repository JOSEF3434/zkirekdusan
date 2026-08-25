// lib/features/home/presentation/widgets/video_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/env/env.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/social/presentation/widgets/like_button.dart';
import 'package:mobile/features/social/presentation/widgets/save_button.dart';
import 'package:mobile/features/social/presentation/widgets/share_button.dart';
import 'package:mobile/features/social/presentation/comments_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class VideoCard extends StatelessWidget {
  final VideoResponseDto video;
  final bool showActions;
  final bool isCompact;

  const VideoCard({
    super.key,
    required this.video,
    this.showActions = true,
    this.isCompact = false,
  });

  /// Resolve possibly-relative or localhost thumbnail URLs to the real API base.
  String? _resolveUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = Env.apiBaseUrl.replaceFirst(RegExp(r'/api$'), '');
    return raw.startsWith('/') ? '$base$raw' : '$base/$raw';
  }

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
                  if (video.thumbnailUrl != null &&
                      _resolveUrl(video.thumbnailUrl) != null)
                    CachedNetworkImage(
                      imageUrl: _resolveUrl(video.thumbnailUrl)!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(
                        Icons.video_library,
                        color: Colors.grey,
                        size: 48,
                      ),
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
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.download_outlined),
                                title: const Text('Download Offline'),
                                onTap: () {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Open the video to start download',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
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
