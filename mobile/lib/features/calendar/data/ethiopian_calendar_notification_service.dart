// lib/features/calendar/data/ethiopian_calendar_notification_service.dart
// Persistent Ethiopian Calendar notification for the Android notification shade and lock screen.
// Also supports daily date notifications on iOS.

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:abushakir/abushakir.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/navigation/navigation_service.dart';

class EthiopianCalendarNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int notificationId = 7701;
  static const String channelId = 'ethiopian_calendar_persistent';
  static const String prefsKey = 'ethiopian_calendar_notification_enabled';
  static const String taskName = 'ethiopian_calendar_notification_update';
  static const String _lastDisplayedDateKey = 'ethiopian_calendar_last_date';

  static bool _initialized = false;
  static bool _backgroundInitialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    'የኢትዮጵያ ቀን ማሳወቂያ',
    description: 'የዛሬውን የኢትዮጵያ ቀን በመቆለፊያ ገጽ እና በማሳወቂያ ቦታ ላይ ያሳያል',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  /// Initialize timezones and notification channel (foreground).
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
      } catch (_) {}

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _ensureChannel();
      _initialized = true;
      developer.log(
        '✅ Ethiopian Calendar Notification Service initialized',
        name: 'EthCalendarNotification',
      );
    } catch (e) {
      developer.log(
        '❌ Failed to initialize Ethiopian Calendar Notification: $e',
        name: 'EthCalendarNotification',
      );
    }
  }

  /// Headless / Background isolate initialization (safe, does not request UI permissions).
  static Future<void> initializeForBackground() async {
    if (_backgroundInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
      } catch (_) {}

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(initSettings);
      await _ensureChannel();
      _backgroundInitialized = true;
    } catch (e) {
      developer.log(
        '❌ Background init error: $e',
        name: 'EthCalendarNotification',
      );
    }
  }

  static Future<void> _ensureChannel() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
      }
    } catch (e) {
      developer.log('⚠️ Failed to create notification channel: $e', name: 'EthCalendarNotification');
    }
  }

  /// Main entrypoint on application start:
  /// Initializes, checks user preference (default true), and posts today's notification.
  static Future<void> initializeAndShow() async {
    if (kIsWeb) return;

    await initialize();

    final enabled = await isEnabled();
    if (!enabled) {
      await cancel();
      return;
    }

    final hasPermission = await checkOrRequestPermission();
    if (hasPermission) {
      await updateNotification(force: true);
    }
  }

  /// Returns the Android status bar small icon name for the given Ethiopian date
  /// (e.g. 'ic_cal_03_08' for Hidar 8). Renders the 2-digit day on top and the
  /// first 2 letters of the Ethiopian month below.
  static String getSmallIconName(int month, int day) {
    if (month >= 1 && month <= 13 && day >= 1 && day <= 30) {
      final mStr = month.toString().padLeft(2, '0');
      final dStr = day.toString().padLeft(2, '0');
      return 'ic_cal_${mStr}_$dStr';
    }
    return 'ic_stat_calendar';
  }

  /// Calculates the current Ethiopian date in Africa/Addis_Ababa timezone.
  static ({
    String title,
    String body,
    String expandedBody,
    String smallIcon,
    int etDay,
    int etMonth,
    int etYear,
  }) calculateTodayInfo() {
    tz.Location addis;
    try {
      addis = tz.getLocation('Africa/Addis_Ababa');
    } catch (_) {
      tz.initializeTimeZones();
      addis = tz.getLocation('Africa/Addis_Ababa');
    }

    final nowAddis = tz.TZDateTime.now(addis);
    // Anchor to UTC noon of the Addis Ababa calendar date to prevent UTC midnight
    // offset skew (abushakir interprets epoch milliseconds in UTC).
    final anchor = DateTime.utc(nowAddis.year, nowAddis.month, nowAddis.day, 12, 0);
    final etDate = EthiopianCalendarUtil.fromGregorian(anchor);
    final monthName = EthiopianCalendarUtil.getMonthName(etDate.month);
    final day = etDate.day;
    final year = etDate.year;

    // Weekday in Addis (1=Mon, 2=Tue, ..., 7=Sun)
    final weekdayName = EthiopianCalendarUtil.getWeekdayName(nowAddis.weekday);

    // Ge'ez numerals
    String geezDay = '$day';
    String geezYear = '$year';
    try {
      geezDay = ConvertToEthiopic(day) ?? '$day';
      geezYear = ConvertToEthiopic(year) ?? '$year';
    } catch (_) {}

    // Title: የዛሬ ቀን (Today's Date)
    const title = 'የዛሬ ቀን';

    // Body: Hidar 8 (ህዳር 8) — matching reference screenshot 2
    final body = '$monthName $day';

    // Expanded notification content for BigTextStyle (collapsed shows title + body)
    final expandedBody =
        '$weekdayName፣ $monthName $day ቀን $year ዓ.ም\n($geezDay $monthName $geezYear)';

    final smallIcon = getSmallIconName(etDate.month, day);

    return (
      title: title,
      body: body,
      expandedBody: expandedBody,
      smallIcon: smallIcon,
      etDay: day,
      etMonth: etDate.month,
      etYear: year,
    );
  }

  /// Shows or updates the persistent notification with today's Ethiopian date.
  /// Also schedules the next midnight rollover.
  static Future<void> updateNotification({bool force = false}) async {
    if (kIsWeb) return;

    final enabled = await isEnabled();
    if (!enabled) {
      await cancel();
      return;
    }

    try {
      final info = calculateTodayInfo();

      // Check if already displayed today and not forced
      final prefs = await SharedPreferences.getInstance();
      final dateKey = '${info.etYear}-${info.etMonth}-${info.etDay}';
      if (!force) {
        final lastDisplayed = prefs.getString(_lastDisplayedDateKey);
        if (lastDisplayed == dateKey) {
          // Already up to date for today
          return;
        }
      }

      final bigTextStyle = BigTextStyleInformation(
        info.expandedBody,
        contentTitle: info.title,
        summaryText: 'ዝክረ ክዱሳን',
        htmlFormatContentTitle: false,
        htmlFormatBigText: false,
      );

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'የኢትዮጵያ ቀን ማሳወቂያ',
        channelDescription: 'የዛሬውን የኢትዮጵያ ቀን በመቆለፊያ ገጽ እና በማሳወቂያ ቦታ ላይ ያሳያል',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // Persistent in notification shade on Android
        autoCancel: false,
        showWhen: false,
        visibility: NotificationVisibility.public, // Visible on lockscreen
        icon: info.smallIcon,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF1B5E20),
        category: AndroidNotificationCategory.status,
        styleInformation: bigTextStyle,
        playSound: false,
        enableVibration: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        categoryIdentifier: channelId,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 1. Post today's persistent notification
      await _notifications.show(
        notificationId,
        info.title,
        info.body,
        notificationDetails,
        payload: 'calendar',
      );

      await prefs.setString(_lastDisplayedDateKey, dateKey);
      developer.log(
        '📅 Posted persistent Ethiopian calendar notification: ${info.title} - ${info.body}',
        name: 'EthCalendarNotification',
      );

      // 2. Schedule automatic midnight update
      await _scheduleMidnightUpdate();
    } catch (e, st) {
      developer.log(
        '❌ Error posting Ethiopian calendar notification: $e',
        name: 'EthCalendarNotification',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Schedules the next automatic notification update at midnight Africa/Addis_Ababa time.
  static Future<void> _scheduleMidnightUpdate() async {
    try {
      final addis = tz.getLocation('Africa/Addis_Ababa');
      final nowAddis = tz.TZDateTime.now(addis);

      // Calculate next midnight + 5 seconds in Addis Ababa
      final nextMidnight = tz.TZDateTime(
        addis,
        nowAddis.year,
        nowAddis.month,
        nowAddis.day + 1,
        0,
        0,
        5,
      );

      developer.log(
        '⏰ Next midnight calendar update scheduled for: $nextMidnight (Addis Ababa)',
        name: 'EthCalendarNotification',
      );

      // We calculate tomorrow's date string ahead of time for exactAlarm
      final tomorrowGregorian = nextMidnight.add(const Duration(seconds: 10));
      final tomorrowAnchor = DateTime.utc(
        tomorrowGregorian.year,
        tomorrowGregorian.month,
        tomorrowGregorian.day,
        12,
        0,
      );
      final tomorrowEt = EthiopianCalendarUtil.fromGregorian(tomorrowAnchor);
      final monthName = EthiopianCalendarUtil.getMonthName(tomorrowEt.month);
      final day = tomorrowEt.day;
      final weekdayName =
          EthiopianCalendarUtil.getWeekdayName(tomorrowGregorian.weekday);

      String geezDay = '$day';
      String geezYear = '${tomorrowEt.year}';
      try {
        geezDay = ConvertToEthiopic(day) ?? '$day';
        geezYear = ConvertToEthiopic(tomorrowEt.year) ?? '${tomorrowEt.year}';
      } catch (_) {}

      final tomorrowBody = '$monthName $day';
      final tomorrowExpanded =
          '$weekdayName፣ $monthName $day ቀን ${tomorrowEt.year} ዓ.ም\n($geezDay $monthName $geezYear)';
      final tomorrowSmallIcon = getSmallIconName(tomorrowEt.month, day);

      final bigTextStyle = BigTextStyleInformation(
        tomorrowExpanded,
        contentTitle: 'የዛሬ ቀን',
        summaryText: 'ዝክረ ክዱሳን',
      );

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'የኢትዮጵያ ቀን ማሳወቂያ',
        channelDescription: 'የዛሬውን የኢትዮጵያ ቀን በመቆለፊያ ገጽ እና በማሳወቂያ ቦታ ላይ ያሳያል',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        visibility: NotificationVisibility.public,
        icon: tomorrowSmallIcon,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF1B5E20),
        category: AndroidNotificationCategory.status,
        styleInformation: bigTextStyle,
        playSound: false,
        enableVibration: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        categoryIdentifier: channelId,
      );

      await _notifications.zonedSchedule(
        notificationId,
        'የዛሬ ቀን',
        tomorrowBody,
        nextMidnight,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'calendar',
      );
    } catch (e) {
      developer.log(
        '⚠️ Failed to schedule midnight update: $e',
        name: 'EthCalendarNotification',
      );
    }
  }

  /// Safe update invoked by WorkManager in background.
  static Future<bool> updateFromBackground() async {
    if (kIsWeb) return true;

    try {
      await initializeForBackground();

      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(prefsKey) ?? true;
      if (!enabled) return true;

      final info = calculateTodayInfo();

      final bigTextStyle = BigTextStyleInformation(
        info.expandedBody,
        contentTitle: info.title,
        summaryText: 'ዝክረ ክዱሳን',
      );

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'የኢትዮጵያ ቀን ማሳወቂያ',
        channelDescription: 'የዛሬውን የኢትዮጵያ ቀን በመቆለፊያ ገጽ እና በማሳወቂያ ቦታ ላይ ያሳያል',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        visibility: NotificationVisibility.public,
        icon: info.smallIcon,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF1B5E20),
        category: AndroidNotificationCategory.status,
        styleInformation: bigTextStyle,
        playSound: false,
        enableVibration: false,
      );

      await _notifications.show(
        notificationId,
        info.title,
        info.body,
        NotificationDetails(android: androidDetails),
        payload: 'calendar',
      );

      final dateKey = '${info.etYear}-${info.etMonth}-${info.etDay}';
      await prefs.setString(_lastDisplayedDateKey, dateKey);

      developer.log(
        '✅ Background calendar notification updated: ${info.body}',
        name: 'EthCalendarNotification',
      );
      return true;
    } catch (e) {
      developer.log(
        '❌ Failed background calendar update: $e',
        name: 'EthCalendarNotification',
      );
      return false;
    }
  }

  /// Check on app resume: If the date has rolled over while app was in background,
  /// immediately refresh the persistent notification.
  static Future<void> updateIfDateChanged() async {
    if (kIsWeb) return;
    try {
      final enabled = await isEnabled();
      if (!enabled) return;

      final info = calculateTodayInfo();
      final prefs = await SharedPreferences.getInstance();
      final lastDisplayed = prefs.getString(_lastDisplayedDateKey);
      final currentKey = '${info.etYear}-${info.etMonth}-${info.etDay}';

      if (lastDisplayed != currentKey) {
        await updateNotification(force: true);
      }
    } catch (_) {}
  }

  /// Cancel the persistent calendar notification.
  static Future<void> cancel() async {
    try {
      await _notifications.cancel(notificationId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastDisplayedDateKey);
      developer.log('🚫 Cancelled Ethiopian calendar notification', name: 'EthCalendarNotification');
    } catch (e) {
      developer.log('⚠️ Error cancelling calendar notification: $e', name: 'EthCalendarNotification');
    }
  }

  /// Enable or disable the notification preference.
  static Future<bool> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, enabled);

    if (enabled) {
      final granted = await checkOrRequestPermission();
      if (granted) {
        await updateNotification(force: true);
        return true;
      }
      return false;
    } else {
      await cancel();
      return true;
    }
  }

  /// Returns whether the persistent notification is enabled (default: true).
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? true;
  }

  /// Checks or requests notification permissions across Android and iOS.
  static Future<bool> checkOrRequestPermission() async {
    if (kIsWeb) return false;

    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted == true) return true;
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: false,
          sound: false,
        );
        if (granted == true) return true;
      }

      // Check with permission_handler
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (status.isDenied) {
        final req = await Permission.notification.request();
        return req.isGranted;
      }
      return false;
    } catch (e) {
      developer.log('⚠️ Permission request error: $e', name: 'EthCalendarNotification');
      return false;
    }
  }

  /// Opens the system app settings if notification permission was permanently denied.
  static Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  /// Handles notification tap — navigates directly to the Calendar tab.
  static void _onNotificationTapped(NotificationResponse response) {
    developer.log(
      '📱 Calendar notification tapped: id=${response.id}, payload=${response.payload}',
      name: 'EthCalendarNotification',
    );

    if (response.id == notificationId || response.payload == 'calendar') {
      NavigationService.instance.goTo('/calendar');
    }
  }
}
