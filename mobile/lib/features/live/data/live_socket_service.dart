// lib/features/live/data/live_socket_service.dart
// Manages the Socket.IO connection to the backend /live namespace.
// Provides strongly-typed Dart Streams for all server→client events.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mobile/app/env/env.dart';
import 'package:mobile/core/network/auth_interceptor.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/domain/stream_health_model.dart';

// ─── Event name constants (mirror backend LIVE_EVENTS) ───────────────────────

class LiveEvents {
  // Client → Server
  static const joinStream = 'stream:join';
  static const leaveStream = 'stream:leave';
  static const sendChat = 'chat:send';
  static const reactChat = 'chat:react';
  static const deleteChat = 'chat:delete';
  static const pinChat = 'chat:pin';
  static const pollVote = 'poll:vote';
  static const sendReaction = 'reaction:send';
  static const qualityReport = 'quality:report';

  // Server → Client
  static const streamStarted = 'stream:started';
  static const streamEnded = 'stream:ended';
  static const streamUpdated = 'stream:updated';
  static const streamError = 'stream:error';
  static const chatMessage = 'chat:message';
  static const chatDeleted = 'chat:deleted';
  static const chatPinned = 'chat:pinned';
  static const chatReaction = 'chat:reaction';
  static const viewerCount = 'viewer:count';
  static const reactionBroadcast = 'reaction:broadcast';
  static const modMuted = 'mod:muted';
  static const modBanned = 'mod:banned';
  static const qualityRecommend = 'quality:recommend';
  static const streamHealth = 'stream:health';
  static const error = 'error';
}

// ─── Stream ended payload ─────────────────────────────────────────────────────

class StreamEndedEvent {
  final String streamId;
  final String? vodUrl;
  final int? duration;

  const StreamEndedEvent({
    required this.streamId,
    this.vodUrl,
    this.duration,
  });

  factory StreamEndedEvent.fromJson(Map<String, dynamic> json) =>
      StreamEndedEvent(
        streamId: json['streamId'] as String? ?? '',
        vodUrl: json['vodUrl'] as String?,
        duration: json['duration'] as int?,
      );
}

// ─── Connection state ─────────────────────────────────────────────────────────

enum SocketConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
  failed,
}

// ─── LiveSocketService ────────────────────────────────────────────────────────

class LiveSocketService {
  io.Socket? _socket;
  String? _currentToken;

  // Connection state
  final _connectionStateCtrl =
      StreamController<SocketConnectionState>.broadcast();
  Stream<SocketConnectionState> get connectionState =>
      _connectionStateCtrl.stream;

  // Typed event streams
  final _chatMessageCtrl =
      StreamController<ChatMessageDto>.broadcast();
  Stream<ChatMessageDto> get onChatMessage => _chatMessageCtrl.stream;

  final _chatDeletedCtrl =
      StreamController<String>.broadcast(); // messageId
  Stream<String> get onChatDeleted => _chatDeletedCtrl.stream;

  final _chatPinnedCtrl =
      StreamController<ChatMessageDto>.broadcast();
  Stream<ChatMessageDto> get onChatPinned => _chatPinnedCtrl.stream;

  final _chatReactionCtrl =
      StreamController<ChatReactionEvent>.broadcast();
  Stream<ChatReactionEvent> get onChatReaction => _chatReactionCtrl.stream;

  final _viewerCountCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onViewerCount => _viewerCountCtrl.stream;

  final _streamStartedCtrl =
      StreamController<LiveStreamDto>.broadcast();
  Stream<LiveStreamDto> get onStreamStarted => _streamStartedCtrl.stream;

  final _streamEndedCtrl =
      StreamController<StreamEndedEvent>.broadcast();
  Stream<StreamEndedEvent> get onStreamEnded => _streamEndedCtrl.stream;

  final _streamUpdatedCtrl =
      StreamController<LiveStreamDto>.broadcast();
  Stream<LiveStreamDto> get onStreamUpdated => _streamUpdatedCtrl.stream;

  final _streamHealthCtrl =
      StreamController<StreamHealthDto>.broadcast();
  Stream<StreamHealthDto> get onStreamHealth => _streamHealthCtrl.stream;

  final _reactionBroadcastCtrl =
      StreamController<ReactionBroadcastEvent>.broadcast();
  Stream<ReactionBroadcastEvent> get onReactionBroadcast =>
      _reactionBroadcastCtrl.stream;

  final _errorCtrl = StreamController<String>.broadcast();
  Stream<String> get onError => _errorCtrl.stream;

  final _qualityRecommendCtrl =
      StreamController<String>.broadcast(); // quality string
  Stream<String> get onQualityRecommend => _qualityRecommendCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  // ─── Connect ───────────────────────────────────────────────────────────────

