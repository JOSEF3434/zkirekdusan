// lib/features/chats/presentation/widgets/chat_details_panel.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/shared_media_tabs_view.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

/// Telegram-style right-side info panel.
/// Shows person info for DIRECT chats, group info for group chats.
class ChatDetailsPanel extends ConsumerWidget {
  final String conversationId;
  final VoidCallback onClose;
  final Function(String messageId)? onJumpToMessage;

  const ChatDetailsPanel({
    super.key,
    required this.conversationId,
    required this.onClose,
    this.onJumpToMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF17212B) : Colors.white;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    final singleConvAsync = ref.watch(singleConversationProvider(conversationId));
    final discoveryAsync = ref.watch(chatDiscoveryProvider);
    final currentUserId = ref.watch(authProvider).user?.id;

    ConversationModel? conversation = singleConvAsync.value;
    if (conversation == null) {
      discoveryAsync.whenData((d) {
        try {
          conversation = d.conversations.firstWhere((c) => c.id == conversationId);
        } catch (_) {}
      });
    }

    if (conversation == null) {
      if (singleConvAsync.hasError) {
        return _buildError(bg, isDark, dividerColor, ref);
      }
      return _buildLoading(bg, isDark, dividerColor);
    }

    final isDirect = conversation!.type == 'DIRECT';

    if (isDirect) {
      final other = conversation!.members.firstWhere(
        (m) => m.userId != currentUserId,
        orElse: () => conversation!.members.isNotEmpty
            ? conversation!.members.first
            : const ConversationMemberModel(userId: '', username: ''),
      );
      return _DirectDetailsPanel(
        conversation: conversation!,
        other: other,
        isDark: isDark,
        bg: bg,
        dividerColor: dividerColor,
        onClose: onClose,
        ref: ref,
        onJumpToMessage: onJumpToMessage,
      );
    } else {
      return _GroupDetailsPanel(
        conversation: conversation!,
        currentUserId: currentUserId,
        isDark: isDark,
        bg: bg,
        dividerColor: dividerColor,
        onClose: onClose,
        ref: ref,
        context: context,
        onJumpToMessage: onJumpToMessage,
      );
    }
  }

