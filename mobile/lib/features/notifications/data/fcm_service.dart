// lib/features/notifications/data/fcm_service.dart
//
// Production-ready Firebase Cloud Messaging service for Flutter.
//
// ── Notification Privacy Architecture ────────────────────────────────────
//
// SECURITY ISSUE (fixed here): When Firebase delivers a notification with a
// `notification` payload, the OS displays it automatically WITHOUT passing
// through any Flutter code. This bypasses all Dart-side privacy redaction.
//
// FIX: All server-sent FCM messages must be DATA-ONLY (no `notification`
// field). The client constructs and displays local notifications using
// flutter_local_notifications, passing content through NotificationPrivacyService
// so sensitive fields are redacted when the app is locked.
//
// This means the backend must send:
//   { "data": { "type": "MESSAGE", "title": "...", "body": "..." } }
// NOT:
//   { "notification": { "title": "...", "body": "..." }, "data": {...} }
//
// iOS: setForegroundNotificationPresentationOptions(alert: false) ensures
// Firebase does not auto-display notifications while in foreground.
//
// Background/terminated: firebaseMessagingBackgroundHandler uses local
// notifications with privacy redaction applied.
//
// Notification Actions (Reply, Mark as Read, Open Chat) are intercepted
// by the notification tap handler which ALWAYS routes through the router
// redirect guard. The guard checks AppLockStatus and redirects to /lock
// before navigating to any protected route.

import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/notifications/core/notification_navigation_resolver.dart';
import 'package:mobile/features/notifications/data/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/notification_model.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:mobile/features/security/data/notification_privacy_service.dart';

const _kFcmDeviceTokenKey = 'fcm_device_token';

// ── Local notification channel ─────────────────────────────────────────────

const _kAndroidChannelId = 'zikre_general';
const _kAndroidChannelName = 'ዝክረ ቅዱሳን';
const _kAndroidChannelDesc = 'General notifications for ዝክረ ቅዱሳን';

final _localNotifications = FlutterLocalNotificationsPlugin();
bool _localNotificationsInitialized = false;

/// Extracts a display-safe notification payload from a FCM RemoteMessage.
/// Prefers the `data` map fields because the server MUST send data-only
/// messages for privacy-compliant operation.
({String title, String body, Map<String, dynamic> data})
    _extractPayload(RemoteMessage message) {
  final data = Map<String, dynamic>.from(message.data);
  final title =
      (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : message.notification?.title ?? 'ዝክረ ቅዱሳን';
  final body =
      (data['body'] as String?)?.trim().isNotEmpty == true
          ? data['body'] as String
          : message.notification?.body ?? '';
  return (title: title, body: body, data: data);
}

/// Top-level background message handler — required by Firebase Messaging.
/// Runs in a separate isolate; MUST be annotated with @pragma('vm:entry-point').
///
/// Privacy: We display a local notification using the privacy-safe fallback
/// text. We cannot read Riverpod state from a background isolate, so we
/// read SharedPreferences directly to evaluate the privacy policy.
///
/// Security: If SharedPreferences cannot be read or privacy state cannot be
/// determined, this function FAILS CLOSED and redacts sensitive content.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    await _ensureLocalNotificationsInitialized();

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[FCM Background] Failed to load SharedPreferences: $e');
      prefs = null; // Triggers fail-closed in shouldRedactFromPrefs
    }

    // Determine privacy decision from persisted state:
    // If prefs is null or storage fails -> shouldRedact is true (FAIL CLOSED).
    final shouldRedact =
        NotificationPrivacyService.shouldRedactFromPrefs(prefs);
    final languageCode = prefs?.getString('languageCode') ?? 'en';

    final payload = _extractPayload(message);

    final display = NotificationPrivacyService.redactNotification(
      originalTitle: payload.title,
      originalBody: payload.body,
      shouldRedact: shouldRedact,
      languageCode: languageCode,
    );

    // Build payload data for local notification tap navigation
    final notificationData = Map<String, dynamic>.from(payload.data);
    notificationData['title'] = payload.title; // keep raw title for deep routing
    notificationData['body'] = payload.body;

    await _showLocalNotification(
      id: message.messageId.hashCode.abs(),
      title: display.title,
      body: display.body,
      payload: jsonEncode(notificationData),
    );
  } catch (e) {
    // Never crash the background isolate
    debugPrint('[FCM Background] Handler error: $e');
  }
}

