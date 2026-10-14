// lib/features/library/presentation/watch_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/core/presentation/widgets/video_thumbnail_widget.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/home/presentation/widgets/video_management_sheet.dart';

final watchHistoryProvider = FutureProvider.autoDispose((ref) {
  final repo = ref.watch(videoRepositoryProvider);
  return repo.getWatchHistory(page: 1, limit: 50);
});

/// Card display mode (Grid vs List)
enum HistoryViewMode { grid, list }

/// Filter by date
enum HistoryDateFilter { all, today, thisWeek, thisMonth }

/// Sorting options for watch history
enum HistorySortOrder {
  recentlyWatched,
  oldestWatched,
  mostViewed,
  titleAZ,
  titleZA,
  durationDesc,
  durationAsc,
}

class WatchHistoryScreen extends ConsumerStatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  ConsumerState<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends ConsumerState<WatchHistoryScreen> {
  HistoryViewMode _viewMode = HistoryViewMode.list;
  HistoryDateFilter _dateFilter = HistoryDateFilter.all;
  HistorySortOrder _sortOrder = HistorySortOrder.recentlyWatched;
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
      final saved = prefs.getString('watch_history_view_mode');
      if (saved == 'grid') {
        setState(() => _viewMode = HistoryViewMode.grid);
      } else if (saved == 'list') {
        setState(() => _viewMode = HistoryViewMode.list);
      }
    } catch (_) {}
  }

  Future<void> _saveViewMode(HistoryViewMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'watch_history_view_mode',
        mode == HistoryViewMode.grid ? 'grid' : 'list',
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
      case HistoryDateFilter.all:
        break;
      case HistoryDateFilter.today:
        final startOfToday = DateTime(now.year, now.month, now.day);
        list = list.where((v) {
          final date = v.updatedAt;
          return date.isAfter(startOfToday);
        }).toList();
        break;
      case HistoryDateFilter.thisWeek:
        final weekAgo = now.subtract(const Duration(days: 7));
        list = list.where((v) {
          final date = v.updatedAt;
          return date.isAfter(weekAgo);
        }).toList();
        break;
      case HistoryDateFilter.thisMonth:
        final monthAgo = now.subtract(const Duration(days: 30));
        list = list.where((v) {
          final date = v.updatedAt;
          return date.isAfter(monthAgo);
        }).toList();
        break;
    }

    // 3. Sorting
    switch (_sortOrder) {
      case HistorySortOrder.recentlyWatched:
        // Default API order (most recent first)
        break;
      case HistorySortOrder.oldestWatched:
        list = list.reversed.toList();
        break;
      case HistorySortOrder.mostViewed:
        list.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
        break;
      case HistorySortOrder.durationDesc:
        list.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case HistorySortOrder.durationAsc:
        list.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case HistorySortOrder.titleAZ:
        list.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case HistorySortOrder.titleZA:
        list.sort((a, b) =>
            b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    return list;
  }

  Future<void> _removeVideoFromHistory(
    BuildContext context,
    VideoResponseDto video,
  ) async {
    try {
      await ref.read(videoRepositoryProvider).removeFromWatchHistory(video.id);
      ref.invalidate(watchHistoryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${video.title}" from history'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final historyAsync = ref.watch(watchHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('library.history')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(tr('library.clear_history_title')),
                    content: Text(tr('library.clear_history_msg')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(tr('common.cancel')),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(tr('library.clear_history_btn')),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await ref.read(videoRepositoryProvider).clearWatchHistory();
                    ref.invalidate(watchHistoryProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('library.history_cleared'))),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr('library.history_clear_failed', {
                              'error': e.toString(),
                            }),
                          ),
                        ),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('library.clear_all_history'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(watchHistoryProvider);
        },
        child: historyAsync.when(
          data: (response) {
            if (response.data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('library.no_history'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('library.no_history_desc'),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
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
                                ? '${response.data.length} watched videos'
                                : 'Showing ${filteredVideos.length} of ${response.data.length} videos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty ||
                              _dateFilter != HistoryDateFilter.all ||
                              _sortOrder != HistorySortOrder.recentlyWatched) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _dateFilter = HistoryDateFilter.all;
                                  _sortOrder = HistorySortOrder.recentlyWatched;
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
                            : _viewMode == HistoryViewMode.grid
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
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    tr('library.history_load_failed'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(watchHistoryProvider),
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
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
          // Row 2: Sort dropdown + Date filters + View mode toggle
          Row(
            children: [
              _buildSortDropdown(context, theme),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChips(theme)),
              const SizedBox(width: 8),
              _buildViewModeToggle(theme),
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
        const SizedBox(width: 12),
        _buildViewModeToggle(theme),
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
          hintText: 'Search watch history...',
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
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sort Dropdown ───────────────────────────────────────────────────────────

  Widget _buildSortDropdown(BuildContext context, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showSortMenu(context, theme),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
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
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showSortMenu(BuildContext context, ThemeData theme) async {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<HistorySortOrder>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: HistorySortOrder.values.map((o) {
        final isSelected = o == _sortOrder;
        return PopupMenuItem(
          value: o,
          child: Row(
            children: [
              Icon(
                _sortIcon(o),
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 10),
              Text(
                _sortLabel(o),
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      setState(() => _sortOrder = selected);
    }
  }

  // ─── Filter Chips ────────────────────────────────────────────────────────────

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: HistoryDateFilter.values.map((f) {
          final isSelected = f == _dateFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _dateFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.5)
                        : theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3),
                    width: isSelected ? 1.2 : 0.8,
                  ),
                ),
                child: Text(
                  _dateFilterLabel(f),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
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
            Icons.grid_view_rounded,
            HistoryViewMode.grid,
            'Grid view',
            theme,
          ),
          _toggleBtn(
            Icons.view_list_rounded,
            HistoryViewMode.list,
            'List view',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(
    IconData icon,
    HistoryViewMode mode,
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
              'No matching history videos',
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
                  _dateFilter = HistoryDateFilter.all;
                  _sortOrder = HistorySortOrder.recentlyWatched;
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
        return _HistoryGridCard(
          key: ValueKey(video.id),
          video: video,
          onRemove: () => _removeVideoFromHistory(context, video),
          onTap: () => context.push('/video/${video.id}'),
          onMoreOptions: () {
            VideoManagementSheet.show(
              context,
              video: video,
              onVideoDeleted: () => ref.invalidate(watchHistoryProvider),
              onVideoUpdated: () => ref.invalidate(watchHistoryProvider),
            );
          },
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
        return _HistoryListCard(
          key: ValueKey(video.id),
          video: video,
          onRemove: () => _removeVideoFromHistory(context, video),
          onTap: () => context.push('/video/${video.id}'),
          onMoreOptions: () {
            VideoManagementSheet.show(
              context,
              video: video,
              onVideoDeleted: () => ref.invalidate(watchHistoryProvider),
              onVideoUpdated: () => ref.invalidate(watchHistoryProvider),
            );
          },
        );
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  IconData _sortIcon(HistorySortOrder order) {
    switch (order) {
      case HistorySortOrder.recentlyWatched:
        return Icons.access_time_rounded;
      case HistorySortOrder.oldestWatched:
        return Icons.history_rounded;
      case HistorySortOrder.mostViewed:
        return Icons.trending_up_rounded;
      case HistorySortOrder.durationDesc:
        return Icons.timer_outlined;
      case HistorySortOrder.durationAsc:
        return Icons.timer_3_outlined;
      case HistorySortOrder.titleAZ:
      case HistorySortOrder.titleZA:
        return Icons.sort_by_alpha_rounded;
    }
  }

  String _sortLabel(HistorySortOrder order) {
    switch (order) {
      case HistorySortOrder.recentlyWatched:
        return 'Recently watched';
      case HistorySortOrder.oldestWatched:
        return 'Oldest first';
      case HistorySortOrder.mostViewed:
        return 'Most viewed';
      case HistorySortOrder.durationDesc:
        return 'Duration (Longest)';
      case HistorySortOrder.durationAsc:
        return 'Duration (Shortest)';
      case HistorySortOrder.titleAZ:
        return 'Title (A → Z)';
      case HistorySortOrder.titleZA:
        return 'Title (Z → A)';
    }
  }

  String _dateFilterLabel(HistoryDateFilter filter) {
    switch (filter) {
      case HistoryDateFilter.all:
        return 'All';
      case HistoryDateFilter.today:
        return 'Today';
      case HistoryDateFilter.thisWeek:
        return 'This week';
      case HistoryDateFilter.thisMonth:
        return 'This month';
    }
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

class _HistoryGridCard extends StatefulWidget {
  final VideoResponseDto video;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onMoreOptions;

  const _HistoryGridCard({
    super.key,
    required this.video,
    required this.onTap,
    required this.onRemove,
    required this.onMoreOptions,
  });

  @override
  State<_HistoryGridCard> createState() => _HistoryGridCardState();
}

class _HistoryGridCardState extends State<_HistoryGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = widget.video;
    final authorName = video.channelName ??
        (video.author.displayName?.isNotEmpty == true
            ? video.author.displayName!
            : (video.author.username?.isNotEmpty == true
                ? video.author.username!
                : 'Creator'));

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
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: video.author.avatarUrl != null
                            ? AppNetworkImage.provider(
                                MediaUrlResolver.resolve(
                                    video.author.avatarUrl)!)
                            : null,
                        child: video.author.avatarUrl == null
                            ? Text(
                                authorName.isNotEmpty
                                    ? authorName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(height: 3),
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
                      ),

                      // 3-dots popup menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Options',
                        onSelected: (val) {
                          if (val == 'remove') {
                            widget.onRemove();
                          } else if (val == 'options') {
                            widget.onMoreOptions();
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Remove from history',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'options',
                            child: Row(
                              children: [
                                Icon(Icons.more_horiz_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Video options...',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _HistoryListCard extends StatefulWidget {
  final VideoResponseDto video;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onMoreOptions;

  const _HistoryListCard({
    super.key,
    required this.video,
    required this.onTap,
    required this.onRemove,
    required this.onMoreOptions,
  });

  @override
  State<_HistoryListCard> createState() => _HistoryListCardState();
}

class _HistoryListCardState extends State<_HistoryListCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = widget.video;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double thumbWidth =
        screenWidth < 380 ? 116.0 : (screenWidth < 600 ? 132.0 : 150.0);
    final double thumbHeight = thumbWidth * 9 / 16;
    final authorName = video.channelName ??
        (video.author.displayName?.isNotEmpty == true
            ? video.author.displayName!
            : (video.author.username?.isNotEmpty == true
                ? video.author.username!
                : 'Creator'));

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
                              .withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 3-dots popup menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Options',
                  onSelected: (val) {
                    if (val == 'remove') {
                      widget.onRemove();
                    } else if (val == 'options') {
                      widget.onMoreOptions();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Remove from history',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'options',
                      child: Row(
                        children: [
                          Icon(Icons.more_horiz_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Video options...',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