  Widget _buildLoading(Color bg, bool isDark, Color dividerColor) {
    return Container(
      color: bg,
      child: Column(
        children: [
          _PanelHeader(onClose: onClose, isDark: isDark),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Color bg, bool isDark, Color dividerColor, WidgetRef ref) {
    return Container(
      color: bg,
      child: Column(
        children: [
          _PanelHeader(onClose: onClose, isDark: isDark),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 44, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load details',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.refresh(singleConversationProvider(conversationId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C6FF),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Direct (person) details panel
// ──────────────────────────────────────────────────────────────────────────────

class _DirectDetailsPanel extends StatelessWidget {
  final ConversationModel conversation;
  final ConversationMemberModel other;
  final bool isDark;
  final Color bg;
  final Color dividerColor;
  final VoidCallback onClose;
  final WidgetRef ref;
  final Function(String messageId)? onJumpToMessage;

  const _DirectDetailsPanel({
    required this.conversation,
    required this.other,
    required this.isDark,
    required this.bg,
    required this.dividerColor,
    required this.onClose,
    required this.ref,
    this.onJumpToMessage,
  });

  @override
  Widget build(BuildContext context) {
    final name = other.displayName ?? other.username;
    final avatarUrl = other.avatarUrl;
    final isOnline = other.isOnline;
    final lastSeen = other.lastSeen;

    return Container(
      color: bg,
      child: Column(
        children: [
          _PanelHeader(onClose: onClose, isDark: isDark),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Large avatar
                  _LargeAvatar(
                    name: name,
                    avatarUrl: avatarUrl,
                    isOnline: isOnline,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  // Name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Online/last seen
                  Text(
                    isOnline
                        ? 'Online'
                        : lastSeen != null
                            ? 'last seen ${_fmtSeen(lastSeen)}'
                            : 'Offline',
                    style: TextStyle(
                      fontSize: 13,
                      color: isOnline
                          ? const Color(0xFF10B981)
                          : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons row (Message / Mute / More)
                  _ActionButtonsRow(
                    isDark: isDark,
                    buttons: [
                      _ActionBtn(
                        icon: Icons.message_outlined,
                        label: 'Message',
                        onTap: () {},
                      ),
                      _ActionBtn(
                        icon: Icons.notifications_off_outlined,
                        label: 'Mute',
                        onTap: () {
                          ref
                              .read(conversationsProvider.notifier)
                              .muteConversation(conversation.id);
                        },
                      ),
                      _ActionBtn(
                        icon: Icons.call_outlined,
                        label: 'Call',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, color: dividerColor),
                  // Username info
                  _InfoRow(
                    icon: Icons.alternate_email_rounded,
                    iconColor: const Color(0xFF00C6FF),
                    title: '@${other.username}',
                    subtitle: 'Username',
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: dividerColor),
                  const SizedBox(height: 8),
                  // Shared media tabs
                  _SectionHeader(label: 'Shared Media', isDark: isDark),
                  SharedMediaTabsView(
                    conversationId: conversation.id,
                    isDark: isDark,
                    onJumpToMessage: onJumpToMessage,
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: dividerColor),
                  // Danger zone
                  _DangerAction(
                    icon: Icons.block_rounded,
                    label: 'Block User',
                    isDark: isDark,
                    onTap: () {},
                  ),
                  _DangerAction(
                    icon: Icons.delete_outline_rounded,
                    label: 'Clear Chat History',
                    isDark: isDark,
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtSeen(String lastSeen) {
    try {
      final date = DateTime.parse(lastSeen);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return lastSeen;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Group details panel
// ──────────────────────────────────────────────────────────────────────────────

class _GroupDetailsPanel extends StatelessWidget {
  final ConversationModel conversation;
  final String? currentUserId;
  final bool isDark;
  final Color bg;
  final Color dividerColor;
  final VoidCallback onClose;
  final WidgetRef ref;
  final BuildContext context;
  final Function(String messageId)? onJumpToMessage;

  const _GroupDetailsPanel({
    required this.conversation,
    required this.currentUserId,
    required this.isDark,
    required this.bg,
    required this.dividerColor,
    required this.onClose,
    required this.ref,
    required this.context,
    this.onJumpToMessage,
  });

  @override
  Widget build(BuildContext ctx) {
    final name = conversation.title ??
        conversation.metadata?.groupName ??
        'Group';
    final avatarUrl = conversation.metadata?.groupAvatar;
    final memberCount = conversation.members.length;
    final members = conversation.members;

    return Container(
      color: bg,
      child: Column(
        children: [
          _PanelHeader(onClose: onClose, isDark: isDark),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Group avatar
                  _LargeAvatar(
                    name: name,
                    avatarUrl: avatarUrl,
                    isOnline: false,
                    isDark: isDark,
                    isGroup: true,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$memberCount members',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  _ActionButtonsRow(
                    isDark: isDark,
                    buttons: [
                      _ActionBtn(
                        icon: Icons.notifications_off_outlined,
                        label: 'Mute',
                        onTap: () {
                          ref
                              .read(conversationsProvider.notifier)
                              .muteConversation(conversation.id);
                        },
                      ),
                      if (conversation.groupId != null)
                        _ActionBtn(
                          icon: Icons.settings_outlined,
                          label: 'Manage',
                          onTap: () =>
                              context.push('/groups/${conversation.groupId}?tab=settings'),
                        ),
                      _ActionBtn(
                        icon: Icons.exit_to_app_rounded,
                        label: 'Leave',
                        color: Colors.redAccent,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, color: dividerColor),
                  // Shared media tabs
                  _SectionHeader(label: 'Shared Media', isDark: isDark),
                  SharedMediaTabsView(
                    conversationId: conversation.id,
                    isDark: isDark,
                    onJumpToMessage: onJumpToMessage,
                  ),
                  Divider(height: 1, color: dividerColor),
                  const SizedBox(height: 8),
                  // Member list header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${members.length} MEMBERS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            if (conversation.groupId != null) {
                              context.push(
                                  '/groups/${conversation.groupId}?tab=members');
                            }
                          },
                          child: const Icon(Icons.search_rounded,
                              size: 20, color: Color(0xFF00C6FF)),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {},
                          child: const Icon(Icons.person_add_outlined,
                              size: 20, color: Color(0xFF00C6FF)),
                        ),
                      ],
                    ),
                  ),
                  // Member rows (up to 10)
                  ...members.take(10).map(
                        (m) => _MemberRow(
                          member: m,
                          isDark: isDark,
                          dividerColor: dividerColor,
                        ),
                      ),
                  if (members.length > 10)
                    InkWell(
                      onTap: () {
                        if (conversation.groupId != null) {
                          context.push(
                              '/groups/${conversation.groupId}?tab=members');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00C6FF)
                                    .withValues(alpha: 0.12),
                              ),
                              child: const Icon(Icons.people_outline,
                                  size: 20, color: Color(0xFF00C6FF)),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'See all ${members.length} members',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF00C6FF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: Colors.grey[500]),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ──────────────────────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final VoidCallback onClose;
  final bool isDark;

  const _PanelHeader({required this.onClose, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17212B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            'Info',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black54,
            ),
            onPressed: onClose,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final bool isDark;
  final bool isGroup;

  const _LargeAvatar({
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.isDark,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    const double radius = 44;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: avatarUrl == null
                ? LinearGradient(
                    colors: isGroup
                        ? [const Color(0xFF7C4DFF), const Color(0xFF00C6FF)]
                        : [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C6FF).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.transparent,
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl!)
                : null,
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 34,
                    ),
                  )
                : null,
          ),
        ),
        if (isOnline && !isGroup)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF17212B) : Colors.white,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionBtn {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class _ActionButtonsRow extends StatelessWidget {
  final bool isDark;
  final List<_ActionBtn> buttons;

  const _ActionButtonsRow({required this.isDark, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons.map((btn) {
          final color = btn.color ?? const Color(0xFF00C6FF);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: btn.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2638)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(btn.icon, color: color, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        btn.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}


class _DangerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _DangerAction({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.redAccent, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ConversationMemberModel member;
  final bool isDark;
  final Color dividerColor;

  const _MemberRow({
    required this.member,
    required this.isDark,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final name = member.displayName ?? member.username;
    final avatarUrl = member.avatarUrl;
    final isOnline = member.isOnline;

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    const Color(0xFF00C6FF).withValues(alpha: 0.2),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Color(0xFF00C6FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              if (isOnline)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark ? const Color(0xFF17212B) : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            isOnline ? 'online' : 'last seen recently',
            style: TextStyle(
              fontSize: 12,
              color: isOnline ? const Color(0xFF10B981) : Colors.grey[500],
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: 68,
          color: dividerColor,
        ),
      ],
    );
  }
}
