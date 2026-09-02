// lib/features/chats/presentation/screens/chat_home_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/chat_search_bar.dart';
import 'package:mobile/features/chats/presentation/widgets/conversation_list_tile.dart';
import 'package:mobile/features/chats/presentation/widgets/new_chat_sheet.dart';
import 'package:mobile/features/profile/presentation/providers/profile_providers.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';
import 'package:mobile/features/stories/presentation/screens/story_viewer_screen.dart';

class ChatHomeScreen extends ConsumerStatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  ConsumerState<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends ConsumerState<ChatHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleItemTap(UnifiedChatItem item) async {
    final notifier = ref.read(chatDiscoveryProvider.notifier);

    if (item.conversationId != null && item.type == UnifiedChatType.conversation) {
      context.push('/chats/conversation/${item.conversationId}');
      return;
    }

    if (item.type == UnifiedChatType.user && item.targetUserId != null) {
      try {
        final conv = await notifier.createOrGetDirectConversation(item.targetUserId!);
        if (mounted) {
          context.push('/chats/conversation/${conv.id}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open chat: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      return;
    }

    if ((item.type == UnifiedChatType.publicGroup ||
            item.type == UnifiedChatType.privateGroup) &&
        item.targetGroupId != null) {
      try {
        final conv = await notifier.createOrGetGroupConversation(item.targetGroupId!);
        if (mounted) {
          context.push('/chats/conversation/${conv.id}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open group: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      return;
    }

    if (item.conversationId != null) {
      context.push('/chats/conversation/${item.conversationId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatItemsAsync = ref.watch(unifiedChatListProvider);
    // chatDiscoveryProvider is watched via notifier below for unread count
    final filter = ref.watch(conversationFilterProvider);
    final unreadCount =
        ref.watch(chatDiscoveryProvider.notifier).getTotalUnreadCount();
    final storyFeedAsync = ref.watch(storyFeedProvider);
    final currentUserId = ref.watch(authProvider).user?.id;
    final profile = ref.watch(profileProvider).profile;
    final authUser = ref.watch(authProvider).user;
    final userName = profile?.displayName ?? authUser?.username ?? 'You';
    final userAvatar = profile?.avatarUrl;

    // Story-only contacts strip: only users who have active stories
    final activeContacts = <Map<String, dynamic>>[];
    storyFeedAsync.whenData((groups) {
      for (final g in groups) {
        if (g.owner.id != currentUserId && g.stories.isNotEmpty) {
          activeContacts.add({
            'id': g.owner.id,
            'name': g.owner.displayName ?? g.owner.username ?? 'User',
            'avatarUrl': g.owner.avatarUrl,
            'hasStory': true,
            'storyGroup': g,
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1621) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF17212B) : Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: GestureDetector(
          onTap: () => _showMyProfileSheet(context, userName, userAvatar, isDark),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    const Color(0xFF00C6FF).withValues(alpha: 0.2),
                backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(userAvatar)
                    : null,
                child: userAvatar == null || userAvatar.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'Y',
                        style: const TextStyle(
                          color: Color(0xFF00C6FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              // Name
              Text(
                userName,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black45,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 24),
            tooltip: 'Search',
            onPressed: () => context.push('/chats/search'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_square, size: 22),
            tooltip: 'New message',
            onPressed: () => NewChatSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00C6FF),
        backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
        onRefresh: () async {
          await ref.read(chatDiscoveryProvider.notifier).refreshDiscovery();
          await ref.read(storyFeedProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Active Contacts & Stories Carousel Strip (Screenshot 1 top bar)
            SliverToBoxAdapter(
              child: _buildActiveContactsStrip(
                activeContacts,
                storyFeedAsync.value ?? [],
                isDark,
              ),
            ),

            // Search Bar Input (Screenshot 1 Search bar)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: ChatSearchBar(
                  controller: _searchController,
                  readOnly: true,
                  onTap: () => context.push('/chats/search'),
                ),
              ),
            ),

            // Category Filter Tabs (Screenshot 1: All, Unread (6), Personal, Groups, Channels)
            SliverToBoxAdapter(
              child: Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: filter == 'all',
                      onTap: () => ref
                          .read(conversationFilterProvider.notifier)
                          .state = 'all',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Unread',
                      badgeCount: unreadCount > 0 ? unreadCount : null,
                      isSelected: filter == 'unread',
                      onTap: () => ref
                          .read(conversationFilterProvider.notifier)
                          .state = 'unread',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Personal',
                      isSelected: filter == 'personal',
                      onTap: () => ref
                          .read(conversationFilterProvider.notifier)
                          .state = 'personal',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Groups',
                      isSelected: filter == 'groups',
                      onTap: () => ref
                          .read(conversationFilterProvider.notifier)
                          .state = 'groups',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Channels',
                      isSelected: filter == 'channels',
                      onTap: () => ref
                          .read(conversationFilterProvider.notifier)
                          .state = 'channels',
                    ),
                  ],
                ),
              ),
            ),

            // Divider
            SliverToBoxAdapter(
              child: Divider(
                height: 10,
                thickness: 0.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),

            // Chat Items List (Sorted newest first)
            chatItemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00C6FF)
                                    .withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: Color(0xFF00C6FF),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              filter == 'all'
                                  ? 'No chats found'
                                  : 'No $filter chats',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start chatting with public groups or users',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () => NewChatSheet.show(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Start New Chat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C6FF),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return UnifiedChatListTile(
                        item: item,
                        onTap: () => _handleItemTap(item),
                        onLongPress: item.conversationId != null
                            ? () => _showConversationOptions(
                                context, item.conversationId!)
                            : null,
                      );
                    },
                    childCount: items.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load chats',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(chatDiscoveryProvider.notifier)
                              .loadDiscovery();
                        },
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
      ),
      // Telegram Floating Action Button (Screenshot 1 blue circle with chat icon)
      floatingActionButton: FloatingActionButton(
        onPressed: () => NewChatSheet.show(context),
        backgroundColor: const Color(0xFF00C6FF),
        foregroundColor: Colors.black,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit_rounded, size: 24),
      ),
    );
  }

  Widget _buildActiveContactsStrip(
    List<Map<String, dynamic>> contacts,
    List storyGroups,
    bool isDark,
  ) {
    return Container(
      height: 98,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 1 + contacts.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            // "New Chat" button
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: () => NewChatSheet.show(context),
                borderRadius: BorderRadius.circular(30),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF1E2638)
                            : Colors.grey[200],
                        border: Border.all(
                          color:
                              const Color(0xFF00C6FF).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF00C6FF),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'New Chat',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          }

          final contact = contacts[index - 1];
          final userId = contact['id'] as String;
          final name = contact['name'] as String? ?? 'User';
          final avatarUrl = contact['avatarUrl'] as String?;
          final hasStory = contact['hasStory'] as bool? ?? false;
          final storyGroup = contact['storyGroup'];

          // Colored circular rings (like Screenshot 1: Emu, Addisu, Mamee, Haym, Hana)
          final ringColors = [
            const Color(0xFF00C6FF),
            const Color(0xFF10B981),
            const Color(0xFFFF5252),
            const Color(0xFFFFB300),
            const Color(0xFF7C4DFF),
            const Color(0xFF00E5FF),
          ];
          final ringColor = ringColors[name.hashCode.abs() % ringColors.length];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              onTap: () async {
                if (hasStory &&
                    storyGroup != null &&
                    storyGroups.isNotEmpty) {
                  final groupIdx = storyGroups.indexOf(storyGroup);
                  context.push(
                    '/story-viewer',
                    extra: StoryViewerArgs(
                      groups: storyGroups.cast(),
                      initialGroupIndex: groupIdx >= 0 ? groupIdx : 0,
                    ),
                  );
                } else {
                  final conv = await ref
                      .read(chatDiscoveryProvider.notifier)
                      .createOrGetDirectConversation(userId);
                  if (context.mounted) {
                    context.push('/chats/conversation/${conv.id}');
                  }
                }
              },
              borderRadius: BorderRadius.circular(30),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ringColor,
                        width: 2.2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: CircleAvatar(
                      backgroundColor:
                          ringColor.withValues(alpha: 0.2),
                      backgroundImage: avatarUrl != null
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                color: ringColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 60,
                    child: Text(
                      name.split(' ').first,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showConversationOptions(BuildContext context, String conversationId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF161C28)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined,
                  color: Color(0xFF00C6FF)),
              title: const Text('Pin Conversation'),
              onTap: () {
                ref
                    .read(chatDiscoveryProvider.notifier)
                    .pinConversation(conversationId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off_outlined,
                  color: Colors.orangeAccent),
              title: const Text('Mute Notifications'),
              onTap: () {
                ref
                    .read(chatDiscoveryProvider.notifier)
                    .muteConversation(conversationId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_read_outlined,
                  color: Color(0xFF10B981)),
              title: const Text('Mark as Read'),
              onTap: () {
                ref
                    .read(chatDiscoveryProvider.notifier)
                    .markAsRead(conversationId);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMyProfileSheet(
    BuildContext context,
    String name,
    String? avatarUrl,
    bool isDark,
  ) {
    final auth = ref.read(authProvider);
    final username = auth.user?.username ?? '';
    final bgColor = isDark ? const Color(0xFF17212B) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Avatar + name header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor:
                          const Color(0xFF00C6FF).withValues(alpha: 0.15),
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'Y',
                              style: const TextStyle(
                                color: Color(0xFF00C6FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (username.isNotEmpty)
                            Text(
                              '@$username',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Actions
              ListTile(
                leading: const Icon(Icons.person_outline_rounded,
                    color: Color(0xFF00C6FF)),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_stories_outlined,
                    color: Color(0xFF10B981)),
                title: const Text('My Stories'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/story/create');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined,
                    color: Colors.orangeAccent),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/settings');
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF00C6FF) : const Color(0xFF0072FF))
              : (isDark ? const Color(0xFF17212B) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.black
                    : (isDark ? Colors.grey[300] : Colors.grey[800]),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : const Color(0xFF00C6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount! > 99 ? '99+' : '$badgeCount',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
