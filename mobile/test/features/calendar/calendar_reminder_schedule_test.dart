import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/domain/calendar_reminder_schedule.dart';

void main() {
  test('subtracts one Ethiopian day while preserving time', () {
    final result = CalendarReminderSchedule.forEvent(
      year: 2019,
      month: 4,
      day: 13,
      hour: 12,
      minute: 17,
    );

    expect(result.notification.year, 2019);
    expect(result.notification.month, 4);
    expect(result.notification.day, 12);
    expect(result.notification.hour, 12);
    expect(result.notification.minute, 17);
  });

  test('crosses Ethiopian month boundary without timestamp subtraction', () {
    final result = CalendarReminderSchedule.forEvent(
      year: 2019,
      month: 2,
      day: 1,
      hour: 23,
      minute: 59,
    );

    expect(result.notification.year, 2019);
    expect(result.notification.month, 1);
    expect(result.notification.day, 30);
    expect(result.notification.hour, 23);
    expect(result.notification.minute, 59);
  });

  test('crosses Ethiopian year boundary', () {
    final result = CalendarReminderSchedule.forEvent(
      year: 2019,
      month: 1,
      day: 1,
      hour: 0,
      minute: 0,
    );

    expect(result.notification.year, 2018);
    expect(result.notification.month, 13);
    expect(result.notification.day, 5);
  });

  test('skips a monthly day that does not exist', () {
    final note = CalendarNoteModel(
      id: 'monthly',
      userId: 'user',
      ethiopianYear: 2019,
      ethiopianMonth: 1,
      ethiopianDay: 30,
      gregorianDate: DateTime(2027, 1, 1),
      hasReminder: true,
      reminderRepeat: ReminderRepeat.monthly,
      reminderEthiopianDay: 30,
      reminderHour: 12,
      reminderMinute: 0,
      createdAt: DateTime(2027),
      updatedAt: DateTime(2027),
    );
    final result = CalendarReminderSchedule.nextForNote(
      note,
      now: EthiopianCalendarUtil.toGregorian(
        EthiopianCalendarUtil.create(2019, 1, 1),
      ),
    );

    expect(result, isNotNull);
    expect(result!.event.month, 1);
    expect(result.event.day, 30);
  });

  test('calculates next recurrence for daily reminder', () {
    final note = CalendarNoteModel(
      id: 'daily-note',
      userId: 'user',
      ethiopianYear: 2019,
      ethiopianMonth: 1,
      ethiopianDay: 10,
      gregorianDate: DateTime(2026, 9, 20),
      hasReminder: true,
      reminderRepeat: ReminderRepeat.daily,
      reminderHour: 8,
      reminderMinute: 0,
      createdAt: DateTime(2026, 9, 20),
      updatedAt: DateTime(2026, 9, 20),
    );

    final now = DateTime(2026, 9, 20, 7, 0); // before 8:00 AM
    final result = CalendarReminderSchedule.nextForNote(note, now: now);

    expect(result, isNotNull);
    expect(result!.notificationGregorian.hour, 8);
    expect(result.notificationGregorian.minute, 0);
  });

  test('calculates next recurrence for weekly reminder on matching weekday', () {
    // 2026-09-20 was a Sunday (weekday = 7)
    final note = CalendarNoteModel(
      id: 'weekly-note',
      userId: 'user',
      ethiopianYear: 2019,
      ethiopianMonth: 1,
      ethiopianDay: 10,
      gregorianDate: DateTime(2026, 9, 20),
      hasReminder: true,
      reminderRepeat: ReminderRepeat.weekly,
      reminderHour: 9,
      reminderMinute: 30,
      createdAt: DateTime(2026, 9, 20),
      updatedAt: DateTime(2026, 9, 20),
    );

    final now = DateTime(2026, 9, 21, 10, 0); // Monday, after Sunday
    final result = CalendarReminderSchedule.nextForNote(note, now: now);

    expect(result, isNotNull);
    // Next Sunday should be 2026-09-27
    expect(result!.notificationGregorian.weekday, DateTime.sunday);
    expect(result.notificationGregorian.day, 27);
    expect(result.notificationGregorian.hour, 9);
    expect(result.notificationGregorian.minute, 30);
  });
}
