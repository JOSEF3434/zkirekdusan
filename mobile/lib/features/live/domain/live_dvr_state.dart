// lib/features/live/domain/live_dvr_state.dart
import 'dart:math' as math;
import 'dart:ui' show Size;

/// Comprehensive viewer playback state required for YouTube-style live DVR.
enum LivePlaybackState {
  liveEdge,
  playing,
  paused,
  rewinding,
  fastForwarding,
  buffering,
  seeking,
  reconnecting,
  dvrExpired,
  ended,
  error,
}

extension LivePlaybackStateX on LivePlaybackState {
  bool get isLiveEdge => this == LivePlaybackState.liveEdge;
  bool get isPlaying =>
      this == LivePlaybackState.liveEdge || this == LivePlaybackState.playing;
  bool get isDelayed =>
      this == LivePlaybackState.playing ||
      this == LivePlaybackState.paused ||
      this == LivePlaybackState.rewinding ||
      this == LivePlaybackState.fastForwarding;
}

/// Viewer video scaling mode (uncropped Fit by default; optional Fill).
enum VideoFitMode {
  fit,
  fill,
}

class VideoQualityOption {
  final int index; // -1 for Auto ABR
  final String label;
  final int? bitrate;
  final int? width;
  final int? height;

  const VideoQualityOption({
    required this.index,
    required this.label,
    this.bitrate,
    this.width,
    this.height,
  });

  static const auto = VideoQualityOption(index: -1, label: 'Auto');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoQualityOption &&
          other.index == index &&
          other.label == label;

  @override
  int get hashCode => Object.hash(index, label);
}

class DvrVariantInfo {
  final int id;
  final String label;
  final int bandwidth;
  final int? width;
  final int? height;
  final String playlistPath;

  const DvrVariantInfo({
    required this.id,
    required this.label,
    required this.bandwidth,
    this.width,
    this.height,
    required this.playlistPath,
  });

  factory DvrVariantInfo.fromJson(Map<String, dynamic> json) {
    return DvrVariantInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? 'Auto',
      bandwidth: (json['bandwidth'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      playlistPath: json['playlistPath'] as String? ?? '',
    );
  }
}

class DvrTimelineSnapshot {
  final String streamId;
  final bool dvrEnabled;
  final bool active;
  final bool ended;
  final bool hasSegments;
  final int dvrWindowSeconds;
  final int retentionMinutes;
  final double targetDurationSec;
  final double dvrStartOffsetSec;
  final double liveEdgeOffsetSec;
  final double retainedDurationSec;
  final int segmentCount;
  final String masterPlaylistPath;
  final List<DvrVariantInfo> variants;

  const DvrTimelineSnapshot({
    required this.streamId,
    required this.dvrEnabled,
    required this.active,
    required this.ended,
    required this.hasSegments,
    required this.dvrWindowSeconds,
    required this.retentionMinutes,
    required this.targetDurationSec,
    required this.dvrStartOffsetSec,
    required this.liveEdgeOffsetSec,
    required this.retainedDurationSec,
    required this.segmentCount,
    required this.masterPlaylistPath,
    this.variants = const [],
  });

  factory DvrTimelineSnapshot.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variants'] as List<dynamic>? ?? const [];
    return DvrTimelineSnapshot(
      streamId: json['streamId'] as String? ?? '',
      dvrEnabled: json['dvrEnabled'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
      ended: json['ended'] as bool? ?? false,
      hasSegments: json['hasSegments'] as bool? ?? false,
      dvrWindowSeconds: (json['dvrWindowSeconds'] as num?)?.toInt() ?? 1800,
      retentionMinutes: (json['retentionMinutes'] as num?)?.toInt() ?? 30,
      targetDurationSec:
          (json['targetDurationSec'] as num?)?.toDouble() ?? 4.0,
      dvrStartOffsetSec:
          (json['dvrStartOffsetSec'] as num?)?.toDouble() ?? 0.0,
      liveEdgeOffsetSec:
          (json['liveEdgeOffsetSec'] as num?)?.toDouble() ?? 0.0,
      retainedDurationSec:
          (json['retainedDurationSec'] as num?)?.toDouble() ?? 0.0,
      segmentCount: (json['segmentCount'] as num?)?.toInt() ?? 0,
      masterPlaylistPath: json['masterPlaylistPath'] as String? ?? '',
      variants: rawVariants
          .whereType<Map<String, dynamic>>()
          .map(DvrVariantInfo.fromJson)
          .toList(),
    );
  }
}

class DvrWindowMath {
  final Duration windowStart;
  final Duration windowEnd;
  final Duration currentPosition;
  final Duration bufferedEnd;
  final Duration behindLive;
  final bool isAtLiveEdge;
  final double progress;
  final double bufferedProgress;

  const DvrWindowMath({
    required this.windowStart,
    required this.windowEnd,
    required this.currentPosition,
    required this.bufferedEnd,
    required this.behindLive,
    required this.isAtLiveEdge,
    required this.progress,
    required this.bufferedProgress,
  });

  Duration get windowSpan => windowEnd > windowStart
      ? windowEnd - windowStart
      : const Duration(seconds: 1);

