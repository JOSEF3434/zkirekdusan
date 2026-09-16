// lib/features/chats/presentation/screens/inline_conversation_view.dart
//
// An embedded version of the conversation screen designed for the large-screen
// three-panel layout. Reuses all existing message/composer widgets but renders
// without full-screen routing — lives inside a panel column.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/presentation/widgets/pinned_messages_bar.dart';
import 'package:mobile/features/chats/presentation/providers/chat_messages_provider.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/date_separator.dart';
import 'package:mobile/features/chats/presentation/widgets/message_bubble.dart';
import 'package:mobile/features/chats/presentation/widgets/message_composer.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calls/services/call_service.dart';

/// Callback signature for toggling the details panel.
typedef ToggleDetailsCallback = void Function();

class InlineConversationView extends ConsumerStatefulWidget {
  final String conversationId;

  /// Called when the user taps the ℹ / info icon.
  final ToggleDetailsCallback onToggleDetails;

  /// Whether the details panel is currently open (to show icon state).
  final bool isDetailsPanelOpen;

  const InlineConversationView({
    super.key,
    required this.conversationId,
    required this.onToggleDetails,
    required this.isDetailsPanelOpen,
  });

  @override
  ConsumerState<InlineConversationView> createState() =>
      _InlineConversationViewState();
}

