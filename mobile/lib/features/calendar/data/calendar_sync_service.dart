// lib/features/calendar/data/calendar_sync_service.dart
// Background sync service for calendar notes

import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';

final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  return CalendarSyncService(ref.watch(calendarOfflineRepositoryProvider));
});

class CalendarSyncService {
  final CalendarOfflineRepository _repository;

  CalendarSyncService(this._repository);

  /// Perform a full sync operation
  /// Returns true if successful, false if failed
  Future<bool> performSync({
    bool uploadOnly = false,
    bool downloadOnly = false,
  }) async {
    developer.log('🔄 Starting calendar sync...', name: 'CalendarSync');

    try {
      if (!downloadOnly) {
        // Step 1: Push unsynced notes to server
        developer.log('⬆️ Pushing unsynced notes...', name: 'CalendarSync');
        await _repository.pushUnsyncedNotes();
        developer.log('✅ Push complete', name: 'CalendarSync');
      }

      if (!uploadOnly) {
        // Step 2: Pull updates from server
        developer.log('⬇️ Pulling server updates...', name: 'CalendarSync');

        // Sync current month
        final now = DateTime.now();
        final currentEthiopianYear = now.year - 7; // Rough conversion
        final currentEthiopianMonth = now.month;

        await _repository.syncNotesFromServer(
          year: currentEthiopianYear,
          month: currentEthiopianMonth,
        );

        // Optionally sync adjacent months for better offline experience
        await _repository.syncNotesFromServer(
          year: currentEthiopianYear,
          month: currentEthiopianMonth - 1,
        );

        await _repository.syncNotesFromServer(
          year: currentEthiopianYear,
          month: currentEthiopianMonth + 1,
        );

        developer.log('✅ Pull complete', name: 'CalendarSync');
      }

      developer.log('✅ Sync completed successfully', name: 'CalendarSync');
      return true;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Sync failed: $e',
        name: 'CalendarSync',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Perform a quick sync (current month only)
  Future<bool> performQuickSync() async {
    developer.log('⚡ Quick sync started', name: 'CalendarSync');

    try {
      // Only push local changes
      await _repository.pushUnsyncedNotes();

      // Only pull current month
      final now = DateTime.now();
      final currentEthiopianYear = now.year - 7;
      final currentEthiopianMonth = now.month;

      await _repository.syncNotesFromServer(
        year: currentEthiopianYear,
        month: currentEthiopianMonth,
      );

      developer.log('✅ Quick sync complete', name: 'CalendarSync');
      return true;
    } catch (e) {
      developer.log('❌ Quick sync failed: $e', name: 'CalendarSync');
      return false;
    }
  }

  /// Check if sync is needed
  Future<bool> isSyncNeeded() async {
    // This is a simplified check
    // In production, you'd check:
    // - Last sync timestamp
    // - Pending sync queue items
    // - Network availability
    return true;
  }
}
