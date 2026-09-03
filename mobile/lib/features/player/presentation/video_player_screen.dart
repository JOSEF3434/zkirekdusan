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
  String? _seekFeedback;
  Timer? _seekFeedbackTimer;

  // Mini-player drag state
  double _dragOffset = 0;
  bool _isDragging = false;
  static const _kMiniDragThreshold = 120.0;

  void _showSeekFeedback(String text) {
    setState(() {
      _seekFeedback = text;
    });
    _seekFeedbackTimer?.cancel();
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _seekFeedback = null);
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
    ref.read(miniPlayerProvider.notifier).showVideo(
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
      ref.read(likesProvider.notifier).seed(
        video.id,
        video.isLiked ?? false,
        video.likesCount,
      );
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

    Widget playerWidget = AspectRatio(
      aspectRatio: 16 / 9,
      child: state.controller != null && state.controller!.value.isInitialized
          ? GestureDetector(
              onTap: () => ref
                  .read(playerProvider(widget.videoId).notifier)
                  .toggleControls(),
              onDoubleTapDown: (details) {
                final width = MediaQuery.of(context).size.width;
                final dx = details.localPosition.dx;
                final notifier = ref.read(
                  playerProvider(widget.videoId).notifier,
                );

                if (dx < width / 3) {
                  notifier.seekBackward();
                  _showSeekFeedback('-10s');
                } else if (dx > 2 * width / 3) {
                  notifier.seekForward();
                  _showSeekFeedback('+10s');
                } else {
                  notifier.togglePlayPause();
                }
              },
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(state.controller!),
                  if (_seekFeedback != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          _seekFeedback!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (state.showControls)
                    _PlayerControlsOverlay(
                      controller: state.controller!,
                      notifier: ref.read(
                        playerProvider(widget.videoId).notifier,
                      ),
                      videoId: widget.videoId,
                      isFullscreen: state.isFullscreen,
                    ),
                  if (state.isBuffering)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
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
              child: Column(
                children: [
                  playerWidget,
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                children: [
                  Text(video.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '${video.viewsCount} views • ${video.createdAt.toString().split(' ')[0]}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Action Buttons Row ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Like button — uses existing LikeButton widget with animation
                      _VideoActionLike(videoId: video.id, video: video),

                      // Share button — uses share_plus via existing ShareButton
                      ShareButton(
                        postId: video.id,
                        title: video.title,
                        iconSize: 24,
                      ),

                      // Download button
                      Consumer(
                        builder: (context, ref, _) {
                          final downloadState = ref.watch(
                            downloadServiceProvider,
                          );
                          final isDownloading = downloadState.downloading
                              .contains(video.id);
                          final isDownloaded = downloadState.downloads
                              .containsKey(video.id);
                          final progress =
                              downloadState.progress[video.id] ?? 0.0;

                          if (isDownloading) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 2,
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
                            return _ActionButton(
                              icon: Icons.offline_pin,
                              iconColor: Colors.green,
                              label: 'Downloaded',
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (dlgCtx) => AlertDialog(
                                    title: const Text('Delete Download?'),
                                    content: const Text(
                                      'Remove this downloaded video from your device storage?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dlgCtx),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(dlgCtx);
                                          ref
                                              .read(
                                                downloadServiceProvider.notifier,
                                              )
                                              .deleteDownload(video.id);
                                        },
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }

                          final downloadUrl = video.renditions.isNotEmpty
                              ? video.renditions.first.url
                              : (video.hlsUrl ?? video.dashUrl);
                          final canDownload = video.isDownloadable &&
                              downloadUrl != null &&
                              downloadUrl.isNotEmpty;

                          return _ActionButton(
                            icon: Icons.download_outlined,
                            label: 'Download',
                            onTap: canDownload
                                ? () {
                                    ref
                                        .read(downloadServiceProvider.notifier)
                                        .startDownload(
                                          videoId: video.id,
                                          url: downloadUrl,
                                          title: video.title,
                                          thumbnailUrl: video.thumbnailUrl,
                                        );
                                  }
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Download is disabled for this stream/video',
                                        ),
                                      ),
                                    );
                                  },
                          );
                        },
                      ),

                      // Save / Bookmark button — uses existing SaveButton widget
                      _VideoActionSave(videoId: video.id, video: video),
                    ],
                  ),

                  const Divider(height: 32),

                  // ── Channel row with Subscribe button ─────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (video.author.username != null) {
                            context.push(
                              '/profile/user/${video.author.username}',
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
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
                              context.push(
                                '/profile/user/${video.author.username}',
                              );
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
                      // Follow/Subscribe button using existing FollowButton widget
                      FollowButton(
                        targetUserId: video.author.id,
                        isDense: false,
                      ),
                    ],
                  ),

                  const Divider(height: 32),
                  if (video.description != null) ...[
                    _ExpandableDescription(description: video.description!),
                    const Divider(height: 32),
                  ],
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
        ),
      ),
          ),
        ),
      ),
    );
  }
}

// ── Like action that uses the existing LikeButton widget internally ──────────

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
          Text(isSaved ? 'Saved' : 'Save', style: const TextStyle(fontSize: 12)),
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

// ── Player Controls Overlay ──────────────────────────────────────────────────

class _PlayerControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final PlayerNotifier notifier;
  final String videoId;
  final bool isFullscreen;

  const _PlayerControlsOverlay({
    required this.controller,
    required this.notifier,
    required this.videoId,
    required this.isFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      context.pop();
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

          // Center controls
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  color: Colors.white,
                  icon: const Icon(Icons.replay_10),
                  onPressed: notifier.seekBackward,
                ),
                const SizedBox(width: 24),
                ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, VideoPlayerValue value, child) {
                    return IconButton(
                      iconSize: 64,
                      color: Colors.white,
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                      ),
                      onPressed: notifier.togglePlayPause,
                    );
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  iconSize: 48,
                  color: Colors.white,
                  icon: const Icon(Icons.forward_10),
                  onPressed: notifier.seekForward,
                ),
              ],
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    IconButton(
                      icon: Icon(
                        isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
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
