// lib/features/calendar/presentation/widgets/sync_status_indicator.dart
// Sync status indicator widget for calendar screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_sync_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class SyncStatusIndicator extends ConsumerWidget {
  final bool showDetails;

  const SyncStatusIndicator({super.key, this.showDetails = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncInProgress = ref.watch(syncInProgressProvider);
    final lastSyncTime = ref.watch(lastSyncTimeProvider);
    final pendingSyncCountAsync = ref.watch(pendingSyncCountStreamProvider);

    if (showDetails) {
      return _buildDetailedStatus(
        context,
        ref,
        syncInProgress,
        lastSyncTime,
        pendingSyncCountAsync,
      );
    } else {
      return _buildCompactStatus(
        context,
        syncInProgress,
        pendingSyncCountAsync,
      );
    }
  }

  Widget _buildCompactStatus(
    BuildContext context,
    bool syncInProgress,
    AsyncValue<int> pendingSyncCountAsync,
  ) {
    final theme = Theme.of(context);

    if (syncInProgress) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      );
    }

    return pendingSyncCountAsync.when(
      data: (count) {
        if (count > 0) {
          return Badge(
            label: Text('$count'),
            backgroundColor: theme.colorScheme.error,
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          );
        } else {
          return Icon(
            Icons.cloud_done_outlined,
            size: 20,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          );
        }
      },
      loading: () => const SizedBox(width: 20, height: 20),
      error: (_, _) => Icon(
        Icons.cloud_off_outlined,
        size: 20,
        color: theme.colorScheme.error,
      ),
    );
  }

  Widget _buildDetailedStatus(
    BuildContext context,
    WidgetRef ref,
    bool syncInProgress,
    DateTime? lastSyncTime,
    AsyncValue<int> pendingSyncCountAsync,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: syncInProgress ? null : () => _showSyncOptionsDialog(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncInProgress)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
            else
              pendingSyncCountAsync.when(
                data: (count) => Icon(
                  count > 0
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_done_outlined,
                  size: 16,
                  color: count > 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
                loading: () => const SizedBox(width: 16, height: 16),
                error: (_, _) => Icon(
                  Icons.cloud_off_outlined,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
              ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  syncInProgress
                      ? 'Syncing...'
                      : pendingSyncCountAsync.maybeWhen(
                          data: (count) =>
                              count > 0 ? '$count pending' : 'Synced',
                          orElse: () => 'Sync',
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lastSyncTime != null && !syncInProgress)
                  Text(
                    timeago.format(lastSyncTime, locale: 'en_short'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncOptionsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync Now'),
              subtitle: const Text('Upload and download all changes'),
              onTap: () async {
                Navigator.pop(context);
                final manualSync = ref.read(manualSyncProvider);
                final success = await manualSync();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Sync completed' : 'Sync failed'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Quick Sync'),
              subtitle: const Text('Current month only'),
              onTap: () async {
                Navigator.pop(context);
                final quickSync = ref.read(quickSyncProvider);
                final success = await quickSync();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Quick sync completed' : 'Quick sync failed',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
