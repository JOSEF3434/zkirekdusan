import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/library/presentation/widgets/web_download_card.dart';

// ─── Label helpers ────────────────────────────────────────────────────────────

String _sortLabel(DownloadSortOrder o) => switch (o) {
      DownloadSortOrder.newestFirst => 'Newest first',
      DownloadSortOrder.oldestFirst => 'Oldest first',
      DownloadSortOrder.titleAZ => 'Title A → Z',
      DownloadSortOrder.titleZA => 'Title Z → A',
      DownloadSortOrder.sizeDesc => 'Largest first',
      DownloadSortOrder.sizeAsc => 'Smallest first',
    };

IconData _sortIcon(DownloadSortOrder o) => switch (o) {
      DownloadSortOrder.newestFirst => Icons.arrow_downward_rounded,
      DownloadSortOrder.oldestFirst => Icons.arrow_upward_rounded,
      DownloadSortOrder.titleAZ => Icons.sort_by_alpha_rounded,
      DownloadSortOrder.titleZA => Icons.sort_by_alpha_rounded,
      DownloadSortOrder.sizeDesc => Icons.data_usage_rounded,
      DownloadSortOrder.sizeAsc => Icons.data_usage_rounded,
    };

String _storageModeLabel(DownloadStorageMode m) => switch (m) {
      DownloadStorageMode.inAppOnly => 'In-app only',
      DownloadStorageMode.saveToFile => 'Save to file',
      DownloadStorageMode.both => 'Both (in-app + file)',
    };

String _storageModeDesc(DownloadStorageMode m) => switch (m) {
      DownloadStorageMode.inAppOnly =>
        'Videos are cached inside the app for offline playback. No file is saved to your device.',
      DownloadStorageMode.saveToFile =>
        'Triggers a browser download. The video is saved to your device downloads folder.',
      DownloadStorageMode.both =>
        'Video is cached in-app AND saved to your device downloads folder.',
    };

// ─── Sorting logic ────────────────────────────────────────────────────────────

List<String> _sorted(
  Map<String, DownloadMetadata> downloads,
  Set<String> active,
  DownloadSortOrder order,
) {
  final completed = downloads.entries
      .where((e) => !active.contains(e.key))
      .toList();

  switch (order) {
    case DownloadSortOrder.newestFirst:
      completed.sort((a, b) {
        final da = a.value.downloadedAt ?? DateTime(0);
        final db = b.value.downloadedAt ?? DateTime(0);
        return db.compareTo(da);
      });
    case DownloadSortOrder.oldestFirst:
      completed.sort((a, b) {
        final da = a.value.downloadedAt ?? DateTime(0);
        final db = b.value.downloadedAt ?? DateTime(0);
        return da.compareTo(db);
      });
    case DownloadSortOrder.titleAZ:
      completed.sort((a, b) => a.value.title.compareTo(b.value.title));
    case DownloadSortOrder.titleZA:
      completed.sort((a, b) => b.value.title.compareTo(a.value.title));
    case DownloadSortOrder.sizeDesc:
      completed.sort((a, b) => b.value.sizeBytes.compareTo(a.value.sizeBytes));
    case DownloadSortOrder.sizeAsc:
      completed.sort((a, b) => a.value.sizeBytes.compareTo(b.value.sizeBytes));
  }

  return completed.map((e) => e.key).toList();
}

// ─── Main View ────────────────────────────────────────────────────────────────

class WebDownloadsView extends ConsumerWidget {
  const WebDownloadsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final downloadState = ref.watch(downloadServiceProvider);
    final settings = ref.watch(downloadSettingsProvider);
    final theme = Theme.of(context);

    // Build active ID set
    final activeIds = <String>{
      ...downloadState.downloading,
      ...downloadState.queued,
      ...downloadState.paused,
      ...downloadState.errors.keys
          .where((id) => !downloadState.downloads.containsKey(id)),
    };

    // Sorted completed IDs
    final sortedCompleted = _sorted(
      downloadState.downloads,
      activeIds,
      settings.sortOrder,
    );

    // Active on top, then sorted completed
    final allIds = [...activeIds, ...sortedCompleted];

    final totalCount = downloadState.downloads.length;
    final inProgressCount =
        downloadState.downloading.length + downloadState.queued.length;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          final horizontalPadding = isNarrow ? 16.0 : 32.0;

