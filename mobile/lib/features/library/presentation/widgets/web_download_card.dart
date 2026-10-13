// lib/features/library/presentation/widgets/web_download_card.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/presentation/widgets/video_thumbnail_widget.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/storage/web_download_helper.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/player/data/player_repository.dart';

class WebDownloadCard extends ConsumerStatefulWidget {
  final String videoId;
  final DownloadMetadata? metadata;

  /// When true renders a compact horizontal list-row instead of the vertical grid card.
  final bool isListView;

  const WebDownloadCard({
    super.key,
    required this.videoId,
    this.metadata,
    this.isListView = false,
  });

  @override
  ConsumerState<WebDownloadCard> createState() => _WebDownloadCardState();
}

class _WebDownloadCardState extends ConsumerState<WebDownloadCard> {
  bool _isHovered = false;
  bool _isBlobValid = true;
  bool _checkedBlob = false;
  bool _enqueuedEnrichment = false;

  @override
  void initState() {
    super.initState();
    _checkBlob();
    _enrichMetadataIfNeeded();
  }

  @override
  void didUpdateWidget(WebDownloadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metadata?.localPath != widget.metadata?.localPath) {
      _checkBlob();
    }
    if (oldWidget.metadata?.thumbnailUrl != widget.metadata?.thumbnailUrl ||
        oldWidget.videoId != widget.videoId) {
      _enqueuedEnrichment = false;
      _enrichMetadataIfNeeded();
    }
  }

  Future<void> _checkBlob() async {
    if (!kIsWeb) return;
    final path = widget.metadata?.localPath;
    if (path != null && path.startsWith('blob:')) {
      final valid = await WebDownloadHelper.isBlobUrlValid(path);
      if (mounted) {
        setState(() {
          _isBlobValid = valid;
          _checkedBlob = true;
        });
      }
    } else {
      if (mounted && !_checkedBlob) {
        setState(() {
          _checkedBlob = true;
        });
      }
    }
  }

  void _enrichMetadataIfNeeded() {
    if (_enqueuedEnrichment) return;
    final meta = widget.metadata;
    // If thumbnail or channelName is missing, fetch from repository
    if (meta == null ||
        meta.thumbnailUrl == null ||
        meta.thumbnailUrl!.trim().isEmpty ||
        meta.channelName == null) {
      _enqueuedEnrichment = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          final isOnline = ref.read(connectivityProvider).isOnline;
          if (!isOnline) return;

          final playerRepo = ref.read(playerRepositoryProvider);
          final dto = await playerRepo.getVideo(widget.videoId);
          final resolvedThumb = MediaUrlResolver.resolveThumbnail(
            thumbnailUrl: dto.thumbnailUrl,
            hlsUrl: dto.hlsUrl,
            renditionUrls: dto.renditions.map((r) => r.url).toList(),
          );
          final channelName = dto.channelName ??
              dto.author.displayName ??
              dto.author.username;

          if (mounted) {
            await ref.read(downloadServiceProvider.notifier).updateMetadata(
                  widget.videoId,
                  thumbnailUrl: resolvedThumb,
                  channelName: channelName,
                  title: dto.title,
                );
          }
        } catch (_) {
          // If remote fails, fallback gracefully without blocking UI
        }
      });
    }
  }

  void _handleCardTap(BuildContext context, ThemeData theme, String Function(String) tr) {
    final state = ref.read(downloadServiceProvider);
    final isDownloading = state.downloading.contains(widget.videoId);
    final isQueued = state.queued.contains(widget.videoId);
    final hasError = state.errors.containsKey(widget.videoId);

    if (hasError) {
      _showErrorDialog(context, tr);
      return;
    }

    if (isDownloading) {
      _showDownloadingDialog(context, tr, state.progress[widget.videoId] ?? 0.0);
      return;
    }

    if (isQueued) {
      _showQueuedDialog(context, tr);
      return;
    }

    // Completed download
    if (kIsWeb && !_isBlobValid) {
      final isOnline = ref.read(connectivityProvider).isOnline;
      if (!isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('downloads.web_info'),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    context.push('/video/${widget.videoId}');
  }

  void _showDownloadingDialog(BuildContext context, String Function(String) tr, double progress) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.metadata?.title ?? tr('downloads.status.downloading')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tr('downloads.status.downloading')} ${(progress * 100).toInt()}%'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              color: const Color(0xFF00C6FF),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(tr('common.cancel')),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(downloadServiceProvider.notifier).cancelDownload(widget.videoId);
            },
          ),
          FilledButton(
            child: Text(tr('common.ok')),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showQueuedDialog(BuildContext context, String Function(String) tr) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.metadata?.title ?? tr('downloads.status.queued')),
        content: Text(tr('downloads.status.queued')),
        actions: [
          TextButton(
            child: Text(tr('common.cancel')),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(downloadServiceProvider.notifier).cancelDownload(widget.videoId);
            },
          ),
          FilledButton(
            child: Text(tr('common.ok')),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String Function(String) tr) {
    final state = ref.read(downloadServiceProvider);
    final error = state.errors[widget.videoId] ?? tr('downloads.status.failed');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('downloads.status.failed')),
        content: Text(error),
        actions: [
          TextButton(
            child: Text(tr('downloads.delete')),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(downloadServiceProvider.notifier).deleteDownload(widget.videoId);
            },
          ),
          FilledButton(
            child: Text(tr('downloads.retry')),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(downloadServiceProvider.notifier).retryDownload(widget.videoId);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String Function(String) tr) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('downloads.delete')),
        content: Text(tr('downloads.clear_all_confirm')),
        actions: [
          TextButton(
            child: Text(tr('common.cancel')),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(tr('downloads.delete')),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(downloadServiceProvider.notifier).deleteDownload(widget.videoId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadServiceProvider);
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    final isDownloading = state.downloading.contains(widget.videoId);
    final isQueued = state.queued.contains(widget.videoId);
    final isPaused = state.paused.contains(widget.videoId);
    final error = state.errors[widget.videoId];
    final progress = state.progress[widget.videoId] ?? 0.0;
    final isCompleted = state.downloads.containsKey(widget.videoId) && !isDownloading && error == null;

    final resolvedMeta = widget.metadata ?? state.activeTasks[widget.videoId];
    final title = resolvedMeta?.title ?? 'Video ${widget.videoId}';
    final channelName = resolvedMeta?.channelName ?? 'Creator';
    final thumbnailUrl = resolvedMeta?.thumbnailUrl;
    final sizeBytes = resolvedMeta?.sizeBytes ?? 0;
    final localPath = resolvedMeta?.localPath;
    final effectiveVideoUrl = (localPath != null &&
            !localPath.startsWith('blob:') &&
            !localPath.startsWith('/'))
        ? localPath
        : null;

    final isExpiredSession = kIsWeb && isCompleted && !_isBlobValid;

    if (widget.isListView) {
      return _buildListCard(
        context: context,
        theme: theme,
        tr: tr,
        title: title,
        channelName: channelName,
        thumbnailUrl: thumbnailUrl,
        effectiveVideoUrl: effectiveVideoUrl,
        sizeBytes: sizeBytes,
        isDownloading: isDownloading,
        isQueued: isQueued,
        isPaused: isPaused,
        error: error,
        progress: progress,
        isCompleted: isCompleted,
        isExpiredSession: isExpiredSession,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: _isHovered ? 0.5 : 0.3,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _handleCardTap(context, theme, tr),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Thumbnail with rounded corners and download status overlays ──
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoThumbnailWidget(
                        thumbnailUrl: thumbnailUrl,
                        videoUrl: effectiveVideoUrl,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        fit: BoxFit.cover,
                      ),

                      // Overlay: Downloading State
                      if (isDownloading)
                        Container(
                          color: Colors.black.withValues(alpha: 0.65),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: CircularProgressIndicator(
                                        value: progress > 0 ? progress : null,
                                        strokeWidth: 3.5,
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF00C6FF),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.downloading_rounded,
                                        size: 14,
                                        color: Color(0xFF00C6FF),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tr('downloads.status.downloading'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      // Overlay: Queued State
                      else if (isQueued)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('downloads.status.queued'),
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      // Overlay: Paused State
                      else if (isPaused)
                        Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.pause_circle_filled_rounded,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('downloads.status.paused'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      // Overlay: Error State
                      else if (error != null)
                        Container(
                          color: Colors.black.withValues(alpha: 0.65),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 16,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('downloads.status.failed'),
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      // Badges for Completed State
                      else if (isCompleted) ...[
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF00C6FF),
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Downloaded',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (sizeBytes > 0)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        if (isExpiredSession)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade900.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.cloud_outlined,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tr('downloads.play_online'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                // ── Video Metadata & Actions Area ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        child: Text(
                          channelName.isNotEmpty ? channelName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title & Subtitles
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              channelName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Status / Size text
                            if (isDownloading)
                              Text(
                                '${tr('downloads.status.downloading')} ${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Color(0xFF00C6FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else if (isQueued)
                              Text(
                                tr('downloads.status.queued'),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else if (isPaused)
                              Text(
                                tr('downloads.status.paused'),
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else if (error != null)
                              Text(
                                '${tr('downloads.status.failed')} • ${tr('downloads.retry')}',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else if (isCompleted)
                              Text(
                                sizeBytes > 0
                                    ? tr('downloads.storage').replaceAll(
                                        '{0}',
                                        (sizeBytes / (1024 * 1024)).toStringAsFixed(1),
                                      )
                                    : tr('downloads.status.completed'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Contextual Menu
                      _buildMenu(context, tr, isCompleted, isDownloading, isPaused, isQueued, error),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── YouTube-style horizontal list row ──────────────────────────────────────

  Widget _buildListCard({
    required BuildContext context,
    required ThemeData theme,
    required String Function(String) tr,
    required String title,
    required String channelName,
    required String? thumbnailUrl,
    required String? effectiveVideoUrl,
    required int sizeBytes,
    required bool isDownloading,
    required bool isQueued,
    required bool isPaused,
    required String? error,
    required double progress,
    required bool isCompleted,
    required bool isExpiredSession,
  }) {
    Color pillColor;
    IconData pillIcon;
    String pillLabel;
    if (isDownloading) {
      pillColor = const Color(0xFF00C6FF);
      pillIcon = Icons.downloading_rounded;
      pillLabel = '${(progress * 100).toInt()}%';
    } else if (isQueued) {
      pillColor = Colors.amber.shade700;
      pillIcon = Icons.hourglass_top_rounded;
      pillLabel = tr('downloads.status.queued');
    } else if (isPaused) {
      pillColor = Colors.orange;
      pillIcon = Icons.pause_circle_outline_rounded;
      pillLabel = tr('downloads.status.paused');
    } else if (error != null) {
      pillColor = theme.colorScheme.error;
      pillIcon = Icons.error_outline_rounded;
      pillLabel = tr('downloads.status.failed');
    } else if (isCompleted) {
      pillColor = const Color(0xFF00C6FF);
      pillIcon = Icons.check_circle_rounded;
      pillLabel = tr('downloads.status.completed');
    } else {
      pillColor = theme.colorScheme.onSurfaceVariant;
      pillIcon = Icons.download_rounded;
      pillLabel = '...';
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final double thumbWidth = screenWidth < 380 ? 116.0 : (screenWidth < 600 ? 132.0 : 150.0);
    final double thumbHeight = thumbWidth * 9 / 16;
    final bool isCompact = screenWidth < 500;

    final actions = <Widget>[];
    if (isCompleted) {
      actions.add(
        _ListActionBtn(
          icon: Icons.play_arrow_rounded,
          color: const Color(0xFF00C6FF),
          tooltip: tr('offline.play'),
          onTap: () => context.push('/video/${widget.videoId}'),
        ),
      );
      actions.add(
        _ListActionBtn(
          icon: Icons.delete_outline_rounded,
          color: theme.colorScheme.error,
          tooltip: tr('downloads.delete'),
          onTap: () => _confirmDelete(context, tr),
        ),
      );
    } else if (isDownloading) {
      actions.add(
        _ListActionBtn(
          icon: Icons.pause_rounded,
          color: Colors.orange,
          tooltip: tr('downloads.status.paused'),
          onTap: () => ref
              .read(downloadServiceProvider.notifier)
              .pauseDownload(widget.videoId),
        ),
      );
      actions.add(
        _ListActionBtn(
          icon: Icons.close_rounded,
          color: theme.colorScheme.error,
          tooltip: tr('common.cancel'),
          onTap: () => ref
              .read(downloadServiceProvider.notifier)
              .cancelDownload(widget.videoId),
        ),
      );
    } else if (isPaused) {
      actions.add(
        _ListActionBtn(
          icon: Icons.play_arrow_rounded,
          color: Colors.orange,
          tooltip: tr('downloads.retry'),
          onTap: () => ref
              .read(downloadServiceProvider.notifier)
              .resumeDownload(widget.videoId),
        ),
      );
      actions.add(
        _ListActionBtn(
          icon: Icons.delete_outline_rounded,
          color: theme.colorScheme.error,
          tooltip: tr('downloads.delete'),
          onTap: () => _confirmDelete(context, tr),
        ),
      );
    } else if (error != null) {
      actions.add(
        _ListActionBtn(
          icon: Icons.refresh_rounded,
          color: theme.colorScheme.error,
          tooltip: tr('downloads.retry'),
          onTap: () => ref
              .read(downloadServiceProvider.notifier)
              .retryDownload(widget.videoId),
        ),
      );
      actions.add(
        _ListActionBtn(
          icon: Icons.delete_outline_rounded,
          color: theme.colorScheme.error,
          tooltip: tr('downloads.delete'),
          onTap: () => _confirmDelete(context, tr),
        ),
      );
    } else if (isQueued) {
      actions.add(
        _ListActionBtn(
          icon: Icons.close_rounded,
          color: theme.colorScheme.error,
          tooltip: tr('common.cancel'),
          onTap: () => ref
              .read(downloadServiceProvider.notifier)
              .cancelDownload(widget.videoId),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _isHovered
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
              : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.35)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        child: InkWell(
          onTap: () => _handleCardTap(context, theme, tr),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Thumbnail (responsive 16:9) ────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: thumbWidth,
                    height: thumbHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VideoThumbnailWidget(
                          thumbnailUrl: thumbnailUrl,
                          videoUrl: effectiveVideoUrl,
                          fit: BoxFit.cover,
                        ),
                        if (isDownloading || isQueued || isPaused || error != null)
                          Container(
                            color: Colors.black.withValues(alpha: 0.55),
                            child: isDownloading
                                ? Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        value: progress > 0 ? progress : null,
                                        strokeWidth: 2.5,
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF00C6FF),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      isPaused
                                          ? Icons.pause_rounded
                                          : isQueued
                                              ? Icons.hourglass_top_rounded
                                              : Icons.error_outline_rounded,
                                      color: isPaused
                                          ? Colors.orange
                                          : isQueued
                                              ? Colors.amber
                                              : theme.colorScheme.error,
                                      size: 28,
                                    ),
                                  ),
                          ),
                        if (isCompleted && _isHovered)
                          Container(
                            color: Colors.black.withValues(alpha: 0.35),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        if (sizeBytes > 0 && isCompleted)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (isExpiredSession)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade900.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.cloud_outlined,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ── Metadata ────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        channelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: pillColor.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: pillColor.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(pillIcon, size: 11, color: pillColor),
                            const SizedBox(width: 4),
                            Text(
                              pillLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: pillColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDownloading) ...[  
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress > 0 ? progress : null,
                            minHeight: 3,
                            color: const Color(0xFF00C6FF),
                            backgroundColor:
                                const Color(0xFF00C6FF).withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  // ── Action buttons (right side) ────────────────────────
                  isCompact
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            actions[0],
                            if (actions.length > 1) ...[
                              const SizedBox(height: 6),
                              actions[1],
                            ],
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            actions[0],
                            if (actions.length > 1) ...[
                              const SizedBox(width: 8),
                              actions[1],
                            ],
                          ],
                        ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Shared popup menu ───────────────────────────────────────────────────────

  Widget _buildMenu(
    BuildContext context,
    String Function(String) tr,
    bool isCompleted,
    bool isDownloading,
    bool isPaused,
    bool isQueued,
    String? error,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Options',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (action) {
        switch (action) {
          case 'play':
            context.push('/video/${widget.videoId}');
            break;
          case 'pause':
            ref.read(downloadServiceProvider.notifier).pauseDownload(widget.videoId);
            break;
          case 'resume':
            ref.read(downloadServiceProvider.notifier).resumeDownload(widget.videoId);
            break;
          case 'retry':
            ref.read(downloadServiceProvider.notifier).retryDownload(widget.videoId);
            break;
          case 'cancel':
            ref.read(downloadServiceProvider.notifier).cancelDownload(widget.videoId);
            break;
          case 'delete':
            _confirmDelete(context, tr);
            break;
        }
      },
      itemBuilder: (ctx) => [
        if (isCompleted)
          PopupMenuItem(
            value: 'play',
            child: Row(
              children: [
                const Icon(Icons.play_arrow_rounded, size: 18),
                const SizedBox(width: 8),
                Text(tr('offline.play')),
              ],
            ),
          ),
        if (isDownloading)
          PopupMenuItem(
            value: 'pause',
            child: Row(
              children: [
                const Icon(Icons.pause_rounded, size: 18),
                const SizedBox(width: 8),
                Text(tr('downloads.status.paused')),
              ],
            ),
          ),
        if (isPaused)
          PopupMenuItem(
            value: 'resume',
            child: Row(
              children: [
                const Icon(Icons.play_arrow_rounded, size: 18),
                const SizedBox(width: 8),
                Text(tr('downloads.retry')),
              ],
            ),
          ),
        if (error != null)
          PopupMenuItem(
            value: 'retry',
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded, size: 18),
                const SizedBox(width: 8),
                Text(tr('downloads.retry')),
              ],
            ),
          ),
        if (isDownloading || isQueued)
          PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Text(tr('common.cancel'), style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        if (isCompleted || error != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Text(tr('downloads.delete'), style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Compact, styled icon action button for list view row
class _ListActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? tooltip;
  final VoidCallback? onTap;

  const _ListActionBtn({
    required this.icon,
    required this.color,
    this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.12);

    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: color.withValues(alpha: 0.2),
        splashColor: color.withValues(alpha: 0.25),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(
        message: tooltip!,
        waitDuration: const Duration(milliseconds: 300),
        child: btn,
      );
    }
    return btn;
  }
}
