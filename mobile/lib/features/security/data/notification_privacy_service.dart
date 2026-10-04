// lib/features/security/data/notification_privacy_service.dart
//
// Provides helpers for Notification Privacy mode (Telegram-inspired).
//
// When enabled:
//   • Push notification titles show the app name instead of the sender.
//   • Notification bodies are replaced with "New message" / "You have a new notification".
//   • Notification privacy is ON by default whenever App Lock is active and
//     the notificationPrivacyEnabled setting is true.
//
// Usage:
//   final svc = ref.read(notificationPrivacyServiceProvider);
//   final title = svc.maybeRedact(actualTitle, fallback: 'ዝክረ ቅዱሳን');
//   final body  = svc.maybeRedact(actualBody,  fallback: 'You have a new message');
//
// The notification delivery layer (FCM handler) calls these helpers before
// displaying any local notification.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_provider.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_settings_provider.dart';

class NotificationPrivacyService {
  final bool _isEnabled;
  final bool _isLocked;

  const NotificationPrivacyService({
    required bool isEnabled,
    required bool isLocked,
  })  : _isEnabled = isEnabled,
        _isLocked = isLocked;

  /// Returns true when notification content should be redacted.
  bool get shouldRedact => _isEnabled && _isLocked;

  /// Returns [text] if privacy mode is inactive, or [fallback] if active.
  String maybeRedact(String? text, {required String fallback}) {
    if (!shouldRedact) return text ?? fallback;
    return fallback;
  }

  /// Returns localized fallback title for redacted notifications.
  static String getFallbackTitle(String? languageCode) => 'ዝክረ ቅዱሳን';

  /// Returns localized fallback body for redacted notifications.
  static String getFallbackBody(String? languageCode) {
    if (languageCode == 'am' || languageCode == 'gez') {
      return 'አዲስ መልእክት አለዎት';
    }
    return 'You have a new message';
  }

  /// Background-safe determination of whether notification content must be redacted.
  ///
  /// Evaluates persisted SharedPreferences values without needing Riverpod:
  /// - 'app_lock_enabled'
  /// - 'app_lock_notification_privacy'
  /// - 'app_lock_is_locked'
  /// - 'app_lock_timeout_minutes'
  /// - 'app_lock_last_active'
  ///
  /// CRITICAL SECURITY POLICY:
  /// - If [prefs] is null or storage fails -> FAILS CLOSED (returns true) for sensitive content.
  /// - If App Lock is disabled -> returns false.
  /// - If Notification Privacy is disabled -> returns false.
  /// - If both are enabled:
  ///     - If explicitly marked locked ('app_lock_is_locked' == true) -> true.
  ///     - If timeout is 0 (immediate) -> true.
  ///     - If timeout < 0 (never) -> returns isLocked ?? false.
  ///     - If lastActive is null (e.g. terminated app) -> true (terminated app requires unlock).
  ///     - If elapsed >= timeout -> true.
  ///     - Otherwise (within timeout grace period) -> false.
  static bool shouldRedactFromPrefs(
    SharedPreferences? prefs, {
    DateTime? now,
  }) {
    if (prefs == null) {
      // Fail closed: Unknown privacy state must never expose sensitive content.
      return true;
    }

    try {
      final appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      if (!appLockEnabled) {
        return false;
      }

      final privacyEnabled =
          prefs.getBool('app_lock_notification_privacy') ?? false;
      if (!privacyEnabled) {
        return false;
      }

      final isLocked = prefs.getBool('app_lock_is_locked');
      if (isLocked == true) {
        return true;
      }

      final timeoutMinutes = prefs.getInt('app_lock_timeout_minutes') ?? 1;
      if (timeoutMinutes == 0) {
        return true;
      }

      if (timeoutMinutes < 0) {
        return isLocked ?? false;
      }

      final lastActiveMs = prefs.getInt('app_lock_last_active');
      if (lastActiveMs == null) {
        // App was never active in this session or was killed/terminated.
        // Opening the app will require unlocking, so treat as locked.
        return true;
      }

      final currentTime = now ?? DateTime.now();
      final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMs);
      final elapsed = currentTime.difference(lastActive);

      if (elapsed.inMinutes >= timeoutMinutes) {
        return true;
      }

      return isLocked ?? false;
    } catch (_) {
      // Storage read error -> Fail closed
      return true;
    }
  }

  /// Helper to redact both title and body in one call with localization.
  static ({String title, String body}) redactNotification({
    required String originalTitle,
    required String originalBody,
    required bool shouldRedact,
    String? languageCode,
  }) {
    if (!shouldRedact) {
      return (title: originalTitle, body: originalBody);
    }
    return (
      title: getFallbackTitle(languageCode),
      body: getFallbackBody(languageCode),
    );
  }
}

/// Riverpod provider — automatically re-derives whenever lock state or
/// settings change. Notification handlers should watch this.
final notificationPrivacyServiceProvider =
    Provider<NotificationPrivacyService>((ref) {
  final settings = ref.watch(appLockSettingsProvider);
  final lockState = ref.watch(appLockProvider);

  return NotificationPrivacyService(
    isEnabled: settings.isEnabled && settings.notificationPrivacyEnabled,
    isLocked: lockState.status == AppLockStatus.locked,
  );
});
