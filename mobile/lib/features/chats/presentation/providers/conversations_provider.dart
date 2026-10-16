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
  StreamSubscription? _presenceSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _deliveryReceiptSubscription;
  StreamSubscription? _presenceQuerySubscription;
  Timer? _refreshTimer;
  Future<void>? _discoveryRequest;

  /// In-memory presence truth — updated by every socket presence event.
  /// Applied to state on every state write so API/cache overwrites never win.
  final Map<String, bool> _presenceOnline = {};
  final Map<String, String?> _presenceLastSeen = {};

  ChatDiscoveryNotifier(
    this._repository,
    this._socketService,
    this._currentUserId,
  ) : super(const AsyncValue.loading()) {
    loadDiscovery();
    _setupRealtimeUpdates();
    _setupPresenceQuerySubscription();
    _setupPeriodicRefresh();
  }

  /// Write [nextState] to [state] after merging any in-memory presence overrides.
  /// This guarantees presence events are never lost to API/cache overwrites.
  void _setDiscoveryState(ChatDiscoveryModel nextState) {
    if (!mounted) return;
    if (_presenceOnline.isEmpty) {
      state = AsyncValue.data(nextState);
      return;
    }
    // Merge cached presence into conversations
    final convs = nextState.conversations.map((conv) {
      bool changed = false;
      final members = conv.members.map((m) {
        final online = _presenceOnline[m.userId];
        final lastSeen = _presenceLastSeen[m.userId];
        if (online != null && (m.isOnline != online || (lastSeen != null && m.lastSeen != lastSeen))) {
          changed = true;
          return m.copyWith(isOnline: online, lastSeen: lastSeen ?? m.lastSeen);
        }
        return m;
      }).toList();
      return changed ? conv.copyWith(members: members) : conv;
    }).toList();
    // Merge into allUsers
    final users = nextState.allUsers.map((u) {
      final online = _presenceOnline[u.id];
      final lastSeen = _presenceLastSeen[u.id];
      final newLastSeenAt = lastSeen != null ? DateTime.tryParse(lastSeen) : null;
      if (online != null && (u.isOnline != online || (newLastSeenAt != null && u.lastSeenAt != newLastSeenAt))) {
        return u.copyWith(isOnline: online, lastSeenAt: newLastSeenAt ?? u.lastSeenAt);
      }
      return u;
    }).toList();
    state = AsyncValue.data(nextState.copyWith(conversations: convs, allUsers: users));
  }

  Future<void> loadDiscovery() async {
    if (!mounted) return;
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
    // 1. Immediately hydrate state from Drift cache
    try {
      final cached = await _repository.getCachedConversations();
      if (!mounted) return;
      final cachedModel = ChatDiscoveryModel(conversations: cached);
      _setDiscoveryState(cachedModel);
      if (cached.isNotEmpty) _queryPresenceForAll(cachedModel);
    } catch (_) {
      if (!mounted) return;
      if (state.valueOrNull == null) _setDiscoveryState(const ChatDiscoveryModel());
    }

    // 2. Refresh from server
    try {
      final discovery = await _repository
          .getChatDiscovery()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (discovery.conversations.isNotEmpty ||
          discovery.allUsers.isNotEmpty ||
          discovery.publicGroups.isNotEmpty ||
          state.valueOrNull == null ||
          state.valueOrNull!.conversations.isEmpty) {
        _setDiscoveryState(discovery);
        _queryPresenceForAll(discovery);
      }
    } catch (e) {
      if (!mounted) return;
      if (state.valueOrNull == null) {
        final cached = await _repository.getCachedConversations();
        if (!mounted) return;
        _setDiscoveryState(ChatDiscoveryModel(conversations: cached));
      }
    }
  }

  Future<void> refreshDiscovery() async {
    if (!mounted) return;
    if (_discoveryRequest != null) return _discoveryRequest!;
    final prev = mounted ? state.value : null;
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
      if (!mounted) return;
      if (discovery.conversations.isNotEmpty ||
          discovery.allUsers.isNotEmpty ||
          discovery.publicGroups.isNotEmpty ||
          prev == null) {
        _setDiscoveryState(discovery);
      }
    } catch (e) {
      if (!mounted) return;
      if (prev != null) {
        _setDiscoveryState(prev);
      }
    }
  }

  void _setupRealtimeUpdates() {
    _messageSubscription = _socketService.messageReceived.listen((message) {
      if (!mounted) return;
      state.whenData((discovery) {
        if (!mounted) return;
        final conversations = [...discovery.conversations];
        final index = conversations.indexWhere(
          (c) => c.id == message.conversationId,
        );
        if (index != -1) {
          final conv = conversations[index];
          final isDelivered = message.deliveredTo.isNotEmpty;
          final isSeen = message.readBy.isNotEmpty;
          conversations[index] = conv.copyWith(
            lastMessageAt: message.createdAt,
            lastMessage: MessagePreviewModel(
              id: message.id,
              content: message.content,
              type: message.type,
              senderName: message.sender.displayName ?? message.sender.username,
              isMe: message.sender.id == _currentUserId,
              isDelivered: isDelivered,
              isSeen: isSeen,
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

          if (!mounted) return;
          state = AsyncValue.data(
            ChatDiscoveryModel(
              conversations: conversations,
              publicGroups: discovery.publicGroups,
              myPrivateGroups: discovery.myPrivateGroups,
              allUsers: discovery.allUsers,
            ),
          );
        } else {
          // New conversation received that wasn't in discovery list yet
          refreshDiscovery();
        }
      });
    });

    _readReceiptSubscription = _socketService.readReceipt.listen((data) {
      if (!mounted) return;
      final conversationId = data['conversationId'] as String?;
      final messageId = data['messageId'] as String?;
      final userId = data['userId'] as String?;
      if (conversationId == null && messageId == null) return;

      state.whenData((discovery) {
        if (!mounted) return;
        bool changed = false;
        final conversations = discovery.conversations.map((conv) {
          if ((conversationId != null && conv.id == conversationId) ||
              (messageId != null && conv.lastMessage?.id == messageId)) {
            var updatedConv = conv;
            // If the current user read messages in this conversation, reset our unread count
            if (userId == _currentUserId) {
              final memberIndex = updatedConv.members.indexWhere(
                (m) => m.userId == _currentUserId,
              );
              if (memberIndex != -1 && updatedConv.members[memberIndex].unreadCount > 0) {
                final members = [...updatedConv.members];
                members[memberIndex] = members[memberIndex].copyWith(unreadCount: 0);
                updatedConv = updatedConv.copyWith(members: members);
                changed = true;
              }
            }

            // If last message was sent by me, mark it seen and delivered
            if (updatedConv.lastMessage != null && updatedConv.lastMessage!.isMe == true) {
              if (updatedConv.lastMessage!.isSeen != true || updatedConv.lastMessage!.isDelivered != true) {
                updatedConv = updatedConv.copyWith(
                  lastMessage: updatedConv.lastMessage!.copyWith(
                    isSeen: true,
                    isDelivered: true,
                  ),
                );
                changed = true;
              }
            }
            return updatedConv;
          }
          return conv;
        }).toList();

        if (changed) {
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

    _deliveryReceiptSubscription = _socketService.deliveryReceipt.listen((data) {
      if (!mounted) return;
      final conversationId = data['conversationId'] as String?;
      final messageId = data['messageId'] as String?;
      if (conversationId == null && messageId == null) return;

      state.whenData((discovery) {
        if (!mounted) return;
        bool changed = false;
        final conversations = discovery.conversations.map((conv) {
          if ((conversationId != null && conv.id == conversationId) ||
              (messageId != null && conv.lastMessage?.id == messageId)) {
            if (conv.lastMessage != null &&
                conv.lastMessage!.isMe == true &&
                conv.lastMessage!.isDelivered != true &&
                conv.lastMessage!.isSeen != true) {
              changed = true;
              return conv.copyWith(
                lastMessage: conv.lastMessage!.copyWith(isDelivered: true),
              );
            }
          }
          return conv;
        }).toList();

        if (changed) {
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

    _presenceSubscription = _socketService.presence.listen((data) {
      if (!mounted) return;
      final userId = data['userId'] as String?;
      final status = data['status'] as String?;
      final lastSeen = data['lastSeen'] as String?;
      if (userId == null || status == null) return;
      final isOnline = status.toUpperCase() == 'ONLINE';

      // Always update the in-memory presence cache first.
      // This ensures events received while state is loading are not lost.
      _presenceOnline[userId] = isOnline;
      if (lastSeen != null) _presenceLastSeen[userId] = lastSeen;
      if (!isOnline && lastSeen == null) {
        _presenceLastSeen[userId] = DateTime.now().toIso8601String();
      }

      // Now apply to current state if data is available
      final discovery = state.valueOrNull;
      if (discovery == null || !mounted) return;

      bool changed = false;

      final convs = discovery.conversations.map((conv) {
        bool convChanged = false;
        final members = conv.members.map((m) {
          if (m.userId == userId) {
            final cachedLastSeen = _presenceLastSeen[userId];
            if (m.isOnline != isOnline || (cachedLastSeen != null && m.lastSeen != cachedLastSeen)) {
              convChanged = true;
              return m.copyWith(
                isOnline: isOnline,
                lastSeen: cachedLastSeen ?? m.lastSeen,
              );
            }
          }
          return m;
        }).toList();
        if (convChanged) {
          changed = true;
          return conv.copyWith(members: members);
        }
        return conv;
      }).toList();

      final users = discovery.allUsers.map((u) {
        if (u.id == userId) {
          final cachedLastSeen = _presenceLastSeen[u.id];
          final newLastSeenAt = cachedLastSeen != null ? DateTime.tryParse(cachedLastSeen) : u.lastSeenAt;
          if (u.isOnline != isOnline || (newLastSeenAt != null && u.lastSeenAt != newLastSeenAt)) {
            changed = true;
            return u.copyWith(isOnline: isOnline, lastSeenAt: newLastSeenAt);
          }
        }
        return u;
      }).toList();

      if (changed) {
        if (!mounted) return;
        state = AsyncValue.data(
          ChatDiscoveryModel(
            conversations: convs,
            publicGroups: discovery.publicGroups,
            myPrivateGroups: discovery.myPrivateGroups,
            allUsers: users,
          ),
        );
      }
    });
  }

  /// Bulk-query live presence for every user in the current discovery state.
  void _queryPresenceForAll(ChatDiscoveryModel discovery) {
    final ids = <String>{};
    for (final conv in discovery.conversations) {
      for (final m in conv.members) {
        if (m.userId.isNotEmpty) ids.add(m.userId);
      }
    }
    for (final u in discovery.allUsers) {
      if (u.id.isNotEmpty) ids.add(u.id);
    }
    if (ids.isNotEmpty) {
      _socketService.queryPresence(ids.toList());
    }
  }

  /// Subscribe to bulk presence query responses so we can refresh
  /// the local presence map whenever we fire a query.
  void _setupPresenceQuerySubscription() {
    _presenceQuerySubscription = _socketService.presenceQueryResponse.listen((_) {
      // The individual presence events emitted by the socket service
      // will be handled by _presenceSubscription automatically.
      // Nothing extra needed here, but we keep the subscription open.
    });
  }

  void _setupPeriodicRefresh() {
    // Re-query presence every 20s to recover from missed events
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      final discovery = state.valueOrNull;
      if (discovery != null) _queryPresenceForAll(discovery);
    });

    // On socket connect/reconnect, wait for discovery data then query presence
    _socketService.connectionStatus.listen((connected) {
      if (!mounted || !connected) return;
      _retryPresenceQueryWhenReady();
    });
  }

  /// Polls until discovery data is available, then fires presence query.
  /// Gives up after 30 seconds to avoid an infinite loop.
  void _retryPresenceQueryWhenReady({int attempt = 0}) {
    if (!mounted) return;
    final discovery = state.valueOrNull;
    if (discovery != null) {
      _queryPresenceForAll(discovery);
      return;
    }
    if (attempt > 30) return; // max 30s
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _retryPresenceQueryWhenReady(attempt: attempt + 1);
    });
  }

  Future<void> markAsRead(String conversationId) async {
    _socketService.markConversationAsRead(conversationId);
    await _repository.markConversationAsRead(conversationId);
    if (!mounted) return;
    state.whenData((discovery) {
      if (!mounted) return;
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
          if (!mounted) return;
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
    // Optimistically inject the new conversation into state immediately so the
    // header/details panel can render before the full refresh completes.
    injectConversation(conv);
    // Background-refresh discovery (non-blocking from caller's perspective)
    refreshDiscovery();
    return conv;
  }

  Future<ConversationModel> createOrGetGroupConversation(String groupId) async {
    final conv = await _repository.createOrGetGroupConversation(groupId);
    // Optimistically inject so the center panel & details panel render instantly.
    injectConversation(conv);
    refreshDiscovery();
    return conv;
  }

  /// Injects [conv] into the current discovery state if it is not already there.
  /// If it already exists (same id), the entry is replaced with the fresh data.
  void injectConversation(ConversationModel conv) {
    if (!mounted) return;
    state.whenData((discovery) {
      if (!mounted) return;
      final convs = [...discovery.conversations];
      final idx = convs.indexWhere((c) => c.id == conv.id);
      if (idx == -1) {
        convs.insert(0, conv);
      } else {
        convs[idx] = conv;
      }
      if (!mounted) return;
      state = AsyncValue.data(
        ChatDiscoveryModel(
          conversations: convs,
          publicGroups: discovery.publicGroups,
          myPrivateGroups: discovery.myPrivateGroups,
          allUsers: discovery.allUsers,
        ),
      );
    });
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
    if (!mounted) return 0;
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
    _discoveryRequest = null;
    _messageSubscription?.cancel();
    _presenceSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _deliveryReceiptSubscription?.cancel();
    _presenceQuerySubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// Backward compatibility alias for conversationsProvider
final conversationsProvider = chatDiscoveryProvider;

/// Fetches and caches a single conversation by ID.
/// First looks in discovery cache. If missing, fetches from repository
/// and injects it into discovery state so all panels stay in sync.
final singleConversationProvider =
    FutureProvider.family<ConversationModel, String>((ref, conversationId) async {
  final discovery = ref.watch(chatDiscoveryProvider).value;
  if (discovery != null) {
    for (final c in discovery.conversations) {
      if (c.id == conversationId) return c;
    }
  }

  final repo = ref.read(chatRepositoryProvider);
  final conv = await repo.getConversationById(conversationId);
  ref.read(chatDiscoveryProvider.notifier).injectConversation(conv);
  return conv;
});

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
      final isSelf = user.id == currentUserId;

      // Check if already have active direct conversation
      final alreadyInConvs = discovery.conversations.any(
        (c) => c.type == 'DIRECT' && c.members.any((m) => m.userId == user.id),
      );

      if (!alreadyInConvs) {
        items.add(
          UnifiedChatItem(
            id: 'user_${user.id}',
            title: isSelf ? '${user.displayName} (You)' : user.displayName,
            subtitle: isSelf
                ? 'Message yourself'
                : (user.bio ??
                    (user.username != null
                        ? '@${user.username}'
                        : 'Joined StreamHub')),
            avatarUrl: user.avatarUrl,
            type: UnifiedChatType.user,
            sortDate: user.createdAt,
            isOnline: isSelf ? true : user.isOnline,
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
