// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_member_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupMemberDto {

 String get id; String get userId; String? get username; String? get displayName; GroupRole get role; DateTime get joinedAt;
/// Create a copy of GroupMemberDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupMemberDtoCopyWith<GroupMemberDto> get copyWith => _$GroupMemberDtoCopyWithImpl<GroupMemberDto>(this as GroupMemberDto, _$identity);

  /// Serializes this GroupMemberDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupMemberDto&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,username,displayName,role,joinedAt);

@override
String toString() {
  return 'GroupMemberDto(id: $id, userId: $userId, username: $username, displayName: $displayName, role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $GroupMemberDtoCopyWith<$Res>  {
  factory $GroupMemberDtoCopyWith(GroupMemberDto value, $Res Function(GroupMemberDto) _then) = _$GroupMemberDtoCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String? username, String? displayName, GroupRole role, DateTime joinedAt
});




}
/// @nodoc
class _$GroupMemberDtoCopyWithImpl<$Res>
    implements $GroupMemberDtoCopyWith<$Res> {
  _$GroupMemberDtoCopyWithImpl(this._self, this._then);

  final GroupMemberDto _self;
  final $Res Function(GroupMemberDto) _then;

/// Create a copy of GroupMemberDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? username = freezed,Object? displayName = freezed,Object? role = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as GroupRole,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupMemberDto].
extension GroupMemberDtoPatterns on GroupMemberDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupMemberDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupMemberDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupMemberDto value)  $default,){
final _that = this;
switch (_that) {
case _GroupMemberDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupMemberDto value)?  $default,){
final _that = this;
switch (_that) {
case _GroupMemberDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String? username,  String? displayName,  GroupRole role,  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupMemberDto() when $default != null:
return $default(_that.id,_that.userId,_that.username,_that.displayName,_that.role,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String? username,  String? displayName,  GroupRole role,  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _GroupMemberDto():
return $default(_that.id,_that.userId,_that.username,_that.displayName,_that.role,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String? username,  String? displayName,  GroupRole role,  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _GroupMemberDto() when $default != null:
return $default(_that.id,_that.userId,_that.username,_that.displayName,_that.role,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupMemberDto implements GroupMemberDto {
  const _GroupMemberDto({required this.id, required this.userId, this.username, this.displayName, required this.role, required this.joinedAt});
  factory _GroupMemberDto.fromJson(Map<String, dynamic> json) => _$GroupMemberDtoFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String? username;
@override final  String? displayName;
@override final  GroupRole role;
@override final  DateTime joinedAt;

/// Create a copy of GroupMemberDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupMemberDtoCopyWith<_GroupMemberDto> get copyWith => __$GroupMemberDtoCopyWithImpl<_GroupMemberDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupMemberDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupMemberDto&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,username,displayName,role,joinedAt);

@override
String toString() {
  return 'GroupMemberDto(id: $id, userId: $userId, username: $username, displayName: $displayName, role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$GroupMemberDtoCopyWith<$Res> implements $GroupMemberDtoCopyWith<$Res> {
  factory _$GroupMemberDtoCopyWith(_GroupMemberDto value, $Res Function(_GroupMemberDto) _then) = __$GroupMemberDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String? username, String? displayName, GroupRole role, DateTime joinedAt
});




}
/// @nodoc
class __$GroupMemberDtoCopyWithImpl<$Res>
    implements _$GroupMemberDtoCopyWith<$Res> {
  __$GroupMemberDtoCopyWithImpl(this._self, this._then);

  final _GroupMemberDto _self;
  final $Res Function(_GroupMemberDto) _then;

/// Create a copy of GroupMemberDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? username = freezed,Object? displayName = freezed,Object? role = null,Object? joinedAt = null,}) {
  return _then(_GroupMemberDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as GroupRole,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
