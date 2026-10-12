// lib/features/calendar/data/calendar_sync_service.dart
// Background sync service for calendar notes

import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
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
        // Step 2: Pull updates from server using single request per Ethiopian year
        developer.log(
          '⬇️ Pulling server updates (3 full Ethiopian years)...',
          name: 'CalendarSync',
        );

        final etNow = EthiopianCalendarUtil.now();
        final currentEthiopianYear = etNow.year;
        final yearsToSync = [
          currentEthiopianYear,
          currentEthiopianYear - 1,
          currentEthiopianYear + 1,
        ];

        for (int i = 0; i < yearsToSync.length; i++) {
          final year = yearsToSync[i];
          if (isThrottled) break;

          try {
            // Omitting month queries the whole Ethiopian year in a single request,
            // avoiding the 39-request storm that caused HTTP 429 errors.
            final count = await _repository.syncNotesFromServer(year: year);
            notesPulled += count;
            developer.log(
              '✓ Synced full Ethiopian year $year ($count notes)',
              name: 'CalendarSync',
            );
          } on DioException catch (dioErr) {
            if (dioErr.response?.statusCode == 429) {
              isThrottled = true;
              pullFailures++;
              errorMessage = 'Rate limited by server (HTTP 429)';
              developer.log(
                '⚠️ Throttled (429) on year $year - aborting subsequent pulls',
                name: 'CalendarSync',
              );
              break;
            } else {
              pullFailures++;
              errorMessage ??= dioErr.toString();
              developer.log(
                '⚠️ Failed to sync year $year: $dioErr',
                name: 'CalendarSync',
              );
            }
          } catch (e) {
            pullFailures++;
            errorMessage ??= e.toString();
            developer.log(
              '⚠️ Failed to sync year $year: $e',
              name: 'CalendarSync',
            );
          }

          // Gentle backoff delay between year requests
          if (i < yearsToSync.length - 1) {
            await Future.delayed(const Duration(milliseconds: 150));
          }
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

      // 2. Only pull current Ethiopian month if not throttled
      if (!isThrottled) {
        final etNow = EthiopianCalendarUtil.now();
        try {
          final count = await _repository.syncNotesFromServer(
            year: etNow.year,
            month: etNow.month,
          );
          notesPulled = count;
          developer.log(
            '✓ Quick sync pulled month ${etNow.month}/${etNow.year} ($count notes)',
            name: 'CalendarSync',
          );
        } on DioException catch (dioErr) {
          if (dioErr.response?.statusCode == 429) {
            isThrottled = true;
            pullFailures++;
            errorMessage = 'Rate limited by server (HTTP 429)';
          } else {
            pullFailures++;
            errorMessage ??= dioErr.toString();
          }
        } catch (e) {
          pullFailures++;
          errorMessage ??= e.toString();
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