  Future<void> connect(String token) async {
    if (_socket != null && _socket!.connected && token == _currentToken) return;

    // Disconnect existing if any
    _socket?.disconnect();
    _socket?.dispose();

    _currentToken = token;
    _connectionStateCtrl.add(SocketConnectionState.connecting);

    final baseUrl = Env.apiBaseUrl.replaceAll('/api', '');

    _socket = io.io(
      '$baseUrl/live',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .setQuery({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(30000)
          .build(),
    );

    _bindEvents();
    _socket!.connect();
  }

  void _bindEvents() {
    final s = _socket!;

    s.onConnect((_) {
      _connectionStateCtrl.add(SocketConnectionState.connected);
    });

    s.onDisconnect((_) {
      _connectionStateCtrl.add(SocketConnectionState.disconnected);
    });

    s.onReconnecting((_) {
      _connectionStateCtrl.add(SocketConnectionState.reconnecting);
    });

    s.onConnectError((e) {
      _connectionStateCtrl.add(SocketConnectionState.failed);
    });

    // Chat
    s.on(LiveEvents.chatMessage, (data) {
      try {
        final json = _toMap(data);
        _chatMessageCtrl.add(ChatMessageDto.fromJson(json));
      } catch (_) {}
    });

    s.on(LiveEvents.chatDeleted, (data) {
      try {
        final json = _toMap(data);
        final id = json['messageId'] as String?;
        if (id != null) _chatDeletedCtrl.add(id);
      } catch (_) {}
    });

    s.on(LiveEvents.chatPinned, (data) {
      try {
        final json = _toMap(data);
        final msgJson = json['message'] as Map<String, dynamic>?;
        if (msgJson != null) {
          _chatPinnedCtrl.add(ChatMessageDto.fromJson(msgJson));
        }
      } catch (_) {}
    });

    s.on(LiveEvents.chatReaction, (data) {
      try {
        _chatReactionCtrl.add(ChatReactionEvent.fromJson(_toMap(data)));
      } catch (_) {}
    });

    // Viewer count
    s.on(LiveEvents.viewerCount, (data) {
      try {
        _viewerCountCtrl.add(_toMap(data));
      } catch (_) {}
    });

    // Stream lifecycle
    s.on(LiveEvents.streamStarted, (data) {
      try {
        _streamStartedCtrl.add(LiveStreamDto.fromJson(_toMap(data)));
      } catch (_) {}
    });

    s.on(LiveEvents.streamEnded, (data) {
      try {
        _streamEndedCtrl.add(StreamEndedEvent.fromJson(_toMap(data)));
      } catch (_) {}
    });

    s.on(LiveEvents.streamUpdated, (data) {
      try {
        _streamUpdatedCtrl.add(LiveStreamDto.fromJson(_toMap(data)));
      } catch (_) {}
    });

    // Health
    s.on(LiveEvents.streamHealth, (data) {
      try {
        _streamHealthCtrl.add(StreamHealthDto.fromJson(_toMap(data)));
      } catch (_) {}
    });

    // Reactions
    s.on(LiveEvents.reactionBroadcast, (data) {
      try {
        _reactionBroadcastCtrl
            .add(ReactionBroadcastEvent.fromJson(_toMap(data)));
      } catch (_) {}
    });

    // Quality
    s.on(LiveEvents.qualityRecommend, (data) {
      try {
        final q = _toMap(data)['quality'] as String?;
        if (q != null) _qualityRecommendCtrl.add(q);
      } catch (_) {}
    });

    // Errors
    s.on(LiveEvents.error, (data) {
      try {
        final msg = _toMap(data)['message'] as String? ?? 'Socket error';
        _errorCtrl.add(msg);
      } catch (_) {}
    });
  }

  // ─── Room operations ───────────────────────────────────────────────────────

  void joinStream(String streamId) {
    _socket?.emit(LiveEvents.joinStream, {'streamId': streamId});
  }

  void leaveStream(String streamId) {
    _socket?.emit(LiveEvents.leaveStream, {'streamId': streamId});
  }

  void sendChat({
    required String streamId,
    required String content,
    String type = 'TEXT',
  }) {
    _socket?.emit(LiveEvents.sendChat, {
      'streamId': streamId,
      'content': content,
      'type': type,
    });
  }

  void sendReaction({required String streamId, required String emoji}) {
    _socket?.emit(LiveEvents.sendReaction, {
      'streamId': streamId,
      'emoji': emoji,
    });
  }

  void reactToChat({
    required String streamId,
    required String messageId,
    required String emoji,
  }) {
    _socket?.emit(LiveEvents.reactChat, {
      'streamId': streamId,
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  void deleteChat({required String streamId, required String messageId}) {
    _socket?.emit(LiveEvents.deleteChat, {
      'streamId': streamId,
      'messageId': messageId,
    });
  }

  void pinChat({
    required String streamId,
    required String messageId,
    required bool pin,
  }) {
    _socket?.emit(LiveEvents.pinChat, {
      'streamId': streamId,
      'messageId': messageId,
      'pin': pin,
    });
  }

  void sendQualityReport({
    required String streamId,
    required String quality,
    required double bandwidth,
  }) {
    _socket?.emit(LiveEvents.qualityReport, {
      'streamId': streamId,
      'quality': quality,
      'bandwidth': bandwidth,
    });
  }

  // ─── Disconnect ────────────────────────────────────────────────────────────

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentToken = null;
    _connectionStateCtrl.add(SocketConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionStateCtrl.close();
    _chatMessageCtrl.close();
    _chatDeletedCtrl.close();
    _chatPinnedCtrl.close();
    _chatReactionCtrl.close();
    _viewerCountCtrl.close();
    _streamStartedCtrl.close();
    _streamEndedCtrl.close();
    _streamUpdatedCtrl.close();
    _streamHealthCtrl.close();
    _reactionBroadcastCtrl.close();
    _errorCtrl.close();
    _qualityRecommendCtrl.close();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {};
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final liveSocketServiceProvider = Provider<LiveSocketService>((ref) {
  final service = LiveSocketService();
  ref.onDispose(service.dispose);
  return service;
});
