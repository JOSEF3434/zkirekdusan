// lib/features/chats/presentation/providers/conversations_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/data/repositories/chat_repository_impl.dart';
import 'package:mobile/features/chats/domain/repositories/chat_repository.dart';
import 'package:mobile/features/chats/data/datasources/messaging_socket_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/rich_text/rich_text_renderer.dart';

/// In-memory reactive map for live user presence (userId -> isOnline)
final livePresenceMapProvider = StateProvider<Map<String, bool>>((ref) => {});

/// In-memory reactive map for live user last seen (userId -> ISO string)
final liveLastSeenMapProvider = StateProvider<Map<String, String?>>((ref) => {});

/// Instant, single source of truth for a user's online state
final userOnlineStatusProvider = Provider.family<bool, String>((ref, userId) {
  if (userId.isEmpty) return false;
  final map = ref.watch(livePresenceMapProvider);
  if (map.containsKey(userId)) return map[userId]!;
  final discovery = ref.watch(chatDiscoveryProvider).value;
  if (discovery != null) {
    for (final c in discovery.conversations) {
      for (final m in c.members) {
        if (m.userId == userId) return m.isOnline;
      }
    }
    for (final u in discovery.allUsers) {
      if (u.id == userId) return u.isOnline;
    }
  }
  return false;
});

/// Instant, single source of truth for a user's last seen status
final userLastSeenStatusProvider = Provider.family<String?, String>((ref, userId) {
  if (userId.isEmpty) return null;
  final map = ref.watch(liveLastSeenMapProvider);
  if (map.containsKey(userId)) return map[userId];
  final discovery = ref.watch(chatDiscoveryProvider).value;
  if (discovery != null) {
    for (final c in discovery.conversations) {
      for (final m in c.members) {
        if (m.userId == userId) return m.lastSeen;
      }
    }
    for (final u in discovery.allUsers) {
      if (u.id == userId) return u.lastSeenAt?.toIso8601String();
    }
  }
  return null;
});

/// Conversation ID currently open and visibly viewed in the foreground.
/// Kept distinct from mounted-but-hidden tabs inside StatefulNavigationShell.
final activeViewingConversationProvider = StateProvider<String?>((ref) => null);

/// Tracks whether the Chats shell tab is currently the active tab.
final isChatsTabActiveProvider = StateProvider<bool>((ref) => true);

/// Reactive user-wide unread chat message counter for badges and filters.
final totalUnreadChatCountProvider = Provider<int>((ref) {
  final currentUserId = ref.watch(authProvider.select((auth) => auth.user?.id));
  if (currentUserId == null || currentUserId.isEmpty) return 0;

  final discovery = ref.watch(chatDiscoveryProvider).valueOrNull;
  if (discovery == null) return 0;

  int total = 0;
  for (final conv in discovery.conversations) {
    for (final m in conv.members) {
      if (m.userId == currentUserId) {
        if (!m.isMuted) {
          total += m.unreadCount;
        }
        break;
      }
    }
  }
  return total;
});

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
        ref,
      );
    });

