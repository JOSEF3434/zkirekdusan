// lib/features/stories/presentation/screens/story_viewer_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';
import 'package:mobile/features/stories/presentation/providers/story_viewer_provider.dart';
import 'package:mobile/features/stories/presentation/widgets/story_comment_input.dart';
import 'package:mobile/features/stories/presentation/widgets/story_progress_bar.dart';
import 'package:mobile/features/stories/presentation/widgets/story_reaction_bar.dart';
import 'package:mobile/features/stories/presentation/widgets/story_reactions_sheet.dart';
import 'package:mobile/features/stories/presentation/widgets/story_viewer_analytics.dart';
import 'package:mobile/features/stories/presentation/widgets/story_viewer_controls.dart';
import 'package:mobile/features/stories/presentation/widgets/story_views_sheet.dart';

class StoryViewerArgs {
  final List<StoryFeedGroupModel> groups;
  final int initialGroupIndex;
  final int initialStoryIndex;

  const StoryViewerArgs({
    required this.groups,
    this.initialGroupIndex = 0,
    this.initialStoryIndex = 0,
  });
}

class StoryViewerScreen extends ConsumerStatefulWidget {
  final StoryViewerArgs args;

  const StoryViewerScreen({super.key, required this.args});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  final FocusNode _focusNode = FocusNode();
  VideoPlayerController? _videoController;
  String? _currentVideoUrl;
  bool _isMuted = false;
  bool _showReactionsPicker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(storyViewerProvider.notifier)
          .init(
            groups: widget.args.groups,
            initialGroupIndex: widget.args.initialGroupIndex,
            initialStoryIndex: widget.args.initialStoryIndex,
          );
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _setupVideo(String rawVideoUrl) {
    final videoUrl = MediaUrlResolver.resolve(rawVideoUrl) ?? rawVideoUrl;
    if (_currentVideoUrl == videoUrl && _videoController != null) {
      return;
    }

    _videoController?.dispose();
    _currentVideoUrl = videoUrl;

    final playbackUrl = MediaUrlResolver.isCloudinary(videoUrl) &&
            !videoUrl.endsWith('.mp4') &&
            !videoUrl.endsWith('.m3u8')
        ? MediaUrlResolver.toCloudinaryMp4(videoUrl)
        : videoUrl;

    final controller = VideoPlayerController.networkUrl(Uri.parse(playbackUrl));
    _videoController = controller;

    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          controller.setVolume(_isMuted ? 0.0 : 1.0);
          controller.play();
          setState(() {});

          controller.addListener(() {
            if (!mounted) return;
            final position = controller.value.position;
            final duration = controller.value.duration;

            if (duration.inMilliseconds > 0) {
              final progress =
                  position.inMilliseconds / duration.inMilliseconds;
              ref
                  .read(storyViewerProvider.notifier)
                  .updateVideoProgress(progress);

              if (position >= duration && !controller.value.isPlaying) {
                ref.read(storyViewerProvider.notifier).onVideoFinished();
              }
            }
          });
        })
        .catchError((error) {
          debugPrint('[StoryViewer] video error: $error for $playbackUrl');
          ref.read(storyViewerProvider.notifier).nextStory();
        });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final notifier = ref.read(storyViewerProvider.notifier);
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      notifier.previousStory();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      notifier.nextStory();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      context.pop();
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      final state = ref.read(storyViewerProvider);
      if (state.isPaused) {
        notifier.resume();
        _videoController?.play();
      } else {
        notifier.pause();
        _videoController?.pause();
      }
    }
  }

  Future<void> _confirmDeleteStory(StoryModel story) async {
    final notifier = ref.read(storyViewerProvider.notifier);
    notifier.setOverlayOpen(true);
    _videoController?.pause();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Story?'),
        content: const Text(
          'This story will be removed permanently and won\'t be visible to other users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await notifier.deleteCurrentStory();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story deleted successfully')),
        );
      }
    }

    notifier.setOverlayOpen(false);
    _videoController?.play();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyViewerProvider);
    final myUserId = ref.watch(authProvider).user?.id;

    // Listen for story completion to exit
    ref.listen(storyViewerProvider, (prev, next) {
      if (next.isCompleted && mounted) {
        context.pop();
      }
    });

    final currentStory = state.currentStory;
    final currentGroup = state.currentGroup;

    if (currentStory == null || currentGroup == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final isOwner = state.isOwner(myUserId);

    // Setup video controller if story is video
    if (currentStory.isVideo && currentStory.mediaUrl != null) {
      _setupVideo(currentStory.mediaUrl!);
    } else {
      _videoController?.pause();
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  // Drag down to dismiss
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 250) {
                    context.pop();
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Media Layer
                    _buildMediaContent(currentStory),

                    // Touch Gesture Detector (Left tap = prev, Right tap = next, Hold = pause)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (_) {
                          ref.read(storyViewerProvider.notifier).pause();
                          _videoController?.pause();
                        },
                        onTapUp: (details) {
                          ref.read(storyViewerProvider.notifier).resume();
                          _videoController?.play();

                          final width = MediaQuery.sizeOf(context).width;
                          final dx = details.localPosition.dx;

                          if (dx < width * 0.35) {
                            ref
                                .read(storyViewerProvider.notifier)
                                .previousStory();
                          } else if (dx > width * 0.65) {
                            ref.read(storyViewerProvider.notifier).nextStory();
                          }
                        },
                        onTapCancel: () {
                          ref.read(storyViewerProvider.notifier).resume();
                          _videoController?.play();
                        },
                      ),
                    ),

                    // Top Gradient Shadow + Controls
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress bar
                              StoryProgressBar(
                                totalStories: currentGroup.stories.length,
                                currentIndex: state.currentStoryIndex,
                                currentProgress: state.progress,
                              ),

                              // Controls header
                              StoryViewerControls(
                                story: currentStory,
                                storyIndex: state.currentStoryIndex,
                                totalStories: currentGroup.stories.length,
                                isOwner: isOwner,
                                isMuted: _isMuted,
                                onClose: () => context.pop(),
                                onToggleMute: _toggleMute,
                                onDelete: isOwner
                                    ? () => _confirmDeleteStory(currentStory)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Optional Caption Overlay
                    if (currentStory.content != null &&
                        currentStory.content!.trim().isNotEmpty &&
                        !currentStory.isText)
                      Positioned(
                        bottom: isOwner ? 80 : 80,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentStory.content!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // Reaction Picker Overlay
                    if (_showReactionsPicker)
                      Positioned(
                        bottom: 80,
                        right: 16,
                        child: StoryReactionBar(
                          myReaction: currentStory.myReaction,
                          onReactionSelected: (reaction) {
                            ref
                                .read(storyViewerProvider.notifier)
                                .addReaction(reaction);
                            setState(() => _showReactionsPicker = false);
                          },
                        ),
                      ),

                    // Bottom Bar (Owner Analytics vs Viewer Interaction)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: isOwner
                          ? StoryViewerAnalytics(
                              story: currentStory,
                              onViewersTap: () {
                                final notifier = ref.read(
                                  storyViewerProvider.notifier,
                                );
                                notifier.setOverlayOpen(true);
                                _videoController?.pause();
                                StoryViewsSheet.show(
                                  context,
                                  currentStory.id,
                                ).then((_) {
                                  notifier.setOverlayOpen(false);
                                  _videoController?.play();
                                });
                              },
                              onReactionsTap: () {
                                final notifier = ref.read(
                                  storyViewerProvider.notifier,
                                );
                                notifier.setOverlayOpen(true);
                                _videoController?.pause();
                                StoryReactionsSheet.show(
                                  context,
                                  currentStory.id,
                                ).then((_) {
                                  notifier.setOverlayOpen(false);
                                  _videoController?.play();
                                });
                              },
                              onDeleteTap: () =>
                                  _confirmDeleteStory(currentStory),
                            )
                          : StoryCommentInput(
                              myReaction: currentStory.myReaction,
                              onFocusChanged: (isFocused) {
                                ref
                                    .read(storyViewerProvider.notifier)
                                    .setOverlayOpen(isFocused);
                                if (isFocused) {
                                  _videoController?.pause();
                                } else {
                                  _videoController?.play();
                                }
                              },
                              onSendReaction: (reaction) {
                                if (reaction == 'UNLIKE') {
                                  ref
                                      .read(storyViewerProvider.notifier)
                                      .removeReaction();
                                } else {
                                  ref
                                      .read(storyViewerProvider.notifier)
                                      .addReaction(reaction);
                                }
                              },
                              onSendComment: (text) async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await ref
                                      .read(storiesRemoteDatasourceProvider)
                                      .addComment(currentStory.id, text);
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Reply sent'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to send reply. Try again.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(StoryModel story) {
    if (story.isText) {
      final bgColor =
          _parseColor(story.backgroundColor) ?? const Color(0xFF1E293B);
      final textColor = _parseColor(story.textColor) ?? Colors.white;

      return Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        alignment: Alignment.center,
        child: Text(
          story.content ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    if (story.isVideo) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        return Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Image Story
    final resolvedImageUrl = MediaUrlResolver.resolve(story.mediaUrl);
    if (resolvedImageUrl != null && resolvedImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: resolvedImageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (context, url, error) {
          debugPrint(
            '[StoryViewer] Image load failed for: $resolvedImageUrl (error: $error)',
          );
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load media',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'No media available',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Color? _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return null;
  }
}
