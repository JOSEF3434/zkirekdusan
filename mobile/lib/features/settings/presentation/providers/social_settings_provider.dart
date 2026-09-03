// lib/features/settings/presentation/providers/social_settings_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';

class SessionItem {
  final String id;
  final String deviceName;
  final String platform;
  final String location;
  final String ipAddress;
  final String lastActive;
  final bool isCurrent;

  const SessionItem({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.location,
    required this.ipAddress,
    required this.lastActive,
    this.isCurrent = false,
  });
}

class BlockedUserItem {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;

  const BlockedUserItem({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
  });
}

class SocialSettingsState {
  // Security
  final bool twoFactorEnabled;
  final bool biometricLockEnabled;
  final bool loginAlerts;
  final List<SessionItem> sessions;

  // Privacy
  final String lastSeenPrivacy;
  final String profilePhotoPrivacy;
  final String storyPrivacy;
  final bool readReceipts;
  final String groupAddPrivacy;
  final List<BlockedUserItem> blockedUsers;

  // Notifications
  final bool pauseAllNotifications;
  final bool messageNotifications;
  final bool messageSound;
  final bool messageVibrate;
  final bool messagePreview;
  final bool groupNotifications;
  final bool storyNotifications;
  final bool liveAlerts;
  final bool inAppSounds;

  // Content
  final String sensitiveFilter;
  final String autoplayMode;
  final String streamingQuality;
  final bool subtitlesEnabled;

  // Downloads & Storage
  final String downloadQuality;
  final bool downloadWifiOnly;
  final bool autoDownloadPhotos;
  final bool autoDownloadVideos;
  final bool autoDownloadDocs;
  final String storageLocation;

  // Data Usage
  final bool dataSaver;
  final bool lowDataCalls;
  final double cellularSentMB;
  final double cellularReceivedMB;
  final double wifiSentMB;
  final double wifiReceivedMB;

  // Cache Management
  final double videoCacheMB;
  final double imageCacheMB;
  final double audioCacheMB;
  final double databaseMB;
  final String keepMediaDuration;

  double get totalCacheMB =>
      videoCacheMB + imageCacheMB + audioCacheMB + databaseMB;

  const SocialSettingsState({
    required this.twoFactorEnabled,
    required this.biometricLockEnabled,
    required this.loginAlerts,
    required this.sessions,
    required this.lastSeenPrivacy,
    required this.profilePhotoPrivacy,
    required this.storyPrivacy,
    required this.readReceipts,
    required this.groupAddPrivacy,
    required this.blockedUsers,
    required this.pauseAllNotifications,
    required this.messageNotifications,
    required this.messageSound,
    required this.messageVibrate,
    required this.messagePreview,
    required this.groupNotifications,
    required this.storyNotifications,
    required this.liveAlerts,
    required this.inAppSounds,
    required this.sensitiveFilter,
    required this.autoplayMode,
    required this.streamingQuality,
    required this.subtitlesEnabled,
    required this.downloadQuality,
    required this.downloadWifiOnly,
    required this.autoDownloadPhotos,
    required this.autoDownloadVideos,
    required this.autoDownloadDocs,
    required this.storageLocation,
    required this.dataSaver,
    required this.lowDataCalls,
    required this.cellularSentMB,
    required this.cellularReceivedMB,
    required this.wifiSentMB,
    required this.wifiReceivedMB,
    required this.videoCacheMB,
    required this.imageCacheMB,
    required this.audioCacheMB,
    required this.databaseMB,
    required this.keepMediaDuration,
  });

