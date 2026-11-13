// lib/features/player/presentation/providers/player_provider.dart
// Advanced player with Cloudinary streaming, multi-URL fallback, and progress restore.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/storage/file_system.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/media_experience/data/playback_progress_repository.dart';
import 'package:mobile/features/media_experience/domain/playback_progress.dart';
import 'package:mobile/features/media_experience/domain/playback_preferences.dart';
import 'package:mobile/features/media_experience/presentation/providers/playback_preferences_provider.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';
import 'package:mobile/core/services/pip_service.dart';
import 'package:mobile/features/player/data/player_repository.dart';

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
  final bool isOfflinePlayback;

  /// Restored position in seconds (-1 means no restore).
  final int resumePositionSeconds;
  final double volume;
  final bool isMuted;
  final bool isEnded;

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
    this.isOfflinePlayback = false,
    this.volume = 1.0,
    this.isMuted = false,
    this.isEnded = false,
  });

  PlayerState copyWith({
    VideoResponseDto? video,
    VideoPlayerController? controller,
    bool clearController = false,
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
    bool? isOfflinePlayback,
    double? volume,
    bool? isMuted,
    bool? isEnded,
  }) {
    return PlayerState(
      video: video ?? this.video,
      controller: clearController ? null : (controller ?? this.controller),
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
      isOfflinePlayback: isOfflinePlayback ?? this.isOfflinePlayback,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isEnded: isEnded ?? this.isEnded,
    );
  }
}

