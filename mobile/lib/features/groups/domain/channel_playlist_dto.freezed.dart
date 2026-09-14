// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_playlist_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChannelPlaylistItemDto {

 String get id; int get order; String get videoId; String? get videoTitle; String? get videoSlug; double? get videoDuration; String? get videoThumbnailUrl; int? get videoViewsCount;
/// Create a copy of ChannelPlaylistItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelPlaylistItemDtoCopyWith<ChannelPlaylistItemDto> get copyWith => _$ChannelPlaylistItemDtoCopyWithImpl<ChannelPlaylistItemDto>(this as ChannelPlaylistItemDto, _$identity);

  /// Serializes this ChannelPlaylistItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChannelPlaylistItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.videoTitle, videoTitle) || other.videoTitle == videoTitle)&&(identical(other.videoSlug, videoSlug) || other.videoSlug == videoSlug)&&(identical(other.videoDuration, videoDuration) || other.videoDuration == videoDuration)&&(identical(other.videoThumbnailUrl, videoThumbnailUrl) || other.videoThumbnailUrl == videoThumbnailUrl)&&(identical(other.videoViewsCount, videoViewsCount) || other.videoViewsCount == videoViewsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,order,videoId,videoTitle,videoSlug,videoDuration,videoThumbnailUrl,videoViewsCount);

@override
String toString() {
  return 'ChannelPlaylistItemDto(id: $id, order: $order, videoId: $videoId, videoTitle: $videoTitle, videoSlug: $videoSlug, videoDuration: $videoDuration, videoThumbnailUrl: $videoThumbnailUrl, videoViewsCount: $videoViewsCount)';
}


}

