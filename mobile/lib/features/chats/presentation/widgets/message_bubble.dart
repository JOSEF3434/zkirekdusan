// lib/features/chats/presentation/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/presentation/widgets/voice_message_player.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isGroupStart;
  final bool isGroupEnd;
  final bool showAvatar;
  final VoidCallback? onReply;
  final Function(String emoji)? onReaction;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isGroupStart = true,
    this.isGroupEnd = true,
    this.showAvatar = false,
    this.onReply,
    this.onReaction,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? 54 : 12,
          right: isMe ? 12 : 54,
          top: isGroupStart ? 6 : 2,
          bottom: isGroupEnd ? 6 : 2,
        ),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Sender Avatar (for other users)
            if (!isMe && showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 2),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                  backgroundImage: message.sender.avatarUrl != null
                      ? CachedNetworkImageProvider(message.sender.avatarUrl!)
                      : null,
                  child: message.sender.avatarUrl == null
                      ? Text(
                          (message.sender.displayName ?? message.sender.username).isNotEmpty
                              ? (message.sender.displayName ?? message.sender.username)[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C6FF),
                          ),
                        )
                      : null,
                ),
              )
            else if (!isMe && !showAvatar)
              const SizedBox(width: 38),

            // Message Bubble & Reactions Container
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name for group chats
                  if (!isMe && isGroupStart && message.sender.displayName != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 3),
                      child: Text(
                        message.sender.displayName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getSenderColor(message.sender.id),
                        ),
                      ),
                    ),

                  // Message Bubble
                  Container(
                    decoration: BoxDecoration(
                      // Sent = Emerald/Cyan gradient, Received = Dark slate glass
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [Color(0xFF2DD4BF), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: !isMe
                          ? (isDark ? const Color(0xFF1E232E) : Colors.grey[200])
                          : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      border: !isMe
                          ? Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                              width: 1,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isMe
                              ? const Color(0xFF06B6D4).withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quoted Reply Preview
                          if (message.replyTo != null) _buildReplyPreview(context, isDark),

                          // Attachments (Images, Videos, Docs)
                          if (message.attachments.isNotEmpty) _buildAttachments(context),

                          // Voice Message Player
                          if (message.voiceNote != null)
                            VoiceMessagePlayer(
                              voiceNote: message.voiceNote!,
                              isMe: isMe,
                            ),

                          // Text Content
                          if (message.content != null && message.content!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                              child: Text(
                                message.content!,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isMe
                                      ? Colors.black87
                                      : (isDark ? Colors.white : Colors.black87),
                                  fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                                  height: 1.35,
                                ),
                              ),
                            ),

                          // Timestamp and Status Checkmarks
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (message.isEdited)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      'edited',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.black.withValues(alpha: 0.6)
                                            : Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                Text(
                                  DateFormat('h:mm a').format(message.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: isMe
                                        ? Colors.black.withValues(alpha: 0.65)
                                        : Colors.grey[500],
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done_all_rounded,
                                    size: 15,
                                    color: Colors.black.withValues(alpha: 0.75),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Reactions Badges (e.g. 🔥 3, ❤️ 1)
                  if (message.reactions.isNotEmpty) _buildReactions(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isDark) {
    final reply = message.replyTo!;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.black.withValues(alpha: 0.08)
            : (isDark ? const Color(0xFF131822) : Colors.white.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.black87 : const Color(0xFF00C6FF),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reply.sender.displayName ?? reply.sender.username,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.black87 : const Color(0xFF00C6FF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            reply.content ?? _getMessageTypeLabel(reply.type),
            style: TextStyle(
              fontSize: 13,
              color: isMe
                  ? Colors.black.withValues(alpha: 0.7)
                  : (isDark ? Colors.grey[300] : Colors.grey[700]),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.attachments.map((attachment) {
          if (attachment.fileType == 'IMAGE') {
            return _buildImageAttachment(context, attachment);
          } else if (attachment.fileType == 'VIDEO') {
            return _buildVideoAttachment(context, attachment);
          } else if (attachment.fileType == 'DOCUMENT') {
            return _buildDocumentAttachment(context, attachment);
          }
          return const SizedBox.shrink();
        }).toList(),
      ),
    );
  }

  Widget _buildImageAttachment(
      BuildContext context, MessageAttachmentModel attachment) {
    return GestureDetector(
      onTap: () {
        _openImageViewer(context, attachment.url);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: const BoxConstraints(maxHeight: 260, maxWidth: 260),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: attachment.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 180,
              color: const Color(0xFF1E2638),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 180,
              color: const Color(0xFF1E2638),
              child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(
      BuildContext context, MessageAttachmentModel attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      constraints: const BoxConstraints(maxHeight: 220, maxWidth: 260),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (attachment.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: attachment.thumbnailUrl!,
                fit: BoxFit.cover,
              )
            else
              Container(height: 160, color: const Color(0xFF1E2638)),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentAttachment(
      BuildContext context, MessageAttachmentModel attachment) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.black.withValues(alpha: 0.1)
            : const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF00C6FF), size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.originalName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isMe ? Colors.black87 : Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.size != null)
                  Text(
                    _formatFileSize(attachment.size!),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.black54 : Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: message.reactions.map((reaction) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2638) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reaction.emoji, style: const TextStyle(fontSize: 13)),
                if (reaction.count > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${reaction.count}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF161C28)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Emojis Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '🔥', '👍', '😂', '😮', '👏', '🎉'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onReaction?.call(emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),

            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Color(0xFF00C6FF)),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy Text'),
              onTap: () {
                if (message.content != null) {
                  Clipboard.setData(ClipboardData(text: message.content!));
                }
                Navigator.pop(context);
              },
            ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(imageUrl: imageUrl),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSenderColor(String senderId) {
    final colors = [
      const Color(0xFF00C6FF),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6),
    ];
    final index = senderId.hashCode.abs() % colors.length;
    return colors[index];
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
