// lib/features/media_experience/presentation/widgets/download_status_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    final title = metadata?.title ?? 'Video $videoId';
    final thumbnailUrl = metadata?.thumbnailUrl;

    return ListTile(
      leading: Container(
        width: 80,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(4),
          image: thumbnailUrl != null
              ? DecorationImage(
                  image: NetworkImage(thumbnailUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: isDownloading
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDownloading)
            Text(
              tr('downloads.status.downloading'),
              style: TextStyle(color: theme.colorScheme.primary),
            )
          else if (error != null)
            Text(
              tr('downloads.status.failed'),
              style: TextStyle(color: theme.colorScheme.error),
            )
          else if (isCompleted)
            Text(
              tr('downloads.storage').replaceAll(
                '{0}',
                (metadata!.sizeBytes / (1024 * 1024)).toStringAsFixed(1),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: tr('downloads.retry'),
              onPressed: () {
                // To retry, we need the original URL which we don't store in metadata.
                // Normally we'd fetch the video again or store the URL.
                // For F10, we'll just clear the error to let the user re-initiate from the video page,
                // or we can remove it entirely from downloads state.
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
              context.push('/video/$videoId');
            }
          : null,
    );
  }
}
