import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final connectivityStatusProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.onConnectivityChanged;
});

class ConnectivityMonitor {
  final Connectivity _connectivity;

  ConnectivityMonitor(this._connectivity);

  Future<bool> hasConnection() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}

final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return ConnectivityMonitor(connectivity);
});
