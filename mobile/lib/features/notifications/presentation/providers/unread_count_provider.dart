// lib/features/notifications/presentation/providers/unread_count_provider.dart
// Provides a lightweight unread count that updates from the notifications provider.
// This is independent of the notifications screen so the badge in AppShell
// always reflects the real unread count without requiring the screen to be opened.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_provider.dart';

/// Derives unread count from the notifications state.
/// Lightweight derived provider — no extra network calls.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifState = ref.watch(notificationsProvider);
  return notifState.valueOrNull?.unreadCount ?? 0;
});
