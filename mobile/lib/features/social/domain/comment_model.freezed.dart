// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentAuthorDto {

 String get id; String? get username; String? get displayName; String? get avatarUrl;
/// Create a copy of CommentAuthorDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentAuthorDtoCopyWith<CommentAuthorDto> get copyWith => _$CommentAuthorDtoCopyWithImpl<CommentAuthorDto>(this as CommentAuthorDto, _$identity);

  /// Serializes this CommentAuthorDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentAuthorDto&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl);

@override
String toString() {
  return 'CommentAuthorDto(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $CommentAuthorDtoCopyWith<$Res>  {
  factory $CommentAuthorDtoCopyWith(CommentAuthorDto value, $Res Function(CommentAuthorDto) _then) = _$CommentAuthorDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? username, String? displayName, String? avatarUrl
});




}
/// @nodoc
class _$CommentAuthorDtoCopyWithImpl<$Res>
    implements $CommentAuthorDtoCopyWith<$Res> {
  _$CommentAuthorDtoCopyWithImpl(this._self, this._then);

  final CommentAuthorDto _self;
  final $Res Function(CommentAuthorDto) _then;

/// Create a copy of CommentAuthorDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = freezed,Object? displayName = freezed,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentAuthorDto].
extension CommentAuthorDtoPatterns on CommentAuthorDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentAuthorDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentAuthorDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentAuthorDto value)  $default,){
final _that = this;
switch (_that) {
case _CommentAuthorDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentAuthorDto value)?  $default,){
final _that = this;
switch (_that) {
case _CommentAuthorDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? username,  String? displayName,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentAuthorDto() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? username,  String? displayName,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _CommentAuthorDto():
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? username,  String? displayName,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _CommentAuthorDto() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentAuthorDto implements CommentAuthorDto {
  const _CommentAuthorDto({required this.id, this.username, this.displayName, this.avatarUrl});
  factory _CommentAuthorDto.fromJson(Map<String, dynamic> json) => _$CommentAuthorDtoFromJson(json);

@override final  String id;
@override final  String? username;
@override final  String? displayName;
@override final  String? avatarUrl;

/// Create a copy of CommentAuthorDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentAuthorDtoCopyWith<_CommentAuthorDto> get copyWith => __$CommentAuthorDtoCopyWithImpl<_CommentAuthorDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentAuthorDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentAuthorDto&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl);

@override
String toString() {
  return 'CommentAuthorDto(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$CommentAuthorDtoCopyWith<$Res> implements $CommentAuthorDtoCopyWith<$Res> {
  factory _$CommentAuthorDtoCopyWith(_CommentAuthorDto value, $Res Function(_CommentAuthorDto) _then) = __$CommentAuthorDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? username, String? displayName, String? avatarUrl
});




}
/// @nodoc
class __$CommentAuthorDtoCopyWithImpl<$Res>
    implements _$CommentAuthorDtoCopyWith<$Res> {
  __$CommentAuthorDtoCopyWithImpl(this._self, this._then);

  final _CommentAuthorDto _self;
  final $Res Function(_CommentAuthorDto) _then;

/// Create a copy of CommentAuthorDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = freezed,Object? displayName = freezed,Object? avatarUrl = freezed,}) {
  return _then(_CommentAuthorDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CommentResponseDto {

 String get id; String get postId; String? get parentId; String get content; int get likesCount; CommentAuthorDto get author; DateTime get createdAt; List<CommentResponseDto> get replies;
/// Create a copy of CommentResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentResponseDtoCopyWith<CommentResponseDto> get copyWith => _$CommentResponseDtoCopyWithImpl<CommentResponseDto>(this as CommentResponseDto, _$identity);

  /// Serializes this CommentResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentResponseDto&&(identical(other.id, id) || other.id == id)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.content, content) || other.content == content)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.author, author) || other.author == author)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.replies, replies));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,postId,parentId,content,likesCount,author,createdAt,const DeepCollectionEquality().hash(replies));

@override
String toString() {
  return 'CommentResponseDto(id: $id, postId: $postId, parentId: $parentId, content: $content, likesCount: $likesCount, author: $author, createdAt: $createdAt, replies: $replies)';
}


}

/// @nodoc
abstract mixin class $CommentResponseDtoCopyWith<$Res>  {
  factory $CommentResponseDtoCopyWith(CommentResponseDto value, $Res Function(CommentResponseDto) _then) = _$CommentResponseDtoCopyWithImpl;
@useResult
$Res call({
 String id, String postId, String? parentId, String content, int likesCount, CommentAuthorDto author, DateTime createdAt, List<CommentResponseDto> replies
});


$CommentAuthorDtoCopyWith<$Res> get author;

}
/// @nodoc
class _$CommentResponseDtoCopyWithImpl<$Res>
    implements $CommentResponseDtoCopyWith<$Res> {
  _$CommentResponseDtoCopyWithImpl(this._self, this._then);

  final CommentResponseDto _self;
  final $Res Function(CommentResponseDto) _then;

/// Create a copy of CommentResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? postId = null,Object? parentId = freezed,Object? content = null,Object? likesCount = null,Object? author = null,Object? createdAt = null,Object? replies = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as CommentAuthorDto,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<CommentResponseDto>,
  ));
}
/// Create a copy of CommentResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentAuthorDtoCopyWith<$Res> get author {
  
  return $CommentAuthorDtoCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [CommentResponseDto].
extension CommentResponseDtoPatterns on CommentResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _CommentResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _CommentResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String postId,  String? parentId,  String content,  int likesCount,  CommentAuthorDto author,  DateTime createdAt,  List<CommentResponseDto> replies)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentResponseDto() when $default != null:
return $default(_that.id,_that.postId,_that.parentId,_that.content,_that.likesCount,_that.author,_that.createdAt,_that.replies);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String postId,  String? parentId,  String content,  int likesCount,  CommentAuthorDto author,  DateTime createdAt,  List<CommentResponseDto> replies)  $default,) {final _that = this;
switch (_that) {
case _CommentResponseDto():
return $default(_that.id,_that.postId,_that.parentId,_that.content,_that.likesCount,_that.author,_that.createdAt,_that.replies);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String postId,  String? parentId,  String content,  int likesCount,  CommentAuthorDto author,  DateTime createdAt,  List<CommentResponseDto> replies)?  $default,) {final _that = this;
switch (_that) {
case _CommentResponseDto() when $default != null:
return $default(_that.id,_that.postId,_that.parentId,_that.content,_that.likesCount,_that.author,_that.createdAt,_that.replies);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentResponseDto implements CommentResponseDto {
  const _CommentResponseDto({required this.id, required this.postId, this.parentId, required this.content, this.likesCount = 0, required this.author, required this.createdAt, final  List<CommentResponseDto> replies = const []}): _replies = replies;
  factory _CommentResponseDto.fromJson(Map<String, dynamic> json) => _$CommentResponseDtoFromJson(json);

@override final  String id;
@override final  String postId;
@override final  String? parentId;
@override final  String content;
@override@JsonKey() final  int likesCount;
@override final  CommentAuthorDto author;
@override final  DateTime createdAt;
 final  List<CommentResponseDto> _replies;
@override@JsonKey() List<CommentResponseDto> get replies {
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replies);
}


/// Create a copy of CommentResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentResponseDtoCopyWith<_CommentResponseDto> get copyWith => __$CommentResponseDtoCopyWithImpl<_CommentResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentResponseDto&&(identical(other.id, id) || other.id == id)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.content, content) || other.content == content)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.author, author) || other.author == author)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._replies, _replies));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,postId,parentId,content,likesCount,author,createdAt,const DeepCollectionEquality().hash(_replies));

@override
String toString() {
  return 'CommentResponseDto(id: $id, postId: $postId, parentId: $parentId, content: $content, likesCount: $likesCount, author: $author, createdAt: $createdAt, replies: $replies)';
}


}

/// @nodoc
abstract mixin class _$CommentResponseDtoCopyWith<$Res> implements $CommentResponseDtoCopyWith<$Res> {
  factory _$CommentResponseDtoCopyWith(_CommentResponseDto value, $Res Function(_CommentResponseDto) _then) = __$CommentResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String postId, String? parentId, String content, int likesCount, CommentAuthorDto author, DateTime createdAt, List<CommentResponseDto> replies
});


@override $CommentAuthorDtoCopyWith<$Res> get author;

}
/// @nodoc
class __$CommentResponseDtoCopyWithImpl<$Res>
    implements _$CommentResponseDtoCopyWith<$Res> {
  __$CommentResponseDtoCopyWithImpl(this._self, this._then);

  final _CommentResponseDto _self;
  final $Res Function(_CommentResponseDto) _then;

/// Create a copy of CommentResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? postId = null,Object? parentId = freezed,Object? content = null,Object? likesCount = null,Object? author = null,Object? createdAt = null,Object? replies = null,}) {
  return _then(_CommentResponseDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as CommentAuthorDto,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,replies: null == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<CommentResponseDto>,
  ));
}

/// Create a copy of CommentResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentAuthorDtoCopyWith<$Res> get author {
  
  return $CommentAuthorDtoCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}

// dart format on
