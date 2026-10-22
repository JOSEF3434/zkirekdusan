// lib/features/library/presentation/liked_videos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/widgets/video_thumbnail_widget.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/home/presentation/widgets/video_management_sheet.dart';
import 'package:mobile/features/social/presentation/providers/likes_provider.dart';
import 'package:mobile/features/social/presentation/widgets/share_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

enum LikedViewMode { list, grid }

enum LikedSortOrder {
  recentlyLiked,
  oldestLiked,
  mostViewed,
  durationDesc,
  durationAsc,
  titleAZ,
  titleZA,
}

enum LikedDateFilter {
  all,
  today,
  thisWeek,
  thisMonth,
}

final likedVideosProvider = FutureProvider<VideoListResponseDto>((ref) async {
  final repo = ref.watch(videoRepositoryProvider);
  return repo.getLikedVideos(page: 1, limit: 50);
});

class LikedVideosScreen extends ConsumerStatefulWidget {
  const LikedVideosScreen({super.key});

  @override
  ConsumerState<LikedVideosScreen> createState() => _LikedVideosScreenState();
}

class _LikedVideosScreenState extends ConsumerState<LikedVideosScreen> {
  LikedViewMode _viewMode = LikedViewMode.list;
  LikedSortOrder _sortOrder = LikedSortOrder.recentlyLiked;
  LikedDateFilter _dateFilter = LikedDateFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadViewMode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('liked_videos_view_mode');
      if (saved == 'grid') {
        setState(() => _viewMode = LikedViewMode.grid);
      } else if (saved == 'list') {
        setState(() => _viewMode = LikedViewMode.list);
      }
    } catch (_) {}
  }

  Future<void> _saveViewMode(LikedViewMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'liked_videos_view_mode',
        mode == LikedViewMode.grid ? 'grid' : 'list',
      );
    } catch (_) {}
  }

  List<VideoResponseDto> _filterAndSort(List<VideoResponseDto> source) {
    var list = List<VideoResponseDto>.from(source);

    // 1. Text Search Filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((v) {
        final titleMatch = v.title.toLowerCase().contains(q);
        final authorMatch = (v.channelName ??
                v.author.displayName ??
                v.author.username ??
                '')
            .toLowerCase()
            .contains(q);
        return titleMatch || authorMatch;
      }).toList();
    }

    // 2. Date Filter
    final now = DateTime.now();
    switch (_dateFilter) {
      case LikedDateFilter.all:
        break;
      case LikedDateFilter.today:
        final startOfToday = DateTime(now.year, now.month, now.day);
        list = list.where((v) {
          final date = v.publishedAt ?? v.createdAt;
          return date.isAfter(startOfToday);
        }).toList();
        break;
      case LikedDateFilter.thisWeek:
        final weekAgo = now.subtract(const Duration(days: 7));
        list = list.where((v) {
          final date = v.publishedAt ?? v.createdAt;
          return date.isAfter(weekAgo);
        }).toList();
        break;
      case LikedDateFilter.thisMonth:
        final monthAgo = now.subtract(const Duration(days: 30));
        list = list.where((v) {
          final date = v.publishedAt ?? v.createdAt;
          return date.isAfter(monthAgo);
        }).toList();
        break;
    }

    // 3. Sorting
    switch (_sortOrder) {
      case LikedSortOrder.recentlyLiked:
        // Default API order (most recent first)
        break;
      case LikedSortOrder.oldestLiked:
        list = list.reversed.toList();
        break;
      case LikedSortOrder.mostViewed:
        list.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
        break;
      case LikedSortOrder.durationDesc:
        list.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case LikedSortOrder.durationAsc:
        list.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case LikedSortOrder.titleAZ:
        list.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case LikedSortOrder.titleZA:
        list.sort((a, b) =>
            b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final likedAsync = ref.watch(likedVideosProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('library.liked')),
        actions: [
          Center(
            child: _buildViewModeToggle(theme),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(likedVideosProvider);
        },
        child: likedAsync.when(
          data: (response) {
            if (response.data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('library.no_liked'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('library.no_liked_desc'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final filteredVideos = _filterAndSort(response.data);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final horizontalPadding = constraints.maxWidth > 1200
                    ? 32.0
                    : constraints.maxWidth > 800
                        ? 24.0
                        : 16.0;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // ── Search & Filter Toolbar ──────────────────────────────
                      _buildToolbar(context, theme, isNarrow),

                      const SizedBox(height: 10),

                      // ── Video Count & Status ─────────────────────────────────
                      Row(
                        children: [
                          Text(
                            filteredVideos.length == response.data.length
                                ? '${response.data.length} liked videos'
                                : 'Showing ${filteredVideos.length} of ${response.data.length} videos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty ||
                              _dateFilter != LikedDateFilter.all ||
                              _sortOrder != LikedSortOrder.recentlyLiked) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _dateFilter = LikedDateFilter.all;
                                  _sortOrder = LikedSortOrder.recentlyLiked;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.close_rounded,
                                      size: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Reset',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ── Main Content Area (Grid or List or Empty) ─────────────
                      Expanded(
                        child: filteredVideos.isEmpty
                            ? _buildEmptyFilteredState(theme)
                            : _viewMode == LikedViewMode.grid
                                ? _buildGrid(
                                    filteredVideos,
                                    isNarrow,
                                    constraints.maxWidth,
                                  )
                                : _buildList(filteredVideos),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text('${tr('state.error')}\n$err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(likedVideosProvider),
                  child: Text(tr('common.retry')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Toolbar Widget ──────────────────────────────────────────────────────────

  Widget _buildToolbar(BuildContext context, ThemeData theme, bool isNarrow) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search bar
          _buildSearchField(theme),
          const SizedBox(height: 8),
          // Row 2: Sort dropdown + Date filters
          Row(
            children: [
              _buildSortDropdown(context, theme),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChips(theme)),
            ],
          ),
        ],
      );
    }

    // Wide layout: single row
    return Row(
      children: [
        _buildSortDropdown(context, theme),
        const SizedBox(width: 10),
        _buildFilterChips(theme),
        const SizedBox(width: 12),
        Expanded(child: _buildSearchField(theme)),
      ],
    );
  }

  // ─── Search Field ────────────────────────────────────────────────────────────

  Widget _buildSearchField(ThemeData theme) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search liked videos...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  splashRadius: 14,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          isDense: true,
          filled: true,
          fillColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sort Dropdown ───────────────────────────────────────────────────────────

  Widget _buildSortDropdown(BuildContext context, ThemeData theme) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _sortIcon(_sortOrder),
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _sortLabel(_sortOrder),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: LikedSortOrder.values.map((order) {
        final isSelected = _sortOrder == order;
        return MenuItemButton(
          leadingIcon: Icon(
            _sortIcon(order),
            size: 18,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => setState(() => _sortOrder = order),
          child: Text(
            _sortLabel(order),
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Date Filter Chips ───────────────────────────────────────────────────────

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: LikedDateFilter.values.map((filter) {
          final isSelected = _dateFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(_dateFilterLabel(filter)),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              onSelected: (val) {
                if (val) setState(() => _dateFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── View Mode Toggle (Grid / List) ──────────────────────────────────────────

  Widget _buildViewModeToggle(ThemeData theme) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(
            Icons.view_list_rounded,
            LikedViewMode.list,
            'List view',
            theme,
          ),
          _toggleBtn(
            Icons.grid_view_rounded,
            LikedViewMode.grid,
            'Grid view',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(
    IconData icon,
    LikedViewMode mode,
    String tooltip,
    ThemeData theme,
  ) {
    final isActive = _viewMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () {
          setState(() => _viewMode = mode);
          _saveViewMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ─── Empty Filtered State ────────────────────────────────────────────────────

  Widget _buildEmptyFilteredState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 14),
            Text(
              'No matching liked videos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term or reset your filters.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset filters'),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _dateFilter = LikedDateFilter.all;
                  _sortOrder = LikedSortOrder.recentlyLiked;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Grid View Layout ────────────────────────────────────────────────────────

  Widget _buildGrid(
    List<VideoResponseDto> videos,
    bool isNarrow,
    double maxWidth,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 40),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isNarrow ? maxWidth : 360,
        mainAxisExtent: isNarrow ? 295 : 285,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _LikedGridCard(
          key: ValueKey(video.id),
          video: video,
          onTap: () => context.push('/video/${video.id}'),
          onMoreOptions: () => _showOptionsSheet(context, ref, video),
        );
      },
    );
  }

  // ─── List View Layout ────────────────────────────────────────────────────────

  Widget _buildList(List<VideoResponseDto> videos) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 6, bottom: 40),
      itemCount: videos.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final video = videos[index];
        return _LikedListCard(
          key: ValueKey(video.id),
          video: video,
          onTap: () => context.push('/video/${video.id}'),
          onMoreOptions: () => _showOptionsSheet(context, ref, video),
        );
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  IconData _sortIcon(LikedSortOrder order) {
    switch (order) {
      case LikedSortOrder.recentlyLiked:
        return Icons.history_rounded;
      case LikedSortOrder.oldestLiked:
        return Icons.update_disabled_rounded;
      case LikedSortOrder.mostViewed:
        return Icons.visibility_outlined;
      case LikedSortOrder.durationDesc:
        return Icons.timer_outlined;
      case LikedSortOrder.durationAsc:
        return Icons.timer_3_outlined;
      case LikedSortOrder.titleAZ:
      case LikedSortOrder.titleZA:
        return Icons.sort_by_alpha_rounded;
    }
  }

  String _sortLabel(LikedSortOrder order) {
    switch (order) {
      case LikedSortOrder.recentlyLiked:
        return 'Recently liked';
      case LikedSortOrder.oldestLiked:
        return 'Oldest first';
      case LikedSortOrder.mostViewed:
        return 'Most viewed';
      case LikedSortOrder.durationDesc:
        return 'Duration (Longest)';
      case LikedSortOrder.durationAsc:
        return 'Duration (Shortest)';
      case LikedSortOrder.titleAZ:
        return 'Title (A → Z)';
      case LikedSortOrder.titleZA:
        return 'Title (Z → A)';
    }
  }

  String _dateFilterLabel(LikedDateFilter filter) {
    switch (filter) {
      case LikedDateFilter.all:
        return 'All';
      case LikedDateFilter.today:
        return 'Today';
      case LikedDateFilter.thisWeek:
        return 'This week';
      case LikedDateFilter.thisMonth:
        return 'This month';
    }
  }

  void _showOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    VideoResponseDto video,
  ) {
    final tr = ref.read(trProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: Text(tr('library.play_video')),
              onTap: () {
                Navigator.pop(bContext);
                context.push('/video/${video.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.thumb_down_outlined),
              title: Text(tr('library.remove_from_liked')),
              onTap: () async {
                Navigator.pop(bContext);
                await ref
                    .read(likesProvider.notifier)
                    .toggleLike(video.id, isVideo: true);
                ref.invalidate(likedVideosProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from Liked Videos'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(tr('library.share')),
              onTap: () {
                Navigator.pop(bContext);
                ShareButton(postId: video.id, title: video.title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.more_horiz_rounded),
              title: const Text('More options'),
              onTap: () {
                Navigator.pop(bContext);
                VideoManagementSheet.show(
                  context,
                  video: video,
                  onVideoDeleted: () => ref.invalidate(likedVideosProvider),
                  onVideoUpdated: () => ref.invalidate(likedVideosProvider),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Formatters ─────────────────────────────────────────────────────────

String _formatDuration(int seconds) {
  if (seconds <= 0) return '0:00';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  final h = m ~/ 60;
  if (h > 0) {
    final remM = m % 60;
    return '$h:${remM.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

String _formatViews(int views) {
  if (views >= 1000000) {
    return '${(views / 1000000).toStringAsFixed(1)}M views';
  }
  if (views >= 1000) {
    return '${(views / 1000).toStringAsFixed(1)}K views';
  }
  return '$views views';
}

// ─── Grid Card Component ──────────────────────────────────────────────────────

class _LikedGridCard extends StatefulWidget {
  final VideoResponseDto video;
  final VoidCallback onTap;
  final VoidCallback onMoreOptions;

  const _LikedGridCard({
    super.key,
    required this.video,
    required this.onTap,
    required this.onMoreOptions,
  });

  @override
  State<_LikedGridCard> createState() => _LikedGridCardState();
}

class _LikedGridCardState extends State<_LikedGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = widget.video;
    final authorName = video.channelName ??
        video.author.displayName ??
        video.author.username ??
        'Channel';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
              : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.35)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onMoreOptions,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 16:9 Thumbnail
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(11)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoThumbnailWidget(
                        thumbnailUrl: video.thumbnailUrl,
                        videoUrl: video.sourceFileUrl ?? video.hlsUrl,
                        hlsUrl: video.hlsUrl,
                        renditionUrls:
                            video.renditions.map((r) => r.url).toList(),
                        borderRadius: BorderRadius.zero,
                      ),
                      if (video.duration > 0)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatDuration(video.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Metadata row
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                height: 1.25,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatViews(video.viewsCount)} • ${timeago.format(video.publishedAt ?? video.createdAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.75),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        splashRadius: 16,
                        onPressed: widget.onMoreOptions,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── List Card Component ──────────────────────────────────────────────────────

class _LikedListCard extends StatefulWidget {
  final VideoResponseDto video;
  final VoidCallback onTap;
  final VoidCallback onMoreOptions;

  const _LikedListCard({
    super.key,
    required this.video,
    required this.onTap,
    required this.onMoreOptions,
  });

  @override
  State<_LikedListCard> createState() => _LikedListCardState();
}

class _LikedListCardState extends State<_LikedListCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = widget.video;
    final authorName = video.channelName ??
        video.author.displayName ??
        video.author.username ??
        'Channel';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        final thumbWidth = isNarrow ? 120.0 : 150.0;
        final thumbHeight = thumbWidth * (9 / 16);

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: _isHovered
                  ? theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.55)
                  : theme.colorScheme.surfaceContainerLow
                      .withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.35)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onMoreOptions,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 16:9 Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: thumbWidth,
                        height: thumbHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            VideoThumbnailWidget(
                              thumbnailUrl: video.thumbnailUrl,
                              videoUrl: video.sourceFileUrl ?? video.hlsUrl,
                              hlsUrl: video.hlsUrl,
                              renditionUrls:
                                  video.renditions.map((r) => r.url).toList(),
                              borderRadius: BorderRadius.zero,
                            ),
                            if (video.duration > 0)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    _formatDuration(video.duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Details (middle)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatViews(video.viewsCount)} • ${timeago.format(video.publishedAt ?? video.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action menu (right)
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      splashRadius: 18,
                      onPressed: widget.onMoreOptions,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
