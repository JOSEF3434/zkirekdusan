// lib/features/calendar/data/calendar_sync_service.dart
// Background sync service for calendar notes

import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';

final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  return CalendarSyncService(ref.watch(calendarOfflineRepositoryProvider));
});

/// Structured result of a calendar synchronization operation
class CalendarSyncResult {
  final bool isSuccess;
  final int notesPushed;
  final int notesPulled;
  final int pushFailures;
  final int pullFailures;
  final bool isThrottled;
  final String? errorMessage;

  const CalendarSyncResult({
    required this.isSuccess,
    this.notesPushed = 0,
    this.notesPulled = 0,
    this.pushFailures = 0,
    this.pullFailures = 0,
    this.isThrottled = false,
    this.errorMessage,
  });

  bool get hasErrors =>
      pushFailures > 0 || pullFailures > 0 || isThrottled || !isSuccess;

  @override
  String toString() {
    return 'CalendarSyncResult(isSuccess: $isSuccess, pushed: $notesPushed, pulled: $notesPulled, pushFailures: $pushFailures, pullFailures: $pullFailures, isThrottled: $isThrottled, error: $errorMessage)';
  }
}

class CalendarSyncService {
  final CalendarOfflineRepository _repository;
  Future<CalendarSyncResult>? _inFlightSync;

  CalendarSyncService(this._repository);

  /// Perform a full sync operation with single-flight deduplication
  Future<CalendarSyncResult> performSync({
    bool uploadOnly = false,
    bool downloadOnly = false,
  }) {
    if (_inFlightSync != null) {
      developer.log(
        '🔄 Calendar sync already in progress, returning active task',
        name: 'CalendarSync',
      );
      return _inFlightSync!;
    }

    _inFlightSync = _executeSync(
      uploadOnly: uploadOnly,
      downloadOnly: downloadOnly,
    ).whenComplete(() {
      _inFlightSync = null;
    });
    return _inFlightSync!;
  }

  /// Perform a quick sync (push pending notes and fetch current Ethiopian month)
  Future<CalendarSyncResult> performQuickSync() {
    if (_inFlightSync != null) {
      developer.log(
        '🔄 Calendar sync already in progress, returning active task',
        name: 'CalendarSync',
      );
      return _inFlightSync!;
    }

    _inFlightSync = _executeQuickSync().whenComplete(() {
      _inFlightSync = null;
    });
    return _inFlightSync!;
  }

  Future<CalendarSyncResult> _executeSync({
    bool uploadOnly = false,
    bool downloadOnly = false,
  }) async {
    developer.log('🔄 Starting calendar full sync...', name: 'CalendarSync');

    int notesPushed = 0;
    int pushFailures = 0;
    int notesPulled = 0;
    int pullFailures = 0;
    bool isThrottled = false;
    String? errorMessage;

    try {
      if (!downloadOnly) {
        // Step 1: Push unsynced notes to server
        developer.log('⬆️ Pushing unsynced notes...', name: 'CalendarSync');
        final pushResult = await _repository.pushUnsyncedNotes();
        notesPushed = pushResult.pushedCount;
        pushFailures = pushResult.failedCount + pushResult.permanentFailures;
        isThrottled = pushResult.isThrottled;
        if (pushResult.lastError != null) {
          errorMessage = pushResult.lastError;
        }
        developer.log(
          '✅ Push complete: $notesPushed pushed, $pushFailures failed (throttled: $isThrottled)',
          name: 'CalendarSync',
        );
      }

      if (!uploadOnly && !isThrottled) {
        // Step 2: Pull updates from server using rolling one-Ethiopian-year window covering all 13 months
        developer.log(
          '⬇️ Pulling server updates (rolling 1-Ethiopian-year window)...',
          name: 'CalendarSync',
        );

        final rollingResult = await _repository.syncRollingWindow();
        notesPulled = rollingResult.newRecords + rollingResult.updatedRecords;
        if (!rollingResult.isSuccess) {
          pullFailures++;
          isThrottled = rollingResult.isThrottled;
          errorMessage = rollingResult.errorMessage;
        }
      }

      final isSuccess = pushFailures == 0 && pullFailures == 0 && !isThrottled;
      developer.log(
        isSuccess
            ? '✅ Full sync completed successfully'
            : '⚠️ Full sync completed with issues (throttled: $isThrottled, pushFailures: $pushFailures, pullFailures: $pullFailures)',
        name: 'CalendarSync',
      );

      return CalendarSyncResult(
        isSuccess: isSuccess,
        notesPushed: notesPushed,
        notesPulled: notesPulled,
        pushFailures: pushFailures,
        pullFailures: pullFailures,
        isThrottled: isThrottled,
        errorMessage: errorMessage,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Full sync unexpected failure: $e',
        name: 'CalendarSync',
        error: e,
        stackTrace: stackTrace,
      );
      return CalendarSyncResult(
        isSuccess: false,
        notesPushed: notesPushed,
        notesPulled: notesPulled,
        pushFailures: pushFailures + 1,
        pullFailures: pullFailures,
        isThrottled: isThrottled,
        errorMessage: e.toString(),
      );
    }
  }

  Future<CalendarSyncResult> _executeQuickSync() async {
    developer.log('⚡ Quick sync started', name: 'CalendarSync');

    int notesPushed = 0;
    int pushFailures = 0;
    int notesPulled = 0;
    int pullFailures = 0;
    bool isThrottled = false;
    String? errorMessage;

    try {
      // 1. Push local changes
      final pushResult = await _repository.pushUnsyncedNotes();
      notesPushed = pushResult.pushedCount;
      pushFailures = pushResult.failedCount + pushResult.permanentFailures;
      isThrottled = pushResult.isThrottled;
      if (pushResult.lastError != null) {
        errorMessage = pushResult.lastError;
      }

      // 2. Pull incremental updates for the rolling window if not throttled
      if (!isThrottled) {
        final rollingResult = await _repository.syncRollingWindow();
        notesPulled = rollingResult.newRecords + rollingResult.updatedRecords;
        if (!rollingResult.isSuccess) {
          pullFailures++;
          isThrottled = rollingResult.isThrottled;
          errorMessage = rollingResult.errorMessage;
        }
      }

      final isSuccess = pushFailures == 0 && pullFailures == 0 && !isThrottled;
      developer.log(
        isSuccess
            ? '✅ Quick sync completed'
            : '⚠️ Quick sync completed with issues (throttled: $isThrottled, pushFailures: $pushFailures, pullFailures: $pullFailures)',
        name: 'CalendarSync',
      );

      return CalendarSyncResult(
        isSuccess: isSuccess,
        notesPushed: notesPushed,
        notesPulled: notesPulled,
        pushFailures: pushFailures,
        pullFailures: pullFailures,
        isThrottled: isThrottled,
        errorMessage: errorMessage,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Quick sync failed: $e',
        name: 'CalendarSync',
        error: e,
        stackTrace: stackTrace,
      );
      return CalendarSyncResult(
        isSuccess: false,
        notesPushed: notesPushed,
        notesPulled: notesPulled,
        pushFailures: pushFailures + 1,
        pullFailures: pullFailures,
        isThrottled: isThrottled,
        errorMessage: e.toString(),
      );
    }
  }

  /// Check if sync is needed
  Future<bool> isSyncNeeded() async {
    try {
      final unsynced = await _repository.getUnsyncedNotes();
      return unsynced.isNotEmpty;
    } catch (_) {
      return true;
    }
  }
}
