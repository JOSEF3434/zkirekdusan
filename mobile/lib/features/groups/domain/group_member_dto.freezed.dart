// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_member_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GroupMemberDto _$GroupMemberDtoFromJson(Map<String, dynamic> json) {
  return _GroupMemberDto.fromJson(json);
}

/// @nodoc
mixin _$GroupMemberDto {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  GroupRole get role => throw _privateConstructorUsedError;
  DateTime get joinedAt => throw _privateConstructorUsedError;

  /// Serializes this GroupMemberDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupMemberDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupMemberDtoCopyWith<GroupMemberDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupMemberDtoCopyWith<$Res> {
  factory $GroupMemberDtoCopyWith(
    GroupMemberDto value,
    $Res Function(GroupMemberDto) then,
  ) = _$GroupMemberDtoCopyWithImpl<$Res, GroupMemberDto>;
  @useResult
  $Res call({
    String id,
    String userId,
    String? username,
    String? displayName,
    GroupRole role,
    DateTime joinedAt,
  });
}

/// @nodoc
class _$GroupMemberDtoCopyWithImpl<$Res, $Val extends GroupMemberDto>
    implements $GroupMemberDtoCopyWith<$Res> {
  _$GroupMemberDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupMemberDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? username = freezed,
    Object? displayName = freezed,
    Object? role = null,
    Object? joinedAt = null,
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
            username: freezed == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String?,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as GroupRole,
            joinedAt: null == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GroupMemberDtoImplCopyWith<$Res>
    implements $GroupMemberDtoCopyWith<$Res> {
  factory _$$GroupMemberDtoImplCopyWith(
    _$GroupMemberDtoImpl value,
    $Res Function(_$GroupMemberDtoImpl) then,
  ) = __$$GroupMemberDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String? username,
    String? displayName,
    GroupRole role,
    DateTime joinedAt,
  });
}

/// @nodoc
class __$$GroupMemberDtoImplCopyWithImpl<$Res>
    extends _$GroupMemberDtoCopyWithImpl<$Res, _$GroupMemberDtoImpl>
    implements _$$GroupMemberDtoImplCopyWith<$Res> {
  __$$GroupMemberDtoImplCopyWithImpl(
    _$GroupMemberDtoImpl _value,
    $Res Function(_$GroupMemberDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroupMemberDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? username = freezed,
    Object? displayName = freezed,
    Object? role = null,
    Object? joinedAt = null,
  }) {
    return _then(
      _$GroupMemberDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        username: freezed == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String?,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as GroupRole,
        joinedAt: null == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupMemberDtoImpl implements _GroupMemberDto {
  const _$GroupMemberDtoImpl({
    required this.id,
    required this.userId,
    this.username,
    this.displayName,
    required this.role,
    required this.joinedAt,
  });

  factory _$GroupMemberDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupMemberDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? username;
  @override
  final String? displayName;
  @override
  final GroupRole role;
  @override
  final DateTime joinedAt;

  @override
  String toString() {
    return 'GroupMemberDto(id: $id, userId: $userId, username: $username, displayName: $displayName, role: $role, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupMemberDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    username,
    displayName,
    role,
    joinedAt,
  );

  /// Create a copy of GroupMemberDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupMemberDtoImplCopyWith<_$GroupMemberDtoImpl> get copyWith =>
      __$$GroupMemberDtoImplCopyWithImpl<_$GroupMemberDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupMemberDtoImplToJson(this);
  }
}

abstract class _GroupMemberDto implements GroupMemberDto {
  const factory _GroupMemberDto({
    required final String id,
    required final String userId,
    final String? username,
    final String? displayName,
    required final GroupRole role,
    required final DateTime joinedAt,
  }) = _$GroupMemberDtoImpl;

  factory _GroupMemberDto.fromJson(Map<String, dynamic> json) =
      _$GroupMemberDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get username;
  @override
  String? get displayName;
  @override
  GroupRole get role;
  @override
  DateTime get joinedAt;

  /// Create a copy of GroupMemberDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupMemberDtoImplCopyWith<_$GroupMemberDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
