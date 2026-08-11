// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PostAuthorDto _$PostAuthorDtoFromJson(Map<String, dynamic> json) {
  return _PostAuthorDto.fromJson(json);
}

/// @nodoc
mixin _$PostAuthorDto {
  String get id => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Serializes this PostAuthorDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostAuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostAuthorDtoCopyWith<PostAuthorDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostAuthorDtoCopyWith<$Res> {
  factory $PostAuthorDtoCopyWith(
    PostAuthorDto value,
    $Res Function(PostAuthorDto) then,
  ) = _$PostAuthorDtoCopyWithImpl<$Res, PostAuthorDto>;
  @useResult
  $Res call({
    String id,
    String? username,
    String? displayName,
    String? avatarUrl,
  });
}

/// @nodoc
class _$PostAuthorDtoCopyWithImpl<$Res, $Val extends PostAuthorDto>
    implements $PostAuthorDtoCopyWith<$Res> {
  _$PostAuthorDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostAuthorDto
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
abstract class _$$PostAuthorDtoImplCopyWith<$Res>
    implements $PostAuthorDtoCopyWith<$Res> {
  factory _$$PostAuthorDtoImplCopyWith(
    _$PostAuthorDtoImpl value,
    $Res Function(_$PostAuthorDtoImpl) then,
  ) = __$$PostAuthorDtoImplCopyWithImpl<$Res>;
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
class __$$PostAuthorDtoImplCopyWithImpl<$Res>
    extends _$PostAuthorDtoCopyWithImpl<$Res, _$PostAuthorDtoImpl>
    implements _$$PostAuthorDtoImplCopyWith<$Res> {
  __$$PostAuthorDtoImplCopyWithImpl(
    _$PostAuthorDtoImpl _value,
    $Res Function(_$PostAuthorDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PostAuthorDto
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
      _$PostAuthorDtoImpl(
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
class _$PostAuthorDtoImpl implements _PostAuthorDto {
  const _$PostAuthorDtoImpl({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory _$PostAuthorDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostAuthorDtoImplFromJson(json);

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
    return 'PostAuthorDto(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostAuthorDtoImpl &&
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

  /// Create a copy of PostAuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostAuthorDtoImplCopyWith<_$PostAuthorDtoImpl> get copyWith =>
      __$$PostAuthorDtoImplCopyWithImpl<_$PostAuthorDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostAuthorDtoImplToJson(this);
  }
}

abstract class _PostAuthorDto implements PostAuthorDto {
  const factory _PostAuthorDto({
    required final String id,
    final String? username,
    final String? displayName,
    final String? avatarUrl,
  }) = _$PostAuthorDtoImpl;

  factory _PostAuthorDto.fromJson(Map<String, dynamic> json) =
      _$PostAuthorDtoImpl.fromJson;

  @override
  String get id;
  @override
  String? get username;
  @override
  String? get displayName;
  @override
  String? get avatarUrl;

  /// Create a copy of PostAuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostAuthorDtoImplCopyWith<_$PostAuthorDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PostMediaItemDto _$PostMediaItemDtoFromJson(Map<String, dynamic> json) {
  return _PostMediaItemDto.fromJson(json);
}

/// @nodoc
mixin _$PostMediaItemDto {
  String get id => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get fileType => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;

  /// Serializes this PostMediaItemDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostMediaItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostMediaItemDtoCopyWith<PostMediaItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostMediaItemDtoCopyWith<$Res> {
  factory $PostMediaItemDtoCopyWith(
    PostMediaItemDto value,
    $Res Function(PostMediaItemDto) then,
  ) = _$PostMediaItemDtoCopyWithImpl<$Res, PostMediaItemDto>;
  @useResult
  $Res call({String id, String url, String fileType, int order});
}

/// @nodoc
class _$PostMediaItemDtoCopyWithImpl<$Res, $Val extends PostMediaItemDto>
    implements $PostMediaItemDtoCopyWith<$Res> {
  _$PostMediaItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostMediaItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? fileType = null,
    Object? order = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            fileType: null == fileType
                ? _value.fileType
                : fileType // ignore: cast_nullable_to_non_nullable
                      as String,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PostMediaItemDtoImplCopyWith<$Res>
    implements $PostMediaItemDtoCopyWith<$Res> {
  factory _$$PostMediaItemDtoImplCopyWith(
    _$PostMediaItemDtoImpl value,
    $Res Function(_$PostMediaItemDtoImpl) then,
  ) = __$$PostMediaItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String url, String fileType, int order});
}

/// @nodoc
class __$$PostMediaItemDtoImplCopyWithImpl<$Res>
    extends _$PostMediaItemDtoCopyWithImpl<$Res, _$PostMediaItemDtoImpl>
    implements _$$PostMediaItemDtoImplCopyWith<$Res> {
  __$$PostMediaItemDtoImplCopyWithImpl(
    _$PostMediaItemDtoImpl _value,
    $Res Function(_$PostMediaItemDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PostMediaItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? fileType = null,
    Object? order = null,
  }) {
    return _then(
      _$PostMediaItemDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        fileType: null == fileType
            ? _value.fileType
            : fileType // ignore: cast_nullable_to_non_nullable
                  as String,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PostMediaItemDtoImpl implements _PostMediaItemDto {
  const _$PostMediaItemDtoImpl({
    required this.id,
    required this.url,
    required this.fileType,
    required this.order,
  });

  factory _$PostMediaItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostMediaItemDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String url;
  @override
  final String fileType;
  @override
  final int order;

  @override
  String toString() {
    return 'PostMediaItemDto(id: $id, url: $url, fileType: $fileType, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostMediaItemDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.order, order) || other.order == order));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, url, fileType, order);

  /// Create a copy of PostMediaItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostMediaItemDtoImplCopyWith<_$PostMediaItemDtoImpl> get copyWith =>
      __$$PostMediaItemDtoImplCopyWithImpl<_$PostMediaItemDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PostMediaItemDtoImplToJson(this);
  }
}

abstract class _PostMediaItemDto implements PostMediaItemDto {
  const factory _PostMediaItemDto({
    required final String id,
    required final String url,
    required final String fileType,
    required final int order,
  }) = _$PostMediaItemDtoImpl;

  factory _PostMediaItemDto.fromJson(Map<String, dynamic> json) =
      _$PostMediaItemDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get url;
  @override
  String get fileType;
  @override
  int get order;

  /// Create a copy of PostMediaItemDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostMediaItemDtoImplCopyWith<_$PostMediaItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PostResponseDto _$PostResponseDtoFromJson(Map<String, dynamic> json) {
  return _PostResponseDto.fromJson(json);
}

/// @nodoc
mixin _$PostResponseDto {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get visibility => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  List<String> get hashtags => throw _privateConstructorUsedError;
  int get likesCount => throw _privateConstructorUsedError;
  int get commentsCount => throw _privateConstructorUsedError;
  int get viewsCount => throw _privateConstructorUsedError;
  PostAuthorDto get author => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  List<PostMediaItemDto> get media => throw _privateConstructorUsedError;
  bool? get isLiked => throw _privateConstructorUsedError;
  bool? get isSaved => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PostResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostResponseDtoCopyWith<PostResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostResponseDtoCopyWith<$Res> {
  factory $PostResponseDtoCopyWith(
    PostResponseDto value,
    $Res Function(PostResponseDto) then,
  ) = _$PostResponseDtoCopyWithImpl<$Res, PostResponseDto>;
  @useResult
  $Res call({
    String id,
    String type,
    String visibility,
    String? content,
    List<String> hashtags,
    int likesCount,
    int commentsCount,
    int viewsCount,
    PostAuthorDto author,
    String? groupId,
    List<PostMediaItemDto> media,
    bool? isLiked,
    bool? isSaved,
    DateTime createdAt,
    DateTime updatedAt,
  });

  $PostAuthorDtoCopyWith<$Res> get author;
}

/// @nodoc
class _$PostResponseDtoCopyWithImpl<$Res, $Val extends PostResponseDto>
    implements $PostResponseDtoCopyWith<$Res> {
  _$PostResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? visibility = null,
    Object? content = freezed,
    Object? hashtags = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? viewsCount = null,
    Object? author = null,
    Object? groupId = freezed,
    Object? media = null,
    Object? isLiked = freezed,
    Object? isSaved = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
            visibility: null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                      as String,
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            hashtags: null == hashtags
                ? _value.hashtags
                : hashtags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            likesCount: null == likesCount
                ? _value.likesCount
                : likesCount // ignore: cast_nullable_to_non_nullable
                      as int,
            commentsCount: null == commentsCount
                ? _value.commentsCount
                : commentsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            viewsCount: null == viewsCount
                ? _value.viewsCount
                : viewsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as PostAuthorDto,
            groupId: freezed == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String?,
            media: null == media
                ? _value.media
                : media // ignore: cast_nullable_to_non_nullable
                      as List<PostMediaItemDto>,
            isLiked: freezed == isLiked
                ? _value.isLiked
                : isLiked // ignore: cast_nullable_to_non_nullable
                      as bool?,
            isSaved: freezed == isSaved
                ? _value.isSaved
                : isSaved // ignore: cast_nullable_to_non_nullable
                      as bool?,
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

  /// Create a copy of PostResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PostAuthorDtoCopyWith<$Res> get author {
    return $PostAuthorDtoCopyWith<$Res>(_value.author, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PostResponseDtoImplCopyWith<$Res>
    implements $PostResponseDtoCopyWith<$Res> {
  factory _$$PostResponseDtoImplCopyWith(
    _$PostResponseDtoImpl value,
    $Res Function(_$PostResponseDtoImpl) then,
  ) = __$$PostResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String type,
    String visibility,
    String? content,
    List<String> hashtags,
    int likesCount,
    int commentsCount,
    int viewsCount,
    PostAuthorDto author,
    String? groupId,
    List<PostMediaItemDto> media,
    bool? isLiked,
    bool? isSaved,
    DateTime createdAt,
    DateTime updatedAt,
  });

  @override
  $PostAuthorDtoCopyWith<$Res> get author;
}

/// @nodoc
class __$$PostResponseDtoImplCopyWithImpl<$Res>
    extends _$PostResponseDtoCopyWithImpl<$Res, _$PostResponseDtoImpl>
    implements _$$PostResponseDtoImplCopyWith<$Res> {
  __$$PostResponseDtoImplCopyWithImpl(
    _$PostResponseDtoImpl _value,
    $Res Function(_$PostResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PostResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? visibility = null,
    Object? content = freezed,
    Object? hashtags = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? viewsCount = null,
    Object? author = null,
    Object? groupId = freezed,
    Object? media = null,
    Object? isLiked = freezed,
    Object? isSaved = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$PostResponseDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        visibility: null == visibility
            ? _value.visibility
            : visibility // ignore: cast_nullable_to_non_nullable
                  as String,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        hashtags: null == hashtags
            ? _value._hashtags
            : hashtags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        likesCount: null == likesCount
            ? _value.likesCount
            : likesCount // ignore: cast_nullable_to_non_nullable
                  as int,
        commentsCount: null == commentsCount
            ? _value.commentsCount
            : commentsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        viewsCount: null == viewsCount
            ? _value.viewsCount
            : viewsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as PostAuthorDto,
        groupId: freezed == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String?,
        media: null == media
            ? _value._media
            : media // ignore: cast_nullable_to_non_nullable
                  as List<PostMediaItemDto>,
        isLiked: freezed == isLiked
            ? _value.isLiked
            : isLiked // ignore: cast_nullable_to_non_nullable
                  as bool?,
        isSaved: freezed == isSaved
            ? _value.isSaved
            : isSaved // ignore: cast_nullable_to_non_nullable
                  as bool?,
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
class _$PostResponseDtoImpl implements _PostResponseDto {
  const _$PostResponseDtoImpl({
    required this.id,
    required this.type,
    required this.visibility,
    this.content,
    required final List<String> hashtags,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.author,
    this.groupId,
    required final List<PostMediaItemDto> media,
    this.isLiked,
    this.isSaved,
    required this.createdAt,
    required this.updatedAt,
  }) : _hashtags = hashtags,
       _media = media;

  factory _$PostResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostResponseDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  @override
  final String visibility;
  @override
  final String? content;
  final List<String> _hashtags;
  @override
  List<String> get hashtags {
    if (_hashtags is EqualUnmodifiableListView) return _hashtags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hashtags);
  }

  @override
  final int likesCount;
  @override
  final int commentsCount;
  @override
  final int viewsCount;
  @override
  final PostAuthorDto author;
  @override
  final String? groupId;
  final List<PostMediaItemDto> _media;
  @override
  List<PostMediaItemDto> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  @override
  final bool? isLiked;
  @override
  final bool? isSaved;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'PostResponseDto(id: $id, type: $type, visibility: $visibility, content: $content, hashtags: $hashtags, likesCount: $likesCount, commentsCount: $commentsCount, viewsCount: $viewsCount, author: $author, groupId: $groupId, media: $media, isLiked: $isLiked, isSaved: $isSaved, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostResponseDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other._hashtags, _hashtags) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.commentsCount, commentsCount) ||
                other.commentsCount == commentsCount) &&
            (identical(other.viewsCount, viewsCount) ||
                other.viewsCount == viewsCount) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            const DeepCollectionEquality().equals(other._media, _media) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked) &&
            (identical(other.isSaved, isSaved) || other.isSaved == isSaved) &&
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
    type,
    visibility,
    content,
    const DeepCollectionEquality().hash(_hashtags),
    likesCount,
    commentsCount,
    viewsCount,
    author,
    groupId,
    const DeepCollectionEquality().hash(_media),
    isLiked,
    isSaved,
    createdAt,
    updatedAt,
  );

  /// Create a copy of PostResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostResponseDtoImplCopyWith<_$PostResponseDtoImpl> get copyWith =>
      __$$PostResponseDtoImplCopyWithImpl<_$PostResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PostResponseDtoImplToJson(this);
  }
}

abstract class _PostResponseDto implements PostResponseDto {
  const factory _PostResponseDto({
    required final String id,
    required final String type,
    required final String visibility,
    final String? content,
    required final List<String> hashtags,
    required final int likesCount,
    required final int commentsCount,
    required final int viewsCount,
    required final PostAuthorDto author,
    final String? groupId,
    required final List<PostMediaItemDto> media,
    final bool? isLiked,
    final bool? isSaved,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$PostResponseDtoImpl;

  factory _PostResponseDto.fromJson(Map<String, dynamic> json) =
      _$PostResponseDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  String get visibility;
  @override
  String? get content;
  @override
  List<String> get hashtags;
  @override
  int get likesCount;
  @override
  int get commentsCount;
  @override
  int get viewsCount;
  @override
  PostAuthorDto get author;
  @override
  String? get groupId;
  @override
  List<PostMediaItemDto> get media;
  @override
  bool? get isLiked;
  @override
  bool? get isSaved;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of PostResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostResponseDtoImplCopyWith<_$PostResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
