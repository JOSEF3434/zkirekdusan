// lib/features/calendar/presentation/providers/calendar_notes_provider.dart
import 'package:abushakir/abushakir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';

/// Provider for notes filtered by specific date
final calendarNotesForDateProvider =
    FutureProvider.family<
      List<CalendarNoteModel>,
      ({int year, int month, int day})
    >((ref, params) async {
      final repository = ref.watch(calendarOfflineRepositoryProvider);
      return repository.getNotesForDate(
        year: params.year,
        month: params.month,
        day: params.day,
      );
    });

/// Provider for all notes in a specific month
final calendarNotesForMonthProvider =
    FutureProvider.family<List<CalendarNoteModel>, ({int year, int month})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(calendarOfflineRepositoryProvider);
      return repository.getNotesForMonth(
        year: params.year,
        month: params.month,
      );
    });

/// Provider for notes within a specific Ethiopian date range
final calendarNotesForRangeProvider = FutureProvider.family<
    List<CalendarNoteModel>,
    ({
      int? startYear,
      int? startMonth,
      int? startDay,
      int? endYear,
      int? endMonth,
      int? endDay,
      String? from,
      String? to,
    })>((ref, params) async {
  final repository = ref.watch(calendarOfflineRepositoryProvider);
  return repository.getNotesForRange(
    startYear: params.startYear,
    startMonth: params.startMonth,
    startDay: params.startDay,
    endYear: params.endYear,
    endMonth: params.endMonth,
    endDay: params.endDay,
    from: params.from,
    to: params.to,
  );
});

/// Provider for notes for the current Ethiopian week (Monday to Sunday)
final calendarNotesForCurrentWeekProvider = FutureProvider<
    List<({EtDatetime date, CalendarNoteModel? note})>>((ref) async {
  final repository = ref.watch(calendarOfflineRepositoryProvider);
  final nowGregorian = DateTime.now();
  final mondayGregorian =
      nowGregorian.subtract(Duration(days: nowGregorian.weekday - 1));
  final weekDates = List.generate(7, (i) {
    final gDate = mondayGregorian.add(Duration(days: i));
    return EthiopianCalendarUtil.fromGregorian(gDate);
  });

  final startDate = weekDates.first;
  final endDate = weekDates.last;

  final notes = await repository.getNotesForRange(
    startYear: startDate.year,
    startMonth: startDate.month,
    startDay: startDate.day,
    endYear: endDate.year,
    endMonth: endDate.month,
    endDay: endDate.day,
  );

  return weekDates.map((d) {
    final match = notes.where((n) =>
        n.ethiopianYear == d.year &&
        n.ethiopianMonth == d.month &&
        n.ethiopianDay == d.day &&
        n.deletedAt == null).toList();
    return (
      date: d,
      note: match.isNotEmpty ? match.first : null,
    );
  }).toList();
});

/// Provider for creating a note (offline-first)
final createCalendarNoteProvider =
    Provider<
      Future<CalendarNoteModel> Function({
        required String userId,
        required int ethiopianYear,
        required int ethiopianMonth,
        required int ethiopianDay,
        required DateTime gregorianDate,
        String? title,
        String? content,
        bool? hasReminder,
        DateTime? reminderDateTime,
        ReminderRepeat? reminderRepeat,
        int? reminderEthiopianMonth,
        int? reminderEthiopianDay,
        int? reminderHour,
        int? reminderMinute,
        String? reminderTimezone,
        DateTime? reminderNextOccurrence,
        bool? allowDownload,
        String? category,
        ReminderRepeat? recurrenceType,
        bool? isAutoPublishEnabled,
        String? autoPublishTime,
      })
    >(
      (ref) =>
          ({
            required String userId,
            required int ethiopianYear,
            required int ethiopianMonth,
            required int ethiopianDay,
            required DateTime gregorianDate,
            String? title,
            String? content,
            bool? hasReminder,
            DateTime? reminderDateTime,
            ReminderRepeat? reminderRepeat,
            int? reminderEthiopianMonth,
            int? reminderEthiopianDay,
            int? reminderHour,
            int? reminderMinute,
            String? reminderTimezone,
            DateTime? reminderNextOccurrence,
            bool? allowDownload,
            String? category,
            ReminderRepeat? recurrenceType,
            bool? isAutoPublishEnabled,
            String? autoPublishTime,
          }) {
            final repository = ref.read(calendarOfflineRepositoryProvider);
            return repository.createNote(
              userId: userId,
              ethiopianYear: ethiopianYear,
              ethiopianMonth: ethiopianMonth,
              ethiopianDay: ethiopianDay,
              gregorianDate: gregorianDate,
              title: title,
              content: content,
              hasReminder: hasReminder ?? false,
              reminderDateTime: reminderDateTime,
              reminderRepeat: reminderRepeat ?? ReminderRepeat.none,
              reminderEthiopianMonth: reminderEthiopianMonth,
              reminderEthiopianDay: reminderEthiopianDay,
              reminderHour: reminderHour,
              reminderMinute: reminderMinute,
              reminderTimezone: reminderTimezone ?? 'Africa/Addis_Ababa',
              reminderNextOccurrence: reminderNextOccurrence,
              allowDownload: allowDownload ?? false,
              category: category,
              recurrenceType: recurrenceType,
              isAutoPublishEnabled: isAutoPublishEnabled ?? false,
              autoPublishTime: autoPublishTime,
            );
          },
    );

