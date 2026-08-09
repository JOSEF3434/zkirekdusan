import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_model.freezed.dart';
part 'post_model.g.dart';

@freezed
class PostAuthorDto with _$PostAuthorDto {
  const factory PostAuthorDto({
    required String id,
    String? username,
    String? displayName,
    String? avatarUrl,
  }) = _PostAuthorDto;

  factory PostAuthorDto.fromJson(Map<String, dynamic> json) =>
      _$PostAuthorDtoFromJson(json);
}

@freezed
class PostMediaItemDto with _$PostMediaItemDto {
  const factory PostMediaItemDto({
    required String id,
    required String url,
    required String fileType,
    required int order,
  }) = _PostMediaItemDto;

  factory PostMediaItemDto.fromJson(Map<String, dynamic> json) =>
      _$PostMediaItemDtoFromJson(json);
}

@freezed
class PostResponseDto with _$PostResponseDto {
  const factory PostResponseDto({
    required String id,
    required String type,
    required String visibility,
    String? content,
    required List<String> hashtags,
    required int likesCount,
    required int commentsCount,
    required int viewsCount,
    required PostAuthorDto author,
    String? groupId,
    required List<PostMediaItemDto> media,
    bool? isLiked,
    bool? isSaved,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PostResponseDto;

  factory PostResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PostResponseDtoFromJson(json);
}
