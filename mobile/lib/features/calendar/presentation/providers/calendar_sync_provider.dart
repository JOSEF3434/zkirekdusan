// lib/features/calendar/presentation/providers/calendar_sync_provider.dart
// Providers for sync status and manual sync triggers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/data/calendar_sync_service.dart';
import 'package:mobile/features/calendar/data/calendar_background_sync.dart';
import 'package:mobile/core/providers/database_provider.dart';

/// Provider for last sync timestamp
final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for sync in progress status
final syncInProgressProvider = StateProvider<bool>((ref) => false);

/// Provider for manual sync trigger
final manualSyncProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final syncService = ref.read(calendarSyncServiceProvider);
    final syncInProgress = ref.read(syncInProgressProvider.notifier);
    final lastSyncTime = ref.read(lastSyncTimeProvider.notifier);

    try {
      syncInProgress.state = true;
      final success = await syncService.performSync();

      if (success) {
        lastSyncTime.state = DateTime.now();
      }

      return success;
    } finally {
      syncInProgress.state = false;
    }
  };
});

/// Provider for quick sync trigger (current month only)
final quickSyncProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final syncService = ref.read(calendarSyncServiceProvider);
    final syncInProgress = ref.read(syncInProgressProvider.notifier);
    final lastSyncTime = ref.read(lastSyncTimeProvider.notifier);

    try {
      syncInProgress.state = true;
      final success = await syncService.performQuickSync();

      if (success) {
        lastSyncTime.state = DateTime.now();
      }

      return success;
    } finally {
      syncInProgress.state = false;
    }
  };
});

/// Provider for pending sync count
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.syncQueueDao.getPendingCount();
});

/// Stream provider for watching pending sync count
final pendingSyncCountStreamProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.syncQueueDao.watchPendingCount();
});

/// Provider for background sync initialization
final initializeBackgroundSyncProvider =
    Provider<
      Future<void> Function({
        String? apiBaseUrl,
        String? authToken,
        Duration? frequency,
      })
    >((ref) {
      return ({apiBaseUrl, authToken, frequency}) async {
        await CalendarBackgroundSyncManager.initialize(
          apiBaseUrl: apiBaseUrl,
          authToken: authToken,
        );

        await CalendarBackgroundSyncManager.registerPeriodicSync(
          apiBaseUrl: apiBaseUrl,
          authToken: authToken,
          frequency: frequency ?? const Duration(minutes: 15),
        );
      };
    });

/// Provider for triggering immediate background sync
final triggerImmediateSyncProvider =
    Provider<Future<void> Function({String? apiBaseUrl, String? authToken})>((
      ref,
    ) {
      return ({apiBaseUrl, authToken}) async {
        await CalendarBackgroundSyncManager.triggerImmediateSync(
          apiBaseUrl: apiBaseUrl,
          authToken: authToken,
        );
      };
    });

/// Provider for cancelling background sync
final cancelBackgroundSyncProvider = Provider<Future<void> Function()>((ref) {
  return () => CalendarBackgroundSyncManager.cancelAll();
});

/// Provider for updating sync configuration
final updateSyncConfigProvider =
    Provider<
      Future<void> Function({
        String? apiBaseUrl,
        String? authToken,
        Duration? frequency,
      })
    >((ref) {
      return ({apiBaseUrl, authToken, frequency}) async {
        await CalendarBackgroundSyncManager.updateSyncConfig(
          apiBaseUrl: apiBaseUrl,
          authToken: authToken,
          frequency: frequency,
        );
      };
    });
