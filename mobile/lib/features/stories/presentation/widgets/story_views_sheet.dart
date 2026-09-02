// lib/features/stories/presentation/widgets/story_views_sheet.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:mobile/features/stories/data/models/story_reaction_model.dart';
import 'package:mobile/features/stories/data/models/story_view_model.dart';

class _MergedEntry {
  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime timestamp;
  final bool isLiker;
  final String? reactionEmoji;

  const _MergedEntry({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.timestamp,
    required this.isLiker,
    this.reactionEmoji,
  });
}

class StoryViewsSheet extends ConsumerStatefulWidget {
  final String storyId;

  const StoryViewsSheet({super.key, required this.storyId});

  static Future<void> show(BuildContext context, String storyId) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StoryViewsSheet(storyId: storyId),
    );
  }

  @override
  ConsumerState<StoryViewsSheet> createState() => _StoryViewsSheetState();
}

class _StoryViewsSheetState extends ConsumerState<StoryViewsSheet>
    with SingleTickerProviderStateMixin {
  late Future<List<_MergedEntry>> _mergedFuture;
  late TabController _tabController;

  static const _tabAll = 0;
  static const _tabLikers = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mergedFuture = _fetchMerged();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<_MergedEntry>> _fetchMerged() async {
    final ds = ref.read(storiesRemoteDatasourceProvider);
    final results = await Future.wait([
      ds.getViewers(widget.storyId),
      ds.getReactions(widget.storyId),
    ]);

    final viewers = results[0] as List<StoryViewModel>;
    final reactions = results[1] as List<StoryReactionModel>;

    // Build a map of userId -> reaction for quick lookup
    final reactionsMap = {
      for (final r in reactions) r.userId: r,
    };

    // Merged entries: start with likers (users who reacted)
    final entries = <_MergedEntry>[];

    // Collect all unique user IDs
    final seenIds = <String>{};

    // 1. Add likers first
    for (final r in reactions) {
      seenIds.add(r.userId);
      entries.add(
        _MergedEntry(
          userId: r.userId,
          name: r.user.effectiveName,
          avatarUrl: MediaUrlResolver.resolve(r.user.avatarUrl),
          timestamp: r.createdAt,
          isLiker: true,
          reactionEmoji: _getEmoji(r.reaction),
        ),
      );
    }

    // 2. Add viewers who haven't liked
    for (final v in viewers) {
      if (!seenIds.contains(v.viewerId)) {
        seenIds.add(v.viewerId);
        entries.add(
          _MergedEntry(
            userId: v.viewerId,
            name: v.viewer.effectiveName,
            avatarUrl: MediaUrlResolver.resolve(v.viewer.avatarUrl),
            timestamp: v.viewedAt,
            isLiker: false,
            reactionEmoji: null,
          ),
        );
      } else {
        // If the viewer also liked, update timestamp to the earlier one (view time)
        // Already added as liker — no duplicate needed
      }
    }

    // Sort: likers first, then by timestamp DESC within each group
    entries.sort((a, b) {
      if (a.isLiker && !b.isLiker) return -1;
      if (!a.isLiker && b.isLiker) return 1;
      return b.timestamp.compareTo(a.timestamp);
    });

    return entries;
  }

  String _getEmoji(String reaction) {
    switch (reaction.toUpperCase()) {
      case 'LOVE':
        return '😍';
      case 'HAHA':
        return '😂';
      case 'WOW':
        return '😮';
      case 'SAD':
        return '😢';
      case 'ANGRY':
        return '🔥';
      case 'LIKE':
      default:
        return '❤️';
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      return DateFormat('h:mm a').format(dt);
    }
    return DateFormat('MMM d \'at\' h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1F2E) : theme.colorScheme.surface;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.72,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              children: [
                Text(
                  'Viewers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF00C6FF) : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: isDark ? Colors.black : Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Likers ❤️'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Content
          Expanded(
            child: FutureBuilder<List<_MergedEntry>>(
              future: _mergedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: isDark ? const Color(0xFF00C6FF) : theme.colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load viewers',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  );
                }

                final all = snapshot.data ?? [];
                final likers = all.where((e) => e.isLiker).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(all, isDark, theme),
                    _buildList(likers, isDark, theme, emptyMsg: 'No likes yet'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<_MergedEntry> entries,
    bool isDark,
    ThemeData theme, {
    String emptyMsg = 'No views yet',
  }) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: 44,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              emptyMsg,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildEntryTile(entry, isDark, theme);
      },
    );
  }

  Widget _buildEntryTile(_MergedEntry entry, bool isDark, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
                ? Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          if (entry.isLiker)
            Positioned(
              bottom: -2,
              right: -4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1F2E) : theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.reactionEmoji ?? '❤️',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        entry.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          const Icon(Icons.done_all_rounded, size: 13, color: Colors.blueAccent),
          const SizedBox(width: 4),
          Text(
            _formatTimestamp(entry.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: entry.isLiker
          ? Icon(
              Icons.favorite_rounded,
              color: Colors.redAccent,
              size: 20,
            )
          : null,
    );
  }
}
