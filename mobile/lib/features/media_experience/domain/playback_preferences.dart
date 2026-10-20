// lib/features/media_experience/domain/playback_preferences.dart

class PlaybackPreferences {
  final bool autoplay;
  final double defaultSpeed;
  final bool downloadOnWifiOnly;
  final bool doubleTapSeekEnabled;
  final int seekForwardSeconds;
  final int seekBackwardSeconds;
  final bool autoHideControls;
  final int autoHideDelaySeconds;

  const PlaybackPreferences({
    this.autoplay = true,
    this.defaultSpeed = 1.0,
    this.downloadOnWifiOnly = true,
    this.doubleTapSeekEnabled = true,
    this.seekForwardSeconds = 5,
    this.seekBackwardSeconds = 5,
    this.autoHideControls = true,
    this.autoHideDelaySeconds = 3,
  });

  static const List<double> allowedSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const List<int> allowedSeekIntervals = [5, 10, 15, 20, 30];
  static const List<int> allowedAutoHideDelays = [3, 5, 8, 10];

  PlaybackPreferences copyWith({
    bool? autoplay,
    double? defaultSpeed,
    bool? downloadOnWifiOnly,
    bool? doubleTapSeekEnabled,
    int? seekForwardSeconds,
    int? seekBackwardSeconds,
    bool? autoHideControls,
    int? autoHideDelaySeconds,
  }) => PlaybackPreferences(
    autoplay: autoplay ?? this.autoplay,
    defaultSpeed: defaultSpeed ?? this.defaultSpeed,
    downloadOnWifiOnly: downloadOnWifiOnly ?? this.downloadOnWifiOnly,
    doubleTapSeekEnabled: doubleTapSeekEnabled ?? this.doubleTapSeekEnabled,
    seekForwardSeconds: seekForwardSeconds ?? this.seekForwardSeconds,
    seekBackwardSeconds: seekBackwardSeconds ?? this.seekBackwardSeconds,
    autoHideControls: autoHideControls ?? this.autoHideControls,
    autoHideDelaySeconds: autoHideDelaySeconds ?? this.autoHideDelaySeconds,
  );

  Map<String, dynamic> toJson() => {
    'autoplay': autoplay,
    'defaultSpeed': defaultSpeed,
    'downloadOnWifiOnly': downloadOnWifiOnly,
    'doubleTapSeekEnabled': doubleTapSeekEnabled,
    'seekForwardSeconds': seekForwardSeconds,
    'seekBackwardSeconds': seekBackwardSeconds,
    'autoHideControls': autoHideControls,
    'autoHideDelaySeconds': autoHideDelaySeconds,
  };

  factory PlaybackPreferences.fromJson(Map<String, dynamic> json) =>
      PlaybackPreferences(
        autoplay: json['autoplay'] as bool? ?? true,
        defaultSpeed: (json['defaultSpeed'] as num?)?.toDouble() ?? 1.0,
        downloadOnWifiOnly: json['downloadOnWifiOnly'] as bool? ?? true,
        doubleTapSeekEnabled: json['doubleTapSeekEnabled'] as bool? ?? true,
        seekForwardSeconds: (json['seekForwardSeconds'] as num?)?.toInt() ?? 5,
        seekBackwardSeconds: (json['seekBackwardSeconds'] as num?)?.toInt() ?? 5,
        autoHideControls: json['autoHideControls'] as bool? ?? true,
        autoHideDelaySeconds:
            (json['autoHideDelaySeconds'] as num?)?.toInt() ?? 3,
      );
}