  SocialSettingsState copyWith({
    bool? twoFactorEnabled,
    bool? biometricLockEnabled,
    bool? loginAlerts,
    List<SessionItem>? sessions,
    String? lastSeenPrivacy,
    String? profilePhotoPrivacy,
    String? storyPrivacy,
    bool? readReceipts,
    String? groupAddPrivacy,
    List<BlockedUserItem>? blockedUsers,
    bool? pauseAllNotifications,
    bool? messageNotifications,
    bool? messageSound,
    bool? messageVibrate,
    bool? messagePreview,
    bool? groupNotifications,
    bool? storyNotifications,
    bool? liveAlerts,
    bool? inAppSounds,
    String? sensitiveFilter,
    String? autoplayMode,
    String? streamingQuality,
    bool? subtitlesEnabled,
    String? downloadQuality,
    bool? downloadWifiOnly,
    bool? autoDownloadPhotos,
    bool? autoDownloadVideos,
    bool? autoDownloadDocs,
    String? storageLocation,
    bool? dataSaver,
    bool? lowDataCalls,
    double? cellularSentMB,
    double? cellularReceivedMB,
    double? wifiSentMB,
    double? wifiReceivedMB,
    double? videoCacheMB,
    double? imageCacheMB,
    double? audioCacheMB,
    double? databaseMB,
    String? keepMediaDuration,
  }) {
    return SocialSettingsState(
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      loginAlerts: loginAlerts ?? this.loginAlerts,
      sessions: sessions ?? this.sessions,
      lastSeenPrivacy: lastSeenPrivacy ?? this.lastSeenPrivacy,
      profilePhotoPrivacy: profilePhotoPrivacy ?? this.profilePhotoPrivacy,
      storyPrivacy: storyPrivacy ?? this.storyPrivacy,
      readReceipts: readReceipts ?? this.readReceipts,
      groupAddPrivacy: groupAddPrivacy ?? this.groupAddPrivacy,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      pauseAllNotifications:
          pauseAllNotifications ?? this.pauseAllNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      messageSound: messageSound ?? this.messageSound,
      messageVibrate: messageVibrate ?? this.messageVibrate,
      messagePreview: messagePreview ?? this.messagePreview,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      storyNotifications: storyNotifications ?? this.storyNotifications,
      liveAlerts: liveAlerts ?? this.liveAlerts,
      inAppSounds: inAppSounds ?? this.inAppSounds,
      sensitiveFilter: sensitiveFilter ?? this.sensitiveFilter,
      autoplayMode: autoplayMode ?? this.autoplayMode,
      streamingQuality: streamingQuality ?? this.streamingQuality,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      downloadWifiOnly: downloadWifiOnly ?? this.downloadWifiOnly,
      autoDownloadPhotos: autoDownloadPhotos ?? this.autoDownloadPhotos,
      autoDownloadVideos: autoDownloadVideos ?? this.autoDownloadVideos,
      autoDownloadDocs: autoDownloadDocs ?? this.autoDownloadDocs,
      storageLocation: storageLocation ?? this.storageLocation,
      dataSaver: dataSaver ?? this.dataSaver,
      lowDataCalls: lowDataCalls ?? this.lowDataCalls,
      cellularSentMB: cellularSentMB ?? this.cellularSentMB,
      cellularReceivedMB: cellularReceivedMB ?? this.cellularReceivedMB,
      wifiSentMB: wifiSentMB ?? this.wifiSentMB,
      wifiReceivedMB: wifiReceivedMB ?? this.wifiReceivedMB,
      videoCacheMB: videoCacheMB ?? this.videoCacheMB,
      imageCacheMB: imageCacheMB ?? this.imageCacheMB,
      audioCacheMB: audioCacheMB ?? this.audioCacheMB,
      databaseMB: databaseMB ?? this.databaseMB,
      keepMediaDuration: keepMediaDuration ?? this.keepMediaDuration,
    );
  }
}

class SocialSettingsNotifier extends StateNotifier<SocialSettingsState> {
  final SharedPreferences _prefs;

