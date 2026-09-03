// lib/core/network/connectivity_service.dart
// Global connectivity and actual network reachability monitor.

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mobile/app/env/env.dart';

enum ConnectivityStatus { online, offline }

enum NetworkConnectionType { wifi, mobile, ethernet, other, none, unknown }

class ConnectivityState {
  final ConnectivityStatus status;
  final NetworkConnectionType connectionType;
  final bool isInitialized;
  final bool isReachable;

  const ConnectivityState({
    this.status = ConnectivityStatus.online,
    this.connectionType = NetworkConnectionType.unknown,
    this.isInitialized = false,
    this.isReachable = true,
  });

  bool get isOnline => status == ConnectivityStatus.online && isReachable;
  bool get isOffline => !isOnline;
  bool get isWifi => connectionType == NetworkConnectionType.wifi;
  bool get isMobile => connectionType == NetworkConnectionType.mobile;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    NetworkConnectionType? connectionType,
    bool? isInitialized,
    bool? isReachable,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      connectionType: connectionType ?? this.connectionType,
      isInitialized: isInitialized ?? this.isInitialized,
      isReachable: isReachable ?? this.isReachable,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity;
  final Dio _dio;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _reachabilityDebounce;
  final List<void Function(bool isOnline)> _listeners = [];

  ConnectivityNotifier(this._connectivity, [Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
              ),
            ),
        super(const ConnectivityState()) {
    _init();
  }

  void addOnlineStatusListener(void Function(bool isOnline) listener) {
    _listeners.add(listener);
  }

  void removeOnlineStatusListener(void Function(bool isOnline) listener) {
    _listeners.remove(listener);
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final type = _typeFromResults(results);
      final rawStatus = _statusFromResults(results);

      bool reachable = false;
      if (rawStatus == ConnectivityStatus.online) {
        reachable = await checkActualReachability();
      }

      final finalStatus =
          (rawStatus == ConnectivityStatus.online && reachable)
              ? ConnectivityStatus.online
              : ConnectivityStatus.offline;

      state = ConnectivityState(
        status: finalStatus,
        connectionType: type,
        isInitialized: true,
        isReachable: reachable,
      );
    } catch (_) {
      state = const ConnectivityState(
        status: ConnectivityStatus.offline,
        connectionType: NetworkConnectionType.none,
        isInitialized: true,
        isReachable: false,
      );
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final newType = _typeFromResults(results);
    final rawStatus = _statusFromResults(results);

    _reachabilityDebounce?.cancel();

    if (rawStatus == ConnectivityStatus.offline) {
      final wasOnline = state.isOnline;
      state = state.copyWith(
        status: ConnectivityStatus.offline,
        connectionType: NetworkConnectionType.none,
        isReachable: false,
      );
      if (wasOnline) {
        _notifyListeners(false);
      }
      return;
    }

    // Debounce reachability probe to prevent hammering during interface changes
    _reachabilityDebounce = Timer(const Duration(milliseconds: 500), () async {
      final reachable = await checkActualReachability();
      final finalStatus = reachable
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;

      final wasOnline = state.isOnline;
      state = state.copyWith(
        status: finalStatus,
        connectionType: newType,
        isReachable: reachable,
      );

      final nowOnline = state.isOnline;
      if (!wasOnline && nowOnline) {
        _notifyListeners(true);
      } else if (wasOnline && !nowOnline) {
        _notifyListeners(false);
      }
    });
  }

  Future<bool> checkActualReachability() async {
    if (kIsWeb) {
      return true; // Browser handles reachability
    }

    try {
      // 1. Try server health endpoint first
      final uri = Uri.tryParse(Env.apiBaseUrl);
      if (uri != null && uri.host.isNotEmpty) {
        final healthUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/api/health';
        final response = await _dio.get(
          healthUrl,
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        if (response.statusCode != null && response.statusCode! < 500) {
          return true;
        }
      }
    } catch (_) {
      // Server may be down or unreachable; test general internet reachability
    }

    try {
      // 2. Fallback to lightweight public probe (Cloudflare / Google 204)
      final response = await _dio.get(
        'https://www.google.com/generate_204',
        options: Options(
          validateStatus: (status) => status == 204 || (status != null && status < 400),
        ),
      );
      return response.statusCode == 204 || (response.statusCode != null && response.statusCode! < 400);
    } catch (_) {
      try {
        final result = await InternetAddress.lookup('dns.google')
            .timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  void _notifyListeners(bool isOnline) {
    for (final listener in List.of(_listeners)) {
      try {
        listener(isOnline);
      } catch (e) {
        debugPrint('[ConnectivityService] Listener error: $e');
      }
    }
  }

  ConnectivityStatus _statusFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }

  NetworkConnectionType _typeFromResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return NetworkConnectionType.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return NetworkConnectionType.mobile;
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return NetworkConnectionType.ethernet;
    }
    if (results.contains(ConnectivityResult.other)) {
      return NetworkConnectionType.other;
    }
    if (results.every((r) => r == ConnectivityResult.none)) {
      return NetworkConnectionType.none;
    }
    return NetworkConnectionType.unknown;
  }

  @override
  void dispose() {
    _reachabilityDebounce?.cancel();
    _subscription?.cancel();
    _listeners.clear();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier(Connectivity());
});
