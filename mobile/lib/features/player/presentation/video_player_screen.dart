import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/features/player/presentation/providers/player_provider.dart';
import 'package:mobile/features/social/presentation/providers/likes_provider.dart';
import 'package:mobile/features/social/presentation/providers/save_provider.dart';
import 'package:mobile/features/social/presentation/widgets/follow_button.dart';
import 'package:mobile/features/social/presentation/widgets/share_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:video_player/video_player.dart';

import '../../media_experience/presentation/widgets/player_speed_sheet.dart';
import '../../media_experience/presentation/widgets/player_quality_sheet.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  bool? _isSeekingForward;
  Timer? _seekFeedbackTimer;

  // Mini-player drag state
  double _dragOffset = 0;
  bool _isDragging = false;
  static const _kMiniDragThreshold = 120.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mini = ref.read(miniPlayerProvider);
      if (mini.contentId == widget.videoId && mini.controller != null) {
        // PlayerNotifier already adopted this exact controller. Remove the
        // MiniPlayer listener without pausing or disposing the session.
        final reclaimed = ref
            .read(miniPlayerProvider.notifier)
            .reclaimController(widget.videoId);
        if (reclaimed != null) {
          debugPrint(
            '[VideoPlayerScreen] Fullscreen player mounted; controller '
            'reclaimed for ${widget.videoId} position=${reclaimed.value.position} '
            'playing=${reclaimed.value.isPlaying}',
          );
        }
      }
    });
  }

  void _triggerSeek(bool isForward) {
    setState(() {
      _isSeekingForward = isForward;
    });
    _seekFeedbackTimer?.cancel();
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isSeekingForward = null);
    });
  }

  /// Minimize to mini player: transfer controller ownership and pop.
  void _minimizeToMiniPlayer(PlayerState state) {
    final ctrl = state.controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      context.pop();
      return;
    }

    final video = state.video;
    if (video == null) {
      context.pop();
      return;
    }

    // Detach the controller from the provider so it won't be disposed.
    // The provider is autoDispose — when we pop, it normally disposes the
    // controller. We prevent this by overriding with keepAlive via listen.
    ref
        .read(miniPlayerProvider.notifier)
        .showVideo(
          videoId: video.id,
          title: video.title,
          channelName: video.author.username,
          thumbnailUrl: video.thumbnailUrl,
          controller: ctrl,
        );

    // Null out the controller in provider state before dispose runs.
    ref.read(playerProvider(widget.videoId).notifier).detachController();

    context.pop();
  }

  @override
  void dispose() {
    _seekFeedbackTimer?.cancel();
    // Restore orientation when leaving player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider(widget.videoId));
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(tr('state.error'), style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(playerProvider(widget.videoId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('common.retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final video = state.video!;

    // Seed like/save state from video DTO so buttons reflect backend state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(likesProvider.notifier)
          .seed(video.id, video.isLiked ?? false, video.likesCount);
      ref.read(saveProvider.notifier).seed(video.id, video.isSaved ?? false);
    });

    // Handle fullscreen
    if (state.isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    // Force 16:9 aspect ratio for video player
    final videoAspect = 16 / 9;

    final resolvedThumb = MediaUrlResolver.resolveThumbnail(
      thumbnailUrl: state.video?.thumbnailUrl,
      hlsUrl: state.video?.hlsUrl,
      renditionUrls: state.video?.renditions.map((r) => r.url).toList(),
    );

    final isInitialized =
        state.controller != null && state.controller!.value.isInitialized;
    final isPlaying = isInitialized && state.controller!.value.isPlaying;

    final Widget playerContent = isInitialized
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref
                .read(playerProvider(widget.videoId).notifier)
                .toggleControls(),
            onDoubleTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              final width =
                  box?.size.width ?? MediaQuery.of(context).size.width;
              final dx = details.localPosition.dx;
              final notifier = ref.read(
                playerProvider(widget.videoId).notifier,
              );

              if (dx < width / 2) {
                notifier.seekBackward();
                _triggerSeek(false);
              } else {
                notifier.seekForward();
                _triggerSeek(true);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video player maintaining natural aspect ratio (fixes X and Y stretching)
                Center(
                  child: AspectRatio(
                    aspectRatio: videoAspect,
                    child: VideoPlayer(state.controller!),
                  ),
                ),

                // Show thumbnail preview at beginning when paused instead of black screen
                if (!isPlaying &&
                    state.controller!.value.position == Duration.zero &&
                    resolvedThumb != null &&
                    resolvedThumb.isNotEmpty)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: resolvedThumb,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox.shrink(),
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                  ),

                // YouTube-like double-tap seek feedback animation
                if (_isSeekingForward != null)
                  _YouTubeSeekFeedback(isForward: _isSeekingForward!),

                if (state.showControls)
                  _PlayerControlsOverlay(
                    controller: state.controller!,
                    notifier: ref.read(playerProvider(widget.videoId).notifier),
                    videoId: widget.videoId,
                    isFullscreen: state.isFullscreen,
                    onMinimizeToMiniPlayer: () => _minimizeToMiniPlayer(state),
                    onDoubleTapSeek: (isForward) {
                      _triggerSeek(isForward);
                    },
                  ),

                if (state.isBuffering)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          )
        : Stack(
            alignment: Alignment.center,
            children: [
              if (resolvedThumb != null && resolvedThumb.isNotEmpty)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: resolvedThumb,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox.shrink(),
                    errorWidget: (context, url, error) =>
                        const SizedBox.shrink(),
                  ),
                ),
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ],
          );

    final Widget playerWidget = state.isFullscreen
        ? Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: playerContent,
          )
        : AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: Colors.black, child: playerContent),
          );

    if (state.isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: Center(child: playerWidget)),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _minimizeToMiniPlayer(state);
      },
      child: GestureDetector(
        onVerticalDragStart: (_) => setState(() {
          _isDragging = true;
          _dragOffset = 0;
        }),
        onVerticalDragUpdate: (details) {
          if (!_isDragging) return;
          setState(() => _dragOffset += details.delta.dy);
        },
        onVerticalDragEnd: (_) {
          if (_dragOffset > _kMiniDragThreshold) {
            _minimizeToMiniPlayer(state);
          }
          setState(() {
            _isDragging = false;
            _dragOffset = 0;
          });
        },
        child: Transform.translate(
          offset: Offset(0, _isDragging ? _dragOffset.clamp(0.0, 300.0) : 0),
          child: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1100;

                  final metaSection = _VideoMetaSection(
                    theme: theme,
                    video: video,
                    state: state,
                    tr: tr,
                  );

                  final contentColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      playerWidget,
                      const SizedBox(height: 16),
                      metaSection,
                    ],
                  );

                  if (isWide) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: contentColumn),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 360,
                                child: _VideoSidebar(
                                  theme: theme,
                                  video: video,
                                  state: state,
                                  tr: tr,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      playerWidget,
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            metaSection,
                            const SizedBox(height: 24),
                            Text(
                              tr('home.recommended'),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            ...state.recommendations.map(
                              (rec) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: VideoCard(video: rec),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Like action that uses the existing LikeButton widget internally ──────────

class _VideoMetaSection extends StatelessWidget {
  final ThemeData theme;
  final dynamic video;
  final dynamic state;
  final dynamic tr;

  const _VideoMetaSection({
    required this.theme,
    required this.video,
    required this.state,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          video.title,
          style: theme.textTheme.titleLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${video.viewsCount} views • ${video.createdAt.toString().split(' ')[0]}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: state.isOfflinePlayback
                    ? Colors.green.withValues(alpha: 0.15)
                    : const Color(0xFF00C6FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.isOfflinePlayback
                      ? Colors.green
                      : const Color(0xFF00C6FF),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.isOfflinePlayback
                        ? Icons.offline_pin_rounded
                        : Icons.cloud_done_rounded,
                    size: 14,
                    color: state.isOfflinePlayback
                        ? Colors.green
                        : const Color(0xFF00C6FF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.isOfflinePlayback ? 'Offline Mode' : 'Online Stream',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: state.isOfflinePlayback
                          ? Colors.green
                          : const Color(0xFF00C6FF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _VideoActionLike(videoId: video.id, video: video),
            ShareButton(postId: video.id, title: video.title, iconSize: 24),
            Consumer(
              builder: (context, ref, _) {
                final downloadState = ref.watch(downloadServiceProvider);
                final isDownloading = downloadState.downloading.contains(
                  video.id,
                );
                final isDownloaded = downloadState.downloads.containsKey(
                  video.id,
                );
                final progress = downloadState.progress[video.id] ?? 0.0;

                if (isDownloading) {
                  return Column(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: progress > 0 ? progress : null,
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00C6FF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                }

                if (isDownloaded) {
                  final t = ref.read(trProvider);
                  return _ActionButton(
                    icon: Icons.offline_pin,
                    iconColor: Colors.green,
                    label: t('video.downloaded'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dlgCtx) => AlertDialog(
                          title: Text(t('video.delete_download_title')),
                          content: Text(t('video.delete_download_msg')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dlgCtx),
                              child: Text(t('common.cancel')),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                Navigator.pop(dlgCtx);
                                ref
                                    .read(downloadServiceProvider.notifier)
                                    .deleteDownload(video.id);
                              },
                              child: Text(t('common.remove')),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                final t = ref.read(trProvider);
                String? candidateDownloadUrl;
                for (final r in video.renditions) {
                  if (r.url.trim().isNotEmpty) {
                    candidateDownloadUrl = r.url;
                    break;
                  }
                }
                candidateDownloadUrl ??= video.hlsUrl ?? video.dashUrl;
                final canDownload =
                    candidateDownloadUrl != null &&
                    candidateDownloadUrl.trim().isNotEmpty;

                return _ActionButton(
                  icon: Icons.download_outlined,
                  label: t('video.download'),
                  onTap: canDownload
                      ? () {
                          ref
                              .read(downloadServiceProvider.notifier)
                              .startDownload(
                                videoId: video.id,
                                url: candidateDownloadUrl!,
                                title: video.title,
                                thumbnailUrl: video.thumbnailUrl,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('video.added_to_downloads')),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('video.download_unavailable')),
                            ),
                          );
                        },
                );
              },
            ),
            _VideoActionSave(videoId: video.id, video: video),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (video.author.username != null) {
                  context.push('/profile/user/${video.author.username}');
                }
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Text(
                  (video.author.displayName?.isNotEmpty == true
                          ? video.author.displayName![0]
                          : video.author.username?.isNotEmpty == true
                          ? video.author.username![0]
                          : '?')
                      .toUpperCase(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (video.author.username != null) {
                    context.push('/profile/user/${video.author.username}');
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.author.displayName ??
                          video.author.username ??
                          'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      video.channelName ?? 'Channel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            FollowButton(targetUserId: video.author.id, isDense: false),
          ],
        ),
        const Divider(height: 32),
        if (video.description != null) ...[
          _ExpandableDescription(description: video.description!),
          const Divider(height: 32),
        ],
      ],
    );
  }
}

class _VideoSidebar extends StatelessWidget {
  final ThemeData theme;
  final dynamic video;
  final dynamic state;
  final dynamic tr;

  const _VideoSidebar({
    required this.theme,
    required this.video,
    required this.state,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (video.author.username != null) {
                    context.push('/profile/user/${video.author.username}');
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    (video.author.displayName?.isNotEmpty == true
                            ? video.author.displayName![0]
                            : video.author.username?.isNotEmpty == true
                            ? video.author.username![0]
                            : '?')
                        .toUpperCase(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.author.displayName ??
                          video.author.username ??
                          'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      video.channelName ?? 'Channel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FollowButton(targetUserId: video.author.id, isDense: false),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                icon: Icons.thumb_up_outlined,
                label: '${video.likesCount} likes',
              ),
              _StatChip(
                icon: Icons.comment_outlined,
                label: '${video.commentsCount} comments',
              ),
              _StatChip(
                icon: Icons.visibility_outlined,
                label: '${video.viewsCount} views',
              ),
              _StatChip(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Followers',
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (video.description != null) ...[
            Text('About this video', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _ExpandableDescription(description: video.description!),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _VideoActionLike extends ConsumerWidget {
  final String videoId;
  final dynamic video;

  const _VideoActionLike({required this.videoId, required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeStateMap = ref.watch(likesProvider);
    final likeState = likeStateMap[videoId];
    final isLiked = likeState?.isLiked ?? (video.isLiked ?? false);
    final count = likeState?.likesCount ?? video.likesCount;

    return GestureDetector(
      onTap: () {
        ref.read(likesProvider.notifier).toggleLike(videoId, isVideo: true);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              key: ValueKey(isLiked),
              color: isLiked ? Theme.of(context).colorScheme.primary : null,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count == 0 ? 'Like' : '$count',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Save/Bookmark action ─────────────────────────────────────────────────────

class _VideoActionSave extends ConsumerWidget {
  final String videoId;
  final dynamic video;

  const _VideoActionSave({required this.videoId, required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saveStateMap = ref.watch(saveProvider);
    final isSaved = saveStateMap[videoId] ?? (video.isSaved ?? false);

    return GestureDetector(
      onTap: () {
        ref.read(saveProvider.notifier).toggleSave(videoId, isVideo: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSaved ? 'Removed from saved' : 'Saved to library'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_outline,
              key: ValueKey(isSaved),
              color: isSaved ? Colors.amber : null,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSaved ? 'Saved' : 'Save',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Expandable description ───────────────────────────────────────────────────

class _ExpandableDescription extends StatefulWidget {
  final String description;
  const _ExpandableDescription({required this.description});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _expanded ? 'Show less' : 'Show more',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic action button ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ── YouTube-style Double-tap Seek Feedback ──────────────────────────────────

class _YouTubeSeekFeedback extends StatefulWidget {
  final bool isForward;
  const _YouTubeSeekFeedback({required this.isForward});

  @override
  State<_YouTubeSeekFeedback> createState() => _YouTubeSeekFeedbackState();
}

class _YouTubeSeekFeedbackState extends State<_YouTubeSeekFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFwd = widget.isForward;
    return Positioned(
      left: isFwd ? null : 0,
      right: isFwd ? 0 : null,
      top: 0,
      bottom: 0,
      width: 140,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.horizontal(
                  left: isFwd ? const Radius.circular(100) : Radius.zero,
                  right: isFwd ? Radius.zero : const Radius.circular(100),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFwd
                        ? Icons.fast_forward_rounded
                        : Icons.fast_rewind_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isFwd ? '10 seconds ▶▶' : '◀◀ 10 seconds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Player Controls Overlay ──────────────────────────────────────────────────

class _PlayerControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final PlayerNotifier notifier;
  final String videoId;
  final bool isFullscreen;
  final VoidCallback onMinimizeToMiniPlayer;
  final void Function(bool isForward) onDoubleTapSeek;

  const _PlayerControlsOverlay({
    required this.controller,
    required this.notifier,
    required this.videoId,
    required this.isFullscreen,
    required this.onMinimizeToMiniPlayer,
    required this.onDoubleTapSeek,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: notifier.toggleControls,
      onDoubleTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        final width = box?.size.width ?? MediaQuery.of(context).size.width;
        final isForward = details.localPosition.dx >= width / 2;
        if (isForward) {
          notifier.seekForward();
        } else {
          notifier.seekBackward();
        }
        onDoubleTapSeek(isForward);
      },
      child: Container(
        color: Colors.black45,
        child: Stack(
          children: [
            // Top bar (Back button & Settings)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      if (isFullscreen) {
                        notifier.toggleFullscreen();
                      } else {
                        onMinimizeToMiniPlayer();
                      }
                    },
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.speed, color: Colors.white),
                        onPressed: () {
                          PlayerSpeedSheet.show(context, videoId);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          PlayerQualitySheet.show(context, videoId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Center controls - Play / Pause only (10s skip buttons removed in favor of YouTube-style double-tap)
            Center(
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, VideoPlayerValue value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 64,
                      color: Colors.white,
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      onPressed: notifier.togglePlayPause,
                    ),
                  );
                },
              ),
            ),

            // Bottom progress bar
            Positioned(
              bottom: 8,
              left: 16,
              right: 16,
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, VideoPlayerValue value, child) {
                  return Row(
                    children: [
                      Text(
                        _formatDuration(value.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(value.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          color: Colors.white,
                        ),
                        onPressed: notifier.toggleFullscreen,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