Future<void> _ensureLocalNotificationsInitialized() async {
  if (_localNotificationsInitialized) return;
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _localNotifications.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
    onDidReceiveNotificationResponse: _onLocalNotificationTapped,
  );
  _localNotificationsInitialized = true;
}

@pragma('vm:entry-point')
void _onLocalNotificationTapped(NotificationResponse response) {
  try {
    final payloadStr = response.payload;
    if (payloadStr == null || payloadStr.isEmpty) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(payloadStr) as Map);
    } catch (_) {
      return;
    }

    final notificationDto = NotificationResponseDto(
      id: data['notificationId'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: (data['type'] as String?) ?? 'SYSTEM',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    NotificationNavigationResolver.navigate(context, notificationDto);
  } catch (e) {
    debugPrint('[Notification Tap] Error navigating from local notification: $e');
  }
}

Future<void> _showLocalNotification({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  await _ensureLocalNotificationsInitialized();
  const androidDetails = AndroidNotificationDetails(
    _kAndroidChannelId,
    _kAndroidChannelName,
    channelDescription: _kAndroidChannelDesc,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  await _localNotifications.show(
    id,
    title,
    body,
    const NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: payload,
  );
}

// ── Provider ───────────────────────────────────────────────────────────────

final fcmServiceProvider = Provider<FcmService>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return FcmService(ref, repository);
});

// ── FcmService ─────────────────────────────────────────────────────────────

class FcmService {
  final Ref _ref;
  final NotificationsRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _initialized = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _messageOpenedSub;

