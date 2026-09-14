// lib/features/calendar/data/calendar_background_sync.dart
// Workmanager integration for background sync

import 'dart:developer' as developer;
import 'package:workmanager/workmanager.dart';
import 'package:mobile/features/calendar/data/calendar_sync_service.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/calendar/data/calendar_repository.dart';
import 'package:dio/dio.dart';

/// Unique task names for workmanager
class CalendarSyncTasks {
  static const String periodicSync = 'calendar_periodic_sync';
  static const String oneTimeSync = 'calendar_one_time_sync';
}

/// Background sync callback dispatcher
/// This runs in an isolated background thread
@pragma('vm:entry-point')
void calendarSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      developer.log(
        '🔄 Background sync task started: $task',
        name: 'BackgroundSync',
      );

      // Initialize dependencies in background isolate
      final db = AppDatabase();
      final dio = Dio(
        BaseOptions(
          baseUrl:
              inputData?['apiBaseUrl'] as String? ?? 'http://localhost:3000',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (inputData?['authToken'] != null)
              'Authorization': 'Bearer ${inputData!['authToken']}',
          },
        ),
      );

      final remoteRepo = CalendarRepository(dio);
      final offlineRepo = CalendarOfflineRepository(
        db.calendarNotesDao,
        db.syncQueueDao,
        remoteRepo,
      );

      final syncService = CalendarSyncService(offlineRepo);

      // Perform sync
      final success = await syncService.performSync();

      // Clean up
      await db.close();

      if (success) {
        developer.log('✅ Background sync completed', name: 'BackgroundSync');
        return true;
      } else {
        developer.log('⚠️ Background sync failed', name: 'BackgroundSync');
        return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Background sync error: $e',
        name: 'BackgroundSync',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  });
}

/// Background sync manager
class CalendarBackgroundSyncManager {
  static const String _taskName = CalendarSyncTasks.periodicSync;
  static const String _oneTimeTaskName = CalendarSyncTasks.oneTimeSync;

  /// Initialize background sync worker
  static Future<void> initialize({
    String? apiBaseUrl,
    String? authToken,
  }) async {
    developer.log('🚀 Initializing background sync', name: 'BackgroundSync');

    try {
      await Workmanager().initialize(calendarSyncCallbackDispatcher);

      developer.log('✅ Workmanager initialized', name: 'BackgroundSync');
    } catch (e) {
      developer.log('❌ Workmanager init failed: $e', name: 'BackgroundSync');
    }
  }

  /// Register periodic sync task (runs every 15 minutes)
  static Future<void> registerPeriodicSync({
    String? apiBaseUrl,
    String? authToken,
    Duration frequency = const Duration(minutes: 15),
  }) async {
    try {
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: frequency,
        constraints: Constraints(
          networkType: NetworkType.connected, // Require internet
          requiresBatteryNotLow: true, // Don't run on low battery
          requiresCharging: false, // Can run without charging
        ),
        inputData: {'apiBaseUrl': ?apiBaseUrl, 'authToken': ?authToken},
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

      developer.log(
        '✅ Periodic sync registered (every ${frequency.inMinutes} min)',
        name: 'BackgroundSync',
      );
    } catch (e) {
      developer.log(
        '❌ Failed to register periodic sync: $e',
        name: 'BackgroundSync',
      );
    }
  }

  /// Trigger one-time sync immediately
  static Future<void> triggerImmediateSync({
    String? apiBaseUrl,
    String? authToken,
  }) async {
    try {
      await Workmanager().registerOneOffTask(
        _oneTimeTaskName,
        _oneTimeTaskName,
        constraints: Constraints(networkType: NetworkType.connected),
        inputData: {'apiBaseUrl': ?apiBaseUrl, 'authToken': ?authToken},
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      developer.log('✅ One-time sync triggered', name: 'BackgroundSync');
    } catch (e) {
      developer.log(
        '❌ Failed to trigger one-time sync: $e',
        name: 'BackgroundSync',
      );
    }
  }

  /// Cancel all sync tasks
  static Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
      developer.log('✅ All sync tasks cancelled', name: 'BackgroundSync');
    } catch (e) {
      developer.log('❌ Failed to cancel tasks: $e', name: 'BackgroundSync');
    }
  }

  /// Cancel periodic sync only
  static Future<void> cancelPeriodicSync() async {
    try {
      await Workmanager().cancelByUniqueName(_taskName);
      developer.log('✅ Periodic sync cancelled', name: 'BackgroundSync');
    } catch (e) {
      developer.log(
        '❌ Failed to cancel periodic sync: $e',
        name: 'BackgroundSync',
      );
    }
  }

  /// Update sync configuration (e.g., after login/logout)
  static Future<void> updateSyncConfig({
    String? apiBaseUrl,
    String? authToken,
    Duration? frequency,
  }) async {
    await cancelPeriodicSync();
    await registerPeriodicSync(
      apiBaseUrl: apiBaseUrl,
      authToken: authToken,
      frequency: frequency ?? const Duration(minutes: 15),
    );
  }
}
