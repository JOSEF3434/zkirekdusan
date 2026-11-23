import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';
import 'package:mobile/core/presentation/providers/pip_provider.dart';
import 'package:mobile/core/rich_text/rich_text_renderer.dart';
import 'package:mobile/core/services/pip_service.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/browser_fullscreen_helper.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/features/player/presentation/providers/player_provider.dart';
import 'package:mobile/features/security/presentation/providers/media_activity_provider.dart';
import 'package:mobile/features/social/presentation/providers/likes_provider.dart';
import 'package:mobile/features/social/presentation/providers/save_provider.dart';
import 'package:mobile/features/social/presentation/widgets/follow_button.dart';
import 'package:mobile/features/social/presentation/widgets/share_button.dart';
import 'package:mobile/features/library/presentation/widgets/save_to_playlist_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:video_player/video_player.dart';

import '../../media_experience/presentation/widgets/player_speed_sheet.dart';
import '../../media_experience/presentation/widgets/player_settings_sheet.dart';
import '../../media_experience/presentation/providers/playback_preferences_provider.dart';
import '../../media_experience/domain/playback_preferences.dart';

/// Dynamically detects the true video aspect ratio from the controller.
///
/// Handles portrait (9:16), landscape (16:9), ultra-wide (21:9), and square (1:1)
/// gracefully with fallback to 16:9 before metadata loads.
double _computeVideoAspectRatio(VideoPlayerController? ctrl) {
  if (ctrl != null && ctrl.value.isInitialized) {
    final size = ctrl.value.size;
    if (size.width > 0 &&
        size.height > 0 &&
        !size.width.isNaN &&
        !size.height.isNaN &&
        !size.width.isInfinite &&
        !size.height.isInfinite) {
      return size.width / size.height;
    }
    final ratio = ctrl.value.aspectRatio;
    if (ratio > 0 && !ratio.isNaN && !ratio.isInfinite) {
      return ratio;
    }
  }
  return 16 / 9;
}

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  bool? _isSeekingForward;
  Timer? _seekFeedbackTimer;

  // Video fill/cover mode state (defaults to true for full width cover)
  bool _isCover = true;

  // GlobalKey to preserve video player element during fullscreen reparenting
  final GlobalKey _videoPlayerKey = GlobalKey();

  // Autoplay countdown state
  Timer? _autoplayTimer;
  int _autoplayCountdown = 5;
  bool _isAutoplayCancelled = false;

  void _handleVideoEnded(PlayerState state) {
    final prefs = ref.read(playbackPreferencesProvider);
    if (!prefs.autoplay || _isAutoplayCancelled || !mounted) return;

    final nextVideos = state.recommendations.where((v) => v.id != widget.videoId).toList();
    if (nextVideos.isEmpty) return;

    final nextVideo = nextVideos.first;
    _cancelAutoplayTimer();

    setState(() {
      _autoplayCountdown = 5;
    });

    _autoplayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_autoplayCountdown <= 1) {
        timer.cancel();
        _navigateToNextVideo(nextVideo.id);
      } else {
        setState(() {
          _autoplayCountdown--;
        });
      }
    });
  }

  void _navigateToNextVideo(String nextVideoId) {
    _cancelAutoplayTimer();
    if (context.mounted) {
      context.pushReplacement('/video/$nextVideoId');
    }
  }

  void _cancelAutoplayTimer() {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
  }

  // Mini-player drag state
  double _dragOffset = 0;
  bool _isDragging = false;
  static const _kMiniDragThreshold = 120.0;

  // Media-session ID used to register with mediaActivityProvider.
  // Format: 'video:<videoId>' — stable for the lifetime of this screen.
  String get _mediaSessionId => 'video:${widget.videoId}';

  MediaActivityNotifier? _mediaActivityNotifier;
  PipNotifier? _pipNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mediaActivityNotifier = ref.read(mediaActivityProvider.notifier);
    _pipNotifier = ref.read(pipProvider.notifier);
  }

  @override
  void initState() {
    super.initState();

    // Pause any existing mini-player controller playing a different video
    // in a microtask so it does not trigger synchronous provider mutations during initState.
    final initialMini = ref.read(miniPlayerProvider);
    if (initialMini.hasContent && initialMini.contentId != widget.videoId) {
      Future.microtask(() {
        initialMini.controller?.pause();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mini = ref.read(miniPlayerProvider);
      if (mini.contentId == widget.videoId && mini.controller != null) {
        final wasPlaying = mini.isPlaying ||
            mini.wasPlayingBeforeHandoff ||
            ref.read(miniPlayerProvider.notifier).lastReclaimedWasPlaying;
        final reclaimed = ref
            .read(miniPlayerProvider.notifier)
            .reclaimController(widget.videoId);
        if (reclaimed != null) {
          if (wasPlaying) {
            reclaimed.play().catchError((_) {});
            Future.delayed(const Duration(milliseconds: 200), () {
              if (reclaimed.value.isInitialized && !reclaimed.value.isPlaying) {
                reclaimed.play().catchError((_) {});
              }
            });
          }
          ref
              .read(playerProvider(widget.videoId).notifier)
              .adoptController(reclaimed, wasPlaying: wasPlaying);
        }
      } else if (mini.hasContent || mini.controller != null) {
        // Dismiss previous mini player so only the new video plays in normal mode
        ref.read(miniPlayerProvider.notifier).dismiss();
      }

      final playerState = ref.read(playerProvider(widget.videoId));
      final ctrl = playerState.controller;
      if (ctrl != null && ctrl.value.isInitialized) {
        final isPlaying = ctrl.value.isPlaying;
        final ratio = _computeVideoAspectRatio(ctrl);
        ref.read(pipProvider.notifier).registerActiveMedia(
          contentId: widget.videoId,
          isPlaying: isPlaying,
          aspectRatio: ratio,
          title: playerState.video?.title,
        );
      }
    });
  }

  int _seekFeedbackSeconds = 5;

  bool? _currentFullscreenApplied;

  bool _isEditableFocused() {
    final focus = FocusManager.instance.primaryFocus;
    return focus != null && focus.context?.widget is EditableText;
  }

  void _updateFullscreenOrientationAndSystem(
    bool isFullscreen,
    VideoPlayerController? ctrl,
  ) {
    if (_currentFullscreenApplied == isFullscreen) return;
    _currentFullscreenApplied = isFullscreen;

    if (kIsWeb) {
      if (isFullscreen) {
        requestBrowserFullscreen();
      } else {
        exitBrowserFullscreen();
      }
      return;
    }

    if (isFullscreen) {
      final videoAspect = _computeVideoAspectRatio(ctrl);
      final isPortrait = videoAspect < 0.95;
      if (isPortrait) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Widget _buildFullscreenPlayerWidget(Widget playerContent) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: KeyedSubtree(
        key: _videoPlayerKey,
        child: playerContent,
      ),
    );
  }

  Widget _buildNormalPlayerWidget({
    required Widget playerContent,
    required double videoAspect,
    required bool isWide,
    required BoxConstraints constraints,
    required BuildContext context,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobileLandscape = !isWide &&
        constraints.maxWidth > constraints.maxHeight &&
        constraints.maxHeight < 600;

    final Widget playerKeyed = KeyedSubtree(
      key: _videoPlayerKey,
      child: playerContent,
    );

    if (isWide) {
      // Desktop / Web wide layout:
      // The video container MUST span the full width of the content column (no left/right padding, exactly like YouTube).
      // For landscape (16:9), it sizes naturally via AspectRatio.
      // For portrait (9:16), it takes full column width with a fixed comfortable height,
      // featuring the ambient blur background spanning the full width and the portrait video centered.
      if (videoAspect < 1.05) {
        final height = (screenHeight * 0.70).clamp(420.0, 580.0);
        return Container(
          width: double.infinity,
          height: height,
          color: Colors.black,
          child: ClipRect(child: playerKeyed),
        );
      } else {
        return AspectRatio(
          aspectRatio: videoAspect.clamp(16 / 9, 21 / 9),
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: ClipRect(child: playerKeyed),
          ),
        );
      }
    } else {
      // Mobile / narrow layout:
      if (isMobileLandscape) {
        // Mobile in landscape orientation:
        // Take full width and prominent height with black backdrop and ambient glow,
        // rather than floating in a white container.
        final height = (constraints.maxHeight * 0.88).clamp(240.0, 480.0);
        return Container(
          width: double.infinity,
          height: height,
          color: Colors.black,
          child: ClipRect(child: playerKeyed),
        );
      }

      // Standard mobile portrait orientation:
      if (videoAspect < 1.05) {
        // Portrait video on mobile:
        // Container takes full width (100% phone width) and prominent height (0.75 ratio)
        // with black/ambient background spanning edge-to-edge.
        final height =
            (constraints.maxWidth / 0.75).clamp(240.0, screenHeight * 0.62);
        return Container(
          width: double.infinity,
          height: height,
          color: Colors.black,
          child: ClipRect(child: playerKeyed),
        );
      } else {
        // Landscape video on mobile:
        return AspectRatio(
          aspectRatio: videoAspect.clamp(16 / 9, 21 / 9),
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: ClipRect(child: playerKeyed),
          ),
        );
      }
    }
  }

  void _triggerSeek(bool isForward, [int? seconds]) {
    final prefs = ref.read(playbackPreferencesProvider);
    final sec = seconds ??
        (isForward ? prefs.seekForwardSeconds : prefs.seekBackwardSeconds);
    setState(() {
      _isSeekingForward = isForward;
      _seekFeedbackSeconds = sec;
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
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
      return;
    }

    final video = state.video;
    if (video == null) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
      return;
    }

    final wasPlaying = ctrl.value.isPlaying;

    ref
        .read(miniPlayerProvider.notifier)
        .showVideo(
          videoId: video.id,
          title: video.title,
          channelName: video.author.displayName ?? video.author.username,
          thumbnailUrl: video.thumbnailUrl,
          controller: ctrl,
          wasPlaying: wasPlaying,
        );

    // Null out the controller in provider state before dispose runs.
    ref.read(playerProvider(widget.videoId).notifier).detachController();

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  void didUpdateWidget(VideoPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _cancelAutoplayTimer();
      _isAutoplayCancelled = false;
      _autoplayCountdown = 5;

      final mini = ref.read(miniPlayerProvider);
      if (mini.hasContent || mini.controller != null) {
        ref.read(miniPlayerProvider.notifier).dismiss();
      }
    }
  }

  @override
  void dispose() {
    _cancelAutoplayTimer();
    final pipNotifier = _pipNotifier;
    final mediaId = widget.videoId;
    PipService.instance.disableAutoPip();
    Future.microtask(() {
      try {
        pipNotifier?.unregisterActiveMedia(mediaId);
      } catch (_) {}
    });
    _seekFeedbackTimer?.cancel();
    // End any active media session so the inactivity timer restarts.
    final notifier = _mediaActivityNotifier;
    final sessionId = _mediaSessionId;
    Future.microtask(() {
      try {
        notifier?.endSession(sessionId);
      } catch (_) {}
    });
    // Restore orientation and system UI when leaving player
    if (kIsWeb) {
      exitBrowserFullscreen();
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider(widget.videoId));
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    // Ensure any background mini-player playing another video is dismissed while on normal player
    ref.listen<MiniPlayerState>(miniPlayerProvider, (prev, next) {
      if (next.hasContent && next.contentId != widget.videoId) {
        Future.microtask(() {
          if (mounted) {
            ref.read(miniPlayerProvider.notifier).dismiss();
          }
        });
      }
    });

    // Media-session policy: suspend the App Lock inactivity timer while the
    // video is actively playing; restore the countdown when paused or the
    // player is in an error/loading state.
    ref.listen<PlayerState>(playerProvider(widget.videoId), (prev, next) {
      final wasPlaying = prev?.controller?.value.isPlaying ?? false;
      final isPlaying = next.controller?.value.isPlaying ?? false;
      final hasError = next.error != null || next.controller?.value.hasError == true;

      if (hasError || next.isLoading) {
        // Failed or loading — end any active session so the timer is not
        // suspended indefinitely.
        ref.read(mediaActivityProvider.notifier).endSession(_mediaSessionId);
        ref.read(pipProvider.notifier).unregisterActiveMedia(widget.videoId);
        return;
      }

      // If fullscreen toggled while playing, ensure playback is preserved across transitions
      if (prev != null && prev.isFullscreen != next.isFullscreen) {
        _updateFullscreenOrientationAndSystem(next.isFullscreen, next.controller);
        if (wasPlaying) {
          final ctrl = next.controller;
          if (ctrl != null && ctrl.value.isInitialized && !ctrl.value.isPlaying) {
            ctrl.play().catchError((_) {});
            Future.delayed(const Duration(milliseconds: 200), () {
              if (ctrl.value.isInitialized && !ctrl.value.isPlaying) {
                ctrl.play().catchError((_) {});
              }
            });
          }
        }
      }

      // Autoplay next video when video reaches the end
      if (next.isEnded && (prev == null || !prev.isEnded)) {
        _handleVideoEnded(next);
      } else if (!next.isEnded && prev?.isEnded == true) {
        _cancelAutoplayTimer();
        if (mounted) setState(() => _isAutoplayCancelled = false);
      } else if (next.isEnded && (prev?.recommendations.isEmpty ?? true) && next.recommendations.isNotEmpty) {
        _handleVideoEnded(next);
      }

      if (isPlaying && !wasPlaying) {
        ref.read(mediaActivityProvider.notifier).startSession(
          _mediaSessionId,
          MediaSessionKind.videoPlayback,
        );
        final ratio = _computeVideoAspectRatio(next.controller);
        ref.read(pipProvider.notifier).registerActiveMedia(
          contentId: widget.videoId,
          isPlaying: true,
          aspectRatio: ratio,
          title: next.video?.title,
        );
      } else if (!isPlaying && wasPlaying) {
        // Paused: end the session so the normal inactivity countdown resumes.
        ref.read(mediaActivityProvider.notifier).endSession(_mediaSessionId);
        ref.read(pipProvider.notifier).updatePlaybackState(isPlaying: false);
      }
    });

    final pipState = ref.watch(pipProvider);
    if (pipState.isInPip) {
      final ctrl = state.controller;
      final isInitialized = ctrl != null && ctrl.value.isInitialized;
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: isInitialized
              ? AspectRatio(
                  aspectRatio: _computeVideoAspectRatio(ctrl),
                  child: VideoPlayer(ctrl),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    if (state.isLoading || state.video == null) {
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
      if (mounted) {
        _updateFullscreenOrientationAndSystem(state.isFullscreen, state.controller);
      }
    });

    // Dynamically calculate aspect ratio from video metadata/controller
    final double videoAspect = _computeVideoAspectRatio(state.controller);

    final resolvedThumb = MediaUrlResolver.resolveThumbnail(
      thumbnailUrl: state.video?.thumbnailUrl,
      hlsUrl: state.video?.hlsUrl,
      renditionUrls: state.video?.renditions.map((r) => r.url).toList(),
    );

    final isInitialized =
        state.controller != null && state.controller!.value.isInitialized;
    final isPlaying = isInitialized && state.controller!.value.isPlaying;

    final ctrlSize = state.controller?.value.size;
    final ctrlW =
        (ctrlSize != null && ctrlSize.width > 0) ? ctrlSize.width : 16.0;
    final ctrlH =
        (ctrlSize != null && ctrlSize.height > 0) ? ctrlSize.height : 9.0;

    final prefs = ref.watch(playbackPreferencesProvider);
    final notifier = ref.read(playerProvider(widget.videoId).notifier);

    final Widget playerContent = isInitialized
        ? MouseRegion(
            onHover: (_) => notifier.onUserInteraction(),
            onEnter: (_) => notifier.onUserInteraction(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Ambient blurred background for letterboxed / pillarboxed areas
                if (resolvedThumb != null && resolvedThumb.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: resolvedThumb,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const SizedBox.shrink(),
                            errorWidget: (context, url, error) =>
                                const SizedBox.shrink(),
                          ),
                          ClipRect(
                            child: BackdropFilter(
                              filter:
                                  ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 2. Video player maintaining natural aspect ratio or full-width cover
                ClipRect(
                  child: _isCover
                      ? SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: ctrlW,
                              height: ctrlH,
                              child: VideoPlayer(state.controller!),
                            ),
                          ),
                        )
                      : Center(
                          child: AspectRatio(
                            aspectRatio: videoAspect,
                            child: VideoPlayer(state.controller!),
                          ),
                        ),
                ),

                // 3. Show thumbnail preview at beginning when paused instead of black screen
                if (!isPlaying &&
                    state.controller!.value.position == Duration.zero &&
                    resolvedThumb != null &&
                    resolvedThumb.isNotEmpty)
                  Positioned.fill(
                    child: ClipRect(
                      child: _isCover
                          ? SizedBox.expand(
                              child: CachedNetworkImage(
                                imageUrl: resolvedThumb,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const SizedBox.shrink(),
                                errorWidget: (context, url, error) =>
                                    const SizedBox.shrink(),
                              ),
                            )
                          : Center(
                              child: AspectRatio(
                                aspectRatio: videoAspect,
                                child: CachedNetworkImage(
                                  imageUrl: resolvedThumb,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      const SizedBox.shrink(),
                                  errorWidget: (context, url, error) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                    ),
                  ),

                // 4. Tap detector when controls are hidden: single-tap reveals controls, double-tap seeks
                if (!state.showControls)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: notifier.toggleControls,
                      onDoubleTapDown: prefs.doubleTapSeekEnabled
                          ? (details) {
                              final box =
                                  context.findRenderObject() as RenderBox?;
                              final width = box?.size.width ??
                                  MediaQuery.of(context).size.width;
                              final dx = details.localPosition.dx;
                              final isForward = dx >= width / 2;
                              if (isForward) {
                                notifier.seekForward();
                              } else {
                                notifier.seekBackward();
                              }
                              _triggerSeek(isForward);
                            }
                          : null,
                    ),
                  ),

                // 5. YouTube-like double-tap seek feedback animation
                if (_isSeekingForward != null)
                  _YouTubeSeekFeedback(
                    isForward: _isSeekingForward!,
                    seconds: _seekFeedbackSeconds,
                  ),

                // 6. Controls overlay
                if (state.showControls)
                  _PlayerControlsOverlay(
                    controller: state.controller!,
                    notifier: notifier,
                    videoId: widget.videoId,
                    isFullscreen: state.isFullscreen,
                    state: state,
                    prefs: prefs,
                    isCover: _isCover,
                    onToggleCover: () => setState(() => _isCover = !_isCover),
                    autoplayRemainingSeconds: _autoplayTimer != null ? _autoplayCountdown : null,
                    nextVideo: state.recommendations.where((v) => v.id != widget.videoId).firstOrNull,
                    onCancelAutoplay: () {
                      _cancelAutoplayTimer();
                      setState(() => _isAutoplayCancelled = true);
                    },
                    onPlayNextNow: () {
                      final next = state.recommendations.where((v) => v.id != widget.videoId).firstOrNull;
                      if (next != null) _navigateToNextVideo(next.id);
                    },
                    onReplay: () {
                      _cancelAutoplayTimer();
                      setState(() => _isAutoplayCancelled = false);
                      notifier.togglePlayPause();
                    },
                    onMinimizeToMiniPlayer: () => _minimizeToMiniPlayer(state),
                    onDoubleTapSeek: (isForward) {
                      _triggerSeek(isForward);
                    },
                  ),

                // Branding watermark overlay positioned relative to the actual visible video frame
                ClipRect(
                  child: _isCover
                      ? SizedBox.expand(
                          child: TikTokWatermarkOverlay(
                            controller: state.controller,
                            video: video,
                            isVisible: !state.showControls,
                            isLive: notifier.isLiveStream,
                          ),
                        )
                      : Center(
                          child: AspectRatio(
                            aspectRatio: videoAspect,
                            child: TikTokWatermarkOverlay(
                              controller: state.controller,
                              video: video,
                              isVisible: !state.showControls,
                              isLive: notifier.isLiveStream,
                            ),
                          ),
                        ),
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: resolvedThumb,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox.shrink(),
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                      ClipRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (resolvedThumb != null && resolvedThumb.isNotEmpty)
                _isCover
                    ? Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: resolvedThumb,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const SizedBox.shrink(),
                          errorWidget: (context, url, error) =>
                              const SizedBox.shrink(),
                        ),
                      )
                    : Center(
                        child: AspectRatio(
                          aspectRatio: videoAspect,
                          child: CachedNetworkImage(
                            imageUrl: resolvedThumb,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                const SizedBox.shrink(),
                            errorWidget: (context, url, error) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ],
          );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (state.isFullscreen) {
            notifier.toggleFullscreen();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyF): () {
          if (!_isEditableFocused()) {
            notifier.toggleFullscreen();
          }
        },
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (!_isEditableFocused()) {
            notifier.togglePlayPause();
          }
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          if (!_isEditableFocused()) {
            notifier.seekBackward();
            _triggerSeek(false);
          }
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          if (!_isEditableFocused()) {
            notifier.seekForward();
            _triggerSeek(true);
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyM): () {
          if (!_isEditableFocused()) {
            notifier.toggleMute();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyC): () {
          if (!_isEditableFocused()) {
            setState(() => _isCover = !_isCover);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              if (state.isFullscreen) {
                notifier.toggleFullscreen();
              } else {
                _minimizeToMiniPlayer(state);
              }
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: state.isFullscreen
                ? _buildFullscreenPlayerWidget(playerContent)
                : GestureDetector(
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
                      child: Container(
                        color: theme.colorScheme.surface,
                        child: SafeArea(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 1100;

                              final metaSection = _VideoMetaSection(
                                theme: theme,
                                video: video,
                                state: state,
                                tr: tr,
                              );

                              final normalPlayer = _buildNormalPlayerWidget(
                                playerContent: playerContent,
                                videoAspect: videoAspect,
                                isWide: isWide,
                                constraints: constraints,
                                context: context,
                              );

                              final contentColumn = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  normalPlayer,
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
                                  normalPlayer,
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
                final isPublisherPermitted =
                    video.isDownloadable && video.downloadPermission != 'NONE';

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
                  icon: isPublisherPermitted
                      ? Icons.download_outlined
                      : Icons.file_download_off_outlined,
                  iconColor: isPublisherPermitted ? null : Colors.grey,
                  label: t('video.download'),
                  onTap: !isPublisherPermitted
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('The publisher has disabled downloads.'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      : canDownload
                          ? () {
                              ref
                                  .read(downloadServiceProvider.notifier)
                                  .startDownload(
                                    videoId: video.id,
                                    url: candidateDownloadUrl!,
                                    title: video.title,
                                    thumbnailUrl: video.thumbnailUrl,
                                    channelName: video.channelName ??
                                        video.author.displayName ??
                                        video.author.username,
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
            _VideoActionPlaylist(videoId: video.id, videoTitle: video.title),
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

class _VideoActionPlaylist extends ConsumerWidget {
  final String videoId;
  final String? videoTitle;

  const _VideoActionPlaylist({required this.videoId, this.videoTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        SaveToPlaylistSheet.show(
          context,
          videoId: videoId,
          videoTitle: videoTitle,
        );
      },
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.playlist_add_rounded,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            'Playlist',
            style: TextStyle(fontSize: 12),
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
          RichTextRenderer(
            content: widget.description,
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
  final int seconds;
  const _YouTubeSeekFeedback({
    required this.isForward,
    this.seconds = 5,
  });

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
                    isFwd
                        ? '+${widget.seconds}s ▶▶'
                        : '◀◀ -${widget.seconds}s',
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
  final PlayerState state;
  final PlaybackPreferences prefs;
  final bool isCover;
  final VoidCallback onToggleCover;
  final int? autoplayRemainingSeconds;
  final VideoResponseDto? nextVideo;
  final VoidCallback? onCancelAutoplay;
  final VoidCallback? onPlayNextNow;
  final VoidCallback? onReplay;
  final VoidCallback onMinimizeToMiniPlayer;
  final void Function(bool isForward) onDoubleTapSeek;

  const _PlayerControlsOverlay({
    required this.controller,
    required this.notifier,
    required this.videoId,
    required this.isFullscreen,
    required this.state,
    required this.prefs,
    required this.isCover,
    required this.onToggleCover,
    this.autoplayRemainingSeconds,
    this.nextVideo,
    this.onCancelAutoplay,
    this.onPlayNextNow,
    this.onReplay,
    required this.onMinimizeToMiniPlayer,
    required this.onDoubleTapSeek,
  });

  @override
  Widget build(BuildContext context) {
    final isLiveStream = notifier.isLiveStream;

    return Stack(
      children: [
        // 1. Background layer: tapping toggles controls, double-tapping seeks
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: notifier.toggleControls,
            onDoubleTapDown: prefs.doubleTapSeekEnabled
                ? (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    final width =
                        box?.size.width ?? MediaQuery.of(context).size.width;
                    final isForward = details.localPosition.dx >= width / 2;
                    if (isForward) {
                      notifier.seekForward();
                    } else {
                      notifier.seekBackward();
                    }
                    onDoubleTapSeek(isForward);
                  }
                : null,
            child: Container(color: Colors.black45),
          ),
        ),

        // 2. Top bar (Back/Minimize button, Title if fullscreen, Volume, Speed, Settings)
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
                tooltip: isFullscreen ? 'Exit fullscreen' : 'Minimize player',
                onPressed: () {
                  if (isFullscreen) {
                    notifier.toggleFullscreen();
                  } else {
                    onMinimizeToMiniPlayer();
                  }
                },
              ),
              if (isFullscreen && state.video != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      state.video!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Volume / Mute
                  IconButton(
                    icon: Icon(
                      state.isMuted || state.volume == 0.0
                          ? Icons.volume_off_rounded
                          : (state.volume < 0.5
                              ? Icons.volume_down_rounded
                              : Icons.volume_up_rounded),
                      color: Colors.white,
                    ),
                    tooltip: 'Mute / Unmute',
                    onPressed: notifier.toggleMute,
                  ),
                  // Speed
                  IconButton(
                    icon: const Icon(Icons.speed, color: Colors.white),
                    tooltip: 'Playback speed',
                    onPressed: () {
                      notifier.setInteractingWithControls(true);
                      PlayerSpeedSheet.show(context, videoId).then((_) {
                        notifier.setInteractingWithControls(false);
                      });
                    },
                  ),
                  // Picture-in-Picture
                  Consumer(
                    builder: (context, ref, _) {
                      final pipState = ref.watch(pipProvider);
                      if (!pipState.isSupported) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white),
                        tooltip: 'Picture-in-Picture',
                        onPressed: () {
                          final ratio = _computeVideoAspectRatio(controller);
                          ref.read(pipProvider.notifier).enterPip(aspectRatio: ratio);
                        },
                      );
                    },
                  ),
                  // Settings / Quality
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Settings',
                    onPressed: () {
                      notifier.setInteractingWithControls(true);
                      PlayerSettingsSheet.show(context, videoId).then((_) {
                        notifier.setInteractingWithControls(false);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Center controls - Play / Pause / Replay / Autoplay Next
        Center(
          child: state.isEnded && autoplayRemainingSeconds != null && nextVideo != null
              ? _AutoplayNextCard(
                  nextVideo: nextVideo!,
                  remainingSeconds: autoplayRemainingSeconds!,
                  onCancel: onCancelAutoplay ?? () {},
                  onPlayNow: onPlayNextNow ?? () {},
                )
              : ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, VideoPlayerValue value, child) {
                    final isEnded = state.isEnded;
                    final icon = isEnded
                        ? Icons.replay_rounded
                        : (value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded);
                    final tooltip = isEnded
                        ? 'Replay'
                        : (value.isPlaying ? 'Pause' : 'Play');

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 64,
                        color: Colors.white,
                        tooltip: tooltip,
                        icon: Icon(icon),
                        onPressed: isEnded
                            ? (onReplay ?? notifier.togglePlayPause)
                            : notifier.togglePlayPause,
                      ),
                    );
                  },
                ),
        ),

        // 4. Bottom timeline bar
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Listener(
                      onPointerDown: (_) =>
                          notifier.setInteractingWithControls(true),
                      onPointerUp: (_) =>
                          notifier.setInteractingWithControls(false),
                      onPointerCancel: (_) =>
                          notifier.setInteractingWithControls(false),
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: !isLiveStream,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        colors: const VideoProgressColors(
                          playedColor: Colors.red,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ),
                  ),
                  if (isLiveStream)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      _formatDuration(value.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      isCover
                          ? Icons.fit_screen_rounded
                          : Icons.crop_free_rounded,
                      color: Colors.white,
                    ),
                    tooltip: isCover ? 'Fit to screen' : 'Full width cover',
                    onPressed: onToggleCover,
                  ),
                  IconButton(
                    icon: Icon(
                      isFullscreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                      color: Colors.white,
                    ),
                    tooltip: isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
                    onPressed: notifier.toggleFullscreen,
                  ),
                ],
              );
            },
          ),
        ),
      ],
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

// ── Autoplay Next Card Overlay ────────────────────────────────────────────────

class _AutoplayNextCard extends StatelessWidget {
  final VideoResponseDto nextVideo;
  final int remainingSeconds;
  final VoidCallback onCancel;
  final VoidCallback onPlayNow;

  const _AutoplayNextCard({
    required this.nextVideo,
    required this.remainingSeconds,
    required this.onCancel,
    required this.onPlayNow,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: remainingSeconds / 5.0,
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Up next in ${remainingSeconds}s...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 90,
                    height: 52,
                    child: nextVideo.thumbnailUrl != null && nextVideo.thumbnailUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: nextVideo.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade900,
                              child: const Icon(Icons.videocam, color: Colors.white38),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade900,
                            child: const Icon(Icons.videocam, color: Colors.white38),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nextVideo.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextVideo.author.displayName ?? nextVideo.author.username ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: onCancel,
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: onPlayNow,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Play Now', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
