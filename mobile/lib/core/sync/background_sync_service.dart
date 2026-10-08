import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/features/calendar/data/calendar_background_sync.dart';
import 'package:mobile/features/calendar/data/calendar_reminder_worker.dart';

const String backgroundSyncTaskName = 'com.zikrekidusan.sync_task';

/// Unified top-level callback dispatcher for all WorkManager background tasks.
/// Android WorkManager registers a single callback dispatcher entrypoint.
/// All periodic and one-off background tasks are routed deterministically here.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      developer.log(
        '🔄 Workmanager dispatcher executing task: $task',
        name: 'BackgroundSync',
      );

      if (task == CalendarReminderTasks.checkReminders ||
          task == '${CalendarReminderTasks.checkReminders}_oneoff') {
        return await executeCalendarReminderTask();
      } else if (task == CalendarSyncTasks.periodicSync ||
          task == CalendarSyncTasks.oneTimeSync) {
        return await executeCalendarSyncTask(inputData);
      } else if (task == backgroundSyncTaskName ||
          task == 'zikre_periodic_sync') {
        debugPrint('[BackgroundSyncService] Executing generic sync task');
        return true;
      }

      developer.log(
        '⚠️ Unrecognized background task: $task — completing cleanly',
        name: 'BackgroundSync',
      );
      return true;
    } catch (e, st) {
      developer.log(
        '❌ Background task failed: $e',
        name: 'BackgroundSync',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  });
}

class BackgroundSyncService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    try {
      await Workmanager().initialize(callbackDispatcher);
      _initialized = true;

      // Register periodic task every 15 minutes (minimum allowed by Android OS)
      // Only executes when device has active network connection
      await Workmanager().registerPeriodicTask(
        'zikre_periodic_sync',
        backgroundSyncTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('[BackgroundSyncService] Workmanager init warning: $e');
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelAll();
    } catch (_) {}
  }
}
