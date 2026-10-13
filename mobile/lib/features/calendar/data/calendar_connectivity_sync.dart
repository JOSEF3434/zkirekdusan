// lib/features/calendar/data/calendar_connectivity_sync.dart
// Real-time connectivity and lifecycle monitor that triggers calendar sync

import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/data/calendar_sync_service.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';

final calendarConnectivitySyncProvider =
    Provider<CalendarConnectivitySync>((ref) {
  final sync = CalendarConnectivitySync(
    ref.watch(calendarSyncServiceProvider),
    ref,
  );
  ref.onDispose(() => sync.dispose());
  return sync;
});

class CalendarConnectivitySync with WidgetsBindingObserver {
  final CalendarSyncService _syncService;
  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;
  bool _isSyncing = false;
  DateTime? _lastSyncAttempt;

  CalendarConnectivitySync(this._syncService, this._ref);

  /// Initialize connectivity and lifecycle monitoring and auto-sync
  Future<void> initialize() async {
    developer.log(
      '📡 Initializing connectivity and lifecycle sync...',
      name: 'ConnectivitySync',
    );

    // Register lifecycle observer for AppLifecycleState.resumed
    WidgetsBinding.instance.addObserver(this);

    // Check initial connectivity
    final connectivity = Connectivity();
    final initialStatus = await connectivity.checkConnectivity();
    _wasOffline = _isOffline(initialStatus);

    // Listen to connectivity changes
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // If online initially, trigger sync
    if (!_wasOffline) {
      _triggerSync();
    }

    developer.log(
      '✅ Connectivity sync initialized (initially ${_wasOffline ? "offline" : "online"})',
      name: 'ConnectivitySync',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      developer.log(
        '📱 App resumed, triggering automatic calendar sync check...',
        name: 'ConnectivitySync',
      );
      _triggerSync();
    }
  }

  /// Handle connectivity state changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOffline = _isOffline(results);

    developer.log(
      '📡 Connectivity changed: ${results.join(", ")} (offline: $isOffline)',
      name: 'ConnectivitySync',
    );

    // Trigger sync when transitioning from offline to online
    if (_wasOffline && !isOffline) {
      developer.log(
        '🌐 Back online! Triggering immediate sync...',
        name: 'ConnectivitySync',
      );
      _triggerSync();
    }

    _wasOffline = isOffline;
  }

  /// Trigger sync with debouncing
  void _triggerSync() {
    // Prevent multiple simultaneous syncs
    if (_isSyncing) {
      developer.log(
        '⏳ Sync already in progress, skipping...',
        name: 'ConnectivitySync',
      );
      return;
    }

    // Debounce: wait at least 5 seconds between sync attempts
    final now = DateTime.now();
    if (_lastSyncAttempt != null &&
        now.difference(_lastSyncAttempt!).inSeconds < 5) {
      developer.log(
        '⏰ Too soon since last sync attempt, skipping...',
        name: 'ConnectivitySync',
      );
      return;
    }

    _lastSyncAttempt = now;
    _isSyncing = true;

    // Perform sync asynchronously
    _syncService.performSync().then((result) {
      _isSyncing = false;
      if (result.isSuccess) {
        developer.log('✅ Auto-sync completed', name: 'ConnectivitySync');
      } else {
        developer.log(
          '⚠️ Auto-sync completed with issues: ${result.errorMessage}',
          name: 'ConnectivitySync',
        );
      }
      // On Web, Drift is a no-op so notes live only in _webCache.
      // Invalidate the FutureProviders so the UI re-reads the populated cache.
      if (kIsWeb && result.notesPulled > 0) {
        _ref.invalidate(calendarNotesForMonthProvider);
        _ref.invalidate(calendarNotesForDateProvider);
        developer.log(
          '🔄 Invalidated note providers after Web sync (${result.notesPulled} notes)',
          name: 'ConnectivitySync',
        );
      }
    }).catchError((error) {
      _isSyncing = false;
      developer.log(
        '❌ Auto-sync error: $error',
        name: 'ConnectivitySync',
        error: error,
      );
    });
  }

  /// Check if device is offline
  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  /// Dispose resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    developer.log('🔌 Connectivity sync disposed', name: 'ConnectivitySync');
  }
}
