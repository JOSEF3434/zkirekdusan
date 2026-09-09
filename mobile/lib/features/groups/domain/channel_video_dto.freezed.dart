// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_video_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChannelVideoDto {

 String get id; String get title; String get slug; String? get description; String get status; String get visibility; String? get thumbnailUrl; String? get hlsUrl; double? get duration; int get viewsCount; int get likesCount; int get commentsCount; String get videoChannelId; String? get channelName; String? get channelHandle; String? get groupId; String get uploadedById; String? get uploaderUsername; String? get uploaderDisplayName; DateTime get createdAt; DateTime? get publishedAt;
/// Create a copy of ChannelVideoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelVideoDtoCopyWith<ChannelVideoDto> get copyWith => _$ChannelVideoDtoCopyWithImpl<ChannelVideoDto>(this as ChannelVideoDto, _$identity);

  /// Serializes this ChannelVideoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChannelVideoDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.hlsUrl, hlsUrl) || other.hlsUrl == hlsUrl)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.viewsCount, viewsCount) || other.viewsCount == viewsCount)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.videoChannelId, videoChannelId) || other.videoChannelId == videoChannelId)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&(identical(other.channelHandle, channelHandle) || other.channelHandle == channelHandle)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.uploadedById, uploadedById) || other.uploadedById == uploadedById)&&(identical(other.uploaderUsername, uploaderUsername) || other.uploaderUsername == uploaderUsername)&&(identical(other.uploaderDisplayName, uploaderDisplayName) || other.uploaderDisplayName == uploaderDisplayName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,slug,description,status,visibility,thumbnailUrl,hlsUrl,duration,viewsCount,likesCount,commentsCount,videoChannelId,channelName,channelHandle,groupId,uploadedById,uploaderUsername,uploaderDisplayName,createdAt,publishedAt]);