/// @nodoc
abstract mixin class $ChannelPlaylistItemDtoCopyWith<$Res>  {
  factory $ChannelPlaylistItemDtoCopyWith(ChannelPlaylistItemDto value, $Res Function(ChannelPlaylistItemDto) _then) = _$ChannelPlaylistItemDtoCopyWithImpl;
@useResult
$Res call({
 String id, int order, String videoId, String? videoTitle, String? videoSlug, double? videoDuration, String? videoThumbnailUrl, int? videoViewsCount
});




}
/// @nodoc
class _$ChannelPlaylistItemDtoCopyWithImpl<$Res>
    implements $ChannelPlaylistItemDtoCopyWith<$Res> {
  _$ChannelPlaylistItemDtoCopyWithImpl(this._self, this._then);

  final ChannelPlaylistItemDto _self;
  final $Res Function(ChannelPlaylistItemDto) _then;

/// Create a copy of ChannelPlaylistItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? order = null,Object? videoId = null,Object? videoTitle = freezed,Object? videoSlug = freezed,Object? videoDuration = freezed,Object? videoThumbnailUrl = freezed,Object? videoViewsCount = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,videoId: null == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String,videoTitle: freezed == videoTitle ? _self.videoTitle : videoTitle // ignore: cast_nullable_to_non_nullable
as String?,videoSlug: freezed == videoSlug ? _self.videoSlug : videoSlug // ignore: cast_nullable_to_non_nullable
as String?,videoDuration: freezed == videoDuration ? _self.videoDuration : videoDuration // ignore: cast_nullable_to_non_nullable
as double?,videoThumbnailUrl: freezed == videoThumbnailUrl ? _self.videoThumbnailUrl : videoThumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,videoViewsCount: freezed == videoViewsCount ? _self.videoViewsCount : videoViewsCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChannelPlaylistItemDto].
extension ChannelPlaylistItemDtoPatterns on ChannelPlaylistItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChannelPlaylistItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChannelPlaylistItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChannelPlaylistItemDto value)  $default,){
final _that = this;
switch (_that) {
case _ChannelPlaylistItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChannelPlaylistItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChannelPlaylistItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int order,  String videoId,  String? videoTitle,  String? videoSlug,  double? videoDuration,  String? videoThumbnailUrl,  int? videoViewsCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChannelPlaylistItemDto() when $default != null:
return $default(_that.id,_that.order,_that.videoId,_that.videoTitle,_that.videoSlug,_that.videoDuration,_that.videoThumbnailUrl,_that.videoViewsCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int order,  String videoId,  String? videoTitle,  String? videoSlug,  double? videoDuration,  String? videoThumbnailUrl,  int? videoViewsCount)  $default,) {final _that = this;
switch (_that) {
case _ChannelPlaylistItemDto():
return $default(_that.id,_that.order,_that.videoId,_that.videoTitle,_that.videoSlug,_that.videoDuration,_that.videoThumbnailUrl,_that.videoViewsCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int order,  String videoId,  String? videoTitle,  String? videoSlug,  double? videoDuration,  String? videoThumbnailUrl,  int? videoViewsCount)?  $default,) {final _that = this;
switch (_that) {
case _ChannelPlaylistItemDto() when $default != null:
return $default(_that.id,_that.order,_that.videoId,_that.videoTitle,_that.videoSlug,_that.videoDuration,_that.videoThumbnailUrl,_that.videoViewsCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChannelPlaylistItemDto implements ChannelPlaylistItemDto {
  const _ChannelPlaylistItemDto({required this.id, required this.order, required this.videoId, this.videoTitle, this.videoSlug, this.videoDuration, this.videoThumbnailUrl, this.videoViewsCount});
  factory _ChannelPlaylistItemDto.fromJson(Map<String, dynamic> json) => _$ChannelPlaylistItemDtoFromJson(json);

@override final  String id;
@override final  int order;
@override final  String videoId;
@override final  String? videoTitle;
@override final  String? videoSlug;
@override final  double? videoDuration;
@override final  String? videoThumbnailUrl;
@override final  int? videoViewsCount;

/// Create a copy of ChannelPlaylistItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelPlaylistItemDtoCopyWith<_ChannelPlaylistItemDto> get copyWith => __$ChannelPlaylistItemDtoCopyWithImpl<_ChannelPlaylistItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChannelPlaylistItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChannelPlaylistItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.videoTitle, videoTitle) || other.videoTitle == videoTitle)&&(identical(other.videoSlug, videoSlug) || other.videoSlug == videoSlug)&&(identical(other.videoDuration, videoDuration) || other.videoDuration == videoDuration)&&(identical(other.videoThumbnailUrl, videoThumbnailUrl) || other.videoThumbnailUrl == videoThumbnailUrl)&&(identical(other.videoViewsCount, videoViewsCount) || other.videoViewsCount == videoViewsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,order,videoId,videoTitle,videoSlug,videoDuration,videoThumbnailUrl,videoViewsCount);

@override
String toString() {
  return 'ChannelPlaylistItemDto(id: $id, order: $order, videoId: $videoId, videoTitle: $videoTitle, videoSlug: $videoSlug, videoDuration: $videoDuration, videoThumbnailUrl: $videoThumbnailUrl, videoViewsCount: $videoViewsCount)';
}


}

/// @nodoc
abstract mixin class _$ChannelPlaylistItemDtoCopyWith<$Res> implements $ChannelPlaylistItemDtoCopyWith<$Res> {
  factory _$ChannelPlaylistItemDtoCopyWith(_ChannelPlaylistItemDto value, $Res Function(_ChannelPlaylistItemDto) _then) = __$ChannelPlaylistItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, int order, String videoId, String? videoTitle, String? videoSlug, double? videoDuration, String? videoThumbnailUrl, int? videoViewsCount
});




}
/// @nodoc
class __$ChannelPlaylistItemDtoCopyWithImpl<$Res>
    implements _$ChannelPlaylistItemDtoCopyWith<$Res> {
  __$ChannelPlaylistItemDtoCopyWithImpl(this._self, this._then);

  final _ChannelPlaylistItemDto _self;
  final $Res Function(_ChannelPlaylistItemDto) _then;

/// Create a copy of ChannelPlaylistItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? order = null,Object? videoId = null,Object? videoTitle = freezed,Object? videoSlug = freezed,Object? videoDuration = freezed,Object? videoThumbnailUrl = freezed,Object? videoViewsCount = freezed,}) {
  return _then(_ChannelPlaylistItemDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,videoId: null == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String,videoTitle: freezed == videoTitle ? _self.videoTitle : videoTitle // ignore: cast_nullable_to_non_nullable
as String?,videoSlug: freezed == videoSlug ? _self.videoSlug : videoSlug // ignore: cast_nullable_to_non_nullable
as String?,videoDuration: freezed == videoDuration ? _self.videoDuration : videoDuration // ignore: cast_nullable_to_non_nullable
as double?,videoThumbnailUrl: freezed == videoThumbnailUrl ? _self.videoThumbnailUrl : videoThumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,videoViewsCount: freezed == videoViewsCount ? _self.videoViewsCount : videoViewsCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ChannelPlaylistDto {

 String get id; String get title; String? get description; String get visibility; int get videosCount; String get ownerId; String? get ownerUsername; String? get videoChannelId; String? get channelName; List<ChannelPlaylistItemDto> get items; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of ChannelPlaylistDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelPlaylistDtoCopyWith<ChannelPlaylistDto> get copyWith => _$ChannelPlaylistDtoCopyWithImpl<ChannelPlaylistDto>(this as ChannelPlaylistDto, _$identity);

  /// Serializes this ChannelPlaylistDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChannelPlaylistDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.videosCount, videosCount) || other.videosCount == videosCount)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.ownerUsername, ownerUsername) || other.ownerUsername == ownerUsername)&&(identical(other.videoChannelId, videoChannelId) || other.videoChannelId == videoChannelId)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,visibility,videosCount,ownerId,ownerUsername,videoChannelId,channelName,const DeepCollectionEquality().hash(items),createdAt,updatedAt);

@override
String toString() {
  return 'ChannelPlaylistDto(id: $id, title: $title, description: $description, visibility: $visibility, videosCount: $videosCount, ownerId: $ownerId, ownerUsername: $ownerUsername, videoChannelId: $videoChannelId, channelName: $channelName, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ChannelPlaylistDtoCopyWith<$Res>  {
  factory $ChannelPlaylistDtoCopyWith(ChannelPlaylistDto value, $Res Function(ChannelPlaylistDto) _then) = _$ChannelPlaylistDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, String visibility, int videosCount, String ownerId, String? ownerUsername, String? videoChannelId, String? channelName, List<ChannelPlaylistItemDto> items, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ChannelPlaylistDtoCopyWithImpl<$Res>
    implements $ChannelPlaylistDtoCopyWith<$Res> {
  _$ChannelPlaylistDtoCopyWithImpl(this._self, this._then);

  final ChannelPlaylistDto _self;
  final $Res Function(ChannelPlaylistDto) _then;

/// Create a copy of ChannelPlaylistDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? visibility = null,Object? videosCount = null,Object? ownerId = null,Object? ownerUsername = freezed,Object? videoChannelId = freezed,Object? channelName = freezed,Object? items = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,videosCount: null == videosCount ? _self.videosCount : videosCount // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,ownerUsername: freezed == ownerUsername ? _self.ownerUsername : ownerUsername // ignore: cast_nullable_to_non_nullable
as String?,videoChannelId: freezed == videoChannelId ? _self.videoChannelId : videoChannelId // ignore: cast_nullable_to_non_nullable
as String?,channelName: freezed == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ChannelPlaylistItemDto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ChannelPlaylistDto].
extension ChannelPlaylistDtoPatterns on ChannelPlaylistDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChannelPlaylistDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChannelPlaylistDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChannelPlaylistDto value)  $default,){
final _that = this;
switch (_that) {
case _ChannelPlaylistDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChannelPlaylistDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChannelPlaylistDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String visibility,  int videosCount,  String ownerId,  String? ownerUsername,  String? videoChannelId,  String? channelName,  List<ChannelPlaylistItemDto> items,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChannelPlaylistDto() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.visibility,_that.videosCount,_that.ownerId,_that.ownerUsername,_that.videoChannelId,_that.channelName,_that.items,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String visibility,  int videosCount,  String ownerId,  String? ownerUsername,  String? videoChannelId,  String? channelName,  List<ChannelPlaylistItemDto> items,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ChannelPlaylistDto():
return $default(_that.id,_that.title,_that.description,_that.visibility,_that.videosCount,_that.ownerId,_that.ownerUsername,_that.videoChannelId,_that.channelName,_that.items,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  String visibility,  int videosCount,  String ownerId,  String? ownerUsername,  String? videoChannelId,  String? channelName,  List<ChannelPlaylistItemDto> items,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChannelPlaylistDto() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.visibility,_that.videosCount,_that.ownerId,_that.ownerUsername,_that.videoChannelId,_that.channelName,_that.items,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChannelPlaylistDto implements ChannelPlaylistDto {
  const _ChannelPlaylistDto({required this.id, required this.title, this.description, required this.visibility, required this.videosCount, required this.ownerId, this.ownerUsername, this.videoChannelId, this.channelName, final  List<ChannelPlaylistItemDto> items = const [], required this.createdAt, required this.updatedAt}): _items = items;
  factory _ChannelPlaylistDto.fromJson(Map<String, dynamic> json) => _$ChannelPlaylistDtoFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? description;
@override final  String visibility;
@override final  int videosCount;
@override final  String ownerId;
@override final  String? ownerUsername;
@override final  String? videoChannelId;
@override final  String? channelName;
 final  List<ChannelPlaylistItemDto> _items;
@override@JsonKey() List<ChannelPlaylistItemDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of ChannelPlaylistDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelPlaylistDtoCopyWith<_ChannelPlaylistDto> get copyWith => __$ChannelPlaylistDtoCopyWithImpl<_ChannelPlaylistDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChannelPlaylistDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChannelPlaylistDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.videosCount, videosCount) || other.videosCount == videosCount)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.ownerUsername, ownerUsername) || other.ownerUsername == ownerUsername)&&(identical(other.videoChannelId, videoChannelId) || other.videoChannelId == videoChannelId)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,visibility,videosCount,ownerId,ownerUsername,videoChannelId,channelName,const DeepCollectionEquality().hash(_items),createdAt,updatedAt);

@override
String toString() {
  return 'ChannelPlaylistDto(id: $id, title: $title, description: $description, visibility: $visibility, videosCount: $videosCount, ownerId: $ownerId, ownerUsername: $ownerUsername, videoChannelId: $videoChannelId, channelName: $channelName, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ChannelPlaylistDtoCopyWith<$Res> implements $ChannelPlaylistDtoCopyWith<$Res> {
  factory _$ChannelPlaylistDtoCopyWith(_ChannelPlaylistDto value, $Res Function(_ChannelPlaylistDto) _then) = __$ChannelPlaylistDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, String visibility, int videosCount, String ownerId, String? ownerUsername, String? videoChannelId, String? channelName, List<ChannelPlaylistItemDto> items, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ChannelPlaylistDtoCopyWithImpl<$Res>
    implements _$ChannelPlaylistDtoCopyWith<$Res> {
  __$ChannelPlaylistDtoCopyWithImpl(this._self, this._then);

  final _ChannelPlaylistDto _self;
  final $Res Function(_ChannelPlaylistDto) _then;

/// Create a copy of ChannelPlaylistDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? visibility = null,Object? videosCount = null,Object? ownerId = null,Object? ownerUsername = freezed,Object? videoChannelId = freezed,Object? channelName = freezed,Object? items = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ChannelPlaylistDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,videosCount: null == videosCount ? _self.videosCount : videosCount // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,ownerUsername: freezed == ownerUsername ? _self.ownerUsername : ownerUsername // ignore: cast_nullable_to_non_nullable
as String?,videoChannelId: freezed == videoChannelId ? _self.videoChannelId : videoChannelId // ignore: cast_nullable_to_non_nullable
as String?,channelName: freezed == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ChannelPlaylistItemDto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
