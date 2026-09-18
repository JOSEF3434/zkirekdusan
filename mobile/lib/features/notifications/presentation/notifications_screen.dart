// lib/features/notifications/presentation/notifications_screen.dart
// Upgraded notification center: skeleton, empty state, error/retry, type icons,
// deep-link navigation via resolver, responsive layout, optimistic updates.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/notifications/core/notification_navigation_resolver.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:mobile/features/notifications/presentation/widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('notifications.title')),
        actions: [
          notificationsAsync.when(
            data: (state) => state.unreadCount > 0
                ? IconButton(
                    icon: const Icon(Icons.done_all_rounded),
                    tooltip: tr('notifications.mark_all_read'),
                    onPressed: () => ref
                        .read(notificationsProvider.notifier)
                        .markAllAsRead(),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.isDesktop(context)
                ? 700
                : double.infinity,
          ),
          child: notificationsAsync.when(
            loading: () => const NotificationSkeleton(),
            error: (e, _) => _ErrorState(
              error: e.toString(),
              onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
            ),
            data: (state) {
              if (state.notifications.isEmpty) {
                return _EmptyState();
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: ListView.separated(
                  itemCount: state.notifications.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return NotificationTile(
                      notification: notification,
                      onTap: () {
                        if (!notification.isRead) {
                          ref
                              .read(notificationsProvider.notifier)
                              .markAsRead(notification.id);
                        }
                        NotificationNavigationResolver.navigate(
                          context,
                          notification,
                        );
                      },
                      onDismiss: () {
                        ref
                            .read(notificationsProvider.notifier)
                            .deleteNotification(notification.id);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              tr('notifications.caught_up'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              tr('notifications.new_appear'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends ConsumerWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              tr('notifications.load_failed'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr('notifications.load_failed_desc'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
