// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_stream_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StreamCreatorDto {

 String get id; String? get username; String? get avatarUrl;
/// Create a copy of StreamCreatorDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamCreatorDtoCopyWith<StreamCreatorDto> get copyWith => _$StreamCreatorDtoCopyWithImpl<StreamCreatorDto>(this as StreamCreatorDto, _$identity);

  /// Serializes this StreamCreatorDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamCreatorDto&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,avatarUrl);

@override
String toString() {
  return 'StreamCreatorDto(id: $id, username: $username, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $StreamCreatorDtoCopyWith<$Res>  {
  factory $StreamCreatorDtoCopyWith(StreamCreatorDto value, $Res Function(StreamCreatorDto) _then) = _$StreamCreatorDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? username, String? avatarUrl
});




}
/// @nodoc
class _$StreamCreatorDtoCopyWithImpl<$Res>
    implements $StreamCreatorDtoCopyWith<$Res> {
  _$StreamCreatorDtoCopyWithImpl(this._self, this._then);

  final StreamCreatorDto _self;
  final $Res Function(StreamCreatorDto) _then;

/// Create a copy of StreamCreatorDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = freezed,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamCreatorDto].
extension StreamCreatorDtoPatterns on StreamCreatorDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamCreatorDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamCreatorDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamCreatorDto value)  $default,){
final _that = this;
switch (_that) {
case _StreamCreatorDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamCreatorDto value)?  $default,){
final _that = this;
switch (_that) {
case _StreamCreatorDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? username,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamCreatorDto() when $default != null:
return $default(_that.id,_that.username,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? username,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _StreamCreatorDto():
return $default(_that.id,_that.username,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? username,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _StreamCreatorDto() when $default != null:
return $default(_that.id,_that.username,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreamCreatorDto implements StreamCreatorDto {
  const _StreamCreatorDto({required this.id, this.username, this.avatarUrl});
  factory _StreamCreatorDto.fromJson(Map<String, dynamic> json) => _$StreamCreatorDtoFromJson(json);

@override final  String id;
@override final  String? username;
@override final  String? avatarUrl;

/// Create a copy of StreamCreatorDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamCreatorDtoCopyWith<_StreamCreatorDto> get copyWith => __$StreamCreatorDtoCopyWithImpl<_StreamCreatorDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreamCreatorDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamCreatorDto&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,avatarUrl);

@override
String toString() {
  return 'StreamCreatorDto(id: $id, username: $username, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$StreamCreatorDtoCopyWith<$Res> implements $StreamCreatorDtoCopyWith<$Res> {
  factory _$StreamCreatorDtoCopyWith(_StreamCreatorDto value, $Res Function(_StreamCreatorDto) _then) = __$StreamCreatorDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? username, String? avatarUrl
});




}
/// @nodoc
class __$StreamCreatorDtoCopyWithImpl<$Res>
    implements _$StreamCreatorDtoCopyWith<$Res> {
  __$StreamCreatorDtoCopyWithImpl(this._self, this._then);

  final _StreamCreatorDto _self;
  final $Res Function(_StreamCreatorDto) _then;

/// Create a copy of StreamCreatorDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = freezed,Object? avatarUrl = freezed,}) {
  return _then(_StreamCreatorDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$StreamChannelDto {

 String get id; String get name; String? get avatarUrl;
/// Create a copy of StreamChannelDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamChannelDtoCopyWith<StreamChannelDto> get copyWith => _$StreamChannelDtoCopyWithImpl<StreamChannelDto>(this as StreamChannelDto, _$identity);

  /// Serializes this StreamChannelDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamChannelDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarUrl);

@override
String toString() {
  return 'StreamChannelDto(id: $id, name: $name, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $StreamChannelDtoCopyWith<$Res>  {
  factory $StreamChannelDtoCopyWith(StreamChannelDto value, $Res Function(StreamChannelDto) _then) = _$StreamChannelDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? avatarUrl
});




}
/// @nodoc
class _$StreamChannelDtoCopyWithImpl<$Res>
    implements $StreamChannelDtoCopyWith<$Res> {
  _$StreamChannelDtoCopyWithImpl(this._self, this._then);

  final StreamChannelDto _self;
  final $Res Function(StreamChannelDto) _then;

/// Create a copy of StreamChannelDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamChannelDto].
extension StreamChannelDtoPatterns on StreamChannelDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamChannelDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamChannelDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamChannelDto value)  $default,){
final _that = this;
switch (_that) {
case _StreamChannelDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamChannelDto value)?  $default,){
final _that = this;
switch (_that) {
case _StreamChannelDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamChannelDto() when $default != null:
return $default(_that.id,_that.name,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _StreamChannelDto():
return $default(_that.id,_that.name,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _StreamChannelDto() when $default != null:
return $default(_that.id,_that.name,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreamChannelDto implements StreamChannelDto {
  const _StreamChannelDto({required this.id, required this.name, this.avatarUrl});
  factory _StreamChannelDto.fromJson(Map<String, dynamic> json) => _$StreamChannelDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? avatarUrl;

/// Create a copy of StreamChannelDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamChannelDtoCopyWith<_StreamChannelDto> get copyWith => __$StreamChannelDtoCopyWithImpl<_StreamChannelDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreamChannelDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamChannelDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarUrl);

@override
String toString() {
  return 'StreamChannelDto(id: $id, name: $name, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$StreamChannelDtoCopyWith<$Res> implements $StreamChannelDtoCopyWith<$Res> {
  factory _$StreamChannelDtoCopyWith(_StreamChannelDto value, $Res Function(_StreamChannelDto) _then) = __$StreamChannelDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? avatarUrl
});




}
/// @nodoc
class __$StreamChannelDtoCopyWithImpl<$Res>
    implements _$StreamChannelDtoCopyWith<$Res> {
  __$StreamChannelDtoCopyWithImpl(this._self, this._then);

  final _StreamChannelDto _self;
  final $Res Function(_StreamChannelDto) _then;

/// Create a copy of StreamChannelDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatarUrl = freezed,}) {
  return _then(_StreamChannelDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$StreamGroupDto {

 String get id; String get name;
/// Create a copy of StreamGroupDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamGroupDtoCopyWith<StreamGroupDto> get copyWith => _$StreamGroupDtoCopyWithImpl<StreamGroupDto>(this as StreamGroupDto, _$identity);

  /// Serializes this StreamGroupDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamGroupDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'StreamGroupDto(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $StreamGroupDtoCopyWith<$Res>  {
  factory $StreamGroupDtoCopyWith(StreamGroupDto value, $Res Function(StreamGroupDto) _then) = _$StreamGroupDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$StreamGroupDtoCopyWithImpl<$Res>
    implements $StreamGroupDtoCopyWith<$Res> {
  _$StreamGroupDtoCopyWithImpl(this._self, this._then);

  final StreamGroupDto _self;
  final $Res Function(StreamGroupDto) _then;

/// Create a copy of StreamGroupDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamGroupDto].
extension StreamGroupDtoPatterns on StreamGroupDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamGroupDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamGroupDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamGroupDto value)  $default,){
final _that = this;
switch (_that) {
case _StreamGroupDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamGroupDto value)?  $default,){
final _that = this;
switch (_that) {
case _StreamGroupDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamGroupDto() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _StreamGroupDto():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _StreamGroupDto() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreamGroupDto implements StreamGroupDto {
  const _StreamGroupDto({required this.id, required this.name});
  factory _StreamGroupDto.fromJson(Map<String, dynamic> json) => _$StreamGroupDtoFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of StreamGroupDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamGroupDtoCopyWith<_StreamGroupDto> get copyWith => __$StreamGroupDtoCopyWithImpl<_StreamGroupDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreamGroupDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamGroupDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'StreamGroupDto(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$StreamGroupDtoCopyWith<$Res> implements $StreamGroupDtoCopyWith<$Res> {
  factory _$StreamGroupDtoCopyWith(_StreamGroupDto value, $Res Function(_StreamGroupDto) _then) = __$StreamGroupDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$StreamGroupDtoCopyWithImpl<$Res>
    implements _$StreamGroupDtoCopyWith<$Res> {
  __$StreamGroupDtoCopyWithImpl(this._self, this._then);

  final _StreamGroupDto _self;
  final $Res Function(_StreamGroupDto) _then;

/// Create a copy of StreamGroupDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_StreamGroupDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LiveStreamDto {

 String get id; String get videoChannelId; String get groupId; String get createdById; String get title; String? get description; String get slug; LiveStreamStatus get status; LiveStreamVisibility get visibility; StreamProtocol get protocol; String? get hlsUrl; String? get dashUrl; String? get webrtcUrl; String? get rtmpIngestUrl; String? get thumbnailUrl; List<String> get categories; List<String> get tags; List<String> get hashtags; String? get scheduledAt; String? get startedAt; String? get endedAt; bool get isRecordingEnabled; bool get isDvrEnabled; bool get isReplayEnabled; bool get isChatEnabled; bool get isChatSlowMode; int get chatSlowModeSeconds; bool get isMembersOnlyChat; bool get isSubscribersOnlyChat; int get peakViewerCount; int get currentViewerCount; int get totalViewerCount; int get totalChatMessages; int get totalReactions; int get likesCount; int? get duration; String get createdAt; String get updatedAt; StreamCreatorDto? get createdBy; StreamGroupDto? get group; StreamChannelDto? get videoChannel;
/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveStreamDtoCopyWith<LiveStreamDto> get copyWith => _$LiveStreamDtoCopyWithImpl<LiveStreamDto>(this as LiveStreamDto, _$identity);

  /// Serializes this LiveStreamDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveStreamDto&&(identical(other.id, id) || other.id == id)&&(identical(other.videoChannelId, videoChannelId) || other.videoChannelId == videoChannelId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.createdById, createdById) || other.createdById == createdById)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.hlsUrl, hlsUrl) || other.hlsUrl == hlsUrl)&&(identical(other.dashUrl, dashUrl) || other.dashUrl == dashUrl)&&(identical(other.webrtcUrl, webrtcUrl) || other.webrtcUrl == webrtcUrl)&&(identical(other.rtmpIngestUrl, rtmpIngestUrl) || other.rtmpIngestUrl == rtmpIngestUrl)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.hashtags, hashtags)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.isRecordingEnabled, isRecordingEnabled) || other.isRecordingEnabled == isRecordingEnabled)&&(identical(other.isDvrEnabled, isDvrEnabled) || other.isDvrEnabled == isDvrEnabled)&&(identical(other.isReplayEnabled, isReplayEnabled) || other.isReplayEnabled == isReplayEnabled)&&(identical(other.isChatEnabled, isChatEnabled) || other.isChatEnabled == isChatEnabled)&&(identical(other.isChatSlowMode, isChatSlowMode) || other.isChatSlowMode == isChatSlowMode)&&(identical(other.chatSlowModeSeconds, chatSlowModeSeconds) || other.chatSlowModeSeconds == chatSlowModeSeconds)&&(identical(other.isMembersOnlyChat, isMembersOnlyChat) || other.isMembersOnlyChat == isMembersOnlyChat)&&(identical(other.isSubscribersOnlyChat, isSubscribersOnlyChat) || other.isSubscribersOnlyChat == isSubscribersOnlyChat)&&(identical(other.peakViewerCount, peakViewerCount) || other.peakViewerCount == peakViewerCount)&&(identical(other.currentViewerCount, currentViewerCount) || other.currentViewerCount == currentViewerCount)&&(identical(other.totalViewerCount, totalViewerCount) || other.totalViewerCount == totalViewerCount)&&(identical(other.totalChatMessages, totalChatMessages) || other.totalChatMessages == totalChatMessages)&&(identical(other.totalReactions, totalReactions) || other.totalReactions == totalReactions)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.group, group) || other.group == group)&&(identical(other.videoChannel, videoChannel) || other.videoChannel == videoChannel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,videoChannelId,groupId,createdById,title,description,slug,status,visibility,protocol,hlsUrl,dashUrl,webrtcUrl,rtmpIngestUrl,thumbnailUrl,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(hashtags),scheduledAt,startedAt,endedAt,isRecordingEnabled,isDvrEnabled,isReplayEnabled,isChatEnabled,isChatSlowMode,chatSlowModeSeconds,isMembersOnlyChat,isSubscribersOnlyChat,peakViewerCount,currentViewerCount,totalViewerCount,totalChatMessages,totalReactions,likesCount,duration,createdAt,updatedAt,createdBy,group,videoChannel]);

@override
String toString() {
  return 'LiveStreamDto(id: $id, videoChannelId: $videoChannelId, groupId: $groupId, createdById: $createdById, title: $title, description: $description, slug: $slug, status: $status, visibility: $visibility, protocol: $protocol, hlsUrl: $hlsUrl, dashUrl: $dashUrl, webrtcUrl: $webrtcUrl, rtmpIngestUrl: $rtmpIngestUrl, thumbnailUrl: $thumbnailUrl, categories: $categories, tags: $tags, hashtags: $hashtags, scheduledAt: $scheduledAt, startedAt: $startedAt, endedAt: $endedAt, isRecordingEnabled: $isRecordingEnabled, isDvrEnabled: $isDvrEnabled, isReplayEnabled: $isReplayEnabled, isChatEnabled: $isChatEnabled, isChatSlowMode: $isChatSlowMode, chatSlowModeSeconds: $chatSlowModeSeconds, isMembersOnlyChat: $isMembersOnlyChat, isSubscribersOnlyChat: $isSubscribersOnlyChat, peakViewerCount: $peakViewerCount, currentViewerCount: $currentViewerCount, totalViewerCount: $totalViewerCount, totalChatMessages: $totalChatMessages, totalReactions: $totalReactions, likesCount: $likesCount, duration: $duration, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, group: $group, videoChannel: $videoChannel)';
}


}

/// @nodoc
abstract mixin class $LiveStreamDtoCopyWith<$Res>  {
  factory $LiveStreamDtoCopyWith(LiveStreamDto value, $Res Function(LiveStreamDto) _then) = _$LiveStreamDtoCopyWithImpl;
@useResult
$Res call({
 String id, String videoChannelId, String groupId, String createdById, String title, String? description, String slug, LiveStreamStatus status, LiveStreamVisibility visibility, StreamProtocol protocol, String? hlsUrl, String? dashUrl, String? webrtcUrl, String? rtmpIngestUrl, String? thumbnailUrl, List<String> categories, List<String> tags, List<String> hashtags, String? scheduledAt, String? startedAt, String? endedAt, bool isRecordingEnabled, bool isDvrEnabled, bool isReplayEnabled, bool isChatEnabled, bool isChatSlowMode, int chatSlowModeSeconds, bool isMembersOnlyChat, bool isSubscribersOnlyChat, int peakViewerCount, int currentViewerCount, int totalViewerCount, int totalChatMessages, int totalReactions, int likesCount, int? duration, String createdAt, String updatedAt, StreamCreatorDto? createdBy, StreamGroupDto? group, StreamChannelDto? videoChannel
});


$StreamCreatorDtoCopyWith<$Res>? get createdBy;$StreamGroupDtoCopyWith<$Res>? get group;$StreamChannelDtoCopyWith<$Res>? get videoChannel;

}
/// @nodoc
class _$LiveStreamDtoCopyWithImpl<$Res>
    implements $LiveStreamDtoCopyWith<$Res> {
  _$LiveStreamDtoCopyWithImpl(this._self, this._then);

  final LiveStreamDto _self;
  final $Res Function(LiveStreamDto) _then;

/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? videoChannelId = null,Object? groupId = null,Object? createdById = null,Object? title = null,Object? description = freezed,Object? slug = null,Object? status = null,Object? visibility = null,Object? protocol = null,Object? hlsUrl = freezed,Object? dashUrl = freezed,Object? webrtcUrl = freezed,Object? rtmpIngestUrl = freezed,Object? thumbnailUrl = freezed,Object? categories = null,Object? tags = null,Object? hashtags = null,Object? scheduledAt = freezed,Object? startedAt = freezed,Object? endedAt = freezed,Object? isRecordingEnabled = null,Object? isDvrEnabled = null,Object? isReplayEnabled = null,Object? isChatEnabled = null,Object? isChatSlowMode = null,Object? chatSlowModeSeconds = null,Object? isMembersOnlyChat = null,Object? isSubscribersOnlyChat = null,Object? peakViewerCount = null,Object? currentViewerCount = null,Object? totalViewerCount = null,Object? totalChatMessages = null,Object? totalReactions = null,Object? likesCount = null,Object? duration = freezed,Object? createdAt = null,Object? updatedAt = null,Object? createdBy = freezed,Object? group = freezed,Object? videoChannel = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,videoChannelId: null == videoChannelId ? _self.videoChannelId : videoChannelId // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,createdById: null == createdById ? _self.createdById : createdById // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LiveStreamStatus,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as LiveStreamVisibility,protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as StreamProtocol,hlsUrl: freezed == hlsUrl ? _self.hlsUrl : hlsUrl // ignore: cast_nullable_to_non_nullable
as String?,dashUrl: freezed == dashUrl ? _self.dashUrl : dashUrl // ignore: cast_nullable_to_non_nullable
as String?,webrtcUrl: freezed == webrtcUrl ? _self.webrtcUrl : webrtcUrl // ignore: cast_nullable_to_non_nullable
as String?,rtmpIngestUrl: freezed == rtmpIngestUrl ? _self.rtmpIngestUrl : rtmpIngestUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,hashtags: null == hashtags ? _self.hashtags : hashtags // ignore: cast_nullable_to_non_nullable
as List<String>,scheduledAt: freezed == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as String?,isRecordingEnabled: null == isRecordingEnabled ? _self.isRecordingEnabled : isRecordingEnabled // ignore: cast_nullable_to_non_nullable
as bool,isDvrEnabled: null == isDvrEnabled ? _self.isDvrEnabled : isDvrEnabled // ignore: cast_nullable_to_non_nullable
as bool,isReplayEnabled: null == isReplayEnabled ? _self.isReplayEnabled : isReplayEnabled // ignore: cast_nullable_to_non_nullable
as bool,isChatEnabled: null == isChatEnabled ? _self.isChatEnabled : isChatEnabled // ignore: cast_nullable_to_non_nullable
as bool,isChatSlowMode: null == isChatSlowMode ? _self.isChatSlowMode : isChatSlowMode // ignore: cast_nullable_to_non_nullable
as bool,chatSlowModeSeconds: null == chatSlowModeSeconds ? _self.chatSlowModeSeconds : chatSlowModeSeconds // ignore: cast_nullable_to_non_nullable
as int,isMembersOnlyChat: null == isMembersOnlyChat ? _self.isMembersOnlyChat : isMembersOnlyChat // ignore: cast_nullable_to_non_nullable
as bool,isSubscribersOnlyChat: null == isSubscribersOnlyChat ? _self.isSubscribersOnlyChat : isSubscribersOnlyChat // ignore: cast_nullable_to_non_nullable
as bool,peakViewerCount: null == peakViewerCount ? _self.peakViewerCount : peakViewerCount // ignore: cast_nullable_to_non_nullable
as int,currentViewerCount: null == currentViewerCount ? _self.currentViewerCount : currentViewerCount // ignore: cast_nullable_to_non_nullable
as int,totalViewerCount: null == totalViewerCount ? _self.totalViewerCount : totalViewerCount // ignore: cast_nullable_to_non_nullable
as int,totalChatMessages: null == totalChatMessages ? _self.totalChatMessages : totalChatMessages // ignore: cast_nullable_to_non_nullable
as int,totalReactions: null == totalReactions ? _self.totalReactions : totalReactions // ignore: cast_nullable_to_non_nullable
as int,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as StreamCreatorDto?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as StreamGroupDto?,videoChannel: freezed == videoChannel ? _self.videoChannel : videoChannel // ignore: cast_nullable_to_non_nullable
as StreamChannelDto?,
  ));
}
/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreamCreatorDtoCopyWith<$Res>? get createdBy {
    if (_self.createdBy == null) {
    return null;
  }

  return $StreamCreatorDtoCopyWith<$Res>(_self.createdBy!, (value) {
    return _then(_self.copyWith(createdBy: value));
  });
}/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreamGroupDtoCopyWith<$Res>? get group {
    if (_self.group == null) {
    return null;
  }

  return $StreamGroupDtoCopyWith<$Res>(_self.group!, (value) {
    return _then(_self.copyWith(group: value));
  });
}/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreamChannelDtoCopyWith<$Res>? get videoChannel {
    if (_self.videoChannel == null) {
    return null;
  }

  return $StreamChannelDtoCopyWith<$Res>(_self.videoChannel!, (value) {
    return _then(_self.copyWith(videoChannel: value));
  });
}
}


/// Adds pattern-matching-related methods to [LiveStreamDto].
extension LiveStreamDtoPatterns on LiveStreamDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveStreamDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveStreamDto value)  $default,){
final _that = this;
switch (_that) {
case _LiveStreamDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveStreamDto value)?  $default,){
final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String videoChannelId,  String groupId,  String createdById,  String title,  String? description,  String slug,  LiveStreamStatus status,  LiveStreamVisibility visibility,  StreamProtocol protocol,  String? hlsUrl,  String? dashUrl,  String? webrtcUrl,  String? rtmpIngestUrl,  String? thumbnailUrl,  List<String> categories,  List<String> tags,  List<String> hashtags,  String? scheduledAt,  String? startedAt,  String? endedAt,  bool isRecordingEnabled,  bool isDvrEnabled,  bool isReplayEnabled,  bool isChatEnabled,  bool isChatSlowMode,  int chatSlowModeSeconds,  bool isMembersOnlyChat,  bool isSubscribersOnlyChat,  int peakViewerCount,  int currentViewerCount,  int totalViewerCount,  int totalChatMessages,  int totalReactions,  int likesCount,  int? duration,  String createdAt,  String updatedAt,  StreamCreatorDto? createdBy,  StreamGroupDto? group,  StreamChannelDto? videoChannel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
return $default(_that.id,_that.videoChannelId,_that.groupId,_that.createdById,_that.title,_that.description,_that.slug,_that.status,_that.visibility,_that.protocol,_that.hlsUrl,_that.dashUrl,_that.webrtcUrl,_that.rtmpIngestUrl,_that.thumbnailUrl,_that.categories,_that.tags,_that.hashtags,_that.scheduledAt,_that.startedAt,_that.endedAt,_that.isRecordingEnabled,_that.isDvrEnabled,_that.isReplayEnabled,_that.isChatEnabled,_that.isChatSlowMode,_that.chatSlowModeSeconds,_that.isMembersOnlyChat,_that.isSubscribersOnlyChat,_that.peakViewerCount,_that.currentViewerCount,_that.totalViewerCount,_that.totalChatMessages,_that.totalReactions,_that.likesCount,_that.duration,_that.createdAt,_that.updatedAt,_that.createdBy,_that.group,_that.videoChannel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String videoChannelId,  String groupId,  String createdById,  String title,  String? description,  String slug,  LiveStreamStatus status,  LiveStreamVisibility visibility,  StreamProtocol protocol,  String? hlsUrl,  String? dashUrl,  String? webrtcUrl,  String? rtmpIngestUrl,  String? thumbnailUrl,  List<String> categories,  List<String> tags,  List<String> hashtags,  String? scheduledAt,  String? startedAt,  String? endedAt,  bool isRecordingEnabled,  bool isDvrEnabled,  bool isReplayEnabled,  bool isChatEnabled,  bool isChatSlowMode,  int chatSlowModeSeconds,  bool isMembersOnlyChat,  bool isSubscribersOnlyChat,  int peakViewerCount,  int currentViewerCount,  int totalViewerCount,  int totalChatMessages,  int totalReactions,  int likesCount,  int? duration,  String createdAt,  String updatedAt,  StreamCreatorDto? createdBy,  StreamGroupDto? group,  StreamChannelDto? videoChannel)  $default,) {final _that = this;
switch (_that) {
case _LiveStreamDto():
return $default(_that.id,_that.videoChannelId,_that.groupId,_that.createdById,_that.title,_that.description,_that.slug,_that.status,_that.visibility,_that.protocol,_that.hlsUrl,_that.dashUrl,_that.webrtcUrl,_that.rtmpIngestUrl,_that.thumbnailUrl,_that.categories,_that.tags,_that.hashtags,_that.scheduledAt,_that.startedAt,_that.endedAt,_that.isRecordingEnabled,_that.isDvrEnabled,_that.isReplayEnabled,_that.isChatEnabled,_that.isChatSlowMode,_that.chatSlowModeSeconds,_that.isMembersOnlyChat,_that.isSubscribersOnlyChat,_that.peakViewerCount,_that.currentViewerCount,_that.totalViewerCount,_that.totalChatMessages,_that.totalReactions,_that.likesCount,_that.duration,_that.createdAt,_that.updatedAt,_that.createdBy,_that.group,_that.videoChannel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String videoChannelId,  String groupId,  String createdById,  String title,  String? description,  String slug,  LiveStreamStatus status,  LiveStreamVisibility visibility,  StreamProtocol protocol,  String? hlsUrl,  String? dashUrl,  String? webrtcUrl,  String? rtmpIngestUrl,  String? thumbnailUrl,  List<String> categories,  List<String> tags,  List<String> hashtags,  String? scheduledAt,  String? startedAt,  String? endedAt,  bool isRecordingEnabled,  bool isDvrEnabled,  bool isReplayEnabled,  bool isChatEnabled,  bool isChatSlowMode,  int chatSlowModeSeconds,  bool isMembersOnlyChat,  bool isSubscribersOnlyChat,  int peakViewerCount,  int currentViewerCount,  int totalViewerCount,  int totalChatMessages,  int totalReactions,  int likesCount,  int? duration,  String createdAt,  String updatedAt,  StreamCreatorDto? createdBy,  StreamGroupDto? group,  StreamChannelDto? videoChannel)?  $default,) {final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
return $default(_that.id,_that.videoChannelId,_that.groupId,_that.createdById,_that.title,_that.description,_that.slug,_that.status,_that.visibility,_that.protocol,_that.hlsUrl,_that.dashUrl,_that.webrtcUrl,_that.rtmpIngestUrl,_that.thumbnailUrl,_that.categories,_that.tags,_that.hashtags,_that.scheduledAt,_that.startedAt,_that.endedAt,_that.isRecordingEnabled,_that.isDvrEnabled,_that.isReplayEnabled,_that.isChatEnabled,_that.isChatSlowMode,_that.chatSlowModeSeconds,_that.isMembersOnlyChat,_that.isSubscribersOnlyChat,_that.peakViewerCount,_that.currentViewerCount,_that.totalViewerCount,_that.totalChatMessages,_that.totalReactions,_that.likesCount,_that.duration,_that.createdAt,_that.updatedAt,_that.createdBy,_that.group,_that.videoChannel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveStreamDto implements LiveStreamDto {
  const _LiveStreamDto({required this.id, required this.videoChannelId, required this.groupId, required this.createdById, required this.title, this.description, required this.slug, required this.status, required this.visibility, required this.protocol, this.hlsUrl, this.dashUrl, this.webrtcUrl, this.rtmpIngestUrl, this.thumbnailUrl, final  List<String> categories = const [], final  List<String> tags = const [], final  List<String> hashtags = const [], this.scheduledAt, this.startedAt, this.endedAt, this.isRecordingEnabled = true, this.isDvrEnabled = true, this.isReplayEnabled = true, this.isChatEnabled = true, this.isChatSlowMode = false, this.chatSlowModeSeconds = 0, this.isMembersOnlyChat = false, this.isSubscribersOnlyChat = false, this.peakViewerCount = 0, this.currentViewerCount = 0, this.totalViewerCount = 0, this.totalChatMessages = 0, this.totalReactions = 0, this.likesCount = 0, this.duration, required this.createdAt, required this.updatedAt, this.createdBy, this.group, this.videoChannel}): _categories = categories,_tags = tags,_hashtags = hashtags;
  factory _LiveStreamDto.fromJson(Map<String, dynamic> json) => _$LiveStreamDtoFromJson(json);

@override final  String id;
@override final  String videoChannelId;
@override final  String groupId;
@override final  String createdById;
@override final  String title;
@override final  String? description;
@override final  String slug;
@override final  LiveStreamStatus status;
@override final  LiveStreamVisibility visibility;
@override final  StreamProtocol protocol;
@override final  String? hlsUrl;
@override final  String? dashUrl;
@override final  String? webrtcUrl;
@override final  String? rtmpIngestUrl;
@override final  String? thumbnailUrl;
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

 final  List<String> _hashtags;
@override@JsonKey() List<String> get hashtags {
  if (_hashtags is EqualUnmodifiableListView) return _hashtags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hashtags);
}

@override final  String? scheduledAt;
@override final  String? startedAt;
@override final  String? endedAt;
@override@JsonKey() final  bool isRecordingEnabled;
@override@JsonKey() final  bool isDvrEnabled;
@override@JsonKey() final  bool isReplayEnabled;
@override@JsonKey() final  bool isChatEnabled;
@override@JsonKey() final  bool isChatSlowMode;
@override@JsonKey() final  int chatSlowModeSeconds;
@override@JsonKey() final  bool isMembersOnlyChat;
@override@JsonKey() final  bool isSubscribersOnlyChat;
@override@JsonKey() final  int peakViewerCount;
@override@JsonKey() final  int currentViewerCount;
@override@JsonKey() final  int totalViewerCount;
@override@JsonKey() final  int totalChatMessages;
@override@JsonKey() final  int totalReactions;
@override@JsonKey() final  int likesCount;
@override final  int? duration;
@override final  String createdAt;
@override final  String updatedAt;
@override final  StreamCreatorDto? createdBy;
@override final  StreamGroupDto? group;
@override final  StreamChannelDto? videoChannel;

/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveStreamDtoCopyWith<_LiveStreamDto> get copyWith => __$LiveStreamDtoCopyWithImpl<_LiveStreamDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveStreamDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveStreamDto&&(identical(other.id, id) || other.id == id)&&(identical(other.videoChannelId, videoChannelId) || other.videoChannelId == videoChannelId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.createdById, createdById) || other.createdById == createdById)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.hlsUrl, hlsUrl) || other.hlsUrl == hlsUrl)&&(identical(other.dashUrl, dashUrl) || other.dashUrl == dashUrl)&&(identical(other.webrtcUrl, webrtcUrl) || other.webrtcUrl == webrtcUrl)&&(identical(other.rtmpIngestUrl, rtmpIngestUrl) || other.rtmpIngestUrl == rtmpIngestUrl)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._hashtags, _hashtags)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.isRecordingEnabled, isRecordingEnabled) || other.isRecordingEnabled == isRecordingEnabled)&&(identical(other.isDvrEnabled, isDvrEnabled) || other.isDvrEnabled == isDvrEnabled)&&(identical(other.isReplayEnabled, isReplayEnabled) || other.isReplayEnabled == isReplayEnabled)&&(identical(other.isChatEnabled, isChatEnabled) || other.isChatEnabled == isChatEnabled)&&(identical(other.isChatSlowMode, isChatSlowMode) || other.isChatSlowMode == isChatSlowMode)&&(identical(other.chatSlowModeSeconds, chatSlowModeSeconds) || other.chatSlowModeSeconds == chatSlowModeSeconds)&&(identical(other.isMembersOnlyChat, isMembersOnlyChat) || other.isMembersOnlyChat == isMembersOnlyChat)&&(identical(other.isSubscribersOnlyChat, isSubscribersOnlyChat) || other.isSubscribersOnlyChat == isSubscribersOnlyChat)&&(identical(other.peakViewerCount, peakViewerCount) || other.peakViewerCount == peakViewerCount)&&(identical(other.currentViewerCount, currentViewerCount) || other.currentViewerCount == currentViewerCount)&&(identical(other.totalViewerCount, totalViewerCount) || other.totalViewerCount == totalViewerCount)&&(identical(other.totalChatMessages, totalChatMessages) || other.totalChatMessages == totalChatMessages)&&(identical(other.totalReactions, totalReactions) || other.totalReactions == totalReactions)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.group, group) || other.group == group)&&(identical(other.videoChannel, videoChannel) || other.videoChannel == videoChannel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,videoChannelId,groupId,createdById,title,description,slug,status,visibility,protocol,hlsUrl,dashUrl,webrtcUrl,rtmpIngestUrl,thumbnailUrl,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_hashtags),scheduledAt,startedAt,endedAt,isRecordingEnabled,isDvrEnabled,isReplayEnabled,isChatEnabled,isChatSlowMode,chatSlowModeSeconds,isMembersOnlyChat,isSubscribersOnlyChat,peakViewerCount,currentViewerCount,totalViewerCount,totalChatMessages,totalReactions,likesCount,duration,createdAt,updatedAt,createdBy,group,videoChannel]);

@override
String toString() {
  return 'LiveStreamDto(id: $id, videoChannelId: $videoChannelId, groupId: $groupId, createdById: $createdById, title: $title, description: $description, slug: $slug, status: $status, visibility: $visibility, protocol: $protocol, hlsUrl: $hlsUrl, dashUrl: $dashUrl, webrtcUrl: $webrtcUrl, rtmpIngestUrl: $rtmpIngestUrl, thumbnailUrl: $thumbnailUrl, categories: $categories, tags: $tags, hashtags: $hashtags, scheduledAt: $scheduledAt, startedAt: $startedAt, endedAt: $endedAt, isRecordingEnabled: $isRecordingEnabled, isDvrEnabled: $isDvrEnabled, isReplayEnabled: $isReplayEnabled, isChatEnabled: $isChatEnabled, isChatSlowMode: $isChatSlowMode, chatSlowModeSeconds: $chatSlowModeSeconds, isMembersOnlyChat: $isMembersOnlyChat, isSubscribersOnlyChat: $isSubscribersOnlyChat, peakViewerCount: $peakViewerCount, currentViewerCount: $currentViewerCount, totalViewerCount: $totalViewerCount, totalChatMessages: $totalChatMessages, totalReactions: $totalReactions, likesCount: $likesCount, duration: $duration, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, group: $group, videoChannel: $videoChannel)';
}


}

