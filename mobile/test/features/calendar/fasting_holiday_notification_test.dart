import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/data/calendar_event_repository.dart';
import 'package:mobile/features/calendar/data/fasting_holiday_notification_service.dart';
import 'package:dio/dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Ethiopian Time Arithmetic Tests', () {
    test('Converts Gregorian morning 08:00 to Ethiopian ጧት 2:00', () {
      final time = EthiopianCalendarUtil.toEthiopianTime(8, 0);
      expect(time.hour, 2);
      expect(time.minute, 0);
      expect(time.periodAmharic, 'ጧት');
      expect(time.formatAmharic(), 'ጧት 2:00');
      expect(time.formatGregorian(), '8:00 AM');
      expect(time.formatDual(), 'ጧት 2:00 (8:00 AM)');
    });

    test('Converts Gregorian morning 11:30 to Ethiopian ጧት 5:30', () {
      final time = EthiopianCalendarUtil.toEthiopianTime(11, 30);
      expect(time.hour, 5);
      expect(time.minute, 30);
      expect(time.periodAmharic, 'ጧት');
      expect(time.formatAmharic(), 'ጧት 5:30');
      expect(time.formatGregorian(), '11:30 AM');
      expect(time.formatDual(), 'ጧት 5:30 (11:30 AM)');
    });

    test('Converts Gregorian noon 12:00 to Ethiopian ቀትር 6:00', () {
      final time = EthiopianCalendarUtil.toEthiopianTime(12, 0);
      expect(time.hour, 6);
      expect(time.minute, 0);
      expect(time.periodAmharic, 'ቀትር');
      expect(time.formatAmharic(), 'ቀትር 6:00');
      expect(time.formatGregorian(), '12:00 PM');
    });

    test('Converts Gregorian afternoon 14:15 to Ethiopian ከሰዓት 8:15', () {
      final time = EthiopianCalendarUtil.toEthiopianTime(14, 15);
      expect(time.hour, 8);
      expect(time.minute, 15);
      expect(time.periodAmharic, 'ከሰዓት');
      expect(time.formatAmharic(), 'ከሰዓት 8:15');
      expect(time.formatGregorian(), '2:15 PM');
    });

    test('Converts Gregorian evening 20:00 to Ethiopian ምሽት 2:00', () {
      final time = EthiopianCalendarUtil.toEthiopianTime(20, 0);
      expect(time.hour, 2);
      expect(time.minute, 0);
      expect(time.periodAmharic, 'ምሽት');
      expect(time.formatAmharic(), 'ምሽት 2:00');
      expect(time.formatGregorian(), '8:00 PM');
    });

    test('Converts Gregorian midnight 00:00 to Ethiopian እኩለ ሌሊት 6:00', () {
      final time = EthiopianCalendarUtil.toEthiopianTime(0, 0);
      expect(time.hour, 6);
      expect(time.minute, 0);
      expect(time.periodAmharic, 'እኩለ ሌሊት');
      expect(time.formatAmharic(), 'እኩለ ሌሊት 6:00');
      expect(time.formatGregorian(), '12:00 AM');
    });

    test('Converts Gregorian night 03:00 to Ethiopian ሌሊት 9:00', () {
      final time = EthiopianCalendarUtil.toEthiopianTime(3, 0);
      expect(time.hour, 9);
      expect(time.minute, 0);
      expect(time.periodAmharic, 'ሌሊት');
      expect(time.formatAmharic(), 'ሌሊት 9:00');
      expect(time.formatGregorian(), '3:00 AM');
    });

    test('Converts Gregorian dawn 06:00 to Ethiopian ጧት 12:00', () {
      final time = EthiopianCalendarUtil.toEthiopianTime(6, 0);
      expect(time.hour, 12);
      expect(time.minute, 0);
      expect(time.periodAmharic, 'ጧት');
      expect(time.formatAmharic(), 'ጧት 12:00');
      expect(time.formatGregorian(), '6:00 AM');
    });

    test('Reverses Ethiopian time back to Gregorian', () {
      final greg1 = EthiopianCalendarUtil.toGregorianTime(
        ethiopianHour: 2,
        ethiopianMinute: 0,
        period: 'ጧት',
      );
      expect(greg1.hour, 8);
      expect(greg1.minute, 0);

      final greg2 = EthiopianCalendarUtil.toGregorianTime(
        ethiopianHour: 5,
        ethiopianMinute: 30,
        period: 'ጧት',
      );
      expect(greg2.hour, 11);
      expect(greg2.minute, 30);

      final greg3 = EthiopianCalendarUtil.toGregorianTime(
        ethiopianHour: 8,
        ethiopianMinute: 0,
        period: 'ከሰዓት',
      );
      expect(greg3.hour, 14);
      expect(greg3.minute, 0);
    });
  });

  group('FastingHolidayNotificationService Preferences & Defaults Tests', () {
    test('Default notification state is OFF (false)', () async {
      final repo = CalendarEventRepository(Dio());
      final service = FastingHolidayNotificationService(repo);

      final isEnabled = await service.isEnabled();
      expect(isEnabled, isFalse);
    });

    test('Default times are 08:00 AM (ጧት 2:00) and 11:30 AM (ጧት 5:30)', () async {
      final repo = CalendarEventRepository(Dio());
      final service = FastingHolidayNotificationService(repo);

      final times = await service.getNotificationTimes();
      expect(times.time1.hour, 8);
      expect(times.time1.minute, 0);
      expect(times.time2.hour, 11);
      expect(times.time2.minute, 30);
    });

    test('Enabling and updating times persists to preferences', () async {
      final repo = CalendarEventRepository(Dio());
      final service = FastingHolidayNotificationService(repo);

      await service.setEnabled(true);
      expect(await service.isEnabled(), isTrue);

      await service.setNotificationTimes(
        time1: const TimeOfDay(hour: 7, minute: 30), // ጧት 1:30
        time2: const TimeOfDay(hour: 12, minute: 0), // ቀትር 6:00
      );

      final updatedTimes = await service.getNotificationTimes();
      expect(updatedTimes.time1.hour, 7);
      expect(updatedTimes.time1.minute, 30);
      expect(updatedTimes.time2.hour, 12);
      expect(updatedTimes.time2.minute, 0);

      await service.setEnabled(false);
      expect(await service.isEnabled(), isFalse);
    });
  });
}
