// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) {
  return _MessageModel.fromJson(json);
}

/// @nodoc
mixin _$MessageModel {
  String get id => throw _privateConstructorUsedError;
  String get conversationId => throw _privateConstructorUsedError;
  String? get channelId => throw _privateConstructorUsedError;
  MessageSenderModel get sender => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get replyToId => throw _privateConstructorUsedError;
  MessageReplyModel? get replyTo => throw _privateConstructorUsedError;
  bool get isEdited => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;
  List<MessageAttachmentModel> get attachments =>
      throw _privateConstructorUsedError;
  List<MessageReactionModel> get reactions =>
      throw _privateConstructorUsedError;
  List<String> get readBy => throw _privateConstructorUsedError;
  List<String> get deliveredTo => throw _privateConstructorUsedError;
  MessageVoiceNoteModel? get voiceNote => throw _privateConstructorUsedError;
  MessageForwardModel? get forward => throw _privateConstructorUsedError;
  List<String> get mentions => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this MessageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageModelCopyWith<MessageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageModelCopyWith<$Res> {
  factory $MessageModelCopyWith(
    MessageModel value,
    $Res Function(MessageModel) then,
  ) = _$MessageModelCopyWithImpl<$Res, MessageModel>;
  @useResult
  $Res call({
    String id,
    String conversationId,
    String? channelId,
    MessageSenderModel sender,
    String? content,
    String type,
    String? replyToId,
    MessageReplyModel? replyTo,
    bool isEdited,
    bool isPinned,
    List<MessageAttachmentModel> attachments,
    List<MessageReactionModel> reactions,
    List<String> readBy,
    List<String> deliveredTo,
    MessageVoiceNoteModel? voiceNote,
    MessageForwardModel? forward,
    List<String> mentions,
    DateTime createdAt,
    DateTime updatedAt,
  });

  $MessageSenderModelCopyWith<$Res> get sender;
  $MessageReplyModelCopyWith<$Res>? get replyTo;
  $MessageVoiceNoteModelCopyWith<$Res>? get voiceNote;
  $MessageForwardModelCopyWith<$Res>? get forward;
}

/// @nodoc
class _$MessageModelCopyWithImpl<$Res, $Val extends MessageModel>
    implements $MessageModelCopyWith<$Res> {
  _$MessageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? channelId = freezed,
    Object? sender = null,
    Object? content = freezed,
    Object? type = null,
    Object? replyToId = freezed,
    Object? replyTo = freezed,
    Object? isEdited = null,
    Object? isPinned = null,
    Object? attachments = null,
    Object? reactions = null,
    Object? readBy = null,
    Object? deliveredTo = null,
    Object? voiceNote = freezed,
    Object? forward = freezed,
    Object? mentions = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            conversationId: null == conversationId
                ? _value.conversationId
                : conversationId // ignore: cast_nullable_to_non_nullable
                      as String,
            channelId: freezed == channelId
                ? _value.channelId
                : channelId // ignore: cast_nullable_to_non_nullable
                      as String?,
            sender: null == sender
                ? _value.sender
                : sender // ignore: cast_nullable_to_non_nullable
                      as MessageSenderModel,
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            replyToId: freezed == replyToId
                ? _value.replyToId
                : replyToId // ignore: cast_nullable_to_non_nullable
                      as String?,
            replyTo: freezed == replyTo
                ? _value.replyTo
                : replyTo // ignore: cast_nullable_to_non_nullable
                      as MessageReplyModel?,
            isEdited: null == isEdited
                ? _value.isEdited
                : isEdited // ignore: cast_nullable_to_non_nullable
                      as bool,
            isPinned: null == isPinned
                ? _value.isPinned
                : isPinned // ignore: cast_nullable_to_non_nullable
                      as bool,
            attachments: null == attachments
                ? _value.attachments
                : attachments // ignore: cast_nullable_to_non_nullable
                      as List<MessageAttachmentModel>,
            reactions: null == reactions
                ? _value.reactions
                : reactions // ignore: cast_nullable_to_non_nullable
                      as List<MessageReactionModel>,
            readBy: null == readBy
                ? _value.readBy
                : readBy // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            deliveredTo: null == deliveredTo
                ? _value.deliveredTo
                : deliveredTo // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            voiceNote: freezed == voiceNote
                ? _value.voiceNote
                : voiceNote // ignore: cast_nullable_to_non_nullable
                      as MessageVoiceNoteModel?,
            forward: freezed == forward
                ? _value.forward
                : forward // ignore: cast_nullable_to_non_nullable
                      as MessageForwardModel?,
            mentions: null == mentions
                ? _value.mentions
                : mentions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageSenderModelCopyWith<$Res> get sender {
    return $MessageSenderModelCopyWith<$Res>(_value.sender, (value) {
      return _then(_value.copyWith(sender: value) as $Val);
    });
  }

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageReplyModelCopyWith<$Res>? get replyTo {
    if (_value.replyTo == null) {
      return null;
    }

    return $MessageReplyModelCopyWith<$Res>(_value.replyTo!, (value) {
      return _then(_value.copyWith(replyTo: value) as $Val);
    });
  }

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageVoiceNoteModelCopyWith<$Res>? get voiceNote {
    if (_value.voiceNote == null) {
      return null;
    }

    return $MessageVoiceNoteModelCopyWith<$Res>(_value.voiceNote!, (value) {
      return _then(_value.copyWith(voiceNote: value) as $Val);
    });
  }

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageForwardModelCopyWith<$Res>? get forward {
    if (_value.forward == null) {
      return null;
    }

    return $MessageForwardModelCopyWith<$Res>(_value.forward!, (value) {
      return _then(_value.copyWith(forward: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MessageModelImplCopyWith<$Res>
    implements $MessageModelCopyWith<$Res> {
  factory _$$MessageModelImplCopyWith(
    _$MessageModelImpl value,
    $Res Function(_$MessageModelImpl) then,
  ) = __$$MessageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String conversationId,
    String? channelId,
    MessageSenderModel sender,
    String? content,
    String type,
    String? replyToId,
    MessageReplyModel? replyTo,
    bool isEdited,
    bool isPinned,
    List<MessageAttachmentModel> attachments,
    List<MessageReactionModel> reactions,
    List<String> readBy,
    List<String> deliveredTo,
    MessageVoiceNoteModel? voiceNote,
    MessageForwardModel? forward,
    List<String> mentions,
    DateTime createdAt,
    DateTime updatedAt,
  });

  @override
  $MessageSenderModelCopyWith<$Res> get sender;
  @override
  $MessageReplyModelCopyWith<$Res>? get replyTo;
  @override
  $MessageVoiceNoteModelCopyWith<$Res>? get voiceNote;
  @override
  $MessageForwardModelCopyWith<$Res>? get forward;
}

/// @nodoc
class __$$MessageModelImplCopyWithImpl<$Res>
    extends _$MessageModelCopyWithImpl<$Res, _$MessageModelImpl>
    implements _$$MessageModelImplCopyWith<$Res> {
  __$$MessageModelImplCopyWithImpl(
    _$MessageModelImpl _value,
    $Res Function(_$MessageModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? channelId = freezed,
    Object? sender = null,
    Object? content = freezed,
    Object? type = null,
    Object? replyToId = freezed,
    Object? replyTo = freezed,
    Object? isEdited = null,
    Object? isPinned = null,
    Object? attachments = null,
    Object? reactions = null,
    Object? readBy = null,
    Object? deliveredTo = null,
    Object? voiceNote = freezed,
    Object? forward = freezed,
    Object? mentions = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$MessageModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        conversationId: null == conversationId
            ? _value.conversationId
            : conversationId // ignore: cast_nullable_to_non_nullable
                  as String,
        channelId: freezed == channelId
            ? _value.channelId
            : channelId // ignore: cast_nullable_to_non_nullable
                  as String?,
        sender: null == sender
            ? _value.sender
            : sender // ignore: cast_nullable_to_non_nullable
                  as MessageSenderModel,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        replyToId: freezed == replyToId
            ? _value.replyToId
            : replyToId // ignore: cast_nullable_to_non_nullable
                  as String?,
        replyTo: freezed == replyTo
            ? _value.replyTo
            : replyTo // ignore: cast_nullable_to_non_nullable
                  as MessageReplyModel?,
        isEdited: null == isEdited
            ? _value.isEdited
            : isEdited // ignore: cast_nullable_to_non_nullable
                  as bool,
        isPinned: null == isPinned
            ? _value.isPinned
            : isPinned // ignore: cast_nullable_to_non_nullable
                  as bool,
        attachments: null == attachments
            ? _value._attachments
            : attachments // ignore: cast_nullable_to_non_nullable
                  as List<MessageAttachmentModel>,
        reactions: null == reactions
            ? _value._reactions
            : reactions // ignore: cast_nullable_to_non_nullable
                  as List<MessageReactionModel>,
        readBy: null == readBy
            ? _value._readBy
            : readBy // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        deliveredTo: null == deliveredTo
            ? _value._deliveredTo
            : deliveredTo // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        voiceNote: freezed == voiceNote
            ? _value.voiceNote
            : voiceNote // ignore: cast_nullable_to_non_nullable
                  as MessageVoiceNoteModel?,
        forward: freezed == forward
            ? _value.forward
            : forward // ignore: cast_nullable_to_non_nullable
                  as MessageForwardModel?,
        mentions: null == mentions
            ? _value._mentions
            : mentions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageModelImpl implements _MessageModel {
  const _$MessageModelImpl({
    required this.id,
    required this.conversationId,
    this.channelId,
    required this.sender,
    this.content,
    required this.type,
    this.replyToId,
    this.replyTo,
    this.isEdited = false,
    this.isPinned = false,
    final List<MessageAttachmentModel> attachments = const [],
    final List<MessageReactionModel> reactions = const [],
    final List<String> readBy = const [],
    final List<String> deliveredTo = const [],
    this.voiceNote,
    this.forward,
    final List<String> mentions = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : _attachments = attachments,
       _reactions = reactions,
       _readBy = readBy,
       _deliveredTo = deliveredTo,
       _mentions = mentions;

  factory _$MessageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageModelImplFromJson(json);

  @override
  final String id;
  @override
  final String conversationId;
  @override
  final String? channelId;
  @override
  final MessageSenderModel sender;
  @override
  final String? content;
  @override
  final String type;
  @override
  final String? replyToId;
  @override
  final MessageReplyModel? replyTo;
  @override
  @JsonKey()
  final bool isEdited;
  @override
  @JsonKey()
  final bool isPinned;
  final List<MessageAttachmentModel> _attachments;
  @override
  @JsonKey()
  List<MessageAttachmentModel> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  final List<MessageReactionModel> _reactions;
  @override
  @JsonKey()
  List<MessageReactionModel> get reactions {
    if (_reactions is EqualUnmodifiableListView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactions);
  }

  final List<String> _readBy;
  @override
  @JsonKey()
  List<String> get readBy {
    if (_readBy is EqualUnmodifiableListView) return _readBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_readBy);
  }

  final List<String> _deliveredTo;
  @override
  @JsonKey()
  List<String> get deliveredTo {
    if (_deliveredTo is EqualUnmodifiableListView) return _deliveredTo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deliveredTo);
  }

  @override
  final MessageVoiceNoteModel? voiceNote;
  @override
  final MessageForwardModel? forward;
  final List<String> _mentions;
  @override
  @JsonKey()
  List<String> get mentions {
    if (_mentions is EqualUnmodifiableListView) return _mentions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mentions);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'MessageModel(id: $id, conversationId: $conversationId, channelId: $channelId, sender: $sender, content: $content, type: $type, replyToId: $replyToId, replyTo: $replyTo, isEdited: $isEdited, isPinned: $isPinned, attachments: $attachments, reactions: $reactions, readBy: $readBy, deliveredTo: $deliveredTo, voiceNote: $voiceNote, forward: $forward, mentions: $mentions, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.channelId, channelId) ||
                other.channelId == channelId) &&
            (identical(other.sender, sender) || other.sender == sender) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.replyToId, replyToId) ||
                other.replyToId == replyToId) &&
            (identical(other.replyTo, replyTo) || other.replyTo == replyTo) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            const DeepCollectionEquality().equals(
              other._attachments,
              _attachments,
            ) &&
            const DeepCollectionEquality().equals(
              other._reactions,
              _reactions,
            ) &&
            const DeepCollectionEquality().equals(other._readBy, _readBy) &&
            const DeepCollectionEquality().equals(
              other._deliveredTo,
              _deliveredTo,
            ) &&
            (identical(other.voiceNote, voiceNote) ||
                other.voiceNote == voiceNote) &&
            (identical(other.forward, forward) || other.forward == forward) &&
            const DeepCollectionEquality().equals(other._mentions, _mentions) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    conversationId,
    channelId,
    sender,
    content,
    type,
    replyToId,
    replyTo,
    isEdited,
    isPinned,
    const DeepCollectionEquality().hash(_attachments),
    const DeepCollectionEquality().hash(_reactions),
    const DeepCollectionEquality().hash(_readBy),
    const DeepCollectionEquality().hash(_deliveredTo),
    voiceNote,
    forward,
    const DeepCollectionEquality().hash(_mentions),
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageModelImplCopyWith<_$MessageModelImpl> get copyWith =>
      __$$MessageModelImplCopyWithImpl<_$MessageModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageModelImplToJson(this);
  }
}

abstract class _MessageModel implements MessageModel {
  const factory _MessageModel({
    required final String id,
    required final String conversationId,
    final String? channelId,
    required final MessageSenderModel sender,
    final String? content,
    required final String type,
    final String? replyToId,
    final MessageReplyModel? replyTo,
    final bool isEdited,
    final bool isPinned,
    final List<MessageAttachmentModel> attachments,
    final List<MessageReactionModel> reactions,
    final List<String> readBy,
    final List<String> deliveredTo,
    final MessageVoiceNoteModel? voiceNote,
    final MessageForwardModel? forward,
    final List<String> mentions,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$MessageModelImpl;

  factory _MessageModel.fromJson(Map<String, dynamic> json) =
      _$MessageModelImpl.fromJson;

  @override
  String get id;
  @override
  String get conversationId;
  @override
  String? get channelId;
  @override
  MessageSenderModel get sender;
  @override
  String? get content;
  @override
  String get type;
  @override
  String? get replyToId;
  @override
  MessageReplyModel? get replyTo;
  @override
  bool get isEdited;
  @override
  bool get isPinned;
  @override
  List<MessageAttachmentModel> get attachments;
  @override
  List<MessageReactionModel> get reactions;
  @override
  List<String> get readBy;
  @override
  List<String> get deliveredTo;
  @override
  MessageVoiceNoteModel? get voiceNote;
  @override
  MessageForwardModel? get forward;
  @override
  List<String> get mentions;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageModelImplCopyWith<_$MessageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MessageSenderModel _$MessageSenderModelFromJson(Map<String, dynamic> json) {
  return _MessageSenderModel.fromJson(json);
}

/// @nodoc
mixin _$MessageSenderModel {
  String get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Serializes this MessageSenderModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageSenderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageSenderModelCopyWith<MessageSenderModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageSenderModelCopyWith<$Res> {
  factory $MessageSenderModelCopyWith(
    MessageSenderModel value,
    $Res Function(MessageSenderModel) then,
  ) = _$MessageSenderModelCopyWithImpl<$Res, MessageSenderModel>;
  @useResult
  $Res call({
    String id,
    String username,
    String? displayName,
    String? avatarUrl,
  });
}

/// @nodoc
class _$MessageSenderModelCopyWithImpl<$Res, $Val extends MessageSenderModel>
    implements $MessageSenderModelCopyWith<$Res> {
  _$MessageSenderModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageSenderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageSenderModelImplCopyWith<$Res>
    implements $MessageSenderModelCopyWith<$Res> {
  factory _$$MessageSenderModelImplCopyWith(
    _$MessageSenderModelImpl value,
    $Res Function(_$MessageSenderModelImpl) then,
  ) = __$$MessageSenderModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String username,
    String? displayName,
    String? avatarUrl,
  });
}

/// @nodoc
class __$$MessageSenderModelImplCopyWithImpl<$Res>
    extends _$MessageSenderModelCopyWithImpl<$Res, _$MessageSenderModelImpl>
    implements _$$MessageSenderModelImplCopyWith<$Res> {
  __$$MessageSenderModelImplCopyWithImpl(
    _$MessageSenderModelImpl _value,
    $Res Function(_$MessageSenderModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageSenderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _$MessageSenderModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageSenderModelImpl implements _MessageSenderModel {
  const _$MessageSenderModelImpl({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory _$MessageSenderModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageSenderModelImplFromJson(json);

  @override
  final String id;
  @override
  final String username;
  @override
  final String? displayName;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'MessageSenderModel(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageSenderModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, username, displayName, avatarUrl);

  /// Create a copy of MessageSenderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageSenderModelImplCopyWith<_$MessageSenderModelImpl> get copyWith =>
      __$$MessageSenderModelImplCopyWithImpl<_$MessageSenderModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageSenderModelImplToJson(this);
  }
}

abstract class _MessageSenderModel implements MessageSenderModel {
  const factory _MessageSenderModel({
    required final String id,
    required final String username,
    final String? displayName,
    final String? avatarUrl,
  }) = _$MessageSenderModelImpl;

  factory _MessageSenderModel.fromJson(Map<String, dynamic> json) =
      _$MessageSenderModelImpl.fromJson;

  @override
  String get id;
  @override
  String get username;
  @override
  String? get displayName;
  @override
  String? get avatarUrl;

  /// Create a copy of MessageSenderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageSenderModelImplCopyWith<_$MessageSenderModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MessageReplyModel _$MessageReplyModelFromJson(Map<String, dynamic> json) {
  return _MessageReplyModel.fromJson(json);
}

/// @nodoc
mixin _$MessageReplyModel {
  String get id => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  MessageSenderModel get sender => throw _privateConstructorUsedError;

  /// Serializes this MessageReplyModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageReplyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageReplyModelCopyWith<MessageReplyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageReplyModelCopyWith<$Res> {
  factory $MessageReplyModelCopyWith(
    MessageReplyModel value,
    $Res Function(MessageReplyModel) then,
  ) = _$MessageReplyModelCopyWithImpl<$Res, MessageReplyModel>;
  @useResult
  $Res call({
    String id,
    String? content,
    String type,
    MessageSenderModel sender,
  });

  $MessageSenderModelCopyWith<$Res> get sender;
}

/// @nodoc
class _$MessageReplyModelCopyWithImpl<$Res, $Val extends MessageReplyModel>
    implements $MessageReplyModelCopyWith<$Res> {
  _$MessageReplyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageReplyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = freezed,
    Object? type = null,
    Object? sender = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            sender: null == sender
                ? _value.sender
                : sender // ignore: cast_nullable_to_non_nullable
                      as MessageSenderModel,
          )
          as $Val,
    );
  }

  /// Create a copy of MessageReplyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageSenderModelCopyWith<$Res> get sender {
    return $MessageSenderModelCopyWith<$Res>(_value.sender, (value) {
      return _then(_value.copyWith(sender: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MessageReplyModelImplCopyWith<$Res>
    implements $MessageReplyModelCopyWith<$Res> {
  factory _$$MessageReplyModelImplCopyWith(
    _$MessageReplyModelImpl value,
    $Res Function(_$MessageReplyModelImpl) then,
  ) = __$$MessageReplyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? content,
    String type,
    MessageSenderModel sender,
  });

  @override
  $MessageSenderModelCopyWith<$Res> get sender;
}

/// @nodoc
class __$$MessageReplyModelImplCopyWithImpl<$Res>
    extends _$MessageReplyModelCopyWithImpl<$Res, _$MessageReplyModelImpl>
    implements _$$MessageReplyModelImplCopyWith<$Res> {
  __$$MessageReplyModelImplCopyWithImpl(
    _$MessageReplyModelImpl _value,
    $Res Function(_$MessageReplyModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageReplyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = freezed,
    Object? type = null,
    Object? sender = null,
  }) {
    return _then(
      _$MessageReplyModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        sender: null == sender
            ? _value.sender
            : sender // ignore: cast_nullable_to_non_nullable
                  as MessageSenderModel,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageReplyModelImpl implements _MessageReplyModel {
  const _$MessageReplyModelImpl({
    required this.id,
    this.content,
    required this.type,
    required this.sender,
  });

  factory _$MessageReplyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageReplyModelImplFromJson(json);

  @override
  final String id;
  @override
  final String? content;
  @override
  final String type;
  @override
  final MessageSenderModel sender;

  @override
  String toString() {
    return 'MessageReplyModel(id: $id, content: $content, type: $type, sender: $sender)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageReplyModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.sender, sender) || other.sender == sender));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, content, type, sender);

  /// Create a copy of MessageReplyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageReplyModelImplCopyWith<_$MessageReplyModelImpl> get copyWith =>
      __$$MessageReplyModelImplCopyWithImpl<_$MessageReplyModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageReplyModelImplToJson(this);
  }
}

abstract class _MessageReplyModel implements MessageReplyModel {
  const factory _MessageReplyModel({
    required final String id,
    final String? content,
    required final String type,
    required final MessageSenderModel sender,
  }) = _$MessageReplyModelImpl;

  factory _MessageReplyModel.fromJson(Map<String, dynamic> json) =
      _$MessageReplyModelImpl.fromJson;

  @override
  String get id;
  @override
  String? get content;
  @override
  String get type;
  @override
  MessageSenderModel get sender;

  /// Create a copy of MessageReplyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageReplyModelImplCopyWith<_$MessageReplyModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MessageAttachmentModel _$MessageAttachmentModelFromJson(
  Map<String, dynamic> json,
) {
  return _MessageAttachmentModel.fromJson(json);
}

/// @nodoc
mixin _$MessageAttachmentModel {
  String get fileId => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get fileType => throw _privateConstructorUsedError;
  String get mimeType => throw _privateConstructorUsedError;
  String get originalName => throw _privateConstructorUsedError;
  int? get width => throw _privateConstructorUsedError;
  int? get height => throw _privateConstructorUsedError;
  double? get duration => throw _privateConstructorUsedError;
  int? get size => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;

  /// Serializes this MessageAttachmentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageAttachmentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageAttachmentModelCopyWith<MessageAttachmentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageAttachmentModelCopyWith<$Res> {
  factory $MessageAttachmentModelCopyWith(
    MessageAttachmentModel value,
    $Res Function(MessageAttachmentModel) then,
  ) = _$MessageAttachmentModelCopyWithImpl<$Res, MessageAttachmentModel>;
  @useResult
  $Res call({
    String fileId,
    String url,
    String fileType,
    String mimeType,
    String originalName,
    int? width,
    int? height,
    double? duration,
    int? size,
    String? thumbnailUrl,
  });
}

/// @nodoc
class _$MessageAttachmentModelCopyWithImpl<
  $Res,
  $Val extends MessageAttachmentModel
>
    implements $MessageAttachmentModelCopyWith<$Res> {
  _$MessageAttachmentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageAttachmentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileId = null,
    Object? url = null,
    Object? fileType = null,
    Object? mimeType = null,
    Object? originalName = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? duration = freezed,
    Object? size = freezed,
    Object? thumbnailUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            fileId: null == fileId
                ? _value.fileId
                : fileId // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            fileType: null == fileType
                ? _value.fileType
                : fileType // ignore: cast_nullable_to_non_nullable
                      as String,
            mimeType: null == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                      as String,
            originalName: null == originalName
                ? _value.originalName
                : originalName // ignore: cast_nullable_to_non_nullable
                      as String,
            width: freezed == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                      as int?,
            height: freezed == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                      as int?,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as double?,
            size: freezed == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as int?,
            thumbnailUrl: freezed == thumbnailUrl
                ? _value.thumbnailUrl
                : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageAttachmentModelImplCopyWith<$Res>
    implements $MessageAttachmentModelCopyWith<$Res> {
  factory _$$MessageAttachmentModelImplCopyWith(
    _$MessageAttachmentModelImpl value,
    $Res Function(_$MessageAttachmentModelImpl) then,
  ) = __$$MessageAttachmentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String fileId,
    String url,
    String fileType,
    String mimeType,
    String originalName,
    int? width,
    int? height,
    double? duration,
    int? size,
    String? thumbnailUrl,
  });
}

/// @nodoc
class __$$MessageAttachmentModelImplCopyWithImpl<$Res>
    extends
        _$MessageAttachmentModelCopyWithImpl<$Res, _$MessageAttachmentModelImpl>
    implements _$$MessageAttachmentModelImplCopyWith<$Res> {
  __$$MessageAttachmentModelImplCopyWithImpl(
    _$MessageAttachmentModelImpl _value,
    $Res Function(_$MessageAttachmentModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageAttachmentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileId = null,
    Object? url = null,
    Object? fileType = null,
    Object? mimeType = null,
    Object? originalName = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? duration = freezed,
    Object? size = freezed,
    Object? thumbnailUrl = freezed,
  }) {
    return _then(
      _$MessageAttachmentModelImpl(
        fileId: null == fileId
            ? _value.fileId
            : fileId // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        fileType: null == fileType
            ? _value.fileType
            : fileType // ignore: cast_nullable_to_non_nullable
                  as String,
        mimeType: null == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String,
        originalName: null == originalName
            ? _value.originalName
            : originalName // ignore: cast_nullable_to_non_nullable
                  as String,
        width: freezed == width
            ? _value.width
            : width // ignore: cast_nullable_to_non_nullable
                  as int?,
        height: freezed == height
            ? _value.height
            : height // ignore: cast_nullable_to_non_nullable
                  as int?,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as double?,
        size: freezed == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int?,
        thumbnailUrl: freezed == thumbnailUrl
            ? _value.thumbnailUrl
            : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageAttachmentModelImpl implements _MessageAttachmentModel {
  const _$MessageAttachmentModelImpl({
    required this.fileId,
    required this.url,
    required this.fileType,
    required this.mimeType,
    required this.originalName,
    this.width,
    this.height,
    this.duration,
    this.size,
    this.thumbnailUrl,
  });

  factory _$MessageAttachmentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageAttachmentModelImplFromJson(json);

  @override
  final String fileId;
  @override
  final String url;
  @override
  final String fileType;
  @override
  final String mimeType;
  @override
  final String originalName;
  @override
  final int? width;
  @override
  final int? height;
  @override
  final double? duration;
  @override
  final int? size;
  @override
  final String? thumbnailUrl;

  @override
  String toString() {
    return 'MessageAttachmentModel(fileId: $fileId, url: $url, fileType: $fileType, mimeType: $mimeType, originalName: $originalName, width: $width, height: $height, duration: $duration, size: $size, thumbnailUrl: $thumbnailUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageAttachmentModelImpl &&
            (identical(other.fileId, fileId) || other.fileId == fileId) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.originalName, originalName) ||
                other.originalName == originalName) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fileId,
    url,
    fileType,
    mimeType,
    originalName,
    width,
    height,
    duration,
    size,
    thumbnailUrl,
  );

  /// Create a copy of MessageAttachmentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageAttachmentModelImplCopyWith<_$MessageAttachmentModelImpl>
  get copyWith =>
      __$$MessageAttachmentModelImplCopyWithImpl<_$MessageAttachmentModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageAttachmentModelImplToJson(this);
  }
}

abstract class _MessageAttachmentModel implements MessageAttachmentModel {
  const factory _MessageAttachmentModel({
    required final String fileId,
    required final String url,
    required final String fileType,
    required final String mimeType,
    required final String originalName,
    final int? width,
    final int? height,
    final double? duration,
    final int? size,
    final String? thumbnailUrl,
  }) = _$MessageAttachmentModelImpl;

  factory _MessageAttachmentModel.fromJson(Map<String, dynamic> json) =
      _$MessageAttachmentModelImpl.fromJson;

  @override
  String get fileId;
  @override
  String get url;
  @override
  String get fileType;
  @override
  String get mimeType;
  @override
  String get originalName;
  @override
  int? get width;
  @override
  int? get height;
  @override
  double? get duration;
  @override
  int? get size;
  @override
  String? get thumbnailUrl;

  /// Create a copy of MessageAttachmentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageAttachmentModelImplCopyWith<_$MessageAttachmentModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MessageReactionModel _$MessageReactionModelFromJson(Map<String, dynamic> json) {
  return _MessageReactionModel.fromJson(json);
}

/// @nodoc
mixin _$MessageReactionModel {
  String get emoji => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  List<String> get userIds => throw _privateConstructorUsedError;

  /// Serializes this MessageReactionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageReactionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageReactionModelCopyWith<MessageReactionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageReactionModelCopyWith<$Res> {
  factory $MessageReactionModelCopyWith(
    MessageReactionModel value,
    $Res Function(MessageReactionModel) then,
  ) = _$MessageReactionModelCopyWithImpl<$Res, MessageReactionModel>;
  @useResult
  $Res call({String emoji, int count, List<String> userIds});
}

/// @nodoc
class _$MessageReactionModelCopyWithImpl<
  $Res,
  $Val extends MessageReactionModel
>
    implements $MessageReactionModelCopyWith<$Res> {
  _$MessageReactionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageReactionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? emoji = null,
    Object? count = null,
    Object? userIds = null,
  }) {
    return _then(
      _value.copyWith(
            emoji: null == emoji
                ? _value.emoji
                : emoji // ignore: cast_nullable_to_non_nullable
                      as String,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            userIds: null == userIds
                ? _value.userIds
                : userIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageReactionModelImplCopyWith<$Res>
    implements $MessageReactionModelCopyWith<$Res> {
  factory _$$MessageReactionModelImplCopyWith(
    _$MessageReactionModelImpl value,
    $Res Function(_$MessageReactionModelImpl) then,
  ) = __$$MessageReactionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String emoji, int count, List<String> userIds});
}

/// @nodoc
class __$$MessageReactionModelImplCopyWithImpl<$Res>
    extends _$MessageReactionModelCopyWithImpl<$Res, _$MessageReactionModelImpl>
    implements _$$MessageReactionModelImplCopyWith<$Res> {
  __$$MessageReactionModelImplCopyWithImpl(
    _$MessageReactionModelImpl _value,
    $Res Function(_$MessageReactionModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageReactionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? emoji = null,
    Object? count = null,
    Object? userIds = null,
  }) {
    return _then(
      _$MessageReactionModelImpl(
        emoji: null == emoji
            ? _value.emoji
            : emoji // ignore: cast_nullable_to_non_nullable
                  as String,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        userIds: null == userIds
            ? _value._userIds
            : userIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageReactionModelImpl implements _MessageReactionModel {
  const _$MessageReactionModelImpl({
    required this.emoji,
    required this.count,
    required final List<String> userIds,
  }) : _userIds = userIds;

  factory _$MessageReactionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageReactionModelImplFromJson(json);

  @override
  final String emoji;
  @override
  final int count;
  final List<String> _userIds;
  @override
  List<String> get userIds {
    if (_userIds is EqualUnmodifiableListView) return _userIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_userIds);
  }

  @override
  String toString() {
    return 'MessageReactionModel(emoji: $emoji, count: $count, userIds: $userIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageReactionModelImpl &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.count, count) || other.count == count) &&
            const DeepCollectionEquality().equals(other._userIds, _userIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    emoji,
    count,
    const DeepCollectionEquality().hash(_userIds),
  );

  /// Create a copy of MessageReactionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageReactionModelImplCopyWith<_$MessageReactionModelImpl>
  get copyWith =>
      __$$MessageReactionModelImplCopyWithImpl<_$MessageReactionModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageReactionModelImplToJson(this);
  }
}

abstract class _MessageReactionModel implements MessageReactionModel {
  const factory _MessageReactionModel({
    required final String emoji,
    required final int count,
    required final List<String> userIds,
  }) = _$MessageReactionModelImpl;

  factory _MessageReactionModel.fromJson(Map<String, dynamic> json) =
      _$MessageReactionModelImpl.fromJson;

  @override
  String get emoji;
  @override
  int get count;
  @override
  List<String> get userIds;

  /// Create a copy of MessageReactionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageReactionModelImplCopyWith<_$MessageReactionModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MessageVoiceNoteModel _$MessageVoiceNoteModelFromJson(
  Map<String, dynamic> json,
) {
  return _MessageVoiceNoteModel.fromJson(json);
}

/// @nodoc
mixin _$MessageVoiceNoteModel {
  String get fileId => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  List<double>? get waveform => throw _privateConstructorUsedError;

  /// Serializes this MessageVoiceNoteModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageVoiceNoteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageVoiceNoteModelCopyWith<MessageVoiceNoteModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageVoiceNoteModelCopyWith<$Res> {
  factory $MessageVoiceNoteModelCopyWith(
    MessageVoiceNoteModel value,
    $Res Function(MessageVoiceNoteModel) then,
  ) = _$MessageVoiceNoteModelCopyWithImpl<$Res, MessageVoiceNoteModel>;
  @useResult
  $Res call({String fileId, String url, int duration, List<double>? waveform});
}

/// @nodoc
class _$MessageVoiceNoteModelCopyWithImpl<
  $Res,
  $Val extends MessageVoiceNoteModel
>
    implements $MessageVoiceNoteModelCopyWith<$Res> {
  _$MessageVoiceNoteModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageVoiceNoteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileId = null,
    Object? url = null,
    Object? duration = null,
    Object? waveform = freezed,
  }) {
    return _then(
      _value.copyWith(
            fileId: null == fileId
                ? _value.fileId
                : fileId // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            duration: null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as int,
            waveform: freezed == waveform
                ? _value.waveform
                : waveform // ignore: cast_nullable_to_non_nullable
                      as List<double>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageVoiceNoteModelImplCopyWith<$Res>
    implements $MessageVoiceNoteModelCopyWith<$Res> {
  factory _$$MessageVoiceNoteModelImplCopyWith(
    _$MessageVoiceNoteModelImpl value,
    $Res Function(_$MessageVoiceNoteModelImpl) then,
  ) = __$$MessageVoiceNoteModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String fileId, String url, int duration, List<double>? waveform});
}

/// @nodoc
class __$$MessageVoiceNoteModelImplCopyWithImpl<$Res>
    extends
        _$MessageVoiceNoteModelCopyWithImpl<$Res, _$MessageVoiceNoteModelImpl>
    implements _$$MessageVoiceNoteModelImplCopyWith<$Res> {
  __$$MessageVoiceNoteModelImplCopyWithImpl(
    _$MessageVoiceNoteModelImpl _value,
    $Res Function(_$MessageVoiceNoteModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageVoiceNoteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileId = null,
    Object? url = null,
    Object? duration = null,
    Object? waveform = freezed,
  }) {
    return _then(
      _$MessageVoiceNoteModelImpl(
        fileId: null == fileId
            ? _value.fileId
            : fileId // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        duration: null == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as int,
        waveform: freezed == waveform
            ? _value._waveform
            : waveform // ignore: cast_nullable_to_non_nullable
                  as List<double>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageVoiceNoteModelImpl implements _MessageVoiceNoteModel {
  const _$MessageVoiceNoteModelImpl({
    required this.fileId,
    required this.url,
    required this.duration,
    final List<double>? waveform,
  }) : _waveform = waveform;

  factory _$MessageVoiceNoteModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageVoiceNoteModelImplFromJson(json);

  @override
  final String fileId;
  @override
  final String url;
  @override
  final int duration;
  final List<double>? _waveform;
  @override
  List<double>? get waveform {
    final value = _waveform;
    if (value == null) return null;
    if (_waveform is EqualUnmodifiableListView) return _waveform;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'MessageVoiceNoteModel(fileId: $fileId, url: $url, duration: $duration, waveform: $waveform)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageVoiceNoteModelImpl &&
            (identical(other.fileId, fileId) || other.fileId == fileId) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            const DeepCollectionEquality().equals(other._waveform, _waveform));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fileId,
    url,
    duration,
    const DeepCollectionEquality().hash(_waveform),
  );

  /// Create a copy of MessageVoiceNoteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageVoiceNoteModelImplCopyWith<_$MessageVoiceNoteModelImpl>
  get copyWith =>
      __$$MessageVoiceNoteModelImplCopyWithImpl<_$MessageVoiceNoteModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageVoiceNoteModelImplToJson(this);
  }
}

abstract class _MessageVoiceNoteModel implements MessageVoiceNoteModel {
  const factory _MessageVoiceNoteModel({
    required final String fileId,
    required final String url,
    required final int duration,
    final List<double>? waveform,
  }) = _$MessageVoiceNoteModelImpl;

  factory _MessageVoiceNoteModel.fromJson(Map<String, dynamic> json) =
      _$MessageVoiceNoteModelImpl.fromJson;

  @override
  String get fileId;
  @override
  String get url;
  @override
  int get duration;
  @override
  List<double>? get waveform;

  /// Create a copy of MessageVoiceNoteModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageVoiceNoteModelImplCopyWith<_$MessageVoiceNoteModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MessageForwardModel _$MessageForwardModelFromJson(Map<String, dynamic> json) {
  return _MessageForwardModel.fromJson(json);
}

/// @nodoc
mixin _$MessageForwardModel {
  String get originalMessageId => throw _privateConstructorUsedError;
  MessageSenderModel get originalSender => throw _privateConstructorUsedError;
  DateTime get originalCreatedAt => throw _privateConstructorUsedError;

  /// Serializes this MessageForwardModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageForwardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageForwardModelCopyWith<MessageForwardModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageForwardModelCopyWith<$Res> {
  factory $MessageForwardModelCopyWith(
    MessageForwardModel value,
    $Res Function(MessageForwardModel) then,
  ) = _$MessageForwardModelCopyWithImpl<$Res, MessageForwardModel>;
  @useResult
  $Res call({
    String originalMessageId,
    MessageSenderModel originalSender,
    DateTime originalCreatedAt,
  });

  $MessageSenderModelCopyWith<$Res> get originalSender;
}

/// @nodoc
class _$MessageForwardModelCopyWithImpl<$Res, $Val extends MessageForwardModel>
    implements $MessageForwardModelCopyWith<$Res> {
  _$MessageForwardModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageForwardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalMessageId = null,
    Object? originalSender = null,
    Object? originalCreatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            originalMessageId: null == originalMessageId
                ? _value.originalMessageId
                : originalMessageId // ignore: cast_nullable_to_non_nullable
                      as String,
            originalSender: null == originalSender
                ? _value.originalSender
                : originalSender // ignore: cast_nullable_to_non_nullable
                      as MessageSenderModel,
            originalCreatedAt: null == originalCreatedAt
                ? _value.originalCreatedAt
                : originalCreatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }

  /// Create a copy of MessageForwardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageSenderModelCopyWith<$Res> get originalSender {
    return $MessageSenderModelCopyWith<$Res>(_value.originalSender, (value) {
      return _then(_value.copyWith(originalSender: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MessageForwardModelImplCopyWith<$Res>
    implements $MessageForwardModelCopyWith<$Res> {
  factory _$$MessageForwardModelImplCopyWith(
    _$MessageForwardModelImpl value,
    $Res Function(_$MessageForwardModelImpl) then,
  ) = __$$MessageForwardModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String originalMessageId,
    MessageSenderModel originalSender,
    DateTime originalCreatedAt,
  });

  @override
  $MessageSenderModelCopyWith<$Res> get originalSender;
}

/// @nodoc
class __$$MessageForwardModelImplCopyWithImpl<$Res>
    extends _$MessageForwardModelCopyWithImpl<$Res, _$MessageForwardModelImpl>
    implements _$$MessageForwardModelImplCopyWith<$Res> {
  __$$MessageForwardModelImplCopyWithImpl(
    _$MessageForwardModelImpl _value,
    $Res Function(_$MessageForwardModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageForwardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalMessageId = null,
    Object? originalSender = null,
    Object? originalCreatedAt = null,
  }) {
    return _then(
      _$MessageForwardModelImpl(
        originalMessageId: null == originalMessageId
            ? _value.originalMessageId
            : originalMessageId // ignore: cast_nullable_to_non_nullable
                  as String,
        originalSender: null == originalSender
            ? _value.originalSender
            : originalSender // ignore: cast_nullable_to_non_nullable
                  as MessageSenderModel,
        originalCreatedAt: null == originalCreatedAt
            ? _value.originalCreatedAt
            : originalCreatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageForwardModelImpl implements _MessageForwardModel {
  const _$MessageForwardModelImpl({
    required this.originalMessageId,
    required this.originalSender,
    required this.originalCreatedAt,
  });

  factory _$MessageForwardModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageForwardModelImplFromJson(json);

  @override
  final String originalMessageId;
  @override
  final MessageSenderModel originalSender;
  @override
  final DateTime originalCreatedAt;

  @override
  String toString() {
    return 'MessageForwardModel(originalMessageId: $originalMessageId, originalSender: $originalSender, originalCreatedAt: $originalCreatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageForwardModelImpl &&
            (identical(other.originalMessageId, originalMessageId) ||
                other.originalMessageId == originalMessageId) &&
            (identical(other.originalSender, originalSender) ||
                other.originalSender == originalSender) &&
            (identical(other.originalCreatedAt, originalCreatedAt) ||
                other.originalCreatedAt == originalCreatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    originalMessageId,
    originalSender,
    originalCreatedAt,
  );

  /// Create a copy of MessageForwardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageForwardModelImplCopyWith<_$MessageForwardModelImpl> get copyWith =>
      __$$MessageForwardModelImplCopyWithImpl<_$MessageForwardModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageForwardModelImplToJson(this);
  }
}

abstract class _MessageForwardModel implements MessageForwardModel {
  const factory _MessageForwardModel({
    required final String originalMessageId,
    required final MessageSenderModel originalSender,
    required final DateTime originalCreatedAt,
  }) = _$MessageForwardModelImpl;

  factory _MessageForwardModel.fromJson(Map<String, dynamic> json) =
      _$MessageForwardModelImpl.fromJson;

  @override
  String get originalMessageId;
  @override
  MessageSenderModel get originalSender;
  @override
  DateTime get originalCreatedAt;

  /// Create a copy of MessageForwardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageForwardModelImplCopyWith<_$MessageForwardModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PaginatedMessagesModel _$PaginatedMessagesModelFromJson(
  Map<String, dynamic> json,
) {
  return _PaginatedMessagesModel.fromJson(json);
}

/// @nodoc
mixin _$PaginatedMessagesModel {
  List<MessageModel> get data => throw _privateConstructorUsedError;
  String? get nextCursor => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;

  /// Serializes this PaginatedMessagesModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaginatedMessagesModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaginatedMessagesModelCopyWith<PaginatedMessagesModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginatedMessagesModelCopyWith<$Res> {
  factory $PaginatedMessagesModelCopyWith(
    PaginatedMessagesModel value,
    $Res Function(PaginatedMessagesModel) then,
  ) = _$PaginatedMessagesModelCopyWithImpl<$Res, PaginatedMessagesModel>;
  @useResult
  $Res call({List<MessageModel> data, String? nextCursor, bool hasMore});
}

/// @nodoc
class _$PaginatedMessagesModelCopyWithImpl<
  $Res,
  $Val extends PaginatedMessagesModel
>
    implements $PaginatedMessagesModelCopyWith<$Res> {
  _$PaginatedMessagesModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaginatedMessagesModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? nextCursor = freezed,
    Object? hasMore = null,
  }) {
    return _then(
      _value.copyWith(
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as List<MessageModel>,
            nextCursor: freezed == nextCursor
                ? _value.nextCursor
                : nextCursor // ignore: cast_nullable_to_non_nullable
                      as String?,
            hasMore: null == hasMore
                ? _value.hasMore
                : hasMore // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaginatedMessagesModelImplCopyWith<$Res>
    implements $PaginatedMessagesModelCopyWith<$Res> {
  factory _$$PaginatedMessagesModelImplCopyWith(
    _$PaginatedMessagesModelImpl value,
    $Res Function(_$PaginatedMessagesModelImpl) then,
  ) = __$$PaginatedMessagesModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MessageModel> data, String? nextCursor, bool hasMore});
}

/// @nodoc
class __$$PaginatedMessagesModelImplCopyWithImpl<$Res>
    extends
        _$PaginatedMessagesModelCopyWithImpl<$Res, _$PaginatedMessagesModelImpl>
    implements _$$PaginatedMessagesModelImplCopyWith<$Res> {
  __$$PaginatedMessagesModelImplCopyWithImpl(
    _$PaginatedMessagesModelImpl _value,
    $Res Function(_$PaginatedMessagesModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaginatedMessagesModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? nextCursor = freezed,
    Object? hasMore = null,
  }) {
    return _then(
      _$PaginatedMessagesModelImpl(
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as List<MessageModel>,
        nextCursor: freezed == nextCursor
            ? _value.nextCursor
            : nextCursor // ignore: cast_nullable_to_non_nullable
                  as String?,
        hasMore: null == hasMore
            ? _value.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaginatedMessagesModelImpl implements _PaginatedMessagesModel {
  const _$PaginatedMessagesModelImpl({
    required final List<MessageModel> data,
    this.nextCursor,
    this.hasMore = false,
  }) : _data = data;

  factory _$PaginatedMessagesModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaginatedMessagesModelImplFromJson(json);

  final List<MessageModel> _data;
  @override
  List<MessageModel> get data {
    if (_data is EqualUnmodifiableListView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_data);
  }

  @override
  final String? nextCursor;
  @override
  @JsonKey()
  final bool hasMore;

  @override
  String toString() {
    return 'PaginatedMessagesModel(data: $data, nextCursor: $nextCursor, hasMore: $hasMore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginatedMessagesModelImpl &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.nextCursor, nextCursor) ||
                other.nextCursor == nextCursor) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_data),
    nextCursor,
    hasMore,
  );

  /// Create a copy of PaginatedMessagesModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginatedMessagesModelImplCopyWith<_$PaginatedMessagesModelImpl>
  get copyWith =>
      __$$PaginatedMessagesModelImplCopyWithImpl<_$PaginatedMessagesModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PaginatedMessagesModelImplToJson(this);
  }
}

abstract class _PaginatedMessagesModel implements PaginatedMessagesModel {
  const factory _PaginatedMessagesModel({
    required final List<MessageModel> data,
    final String? nextCursor,
    final bool hasMore,
  }) = _$PaginatedMessagesModelImpl;

  factory _PaginatedMessagesModel.fromJson(Map<String, dynamic> json) =
      _$PaginatedMessagesModelImpl.fromJson;

  @override
  List<MessageModel> get data;
  @override
  String? get nextCursor;
  @override
  bool get hasMore;

  /// Create a copy of PaginatedMessagesModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaginatedMessagesModelImplCopyWith<_$PaginatedMessagesModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
