// lib/features/calendar/presentation/providers/calendar_notes_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      })
    >(
      (ref) => (id, {title, content}) {
        final repository = ref.read(calendarOfflineRepositoryProvider);
        return repository.updateNote(id, title: title, content: content);
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
