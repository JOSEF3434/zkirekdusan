// lib/core/presentation/providers/mini_player_provider.dart
// Global persistent mini-player state and controller lifecycle management.
// Supports both live streams and VOD videos with seamless handoff,
// draggable position persistence, play/pause controls, and clean resource release.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/services/pip_service.dart';
import 'package:mobile/features/media_experience/data/playback_progress_repository.dart';
import 'package:mobile/features/media_experience/domain/playback_progress.dart';

enum MiniPlayerType { video, live }

class MiniPlayerState {
  /// When true, the floating mini player is visible.
  final bool isVisible;

  final MiniPlayerType type;

  // -- Content metadata --
  final String? contentId; // videoId or streamId
  final String? title;
  final String? channelName;
  final String? thumbnailUrl;
  final String? avatarUrl;

  // -- Player controller --
  final VideoPlayerController? controller;

  // -- Live-specific fields --
  final String? hlsUrl;

  // -- Lifecycle state --
  /// True when the live stream has definitively ended while the MiniPlayer was visible.
  /// Does NOT auto-dismiss — user controls when to close.
  final bool isEnded;

  /// Duration in seconds when the stream ended, if available.
  final int? endedDurationSeconds;

  // -- Playback and UI state --
  final bool isPlaying;
  final bool wasPlayingBeforeHandoff;
  final bool isHandoffInProgress;
  final Offset? position; // Dragged position on screen
  final bool isNavigatingToFull; // Controller handoff flag

  const MiniPlayerState({
    this.isVisible = false,
    this.type = MiniPlayerType.video,
    this.contentId,
    this.title,
    this.channelName,
    this.thumbnailUrl,
    this.avatarUrl,
    this.controller,
    this.hlsUrl,
    this.isEnded = false,
    this.endedDurationSeconds,
    this.isPlaying = true,
    this.wasPlayingBeforeHandoff = false,
    this.isHandoffInProgress = false,
    this.position,
    this.isNavigatingToFull = false,
  });

  MiniPlayerState copyWith({
    bool? isVisible,
    MiniPlayerType? type,
    String? contentId,
    String? title,
    String? channelName,
    String? thumbnailUrl,
    String? avatarUrl,
    VideoPlayerController? controller,
    bool clearController = false,
    String? hlsUrl,
    bool? isEnded,
    int? endedDurationSeconds,
    bool clearEndedDuration = false,
    bool? isPlaying,
    bool? wasPlayingBeforeHandoff,
    bool? isHandoffInProgress,
    Offset? position,
    bool? isNavigatingToFull,
  }) {
    return MiniPlayerState(
      isVisible: isVisible ?? this.isVisible,
      type: type ?? this.type,
      contentId: contentId ?? this.contentId,
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      controller: clearController ? null : (controller ?? this.controller),
      hlsUrl: hlsUrl ?? this.hlsUrl,
      isEnded: isEnded ?? this.isEnded,
      endedDurationSeconds: clearEndedDuration
          ? null
          : (endedDurationSeconds ?? this.endedDurationSeconds),
      isPlaying: isPlaying ?? this.isPlaying,
      wasPlayingBeforeHandoff:
          wasPlayingBeforeHandoff ?? this.wasPlayingBeforeHandoff,
      isHandoffInProgress: isHandoffInProgress ?? this.isHandoffInProgress,
      position: position ?? this.position,
      isNavigatingToFull: isNavigatingToFull ?? this.isNavigatingToFull,
    );
  }

  bool get hasContent => contentId != null && contentId!.isNotEmpty;
  bool get isLive => type == MiniPlayerType.live;
}

class MiniPlayerNotifier extends StateNotifier<MiniPlayerState> {
  final PlaybackProgressRepository? _progressRepo;

  MiniPlayerNotifier([this._progressRepo]) : super(const MiniPlayerState());

  VoidCallback? _controllerListener;
  Timer? _handoffTimer;
  final List<Timer> _retryTimers = [];
  bool _lastReclaimedWasPlaying = false;

