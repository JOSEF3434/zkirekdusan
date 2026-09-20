// lib/features/notifications/data/fcm_service.dart
// Production-ready Firebase Cloud Messaging service for Flutter.
// Handles: permissions, FCM token lifecycle, token sync to NestJS backend,
// foreground messages, background messages, and terminated/deep-link click routing.

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/features/notifications/core/notification_navigation_resolver.dart';
import 'package:mobile/features/notifications/data/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/notification_model.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_provider.dart';

const _kFcmDeviceTokenKey = 'fcm_device_token';

/// Top-level background message handler required by Firebase Messaging.
/// Must be annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Ensure Firebase is initialized in background isolate if needed
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint(
      '[FCM Background] Message ID: ${message.messageId}, title: ${message.notification?.title}',
    );
  } catch (e) {
    debugPrint('[FCM Background] Handler error: $e');
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  final service = FcmService(ref, repository);
  return service;
});

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

  /// Initializes FCM listeners and checks for initial launch message.
  Future<void> init() async {
    if (_initialized) return;

    // Firebase messaging is primarily supported on Android, iOS, Web, macOS
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      debugPrint('[FCM] Platform $defaultTargetPlatform does not support FCM');
      _initialized = true;
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('[FCM] Firebase not initialized — skipping FCM init');
        return;
      }

      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions (iOS / Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '[FCM] Permission status: ${settings.authorizationStatus}',
      );

      // 2. Set presentation options for foreground notifications (iOS)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Fetch current FCM token
      try {
        _currentToken = await messaging.getToken();
        if (_currentToken != null) {
          debugPrint(
            '[FCM] Current token: ${_currentToken!.substring(0, _currentToken!.length > 15 ? 15 : _currentToken!.length)}...',
          );
          await _storage.write(key: _kFcmDeviceTokenKey, value: _currentToken);
        }
      } catch (tokenErr) {
        debugPrint('[FCM] Error fetching token: $tokenErr');
      }

      // 4. Listen for token refresh events
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM] Token refreshed');
        _currentToken = newToken;
        await _storage.write(key: _kFcmDeviceTokenKey, value: newToken);
        await _syncTokenToBackend(newToken);
      });

      // 5. Handle foreground messages
      _foregroundSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[FCM Foreground] Received message: ${message.notification?.title}',
        );
        try {
          final data = Map<String, dynamic>.from(message.data);
          final id = data['notificationId'] as String? ??
              message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString();

          final notification = NotificationResponseDto(
            id: id,
            type: (data['type'] as String?) ?? 'SYSTEM',
            title: message.notification?.title ??
                (data['title'] as String?) ??
                'Notification',
            body: message.notification?.body ??
                (data['body'] as String?) ??
                '',
            data: data,
            isRead: false,
            createdAt: message.sentTime ?? DateTime.now(),
          );

          _ref.read(notificationsProvider.notifier).addFromFcm(notification);
        } catch (e) {
          debugPrint('[FCM Foreground] Error handling message: $e');
        }
      });

      // 6. Handle notification click when app is in background
      _messageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((
        RemoteMessage message,
      ) {
        debugPrint('[FCM Click] App opened from notification');
        _handleMessageNavigation(message);
      });

      // 7. Check if app was opened from a terminated state via notification click
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM Initial] App launched from terminated state via notification');
        // Delay slightly to let router and widget tree mount
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleMessageNavigation(initialMessage);
        });
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] Initialization failed gracefully: $e');
    }
  }

  /// Called when user logs in or app restores authenticated session.
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

  /// Called when user logs out.
  Future<void> onUserLoggedOut() async {
    final token = _currentToken ?? await _storage.read(key: _kFcmDeviceTokenKey);
    if (token != null) {
      await _repository.removeDeviceToken(token);
    }
    await _storage.delete(key: _kFcmDeviceTokenKey);
  }

  Future<void> _syncTokenToBackend(String token) async {
    final platform = kIsWeb
        ? 'WEB'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'IOS'
            : 'ANDROID';

    debugPrint('[FCM] Syncing device token ($platform) to backend...');
    await _repository.registerDeviceToken(
      token: token,
      platform: platform,
    );
  }

  void _handleMessageNavigation(RemoteMessage message) {
    try {
      final context = rootNavigatorKey.currentContext;
      if (context == null) {
        debugPrint('[FCM Navigation] rootNavigatorKey context is null');
        return;
      }

      final data = Map<String, dynamic>.from(message.data);
      final notificationDto = NotificationResponseDto(
        id: data['notificationId'] as String? ??
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        type: (data['type'] as String?) ?? 'SYSTEM',
        title: message.notification?.title ??
            (data['title'] as String?) ??
            'Notification',
        body: message.notification?.body ??
            (data['body'] as String?) ??
            '',
        data: data,
        isRead: false,
        createdAt: message.sentTime ?? DateTime.now(),
      );

      NotificationNavigationResolver.navigate(context, notificationDto);
    } catch (e) {
      debugPrint('[FCM Navigation] Failed to route notification: $e');
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _messageOpenedSub?.cancel();
  }
}
