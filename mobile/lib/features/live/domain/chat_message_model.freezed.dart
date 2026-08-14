// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChatSenderDto _$ChatSenderDtoFromJson(Map<String, dynamic> json) {
  return _ChatSenderDto.fromJson(json);
}

/// @nodoc
mixin _$ChatSenderDto {
  String get id => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Serializes this ChatSenderDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatSenderDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatSenderDtoCopyWith<ChatSenderDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatSenderDtoCopyWith<$Res> {
  factory $ChatSenderDtoCopyWith(
    ChatSenderDto value,
    $Res Function(ChatSenderDto) then,
  ) = _$ChatSenderDtoCopyWithImpl<$Res, ChatSenderDto>;
  @useResult
  $Res call({
    String id,
    String? username,
    String? displayName,
    String? avatarUrl,
  });
}

/// @nodoc
class _$ChatSenderDtoCopyWithImpl<$Res, $Val extends ChatSenderDto>
    implements $ChatSenderDtoCopyWith<$Res> {
  _$ChatSenderDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatSenderDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = freezed,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            username: freezed == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$ChatSenderDtoImplCopyWith<$Res>
    implements $ChatSenderDtoCopyWith<$Res> {
  factory _$$ChatSenderDtoImplCopyWith(
    _$ChatSenderDtoImpl value,
    $Res Function(_$ChatSenderDtoImpl) then,
  ) = __$$ChatSenderDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? username,
    String? displayName,
    String? avatarUrl,
  });
}

