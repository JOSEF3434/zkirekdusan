// lib/features/notifications/presentation/providers/notifications_provider.dart
// Upgraded to: real-time Socket.IO integration, unread count tracking,
// optimistic updates, rollback, and proper lifecycle management.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/notifications/data/notifications_repository.dart';
import 'package:mobile/features/notifications/data/notification_socket_service.dart';
import 'package:mobile/features/notifications/domain/notification_model.dart';

class NotificationsState {
  final List<NotificationResponseDto> notifications;
  final int unreadCount;
  final bool isLoadingMore;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoadingMore = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationResponseDto>? notifications,
    int? unreadCount,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsState>(() {
      return NotificationsNotifier();
    });

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  StreamSubscription<NotificationResponseDto>? _socketSub;

  @override
  Future<NotificationsState> build() async {
    final repo = ref.read(notificationsRepositoryProvider);
    final notifications = await repo.getAll();
    final unreadCount = await repo.getUnreadCount();

    // Subscribe to real-time notifications from the socket service
    final socketService = ref.read(notificationSocketServiceProvider);
    _socketSub?.cancel();
    _socketSub = socketService.notificationStream.listen(_onSocketNotification);

    ref.onDispose(() {
      _socketSub?.cancel();
    });

    return NotificationsState(
      notifications: notifications,
      unreadCount: unreadCount,
    );
  }

  void _onSocketNotification(NotificationResponseDto notification) {
    final current = state.valueOrNull;
    if (current == null) return;

    // Check for duplicates by id or by noteId in data payload
    final notifNoteId =
        notification.data?['noteId'] ?? notification.data?['calendarNoteId'];
    final exists = current.notifications.any((n) {
      if (n.id == notification.id) return true;
      if (notifNoteId != null) {
        final existingNoteId =
            n.data?['noteId'] ?? n.data?['calendarNoteId'];
        if (existingNoteId != null && existingNoteId == notifNoteId) {
          return true;
        }
      }
      return false;
    });
    if (exists) return;

    state = AsyncValue.data(
      current.copyWith(
        notifications: [notification, ...current.notifications],
        unreadCount: current.unreadCount + 1,
      ),
    );
  }

  /// Called from FcmService when a foreground push message arrives.
  /// Deduplicates against existing notifications before adding.
  void addFromFcm(NotificationResponseDto notification) {
    _onSocketNotification(notification);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    // Don't set loading — keep existing notifications visible during background refresh
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final notifications = await repo
          .getAll()
          .timeout(const Duration(seconds: 15));
      final unreadCount = await repo.getUnreadCount();
      state = AsyncValue.data(
        NotificationsState(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e, st) {
      if (previous != null) {
        // Keep showing cached notifications; surface error non-destructively
        state = AsyncValue.data(
          previous.copyWith(error: e.toString()),
        );
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> markAsRead(String id) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final target = currentState.notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => currentState.notifications.first,
    );
    if (target.isRead) return;

    // Optimistic update
    final updatedNotifications = currentState.notifications.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();

    state = AsyncValue.data(
      currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: (currentState.unreadCount - 1).clamp(0, 999),
      ),
    );

    try {
      final repo = ref.read(notificationsRepositoryProvider);
      await repo.markAsRead(id);
    } catch (_) {
      // Rollback on failure
      ref.invalidateSelf();
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Optimistic update
    final updatedNotifications = currentState.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    state = AsyncValue.data(
      currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      ),
    );

    try {
      final repo = ref.read(notificationsRepositoryProvider);
      await repo.markAllAsRead();
    } catch (_) {
      // Rollback on failure
      ref.invalidateSelf();
    }
  }

  Future<void> deleteNotification(String id) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final target = currentState.notifications.where((n) => n.id == id).toList();
    if (target.isEmpty) return;
    final wasUnread = !target.first.isRead;

    // Optimistic update
    state = AsyncValue.data(
      currentState.copyWith(
        notifications: currentState.notifications
            .where((n) => n.id != id)
            .toList(),
        unreadCount: wasUnread
            ? (currentState.unreadCount - 1).clamp(0, 999)
            : currentState.unreadCount,
      ),
    );

    try {
      final repo = ref.read(notificationsRepositoryProvider);
      await repo.deleteNotification(id);
    } catch (_) {
      // Rollback on failure
      ref.invalidateSelf();
    }
  }
}
