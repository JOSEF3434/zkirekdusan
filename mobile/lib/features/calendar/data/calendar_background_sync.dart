// lib/features/calendar/data/calendar_background_sync.dart
// Workmanager integration for background sync

import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/app/env/env.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/calendar/data/calendar_sync_service.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';
import 'package:mobile/features/calendar/data/calendar_repository.dart';
import 'package:dio/dio.dart';

/// Unique task names for workmanager
class CalendarSyncTasks {
  static const String periodicSync = 'calendar_periodic_sync';
  static const String oneTimeSync = 'calendar_one_time_sync';
}

/// Core calendar background sync task execution logic.
Future<bool> executeCalendarSyncTask(Map<String, dynamic>? inputData) async {
  try {
    developer.log(
      '🔄 Background sync task executing',
      name: 'BackgroundSync',
    );

    // Initialize dependencies in background isolate
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage(aOptions: AndroidOptions());
    final storage = StorageService(secureStorage, prefs);
    final db = AppDatabase();

    final baseUrl = inputData?['apiBaseUrl'] as String? ?? Env.apiBaseUrl;
    var accessToken = await storage.getToken(key: 'access_token') ??
        inputData?['authToken'] as String?;
    final refreshToken = await storage.getToken(key: 'refresh_token');

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    // Silent token refresh interceptor for background execution
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (err, handler) async {
          if (err.response?.statusCode == 401 &&
              refreshToken != null &&
              refreshToken.isNotEmpty) {
            developer.log(
              '🔄 Background sync received 401: attempting silent refresh',
              name: 'BackgroundSync',
            );
            try {
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: baseUrl,
                  connectTimeout: const Duration(seconds: 30),
                  receiveTimeout: const Duration(seconds: 30),
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ),
              );
              final refreshResponse = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );
              final data = refreshResponse.data;
              final Map<String, dynamic> body =
                  (data is Map && data.containsKey('data'))
                      ? data['data'] as Map<String, dynamic>
                      : data as Map<String, dynamic>;
              final newAccessToken = body['accessToken'] as String?;
              final newRefreshToken = body['refreshToken'] as String?;

              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                await storage.saveToken(newAccessToken, key: 'access_token');
                if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                  await storage.saveToken(
                    newRefreshToken,
                    key: 'refresh_token',
                  );
                }
                dio.options.headers['Authorization'] =
                    'Bearer $newAccessToken';

                // Retry original request
                final retryOpts = Options(
                  method: err.requestOptions.method,
                  headers: {
                    ...err.requestOptions.headers,
                    'Authorization': 'Bearer $newAccessToken',
                  },
                );
                final retryResponse = await dio.request<dynamic>(
                  err.requestOptions.path,
                  data: err.requestOptions.data,
                  queryParameters: err.requestOptions.queryParameters,
                  options: retryOpts,
                );
                return handler.resolve(retryResponse);
              }
            } catch (refreshErr) {
              developer.log(
                '❌ Background silent refresh failed: $refreshErr',
                name: 'BackgroundSync',
              );
            }
          }
          return handler.next(err);
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
    final result = await syncService.performSync();
    final success = result.isSuccess;

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
}

/// Background sync callback dispatcher (for backward compatibility if invoked directly)
/// This runs in an isolated background thread
@pragma('vm:entry-point')
void calendarSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return await executeCalendarSyncTask(inputData);
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
    developer.log('✅ Calendar background sync ready', name: 'BackgroundSync');
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
