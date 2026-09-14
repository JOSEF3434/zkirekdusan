// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageModel {

 String get id; String get conversationId; String? get channelId; MessageSenderModel get sender; String? get content; String get type; String? get replyToId; MessageReplyModel? get replyTo; bool get isEdited; bool get isPinned; List<MessageAttachmentModel> get attachments; List<MessageReactionModel> get reactions; List<String> get readBy; List<String> get deliveredTo; MessageVoiceNoteModel? get voiceNote; MessageForwardModel? get forward; List<String> get mentions; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageModelCopyWith<MessageModel> get copyWith => _$MessageModelCopyWithImpl<MessageModel>(this as MessageModel, _$identity);

  /// Serializes this MessageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.replyTo, replyTo) || other.replyTo == replyTo)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&const DeepCollectionEquality().equals(other.reactions, reactions)&&const DeepCollectionEquality().equals(other.readBy, readBy)&&const DeepCollectionEquality().equals(other.deliveredTo, deliveredTo)&&(identical(other.voiceNote, voiceNote) || other.voiceNote == voiceNote)&&(identical(other.forward, forward) || other.forward == forward)&&const DeepCollectionEquality().equals(other.mentions, mentions)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,conversationId,channelId,sender,content,type,replyToId,replyTo,isEdited,isPinned,const DeepCollectionEquality().hash(attachments),const DeepCollectionEquality().hash(reactions),const DeepCollectionEquality().hash(readBy),const DeepCollectionEquality().hash(deliveredTo),voiceNote,forward,const DeepCollectionEquality().hash(mentions),createdAt,updatedAt]);

