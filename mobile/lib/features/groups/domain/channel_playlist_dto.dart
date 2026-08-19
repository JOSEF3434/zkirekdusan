// lib/features/groups/domain/channel_playlist_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_playlist_dto.freezed.dart';
part 'channel_playlist_dto.g.dart';

@freezed
class ChannelPlaylistItemDto with _$ChannelPlaylistItemDto {
  const factory ChannelPlaylistItemDto({
    required String id,
    required int order,
    required String videoId,
    String? videoTitle,
    String? videoSlug,
    double? videoDuration,
    String? videoThumbnailUrl,
    int? videoViewsCount,
  }) = _ChannelPlaylistItemDto;

  factory ChannelPlaylistItemDto.fromJson(Map<String, dynamic> json) =>
      _$ChannelPlaylistItemDtoFromJson(json);
}

@freezed
class ChannelPlaylistDto with _$ChannelPlaylistDto {
  const factory ChannelPlaylistDto({
    required String id,
    required String title,
    String? description,
    required String visibility,
    required int videosCount,
    required String ownerId,
    String? ownerUsername,
    String? videoChannelId,
    String? channelName,
    @Default([]) List<ChannelPlaylistItemDto> items,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ChannelPlaylistDto;

  factory ChannelPlaylistDto.fromJson(Map<String, dynamic> json) =>
      _$ChannelPlaylistDtoFromJson(json);
}
