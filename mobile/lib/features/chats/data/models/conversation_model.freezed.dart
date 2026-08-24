// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ConversationModel _$ConversationModelFromJson(Map<String, dynamic> json) {
  return _ConversationModel.fromJson(json);
}

/// @nodoc
mixin _$ConversationModel {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  String? get channelId => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  MessagePreviewModel? get lastMessage => throw _privateConstructorUsedError;
  List<ConversationMemberModel> get members =>
      throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  ConversationMetadataModel? get metadata => throw _privateConstructorUsedError;

  /// Serializes this ConversationModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationModelCopyWith<ConversationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationModelCopyWith<$Res> {
  factory $ConversationModelCopyWith(
    ConversationModel value,
    $Res Function(ConversationModel) then,
  ) = _$ConversationModelCopyWithImpl<$Res, ConversationModel>;
  @useResult
  $Res call({
    String id,
    String type,
    String? groupId,
    String? channelId,
    String? title,
    DateTime? lastMessageAt,
    MessagePreviewModel? lastMessage,
    List<ConversationMemberModel> members,
    DateTime createdAt,
    ConversationMetadataModel? metadata,
  });

  $MessagePreviewModelCopyWith<$Res>? get lastMessage;
  $ConversationMetadataModelCopyWith<$Res>? get metadata;
}

/// @nodoc
class _$ConversationModelCopyWithImpl<$Res, $Val extends ConversationModel>
    implements $ConversationModelCopyWith<$Res> {
  _$ConversationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? groupId = freezed,
    Object? channelId = freezed,
    Object? title = freezed,
    Object? lastMessageAt = freezed,
    Object? lastMessage = freezed,
    Object? members = null,
    Object? createdAt = null,
    Object? metadata = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            groupId: freezed == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String?,
            channelId: freezed == channelId
                ? _value.channelId
                : channelId // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastMessageAt: freezed == lastMessageAt
                ? _value.lastMessageAt
                : lastMessageAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastMessage: freezed == lastMessage
                ? _value.lastMessage
                : lastMessage // ignore: cast_nullable_to_non_nullable
                      as MessagePreviewModel?,
            members: null == members
                ? _value.members
                : members // ignore: cast_nullable_to_non_nullable
                      as List<ConversationMemberModel>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as ConversationMetadataModel?,
          )
          as $Val,
    );
  }

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessagePreviewModelCopyWith<$Res>? get lastMessage {
    if (_value.lastMessage == null) {
      return null;
    }

    return $MessagePreviewModelCopyWith<$Res>(_value.lastMessage!, (value) {
      return _then(_value.copyWith(lastMessage: value) as $Val);
    });
  }

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConversationMetadataModelCopyWith<$Res>? get metadata {
    if (_value.metadata == null) {
      return null;
    }

    return $ConversationMetadataModelCopyWith<$Res>(_value.metadata!, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConversationModelImplCopyWith<$Res>
    implements $ConversationModelCopyWith<$Res> {
  factory _$$ConversationModelImplCopyWith(
    _$ConversationModelImpl value,
    $Res Function(_$ConversationModelImpl) then,
  ) = __$$ConversationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String type,
    String? groupId,
    String? channelId,
    String? title,
    DateTime? lastMessageAt,
    MessagePreviewModel? lastMessage,
    List<ConversationMemberModel> members,
    DateTime createdAt,
    ConversationMetadataModel? metadata,
  });

  @override
  $MessagePreviewModelCopyWith<$Res>? get lastMessage;
  @override
  $ConversationMetadataModelCopyWith<$Res>? get metadata;
}

