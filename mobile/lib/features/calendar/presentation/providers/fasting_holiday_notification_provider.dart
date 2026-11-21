// lib/features/calendar/presentation/providers/fasting_holiday_notification_provider.dart
// Riverpod state management for Ethiopian Orthodox fasting and holiday notifications.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/data/fasting_holiday_notification_service.dart';

class FastingHolidayNotificationState {
  final bool isEnabled;
  final TimeOfDay time1;
  final TimeOfDay time2;
  final bool isLoading;

  const FastingHolidayNotificationState({
    this.isEnabled = false,
    this.time1 = const TimeOfDay(
      hour: FastingHolidayNotificationService.defaultTime1Hour,
      minute: FastingHolidayNotificationService.defaultTime1Minute,
    ),
    this.time2 = const TimeOfDay(
      hour: FastingHolidayNotificationService.defaultTime2Hour,
      minute: FastingHolidayNotificationService.defaultTime2Minute,
    ),
    this.isLoading = false,
  });

  FastingHolidayNotificationState copyWith({
    bool? isEnabled,
    TimeOfDay? time1,
    TimeOfDay? time2,
    bool? isLoading,
  }) {
    return FastingHolidayNotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      time1: time1 ?? this.time1,
      time2: time2 ?? this.time2,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FastingHolidayNotificationNotifier
    extends StateNotifier<FastingHolidayNotificationState> {
  final FastingHolidayNotificationService _service;

  FastingHolidayNotificationNotifier(this._service)
      : super(const FastingHolidayNotificationState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final enabled = await _service.isEnabled();
      final times = await _service.getNotificationTimes();
      state = state.copyWith(
        isEnabled: enabled,
        time1: times.time1,
        time2: times.time2,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
    await _service.setEnabled(enabled);
  }

  Future<void> updateTime1(TimeOfDay time) async {
    state = state.copyWith(time1: time);
    await _service.setNotificationTimes(time1: time);
  }

  Future<void> updateTime2(TimeOfDay time) async {
    state = state.copyWith(time2: time);
    await _service.setNotificationTimes(time2: time);
  }

  Future<void> refresh() async {
    await _service.scheduleUpcomingNotifications();
  }

  Future<void> sendTestNotification() async {
    await _service.showTestNotification();
  }
}

final fastingHolidayNotificationProvider = StateNotifierProvider<
    FastingHolidayNotificationNotifier, FastingHolidayNotificationState>((ref) {
  final service = ref.watch(fastingHolidayNotificationServiceProvider);
  return FastingHolidayNotificationNotifier(service);
});