  String get formattedCurrent => formatDvrDuration(currentPosition);
  String get formattedTotal => formatDvrDuration(windowEnd);
  String get formattedBehindLive => '-${formatDvrDuration(behindLive)}';
}

String formatDvrDuration(Duration d) {
  final absSeconds = d.inSeconds.abs();
  final hours = absSeconds ~/ 3600;
  final minutes = (absSeconds % 3600) ~/ 60;
  final seconds = absSeconds % 60;
  final m = minutes.toString().padLeft(2, '0');
  final s = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$m:$s';
  }
  return '$m:$s';
}

/// Computes unified DVR scrubber bounds & live-edge proximity from real player
/// coordinates and (optionally) the server DVR timeline snapshot.
DvrWindowMath computeDvrWindowMath({
  required Duration currentPosition,
  required Duration reportedDuration,
  Duration? seekableStart,
  Duration? seekableEnd,
  Duration? bufferedEnd,
  Duration? liveSyncPosition,
  DvrTimelineSnapshot? serverTimeline,
  Duration liveEdgeTolerance = const Duration(seconds: 12),
}) {
  final start = seekableStart ??
      (serverTimeline != null && serverTimeline.hasSegments
          ? Duration(milliseconds: (serverTimeline.dvrStartOffsetSec * 1000).round())
          : Duration.zero);

  Duration end = Duration.zero;
  if (seekableEnd != null && seekableEnd > start) {
    end = seekableEnd;
  }
  if (reportedDuration > end) {
    end = reportedDuration;
  }
  if (serverTimeline != null && serverTimeline.hasSegments) {
    final serverSpanMs =
        (serverTimeline.retainedDurationSec * 1000).round();
    final serverEnd = start + Duration(milliseconds: serverSpanMs);
    if (serverEnd > end) {
      end = serverEnd;
    }
  }
  if (end <= start) {
    end = currentPosition > start
        ? currentPosition
        : start + const Duration(seconds: 1);
  }

  final clampedPos = currentPosition < start
      ? start
      : (currentPosition > end ? end : currentPosition);

  final effectiveLiveTarget = liveSyncPosition != null &&
          liveSyncPosition >= start &&
          liveSyncPosition <= end
      ? liveSyncPosition
      : end;

  final behind = effectiveLiveTarget > clampedPos
      ? effectiveLiveTarget - clampedPos
      : Duration.zero;

  final spanMs = math.max(1, (end - start).inMilliseconds);
  final posRatio =
      ((clampedPos - start).inMilliseconds / spanMs).clamp(0.0, 1.0);

  final effectiveBuffered = bufferedEnd != null && bufferedEnd > start
      ? (bufferedEnd > end ? end : bufferedEnd)
      : clampedPos;
  final bufRatio =
      ((effectiveBuffered - start).inMilliseconds / spanMs).clamp(0.0, 1.0);

  return DvrWindowMath(
    windowStart: start,
    windowEnd: end,
    currentPosition: clampedPos,
    bufferedEnd: effectiveBuffered,
    behindLive: behind,
    isAtLiveEdge: behind <= liveEdgeTolerance,
    progress: posRatio,
    bufferedProgress: math.max(posRatio, bufRatio),
  );
}

class ResponsiveVideoFrame {
  final double stageWidth;
  final double stageHeight;
  final double videoAspectRatio;
  final bool isPortraitVideo;

  const ResponsiveVideoFrame({
    required this.stageWidth,
    required this.stageHeight,
    required this.videoAspectRatio,
    required this.isPortraitVideo,
  });
}

/// Computes YouTube-style full-width responsive player stage dimensions with a
/// controlled 16:9 landscape aspect ratio across mobile, tablet, and desktop
/// viewports so portrait camera feeds fill 100% of player width cleanly.
ResponsiveVideoFrame computeResponsiveVideoFrame({
  required double maxWidth,
  required double maxHeight,
  required Size? sourceVideoSize,
  required bool isWideScreen,
  required bool isFullscreen,
}) {
  final safeW = math.max(120.0, maxWidth);
  final safeH = math.max(120.0, maxHeight);

  double aspect = 16.0 / 9.0;
  if (sourceVideoSize != null &&
      sourceVideoSize.width > 0 &&
      sourceVideoSize.height > 0) {
    aspect = (sourceVideoSize.width / sourceVideoSize.height).clamp(0.25, 4.0);
  }
  final isPortrait = aspect < 0.92;

  if (isFullscreen) {
    return ResponsiveVideoFrame(
      stageWidth: safeW,
      stageHeight: safeH,
      videoAspectRatio: aspect,
      isPortraitVideo: isPortrait,
    );
  }

  // Always enforce a responsive 16:9 landscape stage occupying 100% width;
  // video content scales via cover/crop-to-fill rather than tall portrait pillars.
  final ideal16x9H = safeW * 9.0 / 16.0;
  final minStageH = isWideScreen ? math.min(260.0, safeH) : math.min(180.0, safeH);
  final boundedH = ideal16x9H.clamp(minStageH, safeH);

  return ResponsiveVideoFrame(
    stageWidth: safeW,
    stageHeight: boundedH,
    videoAspectRatio: aspect,
    isPortraitVideo: isPortrait,
  );
}
