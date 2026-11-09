// lib/core/rich_text/content_search_sheet.dart
//
// Bottom sheet for # content search. Opens when user types # in a composer.
// Shows a search field and mixed content results (videos, books, groups, etc.).
// User taps an item → token inserted into the composer text field.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/core/rich_text/providers/content_search_provider.dart';

/// Shows the content search sheet and returns the selected [ContentSearchItem],
/// or `null` if the user dismissed without selecting.
Future<ContentSearchItem?> showContentSearchSheet(
  BuildContext context, {
  String initialQuery = '',
}) {
  return showModalBottomSheet<ContentSearchItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery);
    // Run initial search if query was pre-filled
    if (widget.initialQuery.isNotEmpty) {
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
    ref.read(contentSearchProvider.notifier).clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(contentSearchProvider);
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
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: Color(0xFF00C6FF), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Search Content',
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
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search videos, books, channels, groups…',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  fontSize: 14,
                ),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF1E2638) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: Color(0xFF00C6FF)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(contentSearchProvider.notifier).clear();
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
              onChanged: (q) =>
                  ref.read(contentSearchProvider.notifier).search(q),
            ),
          ),
          // Results
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: _buildResults(state, isDark),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResults(ContentSearchState state, bool isDark) {
    if (state.isLoading && state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
          ),
        ),
      );
    }

    if (state.query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded,
                size: 40, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              'Type to search videos, books,\nchannels, groups and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          state.error!,
          style: const TextStyle(color: Colors.redAccent),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No results for "${state.query}"',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: state.items.length,
      itemBuilder: (ctx, i) => _ContentItemTile(
        item: state.items[i],
        isDark: isDark,
        onTap: () => Navigator.pop(ctx, state.items[i]),
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
        'channel' => Icons.subscriptions_rounded,
        'group' => Icons.group_rounded,
        'post' => Icons.article_outlined,
        'stream' => Icons.live_tv_rounded,
        'user' => Icons.person_rounded,
        _ => Icons.link_rounded,
      };

  Color get _iconColor => switch (item.entityType) {
        'video' => const Color(0xFF10B981),
        'book' => const Color(0xFFFFB300),
        'channel' => const Color(0xFF00C6FF),
        'group' => const Color(0xFF8B5CF6),
        'post' => const Color(0xFFEC4899),
        'stream' => const Color(0xFFEF4444),
        _ => const Color(0xFF00C6FF),
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Thumbnail or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            // Type badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.entityType,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _iconColor,
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
