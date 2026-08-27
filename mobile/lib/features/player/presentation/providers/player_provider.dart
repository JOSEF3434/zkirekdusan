// lib/features/player/presentation/providers/player_provider.dart
// Advanced player with Cloudinary streaming, multi-URL fallback, and progress restore.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/player/data/player_repository.dart';
import 'package:mobile/features/media_experience/data/playback_progress_repository.dart';
import 'package:mobile/features/media_experience/domain/playback_progress.dart';
import 'package:mobile/features/media_experience/presentation/providers/playback_preferences_provider.dart';

import 'package:mobile/core/utils/media_url_resolver.dart';

class PlayerState {
  final VideoResponseDto? video;
  final VideoPlayerController? controller;
  final bool isLoading;
  final String? error;
  final List<VideoResponseDto> recommendations;
  final VideoRenditionDto? currentRendition;
  final bool showControls;
  final bool isBuffering;
  final bool isFullscreen;
  final double playbackSpeed;
  final String? activeStreamUrl;

  /// Restored position in seconds (-1 means no restore).
  final int resumePositionSeconds;

  const PlayerState({
    this.video,
    this.controller,
    this.isLoading = true,
    this.error,
    this.recommendations = const [],
    this.currentRendition,
    this.showControls = true,
    this.isBuffering = false,
    this.isFullscreen = false,
    this.playbackSpeed = 1.0,
    this.resumePositionSeconds = -1,
    this.activeStreamUrl,
  });

  PlayerState copyWith({
    VideoResponseDto? video,
    VideoPlayerController? controller,
    bool? isLoading,
    String? error,
    List<VideoResponseDto>? recommendations,
    VideoRenditionDto? currentRendition,
    bool? showControls,
    bool? isBuffering,
    bool? isFullscreen,
    double? playbackSpeed,
    int? resumePositionSeconds,
    String? activeStreamUrl,
  }) {
    return PlayerState(
      video: video ?? this.video,
      controller: controller ?? this.controller,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      recommendations: recommendations ?? this.recommendations,
      currentRendition: currentRendition ?? this.currentRendition,
      showControls: showControls ?? this.showControls,
      isBuffering: isBuffering ?? this.isBuffering,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      resumePositionSeconds:
          resumePositionSeconds ?? this.resumePositionSeconds,
      activeStreamUrl: activeStreamUrl ?? this.activeStreamUrl,
    );
  }
}

final playerProvider = StateNotifierProvider.autoDispose
    .family<PlayerNotifier, PlayerState, String>((ref, videoId) {
      return PlayerNotifier(
        ref.watch(playerRepositoryProvider),
        ref.watch(playbackProgressRepositoryProvider),
        videoId,
        ref.read(playbackPreferencesProvider).defaultSpeed,
      );
    });

class PlayerNotifier extends StateNotifier<PlayerState> {
  final PlayerRepository _repository;
  final PlaybackProgressRepository _progressRepo;
  final String _videoId;

  Timer? _progressTimer;
  Timer? _controlsHideTimer;
  bool _qualitySwitching = false;
  int _lastSavedPosition = 0;

  PlayerNotifier(
    this._repository,
    this._progressRepo,
    this._videoId,
    double initialSpeed,
  ) : super(PlayerState(playbackSpeed: initialSpeed)) {
    _initialize();
  }

  // ── Cloudinary URL utilities ────────────────────────────────────────────

