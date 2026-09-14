// lib/features/calendar/data/calendar_notifications_service.dart
// Local notifications service for calendar reminders

import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/domain/calendar_reminder_schedule.dart';

final calendarNotificationsServiceProvider =
    Provider<CalendarNotificationsService>((ref) {
      return CalendarNotificationsService();
    });

class CalendarNotificationsService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize local notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));

      // Android initialization
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      _initialized = true;
      developer.log(
        '✅ Calendar notifications initialized',
        name: 'CalendarNotifications',
      );
    } catch (e) {
      developer.log(
        '❌ Failed to initialize notifications: $e',
        name: 'CalendarNotifications',
      );
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Android 13+ runtime permission
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    // iOS permission
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Schedule a notification for a calendar note reminder
  Future<void> scheduleReminder(CalendarNoteModel note) async {
    if (!note.hasReminder) {
      developer.log(
        '⚠️ Note has no reminder or datetime',
        name: 'CalendarNotifications',
      );
      return;
    }

    try {
      final schedule = CalendarReminderSchedule.nextForNote(note);
      if (schedule == null) {
        developer.log(
          '⚠️ Reminder time is in the past',
          name: 'CalendarNotifications',
        );
        return;
      }
      final reminderTime = schedule.notificationGregorian;

      final notificationId = note.id.hashCode & 0x7fffffff;

      // Notification details
      const androidDetails = AndroidNotificationDetails(
        'calendar_reminders',
        'Calendar Reminders',
        channelDescription: 'Reminders for calendar notes',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.aiff',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        note.title ?? 'Calendar Reminder',
        note.content ??
            'Tomorrow: ${schedule.event.day} ${schedule.event.month}/${schedule.event.year}',
        tz.TZDateTime.from(reminderTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: note.id,
      );

      developer.log(
        '✅ Reminder scheduled for ${reminderTime.toIso8601String()}',
        name: 'CalendarNotifications',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to schedule reminder: $e',
        name: 'CalendarNotifications',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Cancel a scheduled reminder
  Future<void> cancelReminder(String noteId) async {
    try {
      final notificationId = noteId.hashCode & 0x7fffffff;
      await _notifications.cancel(notificationId);
      developer.log(
        '✅ Reminder cancelled for note $noteId',
        name: 'CalendarNotifications',
      );
    } catch (e) {
      developer.log(
        '❌ Failed to cancel reminder: $e',
        name: 'CalendarNotifications',
      );
    }
  }

  /// Cancel all reminders
  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
      developer.log('✅ All reminders cancelled', name: 'CalendarNotifications');
    } catch (e) {
      developer.log(
        '❌ Failed to cancel all reminders: $e',
        name: 'CalendarNotifications',
      );
    }
  }

  /// Show immediate notification (for testing or immediate alerts)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'calendar_reminders',
      'Calendar Reminders',
      channelDescription: 'Reminders for calendar notes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    developer.log(
      '📱 Notification tapped: payload=${response.payload}',
      name: 'CalendarNotifications',
    );

    // TODO: Navigate to calendar note detail screen
    // This would require access to navigation context
    // For now, just log the event
  }
}
