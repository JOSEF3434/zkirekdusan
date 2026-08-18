import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist_dto.freezed.dart';
part 'playlist_dto.g.dart';

@freezed
class PlaylistDto with _$PlaylistDto {
  const factory PlaylistDto({
    required String id,
    required String userId,
    required String title,
    String? description,
    @Default('private') String privacy,
    @Default([]) List<PlaylistItemDto> items,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PlaylistDto;

  factory PlaylistDto.fromJson(Map<String, dynamic> json) =>
      _$PlaylistDtoFromJson(json);
}

@freezed
class PlaylistItemDto with _$PlaylistItemDto {
  const factory PlaylistItemDto({
    required String videoId,
    required DateTime addedAt,
  }) = _PlaylistItemDto;

  factory PlaylistItemDto.fromJson(Map<String, dynamic> json) =>
      _$PlaylistItemDtoFromJson(json);
}