  /// Builds an ordered list of candidate playback URLs, from most-preferred to fallback.
  List<String> _buildCandidateUrls(VideoResponseDto video) {
    final candidates = <String>[];

    void addCandidate(String? raw) {
      if (raw == null || raw.trim().isEmpty) return;
      final resolved = MediaUrlResolver.resolve(raw);
      if (resolved != null &&
          resolved.isNotEmpty &&
          !candidates.contains(resolved)) {
        candidates.add(resolved);
      }
    }

    // ── 1. Primary: Direct HLS or file URL from backend ──────────────────────
    if (video.hlsUrl != null && video.hlsUrl!.isNotEmpty) {
      final resolved = MediaUrlResolver.resolve(video.hlsUrl!);
      if (resolved != null) {
        // Add the direct URL provided by the backend first!
        addCandidate(resolved);

        if (MediaUrlResolver.isCloudinary(resolved)) {
          // Add Cloudinary MP4 direct streaming
          addCandidate(MediaUrlResolver.toCloudinaryMp4(resolved));
          if (!resolved.contains('.m3u8')) {
            addCandidate(MediaUrlResolver.toCloudinaryHls(resolved));
          }
        } else {
          // If local HLS (.m3u8), also add direct MP4 fallback
          if (resolved.endsWith('.m3u8')) {
            final mp4Fallback = resolved.replaceAll(RegExp(r'\.m3u8$'), '.mp4');
            addCandidate(mp4Fallback);
          }
        }
      }
    }

    // ── 2. Renditions (quality options from transcode) ──────────────────────
    for (final rendition in video.renditions) {
      if (rendition.url.isNotEmpty) {
        addCandidate(rendition.url);
        final resolved = MediaUrlResolver.resolve(rendition.url);
        if (resolved != null && MediaUrlResolver.isCloudinary(resolved)) {
          final res = rendition.resolution > 0 ? rendition.resolution : 720;
          addCandidate(MediaUrlResolver.toCloudinaryRendition(resolved, res));
        }
      }
    }

    // ── 3. DASH stream URL fallback ─────────────────────────────────────────
    if (video.dashUrl != null && video.dashUrl!.isNotEmpty) {
      addCandidate(video.dashUrl);
    }

    return candidates;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controlsHideTimer?.cancel();
    _flushProgress();
    state.controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      // Load local progress first for restore decision
      final localProgress = _progressRepo.load(_videoId);
      final video = await _repository.getVideo(_videoId);

      final candidateUrls = _buildCandidateUrls(video);

      if (candidateUrls.isEmpty) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            error: 'No video stream available for this video.',
          );
        }
        return;
      }

      // Determine resume position
      int resumePos = 0;
      if (localProgress != null &&
          !localProgress.isTrivial &&
          !localProgress.isComplete) {
        resumePos = localProgress.positionSeconds;
      }

      VideoPlayerController? initializedController;
      String? successUrl;

      // Try candidates in order — stop at first success
      for (final url in candidateUrls) {
        try {
          final uri = Uri.tryParse(url);
          if (uri == null) continue;

          final ctrl = VideoPlayerController.networkUrl(
            uri,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: false,
              allowBackgroundPlayback: false,
            ),
          );
          await ctrl.initialize().timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              ctrl.dispose();
              throw TimeoutException('Timed out initializing: $url');
            },
          );
          if (ctrl.value.hasError) {
            ctrl.dispose();
            continue;
          }
          initializedController = ctrl;
          successUrl = url;
          break;
        } catch (_) {
          // Try next candidate URL
        }
      }

      if (initializedController == null) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            error:
                'Unable to play video. The video stream source is currently unreachable.\n\nPlease check your internet connection and try again.',
          );
        }
        return;
      }

      final controller = initializedController;

      // Apply saved playback speed
      await controller.setPlaybackSpeed(state.playbackSpeed);

      // Seek to saved position if applicable
      if (resumePos > 0) {
        await controller.seekTo(Duration(seconds: resumePos));
      }

      controller.play();
      controller.addListener(_onControllerUpdate);

      // Throttled progress timer every 5 seconds
      _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _maybeSaveProgress(video);
      });

      // Fetch recommendations in background
      _repository
          .getRecommended(_videoId)
          .then((res) {
            if (mounted) {
              state = state.copyWith(recommendations: res.data);
            }
          })
          .catchError((_) {});

      if (mounted) {
        state = state.copyWith(
          video: video,
          controller: controller,
          isLoading: false,
          resumePositionSeconds: resumePos,
          activeStreamUrl: successUrl,
          currentRendition:
              video.renditions.isNotEmpty ? video.renditions.first : null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final ctrl = state.controller;
    if (ctrl == null) return;
    final isBuffering = ctrl.value.isBuffering;
    if (state.isBuffering != isBuffering) {
      state = state.copyWith(isBuffering: isBuffering);
    }
  }

  void _maybeSaveProgress(VideoResponseDto video) {
    final ctrl = state.controller;
    if (ctrl == null || !ctrl.value.isInitialized || !ctrl.value.isPlaying) {
      return;
    }
    final positionSec = ctrl.value.position.inSeconds;
    final durationSec = ctrl.value.duration.inSeconds;

    if ((positionSec - _lastSavedPosition).abs() < 5) return;
    _lastSavedPosition = positionSec;

    final progress = PlaybackProgress(
      videoId: _videoId,
      videoTitle: video.title,
      thumbnailUrl: video.thumbnailUrl,
      positionSeconds: positionSec,
      durationSeconds: durationSec,
      updatedAt: DateTime.now(),
    );

    _progressRepo.save(progress);
    _repository.saveProgress(_videoId, positionSec);
  }

  void _flushProgress() {
    final video = state.video;
    final ctrl = state.controller;
    if (video == null || ctrl == null || !ctrl.value.isInitialized) return;
    final positionSec = ctrl.value.position.inSeconds;
    final durationSec = ctrl.value.duration.inSeconds;
    if (positionSec <= 0) return;

    final progress = PlaybackProgress(
      videoId: _videoId,
      videoTitle: video.title,
      thumbnailUrl: video.thumbnailUrl,
      positionSeconds: positionSec,
      durationSeconds: durationSec,
      updatedAt: DateTime.now(),
    );
    _progressRepo.save(progress);
  }

  // ── Public control methods ────────────────────────────────────────────────

  void togglePlayPause() {
    final ctrl = state.controller;
    if (ctrl == null) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
    _resetControlsTimer();
  }

  void seekTo(Duration position) {
    state.controller?.seekTo(position);
    _resetControlsTimer();
  }

  void seekForward() {
    final ctrl = state.controller;
    if (ctrl == null) return;
    final newPos = ctrl.value.position + const Duration(seconds: 10);
    final duration = ctrl.value.duration;
    seekTo(newPos > duration ? duration : newPos);
  }

  void seekBackward() {
    final ctrl = state.controller;
    if (ctrl == null) return;
    final newPos = ctrl.value.position - const Duration(seconds: 10);
    seekTo(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void toggleControls() {
    state = state.copyWith(showControls: !state.showControls);
    if (state.showControls) _resetControlsTimer();
  }

  void showControlsNow() {
    state = state.copyWith(showControls: true);
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && state.controller?.value.isPlaying == true) {
        state = state.copyWith(showControls: false);
      }
    });
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await state.controller?.setPlaybackSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  Future<void> setQuality(VideoRenditionDto rendition) async {
    if (_qualitySwitching) return;
    if (state.currentRendition?.id == rendition.id) return;
    if (rendition.url.isEmpty) return;

    _qualitySwitching = true;
    final currentPosition = state.controller?.value.position ?? Duration.zero;
    final wasPlaying = state.controller?.value.isPlaying ?? false;

    final oldController = state.controller;

    try {
      // For Cloudinary/local renditions, resolve the URL properly
      final resolvedUrl =
          MediaUrlResolver.resolve(rendition.url) ?? rendition.url;
      final newController = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
      );
      await newController.initialize();
      await newController.seekTo(currentPosition);
      await newController.setPlaybackSpeed(state.playbackSpeed);
      if (wasPlaying) newController.play();

      newController.addListener(_onControllerUpdate);

      if (mounted) {
        state = state.copyWith(
          controller: newController,
          currentRendition: rendition,
          activeStreamUrl: resolvedUrl,
        );
      }

      oldController?.removeListener(_onControllerUpdate);
      oldController?.dispose();
    } catch (_) {
      if (mounted) {
        state = state.copyWith(error: 'Could not switch quality.');
      }
    } finally {
      _qualitySwitching = false;
    }
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void onAppPause() => _flushProgress();
}
