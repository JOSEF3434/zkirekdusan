// lib/features/chats/presentation/widgets/conversation_list_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      orElse: () => conversation.members.isNotEmpty
          ? conversation.members.first
          : const ConversationMemberModel(userId: '', username: ''),
    );

    // For direct chats, get the other user
    final otherMember = conversation.type == 'DIRECT'
        ? conversation.members.firstWhere(
            (m) => m.userId != currentUserId,
            orElse: () => conversation.members.isNotEmpty
                ? conversation.members.first
                : const ConversationMemberModel(userId: '', username: ''),
          )
        : null;

    final displayName = conversation.title ??
        otherMember?.displayName ??
        otherMember?.username ??
        'Chat';

    final avatarUrl = otherMember?.avatarUrl ??
        conversation.metadata?.groupAvatar;

    final isOnline = otherMember?.isOnline ?? false;
    final hasUnread = currentMember.unreadCount > 0;
    final isMuted = currentMember.isMuted;
    final isPinned = currentMember.isPinned;
    final isGroup = conversation.type == 'GROUP_DIRECT' || conversation.groupId != null;
    final isChannel = conversation.type == 'GROUP_CHANNEL' || conversation.channelId != null;

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
                  _buildAvatar(displayName, avatarUrl, isGroup, isChannel, isDark),
                  if (isOnline && conversation.type == 'DIRECT')
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
                        if (isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Icon(
                              Icons.push_pin,
                              size: 13,
                              color: const Color(0xFF00C6FF),
                            ),
                          ),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMuted) ...[
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
                        if (conversation.lastMessageAt != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (conversation.lastMessage?.isMe == true) ...[
                                const Icon(
                                  Icons.done_all_rounded,
                                  size: 15,
                                  color: Color(0xFF00C6FF),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                _formatTimestamp(conversation.lastMessageAt!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasUnread
                                      ? const Color(0xFF00C6FF)
                                      : Colors.grey[500],
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Bottom row: Last message snippet & Unread count pill
                    Row(
                      children: [
                        Expanded(
                          child: currentMember.typingStatus?.isTyping == true
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF00C6FF),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'typing...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF00C6FF),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                )
                              : _buildMessagePreview(context, isDark, hasUnread),
                        ),
                        const SizedBox(width: 8),

                        // Unread Badge
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
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
                              currentMember.unreadCount > 99
                                  ? '99+'
                                  : '${currentMember.unreadCount}',
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
    bool isChannel,
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
        child: isChannel
            ? const Icon(Icons.campaign_rounded, color: Colors.white, size: 24)
            : isGroup
                ? const Icon(Icons.groups_rounded, color: Colors.white, size: 24)
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    String prefix = '';
    if (lastMessage.isMe == true) {
      prefix = 'You: ';
    } else if (lastMessage.senderName != null && conversation.type != 'DIRECT') {
      prefix = '${lastMessage.senderName}: ';
    }

    Widget contentWidget;
    if (lastMessage.type == 'IMAGE') {
      contentWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_camera_rounded, size: 15, color: Color(0xFF00C6FF)),
          const SizedBox(width: 4),
          Text(
            'Photo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF00C6FF) : const Color(0xFF0072FF),
            ),
          ),
        ],
      );
    } else if (lastMessage.type == 'VOICE_NOTE' || lastMessage.type == 'AUDIO') {
      contentWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic_rounded, size: 15, color: Color(0xFF10B981)),
          const SizedBox(width: 4),
          Text(
            'Voice message',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF10B981) : Colors.green[700],
            ),
          ),
        ],
      );
    } else if (lastMessage.type == 'VIDEO') {
      contentWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_rounded, size: 15, color: Colors.amber),
          const SizedBox(width: 4),
          const Text('Video', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      );
    } else if (lastMessage.type == 'DOCUMENT') {
      contentWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_rounded, size: 15, color: Colors.orange),
          const SizedBox(width: 4),
          const Text('Document', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      );
    } else {
      contentWidget = Text(
        lastMessage.content ?? 'Message',
        style: TextStyle(
          fontSize: 14,
          color: hasUnread
              ? (isDark ? Colors.white : Colors.black87)
              : Colors.grey[500],
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      children: [
        if (prefix.isNotEmpty)
          Text(
            prefix,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF00C6FF) : const Color(0xFF0072FF),
              fontWeight: FontWeight.w500,
            ),
          ),
        Expanded(child: contentWidget),
      ],
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (today.difference(messageDate).inDays == 1) {
      return 'Yesterday';
    } else if (today.difference(messageDate).inDays < 7) {
      return DateFormat('E').format(dateTime); // e.g. Mon, Sat
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
