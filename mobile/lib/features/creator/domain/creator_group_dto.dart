// lib/features/creator/domain/creator_group_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';

part 'creator_group_dto.freezed.dart';
part 'creator_group_dto.g.dart';

@freezed
abstract class CreatorGroupDto with _$CreatorGroupDto {
  const factory CreatorGroupDto({
    required String id,
    required String name,
    required String slug,
    String? description,
    required GroupStatus status,
    required GroupVisibility visibility,
    required String createdById,
    String? approvedById,
    DateTime? approvedAt,
    required int membersCount,
    required DateTime createdAt,
    String? avatarUrl,
    String? coverUrl,
  }) = _CreatorGroupDto;

  factory CreatorGroupDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorGroupDtoFromJson(json);
}
