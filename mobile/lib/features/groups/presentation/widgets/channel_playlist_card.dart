// lib/features/groups/presentation/widgets/channel_playlist_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/groups/domain/channel_playlist_dto.dart';

class ChannelPlaylistCard extends StatelessWidget {
  final ChannelPlaylistDto playlist;
  final VoidCallback? onTap;

  const ChannelPlaylistCard({super.key, required this.playlist, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstItem = playlist.items.isNotEmpty ? playlist.items.first : null;
    final thumbnailUrl = firstItem?.videoThumbnailUrl;

    return InkWell(
      onTap: onTap ?? () => context.push('/playlists/${playlist.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playlist thumbnail stack
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: thumbnailUrl != null
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPlaceholder(theme),
                        )
                      : _buildPlaceholder(theme),
                ),
                // Overlay on the right side indicating playlist & count
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: 70,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.playlist_play,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${playlist.videosCount}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${playlist.videosCount} ${playlist.videosCount == 1 ? "video" : "videos"} • ${_formatDate(playlist.updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
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
          Icons.playlist_play,
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
