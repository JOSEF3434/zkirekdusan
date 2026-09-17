// lib/features/chats/presentation/widgets/conversation_list_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/presentation/providers/chat_messages_provider.dart';

class UnifiedChatListTile extends ConsumerWidget {
  final UnifiedChatItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const UnifiedChatListTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = item.unreadCount > 0;
    final typingUsers = item.conversationId != null
        ? ref.watch(typingIndicatorProvider(item.conversationId!))
        : const <String, bool>{};
    final isSomeoneTyping = typingUsers.isNotEmpty;
    final isGroup = item.type == UnifiedChatType.publicGroup ||
        item.type == UnifiedChatType.privateGroup ||
        (item.conversation != null && item.conversation!.groupId != null);
    final isPrivate = item.type == UnifiedChatType.privateGroup;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: (isDark ? const Color(0xFF00C6FF) : theme.colorScheme.primary)
            .withValues(alpha: 0.08),
        highlightColor: (isDark ? const Color(0xFF00C6FF) : theme.colorScheme.primary)
            .withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: hasUnread
                ? (isDark
                    ? const Color(0xFF131926).withValues(alpha: 0.6)
                    : Colors.blue.withValues(alpha: 0.03))
                : null,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar with Online Badge / Group Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildAvatar(item.title, item.avatarUrl, isGroup, isPrivate, isDark),
                  if (item.isOnline && !isGroup)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF0F141C) : Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Title and Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: Name, Verified/Mute icon, Timestamp
                    Row(
                      children: [
                        if (item.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Icon(
                              Icons.push_pin,
                              size: 13,
                              color: Color(0xFF00C6FF),
                            ),
                          ),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        hasUnread ? FontWeight.w700 : FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPrivate) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: isDark ? const Color(0xFF00C6FF) : Colors.blue,
                                ),
                              ],
                              if (item.isMuted) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.volume_off_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.conversation?.lastMessage?.isMe == true) ...[
                              if (item.conversation?.lastMessage?.isSeen == true)
                                const Icon(
                                  Icons.done_all_rounded,
                                  size: 15,
                                  color: Color(0xFF00C6FF),
                                )
                              else if (item.conversation?.lastMessage?.isDelivered == true)
                                Icon(
                                  Icons.done_all_rounded,
                                  size: 15,
                                  color: Colors.grey[500],
                                )
                              else
                                Icon(
                                  Icons.done_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              _formatTimestamp(item.sortDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasUnread
                                    ? const Color(0xFF00C6FF)
                                    : Colors.grey[500],
                                fontWeight:
                                    hasUnread ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Bottom row: Last message snippet & Unread count pill
                    Row(
                      children: [
                        Expanded(
                          child: isSomeoneTyping
                              ? const Row(
                                  children: [
                                    Text(
                                      'typing',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF00C6FF),
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      '...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF00C6FF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  item.subtitle ?? 'Tap to chat',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: hasUnread
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : Colors.grey[500],
                                    fontWeight:
                                        hasUnread ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        const SizedBox(width: 8),

                        // Unread Badge (matching Screenshot 1 blue circle with count)
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C6FF).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              item.unreadCount > 99
                                  ? '99+'
                                  : '${item.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    String name,
    String? avatarUrl,
    bool isGroup,
    bool isPrivate,
    bool isDark,
  ) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: CachedNetworkImageProvider(avatarUrl),
            fit: BoxFit.cover,
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      );
    }

    // Default Gradient Avatars
    final gradients = [
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFFF857A6), const Color(0xFFFF5858)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    ];
    final gradientIndex = name.hashCode.abs() % gradients.length;
    final gradient = gradients[gradientIndex];

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: isPrivate
            ? const Icon(Icons.lock_rounded, color: Colors.white, size: 22)
            : isGroup
                ? const Icon(Icons.groups_rounded, color: Colors.white, size: 24)
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays == 0 && now.day == timestamp.day) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != timestamp.day)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(timestamp);
    } else if (now.year == timestamp.year) {
      return DateFormat('MMM d').format(timestamp);
    } else {
      return DateFormat('MM/dd/yy').format(timestamp);
    }
  }
}

// Alias for backward compatibility
typedef ConversationListTile = UnifiedChatListTile;