class ChatDiscoveryNotifier
    extends StateNotifier<AsyncValue<ChatDiscoveryModel>> {
  final ChatRepository _repository;
  final MessagingSocketService _socketService;
  final String? _currentUserId;
  final Ref? _ref;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _messageDeletedSubscription;
  StreamSubscription? _presenceSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _deliveryReceiptSubscription;
  StreamSubscription? _unreadUpdateSubscription;
  StreamSubscription? _presenceQuerySubscription;
  StreamSubscription? _connectionSubscription;
  Timer? _refreshTimer;
  Future<void>? _discoveryRequest;

  /// Bounded deduplication set keyed by stable server message ID so the same
  /// message never increments unread counts twice across socket/reconnect/API.
  final Set<String> _processedMessageIds = <String>{};

  /// Race-protection timestamps for HTTP refresh vs concurrent real-time events.
  final Map<String, DateTime> _lastSocketMessageAt = {};
  final Map<String, DateTime> _lastUnreadEventAt = {};
  final Map<String, int> _lastUnreadEventCount = {};
  final Map<String, DateTime> _lastLocalMarkReadAt = {};

  /// In-memory presence truth — updated by every socket presence event.
  /// Applied to state on every state write so API/cache overwrites never win.
  final Map<String, bool> _presenceOnline = {};
  final Map<String, String?> _presenceLastSeen = {};

  ChatDiscoveryNotifier(
    this._repository,
    this._socketService,
    this._currentUserId, [
    this._ref,
  ]) : super(const AsyncValue.loading()) {
    loadDiscovery();
    _setupRealtimeUpdates();
    _setupPresenceQuerySubscription();
    _setupPeriodicRefresh();
  }

  /// Write [nextState] to [state] after merging any in-memory presence overrides.
  /// This guarantees presence events are never lost to API/cache overwrites.
  void _setDiscoveryState(ChatDiscoveryModel nextState) {
    if (!mounted) return;

    // Sync live presence state with reactive map
    if (_ref != null) {
      final currentMap = _ref.read(livePresenceMapProvider);
      final updatedMap = Map<String, bool>.from(currentMap);
      for (final conv in nextState.conversations) {
        for (final m in conv.members) {
          if (!updatedMap.containsKey(m.userId)) {
            updatedMap[m.userId] = _presenceOnline[m.userId] ?? m.isOnline;
          }
        }
      }
      for (final u in nextState.allUsers) {
        if (!updatedMap.containsKey(u.id)) {
          updatedMap[u.id] = _presenceOnline[u.id] ?? u.isOnline;
        }
      }
      _ref.read(livePresenceMapProvider.notifier).state = updatedMap;
    }

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

  bool _recordProcessedMessageId(String messageId) {
    if (messageId.isEmpty) return false;
    if (_processedMessageIds.length > 2000) {
      _processedMessageIds.clear();
    }
    return _processedMessageIds.add(messageId);
  }

  void _seedProcessedMessageIds(List<ConversationModel> conversations) {
    for (final c in conversations) {
      final lastId = c.lastMessage?.id;
      if (lastId != null && lastId.isNotEmpty) {
        _recordProcessedMessageId(lastId);
      }
    }
  }

  /// Merges remote server discovery against newer local real-time state so an
  /// older in-flight API snapshot never clobbers a message or read event that
  /// arrived via Socket.IO after the HTTP request began.
  ChatDiscoveryModel _mergeDiscoveryWithRealtime(
    ChatDiscoveryModel remote,
    DateTime requestStartedAt,
  ) {
    final existingMap = {
      for (final c in state.valueOrNull?.conversations ?? <ConversationModel>[])
        c.id: c,
    };
    final activeConvId = _ref?.read(activeViewingConversationProvider);

    final mergedConversations = remote.conversations.map((remoteConv) {
      final existing = existingMap[remoteConv.id];
      final socketMsgAt = _lastSocketMessageAt[remoteConv.id];
      final remoteMsgAt = remoteConv.lastMessageAt;

      ConversationModel resolved = remoteConv;
      if (existing != null &&
          socketMsgAt != null &&
          socketMsgAt.isAfter(requestStartedAt)) {
        final existingAt = existing.lastMessageAt;
        if (existingAt != null &&
            (remoteMsgAt == null || existingAt.isAfter(remoteMsgAt))) {
          resolved = existing;
        }
      }

      final localReadAt = _lastLocalMarkReadAt[resolved.id];
      final authUnreadAt = _lastUnreadEventAt[resolved.id];
      final authUnread = _lastUnreadEventCount[resolved.id];

      if (activeConvId == resolved.id ||
          (localReadAt != null && localReadAt.isAfter(requestStartedAt))) {
        resolved = _withMemberUnreadCount(resolved, 0);
      } else if (authUnread != null &&
          authUnreadAt != null &&
          authUnreadAt.isAfter(requestStartedAt)) {
        resolved = _withMemberUnreadCount(resolved, authUnread);
      }

      return resolved;
    }).toList();

    _seedProcessedMessageIds(mergedConversations);
    return remote.copyWith(conversations: mergedConversations);
  }

  ConversationModel _withMemberUnreadCount(
    ConversationModel conv,
    int unreadCount,
  ) {
    if (_currentUserId == null || _currentUserId.isEmpty) return conv;
    final memberIndex = conv.members.indexWhere(
      (m) => m.userId == _currentUserId,
    );
    if (memberIndex == -1) return conv;
    if (conv.members[memberIndex].unreadCount == unreadCount) return conv;
    final members = [...conv.members];
    members[memberIndex] = members[memberIndex].copyWith(
      unreadCount: unreadCount < 0 ? 0 : unreadCount,
    );
    return conv.copyWith(members: members);
  }

  Future<void> _loadDiscovery() async {
    if (_currentUserId == null || _currentUserId.isEmpty) {
      if (mounted) _setDiscoveryState(const ChatDiscoveryModel());
      return;
    }

    // 1. Immediately hydrate state from Drift cache
    try {
      final cached = await _repository.getCachedConversations();
      if (!mounted) return;
      _seedProcessedMessageIds(cached);
      final cachedModel = ChatDiscoveryModel(conversations: cached);
      _setDiscoveryState(cachedModel);
      if (cached.isNotEmpty) _queryPresenceForAll(cachedModel);
    } catch (_) {
      if (!mounted) return;
      if (state.valueOrNull == null) _setDiscoveryState(const ChatDiscoveryModel());
    }

    // 2. Refresh from server
    final requestStartedAt = DateTime.now();
    try {
      final discovery = await _repository
          .getChatDiscovery()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (discovery.conversations.isNotEmpty ||
          discovery.allUsers.isNotEmpty ||
          discovery.publicGroups.isNotEmpty ||
          discovery.channels.isNotEmpty ||
          state.valueOrNull == null ||
          state.valueOrNull!.conversations.isEmpty) {
        final merged = _mergeDiscoveryWithRealtime(discovery, requestStartedAt);
        _setDiscoveryState(merged);
        _queryPresenceForAll(merged);
      }
    } catch (e) {
      if (!mounted) return;
      if (state.valueOrNull == null) {
        final cached = await _repository.getCachedConversations();
        if (!mounted) return;
        _seedProcessedMessageIds(cached);
        _setDiscoveryState(ChatDiscoveryModel(conversations: cached));
      }
    }
  }

  Future<void> refreshDiscovery() async {
    if (!mounted) return;
    if (_currentUserId == null || _currentUserId.isEmpty) return;
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
    final requestStartedAt = DateTime.now();
    try {
      final discovery = await _repository
          .getChatDiscovery()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (discovery.conversations.isNotEmpty ||
          discovery.allUsers.isNotEmpty ||
          discovery.publicGroups.isNotEmpty ||
          discovery.channels.isNotEmpty ||
          prev == null) {
        final merged = _mergeDiscoveryWithRealtime(discovery, requestStartedAt);
        _setDiscoveryState(merged);
        _queryPresenceForAll(merged);
      }
    } catch (e) {
      if (!mounted) return;
      if (prev != null) {
        _setDiscoveryState(prev);
      }
    }
  }

  void _setupRealtimeUpdates() {
    _connectionSubscription = _socketService.connectionStatus.listen((connected) {
      if (connected && mounted) {
        refreshDiscovery();
        _retryPresenceQueryWhenReady();
      }
    });

    _messageSubscription = _socketService.messageReceived.listen((message) {
      if (!mounted) return;
      final isFirstSeen = _recordProcessedMessageId(message.id);
      if (!isFirstSeen) return;

      final senderId = message.sender.id;
      final isFromMe = _currentUserId != null && senderId == _currentUserId;
      final activeConvId = _ref?.read(activeViewingConversationProvider);
      final isActivelyViewing = activeConvId == message.conversationId;

      if (!isFromMe &&
          _currentUserId != null &&
          !message.deliveredTo.contains(_currentUserId)) {
        _socketService.markDelivered(message.conversationId, message.id);
      }

      final discovery = state.valueOrNull;
      if (discovery == null) {
        refreshDiscovery();
        return;
      }

      final conversations = [...discovery.conversations];
      final index = conversations.indexWhere(
        (c) => c.id == message.conversationId,
      );
      if (index != -1) {
        final conv = conversations[index];
        // Guard against double-counting if API refresh already surfaced this message
        final alreadyPreviewed = conv.lastMessage?.id == message.id;
        _lastSocketMessageAt[message.conversationId] = DateTime.now();

        final isDelivered = message.deliveredTo.any(
          (u) => u.isNotEmpty && u != senderId,
        );
        final isSeen = message.readBy.any(
          (u) => u.isNotEmpty && u != senderId,
        );

        var updatedConv = conv.copyWith(
          lastMessageAt: message.createdAt,
          lastMessage: MessagePreviewModel(
            id: message.id,
            content: message.content,
            type: message.type,
            senderName: message.sender.displayName ?? message.sender.username,
            isMe: isFromMe,
            isDelivered: isDelivered,
            isSeen: isSeen,
            isPending: false,
            isFailed: false,
          ),
        );

        if (!isFromMe && _currentUserId != null) {
          final memberIndex = updatedConv.members.indexWhere(
            (m) => m.userId == _currentUserId,
          );
          if (memberIndex != -1) {
            final members = [...updatedConv.members];
            final currentUnread = members[memberIndex].unreadCount;
            final nextUnread = isActivelyViewing
                ? 0
                : (alreadyPreviewed ? currentUnread : currentUnread + 1);
            members[memberIndex] = members[memberIndex].copyWith(
              unreadCount: nextUnread,
            );
            updatedConv = updatedConv.copyWith(members: members);
          }
        }

        // Move updated conversation to the front so list ordering reacts immediately
        conversations.removeAt(index);
        conversations.insert(0, updatedConv);

        if (!mounted) return;
        _setDiscoveryState(discovery.copyWith(conversations: conversations));
      } else {
        // New conversation received that wasn't in discovery list yet
        refreshDiscovery();
      }
    });

    _unreadUpdateSubscription = _socketService.unreadUpdate.listen((data) {
      if (!mounted) return;
      final conversationId = data['conversationId'] as String?;
      final rawCount = data['unreadCount'];
      final unreadCount = rawCount is num ? rawCount.toInt() : null;
      if (conversationId == null || unreadCount == null) return;

      _lastUnreadEventAt[conversationId] = DateTime.now();
      _lastUnreadEventCount[conversationId] = unreadCount < 0 ? 0 : unreadCount;

      final activeConvId = _ref?.read(activeViewingConversationProvider);
      final effectiveCount =
          activeConvId == conversationId ? 0 : (unreadCount < 0 ? 0 : unreadCount);

      final discovery = state.valueOrNull;
      if (discovery == null) {
        refreshDiscovery();
        return;
      }

      final conversations = [...discovery.conversations];
      final index = conversations.indexWhere((c) => c.id == conversationId);
      if (index == -1) {
        refreshDiscovery();
        return;
      }

      final updated = _withMemberUnreadCount(
        conversations[index],
        effectiveCount,
      );
      if (updated != conversations[index]) {
        conversations[index] = updated;
        _setDiscoveryState(discovery.copyWith(conversations: conversations));
      }
    });

    _messageDeletedSubscription = _socketService.messageDeleted.listen((data) {
      if (!mounted) return;
      final conversationId = data['conversationId'];
      final messageId = data['messageId'];
      if (conversationId == null || messageId == null) return;

      final discovery = state.valueOrNull;
      if (discovery == null) return;
      final matchesPreview = discovery.conversations.any(
        (c) => c.id == conversationId && c.lastMessage?.id == messageId,
      );
      if (matchesPreview) {
        refreshDiscovery();
      }
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
          final matchesConv =
              (conversationId != null && conv.id == conversationId) ||
              (messageId != null && conv.lastMessage?.id == messageId);
          if (matchesConv) {
            var updatedConv = conv;
            // If the current user read messages in this conversation, reset our unread count
            if (userId == _currentUserId) {
              _lastLocalMarkReadAt[conv.id] = DateTime.now();
              final cleared = _withMemberUnreadCount(updatedConv, 0);
              if (cleared != updatedConv) {
                updatedConv = cleared;
                changed = true;
              }
            }

            // Only update last outgoing message preview when a genuine OTHER
            // recipient has read that specific message (never on self-read).
            final isRecipientRead =
                userId != null &&
                _currentUserId != null &&
                userId != _currentUserId;
            final matchesLastMessage =
                updatedConv.lastMessage != null &&
                updatedConv.lastMessage!.isMe == true &&
                (messageId == null || updatedConv.lastMessage!.id == messageId);

            if (isRecipientRead && matchesLastMessage) {
              if (updatedConv.lastMessage!.isSeen != true ||
                  updatedConv.lastMessage!.isDelivered != true) {
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
          _setDiscoveryState(discovery.copyWith(conversations: conversations));
        }
      });
    });

    _deliveryReceiptSubscription = _socketService.deliveryReceipt.listen((data) {
      if (!mounted) return;
      final conversationId = data['conversationId'] as String?;
      final messageId = data['messageId'] as String?;
      final userId = data['userId'] as String?;
      if (conversationId == null && messageId == null) return;
      // Never treat sender's own ID as a recipient delivery acknowledgement
      if (userId != null &&
          _currentUserId != null &&
          userId == _currentUserId) {
        return;
      }

      state.whenData((discovery) {
        if (!mounted) return;
        bool changed = false;
        final conversations = discovery.conversations.map((conv) {
          final matchesConv =
              (conversationId == null || conv.id == conversationId);
          final matchesLastMessage =
              conv.lastMessage != null &&
              conv.lastMessage!.isMe == true &&
              (messageId == null || conv.lastMessage!.id == messageId);
          if (matchesConv && matchesLastMessage) {
            if (conv.lastMessage!.isDelivered != true &&
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
          _setDiscoveryState(discovery.copyWith(conversations: conversations));
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
      // Note: do NOT fabricate a local lastSeen timestamp when the server
      // did not provide one.  The backend records lastSeenAt only on the
      // OFFLINE transition and always sends it in the presence:changed payload.
      // Inventing a local "now" timestamp would cause "last seen just now" to
      // appear incorrectly.

      // Sync with reactive Riverpod providers so UI rebuilds instantly
      if (_ref != null) {
        _ref.read(livePresenceMapProvider.notifier).update(
          (m) => {...m, userId: isOnline},
        );
        final effLastSeen = _presenceLastSeen[userId];
        if (effLastSeen != null) {
          _ref.read(liveLastSeenMapProvider.notifier).update(
            (m) => {...m, userId: effLastSeen},
          );
        }
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
          discovery.copyWith(
            conversations: convs,
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
    _lastLocalMarkReadAt[conversationId] = DateTime.now();
    _lastUnreadEventAt[conversationId] = DateTime.now();
    _lastUnreadEventCount[conversationId] = 0;

    // Clear unread count locally immediately so badges react with zero lag.
    state.whenData((discovery) {
      if (!mounted) return;
      final conversations = [...discovery.conversations];
      final index = conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        final cleared = _withMemberUnreadCount(conversations[index], 0);
        if (cleared != conversations[index]) {
          conversations[index] = cleared;
          _setDiscoveryState(discovery.copyWith(conversations: conversations));
        }
      }
    });

    _socketService.markConversationAsRead(conversationId);
    await _repository.markConversationAsRead(conversationId);
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
      _setDiscoveryState(
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

  Future<Map<String, dynamic>> requestChannelCreation({
    required String name,
    required String handle,
    String? description,
    String? category,
  }) async {
    final dio = _ref?.read(apiClientProvider);
    if (dio == null) throw Exception('API client unavailable');
    final response = await dio.post(
      '/video-channels',
      data: {
        'name': name,
        'handle': handle.startsWith('@') ? handle : '@$handle',
        if (description != null && description.isNotEmpty)
          'description': description,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    await refreshDiscovery();
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {'success': true};
  }

  Future<void> subscribeChannel(String channelId) async {
    final dio = _ref?.read(apiClientProvider);
    if (dio != null) {
      await dio.post('/video-channels/$channelId/subscribe');
      await refreshDiscovery();
    }
  }

  Future<void> unsubscribeChannel(String channelId) async {
    final dio = _ref?.read(apiClientProvider);
    if (dio != null) {
      await dio.delete('/video-channels/$channelId/subscribe');
      await refreshDiscovery();
    }
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

  /// Synchronizes the conversation preview directly from an outgoing local,
  /// acknowledged, or failed message so the conversation list stays aligned
  /// with message bubbles in real time.
  void syncLocalLastMessage(
    String conversationId,
    MessagePreviewModel preview, {
    DateTime? lastMessageAt,
  }) {
    if (!mounted) return;
    state.whenData((discovery) {
      if (!mounted) return;
      final conversations = [...discovery.conversations];
      final index = conversations.indexWhere((c) => c.id == conversationId);
      if (index == -1) return;

      final existing = conversations[index];
      final existingPreview = existing.lastMessage;
      final mergedPreview =
          existingPreview != null && existingPreview.id == preview.id
              ? preview.copyWith(
                  isSeen: preview.isSeen == true || existingPreview.isSeen == true,
                  isDelivered:
                      preview.isDelivered == true ||
                      existingPreview.isDelivered == true,
                )
              : preview;

      conversations[index] = existing.copyWith(
        lastMessageAt: lastMessageAt ?? existing.lastMessageAt,
        lastMessage: mergedPreview,
      );

      _setDiscoveryState(
        discovery.copyWith(conversations: conversations),
      );
    });
  }

  @override
  void dispose() {
    _discoveryRequest = null;
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _presenceSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _deliveryReceiptSubscription?.cancel();
    _unreadUpdateSubscription?.cancel();
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

      final subtitle = conv.lastMessage?.content != null
          ? stripTokens(conv.lastMessage!.content!)
          : (conv.type == 'DIRECT' ? 'Direct Message' : 'Group Chat');

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

    // 5. Broadcasting Channels (YouTube-Style Content Platform)
    for (final ch in discovery.channels) {
      items.add(
        UnifiedChatItem(
          id: 'channel_${ch.id}',
          title: ch.name,
          subtitle: ch.latestContentTitle != null && ch.latestContentTitle!.isNotEmpty
              ? ch.latestContentTitle
              : (ch.description != null && ch.description!.isNotEmpty
                  ? ch.description
                  : '${ch.handle.isNotEmpty ? (ch.handle.startsWith('@') ? ch.handle : '@${ch.handle}') : ch.name} • ${ch.subscribersCount} subscribers'),
          avatarUrl: ch.avatarUrl,
          bannerUrl: ch.bannerUrl,
          type: UnifiedChatType.channel,
          sortDate: ch.latestContentAt ?? ch.createdAt,
          subscribersCount: ch.subscribersCount,
          videosCount: ch.videosCount,
          handle: ch.handle,
          status: ch.status,
          isSubscribed: ch.isSubscribed,
          isOwner: ch.isOwner,
          isVerified: ch.isVerified,
          targetChannelId: ch.id,
        ),
      );
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
            .where((i) => i.type == UnifiedChatType.channel)
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
