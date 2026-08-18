// lib/features/media_experience/domain/playback_progress.dart
// Local playback progress model — persisted via SharedPreferences.

class PlaybackProgress {
  final String videoId;
  final String videoTitle;
  final String? thumbnailUrl;

  /// Seconds into the video at which the user stopped.
  final int positionSeconds;

  /// Total duration of the video in seconds (0 if unknown).
  final int durationSeconds;
  final DateTime updatedAt;

  const PlaybackProgress({
    required this.videoId,
    required this.videoTitle,
    this.thumbnailUrl,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.updatedAt,
  });

  /// Fraction 0.0–1.0 of how much of the video has been watched.
  double get fraction => durationSeconds > 0
      ? (positionSeconds / durationSeconds).clamp(0.0, 1.0)
      : 0.0;

  /// Seconds remaining.
  int get remainingSeconds =>
      (durationSeconds - positionSeconds).clamp(0, durationSeconds);

  /// True when the video is considered complete (within 30s of end).
  bool get isComplete => durationSeconds > 0 && remainingSeconds <= 30;

  /// True when the user just started — less than 10s in; restart from 0.
  bool get isTrivial => positionSeconds < 10;

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'videoTitle': videoTitle,
    'thumbnailUrl': thumbnailUrl,
    'positionSeconds': positionSeconds,
    'durationSeconds': durationSeconds,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PlaybackProgress.fromJson(Map<String, dynamic> json) =>
      PlaybackProgress(
        videoId: json['videoId'] as String? ?? '',
        videoTitle: json['videoTitle'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String?,
        positionSeconds: json['positionSeconds'] as int? ?? 0,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  PlaybackProgress copyWith({
    int? positionSeconds,
    int? durationSeconds,
    DateTime? updatedAt,
  }) => PlaybackProgress(
    videoId: videoId,
    videoTitle: videoTitle,
    thumbnailUrl: thumbnailUrl,
    positionSeconds: positionSeconds ?? this.positionSeconds,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