  FcmService(this._ref, this._repository);

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      _initialized = true;
      return;
    }

    try {
      if (Firebase.apps.isEmpty) return;

      await _ensureLocalNotificationsInitialized();

      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // SECURITY: Disable automatic foreground notification display on iOS.
      // We handle display ourselves so we can apply privacy redaction.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false, // ← critical: prevents OS auto-display with raw content
        badge: true,
        sound: false,
      );

      // Create Android notification channel
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(const AndroidNotificationChannel(
              _kAndroidChannelId,
              _kAndroidChannelName,
              description: _kAndroidChannelDesc,
              importance: Importance.high,
            ));
      }

      try {
        _currentToken = await messaging.getToken();
        if (_currentToken != null) {
          await _storage.write(
              key: _kFcmDeviceTokenKey, value: _currentToken);
        }
      } catch (_) {}

      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        await _storage.write(key: _kFcmDeviceTokenKey, value: newToken);
        await _syncTokenToBackend(newToken);
      });

      // Foreground messages: apply privacy redaction, show local notification
      _foregroundSub =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background tap: route through router lock guard
      _messageOpenedSub = FirebaseMessaging.onMessageOpenedApp
          .listen(_handleMessageNavigation);

      // Terminated-state tap
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleMessageNavigation(initialMessage);
        });
      }

      // Terminated-state local notification tap check
      final notificationAppLaunchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final response = notificationAppLaunchDetails?.notificationResponse;
        if (response != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _onLocalNotificationTapped(response);
          });
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] Initialization failed gracefully: $e');
    }
  }

  // ── Foreground handler ────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final payload = _extractPayload(message);

      // Apply privacy redaction based on lock state + user setting
      final privacySvc = _ref.read(notificationPrivacyServiceProvider);
      String? languageCode;
      try {
        languageCode = _ref.read(preferencesProvider).languageCode;
      } catch (_) {}

      final display = NotificationPrivacyService.redactNotification(
        originalTitle: payload.title,
        originalBody: payload.body,
        shouldRedact: privacySvc.shouldRedact,
        languageCode: languageCode,
      );

      final notificationData = Map<String, dynamic>.from(payload.data);
      notificationData['title'] = payload.title;
      notificationData['body'] = payload.body;

      // Show local notification with privacy-safe content
      _showLocalNotification(
        id: (message.messageId ?? DateTime.now().toString()).hashCode.abs(),
        title: display.title,
        body: display.body,
        payload: jsonEncode(notificationData),
      );

      // Add to in-app notification list using ACTUAL content (user is in app)
      final id =
          payload.data['notificationId'] as String? ??
          message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final notification = NotificationResponseDto(
        id: id,
        type: (payload.data['type'] as String?) ?? 'SYSTEM',
        title: payload.title, // raw title for in-app list
        body: payload.body, // raw body for in-app list
        data: payload.data,
        isRead: false,
        createdAt: message.sentTime ?? DateTime.now(),
      );

      _ref.read(notificationsProvider.notifier).addFromFcm(notification);
    } catch (e) {
      debugPrint('[FCM Foreground] Error handling message: $e');
    }
  }

  // ── Navigation handler (tapped notification) ──────────────────────────────
  //
  // SECURITY: Notification taps route through context.push/go which triggers
  // GoRouter's redirect guard. The guard checks AppLockStatus and redirects
  // to /lock before navigating to any protected route.
  // No protected content is displayed before the lock screen.

  void _handleMessageNavigation(RemoteMessage message) {
    try {
      final context = rootNavigatorKey.currentContext;
      if (context == null) return;

      final payload = _extractPayload(message);
      final notificationDto = NotificationResponseDto(
        id: payload.data['notificationId'] as String? ??
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        type: (payload.data['type'] as String?) ?? 'SYSTEM',
        title: payload.title,
        body: payload.body,
        data: payload.data,
        isRead: false,
        createdAt: message.sentTime ?? DateTime.now(),
      );

      // Router redirect guard handles App Lock interception
      NotificationNavigationResolver.navigate(context, notificationDto);
    } catch (e) {
      debugPrint('[FCM Navigation] Failed to route: $e');
    }
  }

  // ── Token management ────────────────────────────────────────────────────

  Future<void> onUserAuthenticated() async {
    if (_currentToken == null) {
      try {
        if (Firebase.apps.isNotEmpty) {
          _currentToken = await FirebaseMessaging.instance.getToken();
        }
      } catch (_) {}
    }
    if (_currentToken != null) {
      await _syncTokenToBackend(_currentToken!);
    }
  }

  Future<void> onUserLoggedOut() async {
    final token =
        _currentToken ?? await _storage.read(key: _kFcmDeviceTokenKey);
    if (token != null) {
      await _repository.removeDeviceToken(token);
    }
    await _storage.delete(key: _kFcmDeviceTokenKey);
    _currentToken = null;
  }

  Future<void> _syncTokenToBackend(String token) async {
    final platform = kIsWeb
        ? 'WEB'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'IOS'
            : 'ANDROID';

    String? locale;
    try {
      locale = _ref.read(preferencesProvider).languageCode;
    } catch (_) {}

    await _repository.registerDeviceToken(
      token: token,
      platform: platform,
      locale: locale,
    );
  }

  Future<void> syncLocale(String languageCode) async {
    final token =
        _currentToken ?? await _storage.read(key: _kFcmDeviceTokenKey);
    if (token == null) return;

    final platform = kIsWeb
        ? 'WEB'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'IOS'
            : 'ANDROID';

    await _repository.registerDeviceToken(
      token: token,
      platform: platform,
      locale: languageCode,
    );
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _messageOpenedSub?.cancel();
  }
}
