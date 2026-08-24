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
          left: isMe ? 64 : 16,
          right: isMe ? 16 : 64,
          top: isGroupStart ? 8 : 2,
          bottom: isGroupEnd ? 8 : 2,
        ),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other users
            if (!isMe && showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: message.sender.avatarUrl != null
                      ? CachedNetworkImageProvider(message.sender.avatarUrl!)
                      : null,
                  child: message.sender.avatarUrl == null
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
              )
            else if (!isMe && !showAvatar)
              const SizedBox(width: 40),

            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name for group chats
                  if (!isMe && isGroupStart && message.sender.displayName != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(
                        message.sender.displayName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getSenderColor(message.sender.id),
                        ),
                      ),
                    ),

                  // Message bubble
                  Container(
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.grey[850] : Colors.grey[200]),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe || !isGroupStart ? 18 : 4),
                        topRight: Radius.circular(!isMe || !isGroupStart ? 18 : 4),
                        bottomLeft: Radius.circular(isMe || !isGroupEnd ? 18 : 4),
                        bottomRight: Radius.circular(!isMe || !isGroupEnd ? 18 : 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reply preview
                        if (message.replyTo != null) _buildReplyPreview(context),

                        // Attachments
                        if (message.attachments.isNotEmpty) _buildAttachments(context),

                        // Voice note
                        if (message.voiceNote != null)
                          VoiceMessagePlayer(
                            voiceNote: message.voiceNote!,
                            isMe: isMe,
                          ),

                        // Text content
                        if (message.content != null && message.content!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              message.content!,
                              style: TextStyle(
                                fontSize: 15,
                                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                height: 1.4,
                              ),
                            ),
                          ),

                        // Message metadata (time, status, edited)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 8,
                            top: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (message.isEdited)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    'edited',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMe
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              Text(
                                DateFormat.jm().format(message.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isMe
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.grey[600],
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  _getStatusIcon(),
                                  size: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reactions
                  if (message.reactions.isNotEmpty) _buildReactions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    final theme = Theme.of(context);
    final reply = message.replyTo!;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.2)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white : theme.colorScheme.primary,
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
              fontWeight: FontWeight.w600,
              color: isMe ? Colors.white : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            reply.content ?? _getMessageTypeLabel(reply.type),
            style: TextStyle(
              fontSize: 13,
              color: isMe
                  ? Colors.white.withOpacity(0.8)
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
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

  Widget _buildImageAttachment(BuildContext context, MessageAttachmentModel attachment) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () {
          // TODO: Open full screen image viewer
        },
        child: Hero(
          tag: 'message-image-${attachment.fileId}',
          child: CachedNetworkImage(
            imageUrl: attachment.url,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(BuildContext context, MessageAttachmentModel attachment) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () {
          // TODO: Open video player
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (attachment.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: attachment.thumbnailUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
            if (attachment.duration != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(attachment.duration!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentAttachment(BuildContext context, MessageAttachmentModel attachment) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.2)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(attachment.mimeType),
            color: isMe ? Colors.white : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                attachment.originalName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : theme.textTheme.bodyMedium?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (attachment.size != null)
                Text(
                  _formatFileSize(attachment.size!),
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Wrap(
        spacing: 4,
        children: message.reactions.map((reaction) {
          return Text(
            '${reaction.emoji} ${reaction.count}',
            style: const TextStyle(fontSize: 13),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
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
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
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

  IconData _getStatusIcon() {
    if (message.readBy.isNotEmpty) {
      return Icons.done_all; // Read
    } else if (message.deliveredTo.isNotEmpty) {
      return Icons.done_all; // Delivered
    } else {
      return Icons.done; // Sent
    }
  }

  Color _getSenderColor(String senderId) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final index = senderId.hashCode % colors.length;
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

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word')) return Icons.description;
    if (mimeType.contains('excel')) return Icons.table_chart;
    if (mimeType.contains('zip')) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
