import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';
import 'package:mobile/features/calendar/data/calendar_event_repository.dart';
import 'package:dio/dio.dart';

void main() {
  group('Ethiopian Calendar Date & Leap Year Tests', () {
    test('Ethiopian leap year and month days calculation', () {
      // Ethiopian leap year is when year % 4 == 3 (e.g. 2007, 2011, 2015, 2019)
      expect(EthiopianCalendarUtil.isLeapYear(2015), isTrue);
      expect(EthiopianCalendarUtil.isLeapYear(2016), isFalse);
      expect(EthiopianCalendarUtil.isLeapYear(2017), isFalse);
      expect(EthiopianCalendarUtil.isLeapYear(2018), isFalse);
      expect(EthiopianCalendarUtil.isLeapYear(2019), isTrue);

      // Months 1..12 always have 30 days
      for (int m = 1; m <= 12; m++) {
        expect(EthiopianCalendarUtil.getDaysInMonth(2015, m), equals(30));
        expect(EthiopianCalendarUtil.getDaysInMonth(2016, m), equals(30));
      }

      // Pagumen (month 13) has 6 days on leap year, 5 days on normal year
      expect(EthiopianCalendarUtil.getDaysInMonth(2015, 13), equals(6));
      expect(EthiopianCalendarUtil.getDaysInMonth(2016, 13), equals(5));
      expect(EthiopianCalendarUtil.getDaysInMonth(2017, 13), equals(5));
      expect(EthiopianCalendarUtil.getDaysInMonth(2019, 13), equals(6));
    });
  });

  group('CalendarEventModel Serialization & Behavior Tests', () {
    test('CalendarEventModel serialization and deserialization', () {
      final json = {
        'id': 'evt-1',
        'name': 'ገና',
        'nameEn': 'Christmas',
        'description': 'የጌታችን የመድኃኒታችን የኢየሱስ ክርስቶስ የልደት በዓል',
        'type': 'HOLIDAY',
        'category': 'MAJOR_HOLIDAY',
        'startMonth': 4,
        'startDay': 29,
        'endMonth': 4,
        'endDay': 29,
        'ethiopianYear': null,
        'isRecurring': true,
        'primaryColor': '#10B981',
        'spiritualMeaning': 'Celebration of the birth of Christ',
        'fastingRules': null,
        'durationDays': 1,
        'isMajor': true,
        'isActive': true,
        'importance': 'MAJOR',
      };

      final event = CalendarEventModel.fromJson(json);
      expect(event.id, equals('evt-1'));
      expect(event.name, equals('ገና'));
      expect(event.nameEn, equals('Christmas'));
      expect(event.type, equals(CalendarEventType.holiday));
      expect(event.category, equals(CalendarEventCategory.majorHoliday));
      expect(event.isMajor, isTrue);
      expect(event.isFast, isFalse);
      expect(event.isHoliday, isTrue);
      expect(event.isSpecialEvent, isFalse);
      expect(event.importance, equals('MAJOR'));
      expect(event.isSingleDay, isTrue);
      expect(event.startMonth, equals(4));
      expect(event.startDay, equals(29));
      expect(event.endMonth, equals(4));
      expect(event.endDay, equals(29));
      expect(event.isRecurring, isTrue);
      expect(event.primaryColor, equals('#10B981'));

      final serialized = event.toJson();
      expect(serialized['id'], equals('evt-1'));
      expect(serialized['name'], equals('ገና'));
      expect(serialized['type'], equals('HOLIDAY'));
      expect(serialized['category'], equals('MAJOR_HOLIDAY'));
      expect(serialized['nameEn'], equals('Christmas'));
      expect(serialized['importance'], equals('MAJOR'));
    });

    test('Special Event serialization, category, and importance behavior', () {
      final json = {
        'id': 'spec-1',
        'name': 'የደብር በዓል',
        'nameEn': 'Parish Feast Day',
        'description': 'የታቦት ንግሥ በዓል',
        'type': 'SPECIAL_EVENT',
        'category': 'MEMORIAL',
        'startMonth': 2,
        'startDay': 12,
        'endMonth': 2,
        'endDay': 12,
        'isRecurring': false,
        'importance': 'SPECIAL',
        'isActive': true,
      };

      final event = CalendarEventModel.fromJson(json);
      expect(event.id, equals('spec-1'));
      expect(event.type, equals(CalendarEventType.specialEvent));
      expect(event.isSpecialEvent, isTrue);
      expect(event.isFast, isFalse);
      expect(event.isHoliday, isFalse);
      expect(event.isSpecial, isTrue);
      expect(event.isSingleDay, isTrue);
      expect(event.defaultColorHex, equals('#16A34A'));
      expect(event.effectiveColorHex, equals('#16A34A'));

      final serialized = event.toJson();
      expect(serialized['type'], equals('SPECIAL_EVENT'));
      expect(serialized['importance'], equals('SPECIAL'));
    });

    test('Automatic color rules & effectiveColorHex priority', () {
      // 1. Fasting period default: Orange (#F59E0B)
      const fastEvent = CalendarEventModel(
        id: 'fast-1',
        name: 'ጾመ ነቢያት',
        type: CalendarEventType.fast,
        category: CalendarEventCategory.majorFast,
        startMonth: 3,
        startDay: 15,
        endMonth: 4,
        endDay: 28,
      );
      expect(fastEvent.defaultColorHex, equals('#F59E0B'));
      expect(fastEvent.effectiveColorHex, equals('#F59E0B'));

      // 2. Major holiday default: Red (#DC2626)
      const holidayEvent = CalendarEventModel(
        id: 'hol-1',
        name: 'ገና',
        type: CalendarEventType.holiday,
        category: CalendarEventCategory.majorHoliday,
        startMonth: 4,
        startDay: 29,
        endMonth: 4,
        endDay: 29,
        isMajor: true,
      );
      expect(holidayEvent.defaultColorHex, equals('#DC2626'));
      expect(holidayEvent.effectiveColorHex, equals('#DC2626'));

      // 3. Special event default: Green (#16A34A)
      const specialEvent = CalendarEventModel(
        id: 'spec-1',
        name: 'ጉባኤ',
        type: CalendarEventType.specialEvent,
        category: CalendarEventCategory.annualFeast,
        startMonth: 5,
        startDay: 1,
        endMonth: 5,
        endDay: 1,
      );
      expect(specialEvent.defaultColorHex, equals('#16A34A'));
      expect(specialEvent.effectiveColorHex, equals('#16A34A'));

      // 4. Custom primaryColor override takes priority over default
      final customColorEvent = fastEvent.copyWith(primaryColor: '#7C3AED');
      expect(customColorEvent.effectiveColorHex, equals('#7C3AED'));
    });

    test('Single-month event day start/end boundary checks', () {
      const meskel = CalendarEventModel(
        id: 'meskel',
        name: 'መስቀል',
        nameEn: 'Finding of the True Cross',
        type: CalendarEventType.holiday,
        category: CalendarEventCategory.majorHoliday,
        startMonth: 1,
        startDay: 17,
        endMonth: 1,
        endDay: 17,
        isRecurring: true,
        isMajor: true,
      );

      expect(meskel.isSingleDay, isTrue);
      expect(meskel.isDayStart(17), isTrue);
      expect(meskel.isDayEnd(17), isTrue);
      expect(meskel.isDayStart(16), isFalse);
      expect(meskel.isDayEnd(18), isFalse);
    });

    test('Multi-month spanning fasting coverage with built-in repo', () async {
      final repo = CalendarEventRepository(Dio());
      // Test month 3 (Hidar) - Tsome Nebiyat starts Hidar 15
      final eventsMonth3 = await repo.getEventsForMonth(2016, 3);
      final nebiyatMonth3 = eventsMonth3.firstWhere(
        (e) => e.id == 'fast-prophets' || e.name.contains('ነቢያት'),
      );
      expect(nebiyatMonth3, isNotNull);
      expect(nebiyatMonth3.isFast, isTrue);
      expect(nebiyatMonth3.coverage, isNotNull);
      expect(nebiyatMonth3.coverage!.isStartMonth, isTrue);
      expect(nebiyatMonth3.coverage!.isEndMonth, isFalse);
      expect(nebiyatMonth3.coverage!.startDay, equals(15));
      expect(nebiyatMonth3.coverage!.days.contains(15), isTrue);
      expect(nebiyatMonth3.coverage!.days.contains(30), isTrue);

      // Test month 4 (Tahsas) - Tsome Nebiyat ends Tahsas 28
      final eventsMonth4 = await repo.getEventsForMonth(2016, 4);
      final nebiyatMonth4 = eventsMonth4.firstWhere(
        (e) => e.id == 'fast-prophets' || e.name.contains('ነቢያት'),
      );
      expect(nebiyatMonth4, isNotNull);
      expect(nebiyatMonth4.coverage, isNotNull);
      expect(nebiyatMonth4.coverage!.isStartMonth, isFalse);
      expect(nebiyatMonth4.coverage!.isEndMonth, isTrue);
      expect(nebiyatMonth4.coverage!.endDay, equals(28));
      expect(nebiyatMonth4.coverage!.days.contains(1), isTrue);
      expect(nebiyatMonth4.coverage!.days.contains(28), isTrue);
    });

    test('Yearly canonical events retrieval is sorted chronologically', () async {
      final repo = CalendarEventRepository(Dio());
      final events = await repo.getEventsForYear(2016);
      expect(events.isNotEmpty, isTrue);
      // All events in year must be sorted by startMonth, then startDay
      for (int i = 0; i < events.length - 1; i++) {
        final a = events[i];
        final b = events[i + 1];
        final cmp = a.startMonth.compareTo(b.startMonth);
        if (cmp == 0) {
          expect(a.startDay <= b.startDay, isTrue);
        } else {
          expect(cmp < 0, isTrue);
        }
      }
    });

    test('Cross-year non-recurring date range attributes and validation', () {
      const crossYearRange = CalendarEventModel(
        id: 'cross-year-1',
        name: 'ልዩ የጸሎት ሳምንት',
        type: CalendarEventType.specialEvent,
        category: CalendarEventCategory.majorFast,
        startMonth: 13,
        startDay: 1,
        endMonth: 1,
        endDay: 5,
        ethiopianYear: 2016,
        isRecurring: false,
      );

      expect(crossYearRange.isSingleDay, isFalse);
      expect(crossYearRange.startMonth, equals(13));
      expect(crossYearRange.endMonth, equals(1));
      expect(crossYearRange.startDay, equals(1));
      expect(crossYearRange.endDay, equals(5));
      expect(crossYearRange.isSpecialEvent, isTrue);
    });
  });
}
