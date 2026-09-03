// lib/features/live/presentation/widgets/live_card_widget.dart
// Card displayed in discovery lists / home "LIVE NOW" section.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/presentation/widgets/live_badge_widget.dart';
import 'package:mobile/features/live/presentation/widgets/viewer_count_widget.dart';

class LiveCardWidget extends StatelessWidget {
  final LiveStreamDto stream;
  final bool horizontal; // true for home row, false for full-width discover

  const LiveCardWidget({
    super.key,
    required this.stream,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/live/${stream.id}'),
      child: horizontal
          ? _buildHorizontalCard(theme)
          : _buildVerticalCard(theme),
    );
  }

  Widget _buildHorizontalCard(ThemeData theme) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumbnail(height: 124, radius: 12, onlyTop: true),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stream.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                _channelRow(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumbnail(height: 190, radius: 14, onlyTop: true),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stream.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                _channelRow(theme),
                if (stream.categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: stream.categories
                        .take(3)
                        .map(
                          (c) => Chip(
                            label: Text(c),
                            labelStyle: const TextStyle(fontSize: 10),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail({
    required double height,
    required double radius,
    required bool onlyTop,
  }) {
    final borderRadius = onlyTop
        ? BorderRadius.vertical(top: Radius.circular(radius))
        : BorderRadius.circular(radius);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: borderRadius,
          child: stream.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: stream.thumbnailUrl!,
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _fallbackThumb(height),
                )
              : _fallbackThumb(height),
        ),
        // LIVE badge + viewer count overlay
        Positioned(top: 8, left: 8, child: const LiveBadgeWidget(small: true)),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ViewerCountWidget(
              count: stream.currentViewerCount,
              light: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackThumb(double height) {
    return Container(
      width: double.infinity,
      height: height,
      color: const Color(0xFF1A1A2E),
      child: const Icon(Icons.live_tv, color: Colors.white38, size: 40),
    );
  }

  Widget _channelRow(ThemeData theme) {
    final channelName =
        stream.videoChannel?.name ?? stream.group?.name ?? 'Unknown Channel';
    final avatarUrl = stream.videoChannel?.avatarUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundImage: avatarUrl != null
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: avatarUrl == null
              ? Text(
                  channelName.isNotEmpty ? channelName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 10),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            channelName,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
