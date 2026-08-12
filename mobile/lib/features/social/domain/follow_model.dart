import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_model.freezed.dart';
part 'follow_model.g.dart';

@freezed
class FollowStatusDto with _$FollowStatusDto {
  const factory FollowStatusDto({
    required bool isFollowing,
    required bool isFollowedBy,
  }) = _FollowStatusDto;

  factory FollowStatusDto.fromJson(Map<String, dynamic> json) =>
      _$FollowStatusDtoFromJson(json);
}

@freezed
class FollowerDto with _$FollowerDto {
  const factory FollowerDto({
    required String id,
    String? username,
    String? displayName,
    String? avatarUrl,
    @Default(false) bool isFollowing,
  }) = _FollowerDto;

  factory FollowerDto.fromJson(Map<String, dynamic> json) =>
      _$FollowerDtoFromJson(json);
}
