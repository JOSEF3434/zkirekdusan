// lib/features/live/presentation/widgets/live_chat_widget.dart
// Live chat panel: scrollable message list + emoji-reaction bar + text input.
//
// Features:
//   • Regular chat messages with tappable sender username → /u/:username
//   • Emoji reactions: avatar/initials pill, emoji pill, count badge,
//     sender name as tappable profile link, "reacted" label — all left-aligned
//   • Consecutive same-emoji reactions from the same user update count in-place
//   • Quick-emoji bar with spring-bounce animation
//   • Adaptive density for narrow (mobile) vs wide (web/tablet) panels

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';
import 'package:mobile/features/live/presentation/providers/chat_provider.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─── Quick-reaction emojis ────────────────────────────────────────────────────

const _kQuickEmojis = ['❤️', '🔥', '👏', '😂', '😮', '💯', '🎉', '👍'];

// ─── Main widget ──────────────────────────────────────────────────────────────

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
    _autoScroll = pos.pixels >= pos.maxScrollExtent - 80;
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

  void _sendReaction(String emoji) =>
      ref.read(chatProvider(widget.streamId).notifier).sendReaction(emoji);

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.streamId));
    final cs        = Theme.of(context).colorScheme;

    // Auto-scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoScroll && _scrollCtrl.hasClients) _scrollToBottom();
    });

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        _ChatHeader(hasError: chatState.error != null),
        Divider(height: 1, color: cs.outlineVariant),

        // ── Message list ────────────────────────────────────────────────────
        Expanded(
          child: chatState.isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : chatState.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 36, color: cs.outlineVariant),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to say something!',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      itemCount: chatState.messages.length,
                      itemBuilder: (_, i) => _MessageTile(
                        message: chatState.messages[i],
                        isModerator: widget.isModerator,
                      ),
                    ),
        ),

        // ── Send-error banner ───────────────────────────────────────────────
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
        _QuickEmojiBar(onTap: _sendReaction),

        // ── Text input bar ──────────────────────────────────────────────────
        _InputBar(
          ctrl: _textCtrl,
          isSending: chatState.isSending,
          onSend: _send,
        ),
      ],
    );
  }
}

// ─── Chat header ──────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final bool hasError;
  const _ChatHeader({required this.hasError});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 16,
            color: cs.primary,
          ),
          const SizedBox(width: 6),
          const Text(
            'Live Chat',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const Spacer(),
          if (hasError)
            Tooltip(
              message: 'Connection issue',
              child: Icon(Icons.wifi_off_rounded,
                  size: 16, color: cs.error),
            ),
        ],
      ),
    );
  }
}

// ─── Quick-emoji bar ──────────────────────────────────────────────────────────

