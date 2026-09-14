import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

@freezed
abstract class CommentAuthorDto with _$CommentAuthorDto {
  const factory CommentAuthorDto({
    required String id,
    String? username,
    String? displayName,
    String? avatarUrl,
  }) = _CommentAuthorDto;

  factory CommentAuthorDto.fromJson(Map<String, dynamic> json) =>
      _$CommentAuthorDtoFromJson(json);
}

@freezed
abstract class CommentResponseDto with _$CommentResponseDto {
  const factory CommentResponseDto({
    required String id,
    required String postId,
    String? parentId,
    required String content,
    @Default(0) int likesCount,
    required CommentAuthorDto author,
    required DateTime createdAt,
    @Default([]) List<CommentResponseDto> replies,
  }) = _CommentResponseDto;

  factory CommentResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CommentResponseDtoFromJson(json);
}
