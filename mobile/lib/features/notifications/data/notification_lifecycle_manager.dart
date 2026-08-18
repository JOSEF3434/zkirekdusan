// lib/features/notifications/data/notification_lifecycle_manager.dart
// Bridges authentication state → NotificationSocketService lifecycle.
// Creates ONE centralized socket connection, shared via a global provider.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/notifications/data/notification_socket_service.dart';

/// A provider that watches auth state and manages the notification socket lifecycle.
/// Must be initialized early in the app (e.g., in main() or AppShell).
final notificationLifecycleProvider = Provider<void>((ref) {
  final auth = ref.watch(authProvider);
  final socketService = ref.watch(notificationSocketServiceProvider);

  if (auth.status == AuthStatus.authenticated) {
    socketService.connect();
  } else {
    socketService.disconnect();
  }
});
