// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlaylistDto _$PlaylistDtoFromJson(Map<String, dynamic> json) {
  return _PlaylistDto.fromJson(json);
}

/// @nodoc
mixin _$PlaylistDto {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get privacy => throw _privateConstructorUsedError;
  List<PlaylistItemDto> get items => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PlaylistDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaylistDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaylistDtoCopyWith<PlaylistDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistDtoCopyWith<$Res> {
  factory $PlaylistDtoCopyWith(
    PlaylistDto value,
    $Res Function(PlaylistDto) then,
  ) = _$PlaylistDtoCopyWithImpl<$Res, PlaylistDto>;
  @useResult
  $Res call({
    String id,
    String userId,
    String title,
    String? description,
    String privacy,
    List<PlaylistItemDto> items,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$PlaylistDtoCopyWithImpl<$Res, $Val extends PlaylistDto>
    implements $PlaylistDtoCopyWith<$Res> {
  _$PlaylistDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaylistDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? description = freezed,
    Object? privacy = null,
    Object? items = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            privacy: null == privacy
                ? _value.privacy
                : privacy // ignore: cast_nullable_to_non_nullable
                      as String,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<PlaylistItemDto>,
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
}

/// @nodoc
abstract class _$$PlaylistDtoImplCopyWith<$Res>
    implements $PlaylistDtoCopyWith<$Res> {
  factory _$$PlaylistDtoImplCopyWith(
    _$PlaylistDtoImpl value,
    $Res Function(_$PlaylistDtoImpl) then,
  ) = __$$PlaylistDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String title,
    String? description,
    String privacy,
    List<PlaylistItemDto> items,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$PlaylistDtoImplCopyWithImpl<$Res>
    extends _$PlaylistDtoCopyWithImpl<$Res, _$PlaylistDtoImpl>
    implements _$$PlaylistDtoImplCopyWith<$Res> {
  __$$PlaylistDtoImplCopyWithImpl(
    _$PlaylistDtoImpl _value,
    $Res Function(_$PlaylistDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? description = freezed,
    Object? privacy = null,
    Object? items = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$PlaylistDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        privacy: null == privacy
            ? _value.privacy
            : privacy // ignore: cast_nullable_to_non_nullable
                  as String,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<PlaylistItemDto>,
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
class _$PlaylistDtoImpl implements _PlaylistDto {
  const _$PlaylistDtoImpl({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.privacy = 'private',
    final List<PlaylistItemDto> items = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : _items = items;

  factory _$PlaylistDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey()
  final String privacy;
  final List<PlaylistItemDto> _items;
  @override
  @JsonKey()
  List<PlaylistItemDto> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'PlaylistDto(id: $id, userId: $userId, title: $title, description: $description, privacy: $privacy, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.privacy, privacy) || other.privacy == privacy) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    title,
    description,
    privacy,
    const DeepCollectionEquality().hash(_items),
    createdAt,
    updatedAt,
  );

  /// Create a copy of PlaylistDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistDtoImplCopyWith<_$PlaylistDtoImpl> get copyWith =>
      __$$PlaylistDtoImplCopyWithImpl<_$PlaylistDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistDtoImplToJson(this);
  }
}

abstract class _PlaylistDto implements PlaylistDto {
  const factory _PlaylistDto({
    required final String id,
    required final String userId,
    required final String title,
    final String? description,
    final String privacy,
    final List<PlaylistItemDto> items,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$PlaylistDtoImpl;

  factory _PlaylistDto.fromJson(Map<String, dynamic> json) =
      _$PlaylistDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get title;
  @override
  String? get description;
  @override
  String get privacy;
  @override
  List<PlaylistItemDto> get items;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of PlaylistDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistDtoImplCopyWith<_$PlaylistDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaylistItemDto _$PlaylistItemDtoFromJson(Map<String, dynamic> json) {
  return _PlaylistItemDto.fromJson(json);
}

/// @nodoc
mixin _$PlaylistItemDto {
  String get videoId => throw _privateConstructorUsedError;
  DateTime get addedAt => throw _privateConstructorUsedError;

  /// Serializes this PlaylistItemDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaylistItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaylistItemDtoCopyWith<PlaylistItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistItemDtoCopyWith<$Res> {
  factory $PlaylistItemDtoCopyWith(
    PlaylistItemDto value,
    $Res Function(PlaylistItemDto) then,
  ) = _$PlaylistItemDtoCopyWithImpl<$Res, PlaylistItemDto>;
  @useResult
  $Res call({String videoId, DateTime addedAt});
}

/// @nodoc
class _$PlaylistItemDtoCopyWithImpl<$Res, $Val extends PlaylistItemDto>
    implements $PlaylistItemDtoCopyWith<$Res> {
  _$PlaylistItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaylistItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? videoId = null, Object? addedAt = null}) {
    return _then(
      _value.copyWith(
            videoId: null == videoId
                ? _value.videoId
                : videoId // ignore: cast_nullable_to_non_nullable
                      as String,
            addedAt: null == addedAt
                ? _value.addedAt
                : addedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaylistItemDtoImplCopyWith<$Res>
    implements $PlaylistItemDtoCopyWith<$Res> {
  factory _$$PlaylistItemDtoImplCopyWith(
    _$PlaylistItemDtoImpl value,
    $Res Function(_$PlaylistItemDtoImpl) then,
  ) = __$$PlaylistItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String videoId, DateTime addedAt});
}

/// @nodoc
class __$$PlaylistItemDtoImplCopyWithImpl<$Res>
    extends _$PlaylistItemDtoCopyWithImpl<$Res, _$PlaylistItemDtoImpl>
    implements _$$PlaylistItemDtoImplCopyWith<$Res> {
  __$$PlaylistItemDtoImplCopyWithImpl(
    _$PlaylistItemDtoImpl _value,
    $Res Function(_$PlaylistItemDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? videoId = null, Object? addedAt = null}) {
    return _then(
      _$PlaylistItemDtoImpl(
        videoId: null == videoId
            ? _value.videoId
            : videoId // ignore: cast_nullable_to_non_nullable
                  as String,
        addedAt: null == addedAt
            ? _value.addedAt
            : addedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaylistItemDtoImpl implements _PlaylistItemDto {
  const _$PlaylistItemDtoImpl({required this.videoId, required this.addedAt});

  factory _$PlaylistItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistItemDtoImplFromJson(json);

  @override
  final String videoId;
  @override
  final DateTime addedAt;

  @override
  String toString() {
    return 'PlaylistItemDto(videoId: $videoId, addedAt: $addedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistItemDtoImpl &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, videoId, addedAt);

  /// Create a copy of PlaylistItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistItemDtoImplCopyWith<_$PlaylistItemDtoImpl> get copyWith =>
      __$$PlaylistItemDtoImplCopyWithImpl<_$PlaylistItemDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistItemDtoImplToJson(this);
  }
}

abstract class _PlaylistItemDto implements PlaylistItemDto {
  const factory _PlaylistItemDto({
    required final String videoId,
    required final DateTime addedAt,
  }) = _$PlaylistItemDtoImpl;

  factory _PlaylistItemDto.fromJson(Map<String, dynamic> json) =
      _$PlaylistItemDtoImpl.fromJson;

  @override
  String get videoId;
  @override
  DateTime get addedAt;

  /// Create a copy of PlaylistItemDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistItemDtoImplCopyWith<_$PlaylistItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
