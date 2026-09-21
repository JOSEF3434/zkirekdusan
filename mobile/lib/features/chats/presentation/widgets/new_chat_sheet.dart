import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/create_group_sheet.dart';
import 'package:mobile/features/explore/data/search_repository.dart';
import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class NewChatSheet extends ConsumerStatefulWidget {
  const NewChatSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewChatSheet(),
    );
  }

  @override
  ConsumerState<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends ConsumerState<NewChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _loadingUserId;
  List<SearchUserDto> _searchResultsUsers = [];
  List<SearchGroupDto> _searchResultsGroups = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResultsUsers = [];
        _searchResultsGroups = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final searchRepo = ref.read(searchRepositoryProvider);
      final results = await searchRepo.search(query: query.trim(), limit: 25);

      if (mounted) {
        setState(() {
          _isSearching = true;
          _searchResultsUsers = results.results.users;
          _searchResultsGroups = results.results.groups;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startDirectChat(String userId, String? userName) async {
    setState(() => _loadingUserId = userId);
    try {
      final conv = await ref
          .read(conversationsProvider.notifier)
          .createOrGetDirectConversation(userId);
      if (mounted) {
        Navigator.pop(context);
        context.push('/chats/conversation/${conv.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingUserId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start conversation: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _showJoinByLinkDialog(BuildContext context) async {
    final tokenController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFF161C28)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: Color(0xFF00C6FF)),
            SizedBox(width: 10),
            Text('Join via Link/Token', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste the group invitation link or invite token to join:',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenController,
              decoration: InputDecoration(
                hintText: 'e.g. 8f9a2b4c-... or link',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                filled: true,
                fillColor: Theme.of(ctx).brightness == Brightness.dark
                    ? const Color(0xFF1E2638)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.cancel'))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C6FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              String raw = tokenController.text.trim();
              if (raw.isEmpty) return;
              // If full link passed, extract token
              if (raw.contains('/')) {
                raw = raw.split('/').last;
              }
              Navigator.pop(ctx);
              try {
                final res = await ref
                    .read(chatDiscoveryProvider.notifier)
                    .joinGroupByInvite(raw);
                final groupId = res['groupId'] as String?;
                if (groupId != null && context.mounted) {
                  final conv = await ref
                      .read(chatDiscoveryProvider.notifier)
                      .createOrGetGroupConversation(groupId);
                  if (context.mounted) {
                    context.push('/chats/conversation/${conv.id}');
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not join: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('chat.join_group_btn'))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = ref.watch(authProvider).user?.id;
    final discovery = ref.watch(chatDiscoveryProvider).value;
    final conversations = discovery?.conversations ?? [];

    // Extract recent unique users from existing conversations for quick selection
    final existingUsers = <Map<String, String?>>[];
    for (final conv in conversations) {
      if (conv.type == 'DIRECT') {
        for (final m in conv.members) {
          if (m.userId != currentUserId &&
              !existingUsers.any((u) => u['id'] == m.userId)) {
            existingUsers.add({
              'id': m.userId,
              'username': m.username,
              'displayName': m.displayName ?? m.username,
              'avatarUrl': m.avatarUrl,
            });
          }
        }
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131822) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'New Message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2638) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _performSearch,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search users or groups...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Quick Actions List (Only when not searching)
              if (!_isSearching) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _QuickActionTile(
                        icon: Icons.lock_outline_rounded,
                        color: const Color(0xFF00C6FF),
                        title: 'New Private Group',
                        subtitle: 'Invite-only group with shareable link',
                        onTap: () {
                          Navigator.pop(context);
                          CreateGroupSheet.show(context, isPrivate: true);
                        },
                      ),
                      _QuickActionTile(
                        icon: Icons.public_rounded,
                        color: const Color(0xFF10B981),
                        title: 'New Public Group',
                        subtitle: 'Open community group in discovery',
                        onTap: () {
                          Navigator.pop(context);
                          CreateGroupSheet.show(context, isPrivate: false);
                        },
                      ),
                      _QuickActionTile(
                        icon: Icons.link_rounded,
                        color: const Color(0xFF00F2FE),
                        title: 'Join with Invite Link',
                        subtitle: 'Join private or public group via token',
                        onTap: () {
                          Navigator.pop(context);
                          _showJoinByLinkDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20, thickness: 0.5),
              ],

              // Content Area
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isSearching
                        ? _buildSearchResults(isDark)
                        : _buildSuggestedContacts(existingUsers, isDark, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_searchResultsUsers.isEmpty && _searchResultsGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'No users or groups found',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_searchResultsUsers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Text(
              'USERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey[500],
              ),
            ),
          ),
          ..._searchResultsUsers.map(
            (u) => _UserResultTile(
              id: u.id,
              name: u.displayName ?? u.username ?? 'User',
              username: u.username,
              avatarUrl: u.avatarUrl,
              isLoading: _loadingUserId == u.id,
              onTap: () => _startDirectChat(u.id, u.displayName ?? u.username),
            ),
          ),
        ],
        if (_searchResultsGroups.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Text(
              'GROUPS & CHANNELS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey[500],
              ),
            ),
          ),
          ..._searchResultsGroups.map(
            (g) => ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF0072FF).withValues(alpha: 0.2),
                backgroundImage: g.avatarUrl != null ? NetworkImage(g.avatarUrl!) : null,
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
                g.slug != null ? '@${g.slug}' : 'Group chat',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/groups/${g.id}');
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestedContacts(
    List<Map<String, String?>> existingUsers,
    bool isDark,
    ScrollController scrollController,
  ) {
    if (existingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 54, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Type in search above to find users & groups',
              style: TextStyle(fontSize: 15, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: existingUsers.length,
      itemBuilder: (context, index) {
        final user = existingUsers[index];
        final userId = user['id']!;
        return _UserResultTile(
          id: userId,
          name: user['displayName'] ?? user['username'] ?? 'User',
          username: user['username'],
          avatarUrl: user['avatarUrl'],
          isLoading: _loadingUserId == userId,
          onTap: () => _startDirectChat(userId, user['displayName'] ?? user['username']),
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;
  final bool isLoading;
  final VoidCallback onTap;

  const _UserResultTile({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.2),
            backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00C6FF),
                    ),
                  )
                : null,
          ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: username != null
          ? Text(
              '@$username',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            )
          : null,
      trailing: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: isLoading ? null : onTap,
    );
  }
}


