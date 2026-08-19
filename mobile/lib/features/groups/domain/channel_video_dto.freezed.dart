// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_video_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChannelVideoDto _$ChannelVideoDtoFromJson(Map<String, dynamic> json) {
  return _ChannelVideoDto.fromJson(json);
}

/// @nodoc
mixin _$ChannelVideoDto {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get visibility => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  String? get hlsUrl => throw _privateConstructorUsedError;
  double? get duration => throw _privateConstructorUsedError;
  int get viewsCount => throw _privateConstructorUsedError;
  int get likesCount => throw _privateConstructorUsedError;
  int get commentsCount => throw _privateConstructorUsedError;
  String get videoChannelId => throw _privateConstructorUsedError;
  String? get channelName => throw _privateConstructorUsedError;
  String? get channelHandle => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  String get uploadedById => throw _privateConstructorUsedError;
  String? get uploaderUsername => throw _privateConstructorUsedError;
  String? get uploaderDisplayName => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get publishedAt => throw _privateConstructorUsedError;

  /// Serializes this ChannelVideoDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChannelVideoDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChannelVideoDtoCopyWith<ChannelVideoDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChannelVideoDtoCopyWith<$Res> {
  factory $ChannelVideoDtoCopyWith(
    ChannelVideoDto value,
    $Res Function(ChannelVideoDto) then,
  ) = _$ChannelVideoDtoCopyWithImpl<$Res, ChannelVideoDto>;
  @useResult
  $Res call({
    String id,
    String title,
    String slug,
    String? description,
    String status,
    String visibility,
    String? thumbnailUrl,
    String? hlsUrl,
    double? duration,
    int viewsCount,
    int likesCount,
    int commentsCount,
    String videoChannelId,
    String? channelName,
    String? channelHandle,
    String? groupId,
    String uploadedById,
    String? uploaderUsername,
    String? uploaderDisplayName,
    DateTime createdAt,
    DateTime? publishedAt,
  });
}

/// @nodoc
class _$ChannelVideoDtoCopyWithImpl<$Res, $Val extends ChannelVideoDto>
    implements $ChannelVideoDtoCopyWith<$Res> {
  _$ChannelVideoDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChannelVideoDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? description = freezed,
    Object? status = null,
    Object? visibility = null,
    Object? thumbnailUrl = freezed,
    Object? hlsUrl = freezed,
    Object? duration = freezed,
    Object? viewsCount = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? videoChannelId = null,
    Object? channelName = freezed,
    Object? channelHandle = freezed,
    Object? groupId = freezed,
    Object? uploadedById = null,
    Object? uploaderUsername = freezed,
    Object? uploaderDisplayName = freezed,
    Object? createdAt = null,
    Object? publishedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            visibility: null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                      as String,
            thumbnailUrl: freezed == thumbnailUrl
                ? _value.thumbnailUrl
                : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            hlsUrl: freezed == hlsUrl
                ? _value.hlsUrl
                : hlsUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as double?,
            viewsCount: null == viewsCount
                ? _value.viewsCount
                : viewsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            likesCount: null == likesCount
                ? _value.likesCount
                : likesCount // ignore: cast_nullable_to_non_nullable
                      as int,
            commentsCount: null == commentsCount
                ? _value.commentsCount
                : commentsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            videoChannelId: null == videoChannelId
                ? _value.videoChannelId
                : videoChannelId // ignore: cast_nullable_to_non_nullable
                      as String,
            channelName: freezed == channelName
                ? _value.channelName
                : channelName // ignore: cast_nullable_to_non_nullable
                      as String?,
            channelHandle: freezed == channelHandle
                ? _value.channelHandle
                : channelHandle // ignore: cast_nullable_to_non_nullable
                      as String?,
            groupId: freezed == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String?,
            uploadedById: null == uploadedById
                ? _value.uploadedById
                : uploadedById // ignore: cast_nullable_to_non_nullable
                      as String,
            uploaderUsername: freezed == uploaderUsername
                ? _value.uploaderUsername
                : uploaderUsername // ignore: cast_nullable_to_non_nullable
                      as String?,
            uploaderDisplayName: freezed == uploaderDisplayName
                ? _value.uploaderDisplayName
                : uploaderDisplayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            publishedAt: freezed == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChannelVideoDtoImplCopyWith<$Res>
    implements $ChannelVideoDtoCopyWith<$Res> {
  factory _$$ChannelVideoDtoImplCopyWith(
    _$ChannelVideoDtoImpl value,
    $Res Function(_$ChannelVideoDtoImpl) then,
  ) = __$$ChannelVideoDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String slug,
    String? description,
    String status,
    String visibility,
    String? thumbnailUrl,
    String? hlsUrl,
    double? duration,
    int viewsCount,
    int likesCount,
    int commentsCount,
    String videoChannelId,
    String? channelName,
    String? channelHandle,
    String? groupId,
    String uploadedById,
    String? uploaderUsername,
    String? uploaderDisplayName,
    DateTime createdAt,
    DateTime? publishedAt,
  });
}

