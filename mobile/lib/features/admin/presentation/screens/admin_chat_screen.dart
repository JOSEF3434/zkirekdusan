// lib/features/admin/presentation/screens/admin_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_confirmation_dialog.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_filter_chips.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_search_bar.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_status_badge.dart';

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────

class _ConversationItem {
  final String id;
  final String type;
  final String? groupName;
  final String? channelName;
  final int memberCount;
  final int messageCount;
  final DateTime? lastMessageAt;

  _ConversationItem({
    required this.id,
    required this.type,
    this.groupName,
    this.channelName,
    required this.memberCount,
    required this.messageCount,
    this.lastMessageAt,
  });

  factory _ConversationItem.fromJson(Map<String, dynamic> json) {
    final count = safeMap(json['_count']);
    final members = json['members'] as List?;
    final group = safeMap(json['group']);
    final channel = safeMap(json['channel']);
    return _ConversationItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'GROUP',
      groupName: group?['name'] as String?,
      channelName: channel?['name'] as String?,
      memberCount: (count?['members'] as num?)?.toInt() ?? (members?.length ?? 0),
      messageCount: (count?['messages'] as num?)?.toInt() ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
    );
  }

  String get displayName =>
      groupName ?? channelName ?? 'Direct ($type)';
}

class _MessageItem {
  final String id;
  final String? senderUsername;
  final String? senderDisplayName;
  final String? content;
  final DateTime createdAt;

  _MessageItem({
    required this.id,
    this.senderUsername,
    this.senderDisplayName,
    this.content,
    required this.createdAt,
  });

