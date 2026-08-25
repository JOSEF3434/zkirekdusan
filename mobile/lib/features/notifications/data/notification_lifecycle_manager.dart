// lib/features/notifications/data/notification_lifecycle_manager.dart
// Bridges authentication state → NotificationSocketService and FcmService lifecycle.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/notifications/data/fcm_service.dart';
import 'package:mobile/features/notifications/data/notification_socket_service.dart';

/// A provider that watches auth state and manages the notification socket & FCM lifecycles.
/// Initialized early in the app (in main / AppShell).
final notificationLifecycleProvider = Provider<void>((ref) {
  final auth = ref.watch(authProvider);
  final socketService = ref.watch(notificationSocketServiceProvider);
  final fcmService = ref.watch(fcmServiceProvider);

  if (auth.status == AuthStatus.authenticated) {
    socketService.connect();
    fcmService.onUserAuthenticated();
  } else {
    socketService.disconnect();
    fcmService.onUserLoggedOut();
  }
});

