// lib/features/notifications/data/notification_socket_service.dart
// Centralized Socket.IO client for the /notifications namespace.
// Handles: auth, reconnection with backoff, duplicate event protection,
// clean disconnection on logout/dispose.

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mobile/app/env/env.dart';
import 'package:mobile/features/notifications/domain/notification_model.dart';

final notificationSocketServiceProvider = Provider<NotificationSocketService>((
  ref,
) {
  final service = NotificationSocketService();
  ref.onDispose(service.dispose);
  return service;
});

class NotificationSocketService {
  io.Socket? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 10;
  static const _baseBackoffMs = 1000;

  final _controller = StreamController<NotificationResponseDto>.broadcast();
  final _seenIds = <String>{};

  Stream<NotificationResponseDto> get notificationStream => _controller.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Call after authentication — connects to /notifications namespace.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token == null) {
      debugPrint('[NotificationSocket] No token — skipping connection');
      return;
    }

    final baseUrl = Env.apiBaseUrl.replaceFirst('/api', '');
    _socket = io.io(
      '$baseUrl/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[NotificationSocket] Connected to /notifications');
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
    });

    _socket!.on('notification:new', (data) {
      _handleIncomingNotification(data);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[NotificationSocket] Disconnected');
      _scheduleReconnect();
    });

    _socket!.onError((err) {
      debugPrint('[NotificationSocket] Error: $err');
    });

    _socket!.connect();
  }

  void _handleIncomingNotification(dynamic data) {
    try {
      final Map<String, dynamic> json;
      if (data is Map<String, dynamic>) {
        json = data;
      } else if (data is Map) {
        json = data.cast<String, dynamic>();
      } else {
        return;
      }

      final id = json['id'] as String?;
      if (id == null || id.isEmpty) return;

      // Deduplicate by seen IDs
      if (_seenIds.contains(id)) return;
      _seenIds.add(id);

      // Trim seen set to avoid unbounded growth
      if (_seenIds.length > 500) {
        _seenIds.clear();
      }

      final notification = NotificationResponseDto.fromJson(json);
      if (!_controller.isClosed) {
        _controller.add(notification);
      }
    } catch (e) {
      debugPrint('[NotificationSocket] Parse error: $e');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[NotificationSocket] Max reconnect attempts reached');
      return;
    }
    _reconnectTimer?.cancel();
    final backoff = _baseBackoffMs * pow(2, _reconnectAttempts).toInt();
    final clamped = min(backoff, 30000);
    _reconnectAttempts++;
    debugPrint(
      '[NotificationSocket] Reconnecting in ${clamped}ms (attempt $_reconnectAttempts)',
    );
    _reconnectTimer = Timer(Duration(milliseconds: clamped), () async {
      await connect();
    });
  }

  /// Disconnect cleanly — called on logout or app dispose.
  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _reconnectAttempts = 0;
    _seenIds.clear();
    debugPrint('[NotificationSocket] Disconnected cleanly');
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
