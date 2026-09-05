// lib/features/chats/presentation/screens/large_screen_chat_layout.dart
//
// Telegram-style four-panel layout for tablet/desktop (≥ 600px wide).
//
//  ┌─────────────────────────────────────────────────────────────────────┐
//  │  Chat List (resizable)  │  Conversation (flex)  │  Info (resizable) │
//  └─────────────────────────────────────────────────────────────────────┘
//
// The chat list is always visible. Selecting a conversation renders it
// inline in the center panel (no navigation). The info/details panel is
// OPEN BY DEFAULT and toggled via the ℹ button. All panels are resizable
// via drag handles. The stories strip is collapsed into a compact avatar
// cluster next to the search bar (Telegram Desktop Screenshot 1) and
// expands into a full strip (Screenshot 2) with "Your Story" first.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/screens/inline_conversation_view.dart';
import 'package:mobile/features/chats/presentation/widgets/chat_details_panel.dart';
import 'package:mobile/features/chats/presentation/widgets/conversation_list_tile.dart';
import 'package:mobile/features/chats/presentation/widgets/new_chat_sheet.dart';
import 'package:mobile/features/profile/presentation/providers/profile_providers.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';
import 'package:mobile/features/stories/presentation/screens/story_viewer_screen.dart';

/// Default widths (user can drag to resize).
const double _kListPanelMinWidth = 220.0;
const double _kListPanelMaxWidth = 480.0;
const double _kDetailsPanelMinWidth = 260.0;
const double _kDetailsPanelMaxWidth = 460.0;
const double _kListPanelDefaultWidth = 320.0;
const double _kDetailsPanelDefaultWidth = 320.0;

class LargeScreenChatLayout extends ConsumerStatefulWidget {
  const LargeScreenChatLayout({super.key});

  @override
  ConsumerState<LargeScreenChatLayout> createState() =>
      _LargeScreenChatLayoutState();
}

