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

  group('Bahire Hasab (ባሕረ ሐሳብ) & Movable Fasting Computations in Flutter', () {
    test('Evangelist (ወንጌላዊ) calculation across multiple Ethiopian years', () {
      expect(EthiopianCalendarUtil.calculateBahireHasab(2015).evangelist, equals('ሉቃስ'));
      expect(EthiopianCalendarUtil.calculateBahireHasab(2016).evangelist, equals('ዮሐንስ'));
      expect(EthiopianCalendarUtil.calculateBahireHasab(2017).evangelist, equals('ማቴዎስ'));
      expect(EthiopianCalendarUtil.calculateBahireHasab(2018).evangelist, equals('ማርቆስ'));
      expect(EthiopianCalendarUtil.calculateBahireHasab(2019).evangelist, equals('ሉቃስ'));
      expect(EthiopianCalendarUtil.calculateBahireHasab(2020).evangelist, equals('ዮሐንስ'));
    });

    test('Bahire Hasab movable fasts calculation for Ethiopian year 2016', () {
      final bh2016 = EthiopianCalendarUtil.calculateBahireHasab(2016);
      expect(bh2016.year, equals(2016));
      expect(bh2016.evangelist, equals('ዮሐንስ'));

      // Nenewe in 2016: Yekatit 18
      expect(bh2016.nenewe.month, equals(6));
      expect(bh2016.nenewe.day, equals(18));

      // Abiy Tsom (Great Lent) begins Megabit 2, duration 55 days
      expect(bh2016.abiyTsom.startMonth, equals(7));
      expect(bh2016.abiyTsom.startDay, equals(2));

      // Debre Zeyt: Megabit 29
      expect(bh2016.debreZeyt.month, equals(7));
      expect(bh2016.debreZeyt.day, equals(29));

      // Fasika (Easter): Miazia 27
      expect(bh2016.fasika.month, equals(8));
      expect(bh2016.fasika.day, equals(27));

      // Erget (Ascension): Sene 6
      expect(bh2016.erget.month, equals(10));
      expect(bh2016.erget.day, equals(6));

      // Peraklitos (Pentecost): Sene 16
      expect(bh2016.peraklitos.month, equals(10));
      expect(bh2016.peraklitos.day, equals(16));

      // Apostles Fast: starts Sene 17, ends Hamle 5
      expect(bh2016.apostlesFast.startMonth, equals(10));
      expect(bh2016.apostlesFast.startDay, equals(17));
      expect(bh2016.apostlesFast.endMonth, equals(11));
      expect(bh2016.apostlesFast.endDay, equals(5));
    });
  });

  group('Wednesday & Friday Fasting Rules (ጾመ ድኅነት) & Beale Hamsa Exemptions', () {
    test('Standard Wednesdays and Fridays outside Beale Hamsa are fasting days', () {
      // Meskerem 2016
      for (int day = 1; day <= 30; day++) {
        final weekday = EthiopianCalendarUtil.getWeekday(2016, 1, day);
        final isFast = EthiopianCalendarUtil.isWednesdayFridayFastingDay(2016, 1, day);
        if (weekday == 3 || weekday == 5) {
          expect(isFast, isTrue, reason: 'Meskerem $day is weekday $weekday and must be fasting');
        } else {
          expect(isFast, isFalse, reason: 'Meskerem $day is weekday $weekday and not Wed/Fri');
        }
      }
    });

    test('Wednesdays and Fridays during Beale Hamsa (በዓለ ኀምሳ) are non-fasting', () {
      // In 2016, Fasika is Miazia 27 (Sunday). The subsequent Wednesday is Miazia 30!
      final weekdayMiazia30 = EthiopianCalendarUtil.getWeekday(2016, 8, 30);
      expect(weekdayMiazia30, equals(3)); // Wednesday

      // Must be exempt because it is inside Beale Hamsa
      expect(
        EthiopianCalendarUtil.isWednesdayFridayFastingDay(2016, 8, 30),
        isFalse,
        reason: 'Miazia 30 falls within the 50 joyful days of Beale Hamsa and must be exempt',
      );

      // Check Ginbot (month 9) which is entirely within Beale Hamsa in 2016
      for (int day = 1; day <= 30; day++) {
        final isFast = EthiopianCalendarUtil.isWednesdayFridayFastingDay(2016, 9, day);
        expect(isFast, isFalse, reason: 'Ginbot $day is within Beale Hamsa and cannot be a Wed/Fri fast');
      }
    });

    test('Monthly fast days list returns all fasting Wednesdays and Fridays in the month', () {
      final fastDays = EthiopianCalendarUtil.getWednesdayFridayFastDaysForMonth(2016, 1);
      expect(fastDays.length, greaterThanOrEqualTo(8));
      for (final day in fastDays) {
        final wd = EthiopianCalendarUtil.getWeekday(2016, 1, day);
        expect([3, 5].contains(wd), isTrue);
      }
    });
  });

  group('Canonical Fasts & Holidays Verification', () {
    test('Repository contains verified ጾመ ስብከት / ጾመ ስቢይ with canonical descriptions', () async {
      final repo = CalendarEventRepository(Dio());
      final events = await repo.getEventsForYear(2016);

      // ጾመ ስብከት / ጾመ ስቢይ
      final adventSubEvent = events.firstWhere(
        (e) => e.name.contains('ስብከት') || e.name.contains('ስቢይ'),
        orElse: () => const CalendarEventModel(id: '', name: '', type: CalendarEventType.fast, category: CalendarEventCategory.majorFast, startMonth: 0, startDay: 0, endMonth: 0, endDay: 0),
      );
      expect(adventSubEvent.id.isNotEmpty, isTrue);
      expect(adventSubEvent.isFast, isTrue);
      expect(adventSubEvent.description?.isNotEmpty, isTrue);

      // ጾመ ድኅነት (Wednesday & Friday Fasting rule)
      final wedFriEvent = events.firstWhere(
        (e) => e.id == 'fast-wed-fri' || e.name.contains('ድኅነት'),
        orElse: () => const CalendarEventModel(id: '', name: '', type: CalendarEventType.fast, category: CalendarEventCategory.majorFast, startMonth: 0, startDay: 0, endMonth: 0, endDay: 0),
      );
      expect(wedFriEvent.id.isNotEmpty, isTrue);
      expect(wedFriEvent.isFast, isTrue);

      // Feasts of the Blessed Virgin Mary (e.g. ፍልሰታ ለማርያም, አስተርእዮ ማርያም)
      final filseta = events.firstWhere(
        (e) => e.name.contains('ፍልሰታ ለማርያም'),
        orElse: () => const CalendarEventModel(id: '', name: '', type: CalendarEventType.holiday, category: CalendarEventCategory.majorHoliday, startMonth: 0, startDay: 0, endMonth: 0, endDay: 0),
      );
      expect(filseta.id.isNotEmpty, isTrue);

      // Major Saints & Angels (e.g. ቅዱስ ሚካኤል, ቅዱስ ገብርኤል)
      final michael = events.where((e) => e.name.contains('ሚካኤል')).toList();
      expect(michael.isNotEmpty, isTrue);
    });

    test('Filter logic properly segregates events into the 5 category chips', () async {
      final repo = CalendarEventRepository(Dio());
      final events = await repo.getEventsForYear(2016);

      // 1. Fasting Periods (አጽዋማት)
      final fasts = events.where((e) => e.isFast && e.id != 'fast-wed-fri').toList();
      expect(fasts.isNotEmpty, isTrue);
      for (final f in fasts) {
        expect(f.isFast, isTrue);
        expect(f.id, isNot('fast-wed-fri'));
      }

      // 2. Wed & Fri Fasts (ረቡዕና ዓርብ ጾም)
      final wedFri = events.where((e) => e.id == 'fast-wed-fri' || e.name.contains('ድኅነት') || e.name.contains('ረቡዕ')).toList();
      expect(wedFri.isNotEmpty, isTrue);

      // 3. Major Holidays (ዐበይት በዓላት)
      final majorHolidays = events.where((e) => !e.isFast && (e.isMajor || e.category == CalendarEventCategory.majorHoliday)).toList();
      expect(majorHolidays.isNotEmpty, isTrue);
      for (final h in majorHolidays) {
        expect(h.isFast, isFalse);
      }

      // 4. Saints & Commemorations (የቅዱሳን በዓላት)
      final saints = events.where((e) => !e.isFast && !e.isMajor && e.category != CalendarEventCategory.majorHoliday).toList();
      expect(saints.isNotEmpty, isTrue);
    });
  });
}
