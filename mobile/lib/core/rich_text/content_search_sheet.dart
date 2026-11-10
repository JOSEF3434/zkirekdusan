// lib/core/rich_text/content_search_sheet.dart
//
// Global Content Search sheet triggered by `#` in any RichTextComposer.
// Directly backed by `SearchRepository` (`/api/search`), supporting:
//   • All entity categories (Videos, Books & Dictionaries, People, Groups,
//     Channels, Posts, Live Streams, Reels)
//   • Category filter chips matching the top-left Global Search screen
//   • Recent searches history + paginated load-more
//   • Error state with retry + clean dark/light & Amharic/English UX

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/core/rich_text/providers/content_search_provider.dart';
import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:mobile/features/explore/presentation/providers/search_provider.dart';

/// Shows the global content search picker and returns the selected [ContentSearchItem],
/// or `null` if dismissed.
Future<ContentSearchItem?> showContentSearchSheet(
  BuildContext context, {
  String initialQuery = '',
}) {
  return showModalBottomSheet<ContentSearchItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 620),
    builder: (_) => _ContentSearchSheet(initialQuery: initialQuery),
  );
}

class _ContentSearchSheet extends ConsumerStatefulWidget {
  final String initialQuery;
  const _ContentSearchSheet({this.initialQuery = ''});

  @override
  ConsumerState<_ContentSearchSheet> createState() =>
      _ContentSearchSheetState();
}

class _ContentSearchSheetState extends ConsumerState<_ContentSearchSheet> {
  late final TextEditingController _searchCtrl;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery);
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    if (widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(contentSearchProvider.notifier)
            .search(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.offset >= _scrollCtrl.position.maxScrollExtent - 160) {
      ref.read(contentSearchProvider.notifier).loadNextPage();
    }
  }

  void _selectQuery(String q) {
    _searchCtrl.text = q;
    _searchCtrl.selection = TextSelection.collapsed(offset: q.length);
    setState(() {});
    ref.read(contentSearchProvider.notifier).search(q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(contentSearchProvider);
    final recentAsync = ref.watch(recentSearchesProvider);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131822) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.tag_rounded,
                  color: Color(0xFF00C6FF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Insert Reference (Global Search)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Search input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search videos, books, channels, groups, users…',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2638) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF00C6FF),
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                          ref.read(contentSearchProvider.notifier).clear();
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
              onChanged: (q) {
                setState(() {});
                ref.read(contentSearchProvider.notifier).search(q);
              },
            ),
          ),
          // Category Filter Chips
          _buildFilterChips(state, isDark, theme),
          const Divider(height: 1),
          // Results list / states
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.52,
            ),
            child: _buildBody(state, recentAsync, isDark),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    ContentSearchState state,
    bool isDark,
    ThemeData theme,
  ) {
    final chips = <(SearchEntityType?, String)>[
      (null, 'All'),
      (SearchEntityType.videos, 'Videos'),
      (SearchEntityType.books, 'Books'),
      (SearchEntityType.channels, 'Channels'),
      (SearchEntityType.groups, 'Groups'),
      (SearchEntityType.users, 'People'),
      (SearchEntityType.posts, 'Posts'),
      (SearchEntityType.streams, 'Live'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final selected = state.selectedType == chip.$1;
          return ChoiceChip(
            label: Text(
              chip.$2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? Colors.black87
                    : (isDark ? Colors.grey[300] : Colors.black87),
              ),
            ),
            selected: selected,
            showCheckmark: false,
            selectedColor: const Color(0xFF00C6FF),
            backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.grey[200],
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
            onSelected: (_) =>
                ref.read(contentSearchProvider.notifier).setType(chip.$1),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    ContentSearchState state,
    AsyncValue<List<String>> recentAsync,
    bool isDark,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(36),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
          ),
        ),
      );
    }

    if (state.query.trim().isEmpty) {
      return recentAsync.when(
        loading: () => _buildEmptyHint(),
        error: (_, _) => _buildEmptyHint(),
        data: (recents) {
          if (recents.isEmpty) return _buildEmptyHint();
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: Text(
                  'Recent searches',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              ...recents.take(6).map(
                (q) => ListTile(
                  dense: true,
                  leading: Icon(Icons.history_rounded,
                      size: 18, color: Colors.grey[500]),
                  title: Text(q, style: const TextStyle(fontSize: 14)),
                  onTap: () => _selectQuery(q),
                ),
              ),
            ],
          );
        },
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 36, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(
              state.error!,
              style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.read(contentSearchProvider.notifier).retry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey[500]),
            const SizedBox(height: 10),
            Text(
              'No results for "${state.query.trim()}"',
              style: TextStyle(color: Colors.grey[500], fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.isLoading)
          const LinearProgressIndicator(
            minHeight: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
          ),
        Flexible(
          child: ListView.builder(
            controller: _scrollCtrl,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return _ContentItemTile(
                item: state.items[i],
                isDark: isDark,
                onTap: () => Navigator.pop(ctx, state.items[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHint() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            'Search across Zikre Kedusan for videos, books, dictionaries, channels, groups, posts, or people.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ContentItemTile extends StatelessWidget {
  final ContentSearchItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _ContentItemTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  IconData get _icon => switch (item.entityType) {
    'video' => Icons.play_circle_outline_rounded,
    'book' => Icons.menu_book_rounded,
    'channel' => Icons.tv_rounded,
    'group' => Icons.group_rounded,
    'post' => Icons.article_outlined,
    'stream' => Icons.live_tv_rounded,
    'user' => Icons.person_rounded,
    'reel' => Icons.movie_creation_outlined,
    _ => Icons.link_rounded,
  };

  Color get _iconColor => switch (item.entityType) {
    'video' => const Color(0xFF10B981),
    'book' => const Color(0xFFFFB300),
    'channel' => const Color(0xFF00C6FF),
    'group' => const Color(0xFF8B5CF6),
    'post' => const Color(0xFFEC4899),
    'stream' => const Color(0xFFEF4444),
    'reel' => const Color(0xFFF97316),
    _ => const Color(0xFF00C6FF),
  };

  @override
  Widget build(BuildContext context) {
    final badgeText = item.badgeLabel ?? item.entityType;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                item.entityType == 'user' ? 22 : 8,
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _iconBox(),
                      )
                    : _iconBox(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: Color(0xFF00C6FF),
                        ),
                      ],
                    ],
                  ),
                  if (item.subtitle != null && item.subtitle!.isNotEmpty)
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: item.isLive
                    ? Colors.red
                    : _iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: item.isLive ? Colors.white : _iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox() => Container(
    color: _iconColor.withValues(alpha: 0.15),
    alignment: Alignment.center,
    child: Icon(_icon, color: _iconColor, size: 22),
  );
}
