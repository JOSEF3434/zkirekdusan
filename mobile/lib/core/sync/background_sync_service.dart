// lib/core/sync/background_sync_service.dart
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

const String backgroundSyncTaskName = 'com.zikrekidusan.sync_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == backgroundSyncTaskName) {
        debugPrint('[BackgroundSyncService] Executing background sync task');
      }
      return await Future.value(true);
    } catch (e) {
      debugPrint('[BackgroundSyncService] Task failed: $e');
      return await Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await Workmanager().initialize(callbackDispatcher);

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
