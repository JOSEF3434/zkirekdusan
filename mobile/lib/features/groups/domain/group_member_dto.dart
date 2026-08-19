// lib/features/groups/domain/group_member_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/features/groups/domain/group_enums.dart';

part 'group_member_dto.freezed.dart';
part 'group_member_dto.g.dart';

@freezed
class GroupMemberDto with _$GroupMemberDto {
  const factory GroupMemberDto({
    required String id,
    required String userId,
    String? username,
    String? displayName,
    required GroupRole role,
    required DateTime joinedAt,
  }) = _GroupMemberDto;

  factory GroupMemberDto.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberDtoFromJson(json);
}