/// @nodoc
class __$$ChannelVideoDtoImplCopyWithImpl<$Res>
    extends _$ChannelVideoDtoCopyWithImpl<$Res, _$ChannelVideoDtoImpl>
    implements _$$ChannelVideoDtoImplCopyWith<$Res> {
  __$$ChannelVideoDtoImplCopyWithImpl(
    _$ChannelVideoDtoImpl _value,
    $Res Function(_$ChannelVideoDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChannelVideoDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? description = freezed,
    Object? status = null,
    Object? visibility = null,
    Object? thumbnailUrl = freezed,
    Object? hlsUrl = freezed,
    Object? duration = freezed,
    Object? viewsCount = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? videoChannelId = null,
    Object? channelName = freezed,
    Object? channelHandle = freezed,
    Object? groupId = freezed,
    Object? uploadedById = null,
    Object? uploaderUsername = freezed,
    Object? uploaderDisplayName = freezed,
    Object? createdAt = null,
    Object? publishedAt = freezed,
  }) {
    return _then(
      _$ChannelVideoDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        visibility: null == visibility
            ? _value.visibility
            : visibility // ignore: cast_nullable_to_non_nullable
                  as String,
        thumbnailUrl: freezed == thumbnailUrl
            ? _value.thumbnailUrl
            : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        hlsUrl: freezed == hlsUrl
            ? _value.hlsUrl
            : hlsUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as double?,
        viewsCount: null == viewsCount
            ? _value.viewsCount
            : viewsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        likesCount: null == likesCount
            ? _value.likesCount
            : likesCount // ignore: cast_nullable_to_non_nullable
                  as int,
        commentsCount: null == commentsCount
            ? _value.commentsCount
            : commentsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        videoChannelId: null == videoChannelId
            ? _value.videoChannelId
            : videoChannelId // ignore: cast_nullable_to_non_nullable
                  as String,
        channelName: freezed == channelName
            ? _value.channelName
            : channelName // ignore: cast_nullable_to_non_nullable
                  as String?,
        channelHandle: freezed == channelHandle
            ? _value.channelHandle
            : channelHandle // ignore: cast_nullable_to_non_nullable
                  as String?,
        groupId: freezed == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String?,
        uploadedById: null == uploadedById
            ? _value.uploadedById
            : uploadedById // ignore: cast_nullable_to_non_nullable
                  as String,
        uploaderUsername: freezed == uploaderUsername
            ? _value.uploaderUsername
            : uploaderUsername // ignore: cast_nullable_to_non_nullable
                  as String?,
        uploaderDisplayName: freezed == uploaderDisplayName
            ? _value.uploaderDisplayName
            : uploaderDisplayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        publishedAt: freezed == publishedAt
            ? _value.publishedAt
            : publishedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChannelVideoDtoImpl implements _ChannelVideoDto {
  const _$ChannelVideoDtoImpl({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.status,
    required this.visibility,
    this.thumbnailUrl,
    this.hlsUrl,
    this.duration,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.videoChannelId,
    this.channelName,
    this.channelHandle,
    this.groupId,
    required this.uploadedById,
    this.uploaderUsername,
    this.uploaderDisplayName,
    required this.createdAt,
    this.publishedAt,
  });

  factory _$ChannelVideoDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChannelVideoDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String slug;
  @override
  final String? description;
  @override
  final String status;
  @override
  final String visibility;
  @override
  final String? thumbnailUrl;
  @override
  final String? hlsUrl;
  @override
  final double? duration;
  @override
  final int viewsCount;
  @override
  final int likesCount;
  @override
  final int commentsCount;
  @override
  final String videoChannelId;
  @override
  final String? channelName;
  @override
  final String? channelHandle;
  @override
  final String? groupId;
  @override
  final String uploadedById;
  @override
  final String? uploaderUsername;
  @override
  final String? uploaderDisplayName;
  @override
  final DateTime createdAt;
  @override
  final DateTime? publishedAt;

  @override
  String toString() {
    return 'ChannelVideoDto(id: $id, title: $title, slug: $slug, description: $description, status: $status, visibility: $visibility, thumbnailUrl: $thumbnailUrl, hlsUrl: $hlsUrl, duration: $duration, viewsCount: $viewsCount, likesCount: $likesCount, commentsCount: $commentsCount, videoChannelId: $videoChannelId, channelName: $channelName, channelHandle: $channelHandle, groupId: $groupId, uploadedById: $uploadedById, uploaderUsername: $uploaderUsername, uploaderDisplayName: $uploaderDisplayName, createdAt: $createdAt, publishedAt: $publishedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelVideoDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.hlsUrl, hlsUrl) || other.hlsUrl == hlsUrl) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.viewsCount, viewsCount) ||
                other.viewsCount == viewsCount) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.commentsCount, commentsCount) ||
                other.commentsCount == commentsCount) &&
            (identical(other.videoChannelId, videoChannelId) ||
                other.videoChannelId == videoChannelId) &&
            (identical(other.channelName, channelName) ||
                other.channelName == channelName) &&
            (identical(other.channelHandle, channelHandle) ||
                other.channelHandle == channelHandle) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.uploadedById, uploadedById) ||
                other.uploadedById == uploadedById) &&
            (identical(other.uploaderUsername, uploaderUsername) ||
                other.uploaderUsername == uploaderUsername) &&
            (identical(other.uploaderDisplayName, uploaderDisplayName) ||
                other.uploaderDisplayName == uploaderDisplayName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    title,
    slug,
    description,
    status,
    visibility,
    thumbnailUrl,
    hlsUrl,
    duration,
    viewsCount,
    likesCount,
    commentsCount,
    videoChannelId,
    channelName,
    channelHandle,
    groupId,
    uploadedById,
    uploaderUsername,
    uploaderDisplayName,
    createdAt,
    publishedAt,
  ]);

  /// Create a copy of ChannelVideoDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelVideoDtoImplCopyWith<_$ChannelVideoDtoImpl> get copyWith =>
      __$$ChannelVideoDtoImplCopyWithImpl<_$ChannelVideoDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChannelVideoDtoImplToJson(this);
  }
}

