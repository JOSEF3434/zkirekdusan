// lib/features/calendar/presentation/widgets/sync_status_indicator.dart
// Clickable sync status indicator widget for calendar screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_sync_provider.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/data/calendar_sync_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class SyncStatusIndicator extends ConsumerWidget {
  final bool showDetails;

  const SyncStatusIndicator({super.key, this.showDetails = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncInProgress = ref.watch(syncInProgressProvider);
    final lastSyncTime = ref.watch(lastSyncTimeProvider);
    final pendingSyncCountAsync = ref.watch(pendingSyncCountStreamProvider);
    final userRole = ref.watch(authProvider).user?.role ?? '';

    if (showDetails) {
      return _buildDetailedStatus(
        context,
        ref,
        syncInProgress,
        lastSyncTime,
        pendingSyncCountAsync,
        userRole,
      );
    } else {
      return _buildCompactStatus(
        context,
        ref,
        syncInProgress,
        pendingSyncCountAsync,
        userRole,
      );
    }
  }

  bool _canManage(String role) {
    return role == 'SUPER_ADMIN' || role == 'ADMIN';
  }

  Widget _buildCompactStatus(
    BuildContext context,
    WidgetRef ref,
    bool syncInProgress,
    AsyncValue<int> pendingSyncCountAsync,
    String userRole,
  ) {
    final theme = Theme.of(context);
    final canManage = _canManage(userRole);

    return IconButton(
      icon: syncInProgress
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          : pendingSyncCountAsync.when(
              data: (count) {
                if (count > 0) {
                  return Badge(
                    label: Text('$count'),
                    backgroundColor: theme.colorScheme.error,
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  );
                } else {
                  return Icon(
                    Icons.cloud_done_outlined,
                    size: 24,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  );
                }
              },
              loading: () => Icon(
                Icons.cloud_outlined,
                size: 24,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              error: (_, _) => Icon(
                Icons.cloud_off_outlined,
                size: 24,
                color: theme.colorScheme.error,
              ),
            ),
      tooltip: syncInProgress
          ? 'Syncing...'
          : canManage
          ? pendingSyncCountAsync.maybeWhen(
              data: (count) => count > 0
                  ? 'Tap to sync $count pending note${count > 1 ? "s" : ""}'
                  : 'Tap for sync options',
              orElse: () => 'Tap for sync options',
            )
          : 'Tap to refresh calendar data',
      onPressed: syncInProgress
          ? null
          : () {
              if (canManage) {
                // Admins get the full dialog with options
                _showSyncOptionsDialog(context);
              } else {
                // Regular users just trigger quick sync (pull data)
                _performQuickSync(context, ref);
              }
            },
    );
  }

  Widget _buildDetailedStatus(
    BuildContext context,
    WidgetRef ref,
    bool syncInProgress,
    DateTime? lastSyncTime,
    AsyncValue<int> pendingSyncCountAsync,
    String userRole,
  ) {
    final theme = Theme.of(context);
    final canManage = _canManage(userRole);

    return InkWell(
      onTap: syncInProgress
          ? null
          : () {
              if (canManage) {
                _showSyncOptionsDialog(context);
              } else {
                _performQuickSync(context, ref);
              }
            },
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

  /// Quick sync for regular users (pull data only, no dialog)
  Future<void> _performQuickSync(BuildContext context, WidgetRef ref) async {
    // Show simple loading message with shorter duration
    ScaffoldMessengerState? messenger;
    if (context.mounted) {
      messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Refreshing calendar...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      // Only download data (download-only quick sync)
      final quickSync = ref.read(quickSyncProvider);
      final result = await quickSync();
      final success = result.isSuccess;

      // Dismiss loading snackbar immediately
      messenger?.clearSnackBars();

      if (context.mounted) {
        final String message;
        if (success) {
          message = 'Calendar refreshed!';
        } else if (result.isThrottled) {
          message = 'Rate limited by server. Please wait a moment.';
        } else {
          message = 'Refresh failed. Check your internet connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.greenAccent : Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message),
                ),
              ],
            ),
            backgroundColor: success
                ? Colors.green.shade700
                : Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh calendar data
        if (success || result.notesPulled > 0) {
          ref.invalidate(calendarNotesForMonthProvider);
          ref.invalidate(calendarNotesForDateProvider);
        }
      }
    } catch (e) {
      // Dismiss loading snackbar on error
      messenger?.clearSnackBars();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Check your internet connection.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showSyncOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final tr = ref.watch(trProvider);
          final pendingSyncCountAsync = ref.watch(
            pendingSyncCountStreamProvider,
          );
          final pendingCount = pendingSyncCountAsync.maybeWhen(
            data: (count) => count,
            orElse: () => 0,
          );

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.cloud_sync,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text('Sync Options'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$pendingCount note${pendingCount > 1 ? "s" : ""} waiting to sync',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sync,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Full Sync',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Sync all calendar data (3 years)\n~30 seconds',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await _performSync(context, ref, fullSync: true);
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Quick Sync',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Push pending notes only\n~5 seconds',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await _performSync(context, ref, fullSync: false);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(tr('common.cancel')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performSync(
    BuildContext context,
    WidgetRef ref, {
    required bool fullSync,
  }) async {
    // Show loading indicator with shorter duration
    ScaffoldMessengerState? messenger;
    if (context.mounted) {
      messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(fullSync ? 'Syncing all data...' : 'Syncing changes...'),
            ],
          ),
          duration: Duration(seconds: fullSync ? 5 : 3),
        ),
      );
    }

    try {
      final CalendarSyncResult result;
      if (fullSync) {
        final manualSync = ref.read(manualSyncProvider);
        result = await manualSync();
      } else {
        final quickSync = ref.read(quickSyncProvider);
        result = await quickSync();
      }
      final success = result.isSuccess;

      // Dismiss loading snackbar immediately
      messenger?.clearSnackBars();

      // Show result
      if (context.mounted) {
        final String message;
        if (success) {
          if (fullSync) {
            message =
                'Full sync completed successfully! (${result.notesPushed} uploaded, ${result.notesPulled} downloaded)';
          } else {
            message =
                'Quick sync completed! (${result.notesPushed} uploaded)';
          }
        } else if (result.isThrottled) {
          message =
              'Sync rate limited by server (HTTP 429). Please wait a moment.';
        } else if (result.pushFailures > 0) {
          message =
              'Sync partially failed (${result.pushFailures} notes failed to upload).';
        } else {
          message = 'Sync failed. Check your internet connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.greenAccent : Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message),
                ),
              ],
            ),
            backgroundColor: success
                ? Colors.green.shade700
                : Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh calendar data
        if (success || result.notesPulled > 0) {
          ref.invalidate(calendarNotesForMonthProvider);
          ref.invalidate(calendarNotesForDateProvider);
        }
      }
    } catch (e) {
      // Dismiss loading snackbar on error
      messenger?.clearSnackBars();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Sync error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
