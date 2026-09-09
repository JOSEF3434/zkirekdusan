// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatSenderDto {

 String get id; String? get username; String? get displayName; String? get avatarUrl;
/// Create a copy of ChatSenderDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSenderDtoCopyWith<ChatSenderDto> get copyWith => _$ChatSenderDtoCopyWithImpl<ChatSenderDto>(this as ChatSenderDto, _$identity);

  /// Serializes this ChatSenderDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSenderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl);

@override
String toString() {
  return 'ChatSenderDto(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $ChatSenderDtoCopyWith<$Res>  {
  factory $ChatSenderDtoCopyWith(ChatSenderDto value, $Res Function(ChatSenderDto) _then) = _$ChatSenderDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? username, String? displayName, String? avatarUrl
});




}
/// @nodoc
class _$ChatSenderDtoCopyWithImpl<$Res>
    implements $ChatSenderDtoCopyWith<$Res> {
  _$ChatSenderDtoCopyWithImpl(this._self, this._then);

  final ChatSenderDto _self;
  final $Res Function(ChatSenderDto) _then;

/// Create a copy of ChatSenderDto
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


/// Adds pattern-matching-related methods to [ChatSenderDto].
extension ChatSenderDtoPatterns on ChatSenderDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatSenderDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatSenderDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatSenderDto value)  $default,){
final _that = this;
switch (_that) {
case _ChatSenderDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatSenderDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChatSenderDto() when $default != null:
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
case _ChatSenderDto() when $default != null:
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
case _ChatSenderDto():
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
case _ChatSenderDto() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatSenderDto implements ChatSenderDto {
  const _ChatSenderDto({required this.id, this.username, this.displayName, this.avatarUrl});
  factory _ChatSenderDto.fromJson(Map<String, dynamic> json) => _$ChatSenderDtoFromJson(json);

@override final  String id;
@override final  String? username;
@override final  String? displayName;
@override final  String? avatarUrl;

/// Create a copy of ChatSenderDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatSenderDtoCopyWith<_ChatSenderDto> get copyWith => __$ChatSenderDtoCopyWithImpl<_ChatSenderDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatSenderDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatSenderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl);

@override
String toString() {
  return 'ChatSenderDto(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$ChatSenderDtoCopyWith<$Res> implements $ChatSenderDtoCopyWith<$Res> {
  factory _$ChatSenderDtoCopyWith(_ChatSenderDto value, $Res Function(_ChatSenderDto) _then) = __$ChatSenderDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? username, String? displayName, String? avatarUrl
});




}
/// @nodoc
class __$ChatSenderDtoCopyWithImpl<$Res>
    implements _$ChatSenderDtoCopyWith<$Res> {
  __$ChatSenderDtoCopyWithImpl(this._self, this._then);

  final _ChatSenderDto _self;
  final $Res Function(_ChatSenderDto) _then;

/// Create a copy of ChatSenderDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = freezed,Object? displayName = freezed,Object? avatarUrl = freezed,}) {
  return _then(_ChatSenderDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChatMessageDto {

 String get id; String get content; ChatMessageType get type; bool get isPinned; bool get isDeleted; String get createdAt; ChatSenderDto? get sender;// Locally tracked send status (not from backend)
 bool get isPending; bool get isError;
/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageDtoCopyWith<ChatMessageDto> get copyWith => _$ChatMessageDtoCopyWithImpl<ChatMessageDto>(this as ChatMessageDto, _$identity);

  /// Serializes this ChatMessageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageDto&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.isPending, isPending) || other.isPending == isPending)&&(identical(other.isError, isError) || other.isError == isError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,type,isPinned,isDeleted,createdAt,sender,isPending,isError);

@override
String toString() {
  return 'ChatMessageDto(id: $id, content: $content, type: $type, isPinned: $isPinned, isDeleted: $isDeleted, createdAt: $createdAt, sender: $sender, isPending: $isPending, isError: $isError)';
}


}

/// @nodoc
abstract mixin class $ChatMessageDtoCopyWith<$Res>  {
  factory $ChatMessageDtoCopyWith(ChatMessageDto value, $Res Function(ChatMessageDto) _then) = _$ChatMessageDtoCopyWithImpl;
@useResult
$Res call({
 String id, String content, ChatMessageType type, bool isPinned, bool isDeleted, String createdAt, ChatSenderDto? sender, bool isPending, bool isError
});


$ChatSenderDtoCopyWith<$Res>? get sender;

}
/// @nodoc
class _$ChatMessageDtoCopyWithImpl<$Res>
    implements $ChatMessageDtoCopyWith<$Res> {
  _$ChatMessageDtoCopyWithImpl(this._self, this._then);

  final ChatMessageDto _self;
  final $Res Function(ChatMessageDto) _then;

/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = null,Object? type = null,Object? isPinned = null,Object? isDeleted = null,Object? createdAt = null,Object? sender = freezed,Object? isPending = null,Object? isError = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChatMessageType,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as ChatSenderDto?,isPending: null == isPending ? _self.isPending : isPending // ignore: cast_nullable_to_non_nullable
as bool,isError: null == isError ? _self.isError : isError // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatSenderDtoCopyWith<$Res>? get sender {
    if (_self.sender == null) {
    return null;
  }

  return $ChatSenderDtoCopyWith<$Res>(_self.sender!, (value) {
    return _then(_self.copyWith(sender: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatMessageDto].
extension ChatMessageDtoPatterns on ChatMessageDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageDto value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String content,  ChatMessageType type,  bool isPinned,  bool isDeleted,  String createdAt,  ChatSenderDto? sender,  bool isPending,  bool isError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
return $default(_that.id,_that.content,_that.type,_that.isPinned,_that.isDeleted,_that.createdAt,_that.sender,_that.isPending,_that.isError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String content,  ChatMessageType type,  bool isPinned,  bool isDeleted,  String createdAt,  ChatSenderDto? sender,  bool isPending,  bool isError)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageDto():
return $default(_that.id,_that.content,_that.type,_that.isPinned,_that.isDeleted,_that.createdAt,_that.sender,_that.isPending,_that.isError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String content,  ChatMessageType type,  bool isPinned,  bool isDeleted,  String createdAt,  ChatSenderDto? sender,  bool isPending,  bool isError)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
return $default(_that.id,_that.content,_that.type,_that.isPinned,_that.isDeleted,_that.createdAt,_that.sender,_that.isPending,_that.isError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessageDto implements ChatMessageDto {
  const _ChatMessageDto({required this.id, required this.content, this.type = ChatMessageType.text, this.isPinned = false, this.isDeleted = false, required this.createdAt, this.sender, this.isPending = false, this.isError = false});
  factory _ChatMessageDto.fromJson(Map<String, dynamic> json) => _$ChatMessageDtoFromJson(json);

@override final  String id;
@override final  String content;
@override@JsonKey() final  ChatMessageType type;
@override@JsonKey() final  bool isPinned;
@override@JsonKey() final  bool isDeleted;
@override final  String createdAt;
@override final  ChatSenderDto? sender;
// Locally tracked send status (not from backend)
@override@JsonKey() final  bool isPending;
@override@JsonKey() final  bool isError;

/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageDtoCopyWith<_ChatMessageDto> get copyWith => __$ChatMessageDtoCopyWithImpl<_ChatMessageDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageDto&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.isPending, isPending) || other.isPending == isPending)&&(identical(other.isError, isError) || other.isError == isError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,type,isPinned,isDeleted,createdAt,sender,isPending,isError);

@override
String toString() {
  return 'ChatMessageDto(id: $id, content: $content, type: $type, isPinned: $isPinned, isDeleted: $isDeleted, createdAt: $createdAt, sender: $sender, isPending: $isPending, isError: $isError)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageDtoCopyWith<$Res> implements $ChatMessageDtoCopyWith<$Res> {
  factory _$ChatMessageDtoCopyWith(_ChatMessageDto value, $Res Function(_ChatMessageDto) _then) = __$ChatMessageDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String content, ChatMessageType type, bool isPinned, bool isDeleted, String createdAt, ChatSenderDto? sender, bool isPending, bool isError
});


@override $ChatSenderDtoCopyWith<$Res>? get sender;

}
/// @nodoc
class __$ChatMessageDtoCopyWithImpl<$Res>
    implements _$ChatMessageDtoCopyWith<$Res> {
  __$ChatMessageDtoCopyWithImpl(this._self, this._then);

  final _ChatMessageDto _self;
  final $Res Function(_ChatMessageDto) _then;

/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,Object? type = null,Object? isPinned = null,Object? isDeleted = null,Object? createdAt = null,Object? sender = freezed,Object? isPending = null,Object? isError = null,}) {
  return _then(_ChatMessageDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChatMessageType,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as ChatSenderDto?,isPending: null == isPending ? _self.isPending : isPending // ignore: cast_nullable_to_non_nullable
as bool,isError: null == isError ? _self.isError : isError // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatSenderDtoCopyWith<$Res>? get sender {
    if (_self.sender == null) {
    return null;
  }

  return $ChatSenderDtoCopyWith<$Res>(_self.sender!, (value) {
    return _then(_self.copyWith(sender: value));
  });
}
}


/// @nodoc
mixin _$ChatReactionEvent {

 String get messageId; String get emoji; int get count; String get reactionId;
/// Create a copy of ChatReactionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatReactionEventCopyWith<ChatReactionEvent> get copyWith => _$ChatReactionEventCopyWithImpl<ChatReactionEvent>(this as ChatReactionEvent, _$identity);

  /// Serializes this ChatReactionEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatReactionEvent&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.count, count) || other.count == count)&&(identical(other.reactionId, reactionId) || other.reactionId == reactionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,emoji,count,reactionId);

@override
String toString() {
  return 'ChatReactionEvent(messageId: $messageId, emoji: $emoji, count: $count, reactionId: $reactionId)';
}


}

/// @nodoc
abstract mixin class $ChatReactionEventCopyWith<$Res>  {
  factory $ChatReactionEventCopyWith(ChatReactionEvent value, $Res Function(ChatReactionEvent) _then) = _$ChatReactionEventCopyWithImpl;
@useResult
$Res call({
 String messageId, String emoji, int count, String reactionId
});




}
/// @nodoc
class _$ChatReactionEventCopyWithImpl<$Res>
    implements $ChatReactionEventCopyWith<$Res> {
  _$ChatReactionEventCopyWithImpl(this._self, this._then);

  final ChatReactionEvent _self;
  final $Res Function(ChatReactionEvent) _then;

/// Create a copy of ChatReactionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? emoji = null,Object? count = null,Object? reactionId = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,reactionId: null == reactionId ? _self.reactionId : reactionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatReactionEvent].
extension ChatReactionEventPatterns on ChatReactionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatReactionEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatReactionEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatReactionEvent value)  $default,){
final _that = this;
switch (_that) {
case _ChatReactionEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatReactionEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ChatReactionEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String emoji,  int count,  String reactionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatReactionEvent() when $default != null:
return $default(_that.messageId,_that.emoji,_that.count,_that.reactionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String emoji,  int count,  String reactionId)  $default,) {final _that = this;
switch (_that) {
case _ChatReactionEvent():
return $default(_that.messageId,_that.emoji,_that.count,_that.reactionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String emoji,  int count,  String reactionId)?  $default,) {final _that = this;
switch (_that) {
case _ChatReactionEvent() when $default != null:
return $default(_that.messageId,_that.emoji,_that.count,_that.reactionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatReactionEvent implements ChatReactionEvent {
  const _ChatReactionEvent({required this.messageId, required this.emoji, required this.count, required this.reactionId});
  factory _ChatReactionEvent.fromJson(Map<String, dynamic> json) => _$ChatReactionEventFromJson(json);

@override final  String messageId;
@override final  String emoji;
@override final  int count;
@override final  String reactionId;

/// Create a copy of ChatReactionEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatReactionEventCopyWith<_ChatReactionEvent> get copyWith => __$ChatReactionEventCopyWithImpl<_ChatReactionEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatReactionEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatReactionEvent&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.count, count) || other.count == count)&&(identical(other.reactionId, reactionId) || other.reactionId == reactionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,emoji,count,reactionId);

@override
String toString() {
  return 'ChatReactionEvent(messageId: $messageId, emoji: $emoji, count: $count, reactionId: $reactionId)';
}


}

/// @nodoc
abstract mixin class _$ChatReactionEventCopyWith<$Res> implements $ChatReactionEventCopyWith<$Res> {
  factory _$ChatReactionEventCopyWith(_ChatReactionEvent value, $Res Function(_ChatReactionEvent) _then) = __$ChatReactionEventCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String emoji, int count, String reactionId
});




}
/// @nodoc
class __$ChatReactionEventCopyWithImpl<$Res>
    implements _$ChatReactionEventCopyWith<$Res> {
  __$ChatReactionEventCopyWithImpl(this._self, this._then);

  final _ChatReactionEvent _self;
  final $Res Function(_ChatReactionEvent) _then;

/// Create a copy of ChatReactionEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? emoji = null,Object? count = null,Object? reactionId = null,}) {
  return _then(_ChatReactionEvent(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,reactionId: null == reactionId ? _self.reactionId : reactionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChatHistoryResponse {

 List<ChatMessageDto> get messages; String? get nextCursor; bool get hasMore;
/// Create a copy of ChatHistoryResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatHistoryResponseCopyWith<ChatHistoryResponse> get copyWith => _$ChatHistoryResponseCopyWithImpl<ChatHistoryResponse>(this as ChatHistoryResponse, _$identity);

  /// Serializes this ChatHistoryResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatHistoryResponse&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(messages),nextCursor,hasMore);

@override
String toString() {
  return 'ChatHistoryResponse(messages: $messages, nextCursor: $nextCursor, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $ChatHistoryResponseCopyWith<$Res>  {
  factory $ChatHistoryResponseCopyWith(ChatHistoryResponse value, $Res Function(ChatHistoryResponse) _then) = _$ChatHistoryResponseCopyWithImpl;
@useResult
$Res call({
 List<ChatMessageDto> messages, String? nextCursor, bool hasMore
});




}
/// @nodoc
class _$ChatHistoryResponseCopyWithImpl<$Res>
    implements $ChatHistoryResponseCopyWith<$Res> {
  _$ChatHistoryResponseCopyWithImpl(this._self, this._then);

  final ChatHistoryResponse _self;
  final $Res Function(ChatHistoryResponse) _then;

/// Create a copy of ChatHistoryResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? nextCursor = freezed,Object? hasMore = null,}) {
  return _then(_self.copyWith(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessageDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatHistoryResponse].
extension ChatHistoryResponsePatterns on ChatHistoryResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatHistoryResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatHistoryResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatHistoryResponse value)  $default,){
final _that = this;
switch (_that) {
case _ChatHistoryResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatHistoryResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ChatHistoryResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ChatMessageDto> messages,  String? nextCursor,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatHistoryResponse() when $default != null:
return $default(_that.messages,_that.nextCursor,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ChatMessageDto> messages,  String? nextCursor,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _ChatHistoryResponse():
return $default(_that.messages,_that.nextCursor,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ChatMessageDto> messages,  String? nextCursor,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _ChatHistoryResponse() when $default != null:
return $default(_that.messages,_that.nextCursor,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatHistoryResponse implements ChatHistoryResponse {
  const _ChatHistoryResponse({required final  List<ChatMessageDto> messages, this.nextCursor, this.hasMore = false}): _messages = messages;
  factory _ChatHistoryResponse.fromJson(Map<String, dynamic> json) => _$ChatHistoryResponseFromJson(json);

 final  List<ChatMessageDto> _messages;
@override List<ChatMessageDto> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override final  String? nextCursor;
@override@JsonKey() final  bool hasMore;

/// Create a copy of ChatHistoryResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatHistoryResponseCopyWith<_ChatHistoryResponse> get copyWith => __$ChatHistoryResponseCopyWithImpl<_ChatHistoryResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatHistoryResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatHistoryResponse&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),nextCursor,hasMore);

@override
String toString() {
  return 'ChatHistoryResponse(messages: $messages, nextCursor: $nextCursor, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$ChatHistoryResponseCopyWith<$Res> implements $ChatHistoryResponseCopyWith<$Res> {
  factory _$ChatHistoryResponseCopyWith(_ChatHistoryResponse value, $Res Function(_ChatHistoryResponse) _then) = __$ChatHistoryResponseCopyWithImpl;
@override @useResult
$Res call({
 List<ChatMessageDto> messages, String? nextCursor, bool hasMore
});




}
/// @nodoc
class __$ChatHistoryResponseCopyWithImpl<$Res>
    implements _$ChatHistoryResponseCopyWith<$Res> {
  __$ChatHistoryResponseCopyWithImpl(this._self, this._then);

  final _ChatHistoryResponse _self;
  final $Res Function(_ChatHistoryResponse) _then;

/// Create a copy of ChatHistoryResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? nextCursor = freezed,Object? hasMore = null,}) {
  return _then(_ChatHistoryResponse(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessageDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
