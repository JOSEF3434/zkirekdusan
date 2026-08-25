// lib/features/chats/presentation/widgets/conversation_list_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ConversationListTile extends ConsumerWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationListTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authProvider).user?.id;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get current user's member data
    final currentMember = conversation.members.firstWhere(
      (m) => m.userId == currentUserId,
      orElse: () => conversation.members.first,
    );

    // For direct chats, get the other user
    final otherMember = conversation.type == 'DIRECT'
        ? conversation.members.firstWhere(
            (m) => m.userId != currentUserId,
            orElse: () => conversation.members.first,
          )
        : null;

    final displayName = conversation.title ??
        otherMember?.displayName ??
        otherMember?.username ??
        'Unknown';

    final avatarUrl = otherMember?.avatarUrl ??
        conversation.metadata?.groupAvatar;

    final isOnline = otherMember?.isOnline ?? false;
    final hasUnread = currentMember.unreadCount > 0;
    final isMuted = currentMember.isMuted;
    final isPinned = currentMember.isPinned;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: hasUnread
              ? (isDark ? Colors.grey[900] : Colors.blue.withValues(alpha: 0.05))
              : null,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasUnread
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Icon(
                            conversation.type == 'DIRECT'
                                ? Icons.person
                                : Icons.group,
                            size: 32,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                if (isOnline && conversation.type == 'DIRECT')
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green[500],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.push_pin,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (conversation.lastMessageAt != null)
                        Text(
                          _formatTime(conversation.lastMessageAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? theme.colorScheme.primary
                                : Colors.grey[600],
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMessagePreview(context, isDark, hasUnread),
                      ),
                      const SizedBox(width: 8),
                      if (hasUnread && !isMuted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentMember.unreadCount > 99
                                ? '99+'
                                : '${currentMember.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isMuted)
                        Icon(
                          Icons.volume_off,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                    ],
                  ),
                  if (currentMember.typingStatus?.isTyping == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'typing...',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagePreview(BuildContext context, bool isDark, bool hasUnread) {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) {
      return Text(
        'No messages yet',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    String preview = '';
    if (lastMessage.isMe == true) {
      preview = 'You: ';
    } else if (lastMessage.senderName != null && conversation.type != 'DIRECT') {
      preview = '${lastMessage.senderName}: ';
    }

    // Add message content or media indicator
    if (lastMessage.content != null && lastMessage.content!.isNotEmpty) {
      preview += lastMessage.content!;
    } else if (lastMessage.attachmentPreview != null) {
      preview += lastMessage.attachmentPreview!;
    } else {
      preview += _getMessageTypeLabel(lastMessage.type);
    }

    return Text(
      preview,
      style: TextStyle(
        fontSize: 14,
        color: hasUnread
            ? (isDark ? Colors.white : Colors.black87)
            : Colors.grey[600],
        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getMessageTypeLabel(String type) {
    switch (type) {
      case 'IMAGE':
        return '📷 Photo';
      case 'VIDEO':
        return '🎥 Video';
      case 'AUDIO':
        return '🎵 Audio';
      case 'VOICE_NOTE':
        return '🎤 Voice message';
      case 'DOCUMENT':
        return '📄 Document';
      default:
        return 'Message';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return timeago.format(dateTime, locale: 'en_short');
    }
  }
}