  factory _MessageItem.fromJson(Map<String, dynamic> json) {
    final sender = safeMap(json['sender']);
    final profile = safeMap(sender?['profile']);
    return _MessageItem(
      id: json['id'] as String? ?? '',
      senderUsername: sender?['username'] as String?,
      senderDisplayName: profile?['displayName'] as String?,
      content: json['content'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────

class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({super.key});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final List<_ConversationItem> _conversations = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _page = 1;
  bool _hasNext = false;
  String _search = '';
  String _selectedType = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchConversations(reset: true);
  }

  Future<void> _fetchConversations({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      setState(() {
        _page = 1;
        _conversations.clear();
        _isLoading = true;
        _hasError = false;
      });
    } else {
      setState(() => _isLoading = true);
    }
    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getConversations(
        page: _page,
        limit: 20,
        type: _selectedType == 'ALL' ? null : _selectedType,
        search: _search.isEmpty ? null : _search,
      );
      final items = (res['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => _ConversationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final hasNext = res['hasNext'] as bool? ?? false;
      setState(() {
        _conversations.addAll(items);
        _hasNext = hasNext;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _purgeConversation(_ConversationItem conv) async {
    final tr = ref.read(trProvider);
    final reason = await AdminConfirmationDialog.show(
      context,
      title: tr('admin.chat.purge_title'),
      message: tr('admin.chat.purge_msg'),
      confirmLabel: tr('admin.actions.delete'),
      confirmColor: Colors.red,
      requireReason: true,
    );
    if (reason == null) return;
    final repo = ref.read(adminRepositoryProvider);
    final ok = await repo.purgeConversation(conv.id, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? tr('admin.chat.purge_success')
            : tr('admin.chat.purge_fail')),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    if (ok) _fetchConversations(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.chat')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchConversations(reset: true),
            tooltip: tr('common.retry'),
          ),
        ],
      ),
      body: AdminResponsiveLayout(
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AdminSearchBar(
                hintText: tr('admin.search_placeholder'),
                onSearch: (v) {
                  _search = v;
                  _fetchConversations(reset: true);
                },
              ),
            ),
            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AdminFilterChips(
                filters: const [
                  AdminFilterChipItem(label: 'All', value: 'ALL'),
                  AdminFilterChipItem(label: 'Group', value: 'GROUP'),
                  AdminFilterChipItem(label: 'Channel', value: 'CHANNEL'),
                  AdminFilterChipItem(label: 'Direct', value: 'DIRECT'),
                ],
                selectedValue: _selectedType,
                onSelected: (v) {
                  setState(() => _selectedType = v);
                  _fetchConversations(reset: true);
                },
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(child: _buildContent(tr, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String Function(String) tr, ThemeData theme) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(tr('common.error'), style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _fetchConversations(reset: true),
              child: Text(tr('common.retry')),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(tr('admin.chat.empty'), style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchConversations(reset: true),
      child: ListView.builder(
        itemCount: _conversations.length + (_hasNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _conversations.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: FilledButton(
                  onPressed: () {
                    _page++;
                    _fetchConversations();
                  },
                  child: Text(tr('admin.load_more')),
                ),
              ),
            );
          }
          final conv = _conversations[index];
          return _ConversationTile(
            conv: conv,
            onPurge: () => _purgeConversation(conv),
            onTap: () => _openMessages(conv),
          );
        },
      ),
    );
  }

  void _openMessages(_ConversationItem conv) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ChatMessagesScreen(conversation: conv),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Conversation Tile
// ─────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final _ConversationItem conv;
  final VoidCallback onTap;
  final VoidCallback onPurge;

  const _ConversationTile({
    required this.conv,
    required this.onTap,
    required this.onPurge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = conv.type == 'GROUP'
        ? Colors.deepPurple
        : conv.type == 'CHANNEL'
            ? Colors.teal
            : Colors.blueAccent;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: typeColor.withValues(alpha: 0.15),
        child: Icon(
          conv.type == 'CHANNEL'
              ? Icons.tag_rounded
              : conv.type == 'DIRECT'
                  ? Icons.person_rounded
                  : Icons.groups_rounded,
          color: typeColor,
          size: 20,
        ),
      ),
      title: Text(
        conv.displayName,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${conv.messageCount} msgs · ${conv.memberCount} members',
        style: theme.textTheme.labelSmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminStatusBadge(status: conv.type),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
            tooltip: 'Purge all messages',
            onPressed: onPurge,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────
// Messages Drill-down Screen
// ─────────────────────────────────────────────

class _ChatMessagesScreen extends ConsumerStatefulWidget {
  final _ConversationItem conversation;

  const _ChatMessagesScreen({required this.conversation});

  @override
  ConsumerState<_ChatMessagesScreen> createState() =>
      _ChatMessagesScreenState();
}

class _ChatMessagesScreenState extends ConsumerState<_ChatMessagesScreen> {
  final List<_MessageItem> _messages = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _page = 1;
  bool _hasNext = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchMessages(reset: true);
  }

  Future<void> _fetchMessages({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      setState(() {
        _page = 1;
        _messages.clear();
        _isLoading = true;
        _hasError = false;
      });
    } else {
      setState(() => _isLoading = true);
    }
    try {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.getConversationMessages(
        widget.conversation.id,
        page: _page,
        limit: 30,
        search: _search.isEmpty ? null : _search,
      );
      final items = (res['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => _MessageItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final hasNext = res['hasNext'] as bool? ?? false;
      setState(() {
        _messages.addAll(items);
        _hasNext = hasNext;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _deleteMessage(_MessageItem msg) async {
    final tr = ref.read(trProvider);
    final reason = await AdminConfirmationDialog.show(
      context,
      title: tr('admin.confirm.delete_title'),
      message: tr('admin.chat.delete_msg_confirm'),
      confirmLabel: tr('admin.actions.delete'),
      confirmColor: Colors.red,
      requireReason: false,
    );
    if (reason == null) return;
    final repo = ref.read(adminRepositoryProvider);
    final ok = await repo.deleteMessage(msg.id, reason: reason.isNotEmpty ? reason : null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? tr('admin.chat.delete_msg_success')
            : tr('admin.chat.delete_msg_fail')),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    if (ok) _fetchMessages(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.conversation.displayName,
                style: theme.textTheme.titleMedium),
            Text(
              '${widget.conversation.messageCount} ${tr('admin.chat.messages')}',
              style:
                  theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchMessages(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: AdminSearchBar(
              hintText: tr('admin.search_placeholder'),
              onSearch: (v) {
                _search = v;
                _fetchMessages(reset: true);
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildContent(tr, theme)),
        ],
      ),
    );
  }

  Widget _buildContent(String Function(String) tr, ThemeData theme) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(tr('common.error')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _fetchMessages(reset: true),
              child: Text(tr('common.retry')),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(child: Text(tr('admin.chat.no_messages')));
    }

    return RefreshIndicator(
      onRefresh: () => _fetchMessages(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _messages.length + (_hasNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: FilledButton(
                  onPressed: () {
                    _page++;
                    _fetchMessages();
                  },
                  child: Text(tr('admin.load_more')),
                ),
              ),
            );
          }
          final msg = _messages[index];
          return _MessageTile(msg: msg, onDelete: () => _deleteMessage(msg));
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Message Tile
// ─────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  final _MessageItem msg;
  final VoidCallback onDelete;

  const _MessageTile({required this.msg, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final senderName =
        msg.senderDisplayName ?? msg.senderUsername ?? 'Unknown';
    final timeStr =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
                child: Text(
                  senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: Colors.blueAccent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          senderName,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          timeStr,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      msg.content ?? '[media]',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded,
                    size: 18, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Delete message',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
