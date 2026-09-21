// lib/features/chats/presentation/widgets/pinned_messages_bar.dart

import 'package:flutter/material.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';

class PinnedMessagesBar extends StatefulWidget {
  final List<MessageModel> pinnedMessages;
  final Function(MessageModel message) onSelectMessage;
  final Function(MessageModel message)? onUnpinMessage;
  final bool canUnpin;

  const PinnedMessagesBar({
    super.key,
    required this.pinnedMessages,
    required this.onSelectMessage,
    this.onUnpinMessage,
    this.canUnpin = true,
  });

  @override
  State<PinnedMessagesBar> createState() => _PinnedMessagesBarState();
}

class _PinnedMessagesBarState extends State<PinnedMessagesBar>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(PinnedMessagesBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pinnedMessages.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= widget.pinnedMessages.length) {
      _currentIndex = 0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _cycleNext() {
    if (widget.pinnedMessages.isEmpty) return;

    final target = widget.pinnedMessages[_currentIndex];
    widget.onSelectMessage(target);

    if (widget.pinnedMessages.length > 1) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.pinnedMessages.length;
      });
      _animController.forward(from: 0.0);
    }
  }

  void _showAllPinnedSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161C28) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.push_pin_rounded,
                    color: Color(0xFF00C6FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pinned Messages (${widget.pinnedMessages.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.pinnedMessages.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final msg = widget.pinnedMessages[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(
                        0xFF00C6FF,
                      ).withValues(alpha: 0.15),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF00C6FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      msg.sender.displayName ?? msg.sender.username ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _getMessageSnippet(msg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    trailing: widget.canUnpin
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onUnpinMessage?.call(msg);
                            },
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _currentIndex = index);
                      widget.onSelectMessage(msg);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMessageSnippet(MessageModel msg) {
    if (msg.type == 'VOICE' || msg.voiceNote != null) {
      return '🎤 Voice message';
    }
    if (msg.type == 'IMAGE') {
      return '📷 Photo';
    }
    if (msg.type == 'VIDEO') {
      return '📹 Video';
    }
    if (msg.attachments.isNotEmpty) {
      return '📎 ${msg.attachments.first.originalName}';
    }
    return msg.content?.isNotEmpty == true ? msg.content! : 'Pinned message';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pinnedMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.pinnedMessages.length;
    final currentMsg = widget.pinnedMessages[_currentIndex.clamp(0, total - 1)];

    return Material(
      color: isDark
          ? const Color(0xFF131822).withValues(alpha: 0.95)
          : const Color(0xFFF1F5F9).withValues(alpha: 0.95),
      child: InkWell(
        onTap: _cycleNext,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Left vertical Telegram-style accent bar
              Container(
                width: 3.5,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),

              // Title and preview text
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            total > 1
                                ? 'Pinned Message #${_currentIndex + 1} of $total'
                                : 'Pinned Message',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C6FF),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${currentMsg.sender.displayName ?? currentMsg.sender.username}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getMessageSnippet(currentMsg),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Multiple pinned list button
              if (total > 1)
                IconButton(
                  icon: const Icon(Icons.list_rounded, size: 20),
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  tooltip: 'All pinned messages',
                  onPressed: () => _showAllPinnedSheet(context),
                ),

              // Unpin button
              if (widget.canUnpin)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  tooltip: 'Unpin message',
                  onPressed: () => widget.onUnpinMessage?.call(currentMsg),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
