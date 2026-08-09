import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/features/home/domain/post_model.dart';

part 'feed_response.freezed.dart';
part 'feed_response.g.dart';

@freezed
class FeedMetaDto with _$FeedMetaDto {
  const factory FeedMetaDto({
    required int page,
    required int limit,
    required int total,
    required int totalPages,
    required bool hasNext,
    required bool hasPrev,
  }) = _FeedMetaDto;

  factory FeedMetaDto.fromJson(Map<String, dynamic> json) =>
      _$FeedMetaDtoFromJson(json);
}

@freezed
class FeedResponseDto with _$FeedResponseDto {
  const factory FeedResponseDto({
    required List<PostResponseDto> data,
    required FeedMetaDto meta,
  }) = _FeedResponseDto;

  factory FeedResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FeedResponseDtoFromJson(json);
}
