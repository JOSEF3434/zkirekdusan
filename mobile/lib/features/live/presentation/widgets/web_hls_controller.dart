// lib/features/live/presentation/widgets/web_hls_controller.dart
import 'package:flutter/material.dart';
import 'package:mobile/features/live/domain/live_dvr_state.dart';

class WebHlsSnapshot {
  final bool isReady;
  final bool isPlaying;
  final bool isBuffering;
  final bool isSeeking;
  final bool isMuted;
  final double volume;
  final Duration position;
  final Duration seekableStart;
  final Duration seekableEnd;
  final Duration bufferedEnd;
  final Duration? liveSyncPosition;
  final Size? videoSize;
  final List<VideoQualityOption> qualities;
  final int currentQualityIndex;
  final bool dvrExpired;
  final bool isEnded;

  const WebHlsSnapshot({
    this.isReady = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isSeeking = false,
    this.isMuted = false,
    this.volume = 1.0,
    this.position = Duration.zero,
    this.seekableStart = Duration.zero,
    this.seekableEnd = Duration.zero,
    this.bufferedEnd = Duration.zero,
    this.liveSyncPosition,
    this.videoSize,
    this.qualities = const [VideoQualityOption.auto],
    this.currentQualityIndex = -1,
    this.dvrExpired = false,
    this.isEnded = false,
  });

  WebHlsSnapshot copyWith({
    bool? isReady,
    bool? isPlaying,
    bool? isBuffering,
    bool? isSeeking,
    bool? isMuted,
    double? volume,
    Duration? position,
    Duration? seekableStart,
    Duration? seekableEnd,
    Duration? bufferedEnd,
    Duration? liveSyncPosition,
    Size? videoSize,
    List<VideoQualityOption>? qualities,
    int? currentQualityIndex,
    bool? dvrExpired,
    bool? isEnded,
  }) {
    return WebHlsSnapshot(
      isReady: isReady ?? this.isReady,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isSeeking: isSeeking ?? this.isSeeking,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      position: position ?? this.position,
      seekableStart: seekableStart ?? this.seekableStart,
      seekableEnd: seekableEnd ?? this.seekableEnd,
      bufferedEnd: bufferedEnd ?? this.bufferedEnd,
      liveSyncPosition: liveSyncPosition ?? this.liveSyncPosition,
      videoSize: videoSize ?? this.videoSize,
      qualities: qualities ?? this.qualities,
      currentQualityIndex: currentQualityIndex ?? this.currentQualityIndex,
      dvrExpired: dvrExpired ?? this.dvrExpired,
      isEnded: isEnded ?? this.isEnded,
    );
  }
}

/// Platform-agnostic bridge for imperative DVR control of [WebHlsPlayer].
class WebHlsController extends ValueNotifier<WebHlsSnapshot> {
  WebHlsController() : super(const WebHlsSnapshot());

  Future<void> Function()? _playFn;
  void Function()? _pauseFn;
  void Function(Duration target)? _seekFn;
  void Function()? _seekLiveFn;
  void Function(double vol)? _setVolumeFn;
  void Function(bool muted)? _setMutedFn;
  void Function(int levelIndex)? _setQualityFn;
  void Function(VideoFitMode mode)? _setFitModeFn;

  void attach({
    required Future<void> Function() play,
    required void Function() pause,
    required void Function(Duration target) seekTo,
    required void Function() seekToLiveEdge,
    required void Function(double vol) setVolume,
    required void Function(bool muted) setMuted,
    required void Function(int levelIndex) setQuality,
    required void Function(VideoFitMode mode) setFitMode,
  }) {
    _playFn = play;
    _pauseFn = pause;
    _seekFn = seekTo;
    _seekLiveFn = seekToLiveEdge;
    _setVolumeFn = setVolume;
    _setMutedFn = setMuted;
    _setQualityFn = setQuality;
    _setFitModeFn = setFitMode;
  }

  void detach() {
    _playFn = null;
    _pauseFn = null;
    _seekFn = null;
    _seekLiveFn = null;
    _setVolumeFn = null;
    _setMutedFn = null;
    _setQualityFn = null;
    _setFitModeFn = null;
  }

  Future<void> play() async => _playFn?.call();
  void pause() => _pauseFn?.call();
  void seekTo(Duration target) => _seekFn?.call(target);
  void seekToLiveEdge() => _seekLiveFn?.call();
  void setVolume(double volume) => _setVolumeFn?.call(volume.clamp(0.0, 1.0));
  void setMuted(bool muted) => _setMutedFn?.call(muted);
  void setQualityLevel(int levelIndex) => _setQualityFn?.call(levelIndex);
  void setFitMode(VideoFitMode mode) => _setFitModeFn?.call(mode);
}