          return Padding(
            padding:
                EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Header ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('offline.your_downloads'),
                            style:
                                theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalCount == 1
                                ? '1 downloaded video'
                                : '$totalCount downloaded videos'
                                    '${inProgressCount > 0 ? ' • $inProgressCount in progress' : ''}',
                            style:
                                theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Settings button ──────────────────────────────
                    IconButton(
                      tooltip: 'Download settings',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () =>
                          _showSettingsSheet(context, ref, tr),
                    ),

                    if (downloadState.downloads.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_sweep_outlined,
                            size: 18),
                        label: Text(tr('downloads.clear_all')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              theme.colorScheme.error,
                          side: BorderSide(
                            color: theme.colorScheme.error
                                .withValues(alpha: 0.4),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        onPressed: () =>
                            _confirmClearAll(context, ref, tr),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // ── Sort + View-mode toolbar ─────────────────────────
                if (allIds.isNotEmpty || inProgressCount > 0)
                  _SortBar(
                    settings: settings,
                    ref: ref,
                    isNarrow: isNarrow,
                  ),

                const SizedBox(height: 10),

                // ── Web info banner ──────────────────────────────────
                _WebInfoBanner(settings: settings, theme: theme),
                const SizedBox(height: 14),

                // ── Grid / List of cards or empty state ─────────────
                Expanded(
                  child: allIds.isEmpty
                      ? _buildEmptyState(context, tr, theme)
                      : settings.viewMode == DownloadViewMode.grid
                          ? _buildGrid(
                              allIds,
                              downloadState,
                              isNarrow,
                              constraints.maxWidth,
                            )
                          : _buildList(allIds, downloadState),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Grid layout ────────────────────────────────────────────────────────────

  Widget _buildGrid(
    List<String> ids,
    DownloadState state,
    bool isNarrow,
    double maxWidth,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 40),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isNarrow ? maxWidth : 380,
        mainAxisExtent: isNarrow ? 320 : 315,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final videoId = ids[index];
        final metadata =
            state.downloads[videoId] ?? state.activeTasks[videoId];
        return WebDownloadCard(
          key: ValueKey(videoId),
          videoId: videoId,
          metadata: metadata,
        );
      },
    );
  }

  // ── List layout ────────────────────────────────────────────────────────────

  Widget _buildList(List<String> ids, DownloadState state) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 40),
      itemCount: ids.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final videoId = ids[index];
        final metadata =
            state.downloads[videoId] ?? state.activeTasks[videoId];
        return WebDownloadCard(
          key: ValueKey(videoId),
          videoId: videoId,
          metadata: metadata,
          isListView: true,
        );
      },
    );
  }


  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(
    BuildContext context,
    String Function(String) tr,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.download_for_offline_outlined,
                size: 52,
                color:
                    theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr('downloads.empty'),
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                tr('downloads.empty_web_hint'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: Text(tr('explore.title')),
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Settings bottom sheet ──────────────────────────────────────────────────

  void _showSettingsSheet(
    BuildContext context,
    WidgetRef ref,
    String Function(String) tr,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DownloadSettingsSheet(tr: tr),
    );
  }

  // ── Clear all dialog ───────────────────────────────────────────────────────

  void _confirmClearAll(
    BuildContext context,
    WidgetRef ref,
    String Function(String) tr,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('downloads.clear_all')),
        content: Text(tr('downloads.clear_all_confirm')),
        actions: [
          TextButton(
            child: Text(tr('common.cancel')),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(tr('downloads.delete')),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(downloadServiceProvider.notifier)
                  .deleteAllDownloads();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Sort toolbar ─────────────────────────────────────────────────────────────

class _SortBar extends ConsumerWidget {
  final DownloadSettings settings;
  final WidgetRef ref;
  final bool isNarrow;

  const _SortBar({
    required this.settings,
    required this.ref,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Sort dropdown
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showSortMenu(context, ref, theme),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_sortIcon(settings.sortOrder),
                    size: 16,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  _sortLabel(settings.sortOrder),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const Spacer(),

        // Grid / List toggle
        _ViewModeToggle(settings: settings),
      ],
    );
  }

  void _showSortMenu(
      BuildContext context, WidgetRef ref, ThemeData theme) async {
    final RenderBox button =
        context.findRenderObject()! as RenderBox;
    final RenderBox overlay = Overlay.of(context)
        .context
        .findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<DownloadSortOrder>(
      context: context,
      position: position,
      items: DownloadSortOrder.values
          .map(
            (o) => PopupMenuItem(
              value: o,
              child: Row(
                children: [
                  Icon(
                    _sortIcon(o),
                    size: 16,
                    color: o == settings.sortOrder
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _sortLabel(o),
                    style: TextStyle(
                      fontWeight: o == settings.sortOrder
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: o == settings.sortOrder
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                  if (o == settings.sortOrder) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded,
                        size: 16,
                        color: theme.colorScheme.primary),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );

    if (selected != null) {
      ref
          .read(downloadSettingsProvider.notifier)
          .setSortOrder(selected);
    }
  }
}

// ─── View mode toggle ─────────────────────────────────────────────────────────

class _ViewModeToggle extends ConsumerWidget {
  final DownloadSettings settings;
  const _ViewModeToggle({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(
            context,
            ref,
            Icons.grid_view_rounded,
            DownloadViewMode.grid,
            'Grid view',
            theme,
          ),
          _toggleBtn(
            context,
            ref,
            Icons.view_list_rounded,
            DownloadViewMode.list,
            'List view',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    DownloadViewMode mode,
    String tooltip,
    ThemeData theme,
  ) {
    final isActive = settings.viewMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () =>
            ref.read(downloadSettingsProvider.notifier).setViewMode(mode),
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
}

// ─── Web info banner (adaptive to storage mode) ───────────────────────────────

class _WebInfoBanner extends StatelessWidget {
  final DownloadSettings settings;
  final ThemeData theme;

  const _WebInfoBanner({required this.settings, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isInApp =
        settings.storageMode == DownloadStorageMode.inAppOnly;
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isInApp
                ? Icons.cloud_done_outlined
                : Icons.save_alt_rounded,
            size: 18,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _storageModeDesc(settings.storageMode),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings bottom sheet ────────────────────────────────────────────────────

class _DownloadSettingsSheet extends ConsumerWidget {
  final String Function(String) tr;

  const _DownloadSettingsSheet({required this.tr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(downloadSettingsProvider);
    final notifier = ref.read(downloadSettingsProvider.notifier);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.settings_rounded,
                      color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download Settings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage how videos are stored & displayed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
              color: theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.4),
              height: 1),

          // ── Storage Mode section ────────────────────────────────────
          _SectionHeader(title: 'Storage Mode', theme: theme),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: DownloadStorageMode.values.map((mode) {
                final isSelected = settings.storageMode == mode;
                return _StorageModeCard(
                  mode: mode,
                  isSelected: isSelected,
                  theme: theme,
                  onTap: () => notifier.setStorageMode(mode),
                );
              }).toList(),
            ),
          ),

          // ── Sort Order section ──────────────────────────────────────
          _SectionHeader(title: 'Sort Order', theme: theme),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DownloadSortOrder.values.map((order) {
                final isSelected = settings.sortOrder == order;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_sortIcon(order),
                          size: 14,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface),
                      const SizedBox(width: 5),
                      Text(_sortLabel(order)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => notifier.setSortOrder(order),
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : null,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Display section ─────────────────────────────────────────
          _SectionHeader(title: 'Display', theme: theme),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _DisplayModeButton(
                    icon: Icons.grid_view_rounded,
                    label: 'Grid',
                    isSelected:
                        settings.viewMode == DownloadViewMode.grid,
                    theme: theme,
                    onTap: () => notifier
                        .setViewMode(DownloadViewMode.grid),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DisplayModeButton(
                    icon: Icons.view_list_rounded,
                    label: 'List',
                    isSelected:
                        settings.viewMode == DownloadViewMode.list,
                    theme: theme,
                    onTap: () => notifier
                        .setViewMode(DownloadViewMode.list),
                  ),
                ),
              ],
            ),
          ),

          // ── Max concurrent ──────────────────────────────────────────
          _SectionHeader(title: 'Simultaneous Downloads', theme: theme),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Text(
                  '${settings.maxConcurrent}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: settings.maxConcurrent.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '${settings.maxConcurrent}',
                    onChanged: (v) =>
                        notifier.setMaxConcurrent(v.round()),
                  ),
                ),
                Text(
                  '5',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ),

          // Bottom safe area padding
          SizedBox(
              height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}

// ─── Sheet sub-widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _StorageModeCard extends StatelessWidget {
  final DownloadStorageMode mode;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _StorageModeCard({
    required this.mode,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  IconData get _icon => switch (mode) {
        DownloadStorageMode.inAppOnly => Icons.cloud_done_outlined,
        DownloadStorageMode.saveToFile => Icons.save_alt_rounded,
        DownloadStorageMode.both => Icons.layers_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
                  .withValues(alpha: 0.6)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                    .withValues(alpha: 0.7)
                : theme.colorScheme.outlineVariant
                    .withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                        .withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _storageModeLabel(mode),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _storageModeDesc(mode),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _DisplayModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DisplayModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.6)
                : theme.colorScheme.outlineVariant
                    .withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