@override
String toString() {
  return 'ChannelVideoDto(id: $id, title: $title, slug: $slug, description: $description, status: $status, visibility: $visibility, thumbnailUrl: $thumbnailUrl, hlsUrl: $hlsUrl, duration: $duration, viewsCount: $viewsCount, likesCount: $likesCount, commentsCount: $commentsCount, videoChannelId: $videoChannelId, channelName: $channelName, channelHandle: $channelHandle, groupId: $groupId, uploadedById: $uploadedById, uploaderUsername: $uploaderUsername, uploaderDisplayName: $uploaderDisplayName, createdAt: $createdAt, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class $ChannelVideoDtoCopyWith<$Res>  {
  factory $ChannelVideoDtoCopyWith(ChannelVideoDto value, $Res Function(ChannelVideoDto) _then) = _$ChannelVideoDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String slug, String? description, String status, String visibility, String? thumbnailUrl, String? hlsUrl, double? duration, int viewsCount, int likesCount, int commentsCount, String videoChannelId, String? channelName, String? channelHandle, String? groupId, String uploadedById, String? uploaderUsername, String? uploaderDisplayName, DateTime createdAt, DateTime? publishedAt
});




}
/// @nodoc
class _$ChannelVideoDtoCopyWithImpl<$Res>
    implements $ChannelVideoDtoCopyWith<$Res> {
  _$ChannelVideoDtoCopyWithImpl(this._self, this._then);

  final ChannelVideoDto _self;
  final $Res Function(ChannelVideoDto) _then;

/// Create a copy of ChannelVideoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? slug = null,Object? description = freezed,Object? status = null,Object? visibility = null,Object? thumbnailUrl = freezed,Object? hlsUrl = freezed,Object? duration = freezed,Object? viewsCount = null,Object? likesCount = null,Object? commentsCount = null,Object? videoChannelId = null,Object? channelName = freezed,Object? channelHandle = freezed,Object? groupId = freezed,Object? uploadedById = null,Object? uploaderUsername = freezed,Object? uploaderDisplayName = freezed,Object? createdAt = null,Object? publishedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,hlsUrl: freezed == hlsUrl ? _self.hlsUrl : hlsUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,viewsCount: null == viewsCount ? _self.viewsCount : viewsCount // ignore: cast_nullable_to_non_nullable
as int,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,videoChannelId: null == videoChannelId ? _self.videoChannelId : videoChannelId // ignore: cast_nullable_to_non_nullable
as String,channelName: freezed == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String?,channelHandle: freezed == channelHandle ? _self.channelHandle : channelHandle // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,uploadedById: null == uploadedById ? _self.uploadedById : uploadedById // ignore: cast_nullable_to_non_nullable
as String,uploaderUsername: freezed == uploaderUsername ? _self.uploaderUsername : uploaderUsername // ignore: cast_nullable_to_non_nullable
as String?,uploaderDisplayName: freezed == uploaderDisplayName ? _self.uploaderDisplayName : uploaderDisplayName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChannelVideoDto].
extension ChannelVideoDtoPatterns on ChannelVideoDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChannelVideoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChannelVideoDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChannelVideoDto value)  $default,){
final _that = this;
switch (_that) {
case _ChannelVideoDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChannelVideoDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChannelVideoDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String slug,  String? description,  String status,  String visibility,  String? thumbnailUrl,  String? hlsUrl,  double? duration,  int viewsCount,  int likesCount,  int commentsCount,  String videoChannelId,  String? channelName,  String? channelHandle,  String? groupId,  String uploadedById,  String? uploaderUsername,  String? uploaderDisplayName,  DateTime createdAt,  DateTime? publishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChannelVideoDto() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.description,_that.status,_that.visibility,_that.thumbnailUrl,_that.hlsUrl,_that.duration,_that.viewsCount,_that.likesCount,_that.commentsCount,_that.videoChannelId,_that.channelName,_that.channelHandle,_that.groupId,_that.uploadedById,_that.uploaderUsername,_that.uploaderDisplayName,_that.createdAt,_that.publishedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String slug,  String? description,  String status,  String visibility,  String? thumbnailUrl,  String? hlsUrl,  double? duration,  int viewsCount,  int likesCount,  int commentsCount,  String videoChannelId,  String? channelName,  String? channelHandle,  String? groupId,  String uploadedById,  String? uploaderUsername,  String? uploaderDisplayName,  DateTime createdAt,  DateTime? publishedAt)  $default,) {final _that = this;
switch (_that) {
case _ChannelVideoDto():
return $default(_that.id,_that.title,_that.slug,_that.description,_that.status,_that.visibility,_that.thumbnailUrl,_that.hlsUrl,_that.duration,_that.viewsCount,_that.likesCount,_that.commentsCount,_that.videoChannelId,_that.channelName,_that.channelHandle,_that.groupId,_that.uploadedById,_that.uploaderUsername,_that.uploaderDisplayName,_that.createdAt,_that.publishedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String slug,  String? description,  String status,  String visibility,  String? thumbnailUrl,  String? hlsUrl,  double? duration,  int viewsCount,  int likesCount,  int commentsCount,  String videoChannelId,  String? channelName,  String? channelHandle,  String? groupId,  String uploadedById,  String? uploaderUsername,  String? uploaderDisplayName,  DateTime createdAt,  DateTime? publishedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChannelVideoDto() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.description,_that.status,_that.visibility,_that.thumbnailUrl,_that.hlsUrl,_that.duration,_that.viewsCount,_that.likesCount,_that.commentsCount,_that.videoChannelId,_that.channelName,_that.channelHandle,_that.groupId,_that.uploadedById,_that.uploaderUsername,_that.uploaderDisplayName,_that.createdAt,_that.publishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChannelVideoDto implements ChannelVideoDto {
  const _ChannelVideoDto({required this.id, required this.title, required this.slug, this.description, required this.status, required this.visibility, this.thumbnailUrl, this.hlsUrl, this.duration, required this.viewsCount, required this.likesCount, required this.commentsCount, required this.videoChannelId, this.channelName, this.channelHandle, this.groupId, required this.uploadedById, this.uploaderUsername, this.uploaderDisplayName, required this.createdAt, this.publishedAt});
  factory _ChannelVideoDto.fromJson(Map<String, dynamic> json) => _$ChannelVideoDtoFromJson(json);

@override final  String id;
@override final  String title;
@override final  String slug;
@override final  String? description;
@override final  String status;
@override final  String visibility;
@override final  String? thumbnailUrl;
@override final  String? hlsUrl;
@override final  double? duration;
@override final  int viewsCount;
@override final  int likesCount;
@override final  int commentsCount;
@override final  String videoChannelId;
@override final  String? channelName;
@override final  String? channelHandle;
@override final  String? groupId;
@override final  String uploadedById;
@override final  String? uploaderUsername;
@override final  String? uploaderDisplayName;
@override final  DateTime createdAt;
@override final  DateTime? publishedAt;

/// Create a copy of ChannelVideoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelVideoDtoCopyWith<_ChannelVideoDto> get copyWith => __$ChannelVideoDtoCopyWithImpl<_ChannelVideoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChannelVideoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChannelVideoDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.hlsUrl, hlsUrl) || other.hlsUrl == hlsUrl)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.viewsCount, viewsCount) || other.viewsCount == viewsCount)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.videoChannelId, videoChannelId) || other.videoChannelId == videoChannelId)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&(identical(other.channelHandle, channelHandle) || other.channelHandle == channelHandle)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.uploadedById, uploadedById) || other.uploadedById == uploadedById)&&(identical(other.uploaderUsername, uploaderUsername) || other.uploaderUsername == uploaderUsername)&&(identical(other.uploaderDisplayName, uploaderDisplayName) || other.uploaderDisplayName == uploaderDisplayName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,slug,description,status,visibility,thumbnailUrl,hlsUrl,duration,viewsCount,likesCount,commentsCount,videoChannelId,channelName,channelHandle,groupId,uploadedById,uploaderUsername,uploaderDisplayName,createdAt,publishedAt]);

@override
String toString() {
  return 'ChannelVideoDto(id: $id, title: $title, slug: $slug, description: $description, status: $status, visibility: $visibility, thumbnailUrl: $thumbnailUrl, hlsUrl: $hlsUrl, duration: $duration, viewsCount: $viewsCount, likesCount: $likesCount, commentsCount: $commentsCount, videoChannelId: $videoChannelId, channelName: $channelName, channelHandle: $channelHandle, groupId: $groupId, uploadedById: $uploadedById, uploaderUsername: $uploaderUsername, uploaderDisplayName: $uploaderDisplayName, createdAt: $createdAt, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class _$ChannelVideoDtoCopyWith<$Res> implements $ChannelVideoDtoCopyWith<$Res> {
  factory _$ChannelVideoDtoCopyWith(_ChannelVideoDto value, $Res Function(_ChannelVideoDto) _then) = __$ChannelVideoDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String slug, String? description, String status, String visibility, String? thumbnailUrl, String? hlsUrl, double? duration, int viewsCount, int likesCount, int commentsCount, String videoChannelId, String? channelName, String? channelHandle, String? groupId, String uploadedById, String? uploaderUsername, String? uploaderDisplayName, DateTime createdAt, DateTime? publishedAt
});




}
/// @nodoc
class __$ChannelVideoDtoCopyWithImpl<$Res>
    implements _$ChannelVideoDtoCopyWith<$Res> {
  __$ChannelVideoDtoCopyWithImpl(this._self, this._then);

  final _ChannelVideoDto _self;
  final $Res Function(_ChannelVideoDto) _then;

/// Create a copy of ChannelVideoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? slug = null,Object? description = freezed,Object? status = null,Object? visibility = null,Object? thumbnailUrl = freezed,Object? hlsUrl = freezed,Object? duration = freezed,Object? viewsCount = null,Object? likesCount = null,Object? commentsCount = null,Object? videoChannelId = null,Object? channelName = freezed,Object? channelHandle = freezed,Object? groupId = freezed,Object? uploadedById = null,Object? uploaderUsername = freezed,Object? uploaderDisplayName = freezed,Object? createdAt = null,Object? publishedAt = freezed,}) {
  return _then(_ChannelVideoDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,hlsUrl: freezed == hlsUrl ? _self.hlsUrl : hlsUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,viewsCount: null == viewsCount ? _self.viewsCount : viewsCount // ignore: cast_nullable_to_non_nullable
as int,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,videoChannelId: null == videoChannelId ? _self.videoChannelId : videoChannelId // ignore: cast_nullable_to_non_nullable
as String,channelName: freezed == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String?,channelHandle: freezed == channelHandle ? _self.channelHandle : channelHandle // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,uploadedById: null == uploadedById ? _self.uploadedById : uploadedById // ignore: cast_nullable_to_non_nullable
as String,uploaderUsername: freezed == uploaderUsername ? _self.uploaderUsername : uploaderUsername // ignore: cast_nullable_to_non_nullable
as String?,uploaderDisplayName: freezed == uploaderDisplayName ? _self.uploaderDisplayName : uploaderDisplayName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
