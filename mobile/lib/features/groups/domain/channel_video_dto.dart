// lib/features/groups/domain/channel_video_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_video_dto.freezed.dart';
part 'channel_video_dto.g.dart';

@freezed
class ChannelVideoDto with _$ChannelVideoDto {
  const factory ChannelVideoDto({
    required String id,
    required String title,
    required String slug,
    String? description,
    required String status,
    required String visibility,
    String? thumbnailUrl,
    String? hlsUrl,
    double? duration,
    required int viewsCount,
    required int likesCount,
    required int commentsCount,
    required String videoChannelId,
    String? channelName,
    String? channelHandle,
    String? groupId,
    required String uploadedById,
    String? uploaderUsername,
    String? uploaderDisplayName,
    required DateTime createdAt,
    DateTime? publishedAt,
  }) = _ChannelVideoDto;

  factory ChannelVideoDto.fromJson(Map<String, dynamic> json) =>
      _$ChannelVideoDtoFromJson(json);
}

extension ChannelVideoDtoX on ChannelVideoDto {
  bool get isReady => status == 'READY';
  bool get isProcessing => status == 'PROCESSING' || status == 'UPLOADING';
  bool get isFailed => status == 'FAILED';

  String get formattedDuration {
    if (duration == null) return '';
    final secs = duration!.toInt();
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
