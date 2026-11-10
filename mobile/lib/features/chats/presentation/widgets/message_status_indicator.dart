import 'package:flutter/material.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';

/// Backend / UI delivery lifecycle state for an outgoing chat message.
enum MessageDeliveryStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Surface context used to ensure high-contrast accessible indicator colors
/// across outgoing gradient bubbles and standard light/dark surfaces.
enum MessageStatusSurface {
  outgoingBubble,
  surface,
}

/// Resolves the normalized delivery status for a full [MessageModel].
///
/// Sender IDs are always excluded from [readBy] and [deliveredTo] so a sender
/// viewing their own message on multiple devices can never be mistaken for a
/// recipient read/delivery receipt.
MessageDeliveryStatus resolveMessageDeliveryStatus(
  MessageModel message, {
  String? currentUserId,
}) {
  if (message.isFailed || message.id.startsWith('failed_')) {
    return MessageDeliveryStatus.failed;
  }

  if (message.isPending ||
      message.id.startsWith('temp_') ||
      message.id.startsWith('local_')) {
    return MessageDeliveryStatus.sending;
  }

  final senderId = message.sender.id;
  bool isOtherUser(String uid) =>
      uid.isNotEmpty &&
      uid != senderId &&
      (currentUserId == null || uid != currentUserId);

  if (message.readBy.any(isOtherUser)) {
    return MessageDeliveryStatus.read;
  }

  if (message.deliveredTo.any(isOtherUser)) {
    return MessageDeliveryStatus.delivered;
  }

  return MessageDeliveryStatus.sent;
}

/// Resolves the normalized delivery status for a conversation list
/// [MessagePreviewModel], matching the exact same rules as message bubbles.
MessageDeliveryStatus resolvePreviewDeliveryStatus(
  MessagePreviewModel preview,
) {
  if (preview.isFailed == true || preview.id.startsWith('failed_')) {
    return MessageDeliveryStatus.failed;
  }

  if (preview.isPending == true ||
      preview.id.startsWith('temp_') ||
      preview.id.startsWith('local_')) {
    return MessageDeliveryStatus.sending;
  }

  if (preview.isSeen == true) {
    return MessageDeliveryStatus.read;
  }

  if (preview.isDelivered == true) {
    return MessageDeliveryStatus.delivered;
  }

  return MessageDeliveryStatus.sent;
}

/// Reusable, theme-aware message status indicator used across message bubbles
/// and conversation list previews.
///
/// Visual mapping:
/// - `sending`: tiny animated circular loading indicator (no checkmarks)
/// - `sent` / `delivered`: ONE gray checkmark (never double gray checkmarks)
/// - `read`: TWO colored checkmarks in a high-contrast accent color
/// - `failed`: red error/retry indicator with optional [onRetry] action
class MessageStatusIndicator extends StatelessWidget {
  final MessageDeliveryStatus status;
  final MessageStatusSurface surface;
  final double size;
  final VoidCallback? onRetry;
  final String? retryTooltip;

  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.surface = MessageStatusSurface.surface,
    this.size = 14,
    this.onRetry,
    this.retryTooltip,
  });

  String get _semanticLabel {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return 'Sending';
      case MessageDeliveryStatus.sent:
        return 'Sent';
      case MessageDeliveryStatus.delivered:
        return 'Delivered';
      case MessageDeliveryStatus.read:
        return 'Read';
      case MessageDeliveryStatus.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color neutralGrayColor = surface == MessageStatusSurface.outgoingBubble
        ? const Color(0xFF374151)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final Color spinnerColor = surface == MessageStatusSurface.outgoingBubble
        ? const Color(0xFF1F2937)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final Color readAccentColor = surface == MessageStatusSurface.outgoingBubble
        ? const Color(0xFF1E40AF)
        : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));
    final Color errorColor = isDark
        ? const Color(0xFFF87171)
        : const Color(0xFFDC2626);

    late final Widget child;
    switch (status) {
      case MessageDeliveryStatus.sending:
        final spinnerSize = (size - 3).clamp(10.0, 14.0);
        child = SizedBox(
          width: spinnerSize,
          height: spinnerSize,
          child: CircularProgressIndicator(
            strokeWidth: 1.7,
            valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
          ),
        );
        break;

      case MessageDeliveryStatus.sent:
      case MessageDeliveryStatus.delivered:
        child = Icon(
          Icons.done_rounded,
          size: size,
          color: neutralGrayColor,
        );
        break;

      case MessageDeliveryStatus.read:
        child = Icon(
          Icons.done_all_rounded,
          size: size + 1,
          color: readAccentColor,
        );
        break;

      case MessageDeliveryStatus.failed:
        final errorIcon = surface == MessageStatusSurface.outgoingBubble
            ? Container(
                width: size + 2,
                height: size + 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.error_rounded,
                  size: size,
                  color: const Color(0xFFDC2626),
                ),
              )
            : Icon(
                Icons.error_outline_rounded,
                size: size + 1,
                color: errorColor,
              );

        if (onRetry != null) {
          child = Tooltip(
            message: retryTooltip ?? 'Failed to send. Tap to retry',
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: errorIcon,
              ),
            ),
          );
        } else {
          child = errorIcon;
        }
        break;
    }

    return Semantics(
      label: _semanticLabel,
      button: status == MessageDeliveryStatus.failed && onRetry != null,
      child: child,
    );
  }
}
