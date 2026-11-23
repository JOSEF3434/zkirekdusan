// lib/features/calendar/presentation/providers/calendar_events_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/data/calendar_event_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';

/// Provider for calendar events overlapping a specific Ethiopian month
final calendarEventsForMonthProvider = FutureProvider.family<
    List<CalendarEventModel>,
    ({int year, int month})>((ref, date) async {
  final repo = ref.watch(calendarEventRepositoryProvider);
  return repo.getEventsForMonth(date.year, date.month);
});

/// Provider for all fasting periods and holidays in an Ethiopian year
final calendarEventsForYearProvider =
    FutureProvider.family<List<CalendarEventModel>, int>((ref, year) async {
  final repo = ref.watch(calendarEventRepositoryProvider);
  return repo.getEventsForYear(year);
});

/// Helper provider to get events specifically covering a single day
final calendarEventsForDayProvider = Provider.family<
    List<CalendarEventModel>,
    ({int year, int month, int day})>((ref, arg) {
  final monthAsync = ref.watch(
    calendarEventsForMonthProvider((year: arg.year, month: arg.month)),
  );
  final events = monthAsync.valueOrNull ?? const <CalendarEventModel>[];
  return events.where((e) {
    if (e.coverage != null) {
      return e.coverage!.days.contains(arg.day);
    }
    if (e.startMonth == e.endMonth) {
      return e.startMonth == arg.month &&
          arg.day >= e.startDay &&
          arg.day <= e.endDay;
    }
    if (e.startMonth == arg.month) {
      return arg.day >= e.startDay;
    }
    if (e.endMonth == arg.month) {
      return arg.day <= e.endDay;
    }
    if (e.startMonth < e.endMonth) {
      return arg.month > e.startMonth && arg.month < e.endMonth;
    }
    return arg.month > e.startMonth || arg.month < e.endMonth;
  }).toList();
});

/// Admin StateNotifier for managing calendar events
class AdminCalendarEventsNotifier
    extends StateNotifier<AsyncValue<List<CalendarEventModel>>> {
  final CalendarEventRepository _repo;
  final Ref _ref;

  AdminCalendarEventsNotifier(this._repo, this._ref)
      : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents({
    int? year,
    String? type,
    String? category,
    bool? isMajor,
    String? importance,
    bool? includeInactive = true,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getAllEvents(
        year: year,
        type: type,
        category: category,
        isMajor: isMajor,
        importance: importance,
        includeInactive: includeInactive,
        search: search,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    await _repo.createEvent(data);
    _invalidateCaches();
    await loadEvents();
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _repo.updateEvent(id, data);
    _invalidateCaches();
    await loadEvents();
  }

  Future<void> toggleStatus(String id) async {
    try {
      await _repo.toggleStatus(id);
      _invalidateCaches();
      await loadEvents();
    } catch (e) {
      // Optimistically toggle state in current list if available
      final currentList = state.valueOrNull;
      if (currentList != null) {
        final updated = currentList.map((ev) {
          if (ev.id == id) {
            return ev.copyWith(isActive: !ev.isActive);
          }
          return ev;
        }).toList();
        state = AsyncValue.data(updated);
      }
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    await _repo.deleteEvent(id);
    _invalidateCaches();
    await loadEvents();
  }

  void _invalidateCaches() {
    _ref.invalidate(calendarEventsForMonthProvider);
    _ref.invalidate(calendarEventsForYearProvider);
  }
}

final adminCalendarEventsProvider = StateNotifierProvider<
    AdminCalendarEventsNotifier, AsyncValue<List<CalendarEventModel>>>((ref) {
  final repo = ref.watch(calendarEventRepositoryProvider);
  return AdminCalendarEventsNotifier(repo, ref);
});
