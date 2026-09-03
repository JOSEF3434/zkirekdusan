// lib/features/chats/presentation/providers/chat_messages_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/data/repositories/chat_repository_impl.dart';
import 'package:mobile/features/chats/domain/repositories/chat_repository.dart';
import 'package:mobile/features/chats/data/datasources/messaging_socket_service.dart';

final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, AsyncValue<List<MessageModel>>, String>(
  (ref, conversationId) {
    final repository = ref.watch(chatRepositoryProvider);
    final socketService = ref.watch(messagingSocketServiceProvider);
    return ChatMessagesNotifier(conversationId, repository, socketService);
  },
);

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final String conversationId;
  final ChatRepository _repository;
  final MessagingSocketService _socketService;
  
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  
  StreamSubscription? _newMessageSub;
  StreamSubscription? _updatedMessageSub;
  StreamSubscription? _deletedMessageSub;
  StreamSubscription? _reactionSub;

  ChatMessagesNotifier(this.conversationId, this._repository, this._socketService)
      : super(const AsyncValue.loading()) {
    loadMessages();
    _setupRealtimeListeners();
    _joinConversation();
  }

  void _joinConversation() {
    _socketService.joinConversation(conversationId);
  }

  Future<void> loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getMessages(conversationId: conversationId);
      _nextCursor = result.nextCursor;
      _hasMore = result.hasMore;
      state = AsyncValue.data(result.data.reversed.toList());
    } catch (e, st) {
      if (state.value != null && state.value!.isNotEmpty) {
        // Keep cached state
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    _isLoadingMore = true;
    try {
      final result = await _repository.getMessages(
        conversationId: conversationId,
        cursor: _nextCursor,
      );
      
      _nextCursor = result.nextCursor;
      _hasMore = result.hasMore;

      state.whenData((currentMessages) {
        final newMessages = result.data.reversed.toList();
        state = AsyncValue.data([...newMessages, ...currentMessages]);
      });
    } finally {
      _isLoadingMore = false;
    }
  }

  void _setupRealtimeListeners() {
    // New message received
    _newMessageSub = _socketService.messageReceived.listen((message) {
      if (message.conversationId == conversationId) {
        state.whenData((messages) {
          // Avoid duplicates
          if (!messages.any((m) => m.id == message.id)) {
            state = AsyncValue.data([...messages, message]);
          }
        });
      }
    });

    // Message updated (edited)
    _updatedMessageSub = _socketService.messageUpdated.listen((message) {
      if (message.conversationId == conversationId) {
        state.whenData((messages) {
          final index = messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            final updated = [...messages];
            updated[index] = message;
            state = AsyncValue.data(updated);
          }
        });
      }
    });

    // Message deleted
    _deletedMessageSub = _socketService.messageDeleted.listen((data) {
      if (data['conversationId'] == conversationId) {
        final messageId = data['messageId'];
        state.whenData((messages) {
          state = AsyncValue.data(messages.where((m) => m.id != messageId).toList());
        });
      }
    });

    // Reaction added/removed
    _reactionSub = _socketService.reaction.listen((data) {
      final messageId = data['messageId'] as String?;
      if (messageId != null) {
        state.whenData((messages) {
          final index = messages.indexWhere((m) => m.id == messageId);
          if (index != -1) {
            // Reload the message to get updated reactions
            _refreshMessage(messageId);
          }
        });
      }
    });
  }

  Future<void> _refreshMessage(String messageId) async {
    // This would need a specific API endpoint to fetch a single message
    // For now, we'll just reload all messages
    await loadMessages();
  }

  Future<MessageModel> sendMessage({
    String? content,
    String? replyToId,
    List<String>? attachmentIds,
    String type = 'TEXT',
  }) async {
    final message = await _repository.sendMessage(
      conversationId: conversationId,
      content: content,
      replyToId: replyToId,
      attachmentIds: attachmentIds,
      type: type,
    );

    // Optimistically add to list
    state.whenData((messages) {
      if (!messages.any((m) => m.id == message.id)) {
        state = AsyncValue.data([...messages, message]);
      }
    });

    return message;
  }

  Future<void> editMessage(String messageId, String content) async {
    final updated = await _repository.editMessage(
      messageId: messageId,
      content: content,
    );

    state.whenData((messages) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updatedMessages = [...messages];
        updatedMessages[index] = updated;
        state = AsyncValue.data(updatedMessages);
      }
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await _repository.deleteMessage(messageId);
    
    state.whenData((messages) {
      state = AsyncValue.data(messages.where((m) => m.id != messageId).toList());
    });
  }

  Future<void> addReaction(String messageId, String emoji) async {
    _socketService.sendReaction(messageId, emoji);
    await _repository.addReaction(messageId: messageId, emoji: emoji);
  }

  Future<void> removeReaction(String messageId, String emoji) async {
    _socketService.removeReaction(messageId, emoji);
    await _repository.removeReaction(messageId: messageId, emoji: emoji);
  }

  void markAsRead(String messageId) {
    _socketService.markAsRead(conversationId, messageId);
    _repository.markAsRead(messageId);
  }

  @override
  void dispose() {
    _socketService.leaveConversation(conversationId);
    _newMessageSub?.cancel();
    _updatedMessageSub?.cancel();
    _deletedMessageSub?.cancel();
    _reactionSub?.cancel();
    super.dispose();
  }
}

// Typing indicator provider
final typingIndicatorProvider = StateNotifierProvider.family<TypingIndicatorNotifier, Map<String, bool>, String>(
  (ref, conversationId) {
    final socketService = ref.watch(messagingSocketServiceProvider);
    return TypingIndicatorNotifier(conversationId, socketService);
  },
);

class TypingIndicatorNotifier extends StateNotifier<Map<String, bool>> {
  final String conversationId;
  final MessagingSocketService _socketService;
  StreamSubscription? _typingSub;
  Timer? _typingTimer;

  TypingIndicatorNotifier(this.conversationId, this._socketService) : super({}) {
    _setupTypingListener();
  }

  void _setupTypingListener() {
    _typingSub = _socketService.typing.listen((data) {
      if (data['conversationId'] == conversationId) {
        final userId = data['userId'] as String;
        final isTyping = data['isTyping'] as bool;
        
        if (isTyping) {
          state = {...state, userId: true};
          _resetTypingTimer(userId);
        } else {
          final updated = Map<String, bool>.from(state);
          updated.remove(userId);
          state = updated;
        }
      }
    });
  }

  void _resetTypingTimer(String userId) {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      final updated = Map<String, bool>.from(state);
      updated.remove(userId);
      state = updated;
    });
  }

  void startTyping() {
    _socketService.sendTypingStart(conversationId);
  }

  void stopTyping() {
    _socketService.sendTypingStop(conversationId);
  }

  @override
  void dispose() {
    _typingSub?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}
