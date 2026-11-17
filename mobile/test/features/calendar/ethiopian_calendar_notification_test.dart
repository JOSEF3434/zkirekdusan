import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/data/ethiopian_calendar_notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('EthiopianCalendarNotificationService Tests', () {
    test('calculateTodayInfo returns valid non-empty fields in Addis Ababa timezone', () {
      final info = EthiopianCalendarNotificationService.calculateTodayInfo();

      expect(info.title, 'የዛሬ ቀን');
      expect(info.body, isNotEmpty);
      expect(info.expandedBody, isNotEmpty);
      expect(info.etDay, greaterThanOrEqualTo(1));
      expect(info.etDay, lessThanOrEqualTo(30));
      expect(info.etMonth, greaterThanOrEqualTo(1));
      expect(info.etMonth, lessThanOrEqualTo(13));
      expect(info.etYear, greaterThanOrEqualTo(2016));

      // Notification body should contain the month name and day number (e.g. 'ኅዳር 8' or 'ጥቅምት 8')
      final monthName = EthiopianCalendarUtil.getMonthName(info.etMonth);
      expect(info.body, contains(monthName));
      expect(info.body, contains('${info.etDay}'));

      // Expanded body should contain the Ethiopian year and Ge'ez notation
      expect(info.expandedBody, contains('ዓ.ም'));
      expect(info.expandedBody, contains(monthName));

      // Small icon should be formatted with 2-digit month and day (e.g. 'ic_cal_03_08')
      expect(info.smallIcon, matches(RegExp(r'^ic_cal_\d{2}_\d{2}$')));
    });

    test('getSmallIconName formats 2-digit month and day correctly', () {
      expect(
        EthiopianCalendarNotificationService.getSmallIconName(3, 8),
        'ic_cal_03_08',
      );
      expect(
        EthiopianCalendarNotificationService.getSmallIconName(1, 1),
        'ic_cal_01_01',
      );
      expect(
        EthiopianCalendarNotificationService.getSmallIconName(13, 6),
        'ic_cal_13_06',
      );
      expect(
        EthiopianCalendarNotificationService.getSmallIconName(0, 0),
        'ic_stat_calendar',
      );
    });

    test('EthiopianCalendarUtil converts specific dates accurately', () {
      // November 17, 2026 Gregorian is Hidar 8, 2019 Ethiopian (as seen in user screenshot!)
      final nov17_2026 = DateTime.utc(2026, 11, 17, 12, 0);
      final etDate = EthiopianCalendarUtil.fromGregorian(nov17_2026);

      expect(etDate.year, 2019);
      expect(etDate.month, 3); // 3 = Hidar / ኅዳር
      expect(etDate.day, 8);
      expect(EthiopianCalendarUtil.getMonthName(3), 'ኅዳር');
    });

    test('Handles 13th month (Pagume) and leap years correctly', () {
      // 2015 was an Ethiopian leap year (Pagume had 6 days)
      // Gregorian 2023-09-11 12:00 was Pagume 6, 2015
      final pagume6 = DateTime.utc(2023, 9, 11, 12, 0);
      final etPagume6 = EthiopianCalendarUtil.fromGregorian(pagume6);
      expect(etPagume6.year, 2015);
      expect(etPagume6.month, 13);
      expect(etPagume6.day, 6);
      expect(EthiopianCalendarUtil.getMonthName(13), 'ጳጉሜን');

      // Next day was Meskerem 1, 2016 (Ethiopian New Year)
      final enkutatash = DateTime.utc(2023, 9, 12, 12, 0);
      final etEnkutatash = EthiopianCalendarUtil.fromGregorian(enkutatash);
      expect(etEnkutatash.year, 2016);
      expect(etEnkutatash.month, 1);
      expect(etEnkutatash.day, 1);
      expect(EthiopianCalendarUtil.getMonthName(1), 'መስከረም');
    });

    test('Channel and notification ID constants are defined appropriately', () {
      expect(EthiopianCalendarNotificationService.notificationId, 7701);
      expect(
        EthiopianCalendarNotificationService.channelId,
        'ethiopian_calendar_persistent',
      );
      expect(
        EthiopianCalendarNotificationService.prefsKey,
        'ethiopian_calendar_notification_enabled',
      );
    });
  });
}
