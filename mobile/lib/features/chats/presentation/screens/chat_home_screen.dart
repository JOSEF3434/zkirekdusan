// lib/features/chats/presentation/screens/chat_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/conversation_list_tile.dart';
import 'package:mobile/features/chats/presentation/widgets/chat_search_bar.dart';
import 'package:mobile/features/stories/presentation/widgets/story_section.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';

class ChatHomeScreen extends ConsumerStatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  ConsumerState<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends ConsumerState<ChatHomeScreen> {
  final _searchController = TextEditingController();
  // bool _isSearchActive = false; // Removed unused field

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(filteredConversationsProvider);
    final filter = ref.watch(conversationFilterProvider);
    final unreadCount = ref.watch(conversationsProvider.notifier).getTotalUnreadCount();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call_outlined),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () {
              // TODO: Implement new chat
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(conversationsProvider.notifier).refreshConversations();
          await ref.read(storyFeedProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Stories Section
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: const StorySection(),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: ChatSearchBar(
                  controller: _searchController,
                  onTap: () {
                    // setState(() => _isSearchActive = true);
                    context.push('/chats/search');
                  },
                ),
              ),
            ),

            // Filter Tabs
            SliverToBoxAdapter(
              child: Container(
                height: 48,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: filter == 'all',
                      onTap: () => ref.read(conversationFilterProvider.notifier).state = 'all',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Unread',
                      badgeCount: unreadCount > 0 ? unreadCount : null,
                      isSelected: filter == 'unread',
                      onTap: () => ref.read(conversationFilterProvider.notifier).state = 'unread',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Personal',
                      isSelected: filter == 'personal',
                      onTap: () => ref.read(conversationFilterProvider.notifier).state = 'personal',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Groups',
                      isSelected: filter == 'groups',
                      onTap: () => ref.read(conversationFilterProvider.notifier).state = 'groups',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Channels',
                      isSelected: filter == 'channels',
                      onTap: () => ref.read(conversationFilterProvider.notifier).state = 'channels',
                    ),
                  ],
                ),
              ),
            ),

            // Conversations List
            conversations.when(
              data: (convList) {
                if (convList.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            filter == 'all' 
                                ? 'No conversations yet'
                                : 'No $filter conversations',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a new chat to get connected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final conversation = convList[index];
                      return ConversationListTile(
                        conversation: conversation,
                        onTap: () {
                          context.push('/chats/conversation/${conversation.id}');
                        },
                        onLongPress: () {
                          _showConversationOptions(context, conversation.id);
                        },
                      );
                    },
                    childCount: convList.length,
                  ),
                );
              },
              loading: () => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading conversations...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load conversations',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(conversationsProvider.notifier).loadConversations();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConversationOptions(BuildContext context, String conversationId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: const Text('Pin Conversation'),
              onTap: () {
                ref.read(conversationsProvider.notifier).pinConversation(conversationId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off_outlined),
              title: const Text('Mute'),
              onTap: () {
                ref.read(conversationsProvider.notifier).muteConversation(conversationId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_read_outlined),
              title: const Text('Mark as Read'),
              onTap: () {
                ref.read(conversationsProvider.notifier).markAsRead(conversationId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Conversation', style: TextStyle(color: Colors.red)),
              onTap: () {
                // TODO: Implement delete
                Navigator.pop(context);
              },
            ),
          ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : isDark
                  ? Colors.grey[850]
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.grey[300]
                        : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount! > 99 ? '99+' : '$badgeCount',
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : Colors.white,
                    fontSize: 11,
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
