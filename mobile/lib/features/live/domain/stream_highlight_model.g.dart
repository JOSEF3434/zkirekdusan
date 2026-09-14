// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_highlight_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StreamHighlightDto _$StreamHighlightDtoFromJson(Map<String, dynamic> json) =>
    _StreamHighlightDto(
      id: json['id'] as String,
      streamId: json['streamId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTimeSec: (json['startTimeSec'] as num).toInt(),
      endTimeSec: (json['endTimeSec'] as num).toInt(),
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$StreamHighlightDtoToJson(_StreamHighlightDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'streamId': instance.streamId,
      'title': instance.title,
      'description': instance.description,
      'startTimeSec': instance.startTimeSec,
      'endTimeSec': instance.endTimeSec,
      'createdAt': instance.createdAt,
    };
