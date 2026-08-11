// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FeedMetaDto _$FeedMetaDtoFromJson(Map<String, dynamic> json) {
  return _FeedMetaDto.fromJson(json);
}

/// @nodoc
mixin _$FeedMetaDto {
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get totalPages => throw _privateConstructorUsedError;
  bool get hasNext => throw _privateConstructorUsedError;
  bool get hasPrev => throw _privateConstructorUsedError;

  /// Serializes this FeedMetaDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeedMetaDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedMetaDtoCopyWith<FeedMetaDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedMetaDtoCopyWith<$Res> {
  factory $FeedMetaDtoCopyWith(
    FeedMetaDto value,
    $Res Function(FeedMetaDto) then,
  ) = _$FeedMetaDtoCopyWithImpl<$Res, FeedMetaDto>;
  @useResult
  $Res call({
    int page,
    int limit,
    int total,
    int totalPages,
    bool hasNext,
    bool hasPrev,
  });
}

/// @nodoc
class _$FeedMetaDtoCopyWithImpl<$Res, $Val extends FeedMetaDto>
    implements $FeedMetaDtoCopyWith<$Res> {
  _$FeedMetaDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedMetaDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? page = null,
    Object? limit = null,
    Object? total = null,
    Object? totalPages = null,
    Object? hasNext = null,
    Object? hasPrev = null,
  }) {
    return _then(
      _value.copyWith(
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPages: null == totalPages
                ? _value.totalPages
                : totalPages // ignore: cast_nullable_to_non_nullable
                      as int,
            hasNext: null == hasNext
                ? _value.hasNext
                : hasNext // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasPrev: null == hasPrev
                ? _value.hasPrev
                : hasPrev // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FeedMetaDtoImplCopyWith<$Res>
    implements $FeedMetaDtoCopyWith<$Res> {
  factory _$$FeedMetaDtoImplCopyWith(
    _$FeedMetaDtoImpl value,
    $Res Function(_$FeedMetaDtoImpl) then,
  ) = __$$FeedMetaDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int page,
    int limit,
    int total,
    int totalPages,
    bool hasNext,
    bool hasPrev,
  });
}

/// @nodoc
class __$$FeedMetaDtoImplCopyWithImpl<$Res>
    extends _$FeedMetaDtoCopyWithImpl<$Res, _$FeedMetaDtoImpl>
    implements _$$FeedMetaDtoImplCopyWith<$Res> {
  __$$FeedMetaDtoImplCopyWithImpl(
    _$FeedMetaDtoImpl _value,
    $Res Function(_$FeedMetaDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FeedMetaDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? page = null,
    Object? limit = null,
    Object? total = null,
    Object? totalPages = null,
    Object? hasNext = null,
    Object? hasPrev = null,
  }) {
    return _then(
      _$FeedMetaDtoImpl(
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPages: null == totalPages
            ? _value.totalPages
            : totalPages // ignore: cast_nullable_to_non_nullable
                  as int,
        hasNext: null == hasNext
            ? _value.hasNext
            : hasNext // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasPrev: null == hasPrev
            ? _value.hasPrev
            : hasPrev // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedMetaDtoImpl implements _FeedMetaDto {
  const _$FeedMetaDtoImpl({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory _$FeedMetaDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedMetaDtoImplFromJson(json);

  @override
  final int page;
  @override
  final int limit;
  @override
  final int total;
  @override
  final int totalPages;
  @override
  final bool hasNext;
  @override
  final bool hasPrev;

  @override
  String toString() {
    return 'FeedMetaDto(page: $page, limit: $limit, total: $total, totalPages: $totalPages, hasNext: $hasNext, hasPrev: $hasPrev)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedMetaDtoImpl &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages) &&
            (identical(other.hasNext, hasNext) || other.hasNext == hasNext) &&
            (identical(other.hasPrev, hasPrev) || other.hasPrev == hasPrev));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    page,
    limit,
    total,
    totalPages,
    hasNext,
    hasPrev,
  );

  /// Create a copy of FeedMetaDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedMetaDtoImplCopyWith<_$FeedMetaDtoImpl> get copyWith =>
      __$$FeedMetaDtoImplCopyWithImpl<_$FeedMetaDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedMetaDtoImplToJson(this);
  }
}

abstract class _FeedMetaDto implements FeedMetaDto {
  const factory _FeedMetaDto({
    required final int page,
    required final int limit,
    required final int total,
    required final int totalPages,
    required final bool hasNext,
    required final bool hasPrev,
  }) = _$FeedMetaDtoImpl;

  factory _FeedMetaDto.fromJson(Map<String, dynamic> json) =
      _$FeedMetaDtoImpl.fromJson;

  @override
  int get page;
  @override
  int get limit;
  @override
  int get total;
  @override
  int get totalPages;
  @override
  bool get hasNext;
  @override
  bool get hasPrev;

  /// Create a copy of FeedMetaDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedMetaDtoImplCopyWith<_$FeedMetaDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FeedResponseDto _$FeedResponseDtoFromJson(Map<String, dynamic> json) {
  return _FeedResponseDto.fromJson(json);
}

/// @nodoc
mixin _$FeedResponseDto {
  List<PostResponseDto> get data => throw _privateConstructorUsedError;
  FeedMetaDto get meta => throw _privateConstructorUsedError;

  /// Serializes this FeedResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeedResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedResponseDtoCopyWith<FeedResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedResponseDtoCopyWith<$Res> {
  factory $FeedResponseDtoCopyWith(
    FeedResponseDto value,
    $Res Function(FeedResponseDto) then,
  ) = _$FeedResponseDtoCopyWithImpl<$Res, FeedResponseDto>;
  @useResult
  $Res call({List<PostResponseDto> data, FeedMetaDto meta});

  $FeedMetaDtoCopyWith<$Res> get meta;
}

/// @nodoc
class _$FeedResponseDtoCopyWithImpl<$Res, $Val extends FeedResponseDto>
    implements $FeedResponseDtoCopyWith<$Res> {
  _$FeedResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null, Object? meta = null}) {
    return _then(
      _value.copyWith(
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as List<PostResponseDto>,
            meta: null == meta
                ? _value.meta
                : meta // ignore: cast_nullable_to_non_nullable
                      as FeedMetaDto,
          )
          as $Val,
    );
  }

  /// Create a copy of FeedResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FeedMetaDtoCopyWith<$Res> get meta {
    return $FeedMetaDtoCopyWith<$Res>(_value.meta, (value) {
      return _then(_value.copyWith(meta: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FeedResponseDtoImplCopyWith<$Res>
    implements $FeedResponseDtoCopyWith<$Res> {
  factory _$$FeedResponseDtoImplCopyWith(
    _$FeedResponseDtoImpl value,
    $Res Function(_$FeedResponseDtoImpl) then,
  ) = __$$FeedResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<PostResponseDto> data, FeedMetaDto meta});

  @override
  $FeedMetaDtoCopyWith<$Res> get meta;
}

/// @nodoc
class __$$FeedResponseDtoImplCopyWithImpl<$Res>
    extends _$FeedResponseDtoCopyWithImpl<$Res, _$FeedResponseDtoImpl>
    implements _$$FeedResponseDtoImplCopyWith<$Res> {
  __$$FeedResponseDtoImplCopyWithImpl(
    _$FeedResponseDtoImpl _value,
    $Res Function(_$FeedResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FeedResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null, Object? meta = null}) {
    return _then(
      _$FeedResponseDtoImpl(
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as List<PostResponseDto>,
        meta: null == meta
            ? _value.meta
            : meta // ignore: cast_nullable_to_non_nullable
                  as FeedMetaDto,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedResponseDtoImpl implements _FeedResponseDto {
  const _$FeedResponseDtoImpl({
    required final List<PostResponseDto> data,
    required this.meta,
  }) : _data = data;

  factory _$FeedResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedResponseDtoImplFromJson(json);

  final List<PostResponseDto> _data;
  @override
  List<PostResponseDto> get data {
    if (_data is EqualUnmodifiableListView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_data);
  }

  @override
  final FeedMetaDto meta;

  @override
  String toString() {
    return 'FeedResponseDto(data: $data, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedResponseDtoImpl &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.meta, meta) || other.meta == meta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_data),
    meta,
  );

  /// Create a copy of FeedResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedResponseDtoImplCopyWith<_$FeedResponseDtoImpl> get copyWith =>
      __$$FeedResponseDtoImplCopyWithImpl<_$FeedResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedResponseDtoImplToJson(this);
  }
}

abstract class _FeedResponseDto implements FeedResponseDto {
  const factory _FeedResponseDto({
    required final List<PostResponseDto> data,
    required final FeedMetaDto meta,
  }) = _$FeedResponseDtoImpl;

  factory _FeedResponseDto.fromJson(Map<String, dynamic> json) =
      _$FeedResponseDtoImpl.fromJson;

  @override
  List<PostResponseDto> get data;
  @override
  FeedMetaDto get meta;

  /// Create a copy of FeedResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedResponseDtoImplCopyWith<_$FeedResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
