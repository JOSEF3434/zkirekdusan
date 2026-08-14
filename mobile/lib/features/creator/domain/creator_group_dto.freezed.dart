// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'creator_group_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CreatorGroupDto _$CreatorGroupDtoFromJson(Map<String, dynamic> json) {
  return _CreatorGroupDto.fromJson(json);
}

/// @nodoc
mixin _$CreatorGroupDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  GroupStatus get status => throw _privateConstructorUsedError;
  GroupVisibility get visibility => throw _privateConstructorUsedError;
  String get createdById => throw _privateConstructorUsedError;
  String? get approvedById => throw _privateConstructorUsedError;
  DateTime? get approvedAt => throw _privateConstructorUsedError;
  int get membersCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;

  /// Serializes this CreatorGroupDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorGroupDtoCopyWith<CreatorGroupDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorGroupDtoCopyWith<$Res> {
  factory $CreatorGroupDtoCopyWith(
    CreatorGroupDto value,
    $Res Function(CreatorGroupDto) then,
  ) = _$CreatorGroupDtoCopyWithImpl<$Res, CreatorGroupDto>;
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String? description,
    GroupStatus status,
    GroupVisibility visibility,
    String createdById,
    String? approvedById,
    DateTime? approvedAt,
    int membersCount,
    DateTime createdAt,
    String? avatarUrl,
    String? coverUrl,
  });
}

/// @nodoc
class _$CreatorGroupDtoCopyWithImpl<$Res, $Val extends CreatorGroupDto>
    implements $CreatorGroupDtoCopyWith<$Res> {
  _$CreatorGroupDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? description = freezed,
    Object? status = null,
    Object? visibility = null,
    Object? createdById = null,
    Object? approvedById = freezed,
    Object? approvedAt = freezed,
    Object? membersCount = null,
    Object? createdAt = null,
    Object? avatarUrl = freezed,
    Object? coverUrl = freezed,
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
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as GroupStatus,
            visibility: null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                      as GroupVisibility,
            createdById: null == createdById
                ? _value.createdById
                : createdById // ignore: cast_nullable_to_non_nullable
                      as String,
            approvedById: freezed == approvedById
                ? _value.approvedById
                : approvedById // ignore: cast_nullable_to_non_nullable
                      as String?,
            approvedAt: freezed == approvedAt
                ? _value.approvedAt
                : approvedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            membersCount: null == membersCount
                ? _value.membersCount
                : membersCount // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            coverUrl: freezed == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatorGroupDtoImplCopyWith<$Res>
    implements $CreatorGroupDtoCopyWith<$Res> {
  factory _$$CreatorGroupDtoImplCopyWith(
    _$CreatorGroupDtoImpl value,
    $Res Function(_$CreatorGroupDtoImpl) then,
  ) = __$$CreatorGroupDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String? description,
    GroupStatus status,
    GroupVisibility visibility,
    String createdById,
    String? approvedById,
    DateTime? approvedAt,
    int membersCount,
    DateTime createdAt,
    String? avatarUrl,
    String? coverUrl,
  });
}

/// @nodoc
class __$$CreatorGroupDtoImplCopyWithImpl<$Res>
    extends _$CreatorGroupDtoCopyWithImpl<$Res, _$CreatorGroupDtoImpl>
    implements _$$CreatorGroupDtoImplCopyWith<$Res> {
  __$$CreatorGroupDtoImplCopyWithImpl(
    _$CreatorGroupDtoImpl _value,
    $Res Function(_$CreatorGroupDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? description = freezed,
    Object? status = null,
    Object? visibility = null,
    Object? createdById = null,
    Object? approvedById = freezed,
    Object? approvedAt = freezed,
    Object? membersCount = null,
    Object? createdAt = null,
    Object? avatarUrl = freezed,
    Object? coverUrl = freezed,
  }) {
    return _then(
      _$CreatorGroupDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as GroupStatus,
        visibility: null == visibility
            ? _value.visibility
            : visibility // ignore: cast_nullable_to_non_nullable
                  as GroupVisibility,
        createdById: null == createdById
            ? _value.createdById
            : createdById // ignore: cast_nullable_to_non_nullable
                  as String,
        approvedById: freezed == approvedById
            ? _value.approvedById
            : approvedById // ignore: cast_nullable_to_non_nullable
                  as String?,
        approvedAt: freezed == approvedAt
            ? _value.approvedAt
            : approvedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        membersCount: null == membersCount
            ? _value.membersCount
            : membersCount // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        coverUrl: freezed == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorGroupDtoImpl implements _CreatorGroupDto {
  const _$CreatorGroupDtoImpl({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.status,
    required this.visibility,
    required this.createdById,
    this.approvedById,
    this.approvedAt,
    required this.membersCount,
    required this.createdAt,
    this.avatarUrl,
    this.coverUrl,
  });

  factory _$CreatorGroupDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorGroupDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String? description;
  @override
  final GroupStatus status;
  @override
  final GroupVisibility visibility;
  @override
  final String createdById;
  @override
  final String? approvedById;
  @override
  final DateTime? approvedAt;
  @override
  final int membersCount;
  @override
  final DateTime createdAt;
  @override
  final String? avatarUrl;
  @override
  final String? coverUrl;

  @override
  String toString() {
    return 'CreatorGroupDto(id: $id, name: $name, slug: $slug, description: $description, status: $status, visibility: $visibility, createdById: $createdById, approvedById: $approvedById, approvedAt: $approvedAt, membersCount: $membersCount, createdAt: $createdAt, avatarUrl: $avatarUrl, coverUrl: $coverUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorGroupDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.createdById, createdById) ||
                other.createdById == createdById) &&
            (identical(other.approvedById, approvedById) ||
                other.approvedById == approvedById) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt) &&
            (identical(other.membersCount, membersCount) ||
                other.membersCount == membersCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    slug,
    description,
    status,
    visibility,
    createdById,
    approvedById,
    approvedAt,
    membersCount,
    createdAt,
    avatarUrl,
    coverUrl,
  );

  /// Create a copy of CreatorGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorGroupDtoImplCopyWith<_$CreatorGroupDtoImpl> get copyWith =>
      __$$CreatorGroupDtoImplCopyWithImpl<_$CreatorGroupDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorGroupDtoImplToJson(this);
  }
}

abstract class _CreatorGroupDto implements CreatorGroupDto {
  const factory _CreatorGroupDto({
    required final String id,
    required final String name,
    required final String slug,
    final String? description,
    required final GroupStatus status,
    required final GroupVisibility visibility,
    required final String createdById,
    final String? approvedById,
    final DateTime? approvedAt,
    required final int membersCount,
    required final DateTime createdAt,
    final String? avatarUrl,
    final String? coverUrl,
  }) = _$CreatorGroupDtoImpl;

  factory _CreatorGroupDto.fromJson(Map<String, dynamic> json) =
      _$CreatorGroupDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get slug;
  @override
  String? get description;
  @override
  GroupStatus get status;
  @override
  GroupVisibility get visibility;
  @override
  String get createdById;
  @override
  String? get approvedById;
  @override
  DateTime? get approvedAt;
  @override
  int get membersCount;
  @override
  DateTime get createdAt;
  @override
  String? get avatarUrl;
  @override
  String? get coverUrl;

  /// Create a copy of CreatorGroupDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorGroupDtoImplCopyWith<_$CreatorGroupDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
