// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_stream_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StreamCreatorDto _$StreamCreatorDtoFromJson(Map<String, dynamic> json) {
  return _StreamCreatorDto.fromJson(json);
}

/// @nodoc
mixin _$StreamCreatorDto {
  String get id => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Serializes this StreamCreatorDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StreamCreatorDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StreamCreatorDtoCopyWith<StreamCreatorDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StreamCreatorDtoCopyWith<$Res> {
  factory $StreamCreatorDtoCopyWith(
    StreamCreatorDto value,
    $Res Function(StreamCreatorDto) then,
  ) = _$StreamCreatorDtoCopyWithImpl<$Res, StreamCreatorDto>;
  @useResult
  $Res call({String id, String? username, String? avatarUrl});
}

/// @nodoc
class _$StreamCreatorDtoCopyWithImpl<$Res, $Val extends StreamCreatorDto>
    implements $StreamCreatorDtoCopyWith<$Res> {
  _$StreamCreatorDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StreamCreatorDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = freezed,
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
abstract class _$$StreamCreatorDtoImplCopyWith<$Res>
    implements $StreamCreatorDtoCopyWith<$Res> {
  factory _$$StreamCreatorDtoImplCopyWith(
    _$StreamCreatorDtoImpl value,
    $Res Function(_$StreamCreatorDtoImpl) then,
  ) = __$$StreamCreatorDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String? username, String? avatarUrl});
}

