import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/data/repositories/chat_repository_impl.dart';
import 'package:mobile/features/chats/domain/repositories/chat_repository.dart';
import 'package:mobile/features/chats/data/datasources/messaging_socket_service.dart';

final pinnedMessagesProvider = FutureProvider.family<List<MessageModel>, String>(
  (ref, conversationId) async {
    final repository = ref.watch(chatRepositoryProvider);
    try {
      return await repository.getPinnedMessages(conversationId);
    } catch (_) {
      return [];
    }
  },
);

final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, AsyncValue<List<MessageModel>>, String>(
  (ref, conversationId) {
    final repository = ref.watch(chatRepositoryProvider);
    final socketService = ref.watch(messagingSocketServiceProvider);
    return ChatMessagesNotifier(conversationId, repository, socketService, ref);
  },
);

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final String conversationId;
  final ChatRepository _repository;
  final MessagingSocketService _socketService;
  final Ref _ref;
  
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  
  StreamSubscription? _newMessageSub;
  StreamSubscription? _updatedMessageSub;
  StreamSubscription? _deletedMessageSub;
  StreamSubscription? _reactionSub;
  StreamSubscription? _readReceiptSub;

  ChatMessagesNotifier(this.conversationId, this._repository, this._socketService, this._ref)
      : super(const AsyncValue.loading()) {
    loadMessages();
    _setupRealtimeListeners();
    _joinConversation();
  }

  void _joinConversation() {
    _socketService.joinConversation(conversationId);
  }

  Future<void> loadMessages() async {
    // 1. Try to hydrate instantly from local database without showing empty spinner
    try {
      final cachedResult = await _repository.getMessages(conversationId: conversationId);
      if (cachedResult.data.isNotEmpty) {
        _nextCursor = cachedResult.nextCursor;
        _hasMore = cachedResult.hasMore;
        state = AsyncValue.data(cachedResult.data.reversed.toList());
      }
    } catch (_) {}

    if (state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }

    // 2. Fetch latest messages from server
    try {
      final result = await _repository.getMessages(conversationId: conversationId);
      _nextCursor = result.nextCursor;
      _hasMore = result.hasMore;
      state = AsyncValue.data(result.data.reversed.toList());
    } catch (e, st) {
      if (state.valueOrNull != null && state.valueOrNull!.isNotEmpty) {
        // Keep cached messages for seamless offline viewing
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
        final currentUserId = _ref.read(authProvider).user?.id;
        state.whenData((messages) {
          // Avoid duplicates
          if (!messages.any((m) => m.id == message.id)) {
            var newMsg = message;
            // If from peer and current user has this conversation open, mark read immediately
            if (currentUserId != null && message.sender.id != currentUserId) {
              _socketService.markAsRead(conversationId, message.id);
              _repository.markAsRead(message.id);
              if (!newMsg.readBy.contains(currentUserId)) {
                newMsg = newMsg.copyWith(readBy: [...newMsg.readBy, currentUserId]);
              }
            }
            state = AsyncValue.data([...messages, newMsg]);
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

    // Real-time reaction added/removed by any participant via socket
    _reactionSub = _socketService.reaction.listen((data) {
      final messageId = data['messageId'] as String?;
      final emoji = data['emoji'] as String?;
      final userId = data['userId'] as String?;
      final action = data['action'] as String? ?? 'add';
      final currentUserId = _ref.read(authProvider).user?.id;

      if (messageId == null || emoji == null || userId == null) return;
      // Skip if this event was triggered by our own optimistic action
      if (userId == currentUserId) return;

      state.whenData((messages) {
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index == -1) return;

        final message = messages[index];
        final reactions = List<MessageReactionModel>.from(message.reactions);
        final existingIndex = reactions.indexWhere((r) => r.emoji == emoji);

        if (action == 'remove') {
          if (existingIndex != -1) {
            final existing = reactions[existingIndex];
            final updatedUserIds = existing.userIds.where((id) => id != userId).toList();
            if (updatedUserIds.isEmpty) {
              reactions.removeAt(existingIndex);
            } else {
              reactions[existingIndex] = existing.copyWith(
                count: updatedUserIds.length,
                userIds: updatedUserIds,
              );
            }
          }
        } else {
          // action == 'add'
          if (existingIndex != -1) {
            final existing = reactions[existingIndex];
            if (!existing.userIds.contains(userId)) {
              final updatedUserIds = [...existing.userIds, userId];
              reactions[existingIndex] = existing.copyWith(
                count: updatedUserIds.length,
                userIds: updatedUserIds,
              );
            }
          } else {
            reactions.add(MessageReactionModel(
              emoji: emoji,
              count: 1,
              userIds: [userId],
            ));
          }
        }

        final updatedMessages = [...messages];
        updatedMessages[index] = message.copyWith(reactions: reactions);
        state = AsyncValue.data(updatedMessages);
      });
    });

    // Real-time read receipt updates
    _readReceiptSub = _socketService.readReceipt.listen((data) {
      final messageId = data['messageId'] as String?;
      final userId = data['userId'] as String?;
      if (messageId == null || userId == null) return;

      state.whenData((messages) {
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index == -1) return;

        final message = messages[index];
        if (!message.readBy.contains(userId)) {
          final updatedReadBy = [...message.readBy, userId];
          final updatedMessages = [...messages];
          updatedMessages[index] = message.copyWith(readBy: updatedReadBy);
          state = AsyncValue.data(updatedMessages);
        }
      });
    });
  }

  Future<MessageModel> sendMessage({
    String? content,
    String? replyToId,
    List<String>? attachmentIds,
    String type = 'TEXT',
    List<MessageAttachmentModel>? initialAttachments,
    MessageVoiceNoteModel? voiceNote,
  }) async {
    final message = await _repository.sendMessage(
      conversationId: conversationId,
      content: content,
      replyToId: replyToId,
      attachmentIds: attachmentIds,
      type: type,
      initialAttachments: initialAttachments,
      voiceNote: voiceNote,
    );

    // Optimistically add or update in list
    state.whenData((messages) {
      final existingIndex = messages.indexWhere((m) => m.id == message.id);
      if (existingIndex != -1) {
        final updated = [...messages];
        updated[existingIndex] = message;
        state = AsyncValue.data(updated);
      } else {
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

  Future<void> deleteMessage(String messageId, {bool forEveryone = false}) async {
    await _repository.deleteMessage(messageId, forEveryone: forEveryone);
    
    state.whenData((messages) {
      state = AsyncValue.data(messages.where((m) => m.id != messageId).toList());
    });
    _ref.invalidate(pinnedMessagesProvider(conversationId));
  }

  Future<void> pinMessageForEveryone(String messageId) async {
    await _repository.pinMessage(conversationId: conversationId, messageId: messageId);
    state.whenData((messages) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updated = [...messages];
        updated[index] = updated[index].copyWith(isPinned: true);
        state = AsyncValue.data(updated);
      }
    });
    _ref.invalidate(pinnedMessagesProvider(conversationId));
  }

  Future<void> unpinMessage(String messageId) async {
    await _repository.unpinMessage(conversationId: conversationId, messageId: messageId);
    state.whenData((messages) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updated = [...messages];
        updated[index] = updated[index].copyWith(isPinned: false);
        state = AsyncValue.data(updated);
      }
    });
    _ref.invalidate(pinnedMessagesProvider(conversationId));
  }

  Future<void> pinMessageForMe(String messageId) async {
    await _repository.starMessage(messageId);
  }

  Future<void> unpinMessageForMe(String messageId) async {
    await _repository.unstarMessage(messageId);
  }

  Future<void> addReaction(String messageId, String emoji) async {
    await toggleReaction(messageId, emoji);
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final currentUserId = _ref.read(authProvider).user?.id;
    if (currentUserId == null) return;

    bool isRemove = false;

    // 1. Instant optimistic local UI update
    state.whenData((messages) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index == -1) return;

      final message = messages[index];
      final reactions = List<MessageReactionModel>.from(message.reactions);
      final existingIndex = reactions.indexWhere((r) => r.emoji == emoji);

      if (existingIndex != -1) {
        final existing = reactions[existingIndex];
        if (existing.userIds.contains(currentUserId)) {
          // User already reacted with this emoji -> TOGGLE OFF (remove)
          isRemove = true;
          final updatedUserIds = existing.userIds.where((id) => id != currentUserId).toList();
          if (updatedUserIds.isEmpty) {
            reactions.removeAt(existingIndex);
          } else {
            reactions[existingIndex] = existing.copyWith(
              count: updatedUserIds.length,
              userIds: updatedUserIds,
            );
          }
        } else {
          // Add current user to this existing reaction
          final updatedUserIds = [...existing.userIds, currentUserId];
          reactions[existingIndex] = existing.copyWith(
            count: updatedUserIds.length,
            userIds: updatedUserIds,
          );
        }
      } else {
        // Brand new emoji reaction
        reactions.add(MessageReactionModel(
          emoji: emoji,
          count: 1,
          userIds: [currentUserId],
        ));
      }

      final updatedMessages = [...messages];
      updatedMessages[index] = message.copyWith(reactions: reactions);
      state = AsyncValue.data(updatedMessages);
    });

    // 2. Emit socket event and sync with backend API
    if (isRemove) {
      _socketService.removeReaction(messageId, emoji, conversationId: conversationId);
      try {
        await _repository.removeReaction(messageId: messageId, emoji: emoji);
      } catch (_) {}
    } else {
      _socketService.sendReaction(messageId, emoji, conversationId: conversationId);
      try {
        await _repository.addReaction(messageId: messageId, emoji: emoji);
      } catch (_) {}
    }
  }

  Future<void> removeReaction(String messageId, String emoji) async {
    final currentUserId = _ref.read(authProvider).user?.id;
    if (currentUserId == null) return;

    state.whenData((messages) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index == -1) return;

      final message = messages[index];
      final reactions = List<MessageReactionModel>.from(message.reactions);
      final existingIndex = reactions.indexWhere((r) => r.emoji == emoji);

      if (existingIndex != -1) {
        final existing = reactions[existingIndex];
        final updatedUserIds = existing.userIds.where((id) => id != currentUserId).toList();
        if (updatedUserIds.isEmpty) {
          reactions.removeAt(existingIndex);
        } else {
          reactions[existingIndex] = existing.copyWith(
            count: updatedUserIds.length,
            userIds: updatedUserIds,
          );
        }
        final updatedMessages = [...messages];
        updatedMessages[index] = message.copyWith(reactions: reactions);
        state = AsyncValue.data(updatedMessages);
      }
    });

    _socketService.removeReaction(messageId, emoji, conversationId: conversationId);
    try {
      await _repository.removeReaction(messageId: messageId, emoji: emoji);
    } catch (_) {}
  }

  void markAsRead(String messageId) {
    _socketService.markAsRead(conversationId, messageId);
    _repository.markAsRead(messageId);
  }

  void markIncomingAsRead(String currentUserId) {
    state.whenData((messages) {
      bool anyMarked = false;
      final updated = <MessageModel>[];
      for (final msg in messages) {
        if (msg.sender.id != currentUserId && !msg.readBy.contains(currentUserId)) {
          markAsRead(msg.id);
          updated.add(msg.copyWith(readBy: [...msg.readBy, currentUserId]));
          anyMarked = true;
        } else {
          updated.add(msg);
        }
      }
      if (anyMarked) {
        state = AsyncValue.data(updated);
      }
    });
  }

  @override
  void dispose() {
    _socketService.leaveConversation(conversationId);
    _newMessageSub?.cancel();
    _updatedMessageSub?.cancel();
    _deletedMessageSub?.cancel();
    _reactionSub?.cancel();
    _readReceiptSub?.cancel();
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