class _LargeScreenChatLayoutState
    extends ConsumerState<LargeScreenChatLayout> {
  /// Currently selected conversation id (null → show placeholder).
  String? _selectedConversationId;

  /// Whether the right info/details panel is open.
  /// Defaults to TRUE – open by default like Telegram Desktop.
  bool _isDetailsPanelOpen = true;

  /// Resizable panel widths.
  double _listPanelWidth = _kListPanelDefaultWidth;
  double _detailsPanelWidth = _kDetailsPanelDefaultWidth;

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Handle list-item tap ────────────────────────────────────────────────────
  Future<void> _handleItemTap(UnifiedChatItem item) async {
    final notifier = ref.read(chatDiscoveryProvider.notifier);

    String? convId;

    if (item.conversationId != null &&
        item.type == UnifiedChatType.conversation) {
      convId = item.conversationId;
    } else if (item.type == UnifiedChatType.user &&
        item.targetUserId != null) {
      try {
        final conv = await notifier
            .createOrGetDirectConversation(item.targetUserId!);
        convId = conv.id;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open chat: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    } else if ((item.type == UnifiedChatType.publicGroup ||
            item.type == UnifiedChatType.privateGroup) &&
        item.targetGroupId != null) {
      try {
        final conv = await notifier
            .createOrGetGroupConversation(item.targetGroupId!);
        convId = conv.id;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open group: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    } else if (item.conversationId != null) {
      convId = item.conversationId;
    }

    if (convId != null && mounted) {
      setState(() {
        _selectedConversationId = convId;
        // Open details panel when selecting a new conversation (default open)
        _isDetailsPanelOpen = true;
      });
    }
  }

  void _toggleDetailsPanel() {
    setState(() => _isDetailsPanelOpen = !_isDetailsPanelOpen);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listBg = isDark ? const Color(0xFF0E1621) : Colors.white;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final dragHandleColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0E14) : const Color(0xFFF0F2F5),
      body: Row(
        children: [
          // ── LEFT: Chat list panel (resizable) ────────────────────────────
          SizedBox(
            width: _listPanelWidth,
            child: _ChatListPanel(
              isDark: isDark,
              listBg: listBg,
              dividerColor: dividerColor,
              selectedConversationId: _selectedConversationId,
              onItemTap: _handleItemTap,
              searchController: _searchController,
            ),
          ),

          // ── Drag handle between list and center ───────────────────────────
          _ResizeDivider(
            color: dragHandleColor,
            onDelta: (dx) {
              setState(() {
                _listPanelWidth = (_listPanelWidth + dx)
                    .clamp(_kListPanelMinWidth, _kListPanelMaxWidth);
              });
            },
          ),

          // ── CENTER: Conversation panel ────────────────────────────────────
          Expanded(
            child: _selectedConversationId == null
                ? _PlaceholderPanel(isDark: isDark)
                : InlineConversationView(
                    key: ValueKey(_selectedConversationId),
                    conversationId: _selectedConversationId!,
                    onToggleDetails: _toggleDetailsPanel,
                    isDetailsPanelOpen: _isDetailsPanelOpen,
                  ),
          ),

          // ── RIGHT: Details panel (animated, resizable) ────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _isDetailsPanelOpen && _selectedConversationId != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle on the left edge of details panel
                      _ResizeDivider(
                        color: dragHandleColor,
                        onDelta: (dx) {
                          setState(() {
                            // Dragging right shrinks the panel, left grows it
                            _detailsPanelWidth = (_detailsPanelWidth - dx)
                                .clamp(_kDetailsPanelMinWidth,
                                    _kDetailsPanelMaxWidth);
                          });
                        },
                      ),
                      SizedBox(
                        width: _detailsPanelWidth,
                        child: ChatDetailsPanel(
                          conversationId: _selectedConversationId!,
                          onClose: () =>
                              setState(() => _isDetailsPanelOpen = false),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Left panel: the full chat list with appbar, stories strip, filter chips
// ──────────────────────────────────────────────────────────────────────────────

class _ChatListPanel extends ConsumerStatefulWidget {
  final bool isDark;
  final Color listBg;
  final Color dividerColor;
  final String? selectedConversationId;
  final Future<void> Function(UnifiedChatItem) onItemTap;
  final TextEditingController searchController;

  const _ChatListPanel({
    required this.isDark,
    required this.listBg,
    required this.dividerColor,
    required this.selectedConversationId,
    required this.onItemTap,
    required this.searchController,
  });

  @override
  ConsumerState<_ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends ConsumerState<_ChatListPanel> {
  /// Whether the stories strip is expanded (true) or collapsed into cluster (false)
  bool _isStoriesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final chatItemsAsync = ref.watch(unifiedChatListProvider);
    final filter = ref.watch(conversationFilterProvider);
    final unreadCount =
        ref.watch(chatDiscoveryProvider.notifier).getTotalUnreadCount();
    final storyFeedAsync = ref.watch(storyFeedProvider);
    final allGroups = storyFeedAsync.value ?? <StoryFeedGroupModel>[];
    final currentUserId = ref.watch(authProvider).user?.id;
    final profile = ref.watch(profileProvider).profile;
    final authUser = ref.watch(authProvider).user;
    final userName = profile?.displayName ?? authUser?.username ?? 'You';
    final userAvatar = profile?.avatarUrl;
    final isAuthenticated = authUser != null;

    // Separate my group from others
    StoryFeedGroupModel? myGroup;
    final otherGroups = <StoryFeedGroupModel>[];
    for (final g in allGroups) {
      if (g.owner.id == currentUserId) {
        myGroup = g;
      } else if (g.stories.isNotEmpty) {
        otherGroups.add(g);
      }
    }
    final bool hasMyStories =
        myGroup != null && myGroup.stories.isNotEmpty;
    final bool hasAnyStories = hasMyStories || otherGroups.isNotEmpty;

    return Scaffold(
      backgroundColor: widget.listBg,
      // ── Panel AppBar ───────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF17212B) : Colors.white,
        elevation: 0,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () =>
              _showMyProfileSheet(context, userName, userAvatar, isDark),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    const Color(0xFF00C6FF).withValues(alpha: 0.2),
                backgroundImage: userAvatar != null &&
                        userAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(userAvatar)
                    : null,
                child: userAvatar == null || userAvatar.isEmpty
                    ? Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : 'Y',
                        style: const TextStyle(
                          color: Color(0xFF00C6FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 18,
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
            icon: const Icon(Icons.search_rounded, size: 23),
            tooltip: 'Global Search',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_square, size: 21),
            tooltip: 'New message',
            onPressed: () => NewChatSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
              height: 0.5, color: widget.dividerColor),
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
              parent: BouncingScrollPhysics()),
          slivers: [
            // ── Search bar with compact story cluster (Screenshot 1) ─────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: _buildSearchBarRow(
                  isDark: isDark,
                  hasAnyStories: hasAnyStories,
                  otherGroups: otherGroups,
                  allGroups: allGroups,
                ),
              ),
            ),
            // ── Expanded stories strip (Screenshot 2) ───────────────────────
            if (_isStoriesExpanded)
              SliverToBoxAdapter(
                child: _buildExpandedStoriesStrip(
                  isDark: isDark,
                  myGroup: myGroup,
                  hasMyStories: hasMyStories,
                  userName: userName,
                  userAvatar: userAvatar,
                  isAuthenticated: isAuthenticated,
                  otherGroups: otherGroups,
                  allGroups: allGroups,
                ),
              ),
            // ── Subtle divider ───────────────────────────────────────────────
            if (_isStoriesExpanded)
              SliverToBoxAdapter(
                child: Divider(
                    height: 1, thickness: 0.5, color: widget.dividerColor),
              ),
            // Filter chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
            SliverToBoxAdapter(
              child: SizedBox(height: 6),
            ),
            SliverToBoxAdapter(
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: widget.dividerColor,
              ),
            ),
            // Chat list
            chatItemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00C6FF)
                                  .withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 36,
                              color: Color(0xFF00C6FF),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            filter == 'all'
                                ? 'No chats found'
                                : 'No $filter chats',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                NewChatSheet.show(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Start New Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF00C6FF),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      final item = items[index];
                      final isSelected =
                          item.conversationId != null &&
                              item.conversationId ==
                                  widget.selectedConversationId;
                      return _SelectableListTileWrapper(
                        isSelected: isSelected,
                        isDark: isDark,
                        child: UnifiedChatListTile(
                          item: item,
                          onTap: () => widget.onItemTap(item),
                          onLongPress: item.conversationId != null
                              ? () => _showConversationOptions(
                                  context,
                                  item.conversationId!)
                              : null,
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00C6FF)),
                  ),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load chats',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(chatDiscoveryProvider.notifier)
                            .loadDiscovery(),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C6FF),
                            foregroundColor: Colors.black),
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
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => NewChatSheet.show(context),
        backgroundColor: const Color(0xFF00C6FF),
        foregroundColor: Colors.black,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit_rounded, size: 20),
      ),
    );
  }

  // ── Search bar row with compact story cluster (Telegram Screenshot 1) ───────
  Widget _buildSearchBarRow({
    required bool isDark,
    required bool hasAnyStories,
    required List<StoryFeedGroupModel> otherGroups,
    required List<StoryFeedGroupModel> allGroups,
  }) {

    final hintColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final fillColor = isDark ? const Color(0xFF1A2433) : Colors.grey[100];

    return Row(
      children: [
        // Search field (flexible)
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/chats/search'),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search_rounded, size: 18, color: hintColor),
                  const SizedBox(width: 6),
                  Text(
                    'Search',
                    style: TextStyle(
                        color: hintColor,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Compact overlapping story avatars (right of search) ─────────────
        if (hasAnyStories && (otherGroups.isNotEmpty || allGroups.isNotEmpty)) ...
          [
            const SizedBox(width: 8),
            _CompactStoryCluster(
              groups: otherGroups.isNotEmpty ? otherGroups : allGroups,
              allGroups: allGroups,
              isExpanded: _isStoriesExpanded,
              isDark: isDark,
              onToggle: () =>
                  setState(() => _isStoriesExpanded = !_isStoriesExpanded),
              onGroupTap: (group) {
                final idx = allGroups.indexOf(group);
                context.push(
                  '/story-viewer',
                  extra: StoryViewerArgs(
                    groups: allGroups,
                    initialGroupIndex: idx >= 0 ? idx : 0,
                  ),
                );
              },
            ),
          ],
      ],
    );
  }

  // ── Expanded stories strip (Screenshot 2) ────────────────────────────────────
  Widget _buildExpandedStoriesStrip({
    required bool isDark,
    required StoryFeedGroupModel? myGroup,
    required bool hasMyStories,
    required String userName,
    required String? userAvatar,
    required bool isAuthenticated,
    required List<StoryFeedGroupModel> otherGroups,
    required List<StoryFeedGroupModel> allGroups,
  }) {
    final ringColors = [
      const Color(0xFF00C6FF),
      const Color(0xFF10B981),
      const Color(0xFFFF5252),
      const Color(0xFFFFB300),
      const Color(0xFF7C4DFF),
    ];

    return Container(
      height: 94,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 1 + otherGroups.length,
        itemBuilder: (ctx, index) {
          // ── First item: "Your Story" ─────────────────────────────────────
          if (index == 0) {
            return _MyStoryStripItem(
              isDark: isDark,
              hasStories: hasMyStories,
              userName: userName,
              avatarUrl: userAvatar,
              myGroup: myGroup,
              allGroups: allGroups,
              isAuthenticated: isAuthenticated,
            );
          }

          // ── Other contacts' stories ─────────────────────────────────────
          final g = otherGroups[index - 1];
          final name = g.owner.displayName ?? g.owner.username ?? 'User';
          final avatarUrl = g.owner.avatarUrl;
          final resolvedUrl = MediaUrlResolver.resolve(avatarUrl);
          final ringColor = ringColors[name.hashCode.abs() % ringColors.length];
          final groupIdxInAll = allGroups.indexOf(g);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: InkWell(
              onTap: () {
                context.push(
                  '/story-viewer',
                  extra: StoryViewerArgs(
                    groups: allGroups,
                    initialGroupIndex:
                        groupIdxInAll >= 0 ? groupIdxInAll : 0,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: g.hasUnseen
                          ? LinearGradient(
                              colors: [ringColor, ringColor.withValues(alpha: 0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      border: g.hasUnseen
                          ? null
                          : Border.all(
                              color: Colors.grey.withValues(alpha: 0.4),
                              width: 2),
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF0E1621)
                            : Colors.white,
                      ),
                      padding: const EdgeInsets.all(1.5),
                      child: ClipOval(
                        child: resolvedUrl != null && resolvedUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: resolvedUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, error, _) => _buildInitialAvatar(name, ringColor),
                              )
                            : _buildInitialAvatar(name, ringColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 56,
                    child: Text(
                      name.split(' ').first,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                        fontWeight: g.hasUnseen
                            ? FontWeight.w600
                            : FontWeight.normal,
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

  Widget _buildInitialAvatar(String name, Color color) {
    return Container(
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  void _showConversationOptions(
      BuildContext context, String conversationId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF161C28)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
                Navigator.pop(ctx);
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
                Navigator.pop(ctx);
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
                Navigator.pop(ctx);
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
    final bgColor =
        isDark ? const Color(0xFF17212B) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF00C6FF)
                          .withValues(alpha: 0.15),
                      backgroundImage: avatarUrl != null &&
                              avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'Y',
                              style: const TextStyle(
                                color: Color(0xFF00C6FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          if (username.isNotEmpty)
                            Text(
                              '@$username',
                              style: TextStyle(
                                fontSize: 13,
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

// ──────────────────────────────────────────────────────────────────────────────
// Center placeholder (shown when no conversation is selected)
// ──────────────────────────────────────────────────────────────────────────────

class _PlaceholderPanel extends StatelessWidget {
  final bool isDark;

  const _PlaceholderPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? const Color(0xFF0B0E14)
          : const Color(0xFFF0F2F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00C6FF).withValues(alpha: 0.15),
                    const Color(0xFF0072FF).withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 46,
                color: const Color(0xFF00C6FF).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select a chat to start messaging',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.4),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose from your conversations on the left',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Resize divider: a thin draggable handle between panels
// ──────────────────────────────────────────────────────────────────────────────

class _ResizeDivider extends StatelessWidget {
  final Color color;
  final ValueChanged<double> onDelta;

  const _ResizeDivider({required this.color, required this.onDelta});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) => onDelta(d.delta.dx),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: 5,
          color: color,
          child: Center(
            child: Container(
              width: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Compact overlapping story avatars shown to the right of the search bar
// (Telegram Desktop Screenshot 1: collapsed state)
// ──────────────────────────────────────────────────────────────────────────────

class _CompactStoryCluster extends StatelessWidget {
  final List<StoryFeedGroupModel> groups;
  final List<StoryFeedGroupModel> allGroups;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggle;
  final ValueChanged<StoryFeedGroupModel> onGroupTap;

  const _CompactStoryCluster({
    required this.groups,
    required this.allGroups,
    required this.isExpanded,
    required this.isDark,
    required this.onToggle,
    required this.onGroupTap,
  });

  static const _ringColors = [
    Color(0xFF00C6FF),
    Color(0xFF10B981),
    Color(0xFFFFB300),
  ];

  @override
  Widget build(BuildContext context) {
    final displayGroups = groups.isNotEmpty ? groups : allGroups;
    if (displayGroups.isEmpty) {
      return const SizedBox.shrink();
    }
    final displayCount = displayGroups.length.clamp(1, 3);
    // Width = first avatar (26px) + (n-1) * 14px overlap
    final totalAvatarWidth = 26.0 + (displayCount - 1) * 14.0;

    return Tooltip(
      message: isExpanded ? 'Collapse stories' : 'View stories',
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: totalAvatarWidth,
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int i = 0; i < displayCount; i++)
                      Positioned(
                        left: i * 14.0,
                        child: _buildAvatar(displayGroups[i], _ringColors[i % _ringColors.length]),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isExpanded
                    ? const Color(0xFF00C6FF)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(StoryFeedGroupModel group, Color ring) {
    final avatarUrl = MediaUrlResolver.resolve(group.owner.avatarUrl);
    final name = group.owner.displayName ?? group.owner.username ?? 'U';

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
        color: isDark ? const Color(0xFF0E1621) : Colors.white,
      ),
      padding: const EdgeInsets.all(1),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                errorWidget: (context, error, _) => _initial(name, ring),
              )
            : _initial(name, ring),
      ),
    );
  }

  Widget _initial(String name, Color color) => Container(
        color: color.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 10),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// "Your Story" first item in the expanded strip
// - Has stories → shows avatar with gradient ring (tap to view)
// - No stories  → shows profile avatar + green "+" badge (tap to post)
// ──────────────────────────────────────────────────────────────────────────────

class _MyStoryStripItem extends ConsumerWidget {
  final bool isDark;
  final bool hasStories;
  final String userName;
  final String? avatarUrl;
  final StoryFeedGroupModel? myGroup;
  final List<StoryFeedGroupModel> allGroups;
  final bool isAuthenticated;

  const _MyStoryStripItem({
    required this.isDark,
    required this.hasStories,
    required this.userName,
    required this.avatarUrl,
    required this.myGroup,
    required this.allGroups,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedAvatar = MediaUrlResolver.resolve(avatarUrl);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: InkWell(
        onTap: () {
          if (hasStories && myGroup != null) {
            final idx = allGroups.indexOf(myGroup!);
            context.push(
              '/story-viewer',
              extra: StoryViewerArgs(
                groups: allGroups,
                initialGroupIndex: idx >= 0 ? idx : 0,
              ),
            );
          } else {
            if (isAuthenticated) {
              context.push('/story/create');
            } else {
              context.push('/login');
            }
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Avatar with story ring or plain border
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStories
                        ? const LinearGradient(
                            colors: [Color(0xFF00C6FF), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasStories
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF0E1621)
                          : Colors.white,
                    ),
                    padding: const EdgeInsets.all(1.5),
                    child: ClipOval(
                      child: resolvedAvatar != null &&
                              resolvedAvatar.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: resolvedAvatar,
                              fit: BoxFit.cover,
                              errorWidget: (context, error, _) => _buildInitials(),
                            )
                          : _buildInitials(),
                    ),
                  ),
                ),
                // "+" badge when no active stories
                if (!hasStories)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        if (isAuthenticated) {
                          context.push('/story/create');
                        } else {
                          context.push('/login');
                        }
                      },
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF0E1621)
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                            Icons.add, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(
                'Your Story',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  fontWeight: hasStories
                      ? FontWeight.w600
                      : FontWeight.normal,
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
  }

  Widget _buildInitials() {
    return Container(
      color: const Color(0xFF00C6FF).withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : 'Y',
        style: const TextStyle(
          color: Color(0xFF00C6FF),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Selected conversation highlight wrapper
// ──────────────────────────────────────────────────────────────────────────────

class _SelectableListTileWrapper extends StatelessWidget {
  final bool isSelected;
  final bool isDark;
  final Widget child;

  const _SelectableListTileWrapper({
    required this.isSelected,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSelected) return child;
    return Container(
      color: isDark
          ? const Color(0xFF2B5278).withValues(alpha: 0.4)
          : const Color(0xFF00C6FF).withValues(alpha: 0.08),
      child: child,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Filter chip (same design as ChatHomeScreen)
// ──────────────────────────────────────────────────────────────────────────────

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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF00C6FF)
                  : const Color(0xFF0072FF))
              : (isDark
                  ? const Color(0xFF17212B)
                  : Colors.grey[100]),
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
                    : (isDark
                        ? Colors.grey[300]
                        : Colors.grey[800]),
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black
                      : const Color(0xFF00C6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount! > 99 ? '99+' : '$badgeCount',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 9,
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
