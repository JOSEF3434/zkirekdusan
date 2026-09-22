// lib/features/live/presentation/services/live_notification_service.dart
// Schedules multi-interval reminders for scheduled live streams (1 day, 5h, 1h, 30m, and start)

import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:mobile/features/live/domain/live_stream_model.dart';

final liveNotificationServiceProvider = Provider<LiveNotificationService>((ref) {
  return LiveNotificationService();
});

final liveRemindersStateProvider =
    StateNotifierProvider<LiveRemindersNotifier, Set<String>>((ref) {
      final service = ref.watch(liveNotificationServiceProvider);
      return LiveRemindersNotifier(service);
    });

class LiveRemindersNotifier extends StateNotifier<Set<String>> {
  final LiveNotificationService _service;

  LiveRemindersNotifier(this._service) : super({}) {
    _load();
  }

  Future<void> _load() async {
    final ids = await _service.getSavedReminderStreamIds();
    state = ids;
  }

  Future<bool> toggle(LiveStreamDto stream) async {
    final isSet = state.contains(stream.id);
    if (isSet) {
      await _service.cancelStreamReminders(stream.id);
      state = {...state}..remove(stream.id);
      return false;
    } else {
      await _service.scheduleStreamReminders(stream);
      state = {...state, stream.id};
      return true;
    }
  }

  bool hasReminder(String streamId) => state.contains(streamId);
}

class LiveNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const String _prefsKey = 'live_stream_reminders_set';

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
      } catch (_) {}

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
      }

      _initialized = true;
      developer.log('✅ Live notification service initialized', name: 'LiveNotifications');
    } catch (e) {
      developer.log('❌ Failed to initialize live notifications: $e', name: 'LiveNotifications');
    }
  }

  /// Schedule reminders for a stream at intervals:
  /// - 1 day before (24 hours)
  /// - 5 hours before
  /// - 1 hour before
  /// - 30 minutes before
  /// - At stream start time
  Future<void> scheduleStreamReminders(LiveStreamDto stream) async {
    await initialize();

    if (stream.scheduledAt == null) return;
    final scheduledDate = DateTime.tryParse(stream.scheduledAt!);
    if (scheduledDate == null) return;

    final now = DateTime.now();
    final channelName = stream.videoChannel?.name ?? 'Live Stream';
    final baseId = (stream.id.hashCode & 0x7FFFFFFF) % 100000;

    const androidDetails = AndroidNotificationDetails(
      'live_stream_reminders',
      'Live Stream Reminders',
      channelDescription: 'Notifications for upcoming scheduled live streams',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // List of reminder intervals: (Duration before start, label, unique sub-id)
    final intervals = [
      (const Duration(hours: 24), 'Starting tomorrow (in 24 hours)', 1),
      (const Duration(hours: 5), 'Starting in 5 hours', 2),
      (const Duration(hours: 1), 'Starting in 1 hour', 3),
      (const Duration(minutes: 30), 'Starting in 30 minutes', 4),
      (Duration.zero, 'Is LIVE NOW! Tap to join', 5),
    ];

    for (final (offset, label, subId) in intervals) {
      final reminderTime = scheduledDate.subtract(offset);
      if (reminderTime.isAfter(now)) {
        try {
          await _notifications.zonedSchedule(
            baseId + subId,
            '🔴 $channelName Live Reminder',
            '${stream.title} • $label',
            tz.TZDateTime.from(reminderTime, tz.local),
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: stream.id,
          );
          developer.log(
            'Scheduled reminder for stream ${stream.id} ($label) at $reminderTime',
            name: 'LiveNotifications',
          );
        } catch (e) {
          developer.log('Error scheduling notification: $e', name: 'LiveNotifications');
        }
      }
    }

    // Save stream id to preferences
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    if (!list.contains(stream.id)) {
      list.add(stream.id);
      await prefs.setStringList(_prefsKey, list);
    }
  }

  /// Cancel all scheduled reminders for a stream
  Future<void> cancelStreamReminders(String streamId) async {
    final baseId = (streamId.hashCode & 0x7FFFFFFF) % 100000;
    for (int i = 1; i <= 5; i++) {
      await _notifications.cancel(baseId + i);
    }

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    list.remove(streamId);
    await prefs.setStringList(_prefsKey, list);
  }

  /// Load persisted stream IDs with active reminders
  Future<Set<String>> getSavedReminderStreamIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    return list.toSet();
  }
}
