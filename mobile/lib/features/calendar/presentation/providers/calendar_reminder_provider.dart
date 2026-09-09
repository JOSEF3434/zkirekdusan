// lib/features/calendar/presentation/providers/calendar_reminder_provider.dart
// Providers for calendar reminder management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/data/calendar_notifications_service.dart';
import 'package:mobile/features/calendar/data/calendar_reminder_worker.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';

/// Provider for notifications service
final calendarNotificationsProvider = Provider<CalendarNotificationsService>((
  ref,
) {
  return CalendarNotificationsService();
});

/// Provider for scheduling a reminder
final scheduleReminderProvider =
    Provider<Future<void> Function(CalendarNoteModel note)>((ref) {
      return (note) async {
        final service = ref.read(calendarNotificationsProvider);
        await service.scheduleReminder(note);
      };
    });

/// Provider for cancelling a reminder
final cancelReminderProvider = Provider<Future<void> Function(String noteId)>((
  ref,
) {
  return (noteId) async {
    final service = ref.read(calendarNotificationsProvider);
    await service.cancelReminder(noteId);
  };
});

/// Provider for initializing reminders
final initializeRemindersProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // Initialize notifications service
    final service = ref.read(calendarNotificationsProvider);
    await service.initialize();

    // Initialize and register background worker
    await CalendarReminderManager.initialize();
    await CalendarReminderManager.registerPeriodicReminderCheck();
  };
});

/// Provider for triggering immediate reminder check
final triggerReminderCheckProvider = Provider<Future<void> Function()>((ref) {
  return () => CalendarReminderManager.triggerImmediateCheck();
});

/// Provider for getting pending notifications count
final pendingNotificationsCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(calendarNotificationsProvider);
  final pending = await service.getPendingNotifications();
  return pending.length;
});
