// lib/features/groups/presentation/widgets/group_member_tile.dart

import 'package:flutter/material.dart';
import 'package:mobile/features/groups/domain/group_enums.dart';
import 'package:mobile/features/groups/domain/group_member_dto.dart';
import 'package:mobile/features/groups/presentation/widgets/group_role_badge.dart';

class GroupMemberTile extends StatelessWidget {
  final GroupMemberDto member;
  final bool canManage;
  final ValueChanged<GroupRole>? onRoleChanged;
  final VoidCallback? onRemove;

  const GroupMemberTile({
    super.key,
    required this.member,
    this.canManage = false,
    this.onRoleChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = member.displayName ?? member.username ?? 'Member';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GroupRoleBadge(role: member.role, compact: true),
        ],
      ),
      subtitle: member.username != null
          ? Text('@${member.username}', style: theme.textTheme.bodySmall)
          : null,
      trailing: canManage
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'remove') {
                  onRemove?.call();
                } else if (value.startsWith('role_')) {
                  final roleName = value.replaceFirst('role_', '');
                  final role = GroupRole.values.firstWhere(
                    (r) => r.name.toLowerCase() == roleName.toLowerCase(),
                    orElse: () => GroupRole.member,
                  );
                  onRoleChanged?.call(role);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  enabled: false,
                  child: Text(
                    'Change Role',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuItem(
                  value: 'role_moderator',
                  child: Row(
                    children: [
                      Icon(
                        member.role == GroupRole.moderator
                            ? Icons.check
                            : Icons.shield_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text('Moderator'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'role_member',
                  child: Row(
                    children: [
                      Icon(
                        member.role == GroupRole.member
                            ? Icons.check
                            : Icons.person_outline,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text('Member'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'role_guest',
                  child: Row(
                    children: [
                      Icon(
                        member.role == GroupRole.guest
                            ? Icons.check
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text('Guest'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Remove from Group',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