/// Provider for updating a note (offline-first)
final updateCalendarNoteProvider =
    Provider<
      Future<CalendarNoteModel> Function(
        String, {
        String? title,
        String? content,
        bool? hasReminder,
        DateTime? reminderDateTime,
        ReminderRepeat? reminderRepeat,
        int? reminderEthiopianMonth,
        int? reminderEthiopianDay,
        int? reminderHour,
        int? reminderMinute,
        String? reminderTimezone,
        DateTime? reminderNextOccurrence,
        bool? allowDownload,
        String? category,
        ReminderRepeat? recurrenceType,
        bool? isAutoPublishEnabled,
        String? autoPublishTime,
      })
    >(
      (ref) =>
          (
            id, {
            title,
            content,
            hasReminder,
            reminderDateTime,
            reminderRepeat,
            reminderEthiopianMonth,
            reminderEthiopianDay,
            reminderHour,
            reminderMinute,
            reminderTimezone,
            reminderNextOccurrence,
            allowDownload,
            category,
            recurrenceType,
            isAutoPublishEnabled,
            autoPublishTime,
          }) {
            final repository = ref.read(calendarOfflineRepositoryProvider);
            return repository.updateNote(
              id,
              title: title,
              content: content,
              hasReminder: hasReminder,
              reminderDateTime: reminderDateTime,
              reminderRepeat: reminderRepeat ?? ReminderRepeat.none,
              reminderEthiopianMonth: reminderEthiopianMonth,
              reminderEthiopianDay: reminderEthiopianDay,
              reminderHour: reminderHour,
              reminderMinute: reminderMinute,
              reminderTimezone: reminderTimezone ?? 'Africa/Addis_Ababa',
              reminderNextOccurrence: reminderNextOccurrence,
              allowDownload: allowDownload,
              category: category,
              recurrenceType: recurrenceType,
              isAutoPublishEnabled: isAutoPublishEnabled,
              autoPublishTime: autoPublishTime,
            );
          },
    );

/// Provider for deleting a note (offline-first)
final deleteCalendarNoteProvider = Provider<Future<void> Function(String)>(
  (ref) => (id) {
    final repository = ref.read(calendarOfflineRepositoryProvider);
    return repository.deleteNote(id);
  },
);

/// Provider for syncing notes from server
final syncCalendarNotesProvider =
    Provider<Future<void> Function({int? year, int? month})>(
      (ref) => ({year, month}) {
        final repository = ref.read(calendarOfflineRepositoryProvider);
        return repository.syncNotesFromServer(year: year, month: month);
      },
    );

/// Provider for pushing unsynced notes
final pushUnsyncedNotesProvider = Provider<Future<void> Function()>(
  (ref) => () {
    final repository = ref.read(calendarOfflineRepositoryProvider);
    return repository.pushUnsyncedNotes();
  },
);

// ── Media management providers ────────────────────────────────────────────────

/// Remove a single media item from a calendar note (SUPER_ADMIN only).
final deleteCalendarNoteMediaProvider =
    Provider<Future<void> Function(String noteId, String mediaId)>(
      (ref) => (noteId, mediaId) {
        final repository = ref.read(calendarOfflineRepositoryProvider);
        return repository.removeNoteMedia(noteId: noteId, mediaId: mediaId);
      },
    );

/// Update caption / order of a media item on a calendar note (SUPER_ADMIN only).
final updateCalendarNoteMediaProvider =
    Provider<
      Future<void> Function(
        String noteId,
        String mediaId, {
        String? caption,
        int? order,
      })
    >(
      (ref) =>
          (noteId, mediaId, {caption, order}) {
            final repository = ref.read(calendarOfflineRepositoryProvider);
            return repository.updateNoteMedia(
              noteId: noteId,
              mediaId: mediaId,
              caption: caption,
              order: order,
            );
          },
    );