  bool get lastReclaimedWasPlaying => _lastReclaimedWasPlaying;

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
      if (mounted &&
          state.controller == ctrl &&
          (state.isPlaying || state.wasPlayingBeforeHandoff)) {
        if (!ctrl.value.isPlaying && ctrl.value.isInitialized) {
          ctrl.play().catchError((_) {});
        }
      }
    }));
    _retryTimers.add(Timer(const Duration(milliseconds: 400), () {
      if (mounted &&
          state.controller == ctrl &&
          (state.isPlaying || state.wasPlayingBeforeHandoff)) {
        if (!ctrl.value.isPlaying && ctrl.value.isInitialized) {
          ctrl.play().catchError((_) {});
        }
      }
    }));
    _retryTimers.add(Timer(const Duration(milliseconds: 800), () {
      if (mounted &&
          state.controller == ctrl &&
          (state.isPlaying || state.wasPlayingBeforeHandoff)) {
        if (!ctrl.value.isPlaying && ctrl.value.isInitialized) {
          ctrl.play().catchError((_) {});
        }
      }
    }));
  }

  void _startHandoffGracePeriod(VideoPlayerController ctrl, bool shouldPlay) {
    _handoffTimer?.cancel();
    if (shouldPlay) {
      _ensurePlayback(ctrl);
    }
    _handoffTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && state.isHandoffInProgress) {
        state = state.copyWith(isHandoffInProgress: false);
      }
    });
  }

  // ── Show Video MiniPlayer ──────────────────────────────────────────────

  void showVideo({
    required String videoId,
    required String title,
    String? channelName,
    String? thumbnailUrl,
    String? avatarUrl,
    required VideoPlayerController controller,
    bool? wasPlaying,
  }) {
    if (state.controller != null && state.controller != controller) {
      _disposeCurrentController();
    }
    _bindController(controller);
    final isActuallyPlaying = wasPlaying ?? controller.value.isPlaying;
    _lastReclaimedWasPlaying = isActuallyPlaying;
    _startHandoffGracePeriod(controller, isActuallyPlaying);
    PipService.instance.enableAutoPip(
      isPlaying: isActuallyPlaying,
      aspectRatio: 16 / 9,
      title: title,
    );

    state = MiniPlayerState(
      isVisible: true,
      type: MiniPlayerType.video,
      contentId: videoId,
      title: title,
      channelName: channelName,
      thumbnailUrl: thumbnailUrl,
      avatarUrl: avatarUrl,
      controller: controller,
      isEnded: false,
      isPlaying: isActuallyPlaying,
      wasPlayingBeforeHandoff: isActuallyPlaying,
      isHandoffInProgress: true,
      position: state.position,
      isNavigatingToFull: false,
    );
  }

  // ── Show Live MiniPlayer ───────────────────────────────────────────────

  void showLive({
    required String streamId,
    required String title,
    String? channelName,
    String? thumbnailUrl,
    String? avatarUrl,
    required String hlsUrl,
    VideoPlayerController? controller,
    bool? wasPlaying,
  }) {
    if (state.controller != null &&
        controller != null &&
        state.controller != controller) {
      _disposeCurrentController();
    }
    final isActuallyPlaying =
        wasPlaying ?? (controller?.value.isPlaying ?? true);
    _lastReclaimedWasPlaying = isActuallyPlaying;

    if (controller != null) {
      _bindController(controller);
      _startHandoffGracePeriod(controller, isActuallyPlaying);
      PipService.instance.enableAutoPip(
        isPlaying: isActuallyPlaying,
        aspectRatio: 16 / 9,
        title: title,
      );
    }

    state = MiniPlayerState(
      isVisible: true,
      type: MiniPlayerType.live,
      contentId: streamId,
      title: title,
      channelName: channelName,
      thumbnailUrl: thumbnailUrl,
      avatarUrl: avatarUrl,
      hlsUrl: hlsUrl,
      controller: controller,
      isEnded: false,
      isPlaying: isActuallyPlaying,
      wasPlayingBeforeHandoff: isActuallyPlaying,
      isHandoffInProgress: true,
      position: state.position,
      isNavigatingToFull: false,
    );
  }

  // ── Mark stream as ended while MiniPlayer is visible ─────────────────

  /// Pauses playback, sets isEnded = true.
  /// Does NOT auto-dismiss — user controls when to close.
  void markEnded({int? durationSeconds}) {
    if (!state.hasContent) return;
    PipService.instance.disableAutoPip();
    try {
      final ctrl = state.controller;
      if (ctrl != null && ctrl.value.isInitialized && ctrl.value.isPlaying) {
        ctrl.pause();
      }
    } catch (e) {
      debugPrint('[MiniPlayer] markEnded pause error: $e');
    }
    state = state.copyWith(
      isEnded: true,
      isPlaying: false,
      endedDurationSeconds: durationSeconds,
    );
  }

  /// Only acts if the given streamId matches the current MiniPlayer content.
  void markEndedForStream(String streamId, {int? durationSeconds}) {
    if (state.contentId == streamId && state.isLive) {
      markEnded(durationSeconds: durationSeconds);
    }
  }

  void updateLiveController(VideoPlayerController ctrl) {
    _bindController(ctrl);
    state = state.copyWith(
      controller: ctrl,
      isPlaying: ctrl.value.isPlaying,
    );
  }

  void syncPlaybackState(VideoPlayerController ctrl) {
    if (!mounted || state.controller != ctrl) return;
    // On Web (and during navigation transitions on all platforms), unmounting a platform
    // VideoPlayer widget involuntarily emits a pause event from the browser DOM element.
    // When a handoff is in progress and the video was actively playing, we preserve isPlaying
    // and re-issue play() so the incoming player container seamlessly resumes playback.
    if (state.isHandoffInProgress &&
        state.wasPlayingBeforeHandoff &&
        !ctrl.value.isPlaying) {
      ctrl.play().catchError((_) {});
      return;
    }
    final playing = ctrl.value.isPlaying;
    if (playing != state.isPlaying) {
      // Defer state mutation so controller notifications occurring during
      // widget lifecycle phases (e.g. initState / build) do not throw
      // "Tried to modify a provider while the widget tree was building".
      Future.microtask(() {
        if (mounted && state.controller == ctrl && state.isPlaying != playing) {
          state = state.copyWith(isPlaying: playing);
        }
      });
    }
  }

  /// Called when the target container has mounted and resumed playback
  void completeHandoff() {
    _handoffTimer?.cancel();
    _cancelRetryTimers();
    if (state.isHandoffInProgress) {
      state = state.copyWith(isHandoffInProgress: false);
    }
  }

  void _bindController(VideoPlayerController ctrl) {
    _unbindController();
    _controllerListener = () {
      if (mounted && state.controller == ctrl) {
        syncPlaybackState(ctrl);
      }
    };
    ctrl.addListener(_controllerListener!);
  }

  void _unbindController() {
    if (_controllerListener != null && state.controller != null) {
      try {
        state.controller!.removeListener(_controllerListener!);
      } catch (_) {}
      _controllerListener = null;
    }
  }

  // ── Controls and Actions ────────────────────────────────────────────

  void togglePlayPause() {
    if (state.isEnded) return;
    final ctrl = state.controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      final willPlay = !ctrl.value.isPlaying;
      // Terminate handoff protection BEFORE calling pause/play so synchronous
      // listener notifications in syncPlaybackState do not intercept the user's action.
      _handoffTimer?.cancel();
      _cancelRetryTimers();
      state = state.copyWith(
        isPlaying: willPlay,
        wasPlayingBeforeHandoff: willPlay,
        isHandoffInProgress: false,
      );
      if (willPlay) {
        ctrl.play();
      } else {
        ctrl.pause();
        _flushProgress();
      }
      PipService.instance.updatePlaybackState(isPlaying: willPlay);
    }
  }

  void _flushProgress() {
    final repo = _progressRepo;
    final ctrl = state.controller;
    final contentId = state.contentId;
    if (repo == null || ctrl == null || !ctrl.value.isInitialized || contentId == null) return;
    if (state.type != MiniPlayerType.video) return; // Do not save progress for live streams
    final positionSec = ctrl.value.position.inSeconds;
    final durationSec = ctrl.value.duration.inSeconds;
    if (positionSec <= 0) return;

    final progress = PlaybackProgress(
      videoId: contentId,
      videoTitle: state.title ?? '',
      thumbnailUrl: state.thumbnailUrl,
      positionSeconds: positionSec,
      durationSeconds: durationSec,
      updatedAt: DateTime.now(),
    );
    repo.save(progress);
  }

  void updatePosition(Offset newPos) {
    state = state.copyWith(position: newPos);
  }

  /// Prepare to navigate to full screen. Hides overlay without disposing controller.
  void prepareExpand() {
    final wasPlaying =
        state.isPlaying || (state.controller?.value.isPlaying ?? false);
    _lastReclaimedWasPlaying = wasPlaying;
    final ctrl = state.controller;
    if (ctrl != null && wasPlaying) {
      ctrl.play().catchError((_) {});
    }
    state = state.copyWith(
      isVisible: false,
      isNavigatingToFull: true,
      isHandoffInProgress: true,
      wasPlayingBeforeHandoff: wasPlaying,
    );
    _handoffTimer?.cancel();
    _handoffTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted && state.isHandoffInProgress) {
        state = state.copyWith(isHandoffInProgress: false);
      }
    });
  }

  /// Restore visibility if expand navigation failed
  void cancelExpand() {
    if (state.hasContent) {
      state = state.copyWith(
        isVisible: true,
        isNavigatingToFull: false,
        isHandoffInProgress: false,
      );
    }
  }

  /// Reclaims the controller for full-screen player ownership.
  VideoPlayerController? reclaimController(String expectedId) {
    if (state.contentId == expectedId) {
      final ctrl = state.controller;
      _lastReclaimedWasPlaying =
          state.isPlaying || state.wasPlayingBeforeHandoff;
      _handoffTimer?.cancel();
      _unbindController();
      state = const MiniPlayerState();
      return ctrl;
    }
    return null;
  }

  /// Hide without disposing (used during handoff or modal overlays).
  void hide() {
    state = state.copyWith(isVisible: false);
  }

  /// Completely close and terminate playback, releasing decoders and memory.
  void dismiss() {
    _flushProgress();
    PipService.instance.disableAutoPip();
    _handoffTimer?.cancel();
    _cancelRetryTimers();
    _unbindController();
    _disposeCurrentController();
    state = const MiniPlayerState();
  }

  void _disposeCurrentController() {
    final ctrl = state.controller;
    if (ctrl != null) {
      try {
        ctrl.pause();
        ctrl.dispose();
      } catch (e) {
        debugPrint('[MiniPlayer] Controller dispose error: $e');
      }
    }
  }

  @override
  void dispose() {
    _handoffTimer?.cancel();
    _cancelRetryTimers();
    _unbindController();
    _disposeCurrentController();
    super.dispose();
  }
}

final miniPlayerProvider =
    StateNotifierProvider<MiniPlayerNotifier, MiniPlayerState>(
  (ref) {
    PlaybackProgressRepository? repo;
    try {
      repo = ref.watch(playbackProgressRepositoryProvider);
    } catch (_) {}
    return MiniPlayerNotifier(repo);
  },
);
