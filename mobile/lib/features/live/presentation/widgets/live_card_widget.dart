import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/presentation/widgets/live_badge_widget.dart';
import 'package:mobile/features/live/presentation/widgets/viewer_count_widget.dart';
import 'package:mobile/features/live/presentation/providers/scheduled_live_sync_provider.dart';

class LiveCardWidget extends ConsumerWidget {
  final LiveStreamDto stream;
  final bool horizontal; // true for home row, false for full-width discover

  const LiveCardWidget({
    super.key,
    required this.stream,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watch ticker and sync state for real-time live transition
    ref.watch(scheduledCountdownTickerProvider);
    final syncMap = ref.watch(scheduledLiveSyncProvider);
    final effectiveStatus = syncMap[stream.id] ?? stream.status;

    return GestureDetector(
      onTap: () => context.push('/live/${stream.id}'),
      child: horizontal
          ? _buildHorizontalCard(theme, effectiveStatus: effectiveStatus)
          : _buildVerticalCard(theme, effectiveStatus: effectiveStatus),
    );
  }

  Widget _buildHorizontalCard(ThemeData theme, {required LiveStreamStatus effectiveStatus}) {
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
          _thumbnail(height: 124, radius: 12, onlyTop: true, effectiveStatus: effectiveStatus),
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

  Widget _buildVerticalCard(ThemeData theme, {required LiveStreamStatus effectiveStatus}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumbnail(height: 190, radius: 14, onlyTop: true, effectiveStatus: effectiveStatus),
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
    required LiveStreamStatus effectiveStatus,
  }) {
    final borderRadius = onlyTop
        ? BorderRadius.vertical(top: Radius.circular(radius))
        : BorderRadius.circular(radius);

    final isLive = effectiveStatus == LiveStreamStatus.live;
    final isEnded = effectiveStatus == LiveStreamStatus.ended;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: borderRadius,
          child: stream.thumbnailUrl != null
              ? AppNetworkImage(
                  imageUrl: stream.thumbnailUrl!,
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _fallbackThumb(height),
                )
              : _fallbackThumb(height),
        ),
        if (isEnded)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Container(color: Colors.black54),
            ),
          ),
        // Badge: LIVE vs ENDED vs SCHEDULED
        Positioned(
          top: 8,
          left: 8,
          child: isLive
              ? const LiveBadgeWidget(small: true)
              : isEnded
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stop_circle_outlined, size: 10, color: Colors.white70),
                          SizedBox(width: 4),
                          Text(
                            'ENDED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 10, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'SCHEDULED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
        if (isLive)
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
              ? AppNetworkImage.provider(avatarUrl)
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
