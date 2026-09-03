// lib/core/presentation/providers/mini_player_provider.dart
// Global mini-player state — controls the floating mini player shown over the AppShell.
// Supports two content types:
//   • video  — a VOD played through VideoPlayerScreen / playerProvider
//   • live   — an HLS live stream viewed in LiveRoomScreen

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

// ─── Content type ─────────────────────────────────────────────────────────────

enum MiniPlayerType { video, live }

// ─── State ────────────────────────────────────────────────────────────────────

class MiniPlayerState {
  /// When true the overlay is visible at the bottom of the screen.
  final bool isVisible;

  final MiniPlayerType type;

  // -- Shared fields --
  final String? contentId;   // videoId or streamId
  final String? title;
  final String? channelName;
  final String? thumbnailUrl;

  // -- Video-specific fields --
  /// The VideoPlayerController kept alive while the mini player is shown.
  final VideoPlayerController? controller;

  // -- Live-specific fields --
  final String? hlsUrl;

  const MiniPlayerState({
    this.isVisible = false,
    this.type = MiniPlayerType.video,
    this.contentId,
    this.title,
    this.channelName,
    this.thumbnailUrl,
    this.controller,
    this.hlsUrl,
  });

  MiniPlayerState copyWith({
    bool? isVisible,
    MiniPlayerType? type,
    String? contentId,
    String? title,
    String? channelName,
    String? thumbnailUrl,
    VideoPlayerController? controller,
    bool clearController = false,
    String? hlsUrl,
  }) {
    return MiniPlayerState(
      isVisible: isVisible ?? this.isVisible,
      type: type ?? this.type,
      contentId: contentId ?? this.contentId,
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      controller: clearController ? null : (controller ?? this.controller),
      hlsUrl: hlsUrl ?? this.hlsUrl,
    );
  }

  bool get hasContent => contentId != null;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class MiniPlayerNotifier extends StateNotifier<MiniPlayerState> {
  MiniPlayerNotifier() : super(const MiniPlayerState());

  // ── Video mini-player ────────────────────────────────────────────────────

  /// Show a VOD mini player. The caller transfers ownership of [controller].
  void showVideo({
    required String videoId,
    required String title,
    String? channelName,
    String? thumbnailUrl,
    required VideoPlayerController controller,
  }) {
    _disposeCurrentController();
    state = MiniPlayerState(
      isVisible: true,
      type: MiniPlayerType.video,
      contentId: videoId,
      title: title,
      channelName: channelName,
      thumbnailUrl: thumbnailUrl,
      controller: controller,
    );
  }

  // ── Live mini-player ─────────────────────────────────────────────────────

  /// Show a live-stream mini player.
  void showLive({
    required String streamId,
    required String title,
    String? channelName,
    String? thumbnailUrl,
    required String hlsUrl,
    VideoPlayerController? controller,
  }) {
    _disposeCurrentController();
    state = MiniPlayerState(
      isVisible: true,
      type: MiniPlayerType.live,
      contentId: streamId,
      title: title,
      channelName: channelName,
      thumbnailUrl: thumbnailUrl,
      hlsUrl: hlsUrl,
      controller: controller,
    );
  }

  /// Update the live mini-player controller once the video player is ready.
  void updateLiveController(VideoPlayerController ctrl) {
    state = state.copyWith(controller: ctrl);
  }

  // ── Common ───────────────────────────────────────────────────────────────

  /// Dismiss the mini player and release the controller.
  void dismiss() {
    _disposeCurrentController();
    state = const MiniPlayerState();
  }

  /// Hide the overlay without destroying the controller (caller will reclaim it).
  void hide() {
    state = state.copyWith(isVisible: false);
  }

  /// Called when the user taps the mini player to expand it again.
  void expand() {
    state = state.copyWith(isVisible: false);
    // Navigation is handled by the caller that observes this change.
  }

  void _disposeCurrentController() {
    final ctrl = state.controller;
    if (ctrl != null) {
      ctrl.pause();
      ctrl.dispose();
    }
  }

  @override
  void dispose() {
    _disposeCurrentController();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final miniPlayerProvider =
    StateNotifierProvider<MiniPlayerNotifier, MiniPlayerState>(
  (_) => MiniPlayerNotifier(),
);
