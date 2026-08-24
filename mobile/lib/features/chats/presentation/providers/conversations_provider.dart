// lib/features/chats/presentation/providers/conversations_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/repositories/chat_repository_impl.dart';
import 'package:mobile/features/chats/domain/repositories/chat_repository.dart';
import 'package:mobile/features/chats/data/datasources/messaging_socket_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

final conversationsProvider = StateNotifierProvider<ConversationsNotifier, AsyncValue<List<ConversationModel>>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final socketService = ref.watch(messagingSocketServiceProvider);
  final authState = ref.watch(authProvider);
  return ConversationsNotifier(repository, socketService, authState.user?.id);
});

class ConversationsNotifier extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  final ChatRepository _repository;
  final MessagingSocketService _socketService;
  final String? _currentUserId;
  StreamSubscription? _messageSubscription;
  Timer? _refreshTimer;

  ConversationsNotifier(this._repository, this._socketService, this._currentUserId)
      : super(const AsyncValue.loading()) {
    loadConversations();
    _setupRealtimeUpdates();
    _setupPeriodicRefresh();
  }

  Future<void> loadConversations() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final conversations = await _repository.getUserConversations();
      return _sortConversations(conversations);
    });
  }

  Future<void> refreshConversations() async {
    state = await AsyncValue.guard(() async {
      final conversations = await _repository.getUserConversations();
      return _sortConversations(conversations);
    });
  }

  List<ConversationModel> _sortConversations(List<ConversationModel> conversations) {
    final sorted = [...conversations];
    sorted.sort((a, b) {
      // Pinned conversations first
      final aPinned = a.members.any((m) => m.userId == _currentUserId && m.isPinned);
      final bPinned = b.members.any((m) => m.userId == _currentUserId && m.isPinned);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;

      // Then by lastMessageAt
      if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });
    return sorted;
  }

  void _setupRealtimeUpdates() {
    _messageSubscription = _socketService.messageReceived.listen((message) {
      state.whenData((conversations) {
        final index = conversations.indexWhere((c) => c.id == message.conversationId);
        if (index != -1) {
          final updated = [...conversations];
          final conversation = updated[index];
          
          // Update last message
          updated[index] = conversation.copyWith(
            lastMessageAt: message.createdAt,
            lastMessage: MessagePreviewModel(
              id: message.id,
              content: message.content,
              type: message.type,
              senderName: message.sender.displayName ?? message.sender.username,
              isMe: message.sender.id == _currentUserId,
            ),
          );

          // Increment unread count if not sent by current user
          if (message.sender.id != _currentUserId) {
            final memberIndex = updated[index].members.indexWhere((m) => m.userId == _currentUserId);
            if (memberIndex != -1) {
              final members = [...updated[index].members];
              members[memberIndex] = members[memberIndex].copyWith(
                unreadCount: members[memberIndex].unreadCount + 1,
              );
              updated[index] = updated[index].copyWith(members: members);
            }
          }

          state = AsyncValue.data(_sortConversations(updated));
        }
      });
    });
  }

  void _setupPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshConversations();
    });
  }

  Future<void> muteConversation(String conversationId) async {
    await _repository.muteConversation(conversationId);
    await refreshConversations();
  }

  Future<void> unmuteConversation(String conversationId) async {
    await _repository.unmuteConversation(conversationId);
    await refreshConversations();
  }

  Future<void> pinConversation(String conversationId) async {
    await _repository.pinConversation(conversationId);
    await refreshConversations();
  }

  Future<void> unpinConversation(String conversationId) async {
    await _repository.unpinConversation(conversationId);
    await refreshConversations();
  }

  Future<void> markAsRead(String conversationId) async {
    await _repository.markConversationAsRead(conversationId);
    
    // Optimistically update unread count
    state.whenData((conversations) {
      final index = conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        final updated = [...conversations];
        final memberIndex = updated[index].members.indexWhere((m) => m.userId == _currentUserId);
        if (memberIndex != -1) {
          final members = [...updated[index].members];
          members[memberIndex] = members[memberIndex].copyWith(unreadCount: 0);
          updated[index] = updated[index].copyWith(members: members);
          state = AsyncValue.data(updated);
        }
      }
    });
  }

  int getTotalUnreadCount() {
    return state.maybeWhen(
      data: (conversations) {
        int total = 0;
        for (final conv in conversations) {
          final member = conv.members.firstWhere(
            (m) => m.userId == _currentUserId,
            orElse: () => conv.members.first,
          );
          if (!member.isMuted) {
            total += member.unreadCount;
          }
        }
        return total;
      },
      orElse: () => 0,
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// Filter providers
final conversationFilterProvider = StateProvider<String>((ref) => 'all');

final filteredConversationsProvider = Provider<AsyncValue<List<ConversationModel>>>((ref) {
  final conversations = ref.watch(conversationsProvider);
  final filter = ref.watch(conversationFilterProvider);
  final currentUserId = ref.watch(authProvider).user?.id;

  return conversations.whenData((convs) {
    switch (filter) {
      case 'unread':
        return convs.where((c) {
          final member = c.members.firstWhere(
            (m) => m.userId == currentUserId,
            orElse: () => c.members.first,
          );
          return member.unreadCount > 0;
        }).toList();
      
      case 'personal':
        return convs.where((c) => c.type == ConversationType.direct).toList();
      
      case 'groups':
        return convs.where((c) => c.type == ConversationType.groupDirect).toList();
      
      case 'channels':
        return convs.where((c) => c.type == ConversationType.groupChannel).toList();
      
      default:
        return convs;
    }
  });
});
