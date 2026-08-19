// lib/features/groups/presentation/screens/tabs/group_members_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/groups/domain/group_context_dto.dart';
import 'package:mobile/features/groups/domain/group_enums.dart';
import 'package:mobile/features/groups/presentation/providers/group_members_provider.dart';
import 'package:mobile/features/groups/presentation/widgets/group_member_tile.dart';

class GroupMembersTab extends ConsumerWidget {
  final GroupContextDto groupContext;

  const GroupMembersTab({
    super.key,
    required this.groupContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(groupMembersProvider(groupContext.id));
    final canManage = groupContext.capabilities.canManageMembers;

    if (state.isLoading && state.members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  ref.read(groupMembersProvider(groupContext.id).notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.members.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(groupMembersProvider(groupContext.id).notifier).refresh(),
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                children: [
                  Icon(Icons.group_outlined, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No members found', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(groupMembersProvider(groupContext.id).notifier).refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            ref.read(groupMembersProvider(groupContext.id).notifier).loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.members.length + (state.isFetchingMore ? 1 : 0),
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index >= state.members.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final member = state.members[index];
            return GroupMemberTile(
              member: member,
              canManage: canManage,
              onRoleChanged: (newRole) async {
                try {
                  await ref
                      .read(groupMembersProvider(groupContext.id).notifier)
                      .updateMemberRole(member.userId, newRole);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated role to ${newRole.displayName}')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                }
              },
              onRemove: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove Member'),
                    content: Text(
                      'Are you sure you want to remove ${member.displayName ?? member.username ?? "this member"} from the group?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await ref
                        .read(groupMembersProvider(groupContext.id).notifier)
                        .removeMember(member.userId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Member removed')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                      );
                    }
                  }
                }
              },
            );
          },
        ),
      ),
    );
  }
}