final playerProvider = StateNotifierProvider.autoDispose
    .family<PlayerNotifier, PlayerState, String>((ref, videoId) {
      // Reuse the controller and metadata from the mini-player only if the current content matches.
      // We intentionally avoid mutating the mini-player provider here because provider
      // initialization must not trigger state updates on another provider.
      final mini = ref.read(miniPlayerProvider);
      final isMatching = mini.contentId == videoId;
      final existingCtrl = isMatching ? mini.controller : null;
      final wasPlayingOnHandOff = isMatching
          ? (mini.isPlaying ||
              mini.wasPlayingBeforeHandoff ||
              ref.read(miniPlayerProvider.notifier).lastReclaimedWasPlaying)
          : null;

      VideoResponseDto? initialVideo;
      if (isMatching && mini.hasContent) {
        initialVideo = VideoResponseDto(
          id: videoId,
          title: mini.title ?? 'Video',
          thumbnailUrl: mini.thumbnailUrl,
          status: VideoStatus.ready,
          visibility: 'PUBLIC',
          isDownloadable: true,
          author: PostAuthorDto(
            id: '',
            username: mini.channelName ?? '',
            displayName: mini.channelName,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      final initialPrefs = ref.read(playbackPreferencesProvider);
      final notifier = PlayerNotifier(
        ref.watch(playerRepositoryProvider),
        ref.watch(playbackProgressRepositoryProvider),
        ref.watch(storageServiceProvider),
        videoId,
        initialPrefs,
        existingController: existingCtrl,
        initialVideo: initialVideo,
        wasPlayingOnHandOff: wasPlayingOnHandOff,
      );

      // Listen to playback preference changes without tearing down the player session
      ref.listen<PlaybackPreferences>(playbackPreferencesProvider, (prev, next) {
        notifier.updatePreferences(next);
      });

      return notifier;
    });

class PlayerNotifier extends StateNotifier<PlayerState> {
  final PlayerRepository _repository;
  final PlaybackProgressRepository _progressRepo;
  final StorageService _storage;
  final String _videoId;
  PlaybackPreferences _playbackPreferences;

  Timer? _progressTimer;
  Timer? _controlsHideTimer;
  Timer? _handoffTimer;
  final List<Timer> _retryTimers = [];
  bool _isHandoffInProgress = false;
  bool _qualitySwitching = false;
  int _lastSavedPosition = 0;
  bool _isInteractingWithControls = false;
  double _lastVolumeBeforeMute = 1.0;

  void _cancelRetryTimers() {
    for (final t in _retryTimers) {
      t.cancel();
    }
    _retryTimers.clear();
  }

  void _ensurePlayback(VideoPlayerController ctrl) {
    if (!ctrl.value.isInitialized) return;
    ctrl.play().catchError((_) {});
    _cancelRetryTimers();
    _retryTimers.add(Timer(const Duration(milliseconds: 150), () {
      if (!mounted || state.controller != ctrl) return;
      if (!ctrl.value.isPlaying && ctrl.value.isInitialized) {
        ctrl.play().catchError((_) {});
      }
    }));
    _retryTimers.add(Timer(const Duration(milliseconds: 400), () {
      if (!mounted || state.controller != ctrl) return;
      if (!ctrl.value.isPlaying && ctrl.value.isInitialized) {
        ctrl.play().catchError((_) {});
      }
    }));
    _retryTimers.add(Timer(const Duration(milliseconds: 800), () {
      if (!mounted || state.controller != ctrl) return;
      if (!ctrl.value.isPlaying && ctrl.value.isInitialized) {
        ctrl.play().catchError((_) {});
      }
    }));
  }

  PlayerNotifier(
    this._repository,
    this._progressRepo,
    this._storage,
    this._videoId,
    this._playbackPreferences, {
    VideoPlayerController? existingController,
    VideoResponseDto? initialVideo,
    bool? wasPlayingOnHandOff,
  }) : super(
         PlayerState(
           playbackSpeed: existingController?.value.playbackSpeed ??
               _playbackPreferences.defaultSpeed,
           controller: existingController,
           video: initialVideo,
           isLoading: existingController == null,
           volume: existingController?.value.volume ?? 1.0,
           isMuted: (existingController?.value.volume ?? 1.0) == 0.0,
         ),
       ) {
    if (existingController != null && existingController.value.isInitialized) {
      try {
        existingController.removeListener(_onControllerUpdate);
      } catch (_) {}
      existingController.addListener(_onControllerUpdate);
      if (wasPlayingOnHandOff == true) {
        _isHandoffInProgress = true;
        _handoffTimer?.cancel();
        _handoffTimer = Timer(const Duration(milliseconds: 1500), () {
          _isHandoffInProgress = false;
        });
        _ensurePlayback(existingController);
      }
    }
    _initialize(existingController: existingController);
  }

  /// Updates playback preferences in real time
  void updatePreferences(PlaybackPreferences newPrefs) {
    _playbackPreferences = newPrefs;
    if (!_playbackPreferences.autoHideControls) {
      _controlsHideTimer?.cancel();
      if (!state.showControls) {
        state = state.copyWith(showControls: true);
      }
    } else {
      _resetControlsTimer();
    }
  }

  /// Sets whether user is currently scrubbing or actively holding controls
  void setInteractingWithControls(bool interacting) {
    _isInteractingWithControls = interacting;
    if (interacting) {
      _controlsHideTimer?.cancel();
    } else {
      _resetControlsTimer();
    }
  }

  /// Triggered on mouse hover or tap to reveal controls and reset auto-hide countdown
  void onUserInteraction() {
    if (!state.showControls) {
      state = state.copyWith(showControls: true);
    }
    _resetControlsTimer();
  }

  /// Seamlessly adopt an active VideoPlayerController (e.g. handed off from MiniPlayer)
  void adoptController(VideoPlayerController ctrl, {bool? wasPlaying}) {
    final oldController = state.controller;
    if (oldController != null && oldController != ctrl) {
      try {
        oldController.removeListener(_onControllerUpdate);
      } catch (_) {}
    }

    try {
      ctrl.removeListener(_onControllerUpdate);
    } catch (_) {}
    ctrl.addListener(_onControllerUpdate);

    final shouldPlay = wasPlaying ?? ctrl.value.isPlaying;
    if (shouldPlay) {
      _isHandoffInProgress = true;
      _handoffTimer?.cancel();
      _handoffTimer = Timer(const Duration(milliseconds: 1500), () {
        _isHandoffInProgress = false;
      });
      _ensurePlayback(ctrl);
    }

    state = state.copyWith(
      controller: ctrl,
      isLoading: false,
      volume: ctrl.value.volume,
      isMuted: ctrl.value.volume == 0.0,
      playbackSpeed: ctrl.value.playbackSpeed,
    );

    if (ctrl.value.isPlaying || shouldPlay) {
      _resetControlsTimer();
    } else {
      state = state.copyWith(showControls: true);
    }
  }

  // ── Cloudinary URL utilities ────────────────────────────────────────────

  /// Builds an ordered list of candidate playback URLs, from most-preferred to fallback.
  List<String> _buildCandidateUrls(VideoResponseDto video) {
    final candidates = <String>[];

    void addCandidate(String? raw) {
      if (raw == null || raw.trim().isEmpty) return;
      final resolved = MediaUrlResolver.resolve(raw);
      if (resolved != null &&
          resolved.trim().isNotEmpty &&
          !candidates.contains(resolved)) {
        candidates.add(resolved);
      }
    }

    // ── 1. Primary HLS or direct stream/video URL from backend ────────────────
    if (video.hlsUrl != null && video.hlsUrl!.isNotEmpty) {
      final resolved = MediaUrlResolver.resolve(video.hlsUrl!);
      if (resolved != null) {
        addCandidate(resolved);
        if (MediaUrlResolver.isCloudinary(resolved)) {
          addCandidate(MediaUrlResolver.toCloudinaryMp4(resolved));
          addCandidate(MediaUrlResolver.toCloudinaryRaw(resolved));
        } else if (resolved.endsWith('.m3u8')) {
          final mp4Fallback = resolved.replaceAll(RegExp(r'\.m3u8$'), '.mp4');
          addCandidate(mp4Fallback);
        }
      }
    }

    // ── 2. Direct raw file / sourceFileUrl ────────────────────────────────────
    if (video.sourceFileUrl != null && video.sourceFileUrl!.isNotEmpty) {
      final resolved = MediaUrlResolver.resolve(video.sourceFileUrl!);
      if (resolved != null) {
        addCandidate(resolved);
        if (MediaUrlResolver.isCloudinary(resolved)) {
          addCandidate(MediaUrlResolver.toCloudinaryMp4(resolved));
          addCandidate(MediaUrlResolver.toCloudinaryRaw(resolved));
        }
      }
    }

    // ── 3. Renditions (quality options from transcode) ────────────────────────
    for (final rendition in video.renditions) {
      if (rendition.url.isNotEmpty) {
        final resolved = MediaUrlResolver.resolve(rendition.url);
        if (resolved != null) {
          addCandidate(resolved);
          if (MediaUrlResolver.isCloudinary(resolved)) {
            addCandidate(MediaUrlResolver.toCloudinaryMp4(resolved));
            addCandidate(MediaUrlResolver.toCloudinaryRaw(resolved));
          }
        }
      }
    }

    // ── 4. DASH stream URL fallback ──────────────────────────────────────────
    if (video.dashUrl != null && video.dashUrl!.isNotEmpty) {
      addCandidate(video.dashUrl);
    }

    return candidates;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    PipService.instance.disableAutoPip();
    _handoffTimer?.cancel();
    _cancelRetryTimers();
    _progressTimer?.cancel();
    _controlsHideTimer?.cancel();
    _flushProgress();
    final ctrl = state.controller;
    if (ctrl != null) {
      try {
        ctrl.removeListener(_onControllerUpdate);
        ctrl.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  /// Transfer controller ownership to MiniPlayer.
  /// Must be called BEFORE this notifier is disposed (i.e. before context.pop()).
  /// After this call, dispose() will not touch the controller.
  void detachController() {
    _progressTimer?.cancel();
    _controlsHideTimer?.cancel();
    _flushProgress();
    final ctrl = state.controller;
    if (ctrl != null) {
      try {
        ctrl.removeListener(_onControllerUpdate);
      } catch (_) {}
    }
    state = state.copyWith(clearController: true);
  }

  Future<void> _initialize({VideoPlayerController? existingController}) async {
    try {
      // Load local progress first for restore decision
      final localProgress = _progressRepo.load(_videoId);

      // ── Offline download resolution ──────────────────────────────────────
      // On native: look for local file path on disk.
      // On web: look for stored blob URL in localStorage (persisted by DownloadService).
      String? localFileUrl; // file:// or blob: URL
      String? localFilePath; // native: raw filesystem path (null on web)
      String? offlineTitle;
      String? offlineThumbnail;

      final dlData = await _storage.getToken(key: 'offline_downloads');
      if (dlData != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(dlData);
          if (decoded.containsKey(_videoId)) {
            final item = decoded[_videoId] as Map<String, dynamic>;
            final localPath = item['localPath'] as String?;
            offlineTitle = item['title'] as String?;
            offlineThumbnail = item['thumbnailUrl'] as String?;

            if (localPath != null && localPath.isNotEmpty) {
              if (kIsWeb && localPath.startsWith('blob:')) {
                // Web: blob URL is the playable source directly
                localFileUrl = localPath;
                // We don't set localFilePath on web — blob: is already a URL
              } else if (!kIsWeb &&
                  await FileSystemHelper.fileExists(localPath)) {
                localFilePath = localPath;
                localFileUrl = Uri.file(localPath).toString();
              }
            }
          }
        } catch (_) {}
      }

      // Native fallback: read the on-disk metadata.json
      if (!kIsWeb && localFilePath == null) {
        try {
          final docDir = await FileSystemHelper.getApplicationDocumentsPath();
          final metaFile = File('$docDir/videos/video_$_videoId/metadata.json');
          if (await metaFile.exists()) {
            final Map<String, dynamic> decoded = jsonDecode(
              await metaFile.readAsString(),
            );
            final localPath = decoded['localPath'] as String?;
            offlineTitle = decoded['title'] as String?;
            offlineThumbnail = decoded['thumbnailUrl'] as String?;
            if (localPath != null &&
                await FileSystemHelper.fileExists(localPath)) {
              localFilePath = localPath;
              localFileUrl = Uri.file(localPath).toString();
            }
          }
        } catch (_) {}
      }

      VideoResponseDto video;
      try {
        video = await _repository.getVideo(_videoId);
      } catch (repoErr) {
        if (state.video != null) {
          video = state.video!;
        } else if (localFilePath != null || localFileUrl != null) {
          // Play in offline mode using cached download metadata
          video = VideoResponseDto(
            id: _videoId,
            title: offlineTitle ?? 'Downloaded Video',
            thumbnailUrl: offlineThumbnail,
            status: VideoStatus.ready,
            visibility: 'PUBLIC',
            isDownloadable: true,
            author: const PostAuthorDto(id: '', username: 'Offline Download'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        } else {
          rethrow;
        }
      }

      if (mounted) {
        state = state.copyWith(
          video: video,
          currentRendition: video.renditions.isNotEmpty
              ? video.renditions.first
              : null,
        );
      }

      final activeCtrl = state.controller ?? existingController;
      // If we are adopting an existing controller from MiniPlayer, bind and return immediately
      if (activeCtrl != null && activeCtrl.value.isInitialized) {
        try {
          activeCtrl.removeListener(_onControllerUpdate);
        } catch (_) {}
        activeCtrl.addListener(_onControllerUpdate);
        _progressTimer?.cancel();
        _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          if (state.video != null) {
            _maybeSaveProgress(state.video!);
          }
        });

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
            controller: activeCtrl,
            isLoading: false,
            currentRendition: video.renditions.isNotEmpty
                ? video.renditions.first
                : null,
          );
        }
        return;
      }

      final candidateUrls = <String>[];
      if (localFilePath != null) {
        candidateUrls.add(localFilePath);
      }
      if (localFileUrl != null && !candidateUrls.contains(localFileUrl)) {
        candidateUrls.add(localFileUrl);
      }
      candidateUrls.addAll(_buildCandidateUrls(video));

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
          // A URL is a native local file if it has a local filesystem path
          // OR starts with file://. Web blob: URLs are played via networkUrl.
          final isNativeLocalFile =
              !kIsWeb &&
              ((localFilePath != null &&
                      (url == localFilePath || url == localFileUrl)) ||
                  url.startsWith('file://') ||
                  (!url.startsWith('http://') &&
                      !url.startsWith('https://') &&
                      !url.startsWith('blob:')));

          final VideoPlayerController ctrl;
          if (isNativeLocalFile) {
            final path = (localFilePath != null && url == localFilePath)
                ? localFilePath
                : (url.startsWith('file://')
                      ? Uri.parse(url).toFilePath()
                      : url);
            ctrl = VideoPlayerController.file(
              File(path),
              videoPlayerOptions: VideoPlayerOptions(
                mixWithOthers: false,
                allowBackgroundPlayback: true,
              ),
            );
          } else {
            final uri = Uri.tryParse(url);
            if (uri == null) continue;
            ctrl = VideoPlayerController.networkUrl(
              uri,
              videoPlayerOptions: VideoPlayerOptions(
                mixWithOthers: false,
                allowBackgroundPlayback: true,
              ),
            );
          }

          await ctrl.initialize().timeout(
            const Duration(seconds: 15),
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
        } catch (candidateErr) {
          developer.log(
            'Candidate URL failed [$url]: $candidateErr',
            name: 'PlayerNotifier',
          );
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
      final ratio = controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9;
      PipService.instance.enableAutoPip(
        isPlaying: true,
        aspectRatio: ratio,
        title: video.title,
      );

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

      // Offline if we played from a native local file or a web blob URL
      final isOffline =
          (localFilePath != null &&
              (successUrl == localFilePath || successUrl == localFileUrl)) ||
          (kIsWeb &&
              localFileUrl != null &&
              localFileUrl.startsWith('blob:') &&
              successUrl == localFileUrl);

      if (mounted) {
        state = state.copyWith(
          video: video,
          controller: controller,
          isLoading: false,
          resumePositionSeconds: resumePos,
          activeStreamUrl: successUrl,
          isOfflinePlayback: isOffline,
          currentRendition: video.renditions.isNotEmpty
              ? video.renditions.first
              : null,
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
    final isPlaying = ctrl.value.isPlaying;
    if (state.isBuffering != isBuffering) {
      state = state.copyWith(isBuffering: isBuffering);
    }
    // Involuntary pause during DOM attachment / platform view transfer on Web
    if (_isHandoffInProgress && !isPlaying) {
      ctrl.play().catchError((_) {});
      return;
    }
    PipService.instance.updatePlaybackState(isPlaying: isPlaying);

    final isInitialized = ctrl.value.isInitialized;
    final duration = ctrl.value.duration;
    final position = ctrl.value.position;

    // Detect if video has reached the end
    final hasEnded = !isLiveStream &&
        isInitialized &&
        duration > const Duration(seconds: 1) &&
        (position >= duration ||
            (!isPlaying &&
                position > Duration.zero &&
                position >= duration - const Duration(milliseconds: 600)));

    if (hasEnded) {
      if (!state.isEnded) {
        state = state.copyWith(isEnded: true, showControls: true);
        if (state.recommendations.isEmpty) {
          _repository.getRecommended(_videoId).then((res) {
            if (mounted) {
              state = state.copyWith(recommendations: res.data);
            }
          }).catchError((_) {});
        }
      }
    } else if (state.isEnded && isPlaying) {
      state = state.copyWith(isEnded: false);
    }

    // When video pauses (e.g. ended or buffering pause), reveal controls automatically
    if (!isPlaying && !state.showControls) {
      state = state.copyWith(showControls: true);
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
    _repository.saveProgress(_videoId, positionSec);
  }

  // ── Public control methods ────────────────────────────────────────────────

  bool get isLiveStream {
    final video = state.video;
    if (video != null && video.isStream) return true;
    final ctrl = state.controller;
    if (ctrl != null &&
        ctrl.value.isInitialized &&
        ctrl.value.duration == Duration.zero) {
      return true;
    }
    return false;
  }

  void togglePlayPause() {
    final ctrl = state.controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state.isEnded) {
      state = state.copyWith(isEnded: false);
      ctrl.seekTo(Duration.zero);
      ctrl.play();
      PipService.instance.updatePlaybackState(isPlaying: true);
      _resetControlsTimer();
      return;
    }
    final willPlay = !ctrl.value.isPlaying;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
      _flushProgress();
    } else {
      ctrl.play();
    }
    PipService.instance.updatePlaybackState(isPlaying: willPlay);
    _resetControlsTimer();
  }

  void seekTo(Duration position) {
    if (isLiveStream) return;
    state.controller?.seekTo(position);
    if (state.isEnded) {
      state = state.copyWith(isEnded: false);
    }
    _resetControlsTimer();
    _flushProgress();
  }

  void seekForward([int? seconds]) {
    final ctrl = state.controller;
    if (ctrl == null || !ctrl.value.isInitialized || isLiveStream) return;
    final seekSec = seconds ?? _playbackPreferences.seekForwardSeconds;
    final newPos = ctrl.value.position + Duration(seconds: seekSec);
    final duration = ctrl.value.duration;
    seekTo(newPos > duration ? duration : newPos);
  }

  void seekBackward([int? seconds]) {
    final ctrl = state.controller;
    if (ctrl == null || !ctrl.value.isInitialized || isLiveStream) return;
    final seekSec = seconds ?? _playbackPreferences.seekBackwardSeconds;
    final newPos = ctrl.value.position - Duration(seconds: seekSec);
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
    // Do not auto-hide if disabled, if user is actively interacting, or if video is paused
    if (!_playbackPreferences.autoHideControls) return;
    if (_isInteractingWithControls) return;

    final delay = Duration(seconds: _playbackPreferences.autoHideDelaySeconds);
    _controlsHideTimer = Timer(delay, () {
      if (mounted &&
          state.controller?.value.isPlaying == true &&
          !_isInteractingWithControls &&
          _playbackPreferences.autoHideControls) {
        state = state.copyWith(showControls: false);
      }
    });
  }

  void setVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    state.controller?.setVolume(clamped);
    if (clamped > 0) {
      _lastVolumeBeforeMute = clamped;
    }
    state = state.copyWith(
      volume: clamped,
      isMuted: clamped == 0.0,
    );
  }

  void toggleMute() {
    if (state.isMuted || state.volume == 0.0) {
      final restoreVol =
          _lastVolumeBeforeMute > 0 ? _lastVolumeBeforeMute : 1.0;
      setVolume(restoreVol);
    } else {
      _lastVolumeBeforeMute = state.volume > 0 ? state.volume : 1.0;
      setVolume(0.0);
    }
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
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: true,
        ),
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
    final ctrl = state.controller;
    final wasPlaying = ctrl != null && ctrl.value.isInitialized && ctrl.value.isPlaying;
    state = state.copyWith(isFullscreen: !state.isFullscreen);
    if (wasPlaying) {
      _isHandoffInProgress = true;
      _handoffTimer?.cancel();
      _handoffTimer = Timer(const Duration(milliseconds: 1500), () {
        _isHandoffInProgress = false;
      });
      _ensurePlayback(ctrl);
      _resetControlsTimer();
    }
  }

  void onAppPause() => _flushProgress();
}
