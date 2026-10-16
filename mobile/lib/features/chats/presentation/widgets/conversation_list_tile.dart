// lib/features/chats/presentation/widgets/conversation_list_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/presentation/providers/chat_messages_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/online_aware_avatar.dart';

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
    final activeActivities = item.conversationId != null
        ? ref.watch(chatActivityProvider(item.conversationId!))
        : const <String, String>{};
    final isSomeoneTyping = typingUsers.isNotEmpty;
    final hasSomeoneActive = activeActivities.isNotEmpty;
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
              // ── Avatar (Telegram-style online ring) ──────────────────
              _buildGroupAwareAvatar(
                item, isGroup, isPrivate, isDark,
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
                          child: hasSomeoneActive
                              ? _buildActivityRow(activeActivities.values.first, isDark)
                              : isSomeoneTyping
                                  ? _buildTypingRow(isDark)
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

  Widget _buildTypingRow(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFF00C6FF)),
        const SizedBox(width: 4),
        const Text(
          'typing',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF00C6FF),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        const Text(
          '...',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF00C6FF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow(String activity, bool isDark) {
    final IconData icon;
    final String label;
    switch (activity) {
      case 'recording_audio':
        icon = Icons.mic_rounded;
        label = 'recording audio...';
        break;
      case 'uploading_photo':
        icon = Icons.image_rounded;
        label = 'sending photo...';
        break;
      case 'uploading_video':
        icon = Icons.videocam_rounded;
        label = 'sending video...';
        break;
      case 'uploading_audio':
        icon = Icons.audiotrack_rounded;
        label = 'sending audio...';
        break;
      case 'uploading_file':
      case 'uploading_media':
        icon = Icons.insert_drive_file_rounded;
        label = 'sending file...';
        break;
      default:
        icon = Icons.edit_note_rounded;
        label = 'active...';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF00C6FF)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF00C6FF),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// For groups/private-groups show a special icon avatar;
  /// for DMs delegate to [OnlineAwareAvatar].
  Widget _buildGroupAwareAvatar(
    UnifiedChatItem item,
    bool isGroup,
    bool isPrivate,
    bool isDark,
  ) {
    if (isGroup) {
      return _GroupAvatar(
        name: item.title,
        avatarUrl: item.avatarUrl,
        isPrivate: isPrivate,
        size: 50,
        isDark: isDark,
      );
    }
    return OnlineAwareAvatar(
      name: item.title,
      avatarUrl: item.avatarUrl,
      isOnline: item.isOnline,
      size: 50,
      showDotBadge: true,
      showRing: false,
      backgroundHighlightColor:
          isDark ? const Color(0xFF0E1621) : Colors.white,
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


// ── Group Avatar (static — no online ring) ────────────────────────────────────
class _GroupAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isPrivate;
  final double size;
  final bool isDark;

  const _GroupAvatar({
    required this.name,
    this.avatarUrl,
    required this.isPrivate,
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const gradients = [
      [Color(0xFF00C6FF), Color(0xFF0072FF)],
      [Color(0xFFF857A6), Color(0xFFFF5858)],
      [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      [Color(0xFF43E97B), Color(0xFF38F9D7)],
      [Color(0xFFFA709A), Color(0xFFFEE140)],
      [Color(0xFF667EEA), Color(0xFF764BA2)],
    ];
    final idx = name.hashCode.abs() % gradients.length;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _iconAvatar(gradients[idx]),
        ),
      );
    }
    return _iconAvatar(gradients[idx]);
  }

  Widget _iconAvatar(List<Color> g) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: g,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: g[0].withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isPrivate
            ? const Icon(Icons.lock_rounded, color: Colors.white, size: 22)
            : const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
      );
}

// Alias for backward compatibility
typedef ConversationListTile = UnifiedChatListTile;