/// @nodoc
class __$$StreamCreatorDtoImplCopyWithImpl<$Res>
    extends _$StreamCreatorDtoCopyWithImpl<$Res, _$StreamCreatorDtoImpl>
    implements _$$StreamCreatorDtoImplCopyWith<$Res> {
  __$$StreamCreatorDtoImplCopyWithImpl(
    _$StreamCreatorDtoImpl _value,
    $Res Function(_$StreamCreatorDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StreamCreatorDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _$StreamCreatorDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        username: freezed == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
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
class _$StreamCreatorDtoImpl implements _StreamCreatorDto {
  const _$StreamCreatorDtoImpl({
    required this.id,
    this.username,
    this.avatarUrl,
  });

  factory _$StreamCreatorDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StreamCreatorDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String? username;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'StreamCreatorDto(id: $id, username: $username, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StreamCreatorDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, username, avatarUrl);

  /// Create a copy of StreamCreatorDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StreamCreatorDtoImplCopyWith<_$StreamCreatorDtoImpl> get copyWith =>
      __$$StreamCreatorDtoImplCopyWithImpl<_$StreamCreatorDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StreamCreatorDtoImplToJson(this);
  }
}

abstract class _StreamCreatorDto implements StreamCreatorDto {
  const factory _StreamCreatorDto({
    required final String id,
    final String? username,
    final String? avatarUrl,
  }) = _$StreamCreatorDtoImpl;

  factory _StreamCreatorDto.fromJson(Map<String, dynamic> json) =
      _$StreamCreatorDtoImpl.fromJson;

  @override
  String get id;
  @override
  String? get username;
  @override
  String? get avatarUrl;

  /// Create a copy of StreamCreatorDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StreamCreatorDtoImplCopyWith<_$StreamCreatorDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StreamChannelDto _$StreamChannelDtoFromJson(Map<String, dynamic> json) {
  return _StreamChannelDto.fromJson(json);
}

/// @nodoc
mixin _$StreamChannelDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Serializes this StreamChannelDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StreamChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StreamChannelDtoCopyWith<StreamChannelDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StreamChannelDtoCopyWith<$Res> {
  factory $StreamChannelDtoCopyWith(
    StreamChannelDto value,
    $Res Function(StreamChannelDto) then,
  ) = _$StreamChannelDtoCopyWithImpl<$Res, StreamChannelDto>;
  @useResult
  $Res call({String id, String name, String? avatarUrl});
}

/// @nodoc
class _$StreamChannelDtoCopyWithImpl<$Res, $Val extends StreamChannelDto>
    implements $StreamChannelDtoCopyWith<$Res> {
  _$StreamChannelDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StreamChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$StreamChannelDtoImplCopyWith<$Res>
    implements $StreamChannelDtoCopyWith<$Res> {
  factory _$$StreamChannelDtoImplCopyWith(
    _$StreamChannelDtoImpl value,
    $Res Function(_$StreamChannelDtoImpl) then,
  ) = __$$StreamChannelDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? avatarUrl});
}

/// @nodoc
class __$$StreamChannelDtoImplCopyWithImpl<$Res>
    extends _$StreamChannelDtoCopyWithImpl<$Res, _$StreamChannelDtoImpl>
    implements _$$StreamChannelDtoImplCopyWith<$Res> {
  __$$StreamChannelDtoImplCopyWithImpl(
    _$StreamChannelDtoImpl _value,
    $Res Function(_$StreamChannelDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StreamChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _$StreamChannelDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$StreamChannelDtoImpl implements _StreamChannelDto {
  const _$StreamChannelDtoImpl({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory _$StreamChannelDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StreamChannelDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'StreamChannelDto(id: $id, name: $name, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StreamChannelDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, avatarUrl);

  /// Create a copy of StreamChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StreamChannelDtoImplCopyWith<_$StreamChannelDtoImpl> get copyWith =>
      __$$StreamChannelDtoImplCopyWithImpl<_$StreamChannelDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StreamChannelDtoImplToJson(this);
  }
}

abstract class _StreamChannelDto implements StreamChannelDto {
  const factory _StreamChannelDto({
    required final String id,
    required final String name,
    final String? avatarUrl,
  }) = _$StreamChannelDtoImpl;

  factory _StreamChannelDto.fromJson(Map<String, dynamic> json) =
      _$StreamChannelDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get avatarUrl;

  /// Create a copy of StreamChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StreamChannelDtoImplCopyWith<_$StreamChannelDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StreamGroupDto _$StreamGroupDtoFromJson(Map<String, dynamic> json) {
  return _StreamGroupDto.fromJson(json);
}

/// @nodoc
mixin _$StreamGroupDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this StreamGroupDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StreamGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StreamGroupDtoCopyWith<StreamGroupDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StreamGroupDtoCopyWith<$Res> {
  factory $StreamGroupDtoCopyWith(
    StreamGroupDto value,
    $Res Function(StreamGroupDto) then,
  ) = _$StreamGroupDtoCopyWithImpl<$Res, StreamGroupDto>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class _$StreamGroupDtoCopyWithImpl<$Res, $Val extends StreamGroupDto>
    implements $StreamGroupDtoCopyWith<$Res> {
  _$StreamGroupDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StreamGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StreamGroupDtoImplCopyWith<$Res>
    implements $StreamGroupDtoCopyWith<$Res> {
  factory _$$StreamGroupDtoImplCopyWith(
    _$StreamGroupDtoImpl value,
    $Res Function(_$StreamGroupDtoImpl) then,
  ) = __$$StreamGroupDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$StreamGroupDtoImplCopyWithImpl<$Res>
    extends _$StreamGroupDtoCopyWithImpl<$Res, _$StreamGroupDtoImpl>
    implements _$$StreamGroupDtoImplCopyWith<$Res> {
  __$$StreamGroupDtoImplCopyWithImpl(
    _$StreamGroupDtoImpl _value,
    $Res Function(_$StreamGroupDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StreamGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null}) {
    return _then(
      _$StreamGroupDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StreamGroupDtoImpl implements _StreamGroupDto {
  const _$StreamGroupDtoImpl({required this.id, required this.name});

  factory _$StreamGroupDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StreamGroupDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'StreamGroupDto(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StreamGroupDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of StreamGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StreamGroupDtoImplCopyWith<_$StreamGroupDtoImpl> get copyWith =>
      __$$StreamGroupDtoImplCopyWithImpl<_$StreamGroupDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StreamGroupDtoImplToJson(this);
  }
}

abstract class _StreamGroupDto implements StreamGroupDto {
  const factory _StreamGroupDto({
    required final String id,
    required final String name,
  }) = _$StreamGroupDtoImpl;

  factory _StreamGroupDto.fromJson(Map<String, dynamic> json) =
      _$StreamGroupDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Create a copy of StreamGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StreamGroupDtoImplCopyWith<_$StreamGroupDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LiveStreamDto _$LiveStreamDtoFromJson(Map<String, dynamic> json) {
  return _LiveStreamDto.fromJson(json);
}

/// @nodoc
mixin _$LiveStreamDto {
  String get id => throw _privateConstructorUsedError;
  String get videoChannelId => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  String get createdById => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  LiveStreamStatus get status => throw _privateConstructorUsedError;
  LiveStreamVisibility get visibility => throw _privateConstructorUsedError;
  StreamProtocol get protocol => throw _privateConstructorUsedError;
  String? get hlsUrl => throw _privateConstructorUsedError;
  String? get dashUrl => throw _privateConstructorUsedError;
  String? get webrtcUrl => throw _privateConstructorUsedError;
  String? get rtmpIngestUrl => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  List<String> get categories => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  List<String> get hashtags => throw _privateConstructorUsedError;
  String? get scheduledAt => throw _privateConstructorUsedError;
  String? get startedAt => throw _privateConstructorUsedError;
  String? get endedAt => throw _privateConstructorUsedError;
  bool get isRecordingEnabled => throw _privateConstructorUsedError;
  bool get isDvrEnabled => throw _privateConstructorUsedError;
  bool get isReplayEnabled => throw _privateConstructorUsedError;
  bool get isChatEnabled => throw _privateConstructorUsedError;
  bool get isChatSlowMode => throw _privateConstructorUsedError;
  int get chatSlowModeSeconds => throw _privateConstructorUsedError;
  bool get isMembersOnlyChat => throw _privateConstructorUsedError;
  bool get isSubscribersOnlyChat => throw _privateConstructorUsedError;
  int get peakViewerCount => throw _privateConstructorUsedError;
  int get currentViewerCount => throw _privateConstructorUsedError;
  int get totalViewerCount => throw _privateConstructorUsedError;
  int get totalChatMessages => throw _privateConstructorUsedError;
  int get totalReactions => throw _privateConstructorUsedError;
  int get likesCount => throw _privateConstructorUsedError;
  int? get duration => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;
  StreamCreatorDto? get createdBy => throw _privateConstructorUsedError;
  StreamGroupDto? get group => throw _privateConstructorUsedError;
  StreamChannelDto? get videoChannel => throw _privateConstructorUsedError;

  /// Serializes this LiveStreamDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LiveStreamDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiveStreamDtoCopyWith<LiveStreamDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiveStreamDtoCopyWith<$Res> {
  factory $LiveStreamDtoCopyWith(
    LiveStreamDto value,
    $Res Function(LiveStreamDto) then,
  ) = _$LiveStreamDtoCopyWithImpl<$Res, LiveStreamDto>;
  @useResult
  $Res call({
    String id,
    String videoChannelId,
    String groupId,
    String createdById,
    String title,
    String? description,
    String slug,
    LiveStreamStatus status,
    LiveStreamVisibility visibility,
    StreamProtocol protocol,
    String? hlsUrl,
    String? dashUrl,
    String? webrtcUrl,
    String? rtmpIngestUrl,
    String? thumbnailUrl,
    List<String> categories,
    List<String> tags,
    List<String> hashtags,
    String? scheduledAt,
    String? startedAt,
    String? endedAt,
    bool isRecordingEnabled,
    bool isDvrEnabled,
    bool isReplayEnabled,
    bool isChatEnabled,
    bool isChatSlowMode,
    int chatSlowModeSeconds,
    bool isMembersOnlyChat,
    bool isSubscribersOnlyChat,
    int peakViewerCount,
    int currentViewerCount,
    int totalViewerCount,
    int totalChatMessages,
    int totalReactions,
    int likesCount,
    int? duration,
    String createdAt,
    String updatedAt,
    StreamCreatorDto? createdBy,
    StreamGroupDto? group,
    StreamChannelDto? videoChannel,
  });

  $StreamCreatorDtoCopyWith<$Res>? get createdBy;
  $StreamGroupDtoCopyWith<$Res>? get group;
  $StreamChannelDtoCopyWith<$Res>? get videoChannel;
}

/// @nodoc
class _$LiveStreamDtoCopyWithImpl<$Res, $Val extends LiveStreamDto>
    implements $LiveStreamDtoCopyWith<$Res> {
  _$LiveStreamDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiveStreamDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? videoChannelId = null,
    Object? groupId = null,
    Object? createdById = null,
    Object? title = null,
    Object? description = freezed,
    Object? slug = null,
    Object? status = null,
    Object? visibility = null,
    Object? protocol = null,
    Object? hlsUrl = freezed,
    Object? dashUrl = freezed,
    Object? webrtcUrl = freezed,
    Object? rtmpIngestUrl = freezed,
    Object? thumbnailUrl = freezed,
    Object? categories = null,
    Object? tags = null,
    Object? hashtags = null,
    Object? scheduledAt = freezed,
    Object? startedAt = freezed,
    Object? endedAt = freezed,
    Object? isRecordingEnabled = null,
    Object? isDvrEnabled = null,
    Object? isReplayEnabled = null,
    Object? isChatEnabled = null,
    Object? isChatSlowMode = null,
    Object? chatSlowModeSeconds = null,
    Object? isMembersOnlyChat = null,
    Object? isSubscribersOnlyChat = null,
    Object? peakViewerCount = null,
    Object? currentViewerCount = null,
    Object? totalViewerCount = null,
    Object? totalChatMessages = null,
    Object? totalReactions = null,
    Object? likesCount = null,
    Object? duration = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? createdBy = freezed,
    Object? group = freezed,
    Object? videoChannel = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            videoChannelId: null == videoChannelId
                ? _value.videoChannelId
                : videoChannelId // ignore: cast_nullable_to_non_nullable
                      as String,
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String,
            createdById: null == createdById
                ? _value.createdById
                : createdById // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as LiveStreamStatus,
            visibility: null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                      as LiveStreamVisibility,
            protocol: null == protocol
                ? _value.protocol
                : protocol // ignore: cast_nullable_to_non_nullable
                      as StreamProtocol,
            hlsUrl: freezed == hlsUrl
                ? _value.hlsUrl
                : hlsUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            dashUrl: freezed == dashUrl
                ? _value.dashUrl
                : dashUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            webrtcUrl: freezed == webrtcUrl
                ? _value.webrtcUrl
                : webrtcUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            rtmpIngestUrl: freezed == rtmpIngestUrl
                ? _value.rtmpIngestUrl
                : rtmpIngestUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            thumbnailUrl: freezed == thumbnailUrl
                ? _value.thumbnailUrl
                : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            hashtags: null == hashtags
                ? _value.hashtags
                : hashtags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            scheduledAt: freezed == scheduledAt
                ? _value.scheduledAt
                : scheduledAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            endedAt: freezed == endedAt
                ? _value.endedAt
                : endedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            isRecordingEnabled: null == isRecordingEnabled
                ? _value.isRecordingEnabled
                : isRecordingEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDvrEnabled: null == isDvrEnabled
                ? _value.isDvrEnabled
                : isDvrEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            isReplayEnabled: null == isReplayEnabled
                ? _value.isReplayEnabled
                : isReplayEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            isChatEnabled: null == isChatEnabled
                ? _value.isChatEnabled
                : isChatEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            isChatSlowMode: null == isChatSlowMode
                ? _value.isChatSlowMode
                : isChatSlowMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            chatSlowModeSeconds: null == chatSlowModeSeconds
                ? _value.chatSlowModeSeconds
                : chatSlowModeSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            isMembersOnlyChat: null == isMembersOnlyChat
                ? _value.isMembersOnlyChat
                : isMembersOnlyChat // ignore: cast_nullable_to_non_nullable
                      as bool,
            isSubscribersOnlyChat: null == isSubscribersOnlyChat
                ? _value.isSubscribersOnlyChat
                : isSubscribersOnlyChat // ignore: cast_nullable_to_non_nullable
                      as bool,
            peakViewerCount: null == peakViewerCount
                ? _value.peakViewerCount
                : peakViewerCount // ignore: cast_nullable_to_non_nullable
                      as int,
            currentViewerCount: null == currentViewerCount
                ? _value.currentViewerCount
                : currentViewerCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalViewerCount: null == totalViewerCount
                ? _value.totalViewerCount
                : totalViewerCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalChatMessages: null == totalChatMessages
                ? _value.totalChatMessages
                : totalChatMessages // ignore: cast_nullable_to_non_nullable
                      as int,
            totalReactions: null == totalReactions
                ? _value.totalReactions
                : totalReactions // ignore: cast_nullable_to_non_nullable
                      as int,
            likesCount: null == likesCount
                ? _value.likesCount
                : likesCount // ignore: cast_nullable_to_non_nullable
                      as int,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as StreamCreatorDto?,
            group: freezed == group
                ? _value.group
                : group // ignore: cast_nullable_to_non_nullable
                      as StreamGroupDto?,
            videoChannel: freezed == videoChannel
                ? _value.videoChannel
                : videoChannel // ignore: cast_nullable_to_non_nullable
                      as StreamChannelDto?,
          )
          as $Val,
    );
  }

  /// Create a copy of LiveStreamDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StreamCreatorDtoCopyWith<$Res>? get createdBy {
    if (_value.createdBy == null) {
      return null;
    }

    return $StreamCreatorDtoCopyWith<$Res>(_value.createdBy!, (value) {
      return _then(_value.copyWith(createdBy: value) as $Val);
    });
  }

  /// Create a copy of LiveStreamDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StreamGroupDtoCopyWith<$Res>? get group {
    if (_value.group == null) {
      return null;
    }

    return $StreamGroupDtoCopyWith<$Res>(_value.group!, (value) {
      return _then(_value.copyWith(group: value) as $Val);
    });
  }

  /// Create a copy of LiveStreamDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StreamChannelDtoCopyWith<$Res>? get videoChannel {
    if (_value.videoChannel == null) {
      return null;
    }

    return $StreamChannelDtoCopyWith<$Res>(_value.videoChannel!, (value) {
      return _then(_value.copyWith(videoChannel: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LiveStreamDtoImplCopyWith<$Res>
    implements $LiveStreamDtoCopyWith<$Res> {
  factory _$$LiveStreamDtoImplCopyWith(
    _$LiveStreamDtoImpl value,
    $Res Function(_$LiveStreamDtoImpl) then,
  ) = __$$LiveStreamDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String videoChannelId,
    String groupId,
    String createdById,
    String title,
    String? description,
    String slug,
    LiveStreamStatus status,
    LiveStreamVisibility visibility,
    StreamProtocol protocol,
    String? hlsUrl,
    String? dashUrl,
    String? webrtcUrl,
    String? rtmpIngestUrl,
    String? thumbnailUrl,
    List<String> categories,
    List<String> tags,
    List<String> hashtags,
    String? scheduledAt,
    String? startedAt,
    String? endedAt,
    bool isRecordingEnabled,
    bool isDvrEnabled,
    bool isReplayEnabled,
    bool isChatEnabled,
    bool isChatSlowMode,
    int chatSlowModeSeconds,
    bool isMembersOnlyChat,
    bool isSubscribersOnlyChat,
    int peakViewerCount,
    int currentViewerCount,
    int totalViewerCount,
    int totalChatMessages,
    int totalReactions,
    int likesCount,
    int? duration,
    String createdAt,
    String updatedAt,
    StreamCreatorDto? createdBy,
    StreamGroupDto? group,
    StreamChannelDto? videoChannel,
  });

  @override
  $StreamCreatorDtoCopyWith<$Res>? get createdBy;
  @override
  $StreamGroupDtoCopyWith<$Res>? get group;
  @override
  $StreamChannelDtoCopyWith<$Res>? get videoChannel;
}

/// @nodoc
class __$$LiveStreamDtoImplCopyWithImpl<$Res>
    extends _$LiveStreamDtoCopyWithImpl<$Res, _$LiveStreamDtoImpl>
    implements _$$LiveStreamDtoImplCopyWith<$Res> {
  __$$LiveStreamDtoImplCopyWithImpl(
    _$LiveStreamDtoImpl _value,
    $Res Function(_$LiveStreamDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LiveStreamDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? videoChannelId = null,
    Object? groupId = null,
    Object? createdById = null,
    Object? title = null,
    Object? description = freezed,
    Object? slug = null,
    Object? status = null,
    Object? visibility = null,
    Object? protocol = null,
    Object? hlsUrl = freezed,
    Object? dashUrl = freezed,
    Object? webrtcUrl = freezed,
    Object? rtmpIngestUrl = freezed,
    Object? thumbnailUrl = freezed,
    Object? categories = null,
    Object? tags = null,
    Object? hashtags = null,
    Object? scheduledAt = freezed,
    Object? startedAt = freezed,
    Object? endedAt = freezed,
    Object? isRecordingEnabled = null,
    Object? isDvrEnabled = null,
    Object? isReplayEnabled = null,
    Object? isChatEnabled = null,
    Object? isChatSlowMode = null,
    Object? chatSlowModeSeconds = null,
    Object? isMembersOnlyChat = null,
    Object? isSubscribersOnlyChat = null,
    Object? peakViewerCount = null,
    Object? currentViewerCount = null,
    Object? totalViewerCount = null,
    Object? totalChatMessages = null,
    Object? totalReactions = null,
    Object? likesCount = null,
    Object? duration = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? createdBy = freezed,
    Object? group = freezed,
    Object? videoChannel = freezed,
  }) {
    return _then(
      _$LiveStreamDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        videoChannelId: null == videoChannelId
            ? _value.videoChannelId
            : videoChannelId // ignore: cast_nullable_to_non_nullable
                  as String,
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdById: null == createdById
            ? _value.createdById
            : createdById // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as LiveStreamStatus,
        visibility: null == visibility
            ? _value.visibility
            : visibility // ignore: cast_nullable_to_non_nullable
                  as LiveStreamVisibility,
        protocol: null == protocol
            ? _value.protocol
            : protocol // ignore: cast_nullable_to_non_nullable
                  as StreamProtocol,
        hlsUrl: freezed == hlsUrl
            ? _value.hlsUrl
            : hlsUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        dashUrl: freezed == dashUrl
            ? _value.dashUrl
            : dashUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        webrtcUrl: freezed == webrtcUrl
            ? _value.webrtcUrl
            : webrtcUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        rtmpIngestUrl: freezed == rtmpIngestUrl
            ? _value.rtmpIngestUrl
            : rtmpIngestUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        thumbnailUrl: freezed == thumbnailUrl
            ? _value.thumbnailUrl
            : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        categories: null == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        hashtags: null == hashtags
            ? _value._hashtags
            : hashtags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        scheduledAt: freezed == scheduledAt
            ? _value.scheduledAt
            : scheduledAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        endedAt: freezed == endedAt
            ? _value.endedAt
            : endedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        isRecordingEnabled: null == isRecordingEnabled
            ? _value.isRecordingEnabled
            : isRecordingEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDvrEnabled: null == isDvrEnabled
            ? _value.isDvrEnabled
            : isDvrEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        isReplayEnabled: null == isReplayEnabled
            ? _value.isReplayEnabled
            : isReplayEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        isChatEnabled: null == isChatEnabled
            ? _value.isChatEnabled
            : isChatEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        isChatSlowMode: null == isChatSlowMode
            ? _value.isChatSlowMode
            : isChatSlowMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        chatSlowModeSeconds: null == chatSlowModeSeconds
            ? _value.chatSlowModeSeconds
            : chatSlowModeSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        isMembersOnlyChat: null == isMembersOnlyChat
            ? _value.isMembersOnlyChat
            : isMembersOnlyChat // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSubscribersOnlyChat: null == isSubscribersOnlyChat
            ? _value.isSubscribersOnlyChat
            : isSubscribersOnlyChat // ignore: cast_nullable_to_non_nullable
                  as bool,
        peakViewerCount: null == peakViewerCount
            ? _value.peakViewerCount
            : peakViewerCount // ignore: cast_nullable_to_non_nullable
                  as int,
        currentViewerCount: null == currentViewerCount
            ? _value.currentViewerCount
            : currentViewerCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalViewerCount: null == totalViewerCount
            ? _value.totalViewerCount
            : totalViewerCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalChatMessages: null == totalChatMessages
            ? _value.totalChatMessages
            : totalChatMessages // ignore: cast_nullable_to_non_nullable
                  as int,
        totalReactions: null == totalReactions
            ? _value.totalReactions
            : totalReactions // ignore: cast_nullable_to_non_nullable
                  as int,
        likesCount: null == likesCount
            ? _value.likesCount
            : likesCount // ignore: cast_nullable_to_non_nullable
                  as int,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as StreamCreatorDto?,
        group: freezed == group
            ? _value.group
            : group // ignore: cast_nullable_to_non_nullable
                  as StreamGroupDto?,
        videoChannel: freezed == videoChannel
            ? _value.videoChannel
            : videoChannel // ignore: cast_nullable_to_non_nullable
                  as StreamChannelDto?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LiveStreamDtoImpl implements _LiveStreamDto {
  const _$LiveStreamDtoImpl({
    required this.id,
    required this.videoChannelId,
    required this.groupId,
    required this.createdById,
    required this.title,
    this.description,
    required this.slug,
    required this.status,
    required this.visibility,
    required this.protocol,
    this.hlsUrl,
    this.dashUrl,
    this.webrtcUrl,
    this.rtmpIngestUrl,
    this.thumbnailUrl,
    final List<String> categories = const [],
    final List<String> tags = const [],
    final List<String> hashtags = const [],
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.isRecordingEnabled = true,
    this.isDvrEnabled = true,
    this.isReplayEnabled = true,
    this.isChatEnabled = true,
    this.isChatSlowMode = false,
    this.chatSlowModeSeconds = 0,
    this.isMembersOnlyChat = false,
    this.isSubscribersOnlyChat = false,
    this.peakViewerCount = 0,
    this.currentViewerCount = 0,
    this.totalViewerCount = 0,
    this.totalChatMessages = 0,
    this.totalReactions = 0,
    this.likesCount = 0,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.group,
    this.videoChannel,
  }) : _categories = categories,
       _tags = tags,
       _hashtags = hashtags;

  factory _$LiveStreamDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$LiveStreamDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String videoChannelId;
  @override
  final String groupId;
  @override
  final String createdById;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String slug;
  @override
  final LiveStreamStatus status;
  @override
  final LiveStreamVisibility visibility;
  @override
  final StreamProtocol protocol;
  @override
  final String? hlsUrl;
  @override
  final String? dashUrl;
  @override
  final String? webrtcUrl;
  @override
  final String? rtmpIngestUrl;
  @override
  final String? thumbnailUrl;
  final List<String> _categories;
  @override
  @JsonKey()
  List<String> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<String> _hashtags;
  @override
  @JsonKey()
  List<String> get hashtags {
    if (_hashtags is EqualUnmodifiableListView) return _hashtags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hashtags);
  }

  @override
  final String? scheduledAt;
  @override
  final String? startedAt;
  @override
  final String? endedAt;
  @override
  @JsonKey()
  final bool isRecordingEnabled;
  @override
  @JsonKey()
  final bool isDvrEnabled;
  @override
  @JsonKey()
  final bool isReplayEnabled;
  @override
  @JsonKey()
  final bool isChatEnabled;
  @override
  @JsonKey()
  final bool isChatSlowMode;
  @override
  @JsonKey()
  final int chatSlowModeSeconds;
  @override
  @JsonKey()
  final bool isMembersOnlyChat;
  @override
  @JsonKey()
  final bool isSubscribersOnlyChat;
  @override
  @JsonKey()
  final int peakViewerCount;
  @override
  @JsonKey()
  final int currentViewerCount;
  @override
  @JsonKey()
  final int totalViewerCount;
  @override
  @JsonKey()
  final int totalChatMessages;
  @override
  @JsonKey()
  final int totalReactions;
  @override
  @JsonKey()
  final int likesCount;
  @override
  final int? duration;
  @override
  final String createdAt;
  @override
  final String updatedAt;
  @override
  final StreamCreatorDto? createdBy;
  @override
  final StreamGroupDto? group;
  @override
  final StreamChannelDto? videoChannel;

  @override
  String toString() {
    return 'LiveStreamDto(id: $id, videoChannelId: $videoChannelId, groupId: $groupId, createdById: $createdById, title: $title, description: $description, slug: $slug, status: $status, visibility: $visibility, protocol: $protocol, hlsUrl: $hlsUrl, dashUrl: $dashUrl, webrtcUrl: $webrtcUrl, rtmpIngestUrl: $rtmpIngestUrl, thumbnailUrl: $thumbnailUrl, categories: $categories, tags: $tags, hashtags: $hashtags, scheduledAt: $scheduledAt, startedAt: $startedAt, endedAt: $endedAt, isRecordingEnabled: $isRecordingEnabled, isDvrEnabled: $isDvrEnabled, isReplayEnabled: $isReplayEnabled, isChatEnabled: $isChatEnabled, isChatSlowMode: $isChatSlowMode, chatSlowModeSeconds: $chatSlowModeSeconds, isMembersOnlyChat: $isMembersOnlyChat, isSubscribersOnlyChat: $isSubscribersOnlyChat, peakViewerCount: $peakViewerCount, currentViewerCount: $currentViewerCount, totalViewerCount: $totalViewerCount, totalChatMessages: $totalChatMessages, totalReactions: $totalReactions, likesCount: $likesCount, duration: $duration, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, group: $group, videoChannel: $videoChannel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiveStreamDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.videoChannelId, videoChannelId) ||
                other.videoChannelId == videoChannelId) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.createdById, createdById) ||
                other.createdById == createdById) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol) &&
            (identical(other.hlsUrl, hlsUrl) || other.hlsUrl == hlsUrl) &&
            (identical(other.dashUrl, dashUrl) || other.dashUrl == dashUrl) &&
            (identical(other.webrtcUrl, webrtcUrl) ||
                other.webrtcUrl == webrtcUrl) &&
            (identical(other.rtmpIngestUrl, rtmpIngestUrl) ||
                other.rtmpIngestUrl == rtmpIngestUrl) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(other._hashtags, _hashtags) &&
            (identical(other.scheduledAt, scheduledAt) ||
                other.scheduledAt == scheduledAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.isRecordingEnabled, isRecordingEnabled) ||
                other.isRecordingEnabled == isRecordingEnabled) &&
            (identical(other.isDvrEnabled, isDvrEnabled) ||
                other.isDvrEnabled == isDvrEnabled) &&
            (identical(other.isReplayEnabled, isReplayEnabled) ||
                other.isReplayEnabled == isReplayEnabled) &&
            (identical(other.isChatEnabled, isChatEnabled) ||
                other.isChatEnabled == isChatEnabled) &&
            (identical(other.isChatSlowMode, isChatSlowMode) ||
                other.isChatSlowMode == isChatSlowMode) &&
            (identical(other.chatSlowModeSeconds, chatSlowModeSeconds) ||
                other.chatSlowModeSeconds == chatSlowModeSeconds) &&
            (identical(other.isMembersOnlyChat, isMembersOnlyChat) ||
                other.isMembersOnlyChat == isMembersOnlyChat) &&
            (identical(other.isSubscribersOnlyChat, isSubscribersOnlyChat) ||
                other.isSubscribersOnlyChat == isSubscribersOnlyChat) &&
            (identical(other.peakViewerCount, peakViewerCount) ||
                other.peakViewerCount == peakViewerCount) &&
            (identical(other.currentViewerCount, currentViewerCount) ||
                other.currentViewerCount == currentViewerCount) &&
            (identical(other.totalViewerCount, totalViewerCount) ||
                other.totalViewerCount == totalViewerCount) &&
            (identical(other.totalChatMessages, totalChatMessages) ||
                other.totalChatMessages == totalChatMessages) &&
            (identical(other.totalReactions, totalReactions) ||
                other.totalReactions == totalReactions) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.group, group) || other.group == group) &&
            (identical(other.videoChannel, videoChannel) ||
                other.videoChannel == videoChannel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    videoChannelId,
    groupId,
    createdById,
    title,
    description,
    slug,
    status,
    visibility,
    protocol,
    hlsUrl,
    dashUrl,
    webrtcUrl,
    rtmpIngestUrl,
    thumbnailUrl,
    const DeepCollectionEquality().hash(_categories),
    const DeepCollectionEquality().hash(_tags),
    const DeepCollectionEquality().hash(_hashtags),
    scheduledAt,
    startedAt,
    endedAt,
    isRecordingEnabled,
    isDvrEnabled,
    isReplayEnabled,
    isChatEnabled,
    isChatSlowMode,
    chatSlowModeSeconds,
    isMembersOnlyChat,
    isSubscribersOnlyChat,
    peakViewerCount,
    currentViewerCount,
    totalViewerCount,
    totalChatMessages,
    totalReactions,
    likesCount,
    duration,
    createdAt,
    updatedAt,
    createdBy,
    group,
    videoChannel,
  ]);

  /// Create a copy of LiveStreamDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiveStreamDtoImplCopyWith<_$LiveStreamDtoImpl> get copyWith =>
      __$$LiveStreamDtoImplCopyWithImpl<_$LiveStreamDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LiveStreamDtoImplToJson(this);
  }
}

abstract class _LiveStreamDto implements LiveStreamDto {
  const factory _LiveStreamDto({
    required final String id,
    required final String videoChannelId,
    required final String groupId,
    required final String createdById,
    required final String title,
    final String? description,
    required final String slug,
    required final LiveStreamStatus status,
    required final LiveStreamVisibility visibility,
    required final StreamProtocol protocol,
    final String? hlsUrl,
    final String? dashUrl,
    final String? webrtcUrl,
    final String? rtmpIngestUrl,
    final String? thumbnailUrl,
    final List<String> categories,
    final List<String> tags,
    final List<String> hashtags,
    final String? scheduledAt,
    final String? startedAt,
    final String? endedAt,
    final bool isRecordingEnabled,
    final bool isDvrEnabled,
    final bool isReplayEnabled,
    final bool isChatEnabled,
    final bool isChatSlowMode,
    final int chatSlowModeSeconds,
    final bool isMembersOnlyChat,
    final bool isSubscribersOnlyChat,
    final int peakViewerCount,
    final int currentViewerCount,
    final int totalViewerCount,
    final int totalChatMessages,
    final int totalReactions,
    final int likesCount,
    final int? duration,
    required final String createdAt,
    required final String updatedAt,
    final StreamCreatorDto? createdBy,
    final StreamGroupDto? group,
    final StreamChannelDto? videoChannel,
  }) = _$LiveStreamDtoImpl;

  factory _LiveStreamDto.fromJson(Map<String, dynamic> json) =
      _$LiveStreamDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get videoChannelId;
  @override
  String get groupId;
  @override
  String get createdById;
  @override
  String get title;
  @override
  String? get description;
  @override
  String get slug;
  @override
  LiveStreamStatus get status;
  @override
  LiveStreamVisibility get visibility;
  @override
  StreamProtocol get protocol;
  @override
  String? get hlsUrl;
  @override
  String? get dashUrl;
  @override
  String? get webrtcUrl;
  @override
  String? get rtmpIngestUrl;
  @override
  String? get thumbnailUrl;
  @override
  List<String> get categories;
  @override
  List<String> get tags;
  @override
  List<String> get hashtags;
  @override
  String? get scheduledAt;
  @override
  String? get startedAt;
  @override
  String? get endedAt;
  @override
  bool get isRecordingEnabled;
  @override
  bool get isDvrEnabled;
  @override
  bool get isReplayEnabled;
  @override
  bool get isChatEnabled;
  @override
  bool get isChatSlowMode;
  @override
  int get chatSlowModeSeconds;
  @override
  bool get isMembersOnlyChat;
  @override
  bool get isSubscribersOnlyChat;
  @override
  int get peakViewerCount;
  @override
  int get currentViewerCount;
  @override
  int get totalViewerCount;
  @override
  int get totalChatMessages;
  @override
  int get totalReactions;
  @override
  int get likesCount;
  @override
  int? get duration;
  @override
  String get createdAt;
  @override
  String get updatedAt;
  @override
  StreamCreatorDto? get createdBy;
  @override
  StreamGroupDto? get group;
  @override
  StreamChannelDto? get videoChannel;

  /// Create a copy of LiveStreamDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiveStreamDtoImplCopyWith<_$LiveStreamDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StreamKeyDto _$StreamKeyDtoFromJson(Map<String, dynamic> json) {
  return _StreamKeyDto.fromJson(json);
}

/// @nodoc
mixin _$StreamKeyDto {
  String get channelId => throw _privateConstructorUsedError;
  String? get keyPrefix => throw _privateConstructorUsedError;
  String? get rtmpUrl =>
      throw _privateConstructorUsedError; // Only present when regenerated — the full key shown once
  String? get rawKey => throw _privateConstructorUsedError;

  /// Serializes this StreamKeyDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StreamKeyDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StreamKeyDtoCopyWith<StreamKeyDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StreamKeyDtoCopyWith<$Res> {
  factory $StreamKeyDtoCopyWith(
    StreamKeyDto value,
    $Res Function(StreamKeyDto) then,
  ) = _$StreamKeyDtoCopyWithImpl<$Res, StreamKeyDto>;
  @useResult
  $Res call({
    String channelId,
    String? keyPrefix,
    String? rtmpUrl,
    String? rawKey,
  });
}

/// @nodoc
class _$StreamKeyDtoCopyWithImpl<$Res, $Val extends StreamKeyDto>
    implements $StreamKeyDtoCopyWith<$Res> {
  _$StreamKeyDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StreamKeyDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channelId = null,
    Object? keyPrefix = freezed,
    Object? rtmpUrl = freezed,
    Object? rawKey = freezed,
  }) {
    return _then(
      _value.copyWith(
            channelId: null == channelId
                ? _value.channelId
                : channelId // ignore: cast_nullable_to_non_nullable
                      as String,
            keyPrefix: freezed == keyPrefix
                ? _value.keyPrefix
                : keyPrefix // ignore: cast_nullable_to_non_nullable
                      as String?,
            rtmpUrl: freezed == rtmpUrl
                ? _value.rtmpUrl
                : rtmpUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            rawKey: freezed == rawKey
                ? _value.rawKey
                : rawKey // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StreamKeyDtoImplCopyWith<$Res>
    implements $StreamKeyDtoCopyWith<$Res> {
  factory _$$StreamKeyDtoImplCopyWith(
    _$StreamKeyDtoImpl value,
    $Res Function(_$StreamKeyDtoImpl) then,
  ) = __$$StreamKeyDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String channelId,
    String? keyPrefix,
    String? rtmpUrl,
    String? rawKey,
  });
}

/// @nodoc
class __$$StreamKeyDtoImplCopyWithImpl<$Res>
    extends _$StreamKeyDtoCopyWithImpl<$Res, _$StreamKeyDtoImpl>
    implements _$$StreamKeyDtoImplCopyWith<$Res> {
  __$$StreamKeyDtoImplCopyWithImpl(
    _$StreamKeyDtoImpl _value,
    $Res Function(_$StreamKeyDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StreamKeyDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channelId = null,
    Object? keyPrefix = freezed,
    Object? rtmpUrl = freezed,
    Object? rawKey = freezed,
  }) {
    return _then(
      _$StreamKeyDtoImpl(
        channelId: null == channelId
            ? _value.channelId
            : channelId // ignore: cast_nullable_to_non_nullable
                  as String,
        keyPrefix: freezed == keyPrefix
            ? _value.keyPrefix
            : keyPrefix // ignore: cast_nullable_to_non_nullable
                  as String?,
        rtmpUrl: freezed == rtmpUrl
            ? _value.rtmpUrl
            : rtmpUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        rawKey: freezed == rawKey
            ? _value.rawKey
            : rawKey // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StreamKeyDtoImpl implements _StreamKeyDto {
  const _$StreamKeyDtoImpl({
    required this.channelId,
    this.keyPrefix,
    this.rtmpUrl,
    this.rawKey,
  });

  factory _$StreamKeyDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StreamKeyDtoImplFromJson(json);

  @override
  final String channelId;
  @override
  final String? keyPrefix;
  @override
  final String? rtmpUrl;
  // Only present when regenerated — the full key shown once
  @override
  final String? rawKey;

  @override
  String toString() {
    return 'StreamKeyDto(channelId: $channelId, keyPrefix: $keyPrefix, rtmpUrl: $rtmpUrl, rawKey: $rawKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StreamKeyDtoImpl &&
            (identical(other.channelId, channelId) ||
                other.channelId == channelId) &&
            (identical(other.keyPrefix, keyPrefix) ||
                other.keyPrefix == keyPrefix) &&
            (identical(other.rtmpUrl, rtmpUrl) || other.rtmpUrl == rtmpUrl) &&
            (identical(other.rawKey, rawKey) || other.rawKey == rawKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, channelId, keyPrefix, rtmpUrl, rawKey);

  /// Create a copy of StreamKeyDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StreamKeyDtoImplCopyWith<_$StreamKeyDtoImpl> get copyWith =>
      __$$StreamKeyDtoImplCopyWithImpl<_$StreamKeyDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StreamKeyDtoImplToJson(this);
  }
}

abstract class _StreamKeyDto implements StreamKeyDto {
  const factory _StreamKeyDto({
    required final String channelId,
    final String? keyPrefix,
    final String? rtmpUrl,
    final String? rawKey,
  }) = _$StreamKeyDtoImpl;

  factory _StreamKeyDto.fromJson(Map<String, dynamic> json) =
      _$StreamKeyDtoImpl.fromJson;

  @override
  String get channelId;
  @override
  String? get keyPrefix;
  @override
  String? get rtmpUrl; // Only present when regenerated — the full key shown once
  @override
  String? get rawKey;

  /// Create a copy of StreamKeyDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StreamKeyDtoImplCopyWith<_$StreamKeyDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
