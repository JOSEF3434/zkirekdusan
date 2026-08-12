import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/notifications/data/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/notification_model.dart';

class NotificationsState {
  final List<NotificationResponseDto> notifications;
  final int unreadCount;
  final bool isLoadingMore; // Future proofing if pagination is added
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
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsState>(() {
      return NotificationsNotifier();
    });

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  @override
  Future<NotificationsState> build() async {
    final repo = ref.read(notificationsRepositoryProvider);
    final notifications = await repo.getAll();
    final unreadCount = await repo.getUnreadCount();

    return NotificationsState(
      notifications: notifications,
      unreadCount: unreadCount,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final notifications = await repo.getAll();
      final unreadCount = await repo.getUnreadCount();

      state = AsyncValue.data(
        NotificationsState(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Optimistic update
    final updatedNotifications = currentState.notifications.map((n) {
      if (n.id == id && !n.isRead) {
        return n.copyWith(isRead: true);
      }
      return n;
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
    } catch (e) {
      // Ignore errors for mark-read or revert quietly
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
    } catch (e) {
      ref.invalidateSelf();
    }
  }

  Future<void> deleteNotification(String id) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final target = currentState.notifications.firstWhere((n) => n.id == id);
    final wasUnread = !target.isRead;

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
    } catch (e) {
      ref.invalidateSelf();
      rethrow;
    }
  }
}
