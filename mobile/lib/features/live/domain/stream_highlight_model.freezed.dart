// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_highlight_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StreamHighlightDto _$StreamHighlightDtoFromJson(Map<String, dynamic> json) {
  return _StreamHighlightDto.fromJson(json);
}

/// @nodoc
mixin _$StreamHighlightDto {
  String get id => throw _privateConstructorUsedError;
  String get streamId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get startTimeSec => throw _privateConstructorUsedError;
  int get endTimeSec => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this StreamHighlightDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StreamHighlightDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StreamHighlightDtoCopyWith<StreamHighlightDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StreamHighlightDtoCopyWith<$Res> {
  factory $StreamHighlightDtoCopyWith(
    StreamHighlightDto value,
    $Res Function(StreamHighlightDto) then,
  ) = _$StreamHighlightDtoCopyWithImpl<$Res, StreamHighlightDto>;
  @useResult
  $Res call({
    String id,
    String streamId,
    String title,
    String? description,
    int startTimeSec,
    int endTimeSec,
    String createdAt,
  });
}

/// @nodoc
class _$StreamHighlightDtoCopyWithImpl<$Res, $Val extends StreamHighlightDto>
    implements $StreamHighlightDtoCopyWith<$Res> {
  _$StreamHighlightDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StreamHighlightDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? streamId = null,
    Object? title = null,
    Object? description = freezed,
    Object? startTimeSec = null,
    Object? endTimeSec = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            streamId: null == streamId
                ? _value.streamId
                : streamId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            startTimeSec: null == startTimeSec
                ? _value.startTimeSec
                : startTimeSec // ignore: cast_nullable_to_non_nullable
                      as int,
            endTimeSec: null == endTimeSec
                ? _value.endTimeSec
                : endTimeSec // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StreamHighlightDtoImplCopyWith<$Res>
    implements $StreamHighlightDtoCopyWith<$Res> {
  factory _$$StreamHighlightDtoImplCopyWith(
    _$StreamHighlightDtoImpl value,
    $Res Function(_$StreamHighlightDtoImpl) then,
  ) = __$$StreamHighlightDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String streamId,
    String title,
    String? description,
    int startTimeSec,
    int endTimeSec,
    String createdAt,
  });
}

/// @nodoc
class __$$StreamHighlightDtoImplCopyWithImpl<$Res>
    extends _$StreamHighlightDtoCopyWithImpl<$Res, _$StreamHighlightDtoImpl>
    implements _$$StreamHighlightDtoImplCopyWith<$Res> {
  __$$StreamHighlightDtoImplCopyWithImpl(
    _$StreamHighlightDtoImpl _value,
    $Res Function(_$StreamHighlightDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StreamHighlightDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? streamId = null,
    Object? title = null,
    Object? description = freezed,
    Object? startTimeSec = null,
    Object? endTimeSec = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$StreamHighlightDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        streamId: null == streamId
            ? _value.streamId
            : streamId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        startTimeSec: null == startTimeSec
            ? _value.startTimeSec
            : startTimeSec // ignore: cast_nullable_to_non_nullable
                  as int,
        endTimeSec: null == endTimeSec
            ? _value.endTimeSec
            : endTimeSec // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StreamHighlightDtoImpl implements _StreamHighlightDto {
  const _$StreamHighlightDtoImpl({
    required this.id,
    required this.streamId,
    required this.title,
    this.description,
    required this.startTimeSec,
    required this.endTimeSec,
    required this.createdAt,
  });

  factory _$StreamHighlightDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StreamHighlightDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String streamId;
  @override
  final String title;
  @override
  final String? description;
  @override
  final int startTimeSec;
  @override
  final int endTimeSec;
  @override
  final String createdAt;

  @override
  String toString() {
    return 'StreamHighlightDto(id: $id, streamId: $streamId, title: $title, description: $description, startTimeSec: $startTimeSec, endTimeSec: $endTimeSec, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StreamHighlightDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.streamId, streamId) ||
                other.streamId == streamId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.startTimeSec, startTimeSec) ||
                other.startTimeSec == startTimeSec) &&
            (identical(other.endTimeSec, endTimeSec) ||
                other.endTimeSec == endTimeSec) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    streamId,
    title,
    description,
    startTimeSec,
    endTimeSec,
    createdAt,
  );

  /// Create a copy of StreamHighlightDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StreamHighlightDtoImplCopyWith<_$StreamHighlightDtoImpl> get copyWith =>
      __$$StreamHighlightDtoImplCopyWithImpl<_$StreamHighlightDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StreamHighlightDtoImplToJson(this);
  }
}

abstract class _StreamHighlightDto implements StreamHighlightDto {
  const factory _StreamHighlightDto({
    required final String id,
    required final String streamId,
    required final String title,
    final String? description,
    required final int startTimeSec,
    required final int endTimeSec,
    required final String createdAt,
  }) = _$StreamHighlightDtoImpl;

  factory _StreamHighlightDto.fromJson(Map<String, dynamic> json) =
      _$StreamHighlightDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get streamId;
  @override
  String get title;
  @override
  String? get description;
  @override
  int get startTimeSec;
  @override
  int get endTimeSec;
  @override
  String get createdAt;

  /// Create a copy of StreamHighlightDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StreamHighlightDtoImplCopyWith<_$StreamHighlightDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
