// lib/features/chats/presentation/screens/chat_search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/explore/data/search_repository.dart';
import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class ChatSearchScreen extends ConsumerStatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  ConsumerState<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends ConsumerState<ChatSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _loadingUserId;
  List<SearchUserDto> _foundUsers = [];
  List<SearchGroupDto> _foundGroups = [];
  String _activeTab = 'all'; // 'all', 'chats', 'users', 'groups'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _foundUsers = [];
        _foundGroups = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final searchRepo = ref.read(searchRepositoryProvider);
      final results = await searchRepo.search(query: query.trim(), limit: 25);
      if (mounted) {
        setState(() {
          _foundUsers = results.results.users;
          _foundGroups = results.results.groups;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startDirectChat(String userId) async {
    setState(() => _loadingUserId = userId);
    try {
      final conv = await ref
          .read(conversationsProvider.notifier)
          .createOrGetDirectConversation(userId);
      if (mounted) {
        context.pushReplacement('/chats/conversation/${conv.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingUserId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = ref.watch(authProvider).user?.id;
    final query = _searchController.text.trim().toLowerCase();

    // Filter existing conversations matching query
    final allConversations = ref.watch(conversationsProvider).value ?? [];
    final matchingConversations = allConversations.where((c) {
      if (query.isEmpty) return false;
      final title = c.title?.toLowerCase() ?? '';
      final snippet = c.lastMessage?.content?.toLowerCase() ?? '';
      final otherMember = c.type == 'DIRECT'
          ? c.members.firstWhere(
              (m) => m.userId != currentUserId,
              orElse: () => c.members.first,
            )
          : null;
      final username = otherMember?.username.toLowerCase() ?? '';
      final displayName = otherMember?.displayName?.toLowerCase() ?? '';

      return title.contains(query) ||
          snippet.contains(query) ||
          username.contains(query) ||
          displayName.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F141C) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF131822) : Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2638) : Colors.grey[100],
            borderRadius: BorderRadius.circular(21),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearch,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Search chats, users, groups...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          if (query.isNotEmpty)
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _SearchTabChip(
                    label: 'All',
                    isSelected: _activeTab == 'all',
                    onTap: () => setState(() => _activeTab = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _SearchTabChip(
                    label: 'Chats (${matchingConversations.length})',
                    isSelected: _activeTab == 'chats',
                    onTap: () => setState(() => _activeTab = 'chats'),
                  ),
                  const SizedBox(width: 8),
                  _SearchTabChip(
                    label: 'Users (${_foundUsers.length})',
                    isSelected: _activeTab == 'users',
                    onTap: () => setState(() => _activeTab = 'users'),
                  ),
                  const SizedBox(width: 8),
                  _SearchTabChip(
                    label: 'Groups (${_foundGroups.length})',
                    isSelected: _activeTab == 'groups',
                    onTap: () => setState(() => _activeTab = 'groups'),
                  ),
                ],
              ),
            ),

          const Divider(height: 1, thickness: 0.5),

          // Search Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : query.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(
                        isDark,
                        matchingConversations,
                        _foundUsers,
                        _foundGroups,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'Search messages, people and groups',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    bool isDark,
    List matchingConversations,
    List<SearchUserDto> users,
    List<SearchGroupDto> groups,
  ) {
    final showChats = (_activeTab == 'all' || _activeTab == 'chats') && matchingConversations.isNotEmpty;
    final showUsers = (_activeTab == 'all' || _activeTab == 'users') && users.isNotEmpty;
    final showGroups = (_activeTab == 'all' || _activeTab == 'groups') && groups.isNotEmpty;

    if (!showChats && !showUsers && !showGroups) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Existing Chats
        if (showChats) ...[
          _buildSectionHeader('CHATS'),
          ...matchingConversations.map((conv) => ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF00C6FF), size: 18),
                ),
                title: Text(
                  conv.title ?? 'Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  conv.lastMessage?.content ?? 'No messages',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.push('/chats/conversation/${conv.id}'),
              )),
        ],

        // Global Users
        if (showUsers) ...[
          _buildSectionHeader('GLOBAL USERS'),
          ...users.map((u) => ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                  backgroundImage: u.avatarUrl != null ? CachedNetworkImageProvider(u.avatarUrl!) : null,
                  child: u.avatarUrl == null
                      ? Text(
                          u.displayName?.isNotEmpty == true
                              ? u.displayName![0].toUpperCase()
                              : 'U',
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                title: Text(
                  u.displayName ?? u.username ?? 'User',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: u.username != null
                    ? Text('@${u.username}', style: TextStyle(color: Colors.grey[500], fontSize: 13))
                    : null,
                trailing: _loadingUserId == u.id
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chat_outlined, size: 20, color: Color(0xFF00C6FF)),
                onTap: () => _startDirectChat(u.id),
              )),
        ],

        // Groups & Channels
        if (showGroups) ...[
          _buildSectionHeader('GROUPS & CHANNELS'),
          ...groups.map((g) => ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0072FF).withValues(alpha: 0.2),
                  backgroundImage: g.avatarUrl != null ? CachedNetworkImageProvider(g.avatarUrl!) : null,
                  child: g.avatarUrl == null
                      ? const Icon(Icons.group, color: Color(0xFF00C6FF), size: 20)
                      : null,
                ),
                title: Text(
                  g.name ?? 'Group',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  g.slug != null ? '@${g.slug}' : 'Public group',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                onTap: () => context.push('/groups/${g.id}'),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _SearchTabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SearchTabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00C6FF)
              : Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E2638)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.black
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
