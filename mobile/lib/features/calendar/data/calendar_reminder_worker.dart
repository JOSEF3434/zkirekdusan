// lib/features/calendar/data/calendar_reminder_worker.dart
// Background worker for checking and scheduling upcoming reminders

import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/calendar/data/calendar_notifications_service.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';

/// Task names for reminder checking
class CalendarReminderTasks {
  static const String checkReminders = 'calendar_check_reminders';
}

/// Background reminder callback dispatcher
@pragma('vm:entry-point')
void calendarReminderCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      developer.log('🔔 Reminder check task started', name: 'ReminderWorker');

      // Initialize dependencies
      final db = AppDatabase();
      final notificationsService = CalendarNotificationsService();
      await notificationsService.initialize();

      final upcomingNotes =
          await (db.select(db.localCalendarNotes)..where(
                (tbl) => tbl.hasReminder.equals(true) & tbl.deletedAt.isNull(),
              ))
              .get();

      developer.log(
        '📋 Found ${upcomingNotes.length} upcoming reminders',
        name: 'ReminderWorker',
      );

      // Map notes and schedule with yearly priority and 5-minute staggering
      final notesList = <CalendarNoteModel>[];
      for (final noteData in upcomingNotes) {
        notesList.add(
          CalendarNoteModel(
            id: noteData.id,
            userId: noteData.userId,
            ethiopianYear: noteData.ethiopianYear,
            ethiopianMonth: noteData.ethiopianMonth,
            ethiopianDay: noteData.ethiopianDay,
            gregorianDate: noteData.gregorianDate,
            title: noteData.title,
            content: noteData.content,
            hasReminder: noteData.hasReminder,
            reminderDateTime: noteData.reminderDateTime,
            reminderNotified: noteData.reminderNotified,
            reminderRepeat: ReminderRepeat.values.firstWhere(
              (value) => value.name.toUpperCase() == noteData.reminderRepeat,
              orElse: () => ReminderRepeat.none,
            ),
            reminderEthiopianMonth: noteData.reminderEthiopianMonth,
            reminderEthiopianDay: noteData.reminderEthiopianDay,
            reminderHour: noteData.reminderHour,
            reminderMinute: noteData.reminderMinute,
            reminderTimezone: noteData.reminderTimezone,
            reminderNextOccurrence: noteData.reminderNextOccurrence,
            media: const [],
            createdAt: noteData.createdAt,
            updatedAt: noteData.updatedAt,
            deletedAt: noteData.deletedAt,
          ),
        );
      }

      await notificationsService
          .scheduleRemindersWithPriorityAndStaggering(notesList);

      // Clean up
      await db.close();

      developer.log('✅ Reminder check completed', name: 'ReminderWorker');
      return true;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Reminder check error: $e',
        name: 'ReminderWorker',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  });
}

/// Background reminder manager
class CalendarReminderManager {
  /// Initialize reminder worker
  static Future<void> initialize() async {
    developer.log('🚀 Initializing reminder worker', name: 'ReminderWorker');

    try {
      await Workmanager().initialize(calendarReminderCallbackDispatcher);

      developer.log('✅ Reminder worker initialized', name: 'ReminderWorker');
    } catch (e) {
      developer.log(
        '❌ Reminder worker init failed: $e',
        name: 'ReminderWorker',
      );
    }
  }

  /// Register periodic reminder check (every 15 minutes)
  static Future<void> registerPeriodicReminderCheck() async {
    try {
      await Workmanager().registerPeriodicTask(
        CalendarReminderTasks.checkReminders,
        CalendarReminderTasks.checkReminders,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.notRequired, // Works offline
          requiresBatteryNotLow: true,
          requiresCharging: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );

      developer.log(
        '✅ Periodic reminder check registered (every 15 min)',
        name: 'ReminderWorker',
      );
    } catch (e) {
      developer.log(
        '❌ Failed to register periodic reminder check: $e',
        name: 'ReminderWorker',
      );
    }
  }

  /// Trigger immediate reminder check
  static Future<void> triggerImmediateCheck() async {
    try {
      await Workmanager().registerOneOffTask(
        '${CalendarReminderTasks.checkReminders}_oneoff',
        CalendarReminderTasks.checkReminders,
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      developer.log(
        '✅ Immediate reminder check triggered',
        name: 'ReminderWorker',
      );
    } catch (e) {
      developer.log(
        '❌ Failed to trigger immediate reminder check: $e',
        name: 'ReminderWorker',
      );
    }
  }

  /// Cancel all reminder checks
  static Future<void> cancelAll() async {
    try {
      await Workmanager().cancelByUniqueName(
        CalendarReminderTasks.checkReminders,
      );
      developer.log('✅ Reminder checks cancelled', name: 'ReminderWorker');
    } catch (e) {
      developer.log(
        '❌ Failed to cancel reminder checks: $e',
        name: 'ReminderWorker',
      );
    }
  }
}
