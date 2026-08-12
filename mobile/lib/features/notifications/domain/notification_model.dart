import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
class NotificationResponseDto with _$NotificationResponseDto {
  const factory NotificationResponseDto({
    required String id,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required bool isRead,
    required DateTime createdAt,
  }) = _NotificationResponseDto;

  factory NotificationResponseDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseDtoFromJson(json);
}
