// lib/core/presentation/providers/pip_provider.dart
// Central Riverpod provider for native OS Picture-in-Picture mode management.
// Bridges Flutter UI state with native Android/iOS PiP lifecycle and controls.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';
import 'package:mobile/core/services/pip_service.dart';
import 'package:mobile/features/player/presentation/providers/player_provider.dart';

class PipState {
  final bool isSupported;
  final bool isInPip;
  final bool isAutoPipEnabled;
  final String? activeContentId;

  const PipState({
    this.isSupported = false,
    this.isInPip = false,
    this.isAutoPipEnabled = false,
    this.activeContentId,
  });

  PipState copyWith({
    bool? isSupported,
    bool? isInPip,
    bool? isAutoPipEnabled,
    String? activeContentId,
    bool clearActiveContent = false,
  }) {
    return PipState(
      isSupported: isSupported ?? this.isSupported,
      isInPip: isInPip ?? this.isInPip,
      isAutoPipEnabled: isAutoPipEnabled ?? this.isAutoPipEnabled,
      activeContentId: clearActiveContent
          ? null
          : (activeContentId ?? this.activeContentId),
    );
  }
}

class PipNotifier extends StateNotifier<PipState> {
  final Ref _ref;

  PipNotifier(this._ref) : super(const PipState()) {
    _init();
  }

  Future<void> _init() async {
    final service = PipService.instance;
    await service.initialize();

    state = state.copyWith(
      isSupported: service.isSupported,
      isInPip: service.isInPip,
      
    );

    service.addPipModeListener(_onPipModeChanged);
    service.addPipActionListener(_onPipAction);
  }

  void _onPipModeChanged(bool isInPip) {
    if (!mounted) return;
    state = state.copyWith(isInPip: isInPip);
  }

  void _onPipAction(String action) {
    if (!mounted) return;
    final contentId = state.activeContentId;

    if (action == 'play') {
      if (contentId != null) {
        final playerNotifier = _ref.read(playerProvider(contentId).notifier);
        final playerState = _ref.read(playerProvider(contentId));
        if (playerState.controller != null && !playerState.controller!.value.isPlaying) {
          playerNotifier.togglePlayPause();
          return;
        }
      }
      final mini = _ref.read(miniPlayerProvider);
      if (mini.hasContent && !mini.isPlaying) {
        _ref.read(miniPlayerProvider.notifier).togglePlayPause();
      }
    } else if (action == 'pause') {
      if (contentId != null) {
        final playerNotifier = _ref.read(playerProvider(contentId).notifier);
        final playerState = _ref.read(playerProvider(contentId));
        if (playerState.controller != null && playerState.controller!.value.isPlaying) {
          playerNotifier.togglePlayPause();
          return;
        }
      }
      final mini = _ref.read(miniPlayerProvider);
      if (mini.hasContent && mini.isPlaying) {
        _ref.read(miniPlayerProvider.notifier).togglePlayPause();
      }
    }
  }

  /// Register currently playing video for auto-PiP.
  Future<void> registerActiveMedia({
    required String contentId,
    required bool isPlaying,
    double aspectRatio = 16 / 9,
    String? title,
  }) async {
    state = state.copyWith(
      activeContentId: contentId,
      isAutoPipEnabled: isPlaying,
    );
    if (isPlaying) {
      await PipService.instance.enableAutoPip(
        isPlaying: true,
        aspectRatio: aspectRatio,
        title: title,
      );
    } else {
      await PipService.instance.updatePlaybackState(isPlaying: false);
    }
  }

  /// Synchronize playback state changes (play / pause) with the OS PiP manager.
  Future<void> updatePlaybackState({required bool isPlaying}) async {
    state = state.copyWith(isAutoPipEnabled: isPlaying);
    await PipService.instance.updatePlaybackState(isPlaying: isPlaying);
  }

  /// Unregister when video is disposed or fully closed.
  Future<void> unregisterActiveMedia(String contentId) async {
    if (state.activeContentId == contentId) {
      await PipService.instance.disableAutoPip();
      if (mounted && state.activeContentId == contentId) {
        state = state.copyWith(
          clearActiveContent: true,
          isAutoPipEnabled: false,
        );
      }
    }
  }

  /// Manually enter PiP window.
  Future<bool> enterPip({double aspectRatio = 16 / 9}) async {
    return await PipService.instance.enterPip(aspectRatio: aspectRatio);
  }

  @override
  void dispose() {
    PipService.instance.removePipModeListener(_onPipModeChanged);
    PipService.instance.removePipActionListener(_onPipAction);
    super.dispose();
  }
}

final pipProvider = StateNotifierProvider<PipNotifier, PipState>((ref) {
  return PipNotifier(ref);
});
