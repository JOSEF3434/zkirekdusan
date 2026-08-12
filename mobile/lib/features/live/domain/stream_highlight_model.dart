// lib/features/live/domain/stream_highlight_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_highlight_model.freezed.dart';
part 'stream_highlight_model.g.dart';

@freezed
class StreamHighlightDto with _$StreamHighlightDto {
  const factory StreamHighlightDto({
    required String id,
    required String streamId,
    required String title,
    String? description,
    required int startTimeSec,
    required int endTimeSec,
    required String createdAt,
  }) = _StreamHighlightDto;

  factory StreamHighlightDto.fromJson(Map<String, dynamic> json) =>
      _$StreamHighlightDtoFromJson(json);
}
