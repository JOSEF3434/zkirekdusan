// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'creator_channel_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CreatorChannelDto _$CreatorChannelDtoFromJson(Map<String, dynamic> json) {
  return _CreatorChannelDto.fromJson(json);
}

/// @nodoc
mixin _$CreatorChannelDto {
  String get id => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  ChannelStatus get status => throw _privateConstructorUsedError;
  bool get isVerified => throw _privateConstructorUsedError;
  UploadPermission get uploadPermission => throw _privateConstructorUsedError;
  int get subscribersCount => throw _privateConstructorUsedError;
  int get videosCount => throw _privateConstructorUsedError;
  String? get totalViewsCount => throw _privateConstructorUsedError;
  List<String> get categories => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CreatorChannelDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorChannelDtoCopyWith<CreatorChannelDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorChannelDtoCopyWith<$Res> {
  factory $CreatorChannelDtoCopyWith(
    CreatorChannelDto value,
    $Res Function(CreatorChannelDto) then,
  ) = _$CreatorChannelDtoCopyWithImpl<$Res, CreatorChannelDto>;
  @useResult
  $Res call({
    String id,
    String groupId,
    String name,
    String slug,
    String handle,
    String? description,
    ChannelStatus status,
    bool isVerified,
    UploadPermission uploadPermission,
    int subscribersCount,
    int videosCount,
    String? totalViewsCount,
    List<String> categories,
    List<String> tags,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$CreatorChannelDtoCopyWithImpl<$Res, $Val extends CreatorChannelDto>
    implements $CreatorChannelDtoCopyWith<$Res> {
  _$CreatorChannelDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? name = null,
    Object? slug = null,
    Object? handle = null,
    Object? description = freezed,
    Object? status = null,
    Object? isVerified = null,
    Object? uploadPermission = null,
    Object? subscribersCount = null,
    Object? videosCount = null,
    Object? totalViewsCount = freezed,
    Object? categories = null,
    Object? tags = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            handle: null == handle
                ? _value.handle
                : handle // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ChannelStatus,
            isVerified: null == isVerified
                ? _value.isVerified
                : isVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            uploadPermission: null == uploadPermission
                ? _value.uploadPermission
                : uploadPermission // ignore: cast_nullable_to_non_nullable
                      as UploadPermission,
            subscribersCount: null == subscribersCount
                ? _value.subscribersCount
                : subscribersCount // ignore: cast_nullable_to_non_nullable
                      as int,
            videosCount: null == videosCount
                ? _value.videosCount
                : videosCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalViewsCount: freezed == totalViewsCount
                ? _value.totalViewsCount
                : totalViewsCount // ignore: cast_nullable_to_non_nullable
                      as String?,
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
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
}

/// @nodoc
abstract class _$$CreatorChannelDtoImplCopyWith<$Res>
    implements $CreatorChannelDtoCopyWith<$Res> {
  factory _$$CreatorChannelDtoImplCopyWith(
    _$CreatorChannelDtoImpl value,
    $Res Function(_$CreatorChannelDtoImpl) then,
  ) = __$$CreatorChannelDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String groupId,
    String name,
    String slug,
    String handle,
    String? description,
    ChannelStatus status,
    bool isVerified,
    UploadPermission uploadPermission,
    int subscribersCount,
    int videosCount,
    String? totalViewsCount,
    List<String> categories,
    List<String> tags,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$CreatorChannelDtoImplCopyWithImpl<$Res>
    extends _$CreatorChannelDtoCopyWithImpl<$Res, _$CreatorChannelDtoImpl>
    implements _$$CreatorChannelDtoImplCopyWith<$Res> {
  __$$CreatorChannelDtoImplCopyWithImpl(
    _$CreatorChannelDtoImpl _value,
    $Res Function(_$CreatorChannelDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? name = null,
    Object? slug = null,
    Object? handle = null,
    Object? description = freezed,
    Object? status = null,
    Object? isVerified = null,
    Object? uploadPermission = null,
    Object? subscribersCount = null,
    Object? videosCount = null,
    Object? totalViewsCount = freezed,
    Object? categories = null,
    Object? tags = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$CreatorChannelDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        handle: null == handle
            ? _value.handle
            : handle // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ChannelStatus,
        isVerified: null == isVerified
            ? _value.isVerified
            : isVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        uploadPermission: null == uploadPermission
            ? _value.uploadPermission
            : uploadPermission // ignore: cast_nullable_to_non_nullable
                  as UploadPermission,
        subscribersCount: null == subscribersCount
            ? _value.subscribersCount
            : subscribersCount // ignore: cast_nullable_to_non_nullable
                  as int,
        videosCount: null == videosCount
            ? _value.videosCount
            : videosCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalViewsCount: freezed == totalViewsCount
            ? _value.totalViewsCount
            : totalViewsCount // ignore: cast_nullable_to_non_nullable
                  as String?,
        categories: null == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
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
class _$CreatorChannelDtoImpl implements _CreatorChannelDto {
  const _$CreatorChannelDtoImpl({
    required this.id,
    required this.groupId,
    required this.name,
    required this.slug,
    required this.handle,
    this.description,
    required this.status,
    required this.isVerified,
    required this.uploadPermission,
    this.subscribersCount = 0,
    this.videosCount = 0,
    this.totalViewsCount,
    final List<String> categories = const [],
    final List<String> tags = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : _categories = categories,
       _tags = tags;

  factory _$CreatorChannelDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorChannelDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String groupId;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String handle;
  @override
  final String? description;
  @override
  final ChannelStatus status;
  @override
  final bool isVerified;
  @override
  final UploadPermission uploadPermission;
  @override
  @JsonKey()
  final int subscribersCount;
  @override
  @JsonKey()
  final int videosCount;
  @override
  final String? totalViewsCount;
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

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'CreatorChannelDto(id: $id, groupId: $groupId, name: $name, slug: $slug, handle: $handle, description: $description, status: $status, isVerified: $isVerified, uploadPermission: $uploadPermission, subscribersCount: $subscribersCount, videosCount: $videosCount, totalViewsCount: $totalViewsCount, categories: $categories, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorChannelDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.uploadPermission, uploadPermission) ||
                other.uploadPermission == uploadPermission) &&
            (identical(other.subscribersCount, subscribersCount) ||
                other.subscribersCount == subscribersCount) &&
            (identical(other.videosCount, videosCount) ||
                other.videosCount == videosCount) &&
            (identical(other.totalViewsCount, totalViewsCount) ||
                other.totalViewsCount == totalViewsCount) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
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
    groupId,
    name,
    slug,
    handle,
    description,
    status,
    isVerified,
    uploadPermission,
    subscribersCount,
    videosCount,
    totalViewsCount,
    const DeepCollectionEquality().hash(_categories),
    const DeepCollectionEquality().hash(_tags),
    createdAt,
    updatedAt,
  );

  /// Create a copy of CreatorChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorChannelDtoImplCopyWith<_$CreatorChannelDtoImpl> get copyWith =>
      __$$CreatorChannelDtoImplCopyWithImpl<_$CreatorChannelDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorChannelDtoImplToJson(this);
  }
}

abstract class _CreatorChannelDto implements CreatorChannelDto {
  const factory _CreatorChannelDto({
    required final String id,
    required final String groupId,
    required final String name,
    required final String slug,
    required final String handle,
    final String? description,
    required final ChannelStatus status,
    required final bool isVerified,
    required final UploadPermission uploadPermission,
    final int subscribersCount,
    final int videosCount,
    final String? totalViewsCount,
    final List<String> categories,
    final List<String> tags,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$CreatorChannelDtoImpl;

  factory _CreatorChannelDto.fromJson(Map<String, dynamic> json) =
      _$CreatorChannelDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get groupId;
  @override
  String get name;
  @override
  String get slug;
  @override
  String get handle;
  @override
  String? get description;
  @override
  ChannelStatus get status;
  @override
  bool get isVerified;
  @override
  UploadPermission get uploadPermission;
  @override
  int get subscribersCount;
  @override
  int get videosCount;
  @override
  String? get totalViewsCount;
  @override
  List<String> get categories;
  @override
  List<String> get tags;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of CreatorChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorChannelDtoImplCopyWith<_$CreatorChannelDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
