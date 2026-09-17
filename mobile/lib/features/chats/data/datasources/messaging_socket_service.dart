// lib/features/chats/data/datasources/messaging_socket_service.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';

final messagingSocketServiceProvider = Provider<MessagingSocketService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MessagingSocketService(apiClient, ref);
});

class MessagingSocketService {
  final Dio _apiClient;
  final Ref _ref;
  final Logger _logger = Logger();
  io.Socket? _socket;
  bool _isConnected = false;

  // Stream controllers for real-time events
  final _messageReceivedController = StreamController<MessageModel>.broadcast();
  final _messageUpdatedController = StreamController<MessageModel>.broadcast();
  final _messageDeletedController = StreamController<Map<String, String>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController = StreamController<Map<String, dynamic>>.broadcast();
  final _deliveryReceiptController = StreamController<Map<String, dynamic>>.broadcast();

  final Set<String> _joinedConversations = {};

  // Public streams
  Stream<MessageModel> get messageReceived => _messageReceivedController.stream;
  Stream<MessageModel> get messageUpdated => _messageUpdatedController.stream;
  Stream<Map<String, String>> get messageDeleted => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get typing => _typingController.stream;
  Stream<Map<String, dynamic>> get presence => _presenceController.stream;
  Stream<Map<String, dynamic>> get reaction => _reactionController.stream;
  Stream<Map<String, dynamic>> get readReceipt => _readReceiptController.stream;
  Stream<Map<String, dynamic>> get deliveryReceipt => _deliveryReceiptController.stream;

