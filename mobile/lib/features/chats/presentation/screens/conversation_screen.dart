// lib/features/chats/presentation/screens/conversation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/chats/presentation/providers/chat_messages_provider.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/message_bubble.dart';
import 'package:mobile/features/chats/presentation/widgets/message_composer.dart';
import 'package:mobile/features/chats/presentation/widgets/date_separator.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ConversationScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();
  String? _replyToMessageId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Mark conversation as read when opening
    Future.microtask(() {
      ref.read(conversationsProvider.notifier).markAsRead(widget.conversationId);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= _scrollController.position.minScrollExtent + 100) {
      // Load more messages when near top
      ref.read(chatMessagesProvider(widget.conversationId).notifier).loadMoreMessages();
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
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId = ref.watch(authProvider).user?.id;
    final typingUsers = ref.watch(typingIndicatorProvider(widget.conversationId));

    ConversationModel? conversation;
    conversationsAsync.whenData((conversations) {
      try {
        conversation = conversations.firstWhere((c) => c.id == widget.conversationId);
      } catch (e) {
        // Conversation not found in list
      }
    });

    final otherMember = conversation?.type == 'DIRECT'
        ? conversation?.members.firstWhere(
            (m) => m.userId != currentUserId,
            orElse: () => conversation!.members.first,
          )
        : null;

    final displayName = conversation?.title ??
        otherMember?.displayName ??
        otherMember?.username ??
        'Chat';

    final isOnline = otherMember?.isOnline ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: InkWell(
          onTap: () {
            // TODO: Navigate to profile/group info
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                backgroundImage: otherMember?.avatarUrl != null
                    ? NetworkImage(otherMember!.avatarUrl!)
                    : null,
                child: otherMember?.avatarUrl == null
                    ? Icon(
                        conversation?.type == 'DIRECT' ? Icons.person : Icons.group,
                        size: 20,
                        color: Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (typingUsers.isNotEmpty)
                      Text(
                        'typing...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (isOnline && conversation?.type == 'DIRECT')
                      Text(
                        'online',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      )
                    else if (otherMember?.lastSeen != null)
                      Text(
                        'last seen ${_formatLastSeen(otherMember!.lastSeen!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              // TODO: Implement voice call
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value, conversation),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('View Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.volume_off_outlined),
                    SizedBox(width: 12),
                    Text('Mute Notifications'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 12),
                    Text('Search in Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Clear Chat', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.when(
              data: (messageList) {
                if (messageList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                              color: Colors.grey.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start chatting',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messageList.length,
                  itemBuilder: (context, index) {
                    final message = messageList[index];
                    final isMe = message.sender.id == currentUserId;
                    
                    // Show date separator
                    final showDateSeparator = index == 0 ||
                        !_isSameDay(
                          message.createdAt,
                          messageList[index - 1].createdAt,
                        );

                    // Group consecutive messages from same sender
                    final isGroupStart = index == 0 ||
                        messageList[index - 1].sender.id != message.sender.id ||
                        message.createdAt.difference(messageList[index - 1].createdAt).inMinutes > 5;

                    final isGroupEnd = index == messageList.length - 1 ||
                        messageList[index + 1].sender.id != message.sender.id ||
                        messageList[index + 1].createdAt.difference(message.createdAt).inMinutes > 5;

                    return Column(
                      children: [
                        if (showDateSeparator)
                          DateSeparator(date: message.createdAt),
                        MessageBubble(
                          message: message,
                          isMe: isMe,
                          isGroupStart: isGroupStart,
                          isGroupEnd: isGroupEnd,
                          showAvatar: !isMe && (isGroupEnd || conversation?.type != 'DIRECT'),
                          onReply: () {
                            setState(() => _replyToMessageId = message.id);
                            _composerFocusNode.requestFocus();
                          },
                          onReaction: (emoji) {
                            ref
                                .read(chatMessagesProvider(widget.conversationId).notifier)
                                .addReaction(message.id, emoji);
                          },
                          onDelete: isMe
                              ? () {
                                  _confirmDelete(message.id);
                                }
                              : null,
                          onEdit: isMe && message.type == 'TEXT'
                              ? () {
                                  // TODO: Implement edit
                                }
                              : null,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load messages',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(chatMessagesProvider(widget.conversationId).notifier).loadMessages();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Message Composer
          MessageComposer(
            conversationId: widget.conversationId,
            focusNode: _composerFocusNode,
            replyToMessageId: _replyToMessageId,
            onCancelReply: () {
              setState(() => _replyToMessageId = null);
            },
            onMessageSent: () {
              // Scroll to bottom after sending
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
    } catch (e) {
      return lastSeen;
    }
  }

  void _handleMenuAction(String action, ConversationModel? conversation) {
    switch (action) {
      case 'view_profile':
        // TODO: Navigate to profile
        break;
      case 'mute':
        if (conversation != null) {
          ref.read(conversationsProvider.notifier).muteConversation(conversation.id);
        }
        break;
      case 'search':
        // TODO: Implement search
        break;
      case 'clear':
        // TODO: Implement clear chat
        break;
    }
  }

  void _confirmDelete(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message for everyone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatMessagesProvider(widget.conversationId).notifier).deleteMessage(messageId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
