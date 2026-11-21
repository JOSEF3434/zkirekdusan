// lib/features/calendar/data/fasting_holiday_notification_service.dart
// Dedicated service for scheduling and managing Ethiopian Orthodox Fasting and Holiday notifications.

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/data/calendar_event_repository.dart';

final fastingHolidayNotificationServiceProvider =
    Provider<FastingHolidayNotificationService>((ref) {
      final eventRepo = ref.watch(calendarEventRepositoryProvider);
      return FastingHolidayNotificationService(eventRepo);
    });

class FastingHolidayNotificationService {
  final CalendarEventRepository _eventRepository;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Keys for SharedPreferences
  static const String keyEnabled = 'fasting_holiday_notif_enabled';
  static const String keyTime1Hour = 'fasting_holiday_time_1_hour';
  static const String keyTime1Minute = 'fasting_holiday_time_1_minute';
  static const String keyTime2Hour = 'fasting_holiday_time_2_hour';
  static const String keyTime2Minute = 'fasting_holiday_time_2_minute';

  // Default times:
  // 1. Ethiopian 2:00 morning = 08:00 AM Gregorian
  // 2. Ethiopian 5:30 morning = 11:30 AM Gregorian
  static const int defaultTime1Hour = 8;
  static const int defaultTime1Minute = 0;
  static const int defaultTime2Hour = 11;
  static const int defaultTime2Minute = 30;

  static const String channelId = 'fasting_holiday_reminders';
  static const String channelName = 'Fasting & Holiday Reminders';
  static const String channelDesc =
      'Daily morning notifications for Ethiopian Orthodox fasts and feast days';

  static const int notifIdBase = 88000;
  static const int notifIdRange = 100;

  static bool _timezoneInitialized = false;

  FastingHolidayNotificationService(this._eventRepository);

  /// Ensure timezone database is initialized
  static void _ensureTimezones() {
    if (!_timezoneInitialized) {
      try {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
        _timezoneInitialized = true;
      } catch (e) {
        developer.log('Timezone init error: $e', name: 'FastingHolidayNotification');
      }
    }
  }

