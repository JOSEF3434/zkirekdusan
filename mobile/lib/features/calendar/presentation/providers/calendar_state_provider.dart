// lib/features/calendar/presentation/providers/calendar_state_provider.dart
import 'package:abushakir/abushakir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';

/// Calendar state
class CalendarState {
  final int year;
  final int month;
  final EtDatetime? selectedDate;
  final EtDatetime today;

  CalendarState({
    required this.year,
    required this.month,
    this.selectedDate,
    required this.today,
  });

  CalendarState copyWith({
    int? year,
    int? month,
    EtDatetime? selectedDate,
    bool clearSelection = false,
  }) {
    return CalendarState(
      year: year ?? this.year,
      month: month ?? this.month,
      selectedDate: clearSelection ? null : (selectedDate ?? this.selectedDate),
      today: today,
    );
  }
}

/// Calendar state notifier
class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier()
      : super(
          CalendarState(
            year: EthiopianCalendarUtil.now().year,
            month: EthiopianCalendarUtil.now().month,
            today: EthiopianCalendarUtil.now(),
          ),
        );

  /// Navigate to previous month
  void previousMonth() {
    int newYear = state.year;
    int newMonth = state.month - 1;

    if (newMonth < 1) {
      newMonth = 13;
      newYear -= 1;
    }

    state = state.copyWith(year: newYear, month: newMonth);
  }

  /// Navigate to next month
  void nextMonth() {
    int newYear = state.year;
    int newMonth = state.month + 1;

    if (newMonth > 13) {
      newMonth = 1;
      newYear += 1;
    }

    state = state.copyWith(year: newYear, month: newMonth);
  }

  /// Navigate to today's month
  void goToToday() {
    final now = EthiopianCalendarUtil.now();
    state = state.copyWith(
      year: now.year,
      month: now.month,
      selectedDate: now,
    );
  }

  /// Select a specific date
  void selectDate(int year, int month, int day) {
    final selected = EthiopianCalendarUtil.create(year, month, day);
    state = state.copyWith(selectedDate: selected);
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }
}

/// Calendar state provider
final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});
