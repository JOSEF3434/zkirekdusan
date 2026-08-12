// lib/features/live/presentation/widgets/live_chat_widget.dart
// Live chat panel: scrollable message list + input field.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';
import 'package:mobile/features/live/presentation/providers/chat_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  final _textCtrl = TextEditingController();
  bool _autoScroll = true;

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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.streamId));
    final theme = Theme.of(context);

    // Auto-scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoScroll && _scrollCtrl.hasClients) _scrollToBottom();
    });

    return Column(
      children: [
        // Header
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

        // Message list
        Expanded(
          child: chatState.isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : chatState.messages.isEmpty
                  ? Center(
                      child: Text(
                        'Be the first to say something!',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      itemCount: chatState.messages.length,
                      itemBuilder: (_, i) {
                        final msg = chatState.messages[i];
                        return _MessageTile(
                          message: msg,
                          isModerator: widget.isModerator,
                          onDelete: () => ref
                              .read(chatProvider(widget.streamId).notifier)
                              .sendReaction('🗑️'), // stub
                        );
                      },
                    ),
        ),

        // Send error
        if (chatState.sendError != null)
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              chatState.sendError!,
              style:
                  const TextStyle(fontSize: 12, color: Colors.deepOrange),
            ),
          ),

        // Input bar
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              // Quick emoji reactions
              GestureDetector(
                onTap: () => ref
                    .read(chatProvider(widget.streamId).notifier)
                    .sendReaction('❤️'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('❤️', style: TextStyle(fontSize: 20)),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  maxLength: 500,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  buildCounter: (_, {required count, required isFocused, maxLength}) =>
                      null,
                  decoration: InputDecoration(
                    hintText: 'Say something…',
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider(widget.streamId).notifier).sendMessage(text);
    _textCtrl.clear();
    _autoScroll = true;
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

    final sender =
        message.sender?.displayName ?? message.sender?.username ?? 'Viewer';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pin indicator
          if (message.isPinned)
            const Icon(Icons.push_pin, size: 12, color: Colors.amber),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$sender  ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: message.content,
                        style: const TextStyle(fontSize: 13),
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

          // Time
          Text(
            timeago.format(
              DateTime.tryParse(message.createdAt) ?? DateTime.now(),
              allowFromNow: true,
            ),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
