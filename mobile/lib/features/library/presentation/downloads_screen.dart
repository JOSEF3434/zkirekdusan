// lib/features/library/presentation/downloads_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/media_experience/presentation/widgets/download_status_tile.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final downloadState = ref.watch(downloadServiceProvider);
    final theme = Theme.of(context);

    // Combine downloading + completed + errored items
    final allIds = <String>{
      ...downloadState.downloads.keys,
      ...downloadState.downloading,
      ...downloadState.errors.keys,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('library.downloads')),
        actions: [
          if (downloadState.downloads.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: Text(tr('downloads.clear_all')),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () => _confirmClearAll(context, ref, tr),
            ),
        ],
      ),
      body: Column(
        children: [
          // Web info banner
          if (kIsWeb)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('downloads.web_info'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: allIds.isEmpty
                ? _buildEmptyState(context, tr, theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: allIds.length,
                    itemBuilder: (context, index) {
                      final videoId = allIds[index];
                      final metadata = downloadState.downloads[videoId];
                      return DownloadStatusTile(
                        videoId: videoId,
                        metadata: metadata,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String Function(String) tr,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_for_offline_outlined,
            size: 72,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            tr('downloads.empty'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              kIsWeb
                  ? tr('downloads.empty_web_hint')
                  : tr('downloads.empty_hint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
