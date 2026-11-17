// lib/features/media_experience/presentation/widgets/download_status_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/widgets/video_thumbnail_widget.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/localization_service.dart';

class DownloadStatusTile extends ConsumerWidget {
  final String videoId;
  final DownloadMetadata? metadata;

  const DownloadStatusTile({super.key, required this.videoId, this.metadata});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadServiceProvider);
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    final isDownloading = state.downloading.contains(videoId);
    final error = state.errors[videoId];
    final progress = state.progress[videoId] ?? 0.0;
    final isCompleted = metadata != null && !isDownloading && error == null;

    final resolvedMeta = metadata ?? state.activeTasks[videoId];
    final title = resolvedMeta?.title ?? 'Video $videoId';
    final thumbnailUrl = resolvedMeta?.thumbnailUrl;

    return ListTile(
      leading: SizedBox(
        width: 80,
        height: 45,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoThumbnailWidget(
                thumbnailUrl: thumbnailUrl,
                videoUrl: resolvedMeta?.localPath,
                borderRadius: BorderRadius.circular(4),
                playIconSize: 20,
              ),
              if (isDownloading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            if (isDownloading) ...[
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00C6FF),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${tr('downloads.status.downloading')} ${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFF00C6FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (error != null) ...[
              Icon(
                Icons.error_outline_rounded,
                size: 15,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                tr('downloads.status.failed'),
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (isCompleted) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 15,
                color: Color(0xFF00C6FF),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  metadata?.publisherUsername != null
                      ? '@${metadata!.publisherUsername} • ${(metadata!.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                      : '${tr('downloads.status.completed')} • ${(metadata!.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCompleted)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              tooltip: 'Open Original Source',
              onPressed: () {
                final sourceId = metadata?.sourceId ?? (videoId.startsWith('post_') ? videoId.replaceFirst('post_', '') : videoId);
                if (metadata?.sourceType == 'POST' || videoId.startsWith('post_')) {
                  context.push('/post/$sourceId');
                } else {
                  context.push('/video/$sourceId');
                }
              },
            ),
          if (error != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: tr('downloads.retry'),
              onPressed: () {
                ref
                    .read(downloadServiceProvider.notifier)
                    .deleteDownload(videoId);
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: tr('downloads.delete'),
            onPressed: () {
              ref
                  .read(downloadServiceProvider.notifier)
                  .deleteDownload(videoId);
            },
          ),
        ],
      ),
      onTap: isCompleted
          ? () {
              final sourceId = metadata?.sourceId ?? (videoId.startsWith('post_') ? videoId.replaceFirst('post_', '') : videoId);
              if (metadata?.sourceType == 'POST' || videoId.startsWith('post_')) {
                context.push('/post/$sourceId');
              } else {
                context.push('/video/$sourceId');
              }
            }
          : null,
    );
  }
}
