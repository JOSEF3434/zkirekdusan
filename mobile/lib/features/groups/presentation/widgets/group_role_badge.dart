// lib/features/groups/presentation/widgets/group_role_badge.dart

import 'package:flutter/material.dart';
import 'package:mobile/features/groups/domain/group_enums.dart';

class GroupRoleBadge extends StatelessWidget {
  final GroupRole role;
  final bool compact;

  const GroupRoleBadge({super.key, required this.role, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, bgColor, fgColor) = _getStyle(theme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fgColor,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 10 : 12,
        ),
      ),
    );
  }

  (String, Color, Color) _getStyle(ThemeData theme) {
    switch (role) {
      case GroupRole.groupAdmin:
        return (
          'Admin',
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
        );
      case GroupRole.moderator:
        return (
          'Mod',
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
        );
      case GroupRole.member:
        return (
          'Member',
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
        );
      case GroupRole.guest:
        return (
          'Guest',
          theme.colorScheme.surfaceContainer,
          theme.colorScheme.outline,
        );
    }
  }
}