/// @nodoc
class __$$ChatSenderDtoImplCopyWithImpl<$Res>
    extends _$ChatSenderDtoCopyWithImpl<$Res, _$ChatSenderDtoImpl>
    implements _$$ChatSenderDtoImplCopyWith<$Res> {
  __$$ChatSenderDtoImplCopyWithImpl(
    _$ChatSenderDtoImpl _value,
    $Res Function(_$ChatSenderDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatSenderDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = freezed,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _$ChatSenderDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        username: freezed == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$ChatSenderDtoImpl implements _ChatSenderDto {
  const _$ChatSenderDtoImpl({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory _$ChatSenderDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatSenderDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String? username;
  @override
  final String? displayName;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'ChatSenderDto(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatSenderDtoImpl &&
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

  /// Create a copy of ChatSenderDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatSenderDtoImplCopyWith<_$ChatSenderDtoImpl> get copyWith =>
      __$$ChatSenderDtoImplCopyWithImpl<_$ChatSenderDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatSenderDtoImplToJson(this);
  }
}

abstract class _ChatSenderDto implements ChatSenderDto {
  const factory _ChatSenderDto({
    required final String id,
    final String? username,
    final String? displayName,
    final String? avatarUrl,
  }) = _$ChatSenderDtoImpl;

  factory _ChatSenderDto.fromJson(Map<String, dynamic> json) =
      _$ChatSenderDtoImpl.fromJson;

  @override
  String get id;
  @override
  String? get username;
  @override
  String? get displayName;
  @override
  String? get avatarUrl;

  /// Create a copy of ChatSenderDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatSenderDtoImplCopyWith<_$ChatSenderDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatMessageDto _$ChatMessageDtoFromJson(Map<String, dynamic> json) {
  return _ChatMessageDto.fromJson(json);
}

/// @nodoc
mixin _$ChatMessageDto {
  String get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  ChatMessageType get type => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  ChatSenderDto? get sender =>
      throw _privateConstructorUsedError; // Locally tracked send status (not from backend)
  bool get isPending => throw _privateConstructorUsedError;
  bool get isError => throw _privateConstructorUsedError;

  /// Serializes this ChatMessageDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageDtoCopyWith<ChatMessageDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageDtoCopyWith<$Res> {
  factory $ChatMessageDtoCopyWith(
    ChatMessageDto value,
    $Res Function(ChatMessageDto) then,
  ) = _$ChatMessageDtoCopyWithImpl<$Res, ChatMessageDto>;
  @useResult
  $Res call({
    String id,
    String content,
    ChatMessageType type,
    bool isPinned,
    bool isDeleted,
    String createdAt,
    ChatSenderDto? sender,
    bool isPending,
    bool isError,
  });

  $ChatSenderDtoCopyWith<$Res>? get sender;
}

/// @nodoc
class _$ChatMessageDtoCopyWithImpl<$Res, $Val extends ChatMessageDto>
    implements $ChatMessageDtoCopyWith<$Res> {
  _$ChatMessageDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? type = null,
    Object? isPinned = null,
    Object? isDeleted = null,
    Object? createdAt = null,
    Object? sender = freezed,
    Object? isPending = null,
    Object? isError = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as ChatMessageType,
            isPinned: null == isPinned
                ? _value.isPinned
                : isPinned // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            sender: freezed == sender
                ? _value.sender
                : sender // ignore: cast_nullable_to_non_nullable
                      as ChatSenderDto?,
            isPending: null == isPending
                ? _value.isPending
                : isPending // ignore: cast_nullable_to_non_nullable
                      as bool,
            isError: null == isError
                ? _value.isError
                : isError // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of ChatMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChatSenderDtoCopyWith<$Res>? get sender {
    if (_value.sender == null) {
      return null;
    }

    return $ChatSenderDtoCopyWith<$Res>(_value.sender!, (value) {
      return _then(_value.copyWith(sender: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ChatMessageDtoImplCopyWith<$Res>
    implements $ChatMessageDtoCopyWith<$Res> {
  factory _$$ChatMessageDtoImplCopyWith(
    _$ChatMessageDtoImpl value,
    $Res Function(_$ChatMessageDtoImpl) then,
  ) = __$$ChatMessageDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String content,
    ChatMessageType type,
    bool isPinned,
    bool isDeleted,
    String createdAt,
    ChatSenderDto? sender,
    bool isPending,
    bool isError,
  });

  @override
  $ChatSenderDtoCopyWith<$Res>? get sender;
}

/// @nodoc
class __$$ChatMessageDtoImplCopyWithImpl<$Res>
    extends _$ChatMessageDtoCopyWithImpl<$Res, _$ChatMessageDtoImpl>
    implements _$$ChatMessageDtoImplCopyWith<$Res> {
  __$$ChatMessageDtoImplCopyWithImpl(
    _$ChatMessageDtoImpl _value,
    $Res Function(_$ChatMessageDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? type = null,
    Object? isPinned = null,
    Object? isDeleted = null,
    Object? createdAt = null,
    Object? sender = freezed,
    Object? isPending = null,
    Object? isError = null,
  }) {
    return _then(
      _$ChatMessageDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ChatMessageType,
        isPinned: null == isPinned
            ? _value.isPinned
            : isPinned // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        sender: freezed == sender
            ? _value.sender
            : sender // ignore: cast_nullable_to_non_nullable
                  as ChatSenderDto?,
        isPending: null == isPending
            ? _value.isPending
            : isPending // ignore: cast_nullable_to_non_nullable
                  as bool,
        isError: null == isError
            ? _value.isError
            : isError // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageDtoImpl implements _ChatMessageDto {
  const _$ChatMessageDtoImpl({
    required this.id,
    required this.content,
    this.type = ChatMessageType.text,
    this.isPinned = false,
    this.isDeleted = false,
    required this.createdAt,
    this.sender,
    this.isPending = false,
    this.isError = false,
  });

  factory _$ChatMessageDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String content;
  @override
  @JsonKey()
  final ChatMessageType type;
  @override
  @JsonKey()
  final bool isPinned;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  final String createdAt;
  @override
  final ChatSenderDto? sender;
  // Locally tracked send status (not from backend)
  @override
  @JsonKey()
  final bool isPending;
  @override
  @JsonKey()
  final bool isError;

  @override
  String toString() {
    return 'ChatMessageDto(id: $id, content: $content, type: $type, isPinned: $isPinned, isDeleted: $isDeleted, createdAt: $createdAt, sender: $sender, isPending: $isPending, isError: $isError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.sender, sender) || other.sender == sender) &&
            (identical(other.isPending, isPending) ||
                other.isPending == isPending) &&
            (identical(other.isError, isError) || other.isError == isError));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    content,
    type,
    isPinned,
    isDeleted,
    createdAt,
    sender,
    isPending,
    isError,
  );

  /// Create a copy of ChatMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageDtoImplCopyWith<_$ChatMessageDtoImpl> get copyWith =>
      __$$ChatMessageDtoImplCopyWithImpl<_$ChatMessageDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageDtoImplToJson(this);
  }
}

abstract class _ChatMessageDto implements ChatMessageDto {
  const factory _ChatMessageDto({
    required final String id,
    required final String content,
    final ChatMessageType type,
    final bool isPinned,
    final bool isDeleted,
    required final String createdAt,
    final ChatSenderDto? sender,
    final bool isPending,
    final bool isError,
  }) = _$ChatMessageDtoImpl;

  factory _ChatMessageDto.fromJson(Map<String, dynamic> json) =
      _$ChatMessageDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get content;
  @override
  ChatMessageType get type;
  @override
  bool get isPinned;
  @override
  bool get isDeleted;
  @override
  String get createdAt;
  @override
  ChatSenderDto? get sender; // Locally tracked send status (not from backend)
  @override
  bool get isPending;
  @override
  bool get isError;

  /// Create a copy of ChatMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageDtoImplCopyWith<_$ChatMessageDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatReactionEvent _$ChatReactionEventFromJson(Map<String, dynamic> json) {
  return _ChatReactionEvent.fromJson(json);
}

/// @nodoc
mixin _$ChatReactionEvent {
  String get messageId => throw _privateConstructorUsedError;
  String get emoji => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  String get reactionId => throw _privateConstructorUsedError;

  /// Serializes this ChatReactionEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatReactionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatReactionEventCopyWith<ChatReactionEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatReactionEventCopyWith<$Res> {
  factory $ChatReactionEventCopyWith(
    ChatReactionEvent value,
    $Res Function(ChatReactionEvent) then,
  ) = _$ChatReactionEventCopyWithImpl<$Res, ChatReactionEvent>;
  @useResult
  $Res call({String messageId, String emoji, int count, String reactionId});
}

/// @nodoc
class _$ChatReactionEventCopyWithImpl<$Res, $Val extends ChatReactionEvent>
    implements $ChatReactionEventCopyWith<$Res> {
  _$ChatReactionEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatReactionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? emoji = null,
    Object? count = null,
    Object? reactionId = null,
  }) {
    return _then(
      _value.copyWith(
            messageId: null == messageId
                ? _value.messageId
                : messageId // ignore: cast_nullable_to_non_nullable
                      as String,
            emoji: null == emoji
                ? _value.emoji
                : emoji // ignore: cast_nullable_to_non_nullable
                      as String,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            reactionId: null == reactionId
                ? _value.reactionId
                : reactionId // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatReactionEventImplCopyWith<$Res>
    implements $ChatReactionEventCopyWith<$Res> {
  factory _$$ChatReactionEventImplCopyWith(
    _$ChatReactionEventImpl value,
    $Res Function(_$ChatReactionEventImpl) then,
  ) = __$$ChatReactionEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String messageId, String emoji, int count, String reactionId});
}

/// @nodoc
class __$$ChatReactionEventImplCopyWithImpl<$Res>
    extends _$ChatReactionEventCopyWithImpl<$Res, _$ChatReactionEventImpl>
    implements _$$ChatReactionEventImplCopyWith<$Res> {
  __$$ChatReactionEventImplCopyWithImpl(
    _$ChatReactionEventImpl _value,
    $Res Function(_$ChatReactionEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatReactionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? emoji = null,
    Object? count = null,
    Object? reactionId = null,
  }) {
    return _then(
      _$ChatReactionEventImpl(
        messageId: null == messageId
            ? _value.messageId
            : messageId // ignore: cast_nullable_to_non_nullable
                  as String,
        emoji: null == emoji
            ? _value.emoji
            : emoji // ignore: cast_nullable_to_non_nullable
                  as String,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        reactionId: null == reactionId
            ? _value.reactionId
            : reactionId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatReactionEventImpl implements _ChatReactionEvent {
  const _$ChatReactionEventImpl({
    required this.messageId,
    required this.emoji,
    required this.count,
    required this.reactionId,
  });

  factory _$ChatReactionEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatReactionEventImplFromJson(json);

  @override
  final String messageId;
  @override
  final String emoji;
  @override
  final int count;
  @override
  final String reactionId;

  @override
  String toString() {
    return 'ChatReactionEvent(messageId: $messageId, emoji: $emoji, count: $count, reactionId: $reactionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatReactionEventImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.reactionId, reactionId) ||
                other.reactionId == reactionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, messageId, emoji, count, reactionId);

  /// Create a copy of ChatReactionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatReactionEventImplCopyWith<_$ChatReactionEventImpl> get copyWith =>
      __$$ChatReactionEventImplCopyWithImpl<_$ChatReactionEventImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatReactionEventImplToJson(this);
  }
}

abstract class _ChatReactionEvent implements ChatReactionEvent {
  const factory _ChatReactionEvent({
    required final String messageId,
    required final String emoji,
    required final int count,
    required final String reactionId,
  }) = _$ChatReactionEventImpl;

  factory _ChatReactionEvent.fromJson(Map<String, dynamic> json) =
      _$ChatReactionEventImpl.fromJson;

  @override
  String get messageId;
  @override
  String get emoji;
  @override
  int get count;
  @override
  String get reactionId;

  /// Create a copy of ChatReactionEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatReactionEventImplCopyWith<_$ChatReactionEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatHistoryResponse _$ChatHistoryResponseFromJson(Map<String, dynamic> json) {
  return _ChatHistoryResponse.fromJson(json);
}

/// @nodoc
mixin _$ChatHistoryResponse {
  List<ChatMessageDto> get messages => throw _privateConstructorUsedError;
  String? get nextCursor => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;

  /// Serializes this ChatHistoryResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatHistoryResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatHistoryResponseCopyWith<ChatHistoryResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatHistoryResponseCopyWith<$Res> {
  factory $ChatHistoryResponseCopyWith(
    ChatHistoryResponse value,
    $Res Function(ChatHistoryResponse) then,
  ) = _$ChatHistoryResponseCopyWithImpl<$Res, ChatHistoryResponse>;
  @useResult
  $Res call({List<ChatMessageDto> messages, String? nextCursor, bool hasMore});
}

/// @nodoc
class _$ChatHistoryResponseCopyWithImpl<$Res, $Val extends ChatHistoryResponse>
    implements $ChatHistoryResponseCopyWith<$Res> {
  _$ChatHistoryResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatHistoryResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? nextCursor = freezed,
    Object? hasMore = null,
  }) {
    return _then(
      _value.copyWith(
            messages: null == messages
                ? _value.messages
                : messages // ignore: cast_nullable_to_non_nullable
                      as List<ChatMessageDto>,
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
abstract class _$$ChatHistoryResponseImplCopyWith<$Res>
    implements $ChatHistoryResponseCopyWith<$Res> {
  factory _$$ChatHistoryResponseImplCopyWith(
    _$ChatHistoryResponseImpl value,
    $Res Function(_$ChatHistoryResponseImpl) then,
  ) = __$$ChatHistoryResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ChatMessageDto> messages, String? nextCursor, bool hasMore});
}

/// @nodoc
class __$$ChatHistoryResponseImplCopyWithImpl<$Res>
    extends _$ChatHistoryResponseCopyWithImpl<$Res, _$ChatHistoryResponseImpl>
    implements _$$ChatHistoryResponseImplCopyWith<$Res> {
  __$$ChatHistoryResponseImplCopyWithImpl(
    _$ChatHistoryResponseImpl _value,
    $Res Function(_$ChatHistoryResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatHistoryResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? nextCursor = freezed,
    Object? hasMore = null,
  }) {
    return _then(
      _$ChatHistoryResponseImpl(
        messages: null == messages
            ? _value._messages
            : messages // ignore: cast_nullable_to_non_nullable
                  as List<ChatMessageDto>,
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
class _$ChatHistoryResponseImpl implements _ChatHistoryResponse {
  const _$ChatHistoryResponseImpl({
    required final List<ChatMessageDto> messages,
    this.nextCursor,
    this.hasMore = false,
  }) : _messages = messages;

  factory _$ChatHistoryResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatHistoryResponseImplFromJson(json);

  final List<ChatMessageDto> _messages;
  @override
  List<ChatMessageDto> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  final String? nextCursor;
  @override
  @JsonKey()
  final bool hasMore;

  @override
  String toString() {
    return 'ChatHistoryResponse(messages: $messages, nextCursor: $nextCursor, hasMore: $hasMore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatHistoryResponseImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.nextCursor, nextCursor) ||
                other.nextCursor == nextCursor) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_messages),
    nextCursor,
    hasMore,
  );

  /// Create a copy of ChatHistoryResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatHistoryResponseImplCopyWith<_$ChatHistoryResponseImpl> get copyWith =>
      __$$ChatHistoryResponseImplCopyWithImpl<_$ChatHistoryResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatHistoryResponseImplToJson(this);
  }
}

abstract class _ChatHistoryResponse implements ChatHistoryResponse {
  const factory _ChatHistoryResponse({
    required final List<ChatMessageDto> messages,
    final String? nextCursor,
    final bool hasMore,
  }) = _$ChatHistoryResponseImpl;

  factory _ChatHistoryResponse.fromJson(Map<String, dynamic> json) =
      _$ChatHistoryResponseImpl.fromJson;

  @override
  List<ChatMessageDto> get messages;
  @override
  String? get nextCursor;
  @override
  bool get hasMore;

  /// Create a copy of ChatHistoryResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatHistoryResponseImplCopyWith<_$ChatHistoryResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