  SocialSettingsNotifier(this._prefs)
      : super(
          SocialSettingsState(
            // Security
            twoFactorEnabled: _prefs.getBool('sec_2fa') ?? false,
            biometricLockEnabled: _prefs.getBool('sec_biometric') ?? false,
            loginAlerts: _prefs.getBool('sec_login_alerts') ?? true,
            sessions: const [
              SessionItem(
                id: 'curr',
                deviceName: 'Pixel 8 Pro (This Phone)',
                platform: 'Android 14 • App v1.0.0',
                location: 'Addis Ababa, Ethiopia',
                ipAddress: '197.156.103.42',
                lastActive: 'Online now',
                isCurrent: true,
              ),
              SessionItem(
                id: 'sess_1',
                deviceName: 'Chrome on Windows 11',
                platform: 'Desktop Browser',
                location: 'Addis Ababa, Ethiopia',
                ipAddress: '197.156.103.18',
                lastActive: 'Active 2 hours ago',
                isCurrent: false,
              ),
              SessionItem(
                id: 'sess_2',
                deviceName: 'Telegram Desktop / Mac',
                platform: 'macOS Sonoma',
                location: 'Nairobi, Kenya',
                ipAddress: '105.163.2.91',
                lastActive: 'Active yesterday',
                isCurrent: false,
              ),
            ],

            // Privacy
            lastSeenPrivacy: _prefs.getString('priv_last_seen') ?? 'Everyone',
            profilePhotoPrivacy:
                _prefs.getString('priv_profile_photo') ?? 'Everyone',
            storyPrivacy: _prefs.getString('priv_story') ?? 'Everyone',
            readReceipts: _prefs.getBool('priv_read_receipts') ?? true,
            groupAddPrivacy:
                _prefs.getString('priv_group_add') ?? 'My Contacts',
            blockedUsers: const [
              BlockedUserItem(
                id: 'blk_1',
                name: 'Spam Bot 2026',
                username: '@spambot_promo',
              ),
              BlockedUserItem(
                id: 'blk_2',
                name: 'Unwanted Contact',
                username: '@unwanted_user',
              ),
            ],

            // Notifications
            pauseAllNotifications: _prefs.getBool('notif_pause_all') ?? false,
            messageNotifications: _prefs.getBool('notif_messages') ?? true,
            messageSound: _prefs.getBool('notif_sound') ?? true,
            messageVibrate: _prefs.getBool('notif_vibrate') ?? true,
            messagePreview: _prefs.getBool('notif_preview') ?? true,
            groupNotifications: _prefs.getBool('notif_groups') ?? true,
            storyNotifications: _prefs.getBool('notif_stories') ?? true,
            liveAlerts: _prefs.getBool('notif_live') ?? true,
            inAppSounds: _prefs.getBool('notif_in_app_sounds') ?? true,

            // Content
            sensitiveFilter:
                _prefs.getString('content_sensitive') ?? 'Standard',
            autoplayMode: _prefs.getString('content_autoplay') ?? 'Wi-Fi Only',
            streamingQuality:
                _prefs.getString('content_quality') ?? 'Auto (Recommended)',
            subtitlesEnabled: _prefs.getBool('content_subtitles') ?? false,

            // Downloads & Storage
            downloadQuality:
                _prefs.getString('dl_quality') ?? '1080p Full HD',
            downloadWifiOnly: _prefs.getBool('dl_wifi_only') ?? true,
            autoDownloadPhotos: _prefs.getBool('dl_auto_photos') ?? true,
            autoDownloadVideos: _prefs.getBool('dl_auto_videos') ?? false,
            autoDownloadDocs: _prefs.getBool('dl_auto_docs') ?? false,
            storageLocation: _prefs.getString('dl_location') ??
                'Internal Storage (/Download)',

            // Data Usage
            dataSaver: _prefs.getBool('data_saver') ?? false,
            lowDataCalls: _prefs.getBool('data_low_calls') ?? false,
            cellularSentMB: 48.2,
            cellularReceivedMB: 342.7,
            wifiSentMB: 186.4,
            wifiReceivedMB: 1420.5,

            // Cache
            videoCacheMB: 148.5,
            imageCacheMB: 62.3,
            audioCacheMB: 14.1,
            databaseMB: 5.2,
            keepMediaDuration:
                _prefs.getString('cache_keep_media') ?? '1 Month',
          ),
        );

  // ── Security Actions ────────────────────────────────────────────────────────
  Future<void> setTwoFactor(bool enabled) async {
    state = state.copyWith(twoFactorEnabled: enabled);
    await _prefs.setBool('sec_2fa', enabled);
  }

  Future<void> setBiometricLock(bool enabled) async {
    state = state.copyWith(biometricLockEnabled: enabled);
    await _prefs.setBool('sec_biometric', enabled);
  }

  Future<void> setLoginAlerts(bool enabled) async {
    state = state.copyWith(loginAlerts: enabled);
    await _prefs.setBool('sec_login_alerts', enabled);
  }

