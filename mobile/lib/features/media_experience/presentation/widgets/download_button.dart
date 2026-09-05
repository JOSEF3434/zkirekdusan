// lib/features/media_experience/presentation/widgets/download_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/home/domain/video_model.dart';

class DownloadButton extends ConsumerWidget {
  final VideoResponseDto video;
  final double iconSize;
  final Color? defaultColor;

  const DownloadButton({
    super.key,
    required this.video,
    this.iconSize = 22.0,
    this.defaultColor,
  });

  void _handleTap(BuildContext context, WidgetRef ref, DownloadState downloadState) {
    final videoId = video.id;
    final isDownloading = downloadState.downloading.contains(videoId);
    final isCompleted = downloadState.downloads.containsKey(videoId);
    final progress = downloadState.progress[videoId] ?? 0.0;

    if (isCompleted) {
      _showCompletedOptions(context, ref, videoId);
      return;
    }

    if (isDownloading) {
      _showDownloadingOptions(context, ref, videoId, progress);
      return;
    }

    // Start download
    final downloadUrl = video.sourceFileUrl ?? video.hlsUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download URL is not available for this video.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final resolvedThumb = MediaUrlResolver.resolveThumbnail(
      thumbnailUrl: video.thumbnailUrl,
      hlsUrl: video.hlsUrl,
      renditionUrls: video.renditions.map((r) => r.url).toList(),
    );

    ref.read(downloadServiceProvider.notifier).startDownload(
      videoId: videoId,
      url: downloadUrl,
      title: video.title,
      thumbnailUrl: resolvedThumb,
      quality: '720p',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${video.title}" for offline playback...'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => context.push('/downloads'),
        ),
      ),
    );
  }

  void _showCompletedOptions(BuildContext context, WidgetRef ref, String videoId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline, color: Colors.teal),
              title: const Text('Play Offline'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/video/$videoId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Download'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(downloadServiceProvider.notifier).deleteDownload(videoId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video removed from offline storage.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadingOptions(
    BuildContext context,
    WidgetRef ref,
    String videoId,
    double progress,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Downloading ${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.red),
              title: const Text('Cancel Download'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(downloadServiceProvider.notifier).cancelDownload(videoId);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadServiceProvider);
    final theme = Theme.of(context);
    final themeColor = defaultColor ?? theme.colorScheme.onSurfaceVariant;

    final videoId = video.id;
    final isDownloading = downloadState.downloading.contains(videoId);
    final isCompleted = downloadState.downloads.containsKey(videoId);
    final progress = downloadState.progress[videoId] ?? 0.0;

    Widget iconWidget;
    String label;
    Color activeColor = themeColor;

    if (isCompleted) {
      activeColor = const Color(0xFF00C6FF);
      iconWidget = Icon(
        Icons.check_circle_rounded,
        color: activeColor,
        size: iconSize,
      );
      label = 'Downloaded';
    } else if (isDownloading) {
      activeColor = const Color(0xFF00C6FF);
      iconWidget = SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          value: progress > 0 ? progress : null,
          strokeWidth: 2.5,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
        ),
      );
      label = progress > 0 ? '${(progress * 100).toInt()}%' : 'Saving...';
    } else {
      iconWidget = Icon(
        Icons.download_for_offline_outlined,
        color: themeColor,
        size: iconSize,
      );
      label = 'Download';
    }

    return GestureDetector(
      onTap: () => _handleTap(context, ref, downloadState),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: activeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