  MessagingSocketService(this._apiClient, this._ref);

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_socket != null && _isConnected) {
      _logger.i('MessagingSocket: Already connected');
      return;
    }

    try {
      final token = await _ref.read(storageServiceProvider).getToken();
      if (token == null) {
        _logger.w('MessagingSocket: No access token available');
        return;
      }

      String baseUrl = _apiClient.options.baseUrl;
      if (baseUrl.endsWith('/api')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 4);
      } else if (baseUrl.endsWith('/api/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 5);
      }
      final socketUrl = baseUrl.endsWith('/') ? '${baseUrl}chat' : '$baseUrl/chat';
      _logger.i('MessagingSocket: Connecting to $socketUrl');

      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(999999)
            .setReconnectionDelay(1000)
            .build(),
      );

      _setupSocketListeners();
      _socket!.connect();
    } catch (e) {
      _logger.e('MessagingSocket: Connection error: $e');
    }
  }

  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      _isConnected = true;
      _logger.i('MessagingSocket: Connected to /chat');
      // Re-join any tracked conversations
      for (final id in _joinedConversations) {
        _socket!.emit('conversation:join', {'conversationId': id});
      }
    });

    _socket!.on('reconnect', (_) {
      _logger.i('MessagingSocket: Reconnected, re-joining ${_joinedConversations.length} rooms');
      for (final id in _joinedConversations) {
        _socket!.emit('conversation:join', {'conversationId': id});
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _logger.w('MessagingSocket: Disconnected');
    });

    _socket!.onConnectError((error) {
      _logger.e('MessagingSocket: Connection error: $error');
    });

    _socket!.onError((error) {
      _logger.e('MessagingSocket: Error: $error');
    });

    // Message events
    _socket!.on('message:new', (data) {
      try {
        final message = MessageModel.fromJson(data as Map<String, dynamic>);
        _messageReceivedController.add(message);
        _logger.d('MessagingSocket: New message received: ${message.id}');
      } catch (e) {
        _logger.e('MessagingSocket: Error parsing new message: $e');
      }
    });

    _socket!.on('message:updated', (data) {
      try {
        final message = MessageModel.fromJson(data as Map<String, dynamic>);
        _messageUpdatedController.add(message);
        _logger.d('MessagingSocket: Message updated: ${message.id}');
      } catch (e) {
        _logger.e('MessagingSocket: Error parsing updated message: $e');
      }
    });

    _socket!.on('message:deleted', (data) {
      try {
        final payload = data as Map<String, dynamic>;
        _messageDeletedController.add({
          'conversationId': (payload['conversationId'] as String?) ?? '',
          'messageId': (payload['messageId'] as String?) ?? '',
        });
        _logger.d('MessagingSocket: Message deleted: ${payload['messageId']}');
      } catch (e) {
        _logger.e('MessagingSocket: Error parsing deleted message: $e');
      }
    });

    // Typing indicators
    _socket!.on('typing:start', (data) {
      _typingController.add({...data as Map<String, dynamic>, 'isTyping': true});
    });

    _socket!.on('typing:stop', (data) {
      _typingController.add({...data as Map<String, dynamic>, 'isTyping': false});
    });

    // Presence updates
    _socket!.on('presence:changed', (data) {
      if (data is Map<String, dynamic>) {
        final status = (data['status'] as String? ?? 'offline').toLowerCase();
        _presenceController.add({...data, 'status': status});
        _logger.d('MessagingSocket: Presence changed: $data');
      }
    });

    _socket!.on('presence:online', (data) {
      _presenceController.add({...data as Map<String, dynamic>, 'status': 'online'});
    });

    _socket!.on('presence:offline', (data) {
      _presenceController.add({...data as Map<String, dynamic>, 'status': 'offline'});
    });

    // Reactions
    _socket!.on('reaction:new', (data) {
      _reactionController.add({...data as Map<String, dynamic>, 'action': 'add'});
    });
    _socket!.on('reaction:added', (data) {
      _reactionController.add({...data as Map<String, dynamic>, 'action': 'add'});
    });
    _socket!.on('reaction:removed', (data) {
      _reactionController.add({...data as Map<String, dynamic>, 'action': 'remove'});
    });
    _socket!.on('reaction:updated', (data) {
      _reactionController.add(data as Map<String, dynamic>);
    });

    // Read receipts
    _socket!.on('message:read', (data) {
      _readReceiptController.add(data as Map<String, dynamic>);
    });
    _socket!.on('message:receipt', (data) {
      _readReceiptController.add(data as Map<String, dynamic>);
    });

    // Delivery receipts
    _socket!.on('message:delivered', (data) {
      _deliveryReceiptController.add(data as Map<String, dynamic>);
    });
  }

  // Join a conversation room
  void joinConversation(String conversationId) {
    _joinedConversations.add(conversationId);
    if (_socket != null && _isConnected) {
      _socket!.emit('conversation:join', {'conversationId': conversationId});
      _logger.d('MessagingSocket: Joined conversation $conversationId');
    }
  }

  // Leave a conversation room
  void leaveConversation(String conversationId) {
    _joinedConversations.remove(conversationId);
    if (_socket != null && _isConnected) {
      _socket!.emit('conversation:leave', {'conversationId': conversationId});
      _logger.d('MessagingSocket: Left conversation $conversationId');
    }
  }

  // Send typing indicator
  void sendTypingStart(String conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing:start', {'conversationId': conversationId});
    }
  }

  void sendTypingStop(String conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing:stop', {'conversationId': conversationId});
    }
  }

  // Mark message as read
  void markAsRead(String conversationId, String messageId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('message:read', {
        'conversationId': conversationId,
        'messageId': messageId,
      });
    }
  }

  // Send reaction
  void sendReaction(String messageId, String emoji, {String? conversationId}) {
    if (_socket != null && _isConnected) {
      _socket!.emit('reaction:add', {
        'messageId': messageId,
        'conversationId': conversationId ?? '',
        'emoji': emoji,
      });
    }
  }

  void removeReaction(String messageId, String emoji, {String? conversationId}) {
    if (_socket != null && _isConnected) {
      _socket!.emit('reaction:remove', {
        'messageId': messageId,
        'conversationId': conversationId ?? '',
        'emoji': emoji,
      });
    }
  }

  void disconnect() {
    _joinedConversations.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _logger.i('MessagingSocket: Disconnected and disposed');
  }

  void dispose() {
    disconnect();
    _messageReceivedController.close();
    _messageUpdatedController.close();
    _messageDeletedController.close();
    _typingController.close();
    _presenceController.close();
    _reactionController.close();
    _readReceiptController.close();
    _deliveryReceiptController.close();
  }
}
