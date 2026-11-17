// lib/features/calendar/presentation/providers/ethiopian_calendar_notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/data/ethiopian_calendar_notification_service.dart';

final ethiopianCalendarNotificationEnabledProvider =
    StateNotifierProvider<EthiopianCalendarNotificationNotifier, bool>((ref) {
  return EthiopianCalendarNotificationNotifier();
});

class EthiopianCalendarNotificationNotifier extends StateNotifier<bool> {
  EthiopianCalendarNotificationNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    final enabled = await EthiopianCalendarNotificationService.isEnabled();
    state = enabled;
  }

  /// Toggles the notification preference.
  /// Returns `true` if operation was successful, or `false` if permission was denied.
  Future<bool> setEnabled(bool enabled) async {
    final success =
        await EthiopianCalendarNotificationService.setEnabled(enabled);
    state = await EthiopianCalendarNotificationService.isEnabled();
    return success;
  }

  /// Refreshes the state from SharedPreferences.
  Future<void> refresh() async {
    state = await EthiopianCalendarNotificationService.isEnabled();
  }
}