/// @nodoc
abstract mixin class _$LiveStreamDtoCopyWith<$Res> implements $LiveStreamDtoCopyWith<$Res> {
  factory _$LiveStreamDtoCopyWith(_LiveStreamDto value, $Res Function(_LiveStreamDto) _then) = __$LiveStreamDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String videoChannelId, String groupId, String createdById, String title, String? description, String slug, LiveStreamStatus status, LiveStreamVisibility visibility, StreamProtocol protocol, String? hlsUrl, String? dashUrl, String? webrtcUrl, String? rtmpIngestUrl, String? thumbnailUrl, List<String> categories, List<String> tags, List<String> hashtags, String? scheduledAt, String? startedAt, String? endedAt, bool isRecordingEnabled, bool isDvrEnabled, bool isReplayEnabled, bool isChatEnabled, bool isChatSlowMode, int chatSlowModeSeconds, bool isMembersOnlyChat, bool isSubscribersOnlyChat, int peakViewerCount, int currentViewerCount, int totalViewerCount, int totalChatMessages, int totalReactions, int likesCount, int? duration, String createdAt, String updatedAt, StreamCreatorDto? createdBy, StreamGroupDto? group, StreamChannelDto? videoChannel
});


@override $StreamCreatorDtoCopyWith<$Res>? get createdBy;@override $StreamGroupDtoCopyWith<$Res>? get group;@override $StreamChannelDtoCopyWith<$Res>? get videoChannel;

}
/// @nodoc
class __$LiveStreamDtoCopyWithImpl<$Res>
    implements _$LiveStreamDtoCopyWith<$Res> {
  __$LiveStreamDtoCopyWithImpl(this._self, this._then);

  final _LiveStreamDto _self;
  final $Res Function(_LiveStreamDto) _then;

/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? videoChannelId = null,Object? groupId = null,Object? createdById = null,Object? title = null,Object? description = freezed,Object? slug = null,Object? status = null,Object? visibility = null,Object? protocol = null,Object? hlsUrl = freezed,Object? dashUrl = freezed,Object? webrtcUrl = freezed,Object? rtmpIngestUrl = freezed,Object? thumbnailUrl = freezed,Object? categories = null,Object? tags = null,Object? hashtags = null,Object? scheduledAt = freezed,Object? startedAt = freezed,Object? endedAt = freezed,Object? isRecordingEnabled = null,Object? isDvrEnabled = null,Object? isReplayEnabled = null,Object? isChatEnabled = null,Object? isChatSlowMode = null,Object? chatSlowModeSeconds = null,Object? isMembersOnlyChat = null,Object? isSubscribersOnlyChat = null,Object? peakViewerCount = null,Object? currentViewerCount = null,Object? totalViewerCount = null,Object? totalChatMessages = null,Object? totalReactions = null,Object? likesCount = null,Object? duration = freezed,Object? createdAt = null,Object? updatedAt = null,Object? createdBy = freezed,Object? group = freezed,Object? videoChannel = freezed,}) {
  return _then(_LiveStreamDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,videoChannelId: null == videoChannelId ? _self.videoChannelId : videoChannelId // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,createdById: null == createdById ? _self.createdById : createdById // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LiveStreamStatus,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as LiveStreamVisibility,protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as StreamProtocol,hlsUrl: freezed == hlsUrl ? _self.hlsUrl : hlsUrl // ignore: cast_nullable_to_non_nullable
as String?,dashUrl: freezed == dashUrl ? _self.dashUrl : dashUrl // ignore: cast_nullable_to_non_nullable
as String?,webrtcUrl: freezed == webrtcUrl ? _self.webrtcUrl : webrtcUrl // ignore: cast_nullable_to_non_nullable
as String?,rtmpIngestUrl: freezed == rtmpIngestUrl ? _self.rtmpIngestUrl : rtmpIngestUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,hashtags: null == hashtags ? _self._hashtags : hashtags // ignore: cast_nullable_to_non_nullable
as List<String>,scheduledAt: freezed == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as String?,isRecordingEnabled: null == isRecordingEnabled ? _self.isRecordingEnabled : isRecordingEnabled // ignore: cast_nullable_to_non_nullable
as bool,isDvrEnabled: null == isDvrEnabled ? _self.isDvrEnabled : isDvrEnabled // ignore: cast_nullable_to_non_nullable
as bool,isReplayEnabled: null == isReplayEnabled ? _self.isReplayEnabled : isReplayEnabled // ignore: cast_nullable_to_non_nullable
as bool,isChatEnabled: null == isChatEnabled ? _self.isChatEnabled : isChatEnabled // ignore: cast_nullable_to_non_nullable
as bool,isChatSlowMode: null == isChatSlowMode ? _self.isChatSlowMode : isChatSlowMode // ignore: cast_nullable_to_non_nullable
as bool,chatSlowModeSeconds: null == chatSlowModeSeconds ? _self.chatSlowModeSeconds : chatSlowModeSeconds // ignore: cast_nullable_to_non_nullable
as int,isMembersOnlyChat: null == isMembersOnlyChat ? _self.isMembersOnlyChat : isMembersOnlyChat // ignore: cast_nullable_to_non_nullable
as bool,isSubscribersOnlyChat: null == isSubscribersOnlyChat ? _self.isSubscribersOnlyChat : isSubscribersOnlyChat // ignore: cast_nullable_to_non_nullable
as bool,peakViewerCount: null == peakViewerCount ? _self.peakViewerCount : peakViewerCount // ignore: cast_nullable_to_non_nullable
as int,currentViewerCount: null == currentViewerCount ? _self.currentViewerCount : currentViewerCount // ignore: cast_nullable_to_non_nullable
as int,totalViewerCount: null == totalViewerCount ? _self.totalViewerCount : totalViewerCount // ignore: cast_nullable_to_non_nullable
as int,totalChatMessages: null == totalChatMessages ? _self.totalChatMessages : totalChatMessages // ignore: cast_nullable_to_non_nullable
as int,totalReactions: null == totalReactions ? _self.totalReactions : totalReactions // ignore: cast_nullable_to_non_nullable
as int,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as StreamCreatorDto?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as StreamGroupDto?,videoChannel: freezed == videoChannel ? _self.videoChannel : videoChannel // ignore: cast_nullable_to_non_nullable
as StreamChannelDto?,
  ));
}

