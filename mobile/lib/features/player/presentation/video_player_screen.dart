// lib/features/player/presentation/video_player_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/features/player/presentation/providers/player_provider.dart';
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

  void _showSeekFeedback(String text) {
    setState(() {
      _seekFeedback = text;
    });
    _seekFeedbackTimer?.cancel();
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _seekFeedback = null);
    });
  }
  @override
  void dispose() {
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
                final notifier = ref.read(playerProvider(widget.videoId).notifier);
                
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

    return Scaffold(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: Icons.thumb_up_outlined,
                        label: '${video.likesCount}',
                        onTap: () {},
                      ),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () {},
                      ),
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
                                ref
                                    .read(downloadServiceProvider.notifier)
                                    .deleteDownload(video.id);
                              },
                            );
                          }

                          final canDownload = video.renditions.isNotEmpty;

                          return _ActionButton(
                            icon: Icons.download_outlined,
                            label: 'Download',
                            onTap: canDownload
                                ? () {
                                    ref
                                        .read(downloadServiceProvider.notifier)
                                        .startDownload(
                                          videoId: video.id,
                                          url: video.renditions.first.url,
                                          title: video.title,
                                          thumbnailUrl: video.thumbnailUrl,
                                        );
                                  }
                                : () {},
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.bookmark_outline,
                        label: 'Save',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        child: Text(video.author.displayName?[0] ?? '?'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.author.displayName ?? 'Unknown',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text('Channel', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Subscribe'),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  if (video.description != null) ...[
                    Text(video.description!),
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
    );
  }
}

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
