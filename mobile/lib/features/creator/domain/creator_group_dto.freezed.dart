// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'creator_group_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreatorGroupDto {

 String get id; String get name; String get slug; String? get description; GroupStatus get status; GroupVisibility get visibility; String get createdById; String? get approvedById; DateTime? get approvedAt; int get membersCount; DateTime get createdAt; String? get avatarUrl; String? get coverUrl;
/// Create a copy of CreatorGroupDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatorGroupDtoCopyWith<CreatorGroupDto> get copyWith => _$CreatorGroupDtoCopyWithImpl<CreatorGroupDto>(this as CreatorGroupDto, _$identity);

  /// Serializes this CreatorGroupDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatorGroupDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.createdById, createdById) || other.createdById == createdById)&&(identical(other.approvedById, approvedById) || other.approvedById == approvedById)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.membersCount, membersCount) || other.membersCount == membersCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,description,status,visibility,createdById,approvedById,approvedAt,membersCount,createdAt,avatarUrl,coverUrl);

@override
String toString() {
  return 'CreatorGroupDto(id: $id, name: $name, slug: $slug, description: $description, status: $status, visibility: $visibility, createdById: $createdById, approvedById: $approvedById, approvedAt: $approvedAt, membersCount: $membersCount, createdAt: $createdAt, avatarUrl: $avatarUrl, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class $CreatorGroupDtoCopyWith<$Res>  {
  factory $CreatorGroupDtoCopyWith(CreatorGroupDto value, $Res Function(CreatorGroupDto) _then) = _$CreatorGroupDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug, String? description, GroupStatus status, GroupVisibility visibility, String createdById, String? approvedById, DateTime? approvedAt, int membersCount, DateTime createdAt, String? avatarUrl, String? coverUrl
});




}
/// @nodoc
class _$CreatorGroupDtoCopyWithImpl<$Res>
    implements $CreatorGroupDtoCopyWith<$Res> {
  _$CreatorGroupDtoCopyWithImpl(this._self, this._then);

  final CreatorGroupDto _self;
  final $Res Function(CreatorGroupDto) _then;

/// Create a copy of CreatorGroupDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? description = freezed,Object? status = null,Object? visibility = null,Object? createdById = null,Object? approvedById = freezed,Object? approvedAt = freezed,Object? membersCount = null,Object? createdAt = null,Object? avatarUrl = freezed,Object? coverUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GroupStatus,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as GroupVisibility,createdById: null == createdById ? _self.createdById : createdById // ignore: cast_nullable_to_non_nullable
as String,approvedById: freezed == approvedById ? _self.approvedById : approvedById // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,membersCount: null == membersCount ? _self.membersCount : membersCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatorGroupDto].
extension CreatorGroupDtoPatterns on CreatorGroupDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatorGroupDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatorGroupDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatorGroupDto value)  $default,){
final _that = this;
switch (_that) {
case _CreatorGroupDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatorGroupDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreatorGroupDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String? description,  GroupStatus status,  GroupVisibility visibility,  String createdById,  String? approvedById,  DateTime? approvedAt,  int membersCount,  DateTime createdAt,  String? avatarUrl,  String? coverUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatorGroupDto() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.description,_that.status,_that.visibility,_that.createdById,_that.approvedById,_that.approvedAt,_that.membersCount,_that.createdAt,_that.avatarUrl,_that.coverUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String? description,  GroupStatus status,  GroupVisibility visibility,  String createdById,  String? approvedById,  DateTime? approvedAt,  int membersCount,  DateTime createdAt,  String? avatarUrl,  String? coverUrl)  $default,) {final _that = this;
switch (_that) {
case _CreatorGroupDto():
return $default(_that.id,_that.name,_that.slug,_that.description,_that.status,_that.visibility,_that.createdById,_that.approvedById,_that.approvedAt,_that.membersCount,_that.createdAt,_that.avatarUrl,_that.coverUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String slug,  String? description,  GroupStatus status,  GroupVisibility visibility,  String createdById,  String? approvedById,  DateTime? approvedAt,  int membersCount,  DateTime createdAt,  String? avatarUrl,  String? coverUrl)?  $default,) {final _that = this;
switch (_that) {
case _CreatorGroupDto() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.description,_that.status,_that.visibility,_that.createdById,_that.approvedById,_that.approvedAt,_that.membersCount,_that.createdAt,_that.avatarUrl,_that.coverUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreatorGroupDto implements CreatorGroupDto {
  const _CreatorGroupDto({required this.id, required this.name, required this.slug, this.description, required this.status, required this.visibility, required this.createdById, this.approvedById, this.approvedAt, required this.membersCount, required this.createdAt, this.avatarUrl, this.coverUrl});
  factory _CreatorGroupDto.fromJson(Map<String, dynamic> json) => _$CreatorGroupDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String slug;
@override final  String? description;
@override final  GroupStatus status;
@override final  GroupVisibility visibility;
@override final  String createdById;
@override final  String? approvedById;
@override final  DateTime? approvedAt;
@override final  int membersCount;
@override final  DateTime createdAt;
@override final  String? avatarUrl;
@override final  String? coverUrl;

/// Create a copy of CreatorGroupDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatorGroupDtoCopyWith<_CreatorGroupDto> get copyWith => __$CreatorGroupDtoCopyWithImpl<_CreatorGroupDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatorGroupDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatorGroupDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.createdById, createdById) || other.createdById == createdById)&&(identical(other.approvedById, approvedById) || other.approvedById == approvedById)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.membersCount, membersCount) || other.membersCount == membersCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,description,status,visibility,createdById,approvedById,approvedAt,membersCount,createdAt,avatarUrl,coverUrl);

@override
String toString() {
  return 'CreatorGroupDto(id: $id, name: $name, slug: $slug, description: $description, status: $status, visibility: $visibility, createdById: $createdById, approvedById: $approvedById, approvedAt: $approvedAt, membersCount: $membersCount, createdAt: $createdAt, avatarUrl: $avatarUrl, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class _$CreatorGroupDtoCopyWith<$Res> implements $CreatorGroupDtoCopyWith<$Res> {
  factory _$CreatorGroupDtoCopyWith(_CreatorGroupDto value, $Res Function(_CreatorGroupDto) _then) = __$CreatorGroupDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug, String? description, GroupStatus status, GroupVisibility visibility, String createdById, String? approvedById, DateTime? approvedAt, int membersCount, DateTime createdAt, String? avatarUrl, String? coverUrl
});




}
/// @nodoc
class __$CreatorGroupDtoCopyWithImpl<$Res>
    implements _$CreatorGroupDtoCopyWith<$Res> {
  __$CreatorGroupDtoCopyWithImpl(this._self, this._then);

  final _CreatorGroupDto _self;
  final $Res Function(_CreatorGroupDto) _then;

/// Create a copy of CreatorGroupDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? description = freezed,Object? status = null,Object? visibility = null,Object? createdById = null,Object? approvedById = freezed,Object? approvedAt = freezed,Object? membersCount = null,Object? createdAt = null,Object? avatarUrl = freezed,Object? coverUrl = freezed,}) {
  return _then(_CreatorGroupDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GroupStatus,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as GroupVisibility,createdById: null == createdById ? _self.createdById : createdById // ignore: cast_nullable_to_non_nullable
as String,approvedById: freezed == approvedById ? _self.approvedById : approvedById // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,membersCount: null == membersCount ? _self.membersCount : membersCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
