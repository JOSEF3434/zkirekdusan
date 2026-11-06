// lib/features/live/data/live_socket_service.dart
// Manages the Socket.IO connection to the backend /live namespace.
// Provides strongly-typed Dart Streams for all server-to-client events.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mobile/app/env/env.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/domain/stream_health_model.dart';

// Event name constants (mirror backend LIVE_EVENTS)

class LiveEvents {
  // Client to Server
  static const joinStream = 'stream:join';
  static const leaveStream = 'stream:leave';
  static const sendChat = 'chat:send';
  static const reactChat = 'chat:react';
  static const deleteChat = 'chat:delete';
  static const pinChat = 'chat:pin';
  static const pollVote = 'poll:vote';
  static const sendReaction = 'reaction:send';
  static const qualityReport = 'quality:report';

  // Cast - Client to Server
  static const castAnnounce = 'cast:announce';
  static const castCameraOffer = 'cast:camera-offer';
  static const castCameraAnswer = 'cast:camera-answer';
  static const castCameraIce = 'cast:camera-ice';
  static const castSwitchSource = 'cast:switch-source';
  static const castLeave = 'cast:leave';

  // Server to Client
  static const streamStarted = 'stream:started';
  static const streamEnded = 'stream:ended';
  static const streamUpdated = 'stream:updated';
  static const streamInterrupted = 'stream:interrupted';
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

  // Cast - Server to Client
  static const castDeviceAnnounce = 'cast:device-announce';
  static const castCameraOfferIn = 'cast:camera-offer-in';
  static const castCameraAnswerIn = 'cast:camera-answer-in';
  static const castCameraIceIn = 'cast:camera-ice-in';
  static const castDeviceReady = 'cast:device-ready';
  static const castSourceSwitched = 'cast:source-switched';
}

class StreamEndedEvent {
  final String streamId;
  final String? vodUrl;
  final int? duration;

  const StreamEndedEvent({required this.streamId, this.vodUrl, this.duration});

  factory StreamEndedEvent.fromJson(Map<String, dynamic> json) =>
      StreamEndedEvent(
        streamId: json['streamId'] as String? ?? '',
        vodUrl: json['vodUrl'] as String?,
        duration: json['duration'] as int?,
      );
}

class StreamInterruptedEvent {
  final String streamId;
  final int gracePeriodMs;

  const StreamInterruptedEvent({
    required this.streamId,
    this.gracePeriodMs = 30000,
  });

  factory StreamInterruptedEvent.fromJson(Map<String, dynamic> json) =>
      StreamInterruptedEvent(
        streamId: json['streamId'] as String? ?? '',
        gracePeriodMs: json['gracePeriodMs'] as int? ?? 30000,
      );
}

enum SocketConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
  failed,
}

class LiveSocketService {
  io.Socket? _socket;
  String? _currentToken;
  Timer? _recoveryTimer;

  final _connectionStateCtrl =
      StreamController<SocketConnectionState>.broadcast();
  Stream<SocketConnectionState> get connectionState =>
      _connectionStateCtrl.stream;

  final _chatMessageCtrl = StreamController<ChatMessageDto>.broadcast();
  Stream<ChatMessageDto> get onChatMessage => _chatMessageCtrl.stream;

  final _chatDeletedCtrl = StreamController<String>.broadcast();
  Stream<String> get onChatDeleted => _chatDeletedCtrl.stream;

  final _chatPinnedCtrl = StreamController<ChatMessageDto>.broadcast();
  Stream<ChatMessageDto> get onChatPinned => _chatPinnedCtrl.stream;

  final _chatReactionCtrl = StreamController<ChatReactionEvent>.broadcast();
  Stream<ChatReactionEvent> get onChatReaction => _chatReactionCtrl.stream;

  final _viewerCountCtrl = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onViewerCount => _viewerCountCtrl.stream;

  final _streamStartedCtrl = StreamController<LiveStreamDto>.broadcast();
  Stream<LiveStreamDto> get onStreamStarted => _streamStartedCtrl.stream;

  final _streamEndedCtrl = StreamController<StreamEndedEvent>.broadcast();
  Stream<StreamEndedEvent> get onStreamEnded => _streamEndedCtrl.stream;

  final _streamUpdatedCtrl = StreamController<LiveStreamDto>.broadcast();
  Stream<LiveStreamDto> get onStreamUpdated => _streamUpdatedCtrl.stream;

  final _streamInterruptedCtrl =
      StreamController<StreamInterruptedEvent>.broadcast();
  Stream<StreamInterruptedEvent> get onStreamInterrupted =>
      _streamInterruptedCtrl.stream;

