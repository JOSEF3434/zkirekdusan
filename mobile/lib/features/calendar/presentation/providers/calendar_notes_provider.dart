// lib/features/calendar/presentation/providers/calendar_notes_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/data/calendar_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';

/// Provider for notes filtered by specific date
final calendarNotesForDateProvider = FutureProvider.family<
    List<CalendarNoteModel>,
    ({int year, int month, int day})>((ref, params) async {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.getNotes(
    year: params.year,
    month: params.month,
    day: params.day,
  );
});

/// Provider for all notes in a specific month
final calendarNotesForMonthProvider = FutureProvider.family<
    List<CalendarNoteModel>,
    ({int year, int month})>((ref, params) async {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.getNotes(
    year: params.year,
    month: params.month,
  );
});

/// Provider for creating a note
final createCalendarNoteProvider =
    Provider<Future<CalendarNoteModel> Function(CreateCalendarNoteDto)>(
  (ref) => (dto) {
    final repository = ref.read(calendarRepositoryProvider);
    return repository.createNote(dto);
  },
);

/// Provider for updating a note
final updateCalendarNoteProvider = Provider<
    Future<CalendarNoteModel> Function(String, UpdateCalendarNoteDto)>(
  (ref) => (id, dto) {
    final repository = ref.read(calendarRepositoryProvider);
    return repository.updateNote(id, dto);
  },
);

/// Provider for deleting a note
final deleteCalendarNoteProvider =
    Provider<Future<void> Function(String)>((ref) => (id) {
          final repository = ref.read(calendarRepositoryProvider);
          return repository.deleteNote(id);
        });
