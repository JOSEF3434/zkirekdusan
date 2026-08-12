// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CommentAuthorDto _$CommentAuthorDtoFromJson(Map<String, dynamic> json) {
  return _CommentAuthorDto.fromJson(json);
}

/// @nodoc
mixin _$CommentAuthorDto {
  String get id => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Serializes this CommentAuthorDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommentAuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentAuthorDtoCopyWith<CommentAuthorDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentAuthorDtoCopyWith<$Res> {
  factory $CommentAuthorDtoCopyWith(
    CommentAuthorDto value,
    $Res Function(CommentAuthorDto) then,
  ) = _$CommentAuthorDtoCopyWithImpl<$Res, CommentAuthorDto>;
  @useResult
  $Res call({
    String id,
    String? username,
    String? displayName,
    String? avatarUrl,
  });
}

/// @nodoc
class _$CommentAuthorDtoCopyWithImpl<$Res, $Val extends CommentAuthorDto>
    implements $CommentAuthorDtoCopyWith<$Res> {
  _$CommentAuthorDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommentAuthorDto
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
abstract class _$$CommentAuthorDtoImplCopyWith<$Res>
    implements $CommentAuthorDtoCopyWith<$Res> {
  factory _$$CommentAuthorDtoImplCopyWith(
    _$CommentAuthorDtoImpl value,
    $Res Function(_$CommentAuthorDtoImpl) then,
  ) = __$$CommentAuthorDtoImplCopyWithImpl<$Res>;
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
class __$$CommentAuthorDtoImplCopyWithImpl<$Res>
    extends _$CommentAuthorDtoCopyWithImpl<$Res, _$CommentAuthorDtoImpl>
    implements _$$CommentAuthorDtoImplCopyWith<$Res> {
  __$$CommentAuthorDtoImplCopyWithImpl(
    _$CommentAuthorDtoImpl _value,
    $Res Function(_$CommentAuthorDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommentAuthorDto
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
      _$CommentAuthorDtoImpl(
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
class _$CommentAuthorDtoImpl implements _CommentAuthorDto {
  const _$CommentAuthorDtoImpl({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory _$CommentAuthorDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentAuthorDtoImplFromJson(json);

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
    return 'CommentAuthorDto(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentAuthorDtoImpl &&
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

  /// Create a copy of CommentAuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentAuthorDtoImplCopyWith<_$CommentAuthorDtoImpl> get copyWith =>
      __$$CommentAuthorDtoImplCopyWithImpl<_$CommentAuthorDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentAuthorDtoImplToJson(this);
  }
}

abstract class _CommentAuthorDto implements CommentAuthorDto {
  const factory _CommentAuthorDto({
    required final String id,
    final String? username,
    final String? displayName,
    final String? avatarUrl,
  }) = _$CommentAuthorDtoImpl;

  factory _CommentAuthorDto.fromJson(Map<String, dynamic> json) =
      _$CommentAuthorDtoImpl.fromJson;

  @override
  String get id;
  @override
  String? get username;
  @override
  String? get displayName;
  @override
  String? get avatarUrl;

  /// Create a copy of CommentAuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentAuthorDtoImplCopyWith<_$CommentAuthorDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CommentResponseDto _$CommentResponseDtoFromJson(Map<String, dynamic> json) {
  return _CommentResponseDto.fromJson(json);
}

/// @nodoc
mixin _$CommentResponseDto {
  String get id => throw _privateConstructorUsedError;
  String get postId => throw _privateConstructorUsedError;
  String? get parentId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  int get likesCount => throw _privateConstructorUsedError;
  CommentAuthorDto get author => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  List<CommentResponseDto> get replies => throw _privateConstructorUsedError;

  /// Serializes this CommentResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentResponseDtoCopyWith<CommentResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentResponseDtoCopyWith<$Res> {
  factory $CommentResponseDtoCopyWith(
    CommentResponseDto value,
    $Res Function(CommentResponseDto) then,
  ) = _$CommentResponseDtoCopyWithImpl<$Res, CommentResponseDto>;
  @useResult
  $Res call({
    String id,
    String postId,
    String? parentId,
    String content,
    int likesCount,
    CommentAuthorDto author,
    DateTime createdAt,
    List<CommentResponseDto> replies,
  });

  $CommentAuthorDtoCopyWith<$Res> get author;
}

/// @nodoc
class _$CommentResponseDtoCopyWithImpl<$Res, $Val extends CommentResponseDto>
    implements $CommentResponseDtoCopyWith<$Res> {
  _$CommentResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? postId = null,
    Object? parentId = freezed,
    Object? content = null,
    Object? likesCount = null,
    Object? author = null,
    Object? createdAt = null,
    Object? replies = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            postId: null == postId
                ? _value.postId
                : postId // ignore: cast_nullable_to_non_nullable
                      as String,
            parentId: freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            likesCount: null == likesCount
                ? _value.likesCount
                : likesCount // ignore: cast_nullable_to_non_nullable
                      as int,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as CommentAuthorDto,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            replies: null == replies
                ? _value.replies
                : replies // ignore: cast_nullable_to_non_nullable
                      as List<CommentResponseDto>,
          )
          as $Val,
    );
  }

  /// Create a copy of CommentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CommentAuthorDtoCopyWith<$Res> get author {
    return $CommentAuthorDtoCopyWith<$Res>(_value.author, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommentResponseDtoImplCopyWith<$Res>
    implements $CommentResponseDtoCopyWith<$Res> {
  factory _$$CommentResponseDtoImplCopyWith(
    _$CommentResponseDtoImpl value,
    $Res Function(_$CommentResponseDtoImpl) then,
  ) = __$$CommentResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String postId,
    String? parentId,
    String content,
    int likesCount,
    CommentAuthorDto author,
    DateTime createdAt,
    List<CommentResponseDto> replies,
  });

  @override
  $CommentAuthorDtoCopyWith<$Res> get author;
}

/// @nodoc
class __$$CommentResponseDtoImplCopyWithImpl<$Res>
    extends _$CommentResponseDtoCopyWithImpl<$Res, _$CommentResponseDtoImpl>
    implements _$$CommentResponseDtoImplCopyWith<$Res> {
  __$$CommentResponseDtoImplCopyWithImpl(
    _$CommentResponseDtoImpl _value,
    $Res Function(_$CommentResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? postId = null,
    Object? parentId = freezed,
    Object? content = null,
    Object? likesCount = null,
    Object? author = null,
    Object? createdAt = null,
    Object? replies = null,
  }) {
    return _then(
      _$CommentResponseDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        postId: null == postId
            ? _value.postId
            : postId // ignore: cast_nullable_to_non_nullable
                  as String,
        parentId: freezed == parentId
            ? _value.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        likesCount: null == likesCount
            ? _value.likesCount
            : likesCount // ignore: cast_nullable_to_non_nullable
                  as int,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as CommentAuthorDto,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        replies: null == replies
            ? _value._replies
            : replies // ignore: cast_nullable_to_non_nullable
                  as List<CommentResponseDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentResponseDtoImpl implements _CommentResponseDto {
  const _$CommentResponseDtoImpl({
    required this.id,
    required this.postId,
    this.parentId,
    required this.content,
    this.likesCount = 0,
    required this.author,
    required this.createdAt,
    final List<CommentResponseDto> replies = const [],
  }) : _replies = replies;

  factory _$CommentResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentResponseDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String postId;
  @override
  final String? parentId;
  @override
  final String content;
  @override
  @JsonKey()
  final int likesCount;
  @override
  final CommentAuthorDto author;
  @override
  final DateTime createdAt;
  final List<CommentResponseDto> _replies;
  @override
  @JsonKey()
  List<CommentResponseDto> get replies {
    if (_replies is EqualUnmodifiableListView) return _replies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_replies);
  }

  @override
  String toString() {
    return 'CommentResponseDto(id: $id, postId: $postId, parentId: $parentId, content: $content, likesCount: $likesCount, author: $author, createdAt: $createdAt, replies: $replies)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentResponseDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._replies, _replies));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    postId,
    parentId,
    content,
    likesCount,
    author,
    createdAt,
    const DeepCollectionEquality().hash(_replies),
  );

  /// Create a copy of CommentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentResponseDtoImplCopyWith<_$CommentResponseDtoImpl> get copyWith =>
      __$$CommentResponseDtoImplCopyWithImpl<_$CommentResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentResponseDtoImplToJson(this);
  }
}

abstract class _CommentResponseDto implements CommentResponseDto {
  const factory _CommentResponseDto({
    required final String id,
    required final String postId,
    final String? parentId,
    required final String content,
    final int likesCount,
    required final CommentAuthorDto author,
    required final DateTime createdAt,
    final List<CommentResponseDto> replies,
  }) = _$CommentResponseDtoImpl;

  factory _CommentResponseDto.fromJson(Map<String, dynamic> json) =
      _$CommentResponseDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get postId;
  @override
  String? get parentId;
  @override
  String get content;
  @override
  int get likesCount;
  @override
  CommentAuthorDto get author;
  @override
  DateTime get createdAt;
  @override
  List<CommentResponseDto> get replies;

  /// Create a copy of CommentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentResponseDtoImplCopyWith<_$CommentResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
