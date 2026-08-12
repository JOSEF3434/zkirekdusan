// lib/features/player/presentation/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/player/presentation/providers/player_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/core/storage/download_service.dart';

class VideoPlayerScreen extends ConsumerWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider(videoId));
    final theme = Theme.of(context);

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
                Text('Playback Error', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    // re-initialize by invalidating provider
                    ref.invalidate(playerProvider(videoId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final video = state.video!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Area
            AspectRatio(
              aspectRatio: 16 / 9,
              child:
                  state.controller != null &&
                      state.controller!.value.isInitialized
                  ? GestureDetector(
                      onTap: () => ref
                          .read(playerProvider(videoId).notifier)
                          .toggleControls(),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(state.controller!),
                          if (state.showControls)
                            _PlayerControlsOverlay(
                              controller: state.controller!,
                              notifier: ref.read(
                                playerProvider(videoId).notifier,
                              ),
                            ),
                          // Back button overlay
                          if (state.showControls)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: () => context.pop(),
                              ),
                            ),
                        ],
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            // Video Details and Recommendations
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

                  // Action Bar
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Download removed'),
                                  ),
                                );
                              },
                            );
                          }

                          // Only enable download if we have a direct MP4 url (not HLS master playlist which requires m3u8 parser)
                          // For now we check if renditions exist which implies direct urls are available
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Download started'),
                                      ),
                                    );
                                  }
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'This video cannot be downloaded offline.',
                                        ),
                                      ),
                                    );
                                  },
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

                  // Channel Info
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

                  // Recommendations
                  Text('Up next', style: theme.textTheme.titleMedium),
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

  const _PlayerControlsOverlay({
    required this.controller,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Play/Pause button in center
          Expanded(
            child: Center(
              child: ValueListenableBuilder(
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
            ),
          ),
          // Progress bar
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, VideoPlayerValue value, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(value.position),
                      style: const TextStyle(color: Colors.white),
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
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: () {
                        // Implement fullscreen
                      },
                    ),
                  ],
                ),
              );
            },
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
