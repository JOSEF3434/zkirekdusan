// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedMetaDtoImpl _$$FeedMetaDtoImplFromJson(Map<String, dynamic> json) =>
    _$FeedMetaDtoImpl(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
      hasPrev: json['hasPrev'] as bool,
    );

Map<String, dynamic> _$$FeedMetaDtoImplToJson(_$FeedMetaDtoImpl instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'totalPages': instance.totalPages,
      'hasNext': instance.hasNext,
      'hasPrev': instance.hasPrev,
    };

_$FeedResponseDtoImpl _$$FeedResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$FeedResponseDtoImpl(
  data: (json['data'] as List<dynamic>)
      .map((e) => PostResponseDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: FeedMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$FeedResponseDtoImplToJson(
  _$FeedResponseDtoImpl instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