  void terminateSession(String sessionId) {
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != sessionId).toList(),
    );
  }

  void terminateAllOtherSessions() {
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.isCurrent).toList(),
    );
  }

  // ── Privacy Actions ─────────────────────────────────────────────────────────
  Future<void> setLastSeenPrivacy(String val) async {
    state = state.copyWith(lastSeenPrivacy: val);
    await _prefs.setString('priv_last_seen', val);
  }

  Future<void> setProfilePhotoPrivacy(String val) async {
    state = state.copyWith(profilePhotoPrivacy: val);
    await _prefs.setString('priv_profile_photo', val);
  }

  Future<void> setStoryPrivacy(String val) async {
    state = state.copyWith(storyPrivacy: val);
    await _prefs.setString('priv_story', val);
  }

  Future<void> setReadReceipts(bool val) async {
    state = state.copyWith(readReceipts: val);
    await _prefs.setBool('priv_read_receipts', val);
  }

  Future<void> setGroupAddPrivacy(String val) async {
    state = state.copyWith(groupAddPrivacy: val);
    await _prefs.setString('priv_group_add', val);
  }

  void unblockUser(String userId) {
    state = state.copyWith(
      blockedUsers: state.blockedUsers.where((u) => u.id != userId).toList(),
    );
  }

  // ── Notification Actions ───────────────────────────────────────────────────
  Future<void> setPauseAllNotifications(bool val) async {
    state = state.copyWith(pauseAllNotifications: val);
    await _prefs.setBool('notif_pause_all', val);
  }

  Future<void> setMessageNotifications(bool val) async {
    state = state.copyWith(messageNotifications: val);
    await _prefs.setBool('notif_messages', val);
  }

  Future<void> setMessageSound(bool val) async {
    state = state.copyWith(messageSound: val);
    await _prefs.setBool('notif_sound', val);
  }

  Future<void> setMessageVibrate(bool val) async {
    state = state.copyWith(messageVibrate: val);
    await _prefs.setBool('notif_vibrate', val);
  }

  Future<void> setMessagePreview(bool val) async {
    state = state.copyWith(messagePreview: val);
    await _prefs.setBool('notif_preview', val);
  }

  Future<void> setGroupNotifications(bool val) async {
    state = state.copyWith(groupNotifications: val);
    await _prefs.setBool('notif_groups', val);
  }

  Future<void> setStoryNotifications(bool val) async {
    state = state.copyWith(storyNotifications: val);
    await _prefs.setBool('notif_stories', val);
  }

  Future<void> setLiveAlerts(bool val) async {
    state = state.copyWith(liveAlerts: val);
    await _prefs.setBool('notif_live', val);
  }

  Future<void> setInAppSounds(bool val) async {
    state = state.copyWith(inAppSounds: val);
    await _prefs.setBool('notif_in_app_sounds', val);
  }

  // ── Content Actions ─────────────────────────────────────────────────────────
  Future<void> setSensitiveFilter(String val) async {
    state = state.copyWith(sensitiveFilter: val);
    await _prefs.setString('content_sensitive', val);
  }

  Future<void> setAutoplayMode(String val) async {
    state = state.copyWith(autoplayMode: val);
    await _prefs.setString('content_autoplay', val);
  }

  Future<void> setStreamingQuality(String val) async {
    state = state.copyWith(streamingQuality: val);
    await _prefs.setString('content_quality', val);
  }

  Future<void> setSubtitlesEnabled(bool val) async {
    state = state.copyWith(subtitlesEnabled: val);
    await _prefs.setBool('content_subtitles', val);
  }

  // ── Downloads & Storage Actions ─────────────────────────────────────────────
  Future<void> setDownloadQuality(String val) async {
    state = state.copyWith(downloadQuality: val);
    await _prefs.setString('dl_quality', val);
  }

  Future<void> setDownloadWifiOnly(bool val) async {
    state = state.copyWith(downloadWifiOnly: val);
    await _prefs.setBool('dl_wifi_only', val);
  }

  Future<void> setAutoDownloadPhotos(bool val) async {
    state = state.copyWith(autoDownloadPhotos: val);
    await _prefs.setBool('dl_auto_photos', val);
  }

  Future<void> setAutoDownloadVideos(bool val) async {
    state = state.copyWith(autoDownloadVideos: val);
    await _prefs.setBool('dl_auto_videos', val);
  }

  Future<void> setAutoDownloadDocs(bool val) async {
    state = state.copyWith(autoDownloadDocs: val);
    await _prefs.setBool('dl_auto_docs', val);
  }

  // ── Data Usage Actions ──────────────────────────────────────────────────────
  Future<void> setDataSaver(bool val) async {
    state = state.copyWith(dataSaver: val);
    await _prefs.setBool('data_saver', val);
  }

  Future<void> setLowDataCalls(bool val) async {
    state = state.copyWith(lowDataCalls: val);
    await _prefs.setBool('data_low_calls', val);
  }

  void resetNetworkStats() {
    state = state.copyWith(
      cellularSentMB: 0.0,
      cellularReceivedMB: 0.0,
      wifiSentMB: 0.0,
      wifiReceivedMB: 0.0,
    );
  }

  // ── Cache Actions ───────────────────────────────────────────────────────────
  Future<void> setKeepMediaDuration(String val) async {
    state = state.copyWith(keepMediaDuration: val);
    await _prefs.setString('cache_keep_media', val);
  }

  Future<void> clearAppCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      debugPrint('[Cache] Error clearing cache: $e');
    }
    state = state.copyWith(
      videoCacheMB: 0.0,
      imageCacheMB: 0.0,
      audioCacheMB: 0.0,
    );
  }
}

final socialSettingsProvider =
    StateNotifierProvider<SocialSettingsNotifier, SocialSettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SocialSettingsNotifier(prefs);
});
