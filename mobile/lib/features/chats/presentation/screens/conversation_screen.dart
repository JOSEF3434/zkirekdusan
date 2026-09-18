import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/chats/presentation/providers/chat_messages_provider.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/message_bubble.dart';
import 'package:mobile/features/chats/presentation/widgets/message_composer.dart';
import 'package:mobile/features/chats/presentation/widgets/date_separator.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/presentation/widgets/pinned_messages_bar.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calls/services/call_service.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ConversationScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();
  String? _replyToMessageId;
  MessageModel? _editingMessage;

  bool _hasInitialScrolled = false;
  int _lastMessageCount = 0;

  void _scrollToMessage(String messageId, List<MessageModel> messageList) {
    final index = messageList.indexWhere((m) => m.id == messageId);
    if (index != -1 && _scrollController.hasClients) {
      final target = (index * 75.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(max);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Mark conversation as read when opening
    Future.microtask(() {
      ref
          .read(conversationsProvider.notifier)
          .markAsRead(widget.conversationId);
      final currentUserId = ref.read(authProvider).user?.id;
      if (currentUserId != null) {
        ref
            .read(chatMessagesProvider(widget.conversationId).notifier)
            .markIncomingAsRead(currentUserId);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 100) {
      ref
          .read(chatMessagesProvider(widget.conversationId).notifier)
          .loadMoreMessages();
    }
    final currentUserId = ref.read(authProvider).user?.id;
    if (currentUserId != null) {
      ref
          .read(chatMessagesProvider(widget.conversationId).notifier)
          .markIncomingAsRead(currentUserId);
    }
  }

  @override
  void didUpdateWidget(covariant ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _hasInitialScrolled = false;
      _lastMessageCount = 0;
      Future.microtask(() {
        ref
            .read(conversationsProvider.notifier)
            .markAsRead(widget.conversationId);
        final currentUserId = ref.read(authProvider).user?.id;
        if (currentUserId != null) {
          ref
              .read(chatMessagesProvider(widget.conversationId).notifier)
              .markIncomingAsRead(currentUserId);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));
    final discoveryAsync = ref.watch(chatDiscoveryProvider);
    final currentUserId = ref.watch(authProvider).user?.id;
    final typingUsers = ref.watch(
      typingIndicatorProvider(widget.conversationId),
    );
    final tr = ref.watch(trProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOffline = ref.watch(connectivityProvider).isOffline;

    final singleConvAsync = ref.watch(
      singleConversationProvider(widget.conversationId),
    );
    ConversationModel? conversation = singleConvAsync.value;
    if (conversation == null) {
      discoveryAsync.whenData((discovery) {
        try {
          conversation = discovery.conversations.firstWhere(
            (c) => c.id == widget.conversationId,
          );
        } catch (_) {}
      });
    }

    final otherMember = conversation?.type == 'DIRECT'
        ? conversation?.members.firstWhere(
            (m) => m.userId != currentUserId,
            orElse: () => conversation!.members.isNotEmpty
                ? conversation!.members.first
                : const ConversationMemberModel(userId: '', username: ''),
          )
        : null;

    final chatList = ref.watch(unifiedChatListProvider).value ?? [];
    final listItem = chatList
        .where(
          (i) =>
              i.conversationId == widget.conversationId ||
              i.id == widget.conversationId ||
              (conversation?.groupId != null &&
                  i.targetGroupId == conversation!.groupId) ||
              (otherMember?.userId != null &&
                  i.targetUserId == otherMember!.userId),
        )
        .firstOrNull;

    final displayName =
        (conversation?.title != null && conversation!.title!.isNotEmpty)
        ? conversation!.title!
        : (otherMember?.displayName ??
              otherMember?.username ??
              listItem?.title ??
              'Chat');

    final headerAvatarUrl =
        otherMember?.avatarUrl ??
        conversation?.metadata?.groupAvatar ??
        listItem?.avatarUrl;
    final resolvedAvatarUrl = MediaUrlResolver.resolve(headerAvatarUrl);

    final isOnline = otherMember?.isOnline ?? listItem?.isOnline ?? false;
    final isGroup = conversation?.type != 'DIRECT' && conversation != null;
    final pinnedMessagesAsync = ref.watch(
      pinnedMessagesProvider(widget.conversationId),
    );
    final currentUserRole = ref.watch(authProvider).user?.role;
    final isGlobalAdmin =
        currentUserRole == 'ADMIN' || currentUserRole == 'SUPER_ADMIN';
    final isGroupOwnerOrAdmin =
        !isGroup ||
        isGlobalAdmin ||
        (conversation?.groupId != null &&
            discoveryAsync.value?.myPrivateGroups.any(
                  (g) => g.id == conversation!.groupId,
                ) ==
                true);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E14)
          : const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF131822) : Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: InkWell(
          onTap: () {
            if (otherMember?.username != null) {
              context.push('/profile/user/${otherMember!.username}');
            } else if (conversation?.groupId != null) {
              context.push('/groups/${conversation!.groupId}');
            }
          },
          child: Row(
            children: [
              // Avatar with Online indicator (matching Screenshot 2)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(
                      0xFF00C6FF,
                    ).withValues(alpha: 0.2),
                    backgroundImage:
                        (resolvedAvatarUrl != null &&
                            resolvedAvatarUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(resolvedAvatarUrl)
                        : null,
                    child:
                        (resolvedAvatarUrl == null || resolvedAvatarUrl.isEmpty)
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              color: Color(0xFF00C6FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          )
                        : null,
                  ),
                  if (isOnline && !isGroup)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF131822)
                                : Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),

              // Title and Online Status Subtitle (matching Screenshot 2)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    if (typingUsers.isNotEmpty)
                      Text(
                        tr('chat.typing'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00C6FF),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (isOnline && !isGroup)
                      Text(
                        tr('chat.online'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (isGroup)
                      Text(
                        '${conversation?.members.length ?? 0} members',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      )
                    else if (otherMember?.lastSeen != null)
                      Text(
                        'last seen ${_formatLastSeen(otherMember!.lastSeen!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      )
                    else
                      Text(
                        'Offline',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Voice Call Icon
          IconButton(
            icon: const Icon(Icons.call_outlined, size: 22),
            onPressed: () => _startCall(
              context: context,
              conversation: conversation,
              otherMember: otherMember,
              isVideo: false,
            ),
          ),
          // Video Call Icon
          IconButton(
            icon: const Icon(Icons.videocam_outlined, size: 24),
            onPressed: () => _startCall(
              context: context,
              conversation: conversation,
              otherMember: otherMember,
              isVideo: true,
            ),
          ),
          // More Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            color: isDark ? const Color(0xFF161C28) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) =>
                _handleMenuAction(value, conversation, otherMember),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('View Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.volume_off_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Mute Notifications'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 12),
                    Text('Search in Chat'),
                  ],
                ),
              ),
              if (conversation?.groupId != null)
                const PopupMenuItem(
                  value: 'invite_link',
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        color: Color(0xFF00C6FF),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text('Group Invite Link'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Clear Chat',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF7F9FC),
        ),
        child: Column(
          children: [
            if (isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 16,
                ),
                color: isDark
                    ? const Color(0xFF1E1A11)
                    : const Color(0xFFFFFBEB),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 14,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Offline • Displaying local cached messages',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            // Telegram-Style Pinned Messages Top Bar
            pinnedMessagesAsync.when(
              data: (pins) => PinnedMessagesBar(
                pinnedMessages: pins,
                canUnpin: isGroupOwnerOrAdmin,
                onSelectMessage: (pinnedMsg) {
                  messages.whenData(
                    (list) => _scrollToMessage(pinnedMsg.id, list),
                  );
                },
                onUnpinMessage: (pinnedMsg) {
                  ref
                      .read(
                        chatMessagesProvider(widget.conversationId).notifier,
                      )
                      .unpinMessage(pinnedMsg.id);
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),

            // Messages list area
            Expanded(
              child: messages.when(
                data: (messageList) {
                  if (messageList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xFF00C6FF,
                              ).withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 36,
                              color: Color(0xFF00C6FF),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No messages here yet...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Send a message to start the conversation',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Start at newest message (bottom) when reopening or initially loaded
                  if (!_hasInitialScrolled) {
                    _hasInitialScrolled = true;
                    _lastMessageCount = messageList.length;
                    _scrollToBottom(animate: false);
                    final currentUserId = ref.read(authProvider).user?.id;
                    if (currentUserId != null) {
                      Future.microtask(
                        () => ref
                            .read(
                              chatMessagesProvider(
                                widget.conversationId,
                              ).notifier,
                            )
                            .markIncomingAsRead(currentUserId),
                      );
                    }
                  } else if (messageList.length > _lastMessageCount) {
                    final isNewFromMe =
                        messageList.last.sender.id == currentUserId;
                    final isNearBottom =
                        _scrollController.hasClients &&
                        _scrollController.position.pixels >=
                            _scrollController.position.maxScrollExtent - 250;
                    if (isNewFromMe || isNearBottom) {
                      _scrollToBottom(animate: true);
                    }
                    _lastMessageCount = messageList.length;
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: false,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messageList.length,
                    itemBuilder: (context, index) {
                      final message = messageList[index];
                      final isMe = message.sender.id == currentUserId;

                      // Date separator
                      final showDateSeparator =
                          index == 0 ||
                          !_isSameDay(
                            message.createdAt,
                            messageList[index - 1].createdAt,
                          );

                      // Message grouping
                      final isGroupStart =
                          index == 0 ||
                          messageList[index - 1].sender.id !=
                              message.sender.id ||
                          message.createdAt
                                  .difference(messageList[index - 1].createdAt)
                                  .inMinutes >
                              5;

                      final isGroupEnd =
                          index == messageList.length - 1 ||
                          messageList[index + 1].sender.id !=
                              message.sender.id ||
                          messageList[index + 1].createdAt
                                  .difference(message.createdAt)
                                  .inMinutes >
                              5;

                      return Column(
                        children: [
                          if (showDateSeparator)
                            DateSeparator(date: message.createdAt),
                          MessageBubble(
                            message: message,
                            isMe: isMe,
                            currentUserId: currentUserId,
                            isGroupStart: isGroupStart,
                            isGroupEnd: isGroupEnd,
                            showAvatar:
                                !isMe &&
                                (isGroupEnd || conversation?.type != 'DIRECT'),
                            canManageForEveryone: isMe || isGroupOwnerOrAdmin,
                            onReply: () {
                              setState(() {
                                _replyToMessageId = message.id;
                                _editingMessage = null;
                              });
                              _composerFocusNode.requestFocus();
                            },
                            onReaction: (emoji) {
                              ref
                                  .read(
                                    chatMessagesProvider(
                                      widget.conversationId,
                                    ).notifier,
                                  )
                                  .addReaction(message.id, emoji);
                            },
                            onPinForMe: () {
                              ref
                                  .read(
                                    chatMessagesProvider(
                                      widget.conversationId,
                                    ).notifier,
                                  )
                                  .pinMessageForMe(message.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pinned for you (Saved)'),
                                ),
                              );
                            },
                            onPinForEveryone: () {
                              ref
                                  .read(
                                    chatMessagesProvider(
                                      widget.conversationId,
                                    ).notifier,
                                  )
                                  .pinMessageForEveryone(message.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pinned for everyone'),
                                ),
                              );
                            },
                            onUnpin: () {
                              ref
                                  .read(
                                    chatMessagesProvider(
                                      widget.conversationId,
                                    ).notifier,
                                  )
                                  .unpinMessage(message.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Unpinned message'),
                                ),
                              );
                            },
                            onDeleteMessage: (forEveryone) {
                              ref
                                  .read(
                                    chatMessagesProvider(
                                      widget.conversationId,
                                    ).notifier,
                                  )
                                  .deleteMessage(
                                    message.id,
                                    forEveryone: forEveryone,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    forEveryone
                                        ? 'Message deleted for everyone'
                                        : 'Message deleted for you',
                                  ),
                                ),
                              );
                            },
                            onEdit: isMe
                                ? () {
                                    setState(() {
                                      _editingMessage = message;
                                      _replyToMessageId = null;
                                    });
                                    _composerFocusNode.requestFocus();
                                  }
                                : null,
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00C6FF),
                    ),
                  ),
                ),
                error: (error, stack) {
                  if (isOffline) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Offline Mode',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No cached messages found for this chat.\nConnect to the internet to load messages.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(
                                    chatMessagesProvider(
                                      widget.conversationId,
                                    ).notifier,
                                  )
                                  .loadMessages();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: Consumer(
                              builder: (_, ref, _) => Text(
                                ref.watch(trProvider)('chat.check_connection'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Consumer(
                          builder: (_, ref, _) => Text(
                            ref.watch(trProvider)('chat.load_messages_failed'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref
                                .read(
                                  chatMessagesProvider(
                                    widget.conversationId,
                                  ).notifier,
                                )
                                .loadMessages();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C6FF),
                            foregroundColor: Colors.black,
                          ),
                          child: Consumer(
                            builder: (_, ref, _) =>
                                Text(ref.watch(trProvider)('common.retry')),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Typing indicator bubble when other user is typing
            if (typingUsers.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: _buildTypingStatusBanner(isDark),
              ),

            // Message Composer
            MessageComposer(
              conversationId: widget.conversationId,
              focusNode: _composerFocusNode,
              replyToMessageId: _replyToMessageId,
              onCancelReply: () {
                setState(() => _replyToMessageId = null);
              },
              editingMessage: _editingMessage,
              onCancelEdit: () {
                setState(() => _editingMessage = null);
              },
              onMessageSent: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatLastSeen(String lastSeen) {
    try {
      final lastSeenDate = DateTime.parse(lastSeen);
      final now = DateTime.now();
      final diff = now.difference(lastSeenDate);

      if (diff.inMinutes < 1) {
        return 'just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (_) {
      return lastSeen;
    }
  }

  void _handleMenuAction(
    String action,
    ConversationModel? conversation,
    ConversationMemberModel? otherMember,
  ) {
    switch (action) {
      case 'view_profile':
        if (otherMember?.username != null) {
          context.push('/profile/user/${otherMember!.username}');
        } else if (conversation?.groupId != null) {
          context.push('/groups/${conversation!.groupId}');
        }
        break;
      case 'mute':
        if (conversation != null) {
          ref
              .read(conversationsProvider.notifier)
              .muteConversation(conversation.id);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Notifications muted')));
        }
        break;
      case 'search':
        context.push('/chats/search');
        break;
      case 'invite_link':
        if (conversation?.groupId != null) {
          _showInviteLinkDialog(context, conversation!.groupId!);
        }
        break;
      case 'clear':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat history cleared')));
        break;
    }
  }

  Future<void> _showInviteLinkDialog(
    BuildContext context,
    String groupId,
  ) async {
    try {
      final res = await ref
          .read(chatDiscoveryProvider.notifier)
          .getGroupInviteLink(groupId);
      final link =
          res['inviteLink'] as String? ??
          'https://streamhub.app/join/group/${res['inviteToken']}';

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(ctx).brightness == Brightness.dark
                ? const Color(0xFF161C28)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Row(
              children: [
                Icon(Icons.link_rounded, color: Color(0xFF00C6FF)),
                SizedBox(width: 10),
                Text('Group Invite Link', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anyone with this link can join this group:',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? const Color(0xFF1E2638)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00C6FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          link,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF00C6FF),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: Color(0xFF00C6FF),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: link));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invite link copied!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Consumer(
                  builder: (_, ref, _) =>
                      Text(ref.watch(trProvider)('common.done')),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate invite link: $e')),
        );
      }
    }
  }

  Future<void> _startCall({
    required BuildContext context,
    required ConversationModel? conversation,
    required ConversationMemberModel? otherMember,
    required bool isVideo,
  }) async {
    if (otherMember == null || otherMember.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot call this participant')),
      );
      return;
    }

    final currentUser = ref.read(authProvider).user;
    final myDisplayName = currentUser?.displayIdentifier ?? 'Caller';
    final targetDisplayName = otherMember.displayName ?? otherMember.username;
    final targetAvatarUrl = otherMember.avatarUrl;

    // Navigate to active call screen
    context.push('/call/active');

    // Initiate WebRTC call via CallService
    await ref
        .read(callServiceProvider)
        .initiateCall(
          targetUserId: otherMember.userId,
          conversationId: widget.conversationId,
          targetDisplayName: targetDisplayName,
          targetAvatarUrl: targetAvatarUrl,
          isVideo: isVideo,
          myDisplayName: myDisplayName,
          myAvatarUrl: null,
        );
  }

  Widget _buildTypingStatusBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      margin: const EdgeInsets.only(left: 16, bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'typing a message',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF00C6FF),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2),
          Text(
            '...',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF00C6FF),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF00C6FF)),
        ],
      ),
    );
  }
}
