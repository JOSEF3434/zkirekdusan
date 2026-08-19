// lib/features/groups/domain/group_enums.dart
import 'package:freezed_annotation/freezed_annotation.dart';

/// Group-level roles matching the backend GroupRole enum.
/// Hierarchy: GROUP_ADMIN > MODERATOR > MEMBER > GUEST
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum GroupRole {
  @JsonValue('GROUP_ADMIN')
  groupAdmin,
  @JsonValue('MODERATOR')
  moderator,
  @JsonValue('MEMBER')
  member,
  @JsonValue('GUEST')
  guest,
}

extension GroupRoleX on GroupRole {
  /// Returns true if this role has at least the privileges of [other].
  bool isAtLeast(GroupRole other) {
    const hierarchy = {
      GroupRole.groupAdmin: 4,
      GroupRole.moderator: 3,
      GroupRole.member: 2,
      GroupRole.guest: 1,
    };
    return hierarchy[this]! >= hierarchy[other]!;
  }

  String get displayName {
    switch (this) {
      case GroupRole.groupAdmin:
        return 'Admin';
      case GroupRole.moderator:
        return 'Moderator';
      case GroupRole.member:
        return 'Member';
      case GroupRole.guest:
        return 'Guest';
    }
  }
}
