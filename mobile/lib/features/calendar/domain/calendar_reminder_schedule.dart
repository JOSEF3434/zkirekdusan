import 'package:abushakir/abushakir.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';

/// Ethiopian-calendar recurrence calculations for Calendar reminders.
class CalendarReminderSchedule {
  const CalendarReminderSchedule({
    required this.event,
    required this.notification,
  });

  final EtDatetime event;
  final EtDatetime notification;

  DateTime get eventGregorian => EthiopianCalendarUtil.toGregorian(event);
  DateTime get notificationGregorian =>
      EthiopianCalendarUtil.toGregorian(notification);

  static CalendarReminderSchedule forEvent({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) {
    final event = EtDatetime(
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
    );
    return CalendarReminderSchedule(
      event: event,
      notification: _previousEthiopianDay(event),
    );
  }

  static EtDatetime _previousEthiopianDay(EtDatetime date) {
    if (date.day > 1) {
      return EtDatetime(
        year: date.year,
        month: date.month,
        day: date.day - 1,
        hour: date.hour,
        minute: date.minute,
      );
    }

    if (date.month > 1) {
      final previousMonth = date.month - 1;
      return EtDatetime(
        year: date.year,
        month: previousMonth,
        day: EthiopianCalendarUtil.getDaysInMonth(date.year, previousMonth),
        hour: date.hour,
        minute: date.minute,
      );
    }

    final previousYear = date.year - 1;
    return EtDatetime(
      year: previousYear,
      month: 13,
      day: EthiopianCalendarUtil.getDaysInMonth(previousYear, 13),
      hour: date.hour,
      minute: date.minute,
    );
  }

  static bool isValidEventDate(int year, int month, int day) {
    return month >= 1 &&
        month <= 13 &&
        day >= 1 &&
        day <= EthiopianCalendarUtil.getDaysInMonth(year, month);
  }

  static bool isValidTime(int hour, int minute) =>
      hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;

  static bool isRecurring(ReminderRepeat repeat) =>
      repeat != ReminderRepeat.none;

  static CalendarReminderSchedule? nextForNote(
    CalendarNoteModel note, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final hour = note.reminderHour ?? note.reminderDateTime?.hour;
    final minute = note.reminderMinute ?? note.reminderDateTime?.minute;
    if (!note.hasReminder || hour == null || minute == null) return null;

    if (note.reminderRepeat == ReminderRepeat.none) {
      final reminder = note.reminderDateTime;
      if (reminder == null || !reminder.isAfter(current)) return null;
      final event = EthiopianCalendarUtil.fromGregorian(
        reminder.add(const Duration(days: 1)),
      );
      return CalendarReminderSchedule(
        event: event,
        notification: EthiopianCalendarUtil.fromGregorian(reminder),
      );
    }

    final currentEthiopian = EthiopianCalendarUtil.fromGregorian(current);
    if (note.reminderRepeat == ReminderRepeat.monthly) {
      final day = note.reminderEthiopianDay ?? note.ethiopianDay;
      for (var offset = 0; offset < 24; offset++) {
        final absoluteMonth = currentEthiopian.month - 1 + offset;
        final year = currentEthiopian.year + absoluteMonth ~/ 13;
        final month = absoluteMonth % 13 + 1;
        if (day > EthiopianCalendarUtil.getDaysInMonth(year, month)) continue;
        final schedule = forEvent(
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
        );
        if (schedule.notificationGregorian.isAfter(current)) return schedule;
      }
    }

    if (note.reminderRepeat == ReminderRepeat.yearly) {
      final month = note.reminderEthiopianMonth ?? note.ethiopianMonth;
      final day = note.reminderEthiopianDay ?? note.ethiopianDay;
      for (
        var year = currentEthiopian.year;
        year <= currentEthiopian.year + 8;
        year++
      ) {
        if (!isValidEventDate(year, month, day)) continue;
        final schedule = forEvent(
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
        );
        if (schedule.notificationGregorian.isAfter(current)) return schedule;
      }
    }

    return null;
  }
}