class _InlineConversationViewState
    extends ConsumerState<InlineConversationView> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();
  String? _replyToMessageId;
  MessageModel? _editingMessage;

  void _scrollToMessage(String messageId, List<MessageModel> messageList) {
    final index = messageList.indexWhere((m) => m.id == messageId);
    if (index != -1 && _scrollController.hasClients) {
      final target = (index * 75.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Mark conversation as read on open
    Future.microtask(() {
      ref
          .read(conversationsProvider.notifier)
          .markAsRead(widget.conversationId);
    });
  }

  @override
  void didUpdateWidget(InlineConversationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      // New conversation selected: clear reply state
      setState(() => _replyToMessageId = null);
      // Mark new conversation as read
      Future.microtask(() {
        ref
            .read(conversationsProvider.notifier)
            .markAsRead(widget.conversationId);
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 100) {
      ref
          .read(chatMessagesProvider(widget.conversationId).notifier)
          .loadMoreMessages();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));
    final discoveryAsync = ref.watch(chatDiscoveryProvider);
    final currentUserId = ref.watch(authProvider).user?.id;
    final typingUsers =
        ref.watch(typingIndicatorProvider(widget.conversationId));

    final singleConvAsync =
        ref.watch(singleConversationProvider(widget.conversationId));
    ConversationModel? conversation = singleConvAsync.value;
    if (conversation == null) {
      discoveryAsync.whenData((discovery) {
        try {
          conversation = discovery.conversations
              .firstWhere((c) => c.id == widget.conversationId);
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

    // Immediate fallback from unified list item to ensure title & avatar display instantly
    final chatList = ref.watch(unifiedChatListProvider).value ?? [];
    final listItem = chatList.where((i) =>
        i.conversationId == widget.conversationId ||
        i.id == widget.conversationId ||
        (conversation?.groupId != null && i.targetGroupId == conversation!.groupId) ||
        (otherMember?.userId != null && i.targetUserId == otherMember!.userId)).firstOrNull;

    final displayName = (conversation?.title != null && conversation!.title!.isNotEmpty)
        ? conversation!.title!
        : (otherMember?.displayName ??
            otherMember?.username ??
            listItem?.title ??
            'Chat');

    final avatarUrl = otherMember?.avatarUrl ??
        conversation?.metadata?.groupAvatar ??
        listItem?.avatarUrl;

    final isOnline = otherMember?.isOnline ?? listItem?.isOnline ?? false;
    final isGroup = conversation?.type != 'DIRECT' && conversation != null;
    final pinnedMessagesAsync = ref.watch(pinnedMessagesProvider(widget.conversationId));
    final currentUserRole = ref.watch(authProvider).user?.role;
    final isGlobalAdmin = currentUserRole == 'ADMIN' || currentUserRole == 'SUPER_ADMIN';
    final isGroupOwnerOrAdmin = !isGroup ||
        isGlobalAdmin ||
        (conversation?.groupId != null &&
            discoveryAsync.value?.myPrivateGroups.any((g) => g.id == conversation!.groupId) == true);

    return Column(
      children: [
        // ── Header bar ────────────────────────────────────────────────────────
        _InlineHeader(
          displayName: displayName,
          avatarUrl: avatarUrl,
          isOnline: isOnline,
          isGroup: isGroup,
          memberCount: conversation?.members.length ?? 0,
          typingUsers: typingUsers,
          lastSeen: otherMember?.lastSeen,
          isDark: isDark,
          isDetailsPanelOpen: widget.isDetailsPanelOpen,
          onToggleDetails: widget.onToggleDetails,
          onVoiceCall: () => _startCall(
            conversation: conversation,
            otherMember: otherMember,
            isVideo: false,
          ),
          onVideoCall: () => _startCall(
            conversation: conversation,
            otherMember: otherMember,
            isVideo: true,
          ),
          onViewProfile: () {
            if (otherMember?.username != null) {
              context.push('/profile/user/${otherMember!.username}');
            } else if (conversation?.groupId != null) {
              context.push('/groups/${conversation!.groupId}');
            }
          },
          onSearch: () => context.push('/chats/search'),
          onMute: () {
            if (conversation != null) {
              ref
                  .read(conversationsProvider.notifier)
                  .muteConversation(conversation!.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications muted')),
              );
            }
          },
          onInviteLink: conversation?.groupId != null
              ? () => _showInviteLinkDialog(conversation!.groupId!)
              : null,
          onClearChat: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chat history cleared')),
            );
          },
        ),

        // ── Telegram-Style Pinned Messages Top Bar ────────────────────────────
        pinnedMessagesAsync.when(
          data: (pins) => PinnedMessagesBar(
            pinnedMessages: pins,
            canUnpin: isGroupOwnerOrAdmin,
            onSelectMessage: (pinnedMsg) {
              messages.whenData((list) => _scrollToMessage(pinnedMsg.id, list));
            },
            onUnpinMessage: (pinnedMsg) {
              ref.read(chatMessagesProvider(widget.conversationId).notifier).unpinMessage(pinnedMsg.id);
            },
          ),
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
        ),

        // ── Messages area ─────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: isDark
                ? const Color(0xFF0B0E14)
                : const Color(0xFFF7F9FC),
            child: messages.when(
              data: (messageList) {
                if (messageList.isEmpty) {
                  return _buildEmptyState(isDark);
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messageList.length,
                  itemBuilder: (context, index) {
                    final message = messageList[index];
                    final isMe = message.sender.id == currentUserId;

                    final showDateSep = index == 0 ||
                        !_isSameDay(
                          message.createdAt,
                          messageList[index - 1].createdAt,
                        );

                    final isGroupStart = index == 0 ||
                        messageList[index - 1].sender.id !=
                            message.sender.id ||
                        message.createdAt
                                .difference(
                                    messageList[index - 1].createdAt)
                                .inMinutes >
                            5;

                    final isGroupEnd = index == messageList.length - 1 ||
                        messageList[index + 1].sender.id !=
                            message.sender.id ||
                        messageList[index + 1]
                                .createdAt
                                .difference(message.createdAt)
                                .inMinutes >
                            5;

                    return Column(
                      children: [
                        if (showDateSep)
                          DateSeparator(date: message.createdAt),
                        MessageBubble(
                          message: message,
                          isMe: isMe,
                          isGroupStart: isGroupStart,
                          isGroupEnd: isGroupEnd,
                          showAvatar: !isMe &&
                              (isGroupEnd ||
                                  conversation?.type != 'DIRECT'),
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
                                .read(chatMessagesProvider(
                                        widget.conversationId)
                                    .notifier)
                                .addReaction(message.id, emoji);
                          },
                          onPinForMe: () {
                            ref
                                .read(chatMessagesProvider(widget.conversationId)
                                    .notifier)
                                .pinMessageForMe(message.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pinned for you (Saved)')),
                            );
                          },
                          onPinForEveryone: () {
                            ref
                                .read(chatMessagesProvider(widget.conversationId)
                                    .notifier)
                                .pinMessageForEveryone(message.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pinned for everyone')),
                            );
                          },
                          onUnpin: () {
                            ref
                                .read(chatMessagesProvider(widget.conversationId)
                                    .notifier)
                                .unpinMessage(message.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unpinned message')),
                            );
                          },
                          onDeleteMessage: (forEveryone) {
                            ref
                                .read(chatMessagesProvider(widget.conversationId)
                                    .notifier)
                                .deleteMessage(message.id, forEveryone: forEveryone);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(forEveryone
                                    ? 'Message deleted for everyone'
                                    : 'Message deleted for you'),
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
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    const Text('Failed to load messages'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(chatMessagesProvider(
                                    widget.conversationId)
                                .notifier)
                            .loadMessages();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C6FF),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Composer ──────────────────────────────────────────────────────────
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
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C6FF).withValues(alpha: 0.1),
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
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _showInviteLinkDialog(String groupId) async {
    try {
      final res = await ref
          .read(chatDiscoveryProvider.notifier)
          .getGroupInviteLink(groupId);
      final link = res['inviteLink'] as String? ??
          'https://streamhub.app/join/group/${res['inviteToken']}';
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              Theme.of(ctx).brightness == Brightness.dark
                  ? const Color(0xFF161C28)
                  : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.link_rounded, color: Color(0xFF00C6FF)),
              SizedBox(width: 10),
              Text('Group Invite Link',
                  style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anyone with this link can join this group:',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? const Color(0xFF1E2638)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF00C6FF)
                          .withValues(alpha: 0.3)),
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
                      icon: const Icon(Icons.copy_rounded,
                          size: 18, color: Color(0xFF00C6FF)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Invite link copied!')),
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
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not generate invite link: $e')),
      );
    }
  }

  Future<void> _startCall({
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
    final myDisplayName =
        currentUser?.displayIdentifier ?? 'Caller';
    final targetDisplayName =
        otherMember.displayName ?? otherMember.username;
    final targetAvatarUrl = otherMember.avatarUrl;

    context.push('/call/active');

    await ref.read(callServiceProvider).initiateCall(
          targetUserId: otherMember.userId,
          conversationId: widget.conversationId,
          targetDisplayName: targetDisplayName,
          targetAvatarUrl: targetAvatarUrl,
          isVideo: isVideo,
          myDisplayName: myDisplayName,
          myAvatarUrl: null,
        );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Inline header (replaces AppBar for the embedded conversation panel)
// ──────────────────────────────────────────────────────────────────────────────

class _InlineHeader extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final bool isOnline;
  final bool isGroup;
  final int memberCount;
  final Map<String, bool> typingUsers;
  final String? lastSeen;
  final bool isDark;
  final bool isDetailsPanelOpen;
  final VoidCallback onToggleDetails;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;
  final VoidCallback onViewProfile;
  final VoidCallback onSearch;
  final VoidCallback onMute;
  final VoidCallback? onInviteLink;
  final VoidCallback onClearChat;

  const _InlineHeader({
    required this.displayName,
    required this.avatarUrl,
    required this.isOnline,
    required this.isGroup,
    required this.memberCount,
    required this.typingUsers,
    required this.lastSeen,
    required this.isDark,
    required this.isDetailsPanelOpen,
    required this.onToggleDetails,
    required this.onVoiceCall,
    required this.onVideoCall,
    required this.onViewProfile,
    required this.onSearch,
    required this.onMute,
    required this.onInviteLink,
    required this.onClearChat,
  });

  @override
  Widget build(BuildContext context) {
    final headerBg = isDark ? const Color(0xFF131822) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    String subtitleText;
    Color subtitleColor;
    if (typingUsers.isNotEmpty) {
      subtitleText = 'typing...';
      subtitleColor = const Color(0xFF00C6FF);
    } else if (isOnline && !isGroup) {
      subtitleText = 'Online';
      subtitleColor = const Color(0xFF10B981);
    } else if (isGroup) {
      subtitleText = '$memberCount members';
      subtitleColor = Colors.grey[500]!;
    } else if (lastSeen != null) {
      subtitleText = 'last seen ${_fmtSeen(lastSeen!)}';
      subtitleColor = Colors.grey[500]!;
    } else {
      subtitleText = 'Offline';
      subtitleColor = Colors.grey[500]!;
    }

    return Container(
      height: 56,
      color: headerBg,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: const Color(0xFF00C6FF)
                            .withValues(alpha: 0.2),
                        backgroundImage:
                            avatarUrl != null && avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(avatarUrl!)
                                : null,
                        child: avatarUrl == null || avatarUrl!.isEmpty
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
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Name + subtitle
                  Expanded(
                    child: InkWell(
                      onTap: onViewProfile,
                      borderRadius: BorderRadius.circular(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitleText,
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                              fontStyle: typingUsers.isNotEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Action icons
                  IconButton(
                    icon: const Icon(Icons.search_rounded, size: 21),
                    tooltip: 'Search',
                    onPressed: onSearch,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black54,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_outlined, size: 21),
                    tooltip: 'Voice call',
                    onPressed: onVoiceCall,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black54,
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam_outlined, size: 22),
                    tooltip: 'Video call',
                    onPressed: onVideoCall,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black54,
                  ),
                  // Info / details toggle (highlighted when open)
                  IconButton(
                    icon: Icon(
                      isDetailsPanelOpen
                          ? Icons.info_rounded
                          : Icons.info_outline_rounded,
                      size: 22,
                    ),
                    tooltip: isDetailsPanelOpen
                        ? 'Close Info'
                        : 'View Info',
                    onPressed: onToggleDetails,
                    color: isDetailsPanelOpen
                        ? const Color(0xFF00C6FF)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black54),
                  ),
                  // More menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 22,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black54,
                    ),
                    color: isDark
                        ? const Color(0xFF161C28)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) {
                      switch (value) {
                        case 'view_profile':
                          onViewProfile();
                          break;
                        case 'mute':
                          onMute();
                          break;
                        case 'search':
                          onSearch();
                          break;
                        case 'invite_link':
                          onInviteLink?.call();
                          break;
                        case 'clear':
                          onClearChat();
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'view_profile',
                        child: Row(children: [
                          Icon(Icons.person_outline, size: 20),
                          SizedBox(width: 12),
                          Text('View Info'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'mute',
                        child: Row(children: [
                          Icon(Icons.volume_off_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Mute Notifications'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'search',
                        child: Row(children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 12),
                          Text('Search in Chat'),
                        ]),
                      ),
                      if (onInviteLink != null)
                        const PopupMenuItem(
                          value: 'invite_link',
                          child: Row(children: [
                            Icon(Icons.link_rounded,
                                color: Color(0xFF00C6FF), size: 20),
                            SizedBox(width: 12),
                            Text('Group Invite Link'),
                          ]),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 20),
                          SizedBox(width: 12),
                          Text('Clear Chat',
                              style:
                                  TextStyle(color: Colors.redAccent)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom border
          Container(height: 0.5, color: borderColor),
        ],
      ),
    );
  }

  String _fmtSeen(String lastSeen) {
    try {
      final date = DateTime.parse(lastSeen);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return lastSeen;
    }
  }
}
