// lib/features/live/presentation/widgets/live_chat_widget.dart
// Live chat panel: scrollable message list + emoji-reaction bar + input.
//
// Changes vs original:
//   • Reactions shown inline with sender name (tappable → profile) + big emoji
//   • Consecutive same-emoji reactions from the same sender are merged in-place
//   • Bottom bar has a quick-reaction row (7 emojis) above the text field
//   • Username links navigate to /u/:username (PublicProfileScreen)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';
import 'package:mobile/features/live/presentation/providers/chat_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─── Quick-reaction emojis shown in the bottom bar ───────────────────────────

const _kQuickEmojis = ['❤️', '🔥', '👏', '😂', '😮', '💯', '🎉', '👍'];

// ─── Widget ───────────────────────────────────────────────────────────────────

class LiveChatWidget extends ConsumerStatefulWidget {
  final String streamId;
  final bool isModerator;

  const LiveChatWidget({
    super.key,
    required this.streamId,
    this.isModerator = false,
  });

  @override
  ConsumerState<LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends ConsumerState<LiveChatWidget> {
  final _scrollCtrl = ScrollController();
  final _textCtrl   = TextEditingController();
  bool _autoScroll  = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    _autoScroll = pos.pixels >= pos.maxScrollExtent - 60;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider(widget.streamId).notifier).sendMessage(text);
    _textCtrl.clear();
    _autoScroll = true;
  }

  void _sendReaction(String emoji) {
    ref.read(chatProvider(widget.streamId).notifier).sendReaction(emoji);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.streamId));
    final theme     = Theme.of(context);
    final cs        = theme.colorScheme;

    // Auto-scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoScroll && _scrollCtrl.hasClients) _scrollToBottom();
    });

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Live Chat',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Spacer(),
              if (chatState.error != null)
                const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Message list ────────────────────────────────────────────────────
        Expanded(
          child: chatState.isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : chatState.messages.isEmpty
                  ? Center(
                      child: Text(
                        'Be the first to say something!',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      itemCount: chatState.messages.length,
                      itemBuilder: (_, i) {
                        final msg = chatState.messages[i];
                        return _MessageTile(
                          message: msg,
                          isModerator: widget.isModerator,
                          onDelete: () => ref
                              .read(chatProvider(widget.streamId).notifier)
                              .sendReaction('🗑️'),
                        );
                      },
                    ),
        ),

        // ── Send error banner ───────────────────────────────────────────────
        if (chatState.sendError != null)
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              chatState.sendError!,
              style: const TextStyle(fontSize: 12, color: Colors.deepOrange),
            ),
          ),

        // ── Quick-emoji bar ─────────────────────────────────────────────────
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _kQuickEmojis
                .map(
                  (e) => _EmojiButton(emoji: e, onTap: () => _sendReaction(e)),
                )
                .toList(),
          ),
        ),

        // ── Text input bar ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: cs.surfaceContainerHighest,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  maxLength: 500,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Say something…',
                    isDense: true,
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: chatState.isSending ? null : _send,
                icon: chatState.isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                color: cs.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Quick emoji button ───────────────────────────────────────────────────────

class _EmojiButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;
  const _EmojiButton({required this.emoji, required this.onTap});

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Text(widget.emoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}

// ─── Message tile ─────────────────────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  final ChatMessageDto message;
  final bool isModerator;
  final VoidCallback? onDelete;

  const _MessageTile({
    required this.message,
    required this.isModerator,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Deleted
    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '[Message deleted]',
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      );
    }

    // ── Reaction / emoji system message ─────────────────────────────────────
    if (message.type == ChatMessageType.system) {
      return _ReactionTile(message: message);
    }

    // ── Regular chat message ─────────────────────────────────────────────────
    return _ChatTile(message: message, isModerator: isModerator);
  }
}

// ─── Reaction tile ────────────────────────────────────────────────────────────

class _ReactionTile extends StatelessWidget {
  final ChatMessageDto message;
  const _ReactionTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final cs      = theme.colorScheme;
    final sender  = message.sender;
    final name    = sender?.displayName ?? sender?.username;
    final username = sender?.username;

    // Extract emoji and optional count label from content (e.g. "❤️ ×3")
    final content = message.content;
    final parts   = content.split(' ×');
    final emoji   = parts[0].trim();
    final hasCount = parts.length > 1;
    final count    = hasCount ? '×${parts[1]}' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Big animated emoji pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                if (hasCount) ...[
                  const SizedBox(width: 4),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Sender name (tappable → profile)
          if (name != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                if (username != null) {
                  context.push('/u/$username');
                }
              },
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: cs.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Regular chat tile ────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatMessageDto message;
  final bool isModerator;
  const _ChatTile({required this.message, required this.isModerator});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final sender   = message.sender;
    final name     = sender?.displayName ?? sender?.username ?? 'Viewer';
    final username = sender?.username;

    // Pinned messages get amber, others get primary
    final nameColor = message.isPinned ? Colors.amber : cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pin indicator
          if (message.isPinned)
            const Padding(
              padding: EdgeInsets.only(right: 4, top: 2),
              child: Icon(Icons.push_pin, size: 12, color: Colors.amber),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name (tappable) + message content inline
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () {
                            if (username != null) {
                              context.push('/u/$username');
                            }
                          },
                          child: Text(
                            '$name  ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: nameColor,
                              decoration: username != null
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationColor:
                                  nameColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: message.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                if (message.isPending)
                  const Text(
                    'Sending…',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 1),
            child: Text(
              timeago.format(
                DateTime.tryParse(message.createdAt) ?? DateTime.now(),
                allowFromNow: true,
              ),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