  final _streamHealthCtrl = StreamController<StreamHealthDto>.broadcast();
  Stream<StreamHealthDto> get onStreamHealth => _streamHealthCtrl.stream;

  final _reactionBroadcastCtrl =
      StreamController<ReactionBroadcastEvent>.broadcast();
  Stream<ReactionBroadcastEvent> get onReactionBroadcast =>
      _reactionBroadcastCtrl.stream;

  final _qualityRecommendCtrl = StreamController<String>.broadcast();
  Stream<String> get onQualityRecommend => _qualityRecommendCtrl.stream;

  final _errorCtrl = StreamController<String>.broadcast();
  Stream<String> get onError => _errorCtrl.stream;

  // Cast streams
  final _castDeviceAnnounceCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCastDeviceAnnounce =>
      _castDeviceAnnounceCtrl.stream;

  final _castCameraOfferCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCastCameraOffer =>
      _castCameraOfferCtrl.stream;

  final _castCameraAnswerCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCastCameraAnswer =>
      _castCameraAnswerCtrl.stream;

  final _castCameraIceCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCastCameraIce =>
      _castCameraIceCtrl.stream;

  final _castDeviceReadyCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCastDeviceReady =>
      _castDeviceReadyCtrl.stream;

  final _castSourceSwitchedCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCastSourceSwitched =>
      _castSourceSwitchedCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect(String token) async {
    if (_socket != null && _socket!.connected && token == _currentToken) return;

    if (_socket != null) {
      try {
        _socket!.clearListeners();
        _socket!.disconnect();
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }

    _currentToken = token;
    _connectionStateCtrl.add(SocketConnectionState.connecting);

    final baseUrl = Env.apiBaseUrl.replaceAll('/api', '');

    _socket = io.io(
      '$baseUrl/live',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .setQuery({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1500)
          .setReconnectionDelayMax(30000)
          .build(),
    );

    _bindEvents();
    _socket!.connect();
  }

  void _scheduleCleanRecovery() {
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer(const Duration(seconds: 2), () {
      if (_currentToken != null) {
        final token = _currentToken!;
        disconnect();
        connect(token);
      }
    });
  }

  void _bindEvents() {
    final s = _socket!;

    s.onConnect((_) {
      _recoveryTimer?.cancel();
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
      if (e.toString().contains('No transports available')) {
        _scheduleCleanRecovery();
      }
    });
    s.onError((e) {
      if (e.toString().contains('No transports available')) {
        _scheduleCleanRecovery();
      }
    });

    s.on(LiveEvents.chatMessage, (data) {
      try { _chatMessageCtrl.add(ChatMessageDto.fromJson(_toMap(data))); } catch (_) {}
    });
    s.on(LiveEvents.chatDeleted, (data) {
      try {
        final id = _toMap(data)['messageId'] as String?;
        if (id != null) _chatDeletedCtrl.add(id);
      } catch (_) {}
    });
    s.on(LiveEvents.chatPinned, (data) {
      try {
        final m = _toMap(data)['message'] as Map<String, dynamic>?;
        if (m != null) _chatPinnedCtrl.add(ChatMessageDto.fromJson(m));
      } catch (_) {}
    });
    s.on(LiveEvents.chatReaction, (data) {
      try { _chatReactionCtrl.add(ChatReactionEvent.fromJson(_toMap(data))); } catch (_) {}
    });
    s.on(LiveEvents.viewerCount, (data) {
      try { _viewerCountCtrl.add(_toMap(data)); } catch (_) {}
    });
    s.on(LiveEvents.streamStarted, (data) {
      try { _streamStartedCtrl.add(LiveStreamDto.fromJson(_toMap(data))); } catch (_) {}
    });
    s.on(LiveEvents.streamEnded, (data) {
      try { _streamEndedCtrl.add(StreamEndedEvent.fromJson(_toMap(data))); } catch (_) {}
    });
    s.on(LiveEvents.streamUpdated, (data) {
      try { _streamUpdatedCtrl.add(LiveStreamDto.fromJson(_toMap(data))); } catch (_) {}
    });
    s.on(LiveEvents.streamInterrupted, (data) {
      try { _streamInterruptedCtrl.add(StreamInterruptedEvent.fromJson(_toMap(data))); } catch (_) {}
    });
    s.on(LiveEvents.streamHealth, (data) {
      try { _streamHealthCtrl.add(StreamHealthDto.fromJson(_toMap(data))); } catch (_) {}
    });
    s.on(LiveEvents.reactionBroadcast, (data) {
      try { _reactionBroadcastCtrl.add(ReactionBroadcastEvent.fromJson(_toMap(data))); } catch (_) {}
    });
    s.on(LiveEvents.qualityRecommend, (data) {
      try {
        final q = _toMap(data)['quality'] as String?;
        if (q != null) _qualityRecommendCtrl.add(q);
      } catch (_) {}
    });
    s.on(LiveEvents.error, (data) {
      try { _errorCtrl.add(_toMap(data)['message'] as String? ?? 'Socket error'); } catch (_) {}
    });

    // Cast
    s.on(LiveEvents.castDeviceAnnounce, (data) {
      try { _castDeviceAnnounceCtrl.add(_toMap(data)); } catch (_) {}
    });
    s.on(LiveEvents.castCameraOfferIn, (data) {
      try { _castCameraOfferCtrl.add(_toMap(data)); } catch (_) {}
    });
    s.on(LiveEvents.castCameraAnswerIn, (data) {
      try { _castCameraAnswerCtrl.add(_toMap(data)); } catch (_) {}
    });
    s.on(LiveEvents.castCameraIceIn, (data) {
      try { _castCameraIceCtrl.add(_toMap(data)); } catch (_) {}
    });
    s.on(LiveEvents.castDeviceReady, (data) {
      try { _castDeviceReadyCtrl.add(_toMap(data)); } catch (_) {}
    });
    s.on(LiveEvents.castSourceSwitched, (data) {
      try { _castSourceSwitchedCtrl.add(_toMap(data)); } catch (_) {}
    });
  }

  // Room operations

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

  void sendReaction({
    required String streamId,
    required String emoji,
    Map<String, dynamic>? sender,
  }) {
    final payload = <String, dynamic>{
      'streamId': streamId,
      'emoji': emoji,
    };
    if (sender != null) {
      payload['sender'] = sender;
    }
    _socket?.emit(LiveEvents.sendReaction, payload);
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
    _socket?.emit(LiveEvents.deleteChat, {'streamId': streamId, 'messageId': messageId});
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

  // Cast emit helpers

  void emitCastAnnounce({
    required String streamId,
    required String deviceName,
    String? deviceModel,
    int? signalStrength,
  }) {
    _socket?.emit(LiveEvents.castAnnounce, {
      'streamId': streamId,
      'deviceName': deviceName,
      'deviceModel': ?deviceModel,
      'signalStrength': ?signalStrength,
    });
  }

  void emitCastCameraOffer({
    required String streamId,
    required String peerId,
    required String sdp,
  }) {
    _socket?.emit(LiveEvents.castCameraOffer, {
      'streamId': streamId,
      'peerId': peerId,
      'sdp': sdp,
    });
  }

  void emitCastCameraAnswer({required String peerId, required String sdp}) {
    _socket?.emit(LiveEvents.castCameraAnswer, {'peerId': peerId, 'sdp': sdp});
  }

  void emitCastCameraIce({
    required String streamId,
    required String peerId,
    required Map<String, dynamic> candidate,
  }) {
    _socket?.emit(LiveEvents.castCameraIce, {
      'streamId': streamId,
      'peerId': peerId,
      'candidate': candidate,
    });
  }

  void emitCastSwitchSource({
    required String streamId,
    required String sourceId,
    required String sourceType,
  }) {
    _socket?.emit(LiveEvents.castSwitchSource, {
      'streamId': streamId,
      'sourceId': sourceId,
      'sourceType': sourceType,
    });
  }

  void emitCastLeave({required String streamId, required String peerId}) {
    _socket?.emit(LiveEvents.castLeave, {'streamId': streamId, 'peerId': peerId});
  }

  // Disconnect

  void disconnect() {
    _recoveryTimer?.cancel();
    if (_socket != null) {
      try {
        _socket!.clearListeners();
        _socket!.disconnect();
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }
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
    _streamInterruptedCtrl.close();
    _streamHealthCtrl.close();
    _reactionBroadcastCtrl.close();
    _qualityRecommendCtrl.close();
    _errorCtrl.close();
    _castDeviceAnnounceCtrl.close();
    _castCameraOfferCtrl.close();
    _castCameraAnswerCtrl.close();
    _castCameraIceCtrl.close();
    _castDeviceReadyCtrl.close();
    _castSourceSwitchedCtrl.close();
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {};
  }
}

// Provider

final liveSocketServiceProvider = Provider<LiveSocketService>((ref) {
  final service = LiveSocketService();
  ref.onDispose(service.dispose);
  return service;
});