@override
String toString() {
  return 'MessageModel(id: $id, conversationId: $conversationId, channelId: $channelId, sender: $sender, content: $content, type: $type, replyToId: $replyToId, replyTo: $replyTo, isEdited: $isEdited, isPinned: $isPinned, attachments: $attachments, reactions: $reactions, readBy: $readBy, deliveredTo: $deliveredTo, voiceNote: $voiceNote, forward: $forward, mentions: $mentions, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MessageModelCopyWith<$Res>  {
  factory $MessageModelCopyWith(MessageModel value, $Res Function(MessageModel) _then) = _$MessageModelCopyWithImpl;
@useResult
$Res call({
 String id, String conversationId, String? channelId, MessageSenderModel sender, String? content, String type, String? replyToId, MessageReplyModel? replyTo, bool isEdited, bool isPinned, List<MessageAttachmentModel> attachments, List<MessageReactionModel> reactions, List<String> readBy, List<String> deliveredTo, MessageVoiceNoteModel? voiceNote, MessageForwardModel? forward, List<String> mentions, DateTime createdAt, DateTime updatedAt
});


$MessageSenderModelCopyWith<$Res> get sender;$MessageReplyModelCopyWith<$Res>? get replyTo;$MessageVoiceNoteModelCopyWith<$Res>? get voiceNote;$MessageForwardModelCopyWith<$Res>? get forward;

}
/// @nodoc
class _$MessageModelCopyWithImpl<$Res>
    implements $MessageModelCopyWith<$Res> {
  _$MessageModelCopyWithImpl(this._self, this._then);

  final MessageModel _self;
  final $Res Function(MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = null,Object? channelId = freezed,Object? sender = null,Object? content = freezed,Object? type = null,Object? replyToId = freezed,Object? replyTo = freezed,Object? isEdited = null,Object? isPinned = null,Object? attachments = null,Object? reactions = null,Object? readBy = null,Object? deliveredTo = null,Object? voiceNote = freezed,Object? forward = freezed,Object? mentions = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,channelId: freezed == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String?,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as MessageSenderModel,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,replyTo: freezed == replyTo ? _self.replyTo : replyTo // ignore: cast_nullable_to_non_nullable
as MessageReplyModel?,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachmentModel>,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<MessageReactionModel>,readBy: null == readBy ? _self.readBy : readBy // ignore: cast_nullable_to_non_nullable
as List<String>,deliveredTo: null == deliveredTo ? _self.deliveredTo : deliveredTo // ignore: cast_nullable_to_non_nullable
as List<String>,voiceNote: freezed == voiceNote ? _self.voiceNote : voiceNote // ignore: cast_nullable_to_non_nullable
as MessageVoiceNoteModel?,forward: freezed == forward ? _self.forward : forward // ignore: cast_nullable_to_non_nullable
as MessageForwardModel?,mentions: null == mentions ? _self.mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageSenderModelCopyWith<$Res> get sender {
  
  return $MessageSenderModelCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageReplyModelCopyWith<$Res>? get replyTo {
    if (_self.replyTo == null) {
    return null;
  }

  return $MessageReplyModelCopyWith<$Res>(_self.replyTo!, (value) {
    return _then(_self.copyWith(replyTo: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageVoiceNoteModelCopyWith<$Res>? get voiceNote {
    if (_self.voiceNote == null) {
    return null;
  }

  return $MessageVoiceNoteModelCopyWith<$Res>(_self.voiceNote!, (value) {
    return _then(_self.copyWith(voiceNote: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageForwardModelCopyWith<$Res>? get forward {
    if (_self.forward == null) {
    return null;
  }

  return $MessageForwardModelCopyWith<$Res>(_self.forward!, (value) {
    return _then(_self.copyWith(forward: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessageModel].
extension MessageModelPatterns on MessageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String conversationId,  String? channelId,  MessageSenderModel sender,  String? content,  String type,  String? replyToId,  MessageReplyModel? replyTo,  bool isEdited,  bool isPinned,  List<MessageAttachmentModel> attachments,  List<MessageReactionModel> reactions,  List<String> readBy,  List<String> deliveredTo,  MessageVoiceNoteModel? voiceNote,  MessageForwardModel? forward,  List<String> mentions,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.conversationId,_that.channelId,_that.sender,_that.content,_that.type,_that.replyToId,_that.replyTo,_that.isEdited,_that.isPinned,_that.attachments,_that.reactions,_that.readBy,_that.deliveredTo,_that.voiceNote,_that.forward,_that.mentions,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String conversationId,  String? channelId,  MessageSenderModel sender,  String? content,  String type,  String? replyToId,  MessageReplyModel? replyTo,  bool isEdited,  bool isPinned,  List<MessageAttachmentModel> attachments,  List<MessageReactionModel> reactions,  List<String> readBy,  List<String> deliveredTo,  MessageVoiceNoteModel? voiceNote,  MessageForwardModel? forward,  List<String> mentions,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MessageModel():
return $default(_that.id,_that.conversationId,_that.channelId,_that.sender,_that.content,_that.type,_that.replyToId,_that.replyTo,_that.isEdited,_that.isPinned,_that.attachments,_that.reactions,_that.readBy,_that.deliveredTo,_that.voiceNote,_that.forward,_that.mentions,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String conversationId,  String? channelId,  MessageSenderModel sender,  String? content,  String type,  String? replyToId,  MessageReplyModel? replyTo,  bool isEdited,  bool isPinned,  List<MessageAttachmentModel> attachments,  List<MessageReactionModel> reactions,  List<String> readBy,  List<String> deliveredTo,  MessageVoiceNoteModel? voiceNote,  MessageForwardModel? forward,  List<String> mentions,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.conversationId,_that.channelId,_that.sender,_that.content,_that.type,_that.replyToId,_that.replyTo,_that.isEdited,_that.isPinned,_that.attachments,_that.reactions,_that.readBy,_that.deliveredTo,_that.voiceNote,_that.forward,_that.mentions,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageModel implements MessageModel {
  const _MessageModel({required this.id, required this.conversationId, this.channelId, required this.sender, this.content, required this.type, this.replyToId, this.replyTo, this.isEdited = false, this.isPinned = false, final  List<MessageAttachmentModel> attachments = const [], final  List<MessageReactionModel> reactions = const [], final  List<String> readBy = const [], final  List<String> deliveredTo = const [], this.voiceNote, this.forward, final  List<String> mentions = const [], required this.createdAt, required this.updatedAt}): _attachments = attachments,_reactions = reactions,_readBy = readBy,_deliveredTo = deliveredTo,_mentions = mentions;
  factory _MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);

@override final  String id;
@override final  String conversationId;
@override final  String? channelId;
@override final  MessageSenderModel sender;
@override final  String? content;
@override final  String type;
@override final  String? replyToId;
@override final  MessageReplyModel? replyTo;
@override@JsonKey() final  bool isEdited;
@override@JsonKey() final  bool isPinned;
 final  List<MessageAttachmentModel> _attachments;
@override@JsonKey() List<MessageAttachmentModel> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

 final  List<MessageReactionModel> _reactions;
@override@JsonKey() List<MessageReactionModel> get reactions {
  if (_reactions is EqualUnmodifiableListView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reactions);
}

 final  List<String> _readBy;
@override@JsonKey() List<String> get readBy {
  if (_readBy is EqualUnmodifiableListView) return _readBy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readBy);
}

 final  List<String> _deliveredTo;
@override@JsonKey() List<String> get deliveredTo {
  if (_deliveredTo is EqualUnmodifiableListView) return _deliveredTo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveredTo);
}

@override final  MessageVoiceNoteModel? voiceNote;
@override final  MessageForwardModel? forward;
 final  List<String> _mentions;
@override@JsonKey() List<String> get mentions {
  if (_mentions is EqualUnmodifiableListView) return _mentions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mentions);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageModelCopyWith<_MessageModel> get copyWith => __$MessageModelCopyWithImpl<_MessageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.replyTo, replyTo) || other.replyTo == replyTo)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&const DeepCollectionEquality().equals(other._reactions, _reactions)&&const DeepCollectionEquality().equals(other._readBy, _readBy)&&const DeepCollectionEquality().equals(other._deliveredTo, _deliveredTo)&&(identical(other.voiceNote, voiceNote) || other.voiceNote == voiceNote)&&(identical(other.forward, forward) || other.forward == forward)&&const DeepCollectionEquality().equals(other._mentions, _mentions)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,conversationId,channelId,sender,content,type,replyToId,replyTo,isEdited,isPinned,const DeepCollectionEquality().hash(_attachments),const DeepCollectionEquality().hash(_reactions),const DeepCollectionEquality().hash(_readBy),const DeepCollectionEquality().hash(_deliveredTo),voiceNote,forward,const DeepCollectionEquality().hash(_mentions),createdAt,updatedAt]);

@override
String toString() {
  return 'MessageModel(id: $id, conversationId: $conversationId, channelId: $channelId, sender: $sender, content: $content, type: $type, replyToId: $replyToId, replyTo: $replyTo, isEdited: $isEdited, isPinned: $isPinned, attachments: $attachments, reactions: $reactions, readBy: $readBy, deliveredTo: $deliveredTo, voiceNote: $voiceNote, forward: $forward, mentions: $mentions, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageModelCopyWith<$Res> implements $MessageModelCopyWith<$Res> {
  factory _$MessageModelCopyWith(_MessageModel value, $Res Function(_MessageModel) _then) = __$MessageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String conversationId, String? channelId, MessageSenderModel sender, String? content, String type, String? replyToId, MessageReplyModel? replyTo, bool isEdited, bool isPinned, List<MessageAttachmentModel> attachments, List<MessageReactionModel> reactions, List<String> readBy, List<String> deliveredTo, MessageVoiceNoteModel? voiceNote, MessageForwardModel? forward, List<String> mentions, DateTime createdAt, DateTime updatedAt
});


@override $MessageSenderModelCopyWith<$Res> get sender;@override $MessageReplyModelCopyWith<$Res>? get replyTo;@override $MessageVoiceNoteModelCopyWith<$Res>? get voiceNote;@override $MessageForwardModelCopyWith<$Res>? get forward;

}
/// @nodoc
class __$MessageModelCopyWithImpl<$Res>
    implements _$MessageModelCopyWith<$Res> {
  __$MessageModelCopyWithImpl(this._self, this._then);

  final _MessageModel _self;
  final $Res Function(_MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = null,Object? channelId = freezed,Object? sender = null,Object? content = freezed,Object? type = null,Object? replyToId = freezed,Object? replyTo = freezed,Object? isEdited = null,Object? isPinned = null,Object? attachments = null,Object? reactions = null,Object? readBy = null,Object? deliveredTo = null,Object? voiceNote = freezed,Object? forward = freezed,Object? mentions = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,channelId: freezed == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String?,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as MessageSenderModel,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,replyTo: freezed == replyTo ? _self.replyTo : replyTo // ignore: cast_nullable_to_non_nullable
as MessageReplyModel?,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachmentModel>,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<MessageReactionModel>,readBy: null == readBy ? _self._readBy : readBy // ignore: cast_nullable_to_non_nullable
as List<String>,deliveredTo: null == deliveredTo ? _self._deliveredTo : deliveredTo // ignore: cast_nullable_to_non_nullable
as List<String>,voiceNote: freezed == voiceNote ? _self.voiceNote : voiceNote // ignore: cast_nullable_to_non_nullable
as MessageVoiceNoteModel?,forward: freezed == forward ? _self.forward : forward // ignore: cast_nullable_to_non_nullable
as MessageForwardModel?,mentions: null == mentions ? _self._mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageSenderModelCopyWith<$Res> get sender {
  
  return $MessageSenderModelCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageReplyModelCopyWith<$Res>? get replyTo {
    if (_self.replyTo == null) {
    return null;
  }

  return $MessageReplyModelCopyWith<$Res>(_self.replyTo!, (value) {
    return _then(_self.copyWith(replyTo: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageVoiceNoteModelCopyWith<$Res>? get voiceNote {
    if (_self.voiceNote == null) {
    return null;
  }

  return $MessageVoiceNoteModelCopyWith<$Res>(_self.voiceNote!, (value) {
    return _then(_self.copyWith(voiceNote: value));
  });
}/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageForwardModelCopyWith<$Res>? get forward {
    if (_self.forward == null) {
    return null;
  }

  return $MessageForwardModelCopyWith<$Res>(_self.forward!, (value) {
    return _then(_self.copyWith(forward: value));
  });
}
}


/// @nodoc
mixin _$MessageSenderModel {

 String get id; String get username; String? get displayName; String? get avatarUrl;
/// Create a copy of MessageSenderModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageSenderModelCopyWith<MessageSenderModel> get copyWith => _$MessageSenderModelCopyWithImpl<MessageSenderModel>(this as MessageSenderModel, _$identity);

  /// Serializes this MessageSenderModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageSenderModel&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl);

@override
String toString() {
  return 'MessageSenderModel(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $MessageSenderModelCopyWith<$Res>  {
  factory $MessageSenderModelCopyWith(MessageSenderModel value, $Res Function(MessageSenderModel) _then) = _$MessageSenderModelCopyWithImpl;
@useResult
$Res call({
 String id, String username, String? displayName, String? avatarUrl
});




}
/// @nodoc
class _$MessageSenderModelCopyWithImpl<$Res>
    implements $MessageSenderModelCopyWith<$Res> {
  _$MessageSenderModelCopyWithImpl(this._self, this._then);

  final MessageSenderModel _self;
  final $Res Function(MessageSenderModel) _then;

/// Create a copy of MessageSenderModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? displayName = freezed,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageSenderModel].
extension MessageSenderModelPatterns on MessageSenderModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageSenderModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageSenderModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageSenderModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageSenderModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageSenderModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageSenderModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username,  String? displayName,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageSenderModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username,  String? displayName,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _MessageSenderModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username,  String? displayName,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _MessageSenderModel() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageSenderModel implements MessageSenderModel {
  const _MessageSenderModel({required this.id, required this.username, this.displayName, this.avatarUrl});
  factory _MessageSenderModel.fromJson(Map<String, dynamic> json) => _$MessageSenderModelFromJson(json);

@override final  String id;
@override final  String username;
@override final  String? displayName;
@override final  String? avatarUrl;

/// Create a copy of MessageSenderModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageSenderModelCopyWith<_MessageSenderModel> get copyWith => __$MessageSenderModelCopyWithImpl<_MessageSenderModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageSenderModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageSenderModel&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl);

@override
String toString() {
  return 'MessageSenderModel(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$MessageSenderModelCopyWith<$Res> implements $MessageSenderModelCopyWith<$Res> {
  factory _$MessageSenderModelCopyWith(_MessageSenderModel value, $Res Function(_MessageSenderModel) _then) = __$MessageSenderModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String username, String? displayName, String? avatarUrl
});




}
/// @nodoc
class __$MessageSenderModelCopyWithImpl<$Res>
    implements _$MessageSenderModelCopyWith<$Res> {
  __$MessageSenderModelCopyWithImpl(this._self, this._then);

  final _MessageSenderModel _self;
  final $Res Function(_MessageSenderModel) _then;

/// Create a copy of MessageSenderModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? displayName = freezed,Object? avatarUrl = freezed,}) {
  return _then(_MessageSenderModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MessageReplyModel {

 String get id; String? get content; String get type; MessageSenderModel get sender;
/// Create a copy of MessageReplyModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageReplyModelCopyWith<MessageReplyModel> get copyWith => _$MessageReplyModelCopyWithImpl<MessageReplyModel>(this as MessageReplyModel, _$identity);

  /// Serializes this MessageReplyModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageReplyModel&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.sender, sender) || other.sender == sender));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,type,sender);

@override
String toString() {
  return 'MessageReplyModel(id: $id, content: $content, type: $type, sender: $sender)';
}


}

/// @nodoc
abstract mixin class $MessageReplyModelCopyWith<$Res>  {
  factory $MessageReplyModelCopyWith(MessageReplyModel value, $Res Function(MessageReplyModel) _then) = _$MessageReplyModelCopyWithImpl;
@useResult
$Res call({
 String id, String? content, String type, MessageSenderModel sender
});


$MessageSenderModelCopyWith<$Res> get sender;

}
/// @nodoc
class _$MessageReplyModelCopyWithImpl<$Res>
    implements $MessageReplyModelCopyWith<$Res> {
  _$MessageReplyModelCopyWithImpl(this._self, this._then);

  final MessageReplyModel _self;
  final $Res Function(MessageReplyModel) _then;

/// Create a copy of MessageReplyModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = freezed,Object? type = null,Object? sender = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as MessageSenderModel,
  ));
}
/// Create a copy of MessageReplyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageSenderModelCopyWith<$Res> get sender {
  
  return $MessageSenderModelCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessageReplyModel].
extension MessageReplyModelPatterns on MessageReplyModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageReplyModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageReplyModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageReplyModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageReplyModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageReplyModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageReplyModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? content,  String type,  MessageSenderModel sender)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageReplyModel() when $default != null:
return $default(_that.id,_that.content,_that.type,_that.sender);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? content,  String type,  MessageSenderModel sender)  $default,) {final _that = this;
switch (_that) {
case _MessageReplyModel():
return $default(_that.id,_that.content,_that.type,_that.sender);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? content,  String type,  MessageSenderModel sender)?  $default,) {final _that = this;
switch (_that) {
case _MessageReplyModel() when $default != null:
return $default(_that.id,_that.content,_that.type,_that.sender);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageReplyModel implements MessageReplyModel {
  const _MessageReplyModel({required this.id, this.content, required this.type, required this.sender});
  factory _MessageReplyModel.fromJson(Map<String, dynamic> json) => _$MessageReplyModelFromJson(json);

@override final  String id;
@override final  String? content;
@override final  String type;
@override final  MessageSenderModel sender;

/// Create a copy of MessageReplyModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageReplyModelCopyWith<_MessageReplyModel> get copyWith => __$MessageReplyModelCopyWithImpl<_MessageReplyModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageReplyModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageReplyModel&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.sender, sender) || other.sender == sender));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,type,sender);

@override
String toString() {
  return 'MessageReplyModel(id: $id, content: $content, type: $type, sender: $sender)';
}


}

/// @nodoc
abstract mixin class _$MessageReplyModelCopyWith<$Res> implements $MessageReplyModelCopyWith<$Res> {
  factory _$MessageReplyModelCopyWith(_MessageReplyModel value, $Res Function(_MessageReplyModel) _then) = __$MessageReplyModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? content, String type, MessageSenderModel sender
});


@override $MessageSenderModelCopyWith<$Res> get sender;

}
/// @nodoc
class __$MessageReplyModelCopyWithImpl<$Res>
    implements _$MessageReplyModelCopyWith<$Res> {
  __$MessageReplyModelCopyWithImpl(this._self, this._then);

  final _MessageReplyModel _self;
  final $Res Function(_MessageReplyModel) _then;

/// Create a copy of MessageReplyModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = freezed,Object? type = null,Object? sender = null,}) {
  return _then(_MessageReplyModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as MessageSenderModel,
  ));
}

/// Create a copy of MessageReplyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageSenderModelCopyWith<$Res> get sender {
  
  return $MessageSenderModelCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}
}


/// @nodoc
mixin _$MessageAttachmentModel {

 String get fileId; String get url; String get fileType; String get mimeType; String get originalName; int? get width; int? get height; double? get duration; int? get size; String? get thumbnailUrl;
/// Create a copy of MessageAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageAttachmentModelCopyWith<MessageAttachmentModel> get copyWith => _$MessageAttachmentModelCopyWithImpl<MessageAttachmentModel>(this as MessageAttachmentModel, _$identity);

  /// Serializes this MessageAttachmentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageAttachmentModel&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.url, url) || other.url == url)&&(identical(other.fileType, fileType) || other.fileType == fileType)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.size, size) || other.size == size)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,url,fileType,mimeType,originalName,width,height,duration,size,thumbnailUrl);

@override
String toString() {
  return 'MessageAttachmentModel(fileId: $fileId, url: $url, fileType: $fileType, mimeType: $mimeType, originalName: $originalName, width: $width, height: $height, duration: $duration, size: $size, thumbnailUrl: $thumbnailUrl)';
}


}

/// @nodoc
abstract mixin class $MessageAttachmentModelCopyWith<$Res>  {
  factory $MessageAttachmentModelCopyWith(MessageAttachmentModel value, $Res Function(MessageAttachmentModel) _then) = _$MessageAttachmentModelCopyWithImpl;
@useResult
$Res call({
 String fileId, String url, String fileType, String mimeType, String originalName, int? width, int? height, double? duration, int? size, String? thumbnailUrl
});




}
/// @nodoc
class _$MessageAttachmentModelCopyWithImpl<$Res>
    implements $MessageAttachmentModelCopyWith<$Res> {
  _$MessageAttachmentModelCopyWithImpl(this._self, this._then);

  final MessageAttachmentModel _self;
  final $Res Function(MessageAttachmentModel) _then;

/// Create a copy of MessageAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileId = null,Object? url = null,Object? fileType = null,Object? mimeType = null,Object? originalName = null,Object? width = freezed,Object? height = freezed,Object? duration = freezed,Object? size = freezed,Object? thumbnailUrl = freezed,}) {
  return _then(_self.copyWith(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,fileType: null == fileType ? _self.fileType : fileType // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageAttachmentModel].
extension MessageAttachmentModelPatterns on MessageAttachmentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageAttachmentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageAttachmentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageAttachmentModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageAttachmentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageAttachmentModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageAttachmentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileId,  String url,  String fileType,  String mimeType,  String originalName,  int? width,  int? height,  double? duration,  int? size,  String? thumbnailUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageAttachmentModel() when $default != null:
return $default(_that.fileId,_that.url,_that.fileType,_that.mimeType,_that.originalName,_that.width,_that.height,_that.duration,_that.size,_that.thumbnailUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileId,  String url,  String fileType,  String mimeType,  String originalName,  int? width,  int? height,  double? duration,  int? size,  String? thumbnailUrl)  $default,) {final _that = this;
switch (_that) {
case _MessageAttachmentModel():
return $default(_that.fileId,_that.url,_that.fileType,_that.mimeType,_that.originalName,_that.width,_that.height,_that.duration,_that.size,_that.thumbnailUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileId,  String url,  String fileType,  String mimeType,  String originalName,  int? width,  int? height,  double? duration,  int? size,  String? thumbnailUrl)?  $default,) {final _that = this;
switch (_that) {
case _MessageAttachmentModel() when $default != null:
return $default(_that.fileId,_that.url,_that.fileType,_that.mimeType,_that.originalName,_that.width,_that.height,_that.duration,_that.size,_that.thumbnailUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageAttachmentModel implements MessageAttachmentModel {
  const _MessageAttachmentModel({required this.fileId, required this.url, required this.fileType, required this.mimeType, required this.originalName, this.width, this.height, this.duration, this.size, this.thumbnailUrl});
  factory _MessageAttachmentModel.fromJson(Map<String, dynamic> json) => _$MessageAttachmentModelFromJson(json);

@override final  String fileId;
@override final  String url;
@override final  String fileType;
@override final  String mimeType;
@override final  String originalName;
@override final  int? width;
@override final  int? height;
@override final  double? duration;
@override final  int? size;
@override final  String? thumbnailUrl;

/// Create a copy of MessageAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageAttachmentModelCopyWith<_MessageAttachmentModel> get copyWith => __$MessageAttachmentModelCopyWithImpl<_MessageAttachmentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageAttachmentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageAttachmentModel&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.url, url) || other.url == url)&&(identical(other.fileType, fileType) || other.fileType == fileType)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.size, size) || other.size == size)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,url,fileType,mimeType,originalName,width,height,duration,size,thumbnailUrl);

@override
String toString() {
  return 'MessageAttachmentModel(fileId: $fileId, url: $url, fileType: $fileType, mimeType: $mimeType, originalName: $originalName, width: $width, height: $height, duration: $duration, size: $size, thumbnailUrl: $thumbnailUrl)';
}


}

/// @nodoc
abstract mixin class _$MessageAttachmentModelCopyWith<$Res> implements $MessageAttachmentModelCopyWith<$Res> {
  factory _$MessageAttachmentModelCopyWith(_MessageAttachmentModel value, $Res Function(_MessageAttachmentModel) _then) = __$MessageAttachmentModelCopyWithImpl;
@override @useResult
$Res call({
 String fileId, String url, String fileType, String mimeType, String originalName, int? width, int? height, double? duration, int? size, String? thumbnailUrl
});




}
/// @nodoc
class __$MessageAttachmentModelCopyWithImpl<$Res>
    implements _$MessageAttachmentModelCopyWith<$Res> {
  __$MessageAttachmentModelCopyWithImpl(this._self, this._then);

  final _MessageAttachmentModel _self;
  final $Res Function(_MessageAttachmentModel) _then;

/// Create a copy of MessageAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileId = null,Object? url = null,Object? fileType = null,Object? mimeType = null,Object? originalName = null,Object? width = freezed,Object? height = freezed,Object? duration = freezed,Object? size = freezed,Object? thumbnailUrl = freezed,}) {
  return _then(_MessageAttachmentModel(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,fileType: null == fileType ? _self.fileType : fileType // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MessageReactionModel {

 String get emoji; int get count; List<String> get userIds;
/// Create a copy of MessageReactionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageReactionModelCopyWith<MessageReactionModel> get copyWith => _$MessageReactionModelCopyWithImpl<MessageReactionModel>(this as MessageReactionModel, _$identity);

  /// Serializes this MessageReactionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageReactionModel&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.userIds, userIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,emoji,count,const DeepCollectionEquality().hash(userIds));

@override
String toString() {
  return 'MessageReactionModel(emoji: $emoji, count: $count, userIds: $userIds)';
}


}

/// @nodoc
abstract mixin class $MessageReactionModelCopyWith<$Res>  {
  factory $MessageReactionModelCopyWith(MessageReactionModel value, $Res Function(MessageReactionModel) _then) = _$MessageReactionModelCopyWithImpl;
@useResult
$Res call({
 String emoji, int count, List<String> userIds
});




}
/// @nodoc
class _$MessageReactionModelCopyWithImpl<$Res>
    implements $MessageReactionModelCopyWith<$Res> {
  _$MessageReactionModelCopyWithImpl(this._self, this._then);

  final MessageReactionModel _self;
  final $Res Function(MessageReactionModel) _then;

/// Create a copy of MessageReactionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? emoji = null,Object? count = null,Object? userIds = null,}) {
  return _then(_self.copyWith(
emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,userIds: null == userIds ? _self.userIds : userIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageReactionModel].
extension MessageReactionModelPatterns on MessageReactionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageReactionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageReactionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageReactionModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageReactionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageReactionModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageReactionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String emoji,  int count,  List<String> userIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageReactionModel() when $default != null:
return $default(_that.emoji,_that.count,_that.userIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String emoji,  int count,  List<String> userIds)  $default,) {final _that = this;
switch (_that) {
case _MessageReactionModel():
return $default(_that.emoji,_that.count,_that.userIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String emoji,  int count,  List<String> userIds)?  $default,) {final _that = this;
switch (_that) {
case _MessageReactionModel() when $default != null:
return $default(_that.emoji,_that.count,_that.userIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageReactionModel implements MessageReactionModel {
  const _MessageReactionModel({required this.emoji, required this.count, required final  List<String> userIds}): _userIds = userIds;
  factory _MessageReactionModel.fromJson(Map<String, dynamic> json) => _$MessageReactionModelFromJson(json);

@override final  String emoji;
@override final  int count;
 final  List<String> _userIds;
@override List<String> get userIds {
  if (_userIds is EqualUnmodifiableListView) return _userIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_userIds);
}


/// Create a copy of MessageReactionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageReactionModelCopyWith<_MessageReactionModel> get copyWith => __$MessageReactionModelCopyWithImpl<_MessageReactionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageReactionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageReactionModel&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other._userIds, _userIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,emoji,count,const DeepCollectionEquality().hash(_userIds));

@override
String toString() {
  return 'MessageReactionModel(emoji: $emoji, count: $count, userIds: $userIds)';
}


}

/// @nodoc
abstract mixin class _$MessageReactionModelCopyWith<$Res> implements $MessageReactionModelCopyWith<$Res> {
  factory _$MessageReactionModelCopyWith(_MessageReactionModel value, $Res Function(_MessageReactionModel) _then) = __$MessageReactionModelCopyWithImpl;
@override @useResult
$Res call({
 String emoji, int count, List<String> userIds
});




}
/// @nodoc
class __$MessageReactionModelCopyWithImpl<$Res>
    implements _$MessageReactionModelCopyWith<$Res> {
  __$MessageReactionModelCopyWithImpl(this._self, this._then);

  final _MessageReactionModel _self;
  final $Res Function(_MessageReactionModel) _then;

/// Create a copy of MessageReactionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? emoji = null,Object? count = null,Object? userIds = null,}) {
  return _then(_MessageReactionModel(
emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,userIds: null == userIds ? _self._userIds : userIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$MessageVoiceNoteModel {

 String get fileId; String get url; int get duration; List<double>? get waveform;
/// Create a copy of MessageVoiceNoteModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageVoiceNoteModelCopyWith<MessageVoiceNoteModel> get copyWith => _$MessageVoiceNoteModelCopyWithImpl<MessageVoiceNoteModel>(this as MessageVoiceNoteModel, _$identity);

  /// Serializes this MessageVoiceNoteModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageVoiceNoteModel&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.url, url) || other.url == url)&&(identical(other.duration, duration) || other.duration == duration)&&const DeepCollectionEquality().equals(other.waveform, waveform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,url,duration,const DeepCollectionEquality().hash(waveform));

@override
String toString() {
  return 'MessageVoiceNoteModel(fileId: $fileId, url: $url, duration: $duration, waveform: $waveform)';
}


}

/// @nodoc
abstract mixin class $MessageVoiceNoteModelCopyWith<$Res>  {
  factory $MessageVoiceNoteModelCopyWith(MessageVoiceNoteModel value, $Res Function(MessageVoiceNoteModel) _then) = _$MessageVoiceNoteModelCopyWithImpl;
@useResult
$Res call({
 String fileId, String url, int duration, List<double>? waveform
});




}
/// @nodoc
class _$MessageVoiceNoteModelCopyWithImpl<$Res>
    implements $MessageVoiceNoteModelCopyWith<$Res> {
  _$MessageVoiceNoteModelCopyWithImpl(this._self, this._then);

  final MessageVoiceNoteModel _self;
  final $Res Function(MessageVoiceNoteModel) _then;

/// Create a copy of MessageVoiceNoteModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileId = null,Object? url = null,Object? duration = null,Object? waveform = freezed,}) {
  return _then(_self.copyWith(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,waveform: freezed == waveform ? _self.waveform : waveform // ignore: cast_nullable_to_non_nullable
as List<double>?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageVoiceNoteModel].
extension MessageVoiceNoteModelPatterns on MessageVoiceNoteModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageVoiceNoteModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageVoiceNoteModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageVoiceNoteModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageVoiceNoteModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageVoiceNoteModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageVoiceNoteModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileId,  String url,  int duration,  List<double>? waveform)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageVoiceNoteModel() when $default != null:
return $default(_that.fileId,_that.url,_that.duration,_that.waveform);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileId,  String url,  int duration,  List<double>? waveform)  $default,) {final _that = this;
switch (_that) {
case _MessageVoiceNoteModel():
return $default(_that.fileId,_that.url,_that.duration,_that.waveform);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileId,  String url,  int duration,  List<double>? waveform)?  $default,) {final _that = this;
switch (_that) {
case _MessageVoiceNoteModel() when $default != null:
return $default(_that.fileId,_that.url,_that.duration,_that.waveform);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageVoiceNoteModel implements MessageVoiceNoteModel {
  const _MessageVoiceNoteModel({required this.fileId, required this.url, required this.duration, final  List<double>? waveform}): _waveform = waveform;
  factory _MessageVoiceNoteModel.fromJson(Map<String, dynamic> json) => _$MessageVoiceNoteModelFromJson(json);

@override final  String fileId;
@override final  String url;
@override final  int duration;
 final  List<double>? _waveform;
@override List<double>? get waveform {
  final value = _waveform;
  if (value == null) return null;
  if (_waveform is EqualUnmodifiableListView) return _waveform;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of MessageVoiceNoteModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageVoiceNoteModelCopyWith<_MessageVoiceNoteModel> get copyWith => __$MessageVoiceNoteModelCopyWithImpl<_MessageVoiceNoteModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageVoiceNoteModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageVoiceNoteModel&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.url, url) || other.url == url)&&(identical(other.duration, duration) || other.duration == duration)&&const DeepCollectionEquality().equals(other._waveform, _waveform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,url,duration,const DeepCollectionEquality().hash(_waveform));

@override
String toString() {
  return 'MessageVoiceNoteModel(fileId: $fileId, url: $url, duration: $duration, waveform: $waveform)';
}


}

/// @nodoc
abstract mixin class _$MessageVoiceNoteModelCopyWith<$Res> implements $MessageVoiceNoteModelCopyWith<$Res> {
  factory _$MessageVoiceNoteModelCopyWith(_MessageVoiceNoteModel value, $Res Function(_MessageVoiceNoteModel) _then) = __$MessageVoiceNoteModelCopyWithImpl;
@override @useResult
$Res call({
 String fileId, String url, int duration, List<double>? waveform
});




}
/// @nodoc
class __$MessageVoiceNoteModelCopyWithImpl<$Res>
    implements _$MessageVoiceNoteModelCopyWith<$Res> {
  __$MessageVoiceNoteModelCopyWithImpl(this._self, this._then);

  final _MessageVoiceNoteModel _self;
  final $Res Function(_MessageVoiceNoteModel) _then;

/// Create a copy of MessageVoiceNoteModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileId = null,Object? url = null,Object? duration = null,Object? waveform = freezed,}) {
  return _then(_MessageVoiceNoteModel(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,waveform: freezed == waveform ? _self._waveform : waveform // ignore: cast_nullable_to_non_nullable
as List<double>?,
  ));
}


}


/// @nodoc
mixin _$MessageForwardModel {

 String get originalMessageId; MessageSenderModel get originalSender; DateTime get originalCreatedAt;
/// Create a copy of MessageForwardModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageForwardModelCopyWith<MessageForwardModel> get copyWith => _$MessageForwardModelCopyWithImpl<MessageForwardModel>(this as MessageForwardModel, _$identity);

  /// Serializes this MessageForwardModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageForwardModel&&(identical(other.originalMessageId, originalMessageId) || other.originalMessageId == originalMessageId)&&(identical(other.originalSender, originalSender) || other.originalSender == originalSender)&&(identical(other.originalCreatedAt, originalCreatedAt) || other.originalCreatedAt == originalCreatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalMessageId,originalSender,originalCreatedAt);

@override
String toString() {
  return 'MessageForwardModel(originalMessageId: $originalMessageId, originalSender: $originalSender, originalCreatedAt: $originalCreatedAt)';
}


}

/// @nodoc
abstract mixin class $MessageForwardModelCopyWith<$Res>  {
  factory $MessageForwardModelCopyWith(MessageForwardModel value, $Res Function(MessageForwardModel) _then) = _$MessageForwardModelCopyWithImpl;
@useResult
$Res call({
 String originalMessageId, MessageSenderModel originalSender, DateTime originalCreatedAt
});


$MessageSenderModelCopyWith<$Res> get originalSender;

}
/// @nodoc
class _$MessageForwardModelCopyWithImpl<$Res>
    implements $MessageForwardModelCopyWith<$Res> {
  _$MessageForwardModelCopyWithImpl(this._self, this._then);

  final MessageForwardModel _self;
  final $Res Function(MessageForwardModel) _then;

/// Create a copy of MessageForwardModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originalMessageId = null,Object? originalSender = null,Object? originalCreatedAt = null,}) {
  return _then(_self.copyWith(
originalMessageId: null == originalMessageId ? _self.originalMessageId : originalMessageId // ignore: cast_nullable_to_non_nullable
as String,originalSender: null == originalSender ? _self.originalSender : originalSender // ignore: cast_nullable_to_non_nullable
as MessageSenderModel,originalCreatedAt: null == originalCreatedAt ? _self.originalCreatedAt : originalCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of MessageForwardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageSenderModelCopyWith<$Res> get originalSender {
  
  return $MessageSenderModelCopyWith<$Res>(_self.originalSender, (value) {
    return _then(_self.copyWith(originalSender: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessageForwardModel].
extension MessageForwardModelPatterns on MessageForwardModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageForwardModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageForwardModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageForwardModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageForwardModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageForwardModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageForwardModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String originalMessageId,  MessageSenderModel originalSender,  DateTime originalCreatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageForwardModel() when $default != null:
return $default(_that.originalMessageId,_that.originalSender,_that.originalCreatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String originalMessageId,  MessageSenderModel originalSender,  DateTime originalCreatedAt)  $default,) {final _that = this;
switch (_that) {
case _MessageForwardModel():
return $default(_that.originalMessageId,_that.originalSender,_that.originalCreatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String originalMessageId,  MessageSenderModel originalSender,  DateTime originalCreatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageForwardModel() when $default != null:
return $default(_that.originalMessageId,_that.originalSender,_that.originalCreatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageForwardModel implements MessageForwardModel {
  const _MessageForwardModel({required this.originalMessageId, required this.originalSender, required this.originalCreatedAt});
  factory _MessageForwardModel.fromJson(Map<String, dynamic> json) => _$MessageForwardModelFromJson(json);

@override final  String originalMessageId;
@override final  MessageSenderModel originalSender;
@override final  DateTime originalCreatedAt;

/// Create a copy of MessageForwardModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageForwardModelCopyWith<_MessageForwardModel> get copyWith => __$MessageForwardModelCopyWithImpl<_MessageForwardModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageForwardModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageForwardModel&&(identical(other.originalMessageId, originalMessageId) || other.originalMessageId == originalMessageId)&&(identical(other.originalSender, originalSender) || other.originalSender == originalSender)&&(identical(other.originalCreatedAt, originalCreatedAt) || other.originalCreatedAt == originalCreatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalMessageId,originalSender,originalCreatedAt);

@override
String toString() {
  return 'MessageForwardModel(originalMessageId: $originalMessageId, originalSender: $originalSender, originalCreatedAt: $originalCreatedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageForwardModelCopyWith<$Res> implements $MessageForwardModelCopyWith<$Res> {
  factory _$MessageForwardModelCopyWith(_MessageForwardModel value, $Res Function(_MessageForwardModel) _then) = __$MessageForwardModelCopyWithImpl;
@override @useResult
$Res call({
 String originalMessageId, MessageSenderModel originalSender, DateTime originalCreatedAt
});


@override $MessageSenderModelCopyWith<$Res> get originalSender;

}
/// @nodoc
class __$MessageForwardModelCopyWithImpl<$Res>
    implements _$MessageForwardModelCopyWith<$Res> {
  __$MessageForwardModelCopyWithImpl(this._self, this._then);

  final _MessageForwardModel _self;
  final $Res Function(_MessageForwardModel) _then;

/// Create a copy of MessageForwardModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalMessageId = null,Object? originalSender = null,Object? originalCreatedAt = null,}) {
  return _then(_MessageForwardModel(
originalMessageId: null == originalMessageId ? _self.originalMessageId : originalMessageId // ignore: cast_nullable_to_non_nullable
as String,originalSender: null == originalSender ? _self.originalSender : originalSender // ignore: cast_nullable_to_non_nullable
as MessageSenderModel,originalCreatedAt: null == originalCreatedAt ? _self.originalCreatedAt : originalCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of MessageForwardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageSenderModelCopyWith<$Res> get originalSender {
  
  return $MessageSenderModelCopyWith<$Res>(_self.originalSender, (value) {
    return _then(_self.copyWith(originalSender: value));
  });
}
}


/// @nodoc
mixin _$PaginatedMessagesModel {

 List<MessageModel> get data; String? get nextCursor; bool get hasMore;
/// Create a copy of PaginatedMessagesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginatedMessagesModelCopyWith<PaginatedMessagesModel> get copyWith => _$PaginatedMessagesModelCopyWithImpl<PaginatedMessagesModel>(this as PaginatedMessagesModel, _$identity);

  /// Serializes this PaginatedMessagesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginatedMessagesModel&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data),nextCursor,hasMore);

@override
String toString() {
  return 'PaginatedMessagesModel(data: $data, nextCursor: $nextCursor, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $PaginatedMessagesModelCopyWith<$Res>  {
  factory $PaginatedMessagesModelCopyWith(PaginatedMessagesModel value, $Res Function(PaginatedMessagesModel) _then) = _$PaginatedMessagesModelCopyWithImpl;
@useResult
$Res call({
 List<MessageModel> data, String? nextCursor, bool hasMore
});




}
/// @nodoc
class _$PaginatedMessagesModelCopyWithImpl<$Res>
    implements $PaginatedMessagesModelCopyWith<$Res> {
  _$PaginatedMessagesModelCopyWithImpl(this._self, this._then);

  final PaginatedMessagesModel _self;
  final $Res Function(PaginatedMessagesModel) _then;

/// Create a copy of PaginatedMessagesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? nextCursor = freezed,Object? hasMore = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<MessageModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginatedMessagesModel].
extension PaginatedMessagesModelPatterns on PaginatedMessagesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginatedMessagesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginatedMessagesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginatedMessagesModel value)  $default,){
final _that = this;
switch (_that) {
case _PaginatedMessagesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginatedMessagesModel value)?  $default,){
final _that = this;
switch (_that) {
case _PaginatedMessagesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MessageModel> data,  String? nextCursor,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginatedMessagesModel() when $default != null:
return $default(_that.data,_that.nextCursor,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MessageModel> data,  String? nextCursor,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _PaginatedMessagesModel():
return $default(_that.data,_that.nextCursor,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MessageModel> data,  String? nextCursor,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _PaginatedMessagesModel() when $default != null:
return $default(_that.data,_that.nextCursor,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginatedMessagesModel implements PaginatedMessagesModel {
  const _PaginatedMessagesModel({required final  List<MessageModel> data, this.nextCursor, this.hasMore = false}): _data = data;
  factory _PaginatedMessagesModel.fromJson(Map<String, dynamic> json) => _$PaginatedMessagesModelFromJson(json);

 final  List<MessageModel> _data;
@override List<MessageModel> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}

@override final  String? nextCursor;
@override@JsonKey() final  bool hasMore;

/// Create a copy of PaginatedMessagesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginatedMessagesModelCopyWith<_PaginatedMessagesModel> get copyWith => __$PaginatedMessagesModelCopyWithImpl<_PaginatedMessagesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginatedMessagesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginatedMessagesModel&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data),nextCursor,hasMore);

@override
String toString() {
  return 'PaginatedMessagesModel(data: $data, nextCursor: $nextCursor, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$PaginatedMessagesModelCopyWith<$Res> implements $PaginatedMessagesModelCopyWith<$Res> {
  factory _$PaginatedMessagesModelCopyWith(_PaginatedMessagesModel value, $Res Function(_PaginatedMessagesModel) _then) = __$PaginatedMessagesModelCopyWithImpl;
@override @useResult
$Res call({
 List<MessageModel> data, String? nextCursor, bool hasMore
});




}
/// @nodoc
class __$PaginatedMessagesModelCopyWithImpl<$Res>
    implements _$PaginatedMessagesModelCopyWith<$Res> {
  __$PaginatedMessagesModelCopyWithImpl(this._self, this._then);

  final _PaginatedMessagesModel _self;
  final $Res Function(_PaginatedMessagesModel) _then;

/// Create a copy of PaginatedMessagesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? nextCursor = freezed,Object? hasMore = null,}) {
  return _then(_PaginatedMessagesModel(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<MessageModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
