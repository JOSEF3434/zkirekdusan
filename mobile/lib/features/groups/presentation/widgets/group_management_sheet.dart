// lib/features/groups/presentation/widgets/group_management_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator/presentation/providers/creator_workspace_provider.dart';
import 'package:mobile/features/creator/presentation/widgets/group_status_badge.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/presentation/providers/group_detail_provider.dart';
import 'package:mobile/features/groups/presentation/widgets/edit_group_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class GroupManagementSheet extends ConsumerStatefulWidget {
  final CreatorGroupDto group;

  const GroupManagementSheet({super.key, required this.group});

  static Future<void> show(
    BuildContext context, {
    required CreatorGroupDto group,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupManagementSheet(group: group),
    );
  }

  @override
  ConsumerState<GroupManagementSheet> createState() =>
      _GroupManagementSheetState();
}

class _GroupManagementSheetState extends ConsumerState<GroupManagementSheet> {
  bool _isDeleting = false;
  bool _isRepairing = false;

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('admin.confirm.delete_title'))),
        content: Text(
          'Are you sure you want to delete "${widget.group.name}"? '
          'This will remove all associated channels and content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.cancel'))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.delete'))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.deleteGroup(widget.group.id);

      ref.invalidate(groupDetailProvider(widget.group.id));
      ref.read(creatorWorkspaceProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Group "${widget.group.name}" was deleted successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        final msg = e is Failure
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete group: $msg'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRepair() async {
    setState(() => _isRepairing = true);
    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.repairGroup(widget.group.id);
      ref.invalidate(groupDetailProvider(widget.group.id));
      ref.read(creatorWorkspaceProvider.notifier).refresh();

      if (mounted) {
        setState(() => _isRepairing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group sync & repair complete!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRepairing = false);
        final msg = e is Failure
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repair failed: $msg'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleEdit() {
    Navigator.of(context).pop();
    EditGroupSheet.show(
      context,
      groupId: widget.group.id,
      initialName: widget.group.name,
      initialDescription: widget.group.description,
      initialVisibility: widget.group.visibility.name.toUpperCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = widget.group;
    final isPending = group.status == GroupStatus.pendingApproval;
    final isActive = group.status == GroupStatus.active;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Group Header Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage:
                      (group.avatarUrl != null && group.avatarUrl!.isNotEmpty)
                      ? NetworkImage(group.avatarUrl!)
                      : null,
                  child: (group.avatarUrl == null || group.avatarUrl!.isEmpty)
                      ? Text(
                          group.name.substring(0, 1).toUpperCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          GroupStatusBadge(status: group.status),
                          const SizedBox(width: 8),
                          Text(
                            'Created ${timeago.format(group.createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Action: Open Group Channel
          ListTile(
            leading: Icon(Icons.open_in_new, color: theme.colorScheme.primary),
            title: Text(
              isPending ? 'Open Group (Preview)' : 'Open Group Channel',
            ),
            subtitle: Text(
              isPending
                  ? 'View pending group channel and details'
                  : 'Go to group videos, playlists and chats',
            ),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/groups/${group.id}');
            },
          ),

          // Action: Edit Group Details
          ListTile(
            leading: Icon(
              Icons.edit_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('groups.edit.title'))),
            subtitle: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('groups.edit.desc_label'))),
            onTap: _handleEdit,
          ),

          // Action: Upload Video (for active groups)
          if (isActive)
            ListTile(
              leading: Icon(
                Icons.video_call_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('shell.upload_video'))),
              subtitle: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('upload.description_hint'))),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/creator/upload?groupId=${group.id}');
              },
            ),

          // Action: Manage Members (for active groups)
          if (isActive)
            ListTile(
              leading: Icon(
                Icons.people_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('groups.add_members'))),
              subtitle: Text('${group.membersCount} members'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/groups/${group.id}?tab=members');
              },
            ),

          // Action: Repair / Resync
          ListTile(
            leading: _isRepairing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.sync, color: theme.colorScheme.secondary),
            title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.refresh'))),
            subtitle: const Text(
              'Ensure creator permissions and channel setup',
            ),
            onTap: _isRepairing ? null : _handleRepair,
          ),

          const Divider(height: 16),

          // Action: Delete Group
          ListTile(
            leading: _isDeleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  )
                : Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text(
              isPending ? 'Delete Pending Request' : 'Delete Group',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              isPending
                  ? 'Cancel this group request'
                  : 'Permanently remove this group and all its content',
              style: TextStyle(
                color: theme.colorScheme.error.withValues(alpha: 0.8),
              ),
            ),
            onTap: _isDeleting ? null : _handleDelete,
          ),
        ],
      ),
    );
  }
}


