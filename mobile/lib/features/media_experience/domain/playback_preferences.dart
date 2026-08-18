// lib/features/media_experience/domain/playback_preferences.dart

class PlaybackPreferences {
  final bool autoplay;
  final double defaultSpeed;
  final bool downloadOnWifiOnly;

  const PlaybackPreferences({
    this.autoplay = true,
    this.defaultSpeed = 1.0,
    this.downloadOnWifiOnly = true,
  });

  static const List<double> allowedSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  PlaybackPreferences copyWith({
    bool? autoplay,
    double? defaultSpeed,
    bool? downloadOnWifiOnly,
  }) => PlaybackPreferences(
    autoplay: autoplay ?? this.autoplay,
    defaultSpeed: defaultSpeed ?? this.defaultSpeed,
    downloadOnWifiOnly: downloadOnWifiOnly ?? this.downloadOnWifiOnly,
  );

  Map<String, dynamic> toJson() => {
    'autoplay': autoplay,
    'defaultSpeed': defaultSpeed,
    'downloadOnWifiOnly': downloadOnWifiOnly,
  };

  factory PlaybackPreferences.fromJson(Map<String, dynamic> json) =>
      PlaybackPreferences(
        autoplay: json['autoplay'] as bool? ?? true,
        defaultSpeed: (json['defaultSpeed'] as num?)?.toDouble() ?? 1.0,
        downloadOnWifiOnly: json['downloadOnWifiOnly'] as bool? ?? true,
      );
}
