// lib/core/storage/download_settings.dart
// Manages user-facing download & storage preferences with SharedPreferences persistence.
// Default: in-app only storage, newest-first sort.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/presentation/providers/preferences_provider.dart';

// ─── Enums ──────────────────────────────────────────────────────────────────

/// Controls where downloaded video data is stored.
enum DownloadStorageMode {
  /// Stored in-app memory / web localStorage only (default).
  inAppOnly,

  /// Browser/OS "Save file" dialog is triggered (web: download attribute).
  saveToFile,

  /// Both: kept in-app AND saved to the device file system.
  both,
}

/// How items are ordered on the Downloads page.
enum DownloadSortOrder {
  /// Most recently downloaded appears first (default).
  newestFirst,

  /// Oldest download appears first.
  oldestFirst,

  /// Alphabetical A → Z by title.
  titleAZ,

  /// Alphabetical Z → A by title.
  titleZA,

  /// Largest file first.
  sizeDesc,

  /// Smallest file first.
  sizeAsc,
}

/// Card display density.
enum DownloadViewMode {
  /// YouTube-style grid of video cards (default).
  grid,

  /// Compact list with smaller thumbnails.
  list,
}

// ─── Settings Model ──────────────────────────────────────────────────────────

class DownloadSettings {
  final DownloadStorageMode storageMode;
  final DownloadSortOrder sortOrder;
  final DownloadViewMode viewMode;

  /// Whether to auto-download over Wi-Fi when a new video is published.
  final bool autoDownloadOnWifi;

  /// Maximum simultaneous downloads (1–5).
  final int maxConcurrent;

  /// Publisher permission preference: whether others are allowed to download my media by default.
  final bool allowDownloadsByDefault;

  /// Default storage directory description.
  final String defaultDownloadLocation;

  /// Default download quality (e.g. '720p', '1080p', '480p').
  final String preferredQuality;

  const DownloadSettings({
    this.storageMode = DownloadStorageMode.inAppOnly,
    this.sortOrder = DownloadSortOrder.newestFirst,
    this.viewMode = DownloadViewMode.grid,
    this.autoDownloadOnWifi = false,
    this.maxConcurrent = 1,
    this.allowDownloadsByDefault = true,
    this.defaultDownloadLocation = 'Internal storage/Zikire Kdusan/',
    this.preferredQuality = '720p',
  });

  DownloadSettings copyWith({
    DownloadStorageMode? storageMode,
    DownloadSortOrder? sortOrder,
    DownloadViewMode? viewMode,
    bool? autoDownloadOnWifi,
    int? maxConcurrent,
    bool? allowDownloadsByDefault,
    String? defaultDownloadLocation,
    String? preferredQuality,
  }) {
    return DownloadSettings(
      storageMode: storageMode ?? this.storageMode,
      sortOrder: sortOrder ?? this.sortOrder,
      viewMode: viewMode ?? this.viewMode,
      autoDownloadOnWifi: autoDownloadOnWifi ?? this.autoDownloadOnWifi,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
      allowDownloadsByDefault:
          allowDownloadsByDefault ?? this.allowDownloadsByDefault,
      defaultDownloadLocation:
          defaultDownloadLocation ?? this.defaultDownloadLocation,
      preferredQuality: preferredQuality ?? this.preferredQuality,
    );
  }

  Map<String, dynamic> toJson() => {
        'storageMode': storageMode.name,
        'sortOrder': sortOrder.name,
        'viewMode': viewMode.name,
        'autoDownloadOnWifi': autoDownloadOnWifi,
        'maxConcurrent': maxConcurrent,
        'allowDownloadsByDefault': allowDownloadsByDefault,
        'defaultDownloadLocation': defaultDownloadLocation,
        'preferredQuality': preferredQuality,
      };

  factory DownloadSettings.fromJson(Map<String, dynamic> json) {
    return DownloadSettings(
      storageMode: DownloadStorageMode.values.firstWhere(
        (e) => e.name == json['storageMode'],
        orElse: () => DownloadStorageMode.inAppOnly,
      ),
      sortOrder: DownloadSortOrder.values.firstWhere(
        (e) => e.name == json['sortOrder'],
        orElse: () => DownloadSortOrder.newestFirst,
      ),
      viewMode: DownloadViewMode.values.firstWhere(
        (e) => e.name == json['viewMode'],
        orElse: () => DownloadViewMode.grid,
      ),
      autoDownloadOnWifi: json['autoDownloadOnWifi'] as bool? ?? false,
      maxConcurrent: (json['maxConcurrent'] as num?)?.toInt() ?? 1,
      allowDownloadsByDefault:
          json['allowDownloadsByDefault'] as bool? ?? true,
      defaultDownloadLocation: json['defaultDownloadLocation'] as String? ??
          'Internal storage/Zikire Kdusan/',
      preferredQuality: json['preferredQuality'] as String? ?? '720p',
    );
  }
}

// ─── StateNotifier ───────────────────────────────────────────────────────────

class DownloadSettingsNotifier extends StateNotifier<DownloadSettings> {
  static const _kSettingsKey = 'download_settings_v1';

  final SharedPreferences? _prefs;

  DownloadSettingsNotifier(this._prefs) : super(const DownloadSettings()) {
    _load();
  }

  void _load() {
    try {
      final raw = _prefs?.getString(_kSettingsKey);
      if (raw != null && raw.isNotEmpty) {
        state = DownloadSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    } catch (e) {
      debugPrint('[DownloadSettings] load error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      await _prefs?.setString(_kSettingsKey, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('[DownloadSettings] persist error: $e');
    }
  }

  Future<void> setStorageMode(DownloadStorageMode mode) async {
    state = state.copyWith(storageMode: mode);
    await _persist();
  }

  Future<void> setSortOrder(DownloadSortOrder order) async {
    state = state.copyWith(sortOrder: order);
    await _persist();
  }

  Future<void> setViewMode(DownloadViewMode mode) async {
    state = state.copyWith(viewMode: mode);
    await _persist();
  }

  Future<void> setAutoDownloadOnWifi(bool value) async {
    state = state.copyWith(autoDownloadOnWifi: value);
    await _persist();
  }

  Future<void> setMaxConcurrent(int value) async {
    state = state.copyWith(maxConcurrent: value.clamp(1, 5));
    await _persist();
  }

  Future<void> setAllowDownloadsByDefault(bool value) async {
    state = state.copyWith(allowDownloadsByDefault: value);
    await _persist();
  }

  Future<void> setDefaultDownloadLocation(String path) async {
    state = state.copyWith(defaultDownloadLocation: path);
    await _persist();
  }

  Future<void> setPreferredQuality(String quality) async {
    state = state.copyWith(preferredQuality: quality);
    await _persist();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final downloadSettingsProvider =
    StateNotifierProvider<DownloadSettingsNotifier, DownloadSettings>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    // UnimplementedError or missing override in widget test environments
  }
  return DownloadSettingsNotifier(prefs);
});
