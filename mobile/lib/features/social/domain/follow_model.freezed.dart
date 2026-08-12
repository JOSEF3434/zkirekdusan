// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FollowStatusDto _$FollowStatusDtoFromJson(Map<String, dynamic> json) {
  return _FollowStatusDto.fromJson(json);
}

/// @nodoc
mixin _$FollowStatusDto {
  bool get isFollowing => throw _privateConstructorUsedError;
  bool get isFollowedBy => throw _privateConstructorUsedError;

  /// Serializes this FollowStatusDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FollowStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FollowStatusDtoCopyWith<FollowStatusDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowStatusDtoCopyWith<$Res> {
  factory $FollowStatusDtoCopyWith(
    FollowStatusDto value,
    $Res Function(FollowStatusDto) then,
  ) = _$FollowStatusDtoCopyWithImpl<$Res, FollowStatusDto>;
  @useResult
  $Res call({bool isFollowing, bool isFollowedBy});
}

/// @nodoc
class _$FollowStatusDtoCopyWithImpl<$Res, $Val extends FollowStatusDto>
    implements $FollowStatusDtoCopyWith<$Res> {
  _$FollowStatusDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FollowStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? isFollowing = null, Object? isFollowedBy = null}) {
    return _then(
      _value.copyWith(
            isFollowing: null == isFollowing
                ? _value.isFollowing
                : isFollowing // ignore: cast_nullable_to_non_nullable
                      as bool,
            isFollowedBy: null == isFollowedBy
                ? _value.isFollowedBy
                : isFollowedBy // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FollowStatusDtoImplCopyWith<$Res>
    implements $FollowStatusDtoCopyWith<$Res> {
  factory _$$FollowStatusDtoImplCopyWith(
    _$FollowStatusDtoImpl value,
    $Res Function(_$FollowStatusDtoImpl) then,
  ) = __$$FollowStatusDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isFollowing, bool isFollowedBy});
}

/// @nodoc
class __$$FollowStatusDtoImplCopyWithImpl<$Res>
    extends _$FollowStatusDtoCopyWithImpl<$Res, _$FollowStatusDtoImpl>
    implements _$$FollowStatusDtoImplCopyWith<$Res> {
  __$$FollowStatusDtoImplCopyWithImpl(
    _$FollowStatusDtoImpl _value,
    $Res Function(_$FollowStatusDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FollowStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? isFollowing = null, Object? isFollowedBy = null}) {
    return _then(
      _$FollowStatusDtoImpl(
        isFollowing: null == isFollowing
            ? _value.isFollowing
            : isFollowing // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFollowedBy: null == isFollowedBy
            ? _value.isFollowedBy
            : isFollowedBy // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FollowStatusDtoImpl implements _FollowStatusDto {
  const _$FollowStatusDtoImpl({
    required this.isFollowing,
    required this.isFollowedBy,
  });

  factory _$FollowStatusDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowStatusDtoImplFromJson(json);

  @override
  final bool isFollowing;
  @override
  final bool isFollowedBy;

  @override
  String toString() {
    return 'FollowStatusDto(isFollowing: $isFollowing, isFollowedBy: $isFollowedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowStatusDtoImpl &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.isFollowedBy, isFollowedBy) ||
                other.isFollowedBy == isFollowedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, isFollowing, isFollowedBy);

  /// Create a copy of FollowStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowStatusDtoImplCopyWith<_$FollowStatusDtoImpl> get copyWith =>
      __$$FollowStatusDtoImplCopyWithImpl<_$FollowStatusDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowStatusDtoImplToJson(this);
  }
}

abstract class _FollowStatusDto implements FollowStatusDto {
  const factory _FollowStatusDto({
    required final bool isFollowing,
    required final bool isFollowedBy,
  }) = _$FollowStatusDtoImpl;

  factory _FollowStatusDto.fromJson(Map<String, dynamic> json) =
      _$FollowStatusDtoImpl.fromJson;

  @override
  bool get isFollowing;
  @override
  bool get isFollowedBy;

  /// Create a copy of FollowStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FollowStatusDtoImplCopyWith<_$FollowStatusDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FollowerDto _$FollowerDtoFromJson(Map<String, dynamic> json) {
  return _FollowerDto.fromJson(json);
}

/// @nodoc
mixin _$FollowerDto {
  String get id => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  bool get isFollowing => throw _privateConstructorUsedError;

  /// Serializes this FollowerDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FollowerDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FollowerDtoCopyWith<FollowerDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowerDtoCopyWith<$Res> {
  factory $FollowerDtoCopyWith(
    FollowerDto value,
    $Res Function(FollowerDto) then,
  ) = _$FollowerDtoCopyWithImpl<$Res, FollowerDto>;
  @useResult
  $Res call({
    String id,
    String? username,
    String? displayName,
    String? avatarUrl,
    bool isFollowing,
  });
}

/// @nodoc
class _$FollowerDtoCopyWithImpl<$Res, $Val extends FollowerDto>
    implements $FollowerDtoCopyWith<$Res> {
  _$FollowerDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FollowerDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = freezed,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? isFollowing = null,
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
            isFollowing: null == isFollowing
                ? _value.isFollowing
                : isFollowing // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FollowerDtoImplCopyWith<$Res>
    implements $FollowerDtoCopyWith<$Res> {
  factory _$$FollowerDtoImplCopyWith(
    _$FollowerDtoImpl value,
    $Res Function(_$FollowerDtoImpl) then,
  ) = __$$FollowerDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? username,
    String? displayName,
    String? avatarUrl,
    bool isFollowing,
  });
}

/// @nodoc
class __$$FollowerDtoImplCopyWithImpl<$Res>
    extends _$FollowerDtoCopyWithImpl<$Res, _$FollowerDtoImpl>
    implements _$$FollowerDtoImplCopyWith<$Res> {
  __$$FollowerDtoImplCopyWithImpl(
    _$FollowerDtoImpl _value,
    $Res Function(_$FollowerDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FollowerDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = freezed,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? isFollowing = null,
  }) {
    return _then(
      _$FollowerDtoImpl(
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
        isFollowing: null == isFollowing
            ? _value.isFollowing
            : isFollowing // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FollowerDtoImpl implements _FollowerDto {
  const _$FollowerDtoImpl({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isFollowing = false,
  });

  factory _$FollowerDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowerDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String? username;
  @override
  final String? displayName;
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  final bool isFollowing;

  @override
  String toString() {
    return 'FollowerDto(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, isFollowing: $isFollowing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowerDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    username,
    displayName,
    avatarUrl,
    isFollowing,
  );

  /// Create a copy of FollowerDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowerDtoImplCopyWith<_$FollowerDtoImpl> get copyWith =>
      __$$FollowerDtoImplCopyWithImpl<_$FollowerDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowerDtoImplToJson(this);
  }
}

abstract class _FollowerDto implements FollowerDto {
  const factory _FollowerDto({
    required final String id,
    final String? username,
    final String? displayName,
    final String? avatarUrl,
    final bool isFollowing,
  }) = _$FollowerDtoImpl;

  factory _FollowerDto.fromJson(Map<String, dynamic> json) =
      _$FollowerDtoImpl.fromJson;

  @override
  String get id;
  @override
  String? get username;
  @override
  String? get displayName;
  @override
  String? get avatarUrl;
  @override
  bool get isFollowing;

  /// Create a copy of FollowerDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FollowerDtoImplCopyWith<_$FollowerDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