/// @nodoc
class __$$ConversationModelImplCopyWithImpl<$Res>
    extends _$ConversationModelCopyWithImpl<$Res, _$ConversationModelImpl>
    implements _$$ConversationModelImplCopyWith<$Res> {
  __$$ConversationModelImplCopyWithImpl(
    _$ConversationModelImpl _value,
    $Res Function(_$ConversationModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? groupId = freezed,
    Object? channelId = freezed,
    Object? title = freezed,
    Object? lastMessageAt = freezed,
    Object? lastMessage = freezed,
    Object? members = null,
    Object? createdAt = null,
    Object? metadata = freezed,
  }) {
    return _then(
      _$ConversationModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        groupId: freezed == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String?,
        channelId: freezed == channelId
            ? _value.channelId
            : channelId // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastMessageAt: freezed == lastMessageAt
            ? _value.lastMessageAt
            : lastMessageAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastMessage: freezed == lastMessage
            ? _value.lastMessage
            : lastMessage // ignore: cast_nullable_to_non_nullable
                  as MessagePreviewModel?,
        members: null == members
            ? _value._members
            : members // ignore: cast_nullable_to_non_nullable
                  as List<ConversationMemberModel>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        metadata: freezed == metadata
            ? _value.metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as ConversationMetadataModel?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationModelImpl implements _ConversationModel {
  const _$ConversationModelImpl({
    required this.id,
    required this.type,
    this.groupId,
    this.channelId,
    this.title,
    this.lastMessageAt,
    this.lastMessage,
    final List<ConversationMemberModel> members = const [],
    required this.createdAt,
    this.metadata,
  }) : _members = members;

  factory _$ConversationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationModelImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  @override
  final String? groupId;
  @override
  final String? channelId;
  @override
  final String? title;
  @override
  final DateTime? lastMessageAt;
  @override
  final MessagePreviewModel? lastMessage;
  final List<ConversationMemberModel> _members;
  @override
  @JsonKey()
  List<ConversationMemberModel> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  final DateTime createdAt;
  @override
  final ConversationMetadataModel? metadata;

  @override
  String toString() {
    return 'ConversationModel(id: $id, type: $type, groupId: $groupId, channelId: $channelId, title: $title, lastMessageAt: $lastMessageAt, lastMessage: $lastMessage, members: $members, createdAt: $createdAt, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.channelId, channelId) ||
                other.channelId == channelId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    groupId,
    channelId,
    title,
    lastMessageAt,
    lastMessage,
    const DeepCollectionEquality().hash(_members),
    createdAt,
    metadata,
  );

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationModelImplCopyWith<_$ConversationModelImpl> get copyWith =>
      __$$ConversationModelImplCopyWithImpl<_$ConversationModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationModelImplToJson(this);
  }
}

abstract class _ConversationModel implements ConversationModel {
  const factory _ConversationModel({
    required final String id,
    required final String type,
    final String? groupId,
    final String? channelId,
    final String? title,
    final DateTime? lastMessageAt,
    final MessagePreviewModel? lastMessage,
    final List<ConversationMemberModel> members,
    required final DateTime createdAt,
    final ConversationMetadataModel? metadata,
  }) = _$ConversationModelImpl;

  factory _ConversationModel.fromJson(Map<String, dynamic> json) =
      _$ConversationModelImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  String? get groupId;
  @override
  String? get channelId;
  @override
  String? get title;
  @override
  DateTime? get lastMessageAt;
  @override
  MessagePreviewModel? get lastMessage;
  @override
  List<ConversationMemberModel> get members;
  @override
  DateTime get createdAt;
  @override
  ConversationMetadataModel? get metadata;

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationModelImplCopyWith<_$ConversationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConversationMemberModel _$ConversationMemberModelFromJson(
  Map<String, dynamic> json,
) {
  return _ConversationMemberModel.fromJson(json);
}

/// @nodoc
mixin _$ConversationMemberModel {
  String get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  int get unreadCount => throw _privateConstructorUsedError;
  bool get isMuted => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;
  bool get isOnline => throw _privateConstructorUsedError;
  String? get lastSeen => throw _privateConstructorUsedError;
  TypingStatusModel? get typingStatus => throw _privateConstructorUsedError;

  /// Serializes this ConversationMemberModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConversationMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationMemberModelCopyWith<ConversationMemberModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationMemberModelCopyWith<$Res> {
  factory $ConversationMemberModelCopyWith(
    ConversationMemberModel value,
    $Res Function(ConversationMemberModel) then,
  ) = _$ConversationMemberModelCopyWithImpl<$Res, ConversationMemberModel>;
  @useResult
  $Res call({
    String userId,
    String username,
    String? displayName,
    String? avatarUrl,
    int unreadCount,
    bool isMuted,
    bool isPinned,
    bool isOnline,
    String? lastSeen,
    TypingStatusModel? typingStatus,
  });

  $TypingStatusModelCopyWith<$Res>? get typingStatus;
}

/// @nodoc
class _$ConversationMemberModelCopyWithImpl<
  $Res,
  $Val extends ConversationMemberModel
>
    implements $ConversationMemberModelCopyWith<$Res> {
  _$ConversationMemberModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? unreadCount = null,
    Object? isMuted = null,
    Object? isPinned = null,
    Object? isOnline = null,
    Object? lastSeen = freezed,
    Object? typingStatus = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
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
            unreadCount: null == unreadCount
                ? _value.unreadCount
                : unreadCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isMuted: null == isMuted
                ? _value.isMuted
                : isMuted // ignore: cast_nullable_to_non_nullable
                      as bool,
            isPinned: null == isPinned
                ? _value.isPinned
                : isPinned // ignore: cast_nullable_to_non_nullable
                      as bool,
            isOnline: null == isOnline
                ? _value.isOnline
                : isOnline // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastSeen: freezed == lastSeen
                ? _value.lastSeen
                : lastSeen // ignore: cast_nullable_to_non_nullable
                      as String?,
            typingStatus: freezed == typingStatus
                ? _value.typingStatus
                : typingStatus // ignore: cast_nullable_to_non_nullable
                      as TypingStatusModel?,
          )
          as $Val,
    );
  }

  /// Create a copy of ConversationMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TypingStatusModelCopyWith<$Res>? get typingStatus {
    if (_value.typingStatus == null) {
      return null;
    }

    return $TypingStatusModelCopyWith<$Res>(_value.typingStatus!, (value) {
      return _then(_value.copyWith(typingStatus: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConversationMemberModelImplCopyWith<$Res>
    implements $ConversationMemberModelCopyWith<$Res> {
  factory _$$ConversationMemberModelImplCopyWith(
    _$ConversationMemberModelImpl value,
    $Res Function(_$ConversationMemberModelImpl) then,
  ) = __$$ConversationMemberModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String username,
    String? displayName,
    String? avatarUrl,
    int unreadCount,
    bool isMuted,
    bool isPinned,
    bool isOnline,
    String? lastSeen,
    TypingStatusModel? typingStatus,
  });

  @override
  $TypingStatusModelCopyWith<$Res>? get typingStatus;
}

/// @nodoc
class __$$ConversationMemberModelImplCopyWithImpl<$Res>
    extends
        _$ConversationMemberModelCopyWithImpl<
          $Res,
          _$ConversationMemberModelImpl
        >
    implements _$$ConversationMemberModelImplCopyWith<$Res> {
  __$$ConversationMemberModelImplCopyWithImpl(
    _$ConversationMemberModelImpl _value,
    $Res Function(_$ConversationMemberModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConversationMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? unreadCount = null,
    Object? isMuted = null,
    Object? isPinned = null,
    Object? isOnline = null,
    Object? lastSeen = freezed,
    Object? typingStatus = freezed,
  }) {
    return _then(
      _$ConversationMemberModelImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
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
        unreadCount: null == unreadCount
            ? _value.unreadCount
            : unreadCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isMuted: null == isMuted
            ? _value.isMuted
            : isMuted // ignore: cast_nullable_to_non_nullable
                  as bool,
        isPinned: null == isPinned
            ? _value.isPinned
            : isPinned // ignore: cast_nullable_to_non_nullable
                  as bool,
        isOnline: null == isOnline
            ? _value.isOnline
            : isOnline // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastSeen: freezed == lastSeen
            ? _value.lastSeen
            : lastSeen // ignore: cast_nullable_to_non_nullable
                  as String?,
        typingStatus: freezed == typingStatus
            ? _value.typingStatus
            : typingStatus // ignore: cast_nullable_to_non_nullable
                  as TypingStatusModel?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationMemberModelImpl implements _ConversationMemberModel {
  const _$ConversationMemberModelImpl({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.isOnline = false,
    this.lastSeen,
    this.typingStatus,
  });

  factory _$ConversationMemberModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationMemberModelImplFromJson(json);

  @override
  final String userId;
  @override
  final String username;
  @override
  final String? displayName;
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  final int unreadCount;
  @override
  @JsonKey()
  final bool isMuted;
  @override
  @JsonKey()
  final bool isPinned;
  @override
  @JsonKey()
  final bool isOnline;
  @override
  final String? lastSeen;
  @override
  final TypingStatusModel? typingStatus;

  @override
  String toString() {
    return 'ConversationMemberModel(userId: $userId, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, unreadCount: $unreadCount, isMuted: $isMuted, isPinned: $isPinned, isOnline: $isOnline, lastSeen: $lastSeen, typingStatus: $typingStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationMemberModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen) &&
            (identical(other.typingStatus, typingStatus) ||
                other.typingStatus == typingStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    username,
    displayName,
    avatarUrl,
    unreadCount,
    isMuted,
    isPinned,
    isOnline,
    lastSeen,
    typingStatus,
  );

  /// Create a copy of ConversationMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationMemberModelImplCopyWith<_$ConversationMemberModelImpl>
  get copyWith =>
      __$$ConversationMemberModelImplCopyWithImpl<
        _$ConversationMemberModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationMemberModelImplToJson(this);
  }
}

abstract class _ConversationMemberModel implements ConversationMemberModel {
  const factory _ConversationMemberModel({
    required final String userId,
    required final String username,
    final String? displayName,
    final String? avatarUrl,
    final int unreadCount,
    final bool isMuted,
    final bool isPinned,
    final bool isOnline,
    final String? lastSeen,
    final TypingStatusModel? typingStatus,
  }) = _$ConversationMemberModelImpl;

  factory _ConversationMemberModel.fromJson(Map<String, dynamic> json) =
      _$ConversationMemberModelImpl.fromJson;

  @override
  String get userId;
  @override
  String get username;
  @override
  String? get displayName;
  @override
  String? get avatarUrl;
  @override
  int get unreadCount;
  @override
  bool get isMuted;
  @override
  bool get isPinned;
  @override
  bool get isOnline;
  @override
  String? get lastSeen;
  @override
  TypingStatusModel? get typingStatus;

  /// Create a copy of ConversationMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationMemberModelImplCopyWith<_$ConversationMemberModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MessagePreviewModel _$MessagePreviewModelFromJson(Map<String, dynamic> json) {
  return _MessagePreviewModel.fromJson(json);
}

/// @nodoc
mixin _$MessagePreviewModel {
  String get id => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get senderName => throw _privateConstructorUsedError;
  bool? get isMe => throw _privateConstructorUsedError;
  String? get attachmentPreview => throw _privateConstructorUsedError;

  /// Serializes this MessagePreviewModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessagePreviewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessagePreviewModelCopyWith<MessagePreviewModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessagePreviewModelCopyWith<$Res> {
  factory $MessagePreviewModelCopyWith(
    MessagePreviewModel value,
    $Res Function(MessagePreviewModel) then,
  ) = _$MessagePreviewModelCopyWithImpl<$Res, MessagePreviewModel>;
  @useResult
  $Res call({
    String id,
    String? content,
    String type,
    String? senderName,
    bool? isMe,
    String? attachmentPreview,
  });
}

/// @nodoc
class _$MessagePreviewModelCopyWithImpl<$Res, $Val extends MessagePreviewModel>
    implements $MessagePreviewModelCopyWith<$Res> {
  _$MessagePreviewModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessagePreviewModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = freezed,
    Object? type = null,
    Object? senderName = freezed,
    Object? isMe = freezed,
    Object? attachmentPreview = freezed,
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
            senderName: freezed == senderName
                ? _value.senderName
                : senderName // ignore: cast_nullable_to_non_nullable
                      as String?,
            isMe: freezed == isMe
                ? _value.isMe
                : isMe // ignore: cast_nullable_to_non_nullable
                      as bool?,
            attachmentPreview: freezed == attachmentPreview
                ? _value.attachmentPreview
                : attachmentPreview // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessagePreviewModelImplCopyWith<$Res>
    implements $MessagePreviewModelCopyWith<$Res> {
  factory _$$MessagePreviewModelImplCopyWith(
    _$MessagePreviewModelImpl value,
    $Res Function(_$MessagePreviewModelImpl) then,
  ) = __$$MessagePreviewModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? content,
    String type,
    String? senderName,
    bool? isMe,
    String? attachmentPreview,
  });
}

/// @nodoc
class __$$MessagePreviewModelImplCopyWithImpl<$Res>
    extends _$MessagePreviewModelCopyWithImpl<$Res, _$MessagePreviewModelImpl>
    implements _$$MessagePreviewModelImplCopyWith<$Res> {
  __$$MessagePreviewModelImplCopyWithImpl(
    _$MessagePreviewModelImpl _value,
    $Res Function(_$MessagePreviewModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessagePreviewModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = freezed,
    Object? type = null,
    Object? senderName = freezed,
    Object? isMe = freezed,
    Object? attachmentPreview = freezed,
  }) {
    return _then(
      _$MessagePreviewModelImpl(
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
        senderName: freezed == senderName
            ? _value.senderName
            : senderName // ignore: cast_nullable_to_non_nullable
                  as String?,
        isMe: freezed == isMe
            ? _value.isMe
            : isMe // ignore: cast_nullable_to_non_nullable
                  as bool?,
        attachmentPreview: freezed == attachmentPreview
            ? _value.attachmentPreview
            : attachmentPreview // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessagePreviewModelImpl implements _MessagePreviewModel {
  const _$MessagePreviewModelImpl({
    required this.id,
    this.content,
    required this.type,
    this.senderName,
    this.isMe,
    this.attachmentPreview,
  });

  factory _$MessagePreviewModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessagePreviewModelImplFromJson(json);

  @override
  final String id;
  @override
  final String? content;
  @override
  final String type;
  @override
  final String? senderName;
  @override
  final bool? isMe;
  @override
  final String? attachmentPreview;

  @override
  String toString() {
    return 'MessagePreviewModel(id: $id, content: $content, type: $type, senderName: $senderName, isMe: $isMe, attachmentPreview: $attachmentPreview)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessagePreviewModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.isMe, isMe) || other.isMe == isMe) &&
            (identical(other.attachmentPreview, attachmentPreview) ||
                other.attachmentPreview == attachmentPreview));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    content,
    type,
    senderName,
    isMe,
    attachmentPreview,
  );

  /// Create a copy of MessagePreviewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessagePreviewModelImplCopyWith<_$MessagePreviewModelImpl> get copyWith =>
      __$$MessagePreviewModelImplCopyWithImpl<_$MessagePreviewModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MessagePreviewModelImplToJson(this);
  }
}

abstract class _MessagePreviewModel implements MessagePreviewModel {
  const factory _MessagePreviewModel({
    required final String id,
    final String? content,
    required final String type,
    final String? senderName,
    final bool? isMe,
    final String? attachmentPreview,
  }) = _$MessagePreviewModelImpl;

  factory _MessagePreviewModel.fromJson(Map<String, dynamic> json) =
      _$MessagePreviewModelImpl.fromJson;

  @override
  String get id;
  @override
  String? get content;
  @override
  String get type;
  @override
  String? get senderName;
  @override
  bool? get isMe;
  @override
  String? get attachmentPreview;

  /// Create a copy of MessagePreviewModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessagePreviewModelImplCopyWith<_$MessagePreviewModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConversationMetadataModel _$ConversationMetadataModelFromJson(
  Map<String, dynamic> json,
) {
  return _ConversationMetadataModel.fromJson(json);
}

/// @nodoc
mixin _$ConversationMetadataModel {
  String? get groupName => throw _privateConstructorUsedError;
  String? get groupAvatar => throw _privateConstructorUsedError;
  int? get memberCount => throw _privateConstructorUsedError;
  bool? get isVerified => throw _privateConstructorUsedError;
  String? get channelName => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this ConversationMetadataModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConversationMetadataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationMetadataModelCopyWith<ConversationMetadataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationMetadataModelCopyWith<$Res> {
  factory $ConversationMetadataModelCopyWith(
    ConversationMetadataModel value,
    $Res Function(ConversationMetadataModel) then,
  ) = _$ConversationMetadataModelCopyWithImpl<$Res, ConversationMetadataModel>;
  @useResult
  $Res call({
    String? groupName,
    String? groupAvatar,
    int? memberCount,
    bool? isVerified,
    String? channelName,
    String? description,
  });
}

/// @nodoc
class _$ConversationMetadataModelCopyWithImpl<
  $Res,
  $Val extends ConversationMetadataModel
>
    implements $ConversationMetadataModelCopyWith<$Res> {
  _$ConversationMetadataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationMetadataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupName = freezed,
    Object? groupAvatar = freezed,
    Object? memberCount = freezed,
    Object? isVerified = freezed,
    Object? channelName = freezed,
    Object? description = freezed,
  }) {
    return _then(
      _value.copyWith(
            groupName: freezed == groupName
                ? _value.groupName
                : groupName // ignore: cast_nullable_to_non_nullable
                      as String?,
            groupAvatar: freezed == groupAvatar
                ? _value.groupAvatar
                : groupAvatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            memberCount: freezed == memberCount
                ? _value.memberCount
                : memberCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            isVerified: freezed == isVerified
                ? _value.isVerified
                : isVerified // ignore: cast_nullable_to_non_nullable
                      as bool?,
            channelName: freezed == channelName
                ? _value.channelName
                : channelName // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConversationMetadataModelImplCopyWith<$Res>
    implements $ConversationMetadataModelCopyWith<$Res> {
  factory _$$ConversationMetadataModelImplCopyWith(
    _$ConversationMetadataModelImpl value,
    $Res Function(_$ConversationMetadataModelImpl) then,
  ) = __$$ConversationMetadataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? groupName,
    String? groupAvatar,
    int? memberCount,
    bool? isVerified,
    String? channelName,
    String? description,
  });
}

/// @nodoc
class __$$ConversationMetadataModelImplCopyWithImpl<$Res>
    extends
        _$ConversationMetadataModelCopyWithImpl<
          $Res,
          _$ConversationMetadataModelImpl
        >
    implements _$$ConversationMetadataModelImplCopyWith<$Res> {
  __$$ConversationMetadataModelImplCopyWithImpl(
    _$ConversationMetadataModelImpl _value,
    $Res Function(_$ConversationMetadataModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConversationMetadataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupName = freezed,
    Object? groupAvatar = freezed,
    Object? memberCount = freezed,
    Object? isVerified = freezed,
    Object? channelName = freezed,
    Object? description = freezed,
  }) {
    return _then(
      _$ConversationMetadataModelImpl(
        groupName: freezed == groupName
            ? _value.groupName
            : groupName // ignore: cast_nullable_to_non_nullable
                  as String?,
        groupAvatar: freezed == groupAvatar
            ? _value.groupAvatar
            : groupAvatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        memberCount: freezed == memberCount
            ? _value.memberCount
            : memberCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        isVerified: freezed == isVerified
            ? _value.isVerified
            : isVerified // ignore: cast_nullable_to_non_nullable
                  as bool?,
        channelName: freezed == channelName
            ? _value.channelName
            : channelName // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationMetadataModelImpl implements _ConversationMetadataModel {
  const _$ConversationMetadataModelImpl({
    this.groupName,
    this.groupAvatar,
    this.memberCount,
    this.isVerified,
    this.channelName,
    this.description,
  });

  factory _$ConversationMetadataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationMetadataModelImplFromJson(json);

  @override
  final String? groupName;
  @override
  final String? groupAvatar;
  @override
  final int? memberCount;
  @override
  final bool? isVerified;
  @override
  final String? channelName;
  @override
  final String? description;

  @override
  String toString() {
    return 'ConversationMetadataModel(groupName: $groupName, groupAvatar: $groupAvatar, memberCount: $memberCount, isVerified: $isVerified, channelName: $channelName, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationMetadataModelImpl &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.groupAvatar, groupAvatar) ||
                other.groupAvatar == groupAvatar) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.channelName, channelName) ||
                other.channelName == channelName) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    groupName,
    groupAvatar,
    memberCount,
    isVerified,
    channelName,
    description,
  );

  /// Create a copy of ConversationMetadataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationMetadataModelImplCopyWith<_$ConversationMetadataModelImpl>
  get copyWith =>
      __$$ConversationMetadataModelImplCopyWithImpl<
        _$ConversationMetadataModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationMetadataModelImplToJson(this);
  }
}

abstract class _ConversationMetadataModel implements ConversationMetadataModel {
  const factory _ConversationMetadataModel({
    final String? groupName,
    final String? groupAvatar,
    final int? memberCount,
    final bool? isVerified,
    final String? channelName,
    final String? description,
  }) = _$ConversationMetadataModelImpl;

  factory _ConversationMetadataModel.fromJson(Map<String, dynamic> json) =
      _$ConversationMetadataModelImpl.fromJson;

  @override
  String? get groupName;
  @override
  String? get groupAvatar;
  @override
  int? get memberCount;
  @override
  bool? get isVerified;
  @override
  String? get channelName;
  @override
  String? get description;

  /// Create a copy of ConversationMetadataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationMetadataModelImplCopyWith<_$ConversationMetadataModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

TypingStatusModel _$TypingStatusModelFromJson(Map<String, dynamic> json) {
  return _TypingStatusModel.fromJson(json);
}

/// @nodoc
mixin _$TypingStatusModel {
  bool get isTyping => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;

  /// Serializes this TypingStatusModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TypingStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TypingStatusModelCopyWith<TypingStatusModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TypingStatusModelCopyWith<$Res> {
  factory $TypingStatusModelCopyWith(
    TypingStatusModel value,
    $Res Function(TypingStatusModel) then,
  ) = _$TypingStatusModelCopyWithImpl<$Res, TypingStatusModel>;
  @useResult
  $Res call({bool isTyping, DateTime? startedAt});
}

/// @nodoc
class _$TypingStatusModelCopyWithImpl<$Res, $Val extends TypingStatusModel>
    implements $TypingStatusModelCopyWith<$Res> {
  _$TypingStatusModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TypingStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? isTyping = null, Object? startedAt = freezed}) {
    return _then(
      _value.copyWith(
            isTyping: null == isTyping
                ? _value.isTyping
                : isTyping // ignore: cast_nullable_to_non_nullable
                      as bool,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TypingStatusModelImplCopyWith<$Res>
    implements $TypingStatusModelCopyWith<$Res> {
  factory _$$TypingStatusModelImplCopyWith(
    _$TypingStatusModelImpl value,
    $Res Function(_$TypingStatusModelImpl) then,
  ) = __$$TypingStatusModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isTyping, DateTime? startedAt});
}

/// @nodoc
class __$$TypingStatusModelImplCopyWithImpl<$Res>
    extends _$TypingStatusModelCopyWithImpl<$Res, _$TypingStatusModelImpl>
    implements _$$TypingStatusModelImplCopyWith<$Res> {
  __$$TypingStatusModelImplCopyWithImpl(
    _$TypingStatusModelImpl _value,
    $Res Function(_$TypingStatusModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TypingStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? isTyping = null, Object? startedAt = freezed}) {
    return _then(
      _$TypingStatusModelImpl(
        isTyping: null == isTyping
            ? _value.isTyping
            : isTyping // ignore: cast_nullable_to_non_nullable
                  as bool,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TypingStatusModelImpl implements _TypingStatusModel {
  const _$TypingStatusModelImpl({required this.isTyping, this.startedAt});

  factory _$TypingStatusModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TypingStatusModelImplFromJson(json);

  @override
  final bool isTyping;
  @override
  final DateTime? startedAt;

  @override
  String toString() {
    return 'TypingStatusModel(isTyping: $isTyping, startedAt: $startedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TypingStatusModelImpl &&
            (identical(other.isTyping, isTyping) ||
                other.isTyping == isTyping) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, isTyping, startedAt);

  /// Create a copy of TypingStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TypingStatusModelImplCopyWith<_$TypingStatusModelImpl> get copyWith =>
      __$$TypingStatusModelImplCopyWithImpl<_$TypingStatusModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TypingStatusModelImplToJson(this);
  }
}

abstract class _TypingStatusModel implements TypingStatusModel {
  const factory _TypingStatusModel({
    required final bool isTyping,
    final DateTime? startedAt,
  }) = _$TypingStatusModelImpl;

  factory _TypingStatusModel.fromJson(Map<String, dynamic> json) =
      _$TypingStatusModelImpl.fromJson;

  @override
  bool get isTyping;
  @override
  DateTime? get startedAt;

  /// Create a copy of TypingStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TypingStatusModelImplCopyWith<_$TypingStatusModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