class _QuickEmojiBar extends StatelessWidget {
  final void Function(String) onTap;
  const _QuickEmojiBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _kQuickEmojis
            .map((e) => _EmojiButton(emoji: e, onTap: () => onTap(e)))
            .toList(),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isSending;
  final VoidCallback onSend;
  const _InputBar({
    required this.ctrl,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
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
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: isSending ? null : onSend,
            icon: isSending
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : Icon(Icons.send_rounded, color: cs.primary),
            style: IconButton.styleFrom(
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated emoji button ────────────────────────────────────────────────────

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
    _scale = Tween<double>(begin: 1, end: 1.5).animate(
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
  Widget build(BuildContext context) => GestureDetector(
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

// ─── Message tile (dispatches to reaction or chat) ────────────────────────────

class _MessageTile extends StatelessWidget {
  final ChatMessageDto message;
  final bool isModerator;

  const _MessageTile({required this.message, required this.isModerator});

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
                .withValues(alpha: 0.45),
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      );
    }

    if (message.type == ChatMessageType.system) {
      return _ReactionTile(message: message);
    }

    return _ChatTile(message: message, isModerator: isModerator);
  }
}

// ─── Reaction tile ─────────────────────────────────────────────────────────────
//
// Layout (left-aligned row):
//
//  ┌─────────────────────────────────────────────────────────┐
//  │  [👤]  [👏 ×7]  @mr_jones  reacted                     │
//  └─────────────────────────────────────────────────────────┘
//
// • Avatar = photo if available, else coloured initials circle
// • Emoji pill = rounded dark chip with emoji + bold count
// • Sender name = tappable coloured pill → /u/:username
// • "reacted" label in muted text

class _ReactionTile extends StatelessWidget {
  final ChatMessageDto message;
  const _ReactionTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sender = message.sender;
    final senderId = sender?.id;
    final usernameRaw = sender?.username ??
        (senderId != null && senderId != 'anon' ? senderId : null);
    final cleanUsername = usernameRaw?.replaceFirst(RegExp(r'^@'), '').trim();
    final name = sender?.displayName?.trim().isNotEmpty == true
        ? sender!.displayName!.trim()
        : (cleanUsername != null && cleanUsername.isNotEmpty
            ? cleanUsername
            : 'Viewer');
    final avatarUrl = sender?.avatarUrl;

    // Parse emoji and count from: "👏" or "👏 x7" or "👏 ×7"
    final raw = message.content;
    final xAscii = raw.indexOf(' x');
    final xUni = raw.indexOf(' ×');
    final sepIdx = xAscii != -1 ? xAscii : xUni;
    final emoji = sepIdx == -1 ? raw.trim() : raw.substring(0, sepIdx).trim();
    final count = sepIdx == -1
        ? 1
        : int.tryParse(raw.substring(sepIdx + 2).trim()) ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar (tappable to view profile) ─────────────────────────────
          _Avatar(
            name: name,
            avatarUrl: avatarUrl,
            size: 24,
            username: cleanUsername,
          ),
          const SizedBox(width: 6),

          // ── Emoji pill ───────────────────────────────────────────────────
          _EmojiPill(emoji: emoji, count: count, cs: cs),

          // ── Sender name + "reacted" ──────────────────────────────────────
          const SizedBox(width: 7),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileNameButton(
                  name: name,
                  username: cleanUsername,
                  color: cs.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'reacted',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Emoji pill ───────────────────────────────────────────────────────────────

class _EmojiPill extends StatelessWidget {
  final String emoji;
  final int count;
  final ColorScheme cs;
  const _EmojiPill({required this.emoji, required this.count, required this.cs});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          if (count > 1) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'x$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Avatar widget ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? name;
  final String? avatarUrl;
  final double size;
  final String? username;
  const _Avatar({this.name, this.avatarUrl, required this.size, this.username});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canNav = username != null && username!.isNotEmpty;

    Widget child;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      child = ClipOval(
        child: AppNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      final initial = (name != null && name!.isNotEmpty)
          ? name![0].toUpperCase()
          : (username != null && username!.isNotEmpty
              ? username![0].toUpperCase()
              : 'U');

      child = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w700,
            color: cs.onPrimaryContainer,
          ),
        ),
      );
    }

    if (canNav) {
      return Tooltip(
        message: 'View profile',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.push('/u/$username'),
            child: child,
          ),
        ),
      );
    }
    return child;
  }
}

// ─── Regular chat tile ────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatMessageDto message;
  final bool isModerator;
  const _ChatTile({required this.message, required this.isModerator});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sender = message.sender;
    final senderId = sender?.id;
    final usernameRaw = sender?.username ??
        (senderId != null && senderId != 'anon' ? senderId : null);
    final cleanUsername = usernameRaw?.replaceFirst(RegExp(r'^@'), '').trim();
    final name = sender?.displayName?.trim().isNotEmpty == true
        ? sender!.displayName!.trim()
        : (cleanUsername != null && cleanUsername.isNotEmpty
            ? cleanUsername
            : 'Viewer');
    final avatarUrl = sender?.avatarUrl;

    // Pinned → amber, others → primary
    final nameColor = message.isPinned ? Colors.amber.shade600 : cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pin icon
          if (message.isPinned)
            const Padding(
              padding: EdgeInsets.only(right: 4, top: 3),
              child: Icon(Icons.push_pin_rounded,
                  size: 11, color: Colors.amber),
            ),

          // Mini avatar
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 1),
            child: _Avatar(
              name: name,
              avatarUrl: avatarUrl,
              size: 20,
              username: cleanUsername,
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      // Tappable username chip inline
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: _ProfileNameButton(
                            name: name,
                            username: cleanUsername,
                            color: nameColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: message.content,
                        style: TextStyle(fontSize: 13, color: cs.onSurface),
                      ),
                    ],
                  ),
                ),
                if (message.isPending)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Sending…',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Text(
              timeago.format(
                DateTime.tryParse(message.createdAt) ?? DateTime.now(),
                allowFromNow: true,
              ),
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile name button (reused by both tiles) ───────────────────────────────
//
// Tapping navigates to /u/:username (PublicProfileScreen).
// Keeps the polished button pill style and color.

class _ProfileNameButton extends StatelessWidget {
  final String name;
  final String? username;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;

  const _ProfileNameButton({
    required this.name,
    required this.username,
    required this.color,
    this.fontSize = 11.5,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final clean = username?.replaceFirst(RegExp(r'^@'), '').trim();
    final canNav = clean != null && clean.isNotEmpty;

    return Tooltip(
      message: canNav ? 'View @$clean profile' : name,
      child: MouseRegion(
        cursor: canNav ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: canNav ? () => context.push('/u/$clean') : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 0.9,
              ),
            ),
            child: Text(
              name,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
