// lib/features/creator/domain/creator_channel_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';

part 'creator_channel_dto.freezed.dart';
part 'creator_channel_dto.g.dart';

@freezed
class CreatorChannelDto with _$CreatorChannelDto {
  const factory CreatorChannelDto({
    required String id,
    required String groupId,
    required String name,
    required String slug,
    required String handle,
    String? description,
    required ChannelStatus status,
    required bool isVerified,
    required UploadPermission uploadPermission,
    @Default(0) int subscribersCount,
    @Default(0) int videosCount,
    String? totalViewsCount,
    @Default([]) List<String> categories,
    @Default([]) List<String> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CreatorChannelDto;

  factory CreatorChannelDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorChannelDtoFromJson(json);
}
