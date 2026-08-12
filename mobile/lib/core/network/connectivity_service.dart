// lib/core/network/connectivity_service.dart
// Global connectivity monitor.
// Distinguishes between:
//   - No network interface (definitely offline)
//   - Network interface present but backend may be unreachable
// Shows a non-blocking banner on state transitions only (not on every build).

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityState {
  final ConnectivityStatus status;
  final bool isInitialized;

  const ConnectivityState({
    this.status = ConnectivityStatus.online,
    this.isInitialized = false,
  });

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    bool? isInitialized,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier(this._connectivity) : super(const ConnectivityState()) {
    _init();
  }

  Future<void> _init() async {
    // Check initial state
    final results = await _connectivity.checkConnectivity();
    final status = _statusFromResults(results);
    state = ConnectivityState(status: status, isInitialized: true);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final newStatus = _statusFromResults(results);
      if (newStatus != state.status) {
        state = state.copyWith(status: newStatus);
      }
    });
  }

  ConnectivityStatus _statusFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      return ConnectivityNotifier(Connectivity());
    });
