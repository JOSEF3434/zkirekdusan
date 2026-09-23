// lib/core/presentation/providers/mini_player_provider.dart
// Global persistent mini-player state and controller lifecycle management.
// Supports both live streams and VOD videos with seamless handoff,
// draggable position persistence, play/pause controls, and clean resource release.

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

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

  // -- Playback & UI state --
  final bool isPlaying;
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
    this.isPlaying = true,
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
    bool? isPlaying,
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
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      isNavigatingToFull: isNavigatingToFull ?? this.isNavigatingToFull,
    );
  }

  bool get hasContent => contentId != null && contentId!.isNotEmpty;
  bool get isLive => type == MiniPlayerType.live;
}

class MiniPlayerNotifier extends StateNotifier<MiniPlayerState> {
  MiniPlayerNotifier() : super(const MiniPlayerState());

  VoidCallback? _controllerListener;

  // ── Show Video MiniPlayer ──────────────────────────────────────────────────

  void showVideo({
    required String videoId,
    required String title,
    String? channelName,
    String? thumbnailUrl,
    String? avatarUrl,
    required VideoPlayerController controller,
  }) {
    // If switching content or duplicate, clean previous
    if (state.controller != null && state.controller != controller) {
      _disposeCurrentController();
    }

    _bindController(controller);

    state = MiniPlayerState(
      isVisible: true,
      type: MiniPlayerType.video,
      contentId: videoId,
      title: title,
      channelName: channelName,
      thumbnailUrl: thumbnailUrl,
      avatarUrl: avatarUrl,
      controller: controller,
      isPlaying: controller.value.isPlaying,
      position: state.position, // Retain previously positioned coordinates
      isNavigatingToFull: false,
    );
  }

  // ── Show Live MiniPlayer ───────────────────────────────────────────────────

  void showLive({
    required String streamId,
    required String title,
    String? channelName,
    String? thumbnailUrl,
    String? avatarUrl,
    required String hlsUrl,
    VideoPlayerController? controller,
  }) {
    if (state.controller != null &&
        controller != null &&
        state.controller != controller) {
      _disposeCurrentController();
    }

    if (controller != null) {
      _bindController(controller);
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
      isPlaying: controller?.value.isPlaying ?? true,
      position: state.position,
      isNavigatingToFull: false,
    );
  }

  void updateLiveController(VideoPlayerController ctrl) {
    _bindController(ctrl);
    state = state.copyWith(controller: ctrl, isPlaying: ctrl.value.isPlaying);
  }

  void syncPlaybackState(VideoPlayerController ctrl) {
    if (!mounted || state.controller != ctrl) return;
    final playing = ctrl.value.isPlaying;
    if (playing != state.isPlaying) {
      state = state.copyWith(isPlaying: playing);
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

  // ── Controls & Actions ────────────────────────────────────────────────────

  void togglePlayPause() {
    final ctrl = state.controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      if (ctrl.value.isPlaying) {
        ctrl.pause();
      } else {
        ctrl.play();
      }
      state = state.copyWith(isPlaying: ctrl.value.isPlaying);
    }
  }

  void updatePosition(Offset newPos) {
    state = state.copyWith(position: newPos);
  }

  /// Prepare to navigate to full screen. Hides overlay without disposing controller.
  void prepareExpand() {
    state = state.copyWith(isVisible: false, isNavigatingToFull: true);
  }

  /// Reclaims the controller for full-screen player ownership.
  /// Clears mini-player state without calling dispose() on the controller.
  VideoPlayerController? reclaimController(String expectedId) {
    if (state.contentId == expectedId) {
      final ctrl = state.controller;
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
    _unbindController();
    _disposeCurrentController();
    super.dispose();
  }
}

final miniPlayerProvider =
    StateNotifierProvider<MiniPlayerNotifier, MiniPlayerState>(
      (_) => MiniPlayerNotifier(),
    );