abstract class _ChannelVideoDto implements ChannelVideoDto {
  const factory _ChannelVideoDto({
    required final String id,
    required final String title,
    required final String slug,
    final String? description,
    required final String status,
    required final String visibility,
    final String? thumbnailUrl,
    final String? hlsUrl,
    final double? duration,
    required final int viewsCount,
    required final int likesCount,
    required final int commentsCount,
    required final String videoChannelId,
    final String? channelName,
    final String? channelHandle,
    final String? groupId,
    required final String uploadedById,
    final String? uploaderUsername,
    final String? uploaderDisplayName,
    required final DateTime createdAt,
    final DateTime? publishedAt,
  }) = _$ChannelVideoDtoImpl;

  factory _ChannelVideoDto.fromJson(Map<String, dynamic> json) =
      _$ChannelVideoDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get slug;
  @override
  String? get description;
  @override
  String get status;
  @override
  String get visibility;
  @override
  String? get thumbnailUrl;
  @override
  String? get hlsUrl;
  @override
  double? get duration;
  @override
  int get viewsCount;
  @override
  int get likesCount;
  @override
  int get commentsCount;
  @override
  String get videoChannelId;
  @override
  String? get channelName;
  @override
  String? get channelHandle;
  @override
  String? get groupId;
  @override
  String get uploadedById;
  @override
  String? get uploaderUsername;
  @override
  String? get uploaderDisplayName;
  @override
  DateTime get createdAt;
  @override
  DateTime? get publishedAt;

  /// Create a copy of ChannelVideoDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelVideoDtoImplCopyWith<_$ChannelVideoDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
