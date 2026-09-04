// lib/features/chats/presentation/providers/conversations_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/data/repositories/chat_repository_impl.dart';
import 'package:mobile/features/chats/domain/repositories/chat_repository.dart';
import 'package:mobile/features/chats/data/datasources/messaging_socket_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

final chatDiscoveryProvider =
    StateNotifierProvider<
      ChatDiscoveryNotifier,
      AsyncValue<ChatDiscoveryModel>
    >((ref) {
      final repository = ref.watch(chatRepositoryProvider);
      final socketService = ref.watch(messagingSocketServiceProvider);
      final currentUserId = ref.watch(
        authProvider.select((auth) => auth.user?.id),
      );
      return ChatDiscoveryNotifier(
        repository,
        socketService,
        currentUserId,
      );
    });

class ChatDiscoveryNotifier
    extends StateNotifier<AsyncValue<ChatDiscoveryModel>> {
  final ChatRepository _repository;
  final MessagingSocketService _socketService;
  final String? _currentUserId;
  StreamSubscription? _messageSubscription;
  Timer? _refreshTimer;
  Future<void>? _discoveryRequest;

  ChatDiscoveryNotifier(
    this._repository,
    this._socketService,
    this._currentUserId,
  ) : super(const AsyncValue.loading()) {
    loadDiscovery();
    _setupRealtimeUpdates();
    _setupPeriodicRefresh();
  }

  Future<void> loadDiscovery() async {
    if (_discoveryRequest != null) return _discoveryRequest!;
    if (state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    final request = _loadDiscovery();
    _discoveryRequest = request;
    try {
      await request;
    } finally {
      if (identical(_discoveryRequest, request)) {
        _discoveryRequest = null;
      }
    }
  }

  Future<void> _loadDiscovery() async {
    // 1. Immediately hydrate state with local cached conversations from Drift (no network delay!)
    try {
      final cached = await _repository.getCachedConversations();
      state = AsyncValue.data(
        ChatDiscoveryModel(
          conversations: cached,
        ),
      );
    } catch (_) {
      if (state.valueOrNull == null) {
        state = const AsyncValue.data(ChatDiscoveryModel());
      }
    }

    // 2. Refresh from server in background with timeout
    try {
      final discovery = await _repository
          .getChatDiscovery()
          .timeout(const Duration(seconds: 15));
      if (discovery.conversations.isNotEmpty ||
          discovery.allUsers.isNotEmpty ||
          discovery.publicGroups.isNotEmpty ||
          state.valueOrNull == null ||
          state.valueOrNull!.conversations.isEmpty) {
        state = AsyncValue.data(discovery);
      }
    } catch (e) {
      if (state.valueOrNull == null) {
        // Fallback to local cached conversations
        final cached = await _repository.getCachedConversations();
        state = AsyncValue.data(ChatDiscoveryModel(conversations: cached));
      }
    }
  }

  Future<void> refreshDiscovery() async {
    if (_discoveryRequest != null) return _discoveryRequest!;
    final prev = state.value;
    final request = _refreshDiscovery(prev);
    _discoveryRequest = request;
    try {
      await request;
    } finally {
      if (identical(_discoveryRequest, request)) {
        _discoveryRequest = null;
      }
    }
  }

  Future<void> _refreshDiscovery(ChatDiscoveryModel? prev) async {
    try {
      final discovery = await _repository
          .getChatDiscovery()
          .timeout(const Duration(seconds: 15));
      if (discovery.conversations.isNotEmpty ||
          discovery.allUsers.isNotEmpty ||
          discovery.publicGroups.isNotEmpty ||
          prev == null) {
        state = AsyncValue.data(discovery);
      }
    } catch (e) {
      if (prev != null) {
        state = AsyncValue.data(prev);
      }
    }
  }

  void _setupRealtimeUpdates() {
    _messageSubscription = _socketService.messageReceived.listen((message) {
      state.whenData((discovery) {
        final conversations = [...discovery.conversations];
        final index = conversations.indexWhere(
          (c) => c.id == message.conversationId,
        );
        if (index != -1) {
          final conv = conversations[index];
          conversations[index] = conv.copyWith(
            lastMessageAt: message.createdAt,
            lastMessage: MessagePreviewModel(
              id: message.id,
              content: message.content,
              type: message.type,
              senderName: message.sender.displayName ?? message.sender.username,
              isMe: message.sender.id == _currentUserId,
            ),
          );

          if (message.sender.id != _currentUserId) {
            final memberIndex = conversations[index].members.indexWhere(
              (m) => m.userId == _currentUserId,
            );
            if (memberIndex != -1) {
              final members = [...conversations[index].members];
              members[memberIndex] = members[memberIndex].copyWith(
                unreadCount: members[memberIndex].unreadCount + 1,
              );
              conversations[index] = conversations[index].copyWith(
                members: members,
              );
            }
          }

          state = AsyncValue.data(
            ChatDiscoveryModel(
              conversations: conversations,
              publicGroups: discovery.publicGroups,
              myPrivateGroups: discovery.myPrivateGroups,
              allUsers: discovery.allUsers,
            ),
          );
        }
      });
    });
  }

  void _setupPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshDiscovery();
    });
  }

  Future<void> markAsRead(String conversationId) async {
    await _repository.markConversationAsRead(conversationId);
    state.whenData((discovery) {
      final conversations = [...discovery.conversations];
      final index = conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        final memberIndex = conversations[index].members.indexWhere(
          (m) => m.userId == _currentUserId,
        );
        if (memberIndex != -1) {
          final members = [...conversations[index].members];
          members[memberIndex] = members[memberIndex].copyWith(unreadCount: 0);
          conversations[index] = conversations[index].copyWith(
            members: members,
          );
          state = AsyncValue.data(
            ChatDiscoveryModel(
              conversations: conversations,
              publicGroups: discovery.publicGroups,
              myPrivateGroups: discovery.myPrivateGroups,
              allUsers: discovery.allUsers,
            ),
          );
        }
      }
    });
  }

  Future<void> muteConversation(String conversationId) async {
    await _repository.muteConversation(conversationId);
    await refreshDiscovery();
  }

  Future<void> unmuteConversation(String conversationId) async {
    await _repository.unmuteConversation(conversationId);
    await refreshDiscovery();
  }

  Future<void> pinConversation(String conversationId) async {
    await _repository.pinConversation(conversationId);
    await refreshDiscovery();
  }

  Future<void> unpinConversation(String conversationId) async {
    await _repository.unpinConversation(conversationId);
    await refreshDiscovery();
  }

  Future<ConversationModel> createOrGetDirectConversation(
    String recipientId,
  ) async {
    final conv = await _repository.createDirectConversation(recipientId);
    await refreshDiscovery();
    return conv;
  }

  Future<ConversationModel> createOrGetGroupConversation(String groupId) async {
    final conv = await _repository.createOrGetGroupConversation(groupId);
    await refreshDiscovery();
    return conv;
  }

  Future<Map<String, dynamic>> createPrivateGroup({
    required String name,
    required String slug,
    String? description,
  }) async {
    final result = await _repository.createGroup(
      name: name,
      slug: slug,
      description: description,
      visibility: 'PRIVATE',
    );
    await refreshDiscovery();
    return result;
  }

  Future<Map<String, dynamic>> createPublicGroup({
    required String name,
    required String slug,
    String? description,
  }) async {
    final result = await _repository.createGroup(
      name: name,
      slug: slug,
      description: description,
      visibility: 'PUBLIC',
    );
    await refreshDiscovery();
    return result;
  }

  Future<Map<String, dynamic>> getGroupInviteLink(String groupId) async {
    return await _repository.getGroupInviteLink(groupId);
  }

  Future<Map<String, dynamic>> joinGroupByInvite(String token) async {
    final res = await _repository.joinGroupByInvite(token);
    await refreshDiscovery();
    return res;
  }

  int getTotalUnreadCount() {
    return state.maybeWhen(
      data: (discovery) {
        int total = 0;
        for (final conv in discovery.conversations) {
          final member = conv.members.firstWhere(
            (m) => m.userId == _currentUserId,
            orElse: () => conv.members.isNotEmpty
                ? conv.members.first
                : const ConversationMemberModel(userId: '', username: ''),
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

// Backward compatibility alias for conversationsProvider
final conversationsProvider = chatDiscoveryProvider;

// Filter provider
final conversationFilterProvider = StateProvider<String>((ref) => 'all');

// Unified Chat List Provider (Combines Conversations + Public Groups + All Users sorted newest first)
final unifiedChatListProvider = Provider<AsyncValue<List<UnifiedChatItem>>>((
  ref,
) {
  final discoveryAsync = ref.watch(chatDiscoveryProvider);
  final filter = ref.watch(conversationFilterProvider);
  final currentUserId = ref.watch(authProvider).user?.id;

  final discovery = discoveryAsync.value;
  if (discovery == null) {
    if (discoveryAsync.hasError) {
      return AsyncValue.error(
        discoveryAsync.error!,
        discoveryAsync.stackTrace!,
      );
    }
    return const AsyncValue.loading();
  }

  final items = <UnifiedChatItem>[];

    // 1. Existing Active Conversations
    for (final conv in discovery.conversations) {
      final isPinned = conv.members.any(
        (m) => m.userId == currentUserId && m.isPinned,
      );
      final isMuted = conv.members.any(
        (m) => m.userId == currentUserId && m.isMuted,
      );
      final member = conv.members.firstWhere(
        (m) => m.userId == currentUserId,
        orElse: () => conv.members.isNotEmpty
            ? conv.members.first
            : const ConversationMemberModel(userId: '', username: ''),
      );

      final otherMember = conv.type == 'DIRECT'
          ? conv.members.firstWhere(
              (m) => m.userId != currentUserId,
              orElse: () => conv.members.isNotEmpty
                  ? conv.members.first
                  : const ConversationMemberModel(userId: '', username: ''),
            )
          : null;

      final title =
          conv.title ??
          otherMember?.displayName ??
          otherMember?.username ??
          'Chat';

      final subtitle =
          conv.lastMessage?.content ??
          (conv.type == 'DIRECT' ? 'Direct Message' : 'Group Chat');

      final avatarUrl = conv.type == 'DIRECT'
          ? otherMember?.avatarUrl
          : (conv.metadata?.groupAvatar);

      final isOnline = otherMember?.isOnline ?? false;

      items.add(
        UnifiedChatItem(
          id: conv.id,
          title: title,
          subtitle: subtitle,
          avatarUrl: avatarUrl,
          type: UnifiedChatType.conversation,
          sortDate: conv.lastMessageAt ?? conv.createdAt,
          unreadCount: member.unreadCount,
          isMuted: isMuted,
          isPinned: isPinned,
          isOnline: isOnline,
          conversationId: conv.id,
          targetUserId: otherMember?.userId,
          targetGroupId: conv.groupId,
          conversation: conv,
        ),
      );
    }

    // 2. All Public Groups (sorted newest first)
    for (final group in discovery.publicGroups) {
      // Check if already in active conversations
      final alreadyInConvs = discovery.conversations.any(
        (c) =>
            c.groupId == group.id ||
            (group.conversationId != null && c.id == group.conversationId),
      );

      if (!alreadyInConvs) {
        items.add(
          UnifiedChatItem(
            id: 'group_${group.id}',
            title: group.name,
            subtitle:
                group.description ??
                'Public group • ${group.membersCount} members',
            avatarUrl: group.avatarUrl,
            type: UnifiedChatType.publicGroup,
            sortDate: group.createdAt,
            membersCount: group.membersCount,
            targetGroupId: group.id,
            conversationId: group.conversationId,
          ),
        );
      }
    }

    // 3. User's Private Groups
    for (final group in discovery.myPrivateGroups) {
      final alreadyInConvs = discovery.conversations.any(
        (c) =>
            c.groupId == group.id ||
            (group.conversationId != null && c.id == group.conversationId),
      );

      if (!alreadyInConvs) {
        items.add(
          UnifiedChatItem(
            id: 'private_group_${group.id}',
            title: group.name,
            subtitle:
                group.description ??
                'Private group • ${group.membersCount} members',
            avatarUrl: group.avatarUrl,
            type: UnifiedChatType.privateGroup,
            sortDate: group.createdAt,
            membersCount: group.membersCount,
            targetGroupId: group.id,
            conversationId: group.conversationId,
          ),
        );
      }
    }

    // 4. All Users in the database (sorted newest first)
    for (final user in discovery.allUsers) {
      if (user.id == currentUserId) continue;

      // Check if already have active direct conversation
      final alreadyInConvs = discovery.conversations.any(
        (c) => c.type == 'DIRECT' && c.members.any((m) => m.userId == user.id),
      );

      if (!alreadyInConvs) {
        items.add(
          UnifiedChatItem(
            id: 'user_${user.id}',
            title: user.displayName,
            subtitle:
                user.bio ??
                (user.username != null
                    ? '@${user.username}'
                    : 'Joined StreamHub'),
            avatarUrl: user.avatarUrl,
            type: UnifiedChatType.user,
            sortDate: user.createdAt,
            isOnline: user.isOnline,
            targetUserId: user.id,
          ),
        );
      }
    }

    // Apply Filter
    List<UnifiedChatItem> filtered;
    switch (filter) {
      case 'unread':
        filtered = items.where((i) => i.unreadCount > 0).toList();
        break;

      case 'personal':
        filtered = items
            .where(
              (i) =>
                  i.type == UnifiedChatType.user ||
                  (i.conversation != null &&
                      i.conversation!.type == ConversationType.direct),
            )
            .toList();
        break;

      case 'groups':
        filtered = items
            .where(
              (i) =>
                  i.type == UnifiedChatType.publicGroup ||
                  i.type == UnifiedChatType.privateGroup ||
                  (i.conversation != null &&
                      (i.conversation!.type == ConversationType.groupDirect ||
                          i.conversation!.type ==
                              ConversationType.groupChannel)),
            )
            .toList();
        break;

      case 'channels':
        filtered = items
            .where(
              (i) =>
                  (i.conversation != null &&
                      i.conversation!.type == ConversationType.groupChannel) ||
                  i.type == UnifiedChatType.publicGroup,
            )
            .toList();
        break;

      default: // 'all'
        filtered = items;
        break;
    }

    // Sort: Pinned first, then by date (newest first)
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.sortDate.compareTo(a.sortDate);
    });

    return AsyncValue.data(filtered);
});

// Backward compatibility alias for filteredConversationsProvider
final filteredConversationsProvider =
    Provider<AsyncValue<List<ConversationModel>>>((ref) {
      final discovery = ref.watch(chatDiscoveryProvider);
      return discovery.whenData((d) => d.conversations);
    });