/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreamCreatorDtoCopyWith<$Res>? get createdBy {
    if (_self.createdBy == null) {
    return null;
  }

  return $StreamCreatorDtoCopyWith<$Res>(_self.createdBy!, (value) {
    return _then(_self.copyWith(createdBy: value));
  });
}/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreamGroupDtoCopyWith<$Res>? get group {
    if (_self.group == null) {
    return null;
  }

  return $StreamGroupDtoCopyWith<$Res>(_self.group!, (value) {
    return _then(_self.copyWith(group: value));
  });
}/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreamChannelDtoCopyWith<$Res>? get videoChannel {
    if (_self.videoChannel == null) {
    return null;
  }

  return $StreamChannelDtoCopyWith<$Res>(_self.videoChannel!, (value) {
    return _then(_self.copyWith(videoChannel: value));
  });
}
}


/// @nodoc
mixin _$StreamKeyDto {

 String get channelId; String? get keyPrefix; String? get rtmpUrl;// Only present when regenerated — the full key shown once
 String? get rawKey;
/// Create a copy of StreamKeyDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamKeyDtoCopyWith<StreamKeyDto> get copyWith => _$StreamKeyDtoCopyWithImpl<StreamKeyDto>(this as StreamKeyDto, _$identity);

  /// Serializes this StreamKeyDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamKeyDto&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.keyPrefix, keyPrefix) || other.keyPrefix == keyPrefix)&&(identical(other.rtmpUrl, rtmpUrl) || other.rtmpUrl == rtmpUrl)&&(identical(other.rawKey, rawKey) || other.rawKey == rawKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,channelId,keyPrefix,rtmpUrl,rawKey);

@override
String toString() {
  return 'StreamKeyDto(channelId: $channelId, keyPrefix: $keyPrefix, rtmpUrl: $rtmpUrl, rawKey: $rawKey)';
}


}

