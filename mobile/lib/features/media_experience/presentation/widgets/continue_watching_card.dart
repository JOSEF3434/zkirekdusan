// lib/features/media_experience/presentation/widgets/continue_watching_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/media_experience/domain/playback_progress.dart';
import 'package:mobile/features/media_experience/presentation/providers/continue_watching_provider.dart';
import 'package:mobile/features/media_experience/presentation/widgets/video_progress_overlay.dart';

class ContinueWatchingCard extends ConsumerWidget {
  final PlaybackProgress progress;
  final bool compact;

  const ContinueWatchingCard({
    super.key,
    required this.progress,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () => context.push('/video/${progress.videoId}'),
        child: Row(
          children: [
            SizedBox(
              width: compact ? 120 : 160,
              height: compact ? 68 : 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (progress.thumbnailUrl != null)
                    Image.network(
                      progress.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoProgressOverlay(progress: progress),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.videoTitle,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('continue_watching.remaining').replaceAll(
                      '{0}',
                      _formatDuration(progress.remainingSeconds),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ref
                    .read(continueWatchingProvider.notifier)
                    .removeItem(progress.videoId);
              },
              tooltip: tr('continue_watching.remove'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 32, color: Colors.white54),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return '$totalSeconds sec';
    final minutes = totalSeconds ~/ 60;
    return '$minutes min';
  }
}
