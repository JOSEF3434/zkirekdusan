// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'creator_channel_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreatorChannelDto {

 String get id; String get groupId; String get name; String get slug; String get handle; String? get description; ChannelStatus get status; bool get isVerified; UploadPermission get uploadPermission; int get subscribersCount; int get videosCount; String? get totalViewsCount; List<String> get categories; List<String> get tags; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of CreatorChannelDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatorChannelDtoCopyWith<CreatorChannelDto> get copyWith => _$CreatorChannelDtoCopyWithImpl<CreatorChannelDto>(this as CreatorChannelDto, _$identity);

  /// Serializes this CreatorChannelDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatorChannelDto&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.uploadPermission, uploadPermission) || other.uploadPermission == uploadPermission)&&(identical(other.subscribersCount, subscribersCount) || other.subscribersCount == subscribersCount)&&(identical(other.videosCount, videosCount) || other.videosCount == videosCount)&&(identical(other.totalViewsCount, totalViewsCount) || other.totalViewsCount == totalViewsCount)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,name,slug,handle,description,status,isVerified,uploadPermission,subscribersCount,videosCount,totalViewsCount,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(tags),createdAt,updatedAt);

@override
String toString() {
  return 'CreatorChannelDto(id: $id, groupId: $groupId, name: $name, slug: $slug, handle: $handle, description: $description, status: $status, isVerified: $isVerified, uploadPermission: $uploadPermission, subscribersCount: $subscribersCount, videosCount: $videosCount, totalViewsCount: $totalViewsCount, categories: $categories, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CreatorChannelDtoCopyWith<$Res>  {
  factory $CreatorChannelDtoCopyWith(CreatorChannelDto value, $Res Function(CreatorChannelDto) _then) = _$CreatorChannelDtoCopyWithImpl;
@useResult
$Res call({
 String id, String groupId, String name, String slug, String handle, String? description, ChannelStatus status, bool isVerified, UploadPermission uploadPermission, int subscribersCount, int videosCount, String? totalViewsCount, List<String> categories, List<String> tags, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$CreatorChannelDtoCopyWithImpl<$Res>
    implements $CreatorChannelDtoCopyWith<$Res> {
  _$CreatorChannelDtoCopyWithImpl(this._self, this._then);

  final CreatorChannelDto _self;
  final $Res Function(CreatorChannelDto) _then;

/// Create a copy of CreatorChannelDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? name = null,Object? slug = null,Object? handle = null,Object? description = freezed,Object? status = null,Object? isVerified = null,Object? uploadPermission = null,Object? subscribersCount = null,Object? videosCount = null,Object? totalViewsCount = freezed,Object? categories = null,Object? tags = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChannelStatus,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,uploadPermission: null == uploadPermission ? _self.uploadPermission : uploadPermission // ignore: cast_nullable_to_non_nullable
as UploadPermission,subscribersCount: null == subscribersCount ? _self.subscribersCount : subscribersCount // ignore: cast_nullable_to_non_nullable
as int,videosCount: null == videosCount ? _self.videosCount : videosCount // ignore: cast_nullable_to_non_nullable
as int,totalViewsCount: freezed == totalViewsCount ? _self.totalViewsCount : totalViewsCount // ignore: cast_nullable_to_non_nullable
as String?,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatorChannelDto].
extension CreatorChannelDtoPatterns on CreatorChannelDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatorChannelDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatorChannelDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatorChannelDto value)  $default,){
final _that = this;
switch (_that) {
case _CreatorChannelDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatorChannelDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreatorChannelDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String groupId,  String name,  String slug,  String handle,  String? description,  ChannelStatus status,  bool isVerified,  UploadPermission uploadPermission,  int subscribersCount,  int videosCount,  String? totalViewsCount,  List<String> categories,  List<String> tags,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatorChannelDto() when $default != null:
return $default(_that.id,_that.groupId,_that.name,_that.slug,_that.handle,_that.description,_that.status,_that.isVerified,_that.uploadPermission,_that.subscribersCount,_that.videosCount,_that.totalViewsCount,_that.categories,_that.tags,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String groupId,  String name,  String slug,  String handle,  String? description,  ChannelStatus status,  bool isVerified,  UploadPermission uploadPermission,  int subscribersCount,  int videosCount,  String? totalViewsCount,  List<String> categories,  List<String> tags,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CreatorChannelDto():
return $default(_that.id,_that.groupId,_that.name,_that.slug,_that.handle,_that.description,_that.status,_that.isVerified,_that.uploadPermission,_that.subscribersCount,_that.videosCount,_that.totalViewsCount,_that.categories,_that.tags,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String groupId,  String name,  String slug,  String handle,  String? description,  ChannelStatus status,  bool isVerified,  UploadPermission uploadPermission,  int subscribersCount,  int videosCount,  String? totalViewsCount,  List<String> categories,  List<String> tags,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CreatorChannelDto() when $default != null:
return $default(_that.id,_that.groupId,_that.name,_that.slug,_that.handle,_that.description,_that.status,_that.isVerified,_that.uploadPermission,_that.subscribersCount,_that.videosCount,_that.totalViewsCount,_that.categories,_that.tags,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreatorChannelDto implements CreatorChannelDto {
  const _CreatorChannelDto({required this.id, required this.groupId, required this.name, required this.slug, required this.handle, this.description, required this.status, required this.isVerified, required this.uploadPermission, this.subscribersCount = 0, this.videosCount = 0, this.totalViewsCount, final  List<String> categories = const [], final  List<String> tags = const [], required this.createdAt, required this.updatedAt}): _categories = categories,_tags = tags;
  factory _CreatorChannelDto.fromJson(Map<String, dynamic> json) => _$CreatorChannelDtoFromJson(json);

@override final  String id;
@override final  String groupId;
@override final  String name;
@override final  String slug;
@override final  String handle;
@override final  String? description;
@override final  ChannelStatus status;
@override final  bool isVerified;
@override final  UploadPermission uploadPermission;
@override@JsonKey() final  int subscribersCount;
@override@JsonKey() final  int videosCount;
@override final  String? totalViewsCount;
 final  List<String> _categories;
@override@JsonKey() List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of CreatorChannelDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatorChannelDtoCopyWith<_CreatorChannelDto> get copyWith => __$CreatorChannelDtoCopyWithImpl<_CreatorChannelDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatorChannelDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatorChannelDto&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.uploadPermission, uploadPermission) || other.uploadPermission == uploadPermission)&&(identical(other.subscribersCount, subscribersCount) || other.subscribersCount == subscribersCount)&&(identical(other.videosCount, videosCount) || other.videosCount == videosCount)&&(identical(other.totalViewsCount, totalViewsCount) || other.totalViewsCount == totalViewsCount)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,name,slug,handle,description,status,isVerified,uploadPermission,subscribersCount,videosCount,totalViewsCount,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_tags),createdAt,updatedAt);

@override
String toString() {
  return 'CreatorChannelDto(id: $id, groupId: $groupId, name: $name, slug: $slug, handle: $handle, description: $description, status: $status, isVerified: $isVerified, uploadPermission: $uploadPermission, subscribersCount: $subscribersCount, videosCount: $videosCount, totalViewsCount: $totalViewsCount, categories: $categories, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CreatorChannelDtoCopyWith<$Res> implements $CreatorChannelDtoCopyWith<$Res> {
  factory _$CreatorChannelDtoCopyWith(_CreatorChannelDto value, $Res Function(_CreatorChannelDto) _then) = __$CreatorChannelDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String groupId, String name, String slug, String handle, String? description, ChannelStatus status, bool isVerified, UploadPermission uploadPermission, int subscribersCount, int videosCount, String? totalViewsCount, List<String> categories, List<String> tags, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$CreatorChannelDtoCopyWithImpl<$Res>
    implements _$CreatorChannelDtoCopyWith<$Res> {
  __$CreatorChannelDtoCopyWithImpl(this._self, this._then);

  final _CreatorChannelDto _self;
  final $Res Function(_CreatorChannelDto) _then;

/// Create a copy of CreatorChannelDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? name = null,Object? slug = null,Object? handle = null,Object? description = freezed,Object? status = null,Object? isVerified = null,Object? uploadPermission = null,Object? subscribersCount = null,Object? videosCount = null,Object? totalViewsCount = freezed,Object? categories = null,Object? tags = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_CreatorChannelDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChannelStatus,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,uploadPermission: null == uploadPermission ? _self.uploadPermission : uploadPermission // ignore: cast_nullable_to_non_nullable
as UploadPermission,subscribersCount: null == subscribersCount ? _self.subscribersCount : subscribersCount // ignore: cast_nullable_to_non_nullable
as int,videosCount: null == videosCount ? _self.videosCount : videosCount // ignore: cast_nullable_to_non_nullable
as int,totalViewsCount: freezed == totalViewsCount ? _self.totalViewsCount : totalViewsCount // ignore: cast_nullable_to_non_nullable
as String?,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