/// @nodoc
abstract mixin class $StreamKeyDtoCopyWith<$Res>  {
  factory $StreamKeyDtoCopyWith(StreamKeyDto value, $Res Function(StreamKeyDto) _then) = _$StreamKeyDtoCopyWithImpl;
@useResult
$Res call({
 String channelId, String? keyPrefix, String? rtmpUrl, String? rawKey
});




}
/// @nodoc
class _$StreamKeyDtoCopyWithImpl<$Res>
    implements $StreamKeyDtoCopyWith<$Res> {
  _$StreamKeyDtoCopyWithImpl(this._self, this._then);

  final StreamKeyDto _self;
  final $Res Function(StreamKeyDto) _then;

/// Create a copy of StreamKeyDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channelId = null,Object? keyPrefix = freezed,Object? rtmpUrl = freezed,Object? rawKey = freezed,}) {
  return _then(_self.copyWith(
channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,keyPrefix: freezed == keyPrefix ? _self.keyPrefix : keyPrefix // ignore: cast_nullable_to_non_nullable
as String?,rtmpUrl: freezed == rtmpUrl ? _self.rtmpUrl : rtmpUrl // ignore: cast_nullable_to_non_nullable
as String?,rawKey: freezed == rawKey ? _self.rawKey : rawKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamKeyDto].
extension StreamKeyDtoPatterns on StreamKeyDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamKeyDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamKeyDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamKeyDto value)  $default,){
final _that = this;
switch (_that) {
case _StreamKeyDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamKeyDto value)?  $default,){
final _that = this;
switch (_that) {
case _StreamKeyDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String channelId,  String? keyPrefix,  String? rtmpUrl,  String? rawKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamKeyDto() when $default != null:
return $default(_that.channelId,_that.keyPrefix,_that.rtmpUrl,_that.rawKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String channelId,  String? keyPrefix,  String? rtmpUrl,  String? rawKey)  $default,) {final _that = this;
switch (_that) {
case _StreamKeyDto():
return $default(_that.channelId,_that.keyPrefix,_that.rtmpUrl,_that.rawKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String channelId,  String? keyPrefix,  String? rtmpUrl,  String? rawKey)?  $default,) {final _that = this;
switch (_that) {
case _StreamKeyDto() when $default != null:
return $default(_that.channelId,_that.keyPrefix,_that.rtmpUrl,_that.rawKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreamKeyDto implements StreamKeyDto {
  const _StreamKeyDto({required this.channelId, this.keyPrefix, this.rtmpUrl, this.rawKey});
  factory _StreamKeyDto.fromJson(Map<String, dynamic> json) => _$StreamKeyDtoFromJson(json);

@override final  String channelId;
@override final  String? keyPrefix;
@override final  String? rtmpUrl;
// Only present when regenerated — the full key shown once
@override final  String? rawKey;

/// Create a copy of StreamKeyDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamKeyDtoCopyWith<_StreamKeyDto> get copyWith => __$StreamKeyDtoCopyWithImpl<_StreamKeyDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreamKeyDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamKeyDto&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.keyPrefix, keyPrefix) || other.keyPrefix == keyPrefix)&&(identical(other.rtmpUrl, rtmpUrl) || other.rtmpUrl == rtmpUrl)&&(identical(other.rawKey, rawKey) || other.rawKey == rawKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,channelId,keyPrefix,rtmpUrl,rawKey);

@override
String toString() {
  return 'StreamKeyDto(channelId: $channelId, keyPrefix: $keyPrefix, rtmpUrl: $rtmpUrl, rawKey: $rawKey)';
}


}

/// @nodoc
abstract mixin class _$StreamKeyDtoCopyWith<$Res> implements $StreamKeyDtoCopyWith<$Res> {
  factory _$StreamKeyDtoCopyWith(_StreamKeyDto value, $Res Function(_StreamKeyDto) _then) = __$StreamKeyDtoCopyWithImpl;
@override @useResult
$Res call({
 String channelId, String? keyPrefix, String? rtmpUrl, String? rawKey
});




}
/// @nodoc
class __$StreamKeyDtoCopyWithImpl<$Res>
    implements _$StreamKeyDtoCopyWith<$Res> {
  __$StreamKeyDtoCopyWithImpl(this._self, this._then);

  final _StreamKeyDto _self;
  final $Res Function(_StreamKeyDto) _then;

/// Create a copy of StreamKeyDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channelId = null,Object? keyPrefix = freezed,Object? rtmpUrl = freezed,Object? rawKey = freezed,}) {
  return _then(_StreamKeyDto(
channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,keyPrefix: freezed == keyPrefix ? _self.keyPrefix : keyPrefix // ignore: cast_nullable_to_non_nullable
as String?,rtmpUrl: freezed == rtmpUrl ? _self.rtmpUrl : rtmpUrl // ignore: cast_nullable_to_non_nullable
as String?,rawKey: freezed == rawKey ? _self.rawKey : rawKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
