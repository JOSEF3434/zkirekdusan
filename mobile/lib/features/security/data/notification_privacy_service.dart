// lib/features/security/data/notification_privacy_service.dart
//
// Manages privacy redaction for notifications when App Lock is enabled
// and active, preventing sensitive sender or message preview leakage.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_provider.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_settings_provider.dart';

class RedactedNotification {
  final String title;
  final String body;

  const RedactedNotification({
    required this.title,
    required this.body,
  });
}

class NotificationPrivacyService {
  final bool isEnabled;
  final bool isLocked;

  const NotificationPrivacyService({
    required this.isEnabled,
    required this.isLocked,
  });

  bool get shouldRedact => isEnabled && isLocked;

  String maybeRedact(String? text, {required String fallback}) {
    if (shouldRedact) return fallback;
    return text ?? fallback;
  }

  static bool shouldRedactFromPrefs(SharedPreferences? prefs, {DateTime? now}) {
    if (prefs == null) return true; // fail-closed

    final appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
    if (!appLockEnabled) return false;

    final notificationPrivacy =
        prefs.getBool('app_lock_notification_privacy') ?? true;
    if (!notificationPrivacy) return false;

    final isLocked = prefs.getBool('app_lock_is_locked');
    if (isLocked == true) return true;

    final timeoutMinutes = prefs.getInt('app_lock_timeout_minutes') ?? 0;
    if (timeoutMinutes == 0) return true;

    final lastActiveMillis = prefs.getInt('app_lock_last_active');
    if (lastActiveMillis == null) return true; // terminated state

    final currentTime = now ?? DateTime.now();
    final elapsed = currentTime.difference(
      DateTime.fromMillisecondsSinceEpoch(lastActiveMillis),
    );
    if (elapsed.inMinutes >= timeoutMinutes) return true;

    return false;
  }

  static RedactedNotification redactNotification({
    required String originalTitle,
    required String originalBody,
    required bool shouldRedact,
    String? languageCode,
  }) {
    if (!shouldRedact) {
      return RedactedNotification(
        title: originalTitle,
        body: originalBody,
      );
    }

    final isEn = languageCode == 'en';
    const fallbackTitle = 'ዝክረ ቅዱሳን';
    final fallbackBody =
        isEn ? 'You have a new message' : 'አዲስ መልእክት አለዎት';

    return RedactedNotification(
      title: fallbackTitle,
      body: fallbackBody,
    );
  }
}

final notificationPrivacyServiceProvider =
    Provider<NotificationPrivacyService>((ref) {
  final settings = ref.watch(appLockSettingsProvider);
  final lockState = ref.watch(appLockProvider);
  final isLocked = lockState.status == AppLockStatus.locked;

  return NotificationPrivacyService(
    isEnabled: settings.isEnabled && settings.notificationPrivacy,
    isLocked: isLocked,
  );
});
