// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConversationModel {

 String get id; String get type; String? get groupId; String? get channelId; String? get title; DateTime? get lastMessageAt; MessagePreviewModel? get lastMessage; List<ConversationMemberModel> get members; DateTime get createdAt; ConversationMetadataModel? get metadata;
/// Create a copy of ConversationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationModelCopyWith<ConversationModel> get copyWith => _$ConversationModelCopyWithImpl<ConversationModel>(this as ConversationModel, _$identity);

  /// Serializes this ConversationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.title, title) || other.title == title)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.metadata, metadata) || other.metadata == metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,groupId,channelId,title,lastMessageAt,lastMessage,const DeepCollectionEquality().hash(members),createdAt,metadata);

@override
String toString() {
  return 'ConversationModel(id: $id, type: $type, groupId: $groupId, channelId: $channelId, title: $title, lastMessageAt: $lastMessageAt, lastMessage: $lastMessage, members: $members, createdAt: $createdAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ConversationModelCopyWith<$Res>  {
  factory $ConversationModelCopyWith(ConversationModel value, $Res Function(ConversationModel) _then) = _$ConversationModelCopyWithImpl;
@useResult
$Res call({
 String id, String type, String? groupId, String? channelId, String? title, DateTime? lastMessageAt, MessagePreviewModel? lastMessage, List<ConversationMemberModel> members, DateTime createdAt, ConversationMetadataModel? metadata
});


$MessagePreviewModelCopyWith<$Res>? get lastMessage;$ConversationMetadataModelCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$ConversationModelCopyWithImpl<$Res>
    implements $ConversationModelCopyWith<$Res> {
  _$ConversationModelCopyWithImpl(this._self, this._then);

  final ConversationModel _self;
  final $Res Function(ConversationModel) _then;

/// Create a copy of ConversationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? groupId = freezed,Object? channelId = freezed,Object? title = freezed,Object? lastMessageAt = freezed,Object? lastMessage = freezed,Object? members = null,Object? createdAt = null,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,channelId: freezed == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as MessagePreviewModel?,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<ConversationMemberModel>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ConversationMetadataModel?,
  ));
}
/// Create a copy of ConversationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessagePreviewModelCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $MessagePreviewModelCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}/// Create a copy of ConversationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversationMetadataModelCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $ConversationMetadataModelCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversationModel].
extension ConversationModelPatterns on ConversationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationModel value)  $default,){
final _that = this;
switch (_that) {
case _ConversationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationModel value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String? groupId,  String? channelId,  String? title,  DateTime? lastMessageAt,  MessagePreviewModel? lastMessage,  List<ConversationMemberModel> members,  DateTime createdAt,  ConversationMetadataModel? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationModel() when $default != null:
return $default(_that.id,_that.type,_that.groupId,_that.channelId,_that.title,_that.lastMessageAt,_that.lastMessage,_that.members,_that.createdAt,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String? groupId,  String? channelId,  String? title,  DateTime? lastMessageAt,  MessagePreviewModel? lastMessage,  List<ConversationMemberModel> members,  DateTime createdAt,  ConversationMetadataModel? metadata)  $default,) {final _that = this;
switch (_that) {
case _ConversationModel():
return $default(_that.id,_that.type,_that.groupId,_that.channelId,_that.title,_that.lastMessageAt,_that.lastMessage,_that.members,_that.createdAt,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String? groupId,  String? channelId,  String? title,  DateTime? lastMessageAt,  MessagePreviewModel? lastMessage,  List<ConversationMemberModel> members,  DateTime createdAt,  ConversationMetadataModel? metadata)?  $default,) {final _that = this;
switch (_that) {
case _ConversationModel() when $default != null:
return $default(_that.id,_that.type,_that.groupId,_that.channelId,_that.title,_that.lastMessageAt,_that.lastMessage,_that.members,_that.createdAt,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationModel implements ConversationModel {
  const _ConversationModel({required this.id, required this.type, this.groupId, this.channelId, this.title, this.lastMessageAt, this.lastMessage, final  List<ConversationMemberModel> members = const [], required this.createdAt, this.metadata}): _members = members;
  factory _ConversationModel.fromJson(Map<String, dynamic> json) => _$ConversationModelFromJson(json);

@override final  String id;
@override final  String type;
@override final  String? groupId;
@override final  String? channelId;
@override final  String? title;
@override final  DateTime? lastMessageAt;
@override final  MessagePreviewModel? lastMessage;
 final  List<ConversationMemberModel> _members;
@override@JsonKey() List<ConversationMemberModel> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override final  DateTime createdAt;
@override final  ConversationMetadataModel? metadata;

/// Create a copy of ConversationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationModelCopyWith<_ConversationModel> get copyWith => __$ConversationModelCopyWithImpl<_ConversationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.title, title) || other.title == title)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&const DeepCollectionEquality().equals(other._members, _members)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.metadata, metadata) || other.metadata == metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,groupId,channelId,title,lastMessageAt,lastMessage,const DeepCollectionEquality().hash(_members),createdAt,metadata);

@override
String toString() {
  return 'ConversationModel(id: $id, type: $type, groupId: $groupId, channelId: $channelId, title: $title, lastMessageAt: $lastMessageAt, lastMessage: $lastMessage, members: $members, createdAt: $createdAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ConversationModelCopyWith<$Res> implements $ConversationModelCopyWith<$Res> {
  factory _$ConversationModelCopyWith(_ConversationModel value, $Res Function(_ConversationModel) _then) = __$ConversationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String? groupId, String? channelId, String? title, DateTime? lastMessageAt, MessagePreviewModel? lastMessage, List<ConversationMemberModel> members, DateTime createdAt, ConversationMetadataModel? metadata
});


@override $MessagePreviewModelCopyWith<$Res>? get lastMessage;@override $ConversationMetadataModelCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$ConversationModelCopyWithImpl<$Res>
    implements _$ConversationModelCopyWith<$Res> {
  __$ConversationModelCopyWithImpl(this._self, this._then);

  final _ConversationModel _self;
  final $Res Function(_ConversationModel) _then;

/// Create a copy of ConversationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? groupId = freezed,Object? channelId = freezed,Object? title = freezed,Object? lastMessageAt = freezed,Object? lastMessage = freezed,Object? members = null,Object? createdAt = null,Object? metadata = freezed,}) {
  return _then(_ConversationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,channelId: freezed == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as MessagePreviewModel?,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<ConversationMemberModel>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ConversationMetadataModel?,
  ));
}

/// Create a copy of ConversationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessagePreviewModelCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $MessagePreviewModelCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}/// Create a copy of ConversationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversationMetadataModelCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $ConversationMetadataModelCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// @nodoc
mixin _$ConversationMemberModel {

 String get userId; String get username; String? get displayName; String? get avatarUrl; int get unreadCount; bool get isMuted; bool get isPinned; bool get isOnline; String? get lastSeen; TypingStatusModel? get typingStatus;
/// Create a copy of ConversationMemberModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationMemberModelCopyWith<ConversationMemberModel> get copyWith => _$ConversationMemberModelCopyWithImpl<ConversationMemberModel>(this as ConversationMemberModel, _$identity);

  /// Serializes this ConversationMemberModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationMemberModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.typingStatus, typingStatus) || other.typingStatus == typingStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username,displayName,avatarUrl,unreadCount,isMuted,isPinned,isOnline,lastSeen,typingStatus);

@override
String toString() {
  return 'ConversationMemberModel(userId: $userId, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, unreadCount: $unreadCount, isMuted: $isMuted, isPinned: $isPinned, isOnline: $isOnline, lastSeen: $lastSeen, typingStatus: $typingStatus)';
}


}

/// @nodoc
abstract mixin class $ConversationMemberModelCopyWith<$Res>  {
  factory $ConversationMemberModelCopyWith(ConversationMemberModel value, $Res Function(ConversationMemberModel) _then) = _$ConversationMemberModelCopyWithImpl;
@useResult
$Res call({
 String userId, String username, String? displayName, String? avatarUrl, int unreadCount, bool isMuted, bool isPinned, bool isOnline, String? lastSeen, TypingStatusModel? typingStatus
});


$TypingStatusModelCopyWith<$Res>? get typingStatus;

}
/// @nodoc
class _$ConversationMemberModelCopyWithImpl<$Res>
    implements $ConversationMemberModelCopyWith<$Res> {
  _$ConversationMemberModelCopyWithImpl(this._self, this._then);

  final ConversationMemberModel _self;
  final $Res Function(ConversationMemberModel) _then;

/// Create a copy of ConversationMemberModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? username = null,Object? displayName = freezed,Object? avatarUrl = freezed,Object? unreadCount = null,Object? isMuted = null,Object? isPinned = null,Object? isOnline = null,Object? lastSeen = freezed,Object? typingStatus = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,typingStatus: freezed == typingStatus ? _self.typingStatus : typingStatus // ignore: cast_nullable_to_non_nullable
as TypingStatusModel?,
  ));
}
/// Create a copy of ConversationMemberModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypingStatusModelCopyWith<$Res>? get typingStatus {
    if (_self.typingStatus == null) {
    return null;
  }

  return $TypingStatusModelCopyWith<$Res>(_self.typingStatus!, (value) {
    return _then(_self.copyWith(typingStatus: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversationMemberModel].
extension ConversationMemberModelPatterns on ConversationMemberModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationMemberModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationMemberModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationMemberModel value)  $default,){
final _that = this;
switch (_that) {
case _ConversationMemberModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationMemberModel value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationMemberModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String username,  String? displayName,  String? avatarUrl,  int unreadCount,  bool isMuted,  bool isPinned,  bool isOnline,  String? lastSeen,  TypingStatusModel? typingStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationMemberModel() when $default != null:
return $default(_that.userId,_that.username,_that.displayName,_that.avatarUrl,_that.unreadCount,_that.isMuted,_that.isPinned,_that.isOnline,_that.lastSeen,_that.typingStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String username,  String? displayName,  String? avatarUrl,  int unreadCount,  bool isMuted,  bool isPinned,  bool isOnline,  String? lastSeen,  TypingStatusModel? typingStatus)  $default,) {final _that = this;
switch (_that) {
case _ConversationMemberModel():
return $default(_that.userId,_that.username,_that.displayName,_that.avatarUrl,_that.unreadCount,_that.isMuted,_that.isPinned,_that.isOnline,_that.lastSeen,_that.typingStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String username,  String? displayName,  String? avatarUrl,  int unreadCount,  bool isMuted,  bool isPinned,  bool isOnline,  String? lastSeen,  TypingStatusModel? typingStatus)?  $default,) {final _that = this;
switch (_that) {
case _ConversationMemberModel() when $default != null:
return $default(_that.userId,_that.username,_that.displayName,_that.avatarUrl,_that.unreadCount,_that.isMuted,_that.isPinned,_that.isOnline,_that.lastSeen,_that.typingStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationMemberModel implements ConversationMemberModel {
  const _ConversationMemberModel({required this.userId, required this.username, this.displayName, this.avatarUrl, this.unreadCount = 0, this.isMuted = false, this.isPinned = false, this.isOnline = false, this.lastSeen, this.typingStatus});
  factory _ConversationMemberModel.fromJson(Map<String, dynamic> json) => _$ConversationMemberModelFromJson(json);

@override final  String userId;
@override final  String username;
@override final  String? displayName;
@override final  String? avatarUrl;
@override@JsonKey() final  int unreadCount;
@override@JsonKey() final  bool isMuted;
@override@JsonKey() final  bool isPinned;
@override@JsonKey() final  bool isOnline;
@override final  String? lastSeen;
@override final  TypingStatusModel? typingStatus;

/// Create a copy of ConversationMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationMemberModelCopyWith<_ConversationMemberModel> get copyWith => __$ConversationMemberModelCopyWithImpl<_ConversationMemberModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationMemberModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationMemberModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.typingStatus, typingStatus) || other.typingStatus == typingStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username,displayName,avatarUrl,unreadCount,isMuted,isPinned,isOnline,lastSeen,typingStatus);

@override
String toString() {
  return 'ConversationMemberModel(userId: $userId, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, unreadCount: $unreadCount, isMuted: $isMuted, isPinned: $isPinned, isOnline: $isOnline, lastSeen: $lastSeen, typingStatus: $typingStatus)';
}


}

/// @nodoc
abstract mixin class _$ConversationMemberModelCopyWith<$Res> implements $ConversationMemberModelCopyWith<$Res> {
  factory _$ConversationMemberModelCopyWith(_ConversationMemberModel value, $Res Function(_ConversationMemberModel) _then) = __$ConversationMemberModelCopyWithImpl;
@override @useResult
$Res call({
 String userId, String username, String? displayName, String? avatarUrl, int unreadCount, bool isMuted, bool isPinned, bool isOnline, String? lastSeen, TypingStatusModel? typingStatus
});


@override $TypingStatusModelCopyWith<$Res>? get typingStatus;

}
/// @nodoc
class __$ConversationMemberModelCopyWithImpl<$Res>
    implements _$ConversationMemberModelCopyWith<$Res> {
  __$ConversationMemberModelCopyWithImpl(this._self, this._then);

  final _ConversationMemberModel _self;
  final $Res Function(_ConversationMemberModel) _then;

/// Create a copy of ConversationMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? username = null,Object? displayName = freezed,Object? avatarUrl = freezed,Object? unreadCount = null,Object? isMuted = null,Object? isPinned = null,Object? isOnline = null,Object? lastSeen = freezed,Object? typingStatus = freezed,}) {
  return _then(_ConversationMemberModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,typingStatus: freezed == typingStatus ? _self.typingStatus : typingStatus // ignore: cast_nullable_to_non_nullable
as TypingStatusModel?,
  ));
}

/// Create a copy of ConversationMemberModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypingStatusModelCopyWith<$Res>? get typingStatus {
    if (_self.typingStatus == null) {
    return null;
  }

  return $TypingStatusModelCopyWith<$Res>(_self.typingStatus!, (value) {
    return _then(_self.copyWith(typingStatus: value));
  });
}
}


/// @nodoc
mixin _$MessagePreviewModel {

 String get id; String? get content; String get type; String? get senderName; bool? get isMe; String? get attachmentPreview;
/// Create a copy of MessagePreviewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessagePreviewModelCopyWith<MessagePreviewModel> get copyWith => _$MessagePreviewModelCopyWithImpl<MessagePreviewModel>(this as MessagePreviewModel, _$identity);

  /// Serializes this MessagePreviewModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessagePreviewModel&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.isMe, isMe) || other.isMe == isMe)&&(identical(other.attachmentPreview, attachmentPreview) || other.attachmentPreview == attachmentPreview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,type,senderName,isMe,attachmentPreview);

@override
String toString() {
  return 'MessagePreviewModel(id: $id, content: $content, type: $type, senderName: $senderName, isMe: $isMe, attachmentPreview: $attachmentPreview)';
}


}

/// @nodoc
abstract mixin class $MessagePreviewModelCopyWith<$Res>  {
  factory $MessagePreviewModelCopyWith(MessagePreviewModel value, $Res Function(MessagePreviewModel) _then) = _$MessagePreviewModelCopyWithImpl;
@useResult
$Res call({
 String id, String? content, String type, String? senderName, bool? isMe, String? attachmentPreview
});




}
/// @nodoc
class _$MessagePreviewModelCopyWithImpl<$Res>
    implements $MessagePreviewModelCopyWith<$Res> {
  _$MessagePreviewModelCopyWithImpl(this._self, this._then);

  final MessagePreviewModel _self;
  final $Res Function(MessagePreviewModel) _then;

/// Create a copy of MessagePreviewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = freezed,Object? type = null,Object? senderName = freezed,Object? isMe = freezed,Object? attachmentPreview = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,senderName: freezed == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String?,isMe: freezed == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool?,attachmentPreview: freezed == attachmentPreview ? _self.attachmentPreview : attachmentPreview // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessagePreviewModel].
extension MessagePreviewModelPatterns on MessagePreviewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessagePreviewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessagePreviewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessagePreviewModel value)  $default,){
final _that = this;
switch (_that) {
case _MessagePreviewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessagePreviewModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessagePreviewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? content,  String type,  String? senderName,  bool? isMe,  String? attachmentPreview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessagePreviewModel() when $default != null:
return $default(_that.id,_that.content,_that.type,_that.senderName,_that.isMe,_that.attachmentPreview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? content,  String type,  String? senderName,  bool? isMe,  String? attachmentPreview)  $default,) {final _that = this;
switch (_that) {
case _MessagePreviewModel():
return $default(_that.id,_that.content,_that.type,_that.senderName,_that.isMe,_that.attachmentPreview);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? content,  String type,  String? senderName,  bool? isMe,  String? attachmentPreview)?  $default,) {final _that = this;
switch (_that) {
case _MessagePreviewModel() when $default != null:
return $default(_that.id,_that.content,_that.type,_that.senderName,_that.isMe,_that.attachmentPreview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessagePreviewModel implements MessagePreviewModel {
  const _MessagePreviewModel({required this.id, this.content, required this.type, this.senderName, this.isMe, this.attachmentPreview});
  factory _MessagePreviewModel.fromJson(Map<String, dynamic> json) => _$MessagePreviewModelFromJson(json);

@override final  String id;
@override final  String? content;
@override final  String type;
@override final  String? senderName;
@override final  bool? isMe;
@override final  String? attachmentPreview;

/// Create a copy of MessagePreviewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessagePreviewModelCopyWith<_MessagePreviewModel> get copyWith => __$MessagePreviewModelCopyWithImpl<_MessagePreviewModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessagePreviewModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessagePreviewModel&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.isMe, isMe) || other.isMe == isMe)&&(identical(other.attachmentPreview, attachmentPreview) || other.attachmentPreview == attachmentPreview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,type,senderName,isMe,attachmentPreview);

@override
String toString() {
  return 'MessagePreviewModel(id: $id, content: $content, type: $type, senderName: $senderName, isMe: $isMe, attachmentPreview: $attachmentPreview)';
}


}

/// @nodoc
abstract mixin class _$MessagePreviewModelCopyWith<$Res> implements $MessagePreviewModelCopyWith<$Res> {
  factory _$MessagePreviewModelCopyWith(_MessagePreviewModel value, $Res Function(_MessagePreviewModel) _then) = __$MessagePreviewModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? content, String type, String? senderName, bool? isMe, String? attachmentPreview
});




}
/// @nodoc
class __$MessagePreviewModelCopyWithImpl<$Res>
    implements _$MessagePreviewModelCopyWith<$Res> {
  __$MessagePreviewModelCopyWithImpl(this._self, this._then);

  final _MessagePreviewModel _self;
  final $Res Function(_MessagePreviewModel) _then;

/// Create a copy of MessagePreviewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = freezed,Object? type = null,Object? senderName = freezed,Object? isMe = freezed,Object? attachmentPreview = freezed,}) {
  return _then(_MessagePreviewModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,senderName: freezed == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String?,isMe: freezed == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool?,attachmentPreview: freezed == attachmentPreview ? _self.attachmentPreview : attachmentPreview // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ConversationMetadataModel {

 String? get groupName; String? get groupAvatar; int? get memberCount; bool? get isVerified; String? get channelName; String? get description;
/// Create a copy of ConversationMetadataModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationMetadataModelCopyWith<ConversationMetadataModel> get copyWith => _$ConversationMetadataModelCopyWithImpl<ConversationMetadataModel>(this as ConversationMetadataModel, _$identity);

  /// Serializes this ConversationMetadataModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationMetadataModel&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.groupAvatar, groupAvatar) || other.groupAvatar == groupAvatar)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupName,groupAvatar,memberCount,isVerified,channelName,description);

@override
String toString() {
  return 'ConversationMetadataModel(groupName: $groupName, groupAvatar: $groupAvatar, memberCount: $memberCount, isVerified: $isVerified, channelName: $channelName, description: $description)';
}


}

/// @nodoc
abstract mixin class $ConversationMetadataModelCopyWith<$Res>  {
  factory $ConversationMetadataModelCopyWith(ConversationMetadataModel value, $Res Function(ConversationMetadataModel) _then) = _$ConversationMetadataModelCopyWithImpl;
@useResult
$Res call({
 String? groupName, String? groupAvatar, int? memberCount, bool? isVerified, String? channelName, String? description
});




}
/// @nodoc
class _$ConversationMetadataModelCopyWithImpl<$Res>
    implements $ConversationMetadataModelCopyWith<$Res> {
  _$ConversationMetadataModelCopyWithImpl(this._self, this._then);

  final ConversationMetadataModel _self;
  final $Res Function(ConversationMetadataModel) _then;

/// Create a copy of ConversationMetadataModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupName = freezed,Object? groupAvatar = freezed,Object? memberCount = freezed,Object? isVerified = freezed,Object? channelName = freezed,Object? description = freezed,}) {
  return _then(_self.copyWith(
groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,groupAvatar: freezed == groupAvatar ? _self.groupAvatar : groupAvatar // ignore: cast_nullable_to_non_nullable
as String?,memberCount: freezed == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int?,isVerified: freezed == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool?,channelName: freezed == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationMetadataModel].
extension ConversationMetadataModelPatterns on ConversationMetadataModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationMetadataModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationMetadataModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationMetadataModel value)  $default,){
final _that = this;
switch (_that) {
case _ConversationMetadataModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationMetadataModel value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationMetadataModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? groupName,  String? groupAvatar,  int? memberCount,  bool? isVerified,  String? channelName,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationMetadataModel() when $default != null:
return $default(_that.groupName,_that.groupAvatar,_that.memberCount,_that.isVerified,_that.channelName,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? groupName,  String? groupAvatar,  int? memberCount,  bool? isVerified,  String? channelName,  String? description)  $default,) {final _that = this;
switch (_that) {
case _ConversationMetadataModel():
return $default(_that.groupName,_that.groupAvatar,_that.memberCount,_that.isVerified,_that.channelName,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? groupName,  String? groupAvatar,  int? memberCount,  bool? isVerified,  String? channelName,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _ConversationMetadataModel() when $default != null:
return $default(_that.groupName,_that.groupAvatar,_that.memberCount,_that.isVerified,_that.channelName,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationMetadataModel implements ConversationMetadataModel {
  const _ConversationMetadataModel({this.groupName, this.groupAvatar, this.memberCount, this.isVerified, this.channelName, this.description});
  factory _ConversationMetadataModel.fromJson(Map<String, dynamic> json) => _$ConversationMetadataModelFromJson(json);

@override final  String? groupName;
@override final  String? groupAvatar;
@override final  int? memberCount;
@override final  bool? isVerified;
@override final  String? channelName;
@override final  String? description;

/// Create a copy of ConversationMetadataModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationMetadataModelCopyWith<_ConversationMetadataModel> get copyWith => __$ConversationMetadataModelCopyWithImpl<_ConversationMetadataModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationMetadataModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationMetadataModel&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.groupAvatar, groupAvatar) || other.groupAvatar == groupAvatar)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupName,groupAvatar,memberCount,isVerified,channelName,description);

@override
String toString() {
  return 'ConversationMetadataModel(groupName: $groupName, groupAvatar: $groupAvatar, memberCount: $memberCount, isVerified: $isVerified, channelName: $channelName, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ConversationMetadataModelCopyWith<$Res> implements $ConversationMetadataModelCopyWith<$Res> {
  factory _$ConversationMetadataModelCopyWith(_ConversationMetadataModel value, $Res Function(_ConversationMetadataModel) _then) = __$ConversationMetadataModelCopyWithImpl;
@override @useResult
$Res call({
 String? groupName, String? groupAvatar, int? memberCount, bool? isVerified, String? channelName, String? description
});




}
/// @nodoc
class __$ConversationMetadataModelCopyWithImpl<$Res>
    implements _$ConversationMetadataModelCopyWith<$Res> {
  __$ConversationMetadataModelCopyWithImpl(this._self, this._then);

  final _ConversationMetadataModel _self;
  final $Res Function(_ConversationMetadataModel) _then;

/// Create a copy of ConversationMetadataModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupName = freezed,Object? groupAvatar = freezed,Object? memberCount = freezed,Object? isVerified = freezed,Object? channelName = freezed,Object? description = freezed,}) {
  return _then(_ConversationMetadataModel(
groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,groupAvatar: freezed == groupAvatar ? _self.groupAvatar : groupAvatar // ignore: cast_nullable_to_non_nullable
as String?,memberCount: freezed == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int?,isVerified: freezed == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool?,channelName: freezed == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TypingStatusModel {

 bool get isTyping; DateTime? get startedAt;
/// Create a copy of TypingStatusModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypingStatusModelCopyWith<TypingStatusModel> get copyWith => _$TypingStatusModelCopyWithImpl<TypingStatusModel>(this as TypingStatusModel, _$identity);

  /// Serializes this TypingStatusModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypingStatusModel&&(identical(other.isTyping, isTyping) || other.isTyping == isTyping)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isTyping,startedAt);

@override
String toString() {
  return 'TypingStatusModel(isTyping: $isTyping, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class $TypingStatusModelCopyWith<$Res>  {
  factory $TypingStatusModelCopyWith(TypingStatusModel value, $Res Function(TypingStatusModel) _then) = _$TypingStatusModelCopyWithImpl;
@useResult
$Res call({
 bool isTyping, DateTime? startedAt
});




}
/// @nodoc
class _$TypingStatusModelCopyWithImpl<$Res>
    implements $TypingStatusModelCopyWith<$Res> {
  _$TypingStatusModelCopyWithImpl(this._self, this._then);

  final TypingStatusModel _self;
  final $Res Function(TypingStatusModel) _then;

/// Create a copy of TypingStatusModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isTyping = null,Object? startedAt = freezed,}) {
  return _then(_self.copyWith(
isTyping: null == isTyping ? _self.isTyping : isTyping // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TypingStatusModel].
extension TypingStatusModelPatterns on TypingStatusModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypingStatusModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypingStatusModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypingStatusModel value)  $default,){
final _that = this;
switch (_that) {
case _TypingStatusModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypingStatusModel value)?  $default,){
final _that = this;
switch (_that) {
case _TypingStatusModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isTyping,  DateTime? startedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypingStatusModel() when $default != null:
return $default(_that.isTyping,_that.startedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isTyping,  DateTime? startedAt)  $default,) {final _that = this;
switch (_that) {
case _TypingStatusModel():
return $default(_that.isTyping,_that.startedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isTyping,  DateTime? startedAt)?  $default,) {final _that = this;
switch (_that) {
case _TypingStatusModel() when $default != null:
return $default(_that.isTyping,_that.startedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TypingStatusModel implements TypingStatusModel {
  const _TypingStatusModel({required this.isTyping, this.startedAt});
  factory _TypingStatusModel.fromJson(Map<String, dynamic> json) => _$TypingStatusModelFromJson(json);

@override final  bool isTyping;
@override final  DateTime? startedAt;

/// Create a copy of TypingStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypingStatusModelCopyWith<_TypingStatusModel> get copyWith => __$TypingStatusModelCopyWithImpl<_TypingStatusModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TypingStatusModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypingStatusModel&&(identical(other.isTyping, isTyping) || other.isTyping == isTyping)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isTyping,startedAt);

@override
String toString() {
  return 'TypingStatusModel(isTyping: $isTyping, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class _$TypingStatusModelCopyWith<$Res> implements $TypingStatusModelCopyWith<$Res> {
  factory _$TypingStatusModelCopyWith(_TypingStatusModel value, $Res Function(_TypingStatusModel) _then) = __$TypingStatusModelCopyWithImpl;
@override @useResult
$Res call({
 bool isTyping, DateTime? startedAt
});




}
/// @nodoc
class __$TypingStatusModelCopyWithImpl<$Res>
    implements _$TypingStatusModelCopyWith<$Res> {
  __$TypingStatusModelCopyWithImpl(this._self, this._then);

  final _TypingStatusModel _self;
  final $Res Function(_TypingStatusModel) _then;

/// Create a copy of TypingStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isTyping = null,Object? startedAt = freezed,}) {
  return _then(_TypingStatusModel(
isTyping: null == isTyping ? _self.isTyping : isTyping // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
