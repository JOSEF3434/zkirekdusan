// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FollowStatusDto {

 bool get isFollowing; bool get isFollowedBy;
/// Create a copy of FollowStatusDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowStatusDtoCopyWith<FollowStatusDto> get copyWith => _$FollowStatusDtoCopyWithImpl<FollowStatusDto>(this as FollowStatusDto, _$identity);

  /// Serializes this FollowStatusDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowStatusDto&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.isFollowedBy, isFollowedBy) || other.isFollowedBy == isFollowedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isFollowing,isFollowedBy);

@override
String toString() {
  return 'FollowStatusDto(isFollowing: $isFollowing, isFollowedBy: $isFollowedBy)';
}


}

/// @nodoc
abstract mixin class $FollowStatusDtoCopyWith<$Res>  {
  factory $FollowStatusDtoCopyWith(FollowStatusDto value, $Res Function(FollowStatusDto) _then) = _$FollowStatusDtoCopyWithImpl;
@useResult
$Res call({
 bool isFollowing, bool isFollowedBy
});




}
/// @nodoc
class _$FollowStatusDtoCopyWithImpl<$Res>
    implements $FollowStatusDtoCopyWith<$Res> {
  _$FollowStatusDtoCopyWithImpl(this._self, this._then);

  final FollowStatusDto _self;
  final $Res Function(FollowStatusDto) _then;

/// Create a copy of FollowStatusDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isFollowing = null,Object? isFollowedBy = null,}) {
  return _then(_self.copyWith(
isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,isFollowedBy: null == isFollowedBy ? _self.isFollowedBy : isFollowedBy // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowStatusDto].
extension FollowStatusDtoPatterns on FollowStatusDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowStatusDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowStatusDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowStatusDto value)  $default,){
final _that = this;
switch (_that) {
case _FollowStatusDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowStatusDto value)?  $default,){
final _that = this;
switch (_that) {
case _FollowStatusDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isFollowing,  bool isFollowedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowStatusDto() when $default != null:
return $default(_that.isFollowing,_that.isFollowedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isFollowing,  bool isFollowedBy)  $default,) {final _that = this;
switch (_that) {
case _FollowStatusDto():
return $default(_that.isFollowing,_that.isFollowedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isFollowing,  bool isFollowedBy)?  $default,) {final _that = this;
switch (_that) {
case _FollowStatusDto() when $default != null:
return $default(_that.isFollowing,_that.isFollowedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowStatusDto implements FollowStatusDto {
  const _FollowStatusDto({required this.isFollowing, required this.isFollowedBy});
  factory _FollowStatusDto.fromJson(Map<String, dynamic> json) => _$FollowStatusDtoFromJson(json);

@override final  bool isFollowing;
@override final  bool isFollowedBy;

/// Create a copy of FollowStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowStatusDtoCopyWith<_FollowStatusDto> get copyWith => __$FollowStatusDtoCopyWithImpl<_FollowStatusDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowStatusDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowStatusDto&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.isFollowedBy, isFollowedBy) || other.isFollowedBy == isFollowedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isFollowing,isFollowedBy);

@override
String toString() {
  return 'FollowStatusDto(isFollowing: $isFollowing, isFollowedBy: $isFollowedBy)';
}


}

/// @nodoc
abstract mixin class _$FollowStatusDtoCopyWith<$Res> implements $FollowStatusDtoCopyWith<$Res> {
  factory _$FollowStatusDtoCopyWith(_FollowStatusDto value, $Res Function(_FollowStatusDto) _then) = __$FollowStatusDtoCopyWithImpl;
@override @useResult
$Res call({
 bool isFollowing, bool isFollowedBy
});




}
/// @nodoc
class __$FollowStatusDtoCopyWithImpl<$Res>
    implements _$FollowStatusDtoCopyWith<$Res> {
  __$FollowStatusDtoCopyWithImpl(this._self, this._then);

  final _FollowStatusDto _self;
  final $Res Function(_FollowStatusDto) _then;

/// Create a copy of FollowStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isFollowing = null,Object? isFollowedBy = null,}) {
  return _then(_FollowStatusDto(
isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,isFollowedBy: null == isFollowedBy ? _self.isFollowedBy : isFollowedBy // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$FollowerDto {

 String get id; String? get username; String? get displayName; String? get avatarUrl; bool get isFollowing;
/// Create a copy of FollowerDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowerDtoCopyWith<FollowerDto> get copyWith => _$FollowerDtoCopyWithImpl<FollowerDto>(this as FollowerDto, _$identity);

  /// Serializes this FollowerDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowerDto&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl,isFollowing);

@override
String toString() {
  return 'FollowerDto(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, isFollowing: $isFollowing)';
}


}

/// @nodoc
abstract mixin class $FollowerDtoCopyWith<$Res>  {
  factory $FollowerDtoCopyWith(FollowerDto value, $Res Function(FollowerDto) _then) = _$FollowerDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? username, String? displayName, String? avatarUrl, bool isFollowing
});




}
/// @nodoc
class _$FollowerDtoCopyWithImpl<$Res>
    implements $FollowerDtoCopyWith<$Res> {
  _$FollowerDtoCopyWithImpl(this._self, this._then);

  final FollowerDto _self;
  final $Res Function(FollowerDto) _then;

/// Create a copy of FollowerDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = freezed,Object? displayName = freezed,Object? avatarUrl = freezed,Object? isFollowing = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowerDto].
extension FollowerDtoPatterns on FollowerDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowerDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowerDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowerDto value)  $default,){
final _that = this;
switch (_that) {
case _FollowerDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowerDto value)?  $default,){
final _that = this;
switch (_that) {
case _FollowerDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? username,  String? displayName,  String? avatarUrl,  bool isFollowing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowerDto() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl,_that.isFollowing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? username,  String? displayName,  String? avatarUrl,  bool isFollowing)  $default,) {final _that = this;
switch (_that) {
case _FollowerDto():
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl,_that.isFollowing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? username,  String? displayName,  String? avatarUrl,  bool isFollowing)?  $default,) {final _that = this;
switch (_that) {
case _FollowerDto() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl,_that.isFollowing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowerDto implements FollowerDto {
  const _FollowerDto({required this.id, this.username, this.displayName, this.avatarUrl, this.isFollowing = false});
  factory _FollowerDto.fromJson(Map<String, dynamic> json) => _$FollowerDtoFromJson(json);

@override final  String id;
@override final  String? username;
@override final  String? displayName;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isFollowing;

/// Create a copy of FollowerDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowerDtoCopyWith<_FollowerDto> get copyWith => __$FollowerDtoCopyWithImpl<_FollowerDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowerDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowerDto&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl,isFollowing);

@override
String toString() {
  return 'FollowerDto(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, isFollowing: $isFollowing)';
}


}

/// @nodoc
abstract mixin class _$FollowerDtoCopyWith<$Res> implements $FollowerDtoCopyWith<$Res> {
  factory _$FollowerDtoCopyWith(_FollowerDto value, $Res Function(_FollowerDto) _then) = __$FollowerDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? username, String? displayName, String? avatarUrl, bool isFollowing
});




}
/// @nodoc
class __$FollowerDtoCopyWithImpl<$Res>
    implements _$FollowerDtoCopyWith<$Res> {
  __$FollowerDtoCopyWithImpl(this._self, this._then);

  final _FollowerDto _self;
  final $Res Function(_FollowerDto) _then;

/// Create a copy of FollowerDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = freezed,Object? displayName = freezed,Object? avatarUrl = freezed,Object? isFollowing = null,}) {
  return _then(_FollowerDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
