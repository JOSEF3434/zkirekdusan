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

  const DownloadSettings({
    this.storageMode = DownloadStorageMode.inAppOnly,
    this.sortOrder = DownloadSortOrder.newestFirst,
    this.viewMode = DownloadViewMode.grid,
    this.autoDownloadOnWifi = false,
    this.maxConcurrent = 1,
  });

  DownloadSettings copyWith({
    DownloadStorageMode? storageMode,
    DownloadSortOrder? sortOrder,
    DownloadViewMode? viewMode,
    bool? autoDownloadOnWifi,
    int? maxConcurrent,
  }) {
    return DownloadSettings(
      storageMode: storageMode ?? this.storageMode,
      sortOrder: sortOrder ?? this.sortOrder,
      viewMode: viewMode ?? this.viewMode,
      autoDownloadOnWifi: autoDownloadOnWifi ?? this.autoDownloadOnWifi,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
    );
  }

  Map<String, dynamic> toJson() => {
        'storageMode': storageMode.name,
        'sortOrder': sortOrder.name,
        'viewMode': viewMode.name,
        'autoDownloadOnWifi': autoDownloadOnWifi,
        'maxConcurrent': maxConcurrent,
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
      maxConcurrent: json['maxConcurrent'] as int? ?? 1,
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