  /// Ensure Android notification channel exists
  static Future<void> _ensureChannel() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    } catch (e) {
      developer.log('Error creating channel: $e', name: 'FastingHolidayNotification');
    }
  }

  /// Checks if fasting and holiday notifications are enabled (default: false / OFF).
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyEnabled) ?? false;
  }

  /// Sets whether fasting and holiday notifications are enabled.
  /// If enabled, schedules notifications; if disabled, cancels them.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyEnabled, enabled);

    if (enabled) {
      await scheduleUpcomingNotifications();
    } else {
      await cancelAllFastingHolidayNotifications();
    }
  }

  /// Gets the configured notification times.
  /// Defaults:
  /// - Time 1: 08:00 AM (Ethiopian ጧት 2:00)
  /// - Time 2: 11:30 AM (Ethiopian ጧት 5:30)
  Future<({TimeOfDay time1, TimeOfDay time2})> getNotificationTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final h1 = prefs.getInt(keyTime1Hour) ?? defaultTime1Hour;
    final m1 = prefs.getInt(keyTime1Minute) ?? defaultTime1Minute;
    final h2 = prefs.getInt(keyTime2Hour) ?? defaultTime2Hour;
    final m2 = prefs.getInt(keyTime2Minute) ?? defaultTime2Minute;

    return (
      time1: TimeOfDay(hour: h1, minute: m1),
      time2: TimeOfDay(hour: h2, minute: m2),
    );
  }

  /// Sets notification times and reschedules if notifications are enabled.
  Future<void> setNotificationTimes({TimeOfDay? time1, TimeOfDay? time2}) async {
    final prefs = await SharedPreferences.getInstance();
    if (time1 != null) {
      await prefs.setInt(keyTime1Hour, time1.hour);
      await prefs.setInt(keyTime1Minute, time1.minute);
    }
    if (time2 != null) {
      await prefs.setInt(keyTime2Hour, time2.hour);
      await prefs.setInt(keyTime2Minute, time2.minute);
    }

    final enabled = prefs.getBool(keyEnabled) ?? false;
    if (enabled) {
      await scheduleUpcomingNotifications();
    }
  }

  /// Schedules daily notifications for the upcoming 30 days.
  /// Only schedules for days that actually have a fasting observance or a holiday!
  Future<void> scheduleUpcomingNotifications() async {
    _ensureTimezones();
    await _ensureChannel();

    // First cancel all previous scheduled fasting & holiday notifications
    await cancelAllFastingHolidayNotifications();

    final times = await getNotificationTimes();
    final now = DateTime.now();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    int scheduledCount = 0;

    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final etDate = EthiopianCalendarUtil.fromGregorian(targetDate);

      // Fetch month events (offline-safe)
      final monthEvents = await _eventRepository.getEventsForMonth(
        etDate.year,
        etDate.month,
      );

      // Check for active fasts and holidays on this specific date
      final dayEvents = monthEvents.where((e) {
        return e.appliesToDay(etDate.day);
      }).toList();

      // Also check Wednesday & Friday fast
      final isWedFri = EthiopianCalendarUtil.isWednesdayFridayFastingDay(
        etDate.year,
        etDate.month,
        etDate.day,
      );

      final fasts = dayEvents.where((e) => e.isFast).toList();
      final holidays = dayEvents.where((e) => e.isHoliday).toList();

      final hasFast = fasts.isNotEmpty || isWedFri;
      final hasHoliday = holidays.isNotEmpty;

      // Only schedule if this day has a fast or holiday!
      if (!hasFast && !hasHoliday) continue;

      // Construct notification title and body
      final dateString =
          '${EthiopianCalendarUtil.getMonthName(etDate.month)} ${etDate.day}';

      String title;
      String body;

      if (hasFast && hasHoliday) {
        final holidayName = holidays.first.name;
        final fastName = fasts.isNotEmpty ? fasts.first.name : 'ጾመ ድኅነት (ረቡዕ/ዓርብ)';
        title = 'የዕለቱ ጾም እና በዓል • $dateString';
        body = '$holidayName — $fastName። የበረከት ቀን ይሁንልን!';
      } else if (hasFast) {
        final fastName = fasts.isNotEmpty ? fasts.first.name : 'ጾመ ድኅነት';
        title = 'የጾም ቀን • $dateString';
        final desc = fasts.isNotEmpty && fasts.first.description != null
            ? fasts.first.description!
            : 'ዛሬ የጾም ቀን ነው። በጸሎት እና በምጽዋት እንበርታ።';
        body = '$fastName — $desc';
      } else {
        final holidayName = holidays.first.name;
        title = 'የበዓል ቀን • $dateString';
        final desc = holidays.first.description ?? 'እንኳን አደረሳችሁ!';
        body = '$holidayName — $desc';
      }

      // 1. Time 1 (e.g. 08:00 AM / ጧት 2:00)
      final targetDt1 = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        times.time1.hour,
        times.time1.minute,
      );

      if (targetDt1.isAfter(now)) {
        final id1 = notifIdBase + (dayOffset * 2);
        try {
          await _notifications.zonedSchedule(
            id1,
            title,
            body,
            tz.TZDateTime.from(targetDt1, tz.local),
            notifDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'calendar',
          );
          scheduledCount++;
        } catch (e) {
          developer.log('Failed to schedule Time 1 for day $dayOffset: $e');
        }
      }

      // 2. Time 2 (e.g. 11:30 AM / ጧት 5:30)
      final targetDt2 = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        times.time2.hour,
        times.time2.minute,
      );

      if (targetDt2.isAfter(now)) {
        final id2 = notifIdBase + (dayOffset * 2) + 1;
        try {
          await _notifications.zonedSchedule(
            id2,
            title,
            body,
            tz.TZDateTime.from(targetDt2, tz.local),
            notifDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'calendar',
          );
          scheduledCount++;
        } catch (e) {
          developer.log('Failed to schedule Time 2 for day $dayOffset: $e');
        }
      }
    }

    developer.log(
      '✅ Fasting & Holiday notifications scheduled: $scheduledCount alerts over 30 days',
      name: 'FastingHolidayNotification',
    );
  }

  /// Cancels all scheduled fasting and holiday notifications.
  Future<void> cancelAllFastingHolidayNotifications() async {
    for (int i = 0; i < notifIdRange; i++) {
      try {
        await _notifications.cancel(notifIdBase + i);
      } catch (_) {}
    }
    developer.log('✅ Cancelled all fasting/holiday notifications', name: 'FastingHolidayNotification');
  }

  /// Shows an immediate test notification for user preview.
  Future<void> showTestNotification() async {
    await _ensureChannel();
    final etDate = EthiopianCalendarUtil.now();
    final dateString =
        '${EthiopianCalendarUtil.getMonthName(etDate.month)} ${etDate.day}';

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notifIdBase + 99,
      'የአጽዋማት እና የበዓላት ማሳወቂያ • $dateString',
      'የማሳወቂያ አገልግሎቱ በትክክል እየሰራ ነው። በጾም እና በበዓል ቀናት ጠዋት 2:00 እና 5:30 ማሳወቂያ ይደርስዎታል።',
      notifDetails,
      payload: 'calendar',
    );
  }
}
