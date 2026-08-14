// lib/features/creator/domain/creator_enums.dart
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum GroupStatus {
  @JsonValue('PENDING_APPROVAL')
  pendingApproval,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('SUSPENDED')
  suspended,
  @JsonValue('ARCHIVED')
  archived,
  @JsonValue('REJECTED')
  rejected,
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum GroupVisibility {
  @JsonValue('PUBLIC')
  public,
  @JsonValue('PRIVATE')
  private,
  @JsonValue('INVITE_ONLY')
  inviteOnly,
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum ChannelStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('SUSPENDED')
  suspended,
  @JsonValue('ARCHIVED')
  archived,
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum UploadPermission {
  @JsonValue('GROUP_ADMIN')
  groupAdmin,
  @JsonValue('MODERATOR')
  moderator,
  @JsonValue('MEMBER')
  member,
  @JsonValue('GUEST')
  guest,
}
