// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_highlight_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StreamHighlightDto {

 String get id; String get streamId; String get title; String? get description; int get startTimeSec; int get endTimeSec; String get createdAt;
/// Create a copy of StreamHighlightDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamHighlightDtoCopyWith<StreamHighlightDto> get copyWith => _$StreamHighlightDtoCopyWithImpl<StreamHighlightDto>(this as StreamHighlightDto, _$identity);

  /// Serializes this StreamHighlightDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamHighlightDto&&(identical(other.id, id) || other.id == id)&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.startTimeSec, startTimeSec) || other.startTimeSec == startTimeSec)&&(identical(other.endTimeSec, endTimeSec) || other.endTimeSec == endTimeSec)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,streamId,title,description,startTimeSec,endTimeSec,createdAt);

@override
String toString() {
  return 'StreamHighlightDto(id: $id, streamId: $streamId, title: $title, description: $description, startTimeSec: $startTimeSec, endTimeSec: $endTimeSec, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $StreamHighlightDtoCopyWith<$Res>  {
  factory $StreamHighlightDtoCopyWith(StreamHighlightDto value, $Res Function(StreamHighlightDto) _then) = _$StreamHighlightDtoCopyWithImpl;
@useResult
$Res call({
 String id, String streamId, String title, String? description, int startTimeSec, int endTimeSec, String createdAt
});




}
/// @nodoc
class _$StreamHighlightDtoCopyWithImpl<$Res>
    implements $StreamHighlightDtoCopyWith<$Res> {
  _$StreamHighlightDtoCopyWithImpl(this._self, this._then);

  final StreamHighlightDto _self;
  final $Res Function(StreamHighlightDto) _then;

/// Create a copy of StreamHighlightDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? streamId = null,Object? title = null,Object? description = freezed,Object? startTimeSec = null,Object? endTimeSec = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,streamId: null == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startTimeSec: null == startTimeSec ? _self.startTimeSec : startTimeSec // ignore: cast_nullable_to_non_nullable
as int,endTimeSec: null == endTimeSec ? _self.endTimeSec : endTimeSec // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamHighlightDto].
extension StreamHighlightDtoPatterns on StreamHighlightDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamHighlightDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamHighlightDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamHighlightDto value)  $default,){
final _that = this;
switch (_that) {
case _StreamHighlightDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamHighlightDto value)?  $default,){
final _that = this;
switch (_that) {
case _StreamHighlightDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String streamId,  String title,  String? description,  int startTimeSec,  int endTimeSec,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamHighlightDto() when $default != null:
return $default(_that.id,_that.streamId,_that.title,_that.description,_that.startTimeSec,_that.endTimeSec,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String streamId,  String title,  String? description,  int startTimeSec,  int endTimeSec,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _StreamHighlightDto():
return $default(_that.id,_that.streamId,_that.title,_that.description,_that.startTimeSec,_that.endTimeSec,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String streamId,  String title,  String? description,  int startTimeSec,  int endTimeSec,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _StreamHighlightDto() when $default != null:
return $default(_that.id,_that.streamId,_that.title,_that.description,_that.startTimeSec,_that.endTimeSec,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreamHighlightDto implements StreamHighlightDto {
  const _StreamHighlightDto({required this.id, required this.streamId, required this.title, this.description, required this.startTimeSec, required this.endTimeSec, required this.createdAt});
  factory _StreamHighlightDto.fromJson(Map<String, dynamic> json) => _$StreamHighlightDtoFromJson(json);

@override final  String id;
@override final  String streamId;
@override final  String title;
@override final  String? description;
@override final  int startTimeSec;
@override final  int endTimeSec;
@override final  String createdAt;

/// Create a copy of StreamHighlightDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamHighlightDtoCopyWith<_StreamHighlightDto> get copyWith => __$StreamHighlightDtoCopyWithImpl<_StreamHighlightDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreamHighlightDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamHighlightDto&&(identical(other.id, id) || other.id == id)&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.startTimeSec, startTimeSec) || other.startTimeSec == startTimeSec)&&(identical(other.endTimeSec, endTimeSec) || other.endTimeSec == endTimeSec)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,streamId,title,description,startTimeSec,endTimeSec,createdAt);

@override
String toString() {
  return 'StreamHighlightDto(id: $id, streamId: $streamId, title: $title, description: $description, startTimeSec: $startTimeSec, endTimeSec: $endTimeSec, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$StreamHighlightDtoCopyWith<$Res> implements $StreamHighlightDtoCopyWith<$Res> {
  factory _$StreamHighlightDtoCopyWith(_StreamHighlightDto value, $Res Function(_StreamHighlightDto) _then) = __$StreamHighlightDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String streamId, String title, String? description, int startTimeSec, int endTimeSec, String createdAt
});




}
/// @nodoc
class __$StreamHighlightDtoCopyWithImpl<$Res>
    implements _$StreamHighlightDtoCopyWith<$Res> {
  __$StreamHighlightDtoCopyWithImpl(this._self, this._then);

  final _StreamHighlightDto _self;
  final $Res Function(_StreamHighlightDto) _then;

/// Create a copy of StreamHighlightDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? streamId = null,Object? title = null,Object? description = freezed,Object? startTimeSec = null,Object? endTimeSec = null,Object? createdAt = null,}) {
  return _then(_StreamHighlightDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,streamId: null == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startTimeSec: null == startTimeSec ? _self.startTimeSec : startTimeSec // ignore: cast_nullable_to_non_nullable
as int,endTimeSec: null == endTimeSec ? _self.endTimeSec : endTimeSec // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
