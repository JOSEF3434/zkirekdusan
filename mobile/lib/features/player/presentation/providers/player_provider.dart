// lib/features/player/presentation/providers/player_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/player/data/player_repository.dart';

class PlayerState {
  final VideoResponseDto? video;
  final VideoPlayerController? controller;
  final bool isLoading;
  final String? error;
  final List<VideoResponseDto> recommendations;
  final VideoRenditionDto? currentRendition;
  final bool showControls;

  const PlayerState({
    this.video,
    this.controller,
    this.isLoading = true,
    this.error,
    this.recommendations = const [],
    this.currentRendition,
    this.showControls = true,
  });

  PlayerState copyWith({
    VideoResponseDto? video,
    VideoPlayerController? controller,
    bool? isLoading,
    String? error,
    List<VideoResponseDto>? recommendations,
    VideoRenditionDto? currentRendition,
    bool? showControls,
  }) {
    return PlayerState(
      video: video ?? this.video,
      controller: controller ?? this.controller,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      recommendations: recommendations ?? this.recommendations,
      currentRendition: currentRendition ?? this.currentRendition,
      showControls: showControls ?? this.showControls,
    );
  }
}

final playerProvider = StateNotifierProvider.autoDispose
    .family<PlayerNotifier, PlayerState, String>((ref, videoId) {
      return PlayerNotifier(ref.watch(playerRepositoryProvider), videoId);
    });

class PlayerNotifier extends StateNotifier<PlayerState> {
  final PlayerRepository _repository;
  final String _videoId;
  Timer? _progressTimer;

  PlayerNotifier(this._repository, this._videoId) : super(const PlayerState()) {
    _initialize();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    state.controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final video = await _repository.getVideo(_videoId);

      // Setup Controller with HLS URL if available, else standard URL
      // If renditions are used manually, we would use them, but HLS master playlist handles it automatically.
      final url =
          video.hlsUrl ??
          (video.renditions.isNotEmpty ? video.renditions.first.url : null);

      if (url == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No video stream available.',
        );
        return;
      }

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      controller.play();

      _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _saveProgress();
      });

      // Fetch recommendations in background
      _repository.getRecommended(_videoId).then((res) {
        if (mounted) {
          state = state.copyWith(recommendations: res.data);
        }
      });

      state = state.copyWith(
        video: video,
        controller: controller,
        isLoading: false,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  void togglePlayPause() {
    final ctrl = state.controller;
    if (ctrl == null) return;

    if (ctrl.value.isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
  }

  void seekTo(Duration position) {
    state.controller?.seekTo(position);
  }

  void toggleControls() {
    state = state.copyWith(showControls: !state.showControls);
  }

  Future<void> setQuality(VideoRenditionDto rendition) async {
    // Standard HLS handles quality automatically, but if users manually select:
    final currentPosition = state.controller?.value.position ?? Duration.zero;
    final isPlaying = state.controller?.value.isPlaying ?? false;

    state.controller?.dispose();

    final newController = VideoPlayerController.networkUrl(
      Uri.parse(rendition.url),
    );
    await newController.initialize();
    await newController.seekTo(currentPosition);
    if (isPlaying) {
      newController.play();
    }

    state = state.copyWith(
      controller: newController,
      currentRendition: rendition,
    );
  }

  void _saveProgress() {
    final ctrl = state.controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    _repository.saveProgress(_videoId, ctrl.value.position.inSeconds);
  }
}
