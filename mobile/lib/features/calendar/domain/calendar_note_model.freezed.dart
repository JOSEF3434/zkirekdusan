// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_note_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalendarNoteModel {

 String get id; String get userId; int get ethiopianYear; int get ethiopianMonth; int get ethiopianDay; DateTime get gregorianDate; String? get title; String? get content; bool get hasReminder; DateTime? get reminderDateTime; bool get reminderNotified; ReminderRepeat get reminderRepeat; int? get reminderEthiopianMonth; int? get reminderEthiopianDay; int? get reminderHour; int? get reminderMinute; String get reminderTimezone; DateTime? get reminderNextOccurrence; List<CalendarNoteMedia> get media; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt;
/// Create a copy of CalendarNoteModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarNoteModelCopyWith<CalendarNoteModel> get copyWith => _$CalendarNoteModelCopyWithImpl<CalendarNoteModel>(this as CalendarNoteModel, _$identity);

  /// Serializes this CalendarNoteModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarNoteModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.ethiopianYear, ethiopianYear) || other.ethiopianYear == ethiopianYear)&&(identical(other.ethiopianMonth, ethiopianMonth) || other.ethiopianMonth == ethiopianMonth)&&(identical(other.ethiopianDay, ethiopianDay) || other.ethiopianDay == ethiopianDay)&&(identical(other.gregorianDate, gregorianDate) || other.gregorianDate == gregorianDate)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.hasReminder, hasReminder) || other.hasReminder == hasReminder)&&(identical(other.reminderDateTime, reminderDateTime) || other.reminderDateTime == reminderDateTime)&&(identical(other.reminderNotified, reminderNotified) || other.reminderNotified == reminderNotified)&&(identical(other.reminderRepeat, reminderRepeat) || other.reminderRepeat == reminderRepeat)&&(identical(other.reminderEthiopianMonth, reminderEthiopianMonth) || other.reminderEthiopianMonth == reminderEthiopianMonth)&&(identical(other.reminderEthiopianDay, reminderEthiopianDay) || other.reminderEthiopianDay == reminderEthiopianDay)&&(identical(other.reminderHour, reminderHour) || other.reminderHour == reminderHour)&&(identical(other.reminderMinute, reminderMinute) || other.reminderMinute == reminderMinute)&&(identical(other.reminderTimezone, reminderTimezone) || other.reminderTimezone == reminderTimezone)&&(identical(other.reminderNextOccurrence, reminderNextOccurrence) || other.reminderNextOccurrence == reminderNextOccurrence)&&const DeepCollectionEquality().equals(other.media, media)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,ethiopianYear,ethiopianMonth,ethiopianDay,gregorianDate,title,content,hasReminder,reminderDateTime,reminderNotified,reminderRepeat,reminderEthiopianMonth,reminderEthiopianDay,reminderHour,reminderMinute,reminderTimezone,reminderNextOccurrence,const DeepCollectionEquality().hash(media),createdAt,updatedAt,deletedAt]);

@override
String toString() {
  return 'CalendarNoteModel(id: $id, userId: $userId, ethiopianYear: $ethiopianYear, ethiopianMonth: $ethiopianMonth, ethiopianDay: $ethiopianDay, gregorianDate: $gregorianDate, title: $title, content: $content, hasReminder: $hasReminder, reminderDateTime: $reminderDateTime, reminderNotified: $reminderNotified, reminderRepeat: $reminderRepeat, reminderEthiopianMonth: $reminderEthiopianMonth, reminderEthiopianDay: $reminderEthiopianDay, reminderHour: $reminderHour, reminderMinute: $reminderMinute, reminderTimezone: $reminderTimezone, reminderNextOccurrence: $reminderNextOccurrence, media: $media, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $CalendarNoteModelCopyWith<$Res>  {
  factory $CalendarNoteModelCopyWith(CalendarNoteModel value, $Res Function(CalendarNoteModel) _then) = _$CalendarNoteModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, int ethiopianYear, int ethiopianMonth, int ethiopianDay, DateTime gregorianDate, String? title, String? content, bool hasReminder, DateTime? reminderDateTime, bool reminderNotified, ReminderRepeat reminderRepeat, int? reminderEthiopianMonth, int? reminderEthiopianDay, int? reminderHour, int? reminderMinute, String reminderTimezone, DateTime? reminderNextOccurrence, List<CalendarNoteMedia> media, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt
});




}
/// @nodoc
class _$CalendarNoteModelCopyWithImpl<$Res>
    implements $CalendarNoteModelCopyWith<$Res> {
  _$CalendarNoteModelCopyWithImpl(this._self, this._then);

  final CalendarNoteModel _self;
  final $Res Function(CalendarNoteModel) _then;

/// Create a copy of CalendarNoteModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? ethiopianYear = null,Object? ethiopianMonth = null,Object? ethiopianDay = null,Object? gregorianDate = null,Object? title = freezed,Object? content = freezed,Object? hasReminder = null,Object? reminderDateTime = freezed,Object? reminderNotified = null,Object? reminderRepeat = null,Object? reminderEthiopianMonth = freezed,Object? reminderEthiopianDay = freezed,Object? reminderHour = freezed,Object? reminderMinute = freezed,Object? reminderTimezone = null,Object? reminderNextOccurrence = freezed,Object? media = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,ethiopianYear: null == ethiopianYear ? _self.ethiopianYear : ethiopianYear // ignore: cast_nullable_to_non_nullable
as int,ethiopianMonth: null == ethiopianMonth ? _self.ethiopianMonth : ethiopianMonth // ignore: cast_nullable_to_non_nullable
as int,ethiopianDay: null == ethiopianDay ? _self.ethiopianDay : ethiopianDay // ignore: cast_nullable_to_non_nullable
as int,gregorianDate: null == gregorianDate ? _self.gregorianDate : gregorianDate // ignore: cast_nullable_to_non_nullable
as DateTime,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,hasReminder: null == hasReminder ? _self.hasReminder : hasReminder // ignore: cast_nullable_to_non_nullable
as bool,reminderDateTime: freezed == reminderDateTime ? _self.reminderDateTime : reminderDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,reminderNotified: null == reminderNotified ? _self.reminderNotified : reminderNotified // ignore: cast_nullable_to_non_nullable
as bool,reminderRepeat: null == reminderRepeat ? _self.reminderRepeat : reminderRepeat // ignore: cast_nullable_to_non_nullable
as ReminderRepeat,reminderEthiopianMonth: freezed == reminderEthiopianMonth ? _self.reminderEthiopianMonth : reminderEthiopianMonth // ignore: cast_nullable_to_non_nullable
as int?,reminderEthiopianDay: freezed == reminderEthiopianDay ? _self.reminderEthiopianDay : reminderEthiopianDay // ignore: cast_nullable_to_non_nullable
as int?,reminderHour: freezed == reminderHour ? _self.reminderHour : reminderHour // ignore: cast_nullable_to_non_nullable
as int?,reminderMinute: freezed == reminderMinute ? _self.reminderMinute : reminderMinute // ignore: cast_nullable_to_non_nullable
as int?,reminderTimezone: null == reminderTimezone ? _self.reminderTimezone : reminderTimezone // ignore: cast_nullable_to_non_nullable
as String,reminderNextOccurrence: freezed == reminderNextOccurrence ? _self.reminderNextOccurrence : reminderNextOccurrence // ignore: cast_nullable_to_non_nullable
as DateTime?,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<CalendarNoteMedia>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarNoteModel].
extension CalendarNoteModelPatterns on CalendarNoteModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarNoteModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarNoteModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarNoteModel value)  $default,){
final _that = this;
switch (_that) {
case _CalendarNoteModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarNoteModel value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarNoteModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  int ethiopianYear,  int ethiopianMonth,  int ethiopianDay,  DateTime gregorianDate,  String? title,  String? content,  bool hasReminder,  DateTime? reminderDateTime,  bool reminderNotified,  ReminderRepeat reminderRepeat,  int? reminderEthiopianMonth,  int? reminderEthiopianDay,  int? reminderHour,  int? reminderMinute,  String reminderTimezone,  DateTime? reminderNextOccurrence,  List<CalendarNoteMedia> media,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarNoteModel() when $default != null:
return $default(_that.id,_that.userId,_that.ethiopianYear,_that.ethiopianMonth,_that.ethiopianDay,_that.gregorianDate,_that.title,_that.content,_that.hasReminder,_that.reminderDateTime,_that.reminderNotified,_that.reminderRepeat,_that.reminderEthiopianMonth,_that.reminderEthiopianDay,_that.reminderHour,_that.reminderMinute,_that.reminderTimezone,_that.reminderNextOccurrence,_that.media,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  int ethiopianYear,  int ethiopianMonth,  int ethiopianDay,  DateTime gregorianDate,  String? title,  String? content,  bool hasReminder,  DateTime? reminderDateTime,  bool reminderNotified,  ReminderRepeat reminderRepeat,  int? reminderEthiopianMonth,  int? reminderEthiopianDay,  int? reminderHour,  int? reminderMinute,  String reminderTimezone,  DateTime? reminderNextOccurrence,  List<CalendarNoteMedia> media,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _CalendarNoteModel():
return $default(_that.id,_that.userId,_that.ethiopianYear,_that.ethiopianMonth,_that.ethiopianDay,_that.gregorianDate,_that.title,_that.content,_that.hasReminder,_that.reminderDateTime,_that.reminderNotified,_that.reminderRepeat,_that.reminderEthiopianMonth,_that.reminderEthiopianDay,_that.reminderHour,_that.reminderMinute,_that.reminderTimezone,_that.reminderNextOccurrence,_that.media,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  int ethiopianYear,  int ethiopianMonth,  int ethiopianDay,  DateTime gregorianDate,  String? title,  String? content,  bool hasReminder,  DateTime? reminderDateTime,  bool reminderNotified,  ReminderRepeat reminderRepeat,  int? reminderEthiopianMonth,  int? reminderEthiopianDay,  int? reminderHour,  int? reminderMinute,  String reminderTimezone,  DateTime? reminderNextOccurrence,  List<CalendarNoteMedia> media,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _CalendarNoteModel() when $default != null:
return $default(_that.id,_that.userId,_that.ethiopianYear,_that.ethiopianMonth,_that.ethiopianDay,_that.gregorianDate,_that.title,_that.content,_that.hasReminder,_that.reminderDateTime,_that.reminderNotified,_that.reminderRepeat,_that.reminderEthiopianMonth,_that.reminderEthiopianDay,_that.reminderHour,_that.reminderMinute,_that.reminderTimezone,_that.reminderNextOccurrence,_that.media,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarNoteModel implements CalendarNoteModel {
  const _CalendarNoteModel({required this.id, required this.userId, required this.ethiopianYear, required this.ethiopianMonth, required this.ethiopianDay, required this.gregorianDate, this.title, this.content, this.hasReminder = false, this.reminderDateTime, this.reminderNotified = false, this.reminderRepeat = ReminderRepeat.none, this.reminderEthiopianMonth, this.reminderEthiopianDay, this.reminderHour, this.reminderMinute, this.reminderTimezone = 'Africa/Addis_Ababa', this.reminderNextOccurrence, final  List<CalendarNoteMedia> media = const [], required this.createdAt, required this.updatedAt, this.deletedAt}): _media = media;
  factory _CalendarNoteModel.fromJson(Map<String, dynamic> json) => _$CalendarNoteModelFromJson(json);

@override final  String id;
@override final  String userId;
@override final  int ethiopianYear;
@override final  int ethiopianMonth;
@override final  int ethiopianDay;
@override final  DateTime gregorianDate;
@override final  String? title;
@override final  String? content;
@override@JsonKey() final  bool hasReminder;
@override final  DateTime? reminderDateTime;
@override@JsonKey() final  bool reminderNotified;
@override@JsonKey() final  ReminderRepeat reminderRepeat;
@override final  int? reminderEthiopianMonth;
@override final  int? reminderEthiopianDay;
@override final  int? reminderHour;
@override final  int? reminderMinute;
@override@JsonKey() final  String reminderTimezone;
@override final  DateTime? reminderNextOccurrence;
 final  List<CalendarNoteMedia> _media;
@override@JsonKey() List<CalendarNoteMedia> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;

/// Create a copy of CalendarNoteModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarNoteModelCopyWith<_CalendarNoteModel> get copyWith => __$CalendarNoteModelCopyWithImpl<_CalendarNoteModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarNoteModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarNoteModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.ethiopianYear, ethiopianYear) || other.ethiopianYear == ethiopianYear)&&(identical(other.ethiopianMonth, ethiopianMonth) || other.ethiopianMonth == ethiopianMonth)&&(identical(other.ethiopianDay, ethiopianDay) || other.ethiopianDay == ethiopianDay)&&(identical(other.gregorianDate, gregorianDate) || other.gregorianDate == gregorianDate)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.hasReminder, hasReminder) || other.hasReminder == hasReminder)&&(identical(other.reminderDateTime, reminderDateTime) || other.reminderDateTime == reminderDateTime)&&(identical(other.reminderNotified, reminderNotified) || other.reminderNotified == reminderNotified)&&(identical(other.reminderRepeat, reminderRepeat) || other.reminderRepeat == reminderRepeat)&&(identical(other.reminderEthiopianMonth, reminderEthiopianMonth) || other.reminderEthiopianMonth == reminderEthiopianMonth)&&(identical(other.reminderEthiopianDay, reminderEthiopianDay) || other.reminderEthiopianDay == reminderEthiopianDay)&&(identical(other.reminderHour, reminderHour) || other.reminderHour == reminderHour)&&(identical(other.reminderMinute, reminderMinute) || other.reminderMinute == reminderMinute)&&(identical(other.reminderTimezone, reminderTimezone) || other.reminderTimezone == reminderTimezone)&&(identical(other.reminderNextOccurrence, reminderNextOccurrence) || other.reminderNextOccurrence == reminderNextOccurrence)&&const DeepCollectionEquality().equals(other._media, _media)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,ethiopianYear,ethiopianMonth,ethiopianDay,gregorianDate,title,content,hasReminder,reminderDateTime,reminderNotified,reminderRepeat,reminderEthiopianMonth,reminderEthiopianDay,reminderHour,reminderMinute,reminderTimezone,reminderNextOccurrence,const DeepCollectionEquality().hash(_media),createdAt,updatedAt,deletedAt]);

@override
String toString() {
  return 'CalendarNoteModel(id: $id, userId: $userId, ethiopianYear: $ethiopianYear, ethiopianMonth: $ethiopianMonth, ethiopianDay: $ethiopianDay, gregorianDate: $gregorianDate, title: $title, content: $content, hasReminder: $hasReminder, reminderDateTime: $reminderDateTime, reminderNotified: $reminderNotified, reminderRepeat: $reminderRepeat, reminderEthiopianMonth: $reminderEthiopianMonth, reminderEthiopianDay: $reminderEthiopianDay, reminderHour: $reminderHour, reminderMinute: $reminderMinute, reminderTimezone: $reminderTimezone, reminderNextOccurrence: $reminderNextOccurrence, media: $media, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$CalendarNoteModelCopyWith<$Res> implements $CalendarNoteModelCopyWith<$Res> {
  factory _$CalendarNoteModelCopyWith(_CalendarNoteModel value, $Res Function(_CalendarNoteModel) _then) = __$CalendarNoteModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, int ethiopianYear, int ethiopianMonth, int ethiopianDay, DateTime gregorianDate, String? title, String? content, bool hasReminder, DateTime? reminderDateTime, bool reminderNotified, ReminderRepeat reminderRepeat, int? reminderEthiopianMonth, int? reminderEthiopianDay, int? reminderHour, int? reminderMinute, String reminderTimezone, DateTime? reminderNextOccurrence, List<CalendarNoteMedia> media, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt
});




}
/// @nodoc
class __$CalendarNoteModelCopyWithImpl<$Res>
    implements _$CalendarNoteModelCopyWith<$Res> {
  __$CalendarNoteModelCopyWithImpl(this._self, this._then);

  final _CalendarNoteModel _self;
  final $Res Function(_CalendarNoteModel) _then;

/// Create a copy of CalendarNoteModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? ethiopianYear = null,Object? ethiopianMonth = null,Object? ethiopianDay = null,Object? gregorianDate = null,Object? title = freezed,Object? content = freezed,Object? hasReminder = null,Object? reminderDateTime = freezed,Object? reminderNotified = null,Object? reminderRepeat = null,Object? reminderEthiopianMonth = freezed,Object? reminderEthiopianDay = freezed,Object? reminderHour = freezed,Object? reminderMinute = freezed,Object? reminderTimezone = null,Object? reminderNextOccurrence = freezed,Object? media = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(_CalendarNoteModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,ethiopianYear: null == ethiopianYear ? _self.ethiopianYear : ethiopianYear // ignore: cast_nullable_to_non_nullable
as int,ethiopianMonth: null == ethiopianMonth ? _self.ethiopianMonth : ethiopianMonth // ignore: cast_nullable_to_non_nullable
as int,ethiopianDay: null == ethiopianDay ? _self.ethiopianDay : ethiopianDay // ignore: cast_nullable_to_non_nullable
as int,gregorianDate: null == gregorianDate ? _self.gregorianDate : gregorianDate // ignore: cast_nullable_to_non_nullable
as DateTime,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,hasReminder: null == hasReminder ? _self.hasReminder : hasReminder // ignore: cast_nullable_to_non_nullable
as bool,reminderDateTime: freezed == reminderDateTime ? _self.reminderDateTime : reminderDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,reminderNotified: null == reminderNotified ? _self.reminderNotified : reminderNotified // ignore: cast_nullable_to_non_nullable
as bool,reminderRepeat: null == reminderRepeat ? _self.reminderRepeat : reminderRepeat // ignore: cast_nullable_to_non_nullable
as ReminderRepeat,reminderEthiopianMonth: freezed == reminderEthiopianMonth ? _self.reminderEthiopianMonth : reminderEthiopianMonth // ignore: cast_nullable_to_non_nullable
as int?,reminderEthiopianDay: freezed == reminderEthiopianDay ? _self.reminderEthiopianDay : reminderEthiopianDay // ignore: cast_nullable_to_non_nullable
as int?,reminderHour: freezed == reminderHour ? _self.reminderHour : reminderHour // ignore: cast_nullable_to_non_nullable
as int?,reminderMinute: freezed == reminderMinute ? _self.reminderMinute : reminderMinute // ignore: cast_nullable_to_non_nullable
as int?,reminderTimezone: null == reminderTimezone ? _self.reminderTimezone : reminderTimezone // ignore: cast_nullable_to_non_nullable
as String,reminderNextOccurrence: freezed == reminderNextOccurrence ? _self.reminderNextOccurrence : reminderNextOccurrence // ignore: cast_nullable_to_non_nullable
as DateTime?,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<CalendarNoteMedia>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CalendarNoteMedia {

 String get id; String get noteId; String get fileId; int get order; String? get caption; Map<String, dynamic>? get file; DateTime get createdAt;
/// Create a copy of CalendarNoteMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarNoteMediaCopyWith<CalendarNoteMedia> get copyWith => _$CalendarNoteMediaCopyWithImpl<CalendarNoteMedia>(this as CalendarNoteMedia, _$identity);

  /// Serializes this CalendarNoteMedia to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarNoteMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.noteId, noteId) || other.noteId == noteId)&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.order, order) || other.order == order)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other.file, file)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,noteId,fileId,order,caption,const DeepCollectionEquality().hash(file),createdAt);

@override
String toString() {
  return 'CalendarNoteMedia(id: $id, noteId: $noteId, fileId: $fileId, order: $order, caption: $caption, file: $file, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CalendarNoteMediaCopyWith<$Res>  {
  factory $CalendarNoteMediaCopyWith(CalendarNoteMedia value, $Res Function(CalendarNoteMedia) _then) = _$CalendarNoteMediaCopyWithImpl;
@useResult
$Res call({
 String id, String noteId, String fileId, int order, String? caption, Map<String, dynamic>? file, DateTime createdAt
});




}
/// @nodoc
class _$CalendarNoteMediaCopyWithImpl<$Res>
    implements $CalendarNoteMediaCopyWith<$Res> {
  _$CalendarNoteMediaCopyWithImpl(this._self, this._then);

  final CalendarNoteMedia _self;
  final $Res Function(CalendarNoteMedia) _then;

/// Create a copy of CalendarNoteMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? noteId = null,Object? fileId = null,Object? order = null,Object? caption = freezed,Object? file = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,noteId: null == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as String,fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarNoteMedia].
extension CalendarNoteMediaPatterns on CalendarNoteMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarNoteMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarNoteMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarNoteMedia value)  $default,){
final _that = this;
switch (_that) {
case _CalendarNoteMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarNoteMedia value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarNoteMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String noteId,  String fileId,  int order,  String? caption,  Map<String, dynamic>? file,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarNoteMedia() when $default != null:
return $default(_that.id,_that.noteId,_that.fileId,_that.order,_that.caption,_that.file,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String noteId,  String fileId,  int order,  String? caption,  Map<String, dynamic>? file,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _CalendarNoteMedia():
return $default(_that.id,_that.noteId,_that.fileId,_that.order,_that.caption,_that.file,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String noteId,  String fileId,  int order,  String? caption,  Map<String, dynamic>? file,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CalendarNoteMedia() when $default != null:
return $default(_that.id,_that.noteId,_that.fileId,_that.order,_that.caption,_that.file,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarNoteMedia implements CalendarNoteMedia {
  const _CalendarNoteMedia({required this.id, required this.noteId, required this.fileId, required this.order, this.caption, final  Map<String, dynamic>? file, required this.createdAt}): _file = file;
  factory _CalendarNoteMedia.fromJson(Map<String, dynamic> json) => _$CalendarNoteMediaFromJson(json);

@override final  String id;
@override final  String noteId;
@override final  String fileId;
@override final  int order;
@override final  String? caption;
 final  Map<String, dynamic>? _file;
@override Map<String, dynamic>? get file {
  final value = _file;
  if (value == null) return null;
  if (_file is EqualUnmodifiableMapView) return _file;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime createdAt;

/// Create a copy of CalendarNoteMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarNoteMediaCopyWith<_CalendarNoteMedia> get copyWith => __$CalendarNoteMediaCopyWithImpl<_CalendarNoteMedia>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarNoteMediaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarNoteMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.noteId, noteId) || other.noteId == noteId)&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.order, order) || other.order == order)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other._file, _file)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,noteId,fileId,order,caption,const DeepCollectionEquality().hash(_file),createdAt);

@override
String toString() {
  return 'CalendarNoteMedia(id: $id, noteId: $noteId, fileId: $fileId, order: $order, caption: $caption, file: $file, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CalendarNoteMediaCopyWith<$Res> implements $CalendarNoteMediaCopyWith<$Res> {
  factory _$CalendarNoteMediaCopyWith(_CalendarNoteMedia value, $Res Function(_CalendarNoteMedia) _then) = __$CalendarNoteMediaCopyWithImpl;
@override @useResult
$Res call({
 String id, String noteId, String fileId, int order, String? caption, Map<String, dynamic>? file, DateTime createdAt
});




}
/// @nodoc
class __$CalendarNoteMediaCopyWithImpl<$Res>
    implements _$CalendarNoteMediaCopyWith<$Res> {
  __$CalendarNoteMediaCopyWithImpl(this._self, this._then);

  final _CalendarNoteMedia _self;
  final $Res Function(_CalendarNoteMedia) _then;

/// Create a copy of CalendarNoteMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? noteId = null,Object? fileId = null,Object? order = null,Object? caption = freezed,Object? file = freezed,Object? createdAt = null,}) {
  return _then(_CalendarNoteMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,noteId: null == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as String,fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,file: freezed == file ? _self._file : file // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CreateCalendarNoteDto {

 int get ethiopianYear; int get ethiopianMonth; int get ethiopianDay; String get gregorianDate; String? get title; String? get content; bool get hasReminder; String? get reminderDateTime; ReminderRepeat get reminderRepeat; int? get reminderEthiopianMonth; int? get reminderEthiopianDay; int? get reminderHour; int? get reminderMinute; String get reminderTimezone;
/// Create a copy of CreateCalendarNoteDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateCalendarNoteDtoCopyWith<CreateCalendarNoteDto> get copyWith => _$CreateCalendarNoteDtoCopyWithImpl<CreateCalendarNoteDto>(this as CreateCalendarNoteDto, _$identity);

  /// Serializes this CreateCalendarNoteDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateCalendarNoteDto&&(identical(other.ethiopianYear, ethiopianYear) || other.ethiopianYear == ethiopianYear)&&(identical(other.ethiopianMonth, ethiopianMonth) || other.ethiopianMonth == ethiopianMonth)&&(identical(other.ethiopianDay, ethiopianDay) || other.ethiopianDay == ethiopianDay)&&(identical(other.gregorianDate, gregorianDate) || other.gregorianDate == gregorianDate)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.hasReminder, hasReminder) || other.hasReminder == hasReminder)&&(identical(other.reminderDateTime, reminderDateTime) || other.reminderDateTime == reminderDateTime)&&(identical(other.reminderRepeat, reminderRepeat) || other.reminderRepeat == reminderRepeat)&&(identical(other.reminderEthiopianMonth, reminderEthiopianMonth) || other.reminderEthiopianMonth == reminderEthiopianMonth)&&(identical(other.reminderEthiopianDay, reminderEthiopianDay) || other.reminderEthiopianDay == reminderEthiopianDay)&&(identical(other.reminderHour, reminderHour) || other.reminderHour == reminderHour)&&(identical(other.reminderMinute, reminderMinute) || other.reminderMinute == reminderMinute)&&(identical(other.reminderTimezone, reminderTimezone) || other.reminderTimezone == reminderTimezone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ethiopianYear,ethiopianMonth,ethiopianDay,gregorianDate,title,content,hasReminder,reminderDateTime,reminderRepeat,reminderEthiopianMonth,reminderEthiopianDay,reminderHour,reminderMinute,reminderTimezone);

@override
String toString() {
  return 'CreateCalendarNoteDto(ethiopianYear: $ethiopianYear, ethiopianMonth: $ethiopianMonth, ethiopianDay: $ethiopianDay, gregorianDate: $gregorianDate, title: $title, content: $content, hasReminder: $hasReminder, reminderDateTime: $reminderDateTime, reminderRepeat: $reminderRepeat, reminderEthiopianMonth: $reminderEthiopianMonth, reminderEthiopianDay: $reminderEthiopianDay, reminderHour: $reminderHour, reminderMinute: $reminderMinute, reminderTimezone: $reminderTimezone)';
}


}

/// @nodoc
abstract mixin class $CreateCalendarNoteDtoCopyWith<$Res>  {
  factory $CreateCalendarNoteDtoCopyWith(CreateCalendarNoteDto value, $Res Function(CreateCalendarNoteDto) _then) = _$CreateCalendarNoteDtoCopyWithImpl;
@useResult
$Res call({
 int ethiopianYear, int ethiopianMonth, int ethiopianDay, String gregorianDate, String? title, String? content, bool hasReminder, String? reminderDateTime, ReminderRepeat reminderRepeat, int? reminderEthiopianMonth, int? reminderEthiopianDay, int? reminderHour, int? reminderMinute, String reminderTimezone
});




}
/// @nodoc
class _$CreateCalendarNoteDtoCopyWithImpl<$Res>
    implements $CreateCalendarNoteDtoCopyWith<$Res> {
  _$CreateCalendarNoteDtoCopyWithImpl(this._self, this._then);

  final CreateCalendarNoteDto _self;
  final $Res Function(CreateCalendarNoteDto) _then;

/// Create a copy of CreateCalendarNoteDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ethiopianYear = null,Object? ethiopianMonth = null,Object? ethiopianDay = null,Object? gregorianDate = null,Object? title = freezed,Object? content = freezed,Object? hasReminder = null,Object? reminderDateTime = freezed,Object? reminderRepeat = null,Object? reminderEthiopianMonth = freezed,Object? reminderEthiopianDay = freezed,Object? reminderHour = freezed,Object? reminderMinute = freezed,Object? reminderTimezone = null,}) {
  return _then(_self.copyWith(
ethiopianYear: null == ethiopianYear ? _self.ethiopianYear : ethiopianYear // ignore: cast_nullable_to_non_nullable
as int,ethiopianMonth: null == ethiopianMonth ? _self.ethiopianMonth : ethiopianMonth // ignore: cast_nullable_to_non_nullable
as int,ethiopianDay: null == ethiopianDay ? _self.ethiopianDay : ethiopianDay // ignore: cast_nullable_to_non_nullable
as int,gregorianDate: null == gregorianDate ? _self.gregorianDate : gregorianDate // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,hasReminder: null == hasReminder ? _self.hasReminder : hasReminder // ignore: cast_nullable_to_non_nullable
as bool,reminderDateTime: freezed == reminderDateTime ? _self.reminderDateTime : reminderDateTime // ignore: cast_nullable_to_non_nullable
as String?,reminderRepeat: null == reminderRepeat ? _self.reminderRepeat : reminderRepeat // ignore: cast_nullable_to_non_nullable
as ReminderRepeat,reminderEthiopianMonth: freezed == reminderEthiopianMonth ? _self.reminderEthiopianMonth : reminderEthiopianMonth // ignore: cast_nullable_to_non_nullable
as int?,reminderEthiopianDay: freezed == reminderEthiopianDay ? _self.reminderEthiopianDay : reminderEthiopianDay // ignore: cast_nullable_to_non_nullable
as int?,reminderHour: freezed == reminderHour ? _self.reminderHour : reminderHour // ignore: cast_nullable_to_non_nullable
as int?,reminderMinute: freezed == reminderMinute ? _self.reminderMinute : reminderMinute // ignore: cast_nullable_to_non_nullable
as int?,reminderTimezone: null == reminderTimezone ? _self.reminderTimezone : reminderTimezone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateCalendarNoteDto].
extension CreateCalendarNoteDtoPatterns on CreateCalendarNoteDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateCalendarNoteDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateCalendarNoteDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateCalendarNoteDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateCalendarNoteDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateCalendarNoteDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateCalendarNoteDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int ethiopianYear,  int ethiopianMonth,  int ethiopianDay,  String gregorianDate,  String? title,  String? content,  bool hasReminder,  String? reminderDateTime,  ReminderRepeat reminderRepeat,  int? reminderEthiopianMonth,  int? reminderEthiopianDay,  int? reminderHour,  int? reminderMinute,  String reminderTimezone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateCalendarNoteDto() when $default != null:
return $default(_that.ethiopianYear,_that.ethiopianMonth,_that.ethiopianDay,_that.gregorianDate,_that.title,_that.content,_that.hasReminder,_that.reminderDateTime,_that.reminderRepeat,_that.reminderEthiopianMonth,_that.reminderEthiopianDay,_that.reminderHour,_that.reminderMinute,_that.reminderTimezone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int ethiopianYear,  int ethiopianMonth,  int ethiopianDay,  String gregorianDate,  String? title,  String? content,  bool hasReminder,  String? reminderDateTime,  ReminderRepeat reminderRepeat,  int? reminderEthiopianMonth,  int? reminderEthiopianDay,  int? reminderHour,  int? reminderMinute,  String reminderTimezone)  $default,) {final _that = this;
switch (_that) {
case _CreateCalendarNoteDto():
return $default(_that.ethiopianYear,_that.ethiopianMonth,_that.ethiopianDay,_that.gregorianDate,_that.title,_that.content,_that.hasReminder,_that.reminderDateTime,_that.reminderRepeat,_that.reminderEthiopianMonth,_that.reminderEthiopianDay,_that.reminderHour,_that.reminderMinute,_that.reminderTimezone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int ethiopianYear,  int ethiopianMonth,  int ethiopianDay,  String gregorianDate,  String? title,  String? content,  bool hasReminder,  String? reminderDateTime,  ReminderRepeat reminderRepeat,  int? reminderEthiopianMonth,  int? reminderEthiopianDay,  int? reminderHour,  int? reminderMinute,  String reminderTimezone)?  $default,) {final _that = this;
switch (_that) {
case _CreateCalendarNoteDto() when $default != null:
return $default(_that.ethiopianYear,_that.ethiopianMonth,_that.ethiopianDay,_that.gregorianDate,_that.title,_that.content,_that.hasReminder,_that.reminderDateTime,_that.reminderRepeat,_that.reminderEthiopianMonth,_that.reminderEthiopianDay,_that.reminderHour,_that.reminderMinute,_that.reminderTimezone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateCalendarNoteDto extends CreateCalendarNoteDto {
  const _CreateCalendarNoteDto({required this.ethiopianYear, required this.ethiopianMonth, required this.ethiopianDay, required this.gregorianDate, this.title, this.content, this.hasReminder = false, this.reminderDateTime, this.reminderRepeat = ReminderRepeat.none, this.reminderEthiopianMonth, this.reminderEthiopianDay, this.reminderHour, this.reminderMinute, this.reminderTimezone = 'Africa/Addis_Ababa'}): super._();
  factory _CreateCalendarNoteDto.fromJson(Map<String, dynamic> json) => _$CreateCalendarNoteDtoFromJson(json);

@override final  int ethiopianYear;
@override final  int ethiopianMonth;
@override final  int ethiopianDay;
@override final  String gregorianDate;
@override final  String? title;
@override final  String? content;
@override@JsonKey() final  bool hasReminder;
@override final  String? reminderDateTime;
@override@JsonKey() final  ReminderRepeat reminderRepeat;
@override final  int? reminderEthiopianMonth;
@override final  int? reminderEthiopianDay;
@override final  int? reminderHour;
@override final  int? reminderMinute;
@override@JsonKey() final  String reminderTimezone;

/// Create a copy of CreateCalendarNoteDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateCalendarNoteDtoCopyWith<_CreateCalendarNoteDto> get copyWith => __$CreateCalendarNoteDtoCopyWithImpl<_CreateCalendarNoteDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateCalendarNoteDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateCalendarNoteDto&&(identical(other.ethiopianYear, ethiopianYear) || other.ethiopianYear == ethiopianYear)&&(identical(other.ethiopianMonth, ethiopianMonth) || other.ethiopianMonth == ethiopianMonth)&&(identical(other.ethiopianDay, ethiopianDay) || other.ethiopianDay == ethiopianDay)&&(identical(other.gregorianDate, gregorianDate) || other.gregorianDate == gregorianDate)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.hasReminder, hasReminder) || other.hasReminder == hasReminder)&&(identical(other.reminderDateTime, reminderDateTime) || other.reminderDateTime == reminderDateTime)&&(identical(other.reminderRepeat, reminderRepeat) || other.reminderRepeat == reminderRepeat)&&(identical(other.reminderEthiopianMonth, reminderEthiopianMonth) || other.reminderEthiopianMonth == reminderEthiopianMonth)&&(identical(other.reminderEthiopianDay, reminderEthiopianDay) || other.reminderEthiopianDay == reminderEthiopianDay)&&(identical(other.reminderHour, reminderHour) || other.reminderHour == reminderHour)&&(identical(other.reminderMinute, reminderMinute) || other.reminderMinute == reminderMinute)&&(identical(other.reminderTimezone, reminderTimezone) || other.reminderTimezone == reminderTimezone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ethiopianYear,ethiopianMonth,ethiopianDay,gregorianDate,title,content,hasReminder,reminderDateTime,reminderRepeat,reminderEthiopianMonth,reminderEthiopianDay,reminderHour,reminderMinute,reminderTimezone);

@override
String toString() {
  return 'CreateCalendarNoteDto(ethiopianYear: $ethiopianYear, ethiopianMonth: $ethiopianMonth, ethiopianDay: $ethiopianDay, gregorianDate: $gregorianDate, title: $title, content: $content, hasReminder: $hasReminder, reminderDateTime: $reminderDateTime, reminderRepeat: $reminderRepeat, reminderEthiopianMonth: $reminderEthiopianMonth, reminderEthiopianDay: $reminderEthiopianDay, reminderHour: $reminderHour, reminderMinute: $reminderMinute, reminderTimezone: $reminderTimezone)';
}


}

/// @nodoc
abstract mixin class _$CreateCalendarNoteDtoCopyWith<$Res> implements $CreateCalendarNoteDtoCopyWith<$Res> {
  factory _$CreateCalendarNoteDtoCopyWith(_CreateCalendarNoteDto value, $Res Function(_CreateCalendarNoteDto) _then) = __$CreateCalendarNoteDtoCopyWithImpl;
@override @useResult
$Res call({
 int ethiopianYear, int ethiopianMonth, int ethiopianDay, String gregorianDate, String? title, String? content, bool hasReminder, String? reminderDateTime, ReminderRepeat reminderRepeat, int? reminderEthiopianMonth, int? reminderEthiopianDay, int? reminderHour, int? reminderMinute, String reminderTimezone
});




}
/// @nodoc
class __$CreateCalendarNoteDtoCopyWithImpl<$Res>
    implements _$CreateCalendarNoteDtoCopyWith<$Res> {
  __$CreateCalendarNoteDtoCopyWithImpl(this._self, this._then);

  final _CreateCalendarNoteDto _self;
  final $Res Function(_CreateCalendarNoteDto) _then;

/// Create a copy of CreateCalendarNoteDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ethiopianYear = null,Object? ethiopianMonth = null,Object? ethiopianDay = null,Object? gregorianDate = null,Object? title = freezed,Object? content = freezed,Object? hasReminder = null,Object? reminderDateTime = freezed,Object? reminderRepeat = null,Object? reminderEthiopianMonth = freezed,Object? reminderEthiopianDay = freezed,Object? reminderHour = freezed,Object? reminderMinute = freezed,Object? reminderTimezone = null,}) {
  return _then(_CreateCalendarNoteDto(
ethiopianYear: null == ethiopianYear ? _self.ethiopianYear : ethiopianYear // ignore: cast_nullable_to_non_nullable
as int,ethiopianMonth: null == ethiopianMonth ? _self.ethiopianMonth : ethiopianMonth // ignore: cast_nullable_to_non_nullable
as int,ethiopianDay: null == ethiopianDay ? _self.ethiopianDay : ethiopianDay // ignore: cast_nullable_to_non_nullable
as int,gregorianDate: null == gregorianDate ? _self.gregorianDate : gregorianDate // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,hasReminder: null == hasReminder ? _self.hasReminder : hasReminder // ignore: cast_nullable_to_non_nullable
as bool,reminderDateTime: freezed == reminderDateTime ? _self.reminderDateTime : reminderDateTime // ignore: cast_nullable_to_non_nullable
as String?,reminderRepeat: null == reminderRepeat ? _self.reminderRepeat : reminderRepeat // ignore: cast_nullable_to_non_nullable
as ReminderRepeat,reminderEthiopianMonth: freezed == reminderEthiopianMonth ? _self.reminderEthiopianMonth : reminderEthiopianMonth // ignore: cast_nullable_to_non_nullable
as int?,reminderEthiopianDay: freezed == reminderEthiopianDay ? _self.reminderEthiopianDay : reminderEthiopianDay // ignore: cast_nullable_to_non_nullable
as int?,reminderHour: freezed == reminderHour ? _self.reminderHour : reminderHour // ignore: cast_nullable_to_non_nullable
as int?,reminderMinute: freezed == reminderMinute ? _self.reminderMinute : reminderMinute // ignore: cast_nullable_to_non_nullable
as int?,reminderTimezone: null == reminderTimezone ? _self.reminderTimezone : reminderTimezone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$UpdateCalendarNoteDto {

 int? get ethiopianYear; int? get ethiopianMonth; int? get ethiopianDay; String? get gregorianDate; String? get title; String? get content; bool? get hasReminder; String? get reminderDateTime; ReminderRepeat? get reminderRepeat; int? get reminderEthiopianMonth; int? get reminderEthiopianDay; int? get reminderHour; int? get reminderMinute; String? get reminderTimezone;
/// Create a copy of UpdateCalendarNoteDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateCalendarNoteDtoCopyWith<UpdateCalendarNoteDto> get copyWith => _$UpdateCalendarNoteDtoCopyWithImpl<UpdateCalendarNoteDto>(this as UpdateCalendarNoteDto, _$identity);

  /// Serializes this UpdateCalendarNoteDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateCalendarNoteDto&&(identical(other.ethiopianYear, ethiopianYear) || other.ethiopianYear == ethiopianYear)&&(identical(other.ethiopianMonth, ethiopianMonth) || other.ethiopianMonth == ethiopianMonth)&&(identical(other.ethiopianDay, ethiopianDay) || other.ethiopianDay == ethiopianDay)&&(identical(other.gregorianDate, gregorianDate) || other.gregorianDate == gregorianDate)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.hasReminder, hasReminder) || other.hasReminder == hasReminder)&&(identical(other.reminderDateTime, reminderDateTime) || other.reminderDateTime == reminderDateTime)&&(identical(other.reminderRepeat, reminderRepeat) || other.reminderRepeat == reminderRepeat)&&(identical(other.reminderEthiopianMonth, reminderEthiopianMonth) || other.reminderEthiopianMonth == reminderEthiopianMonth)&&(identical(other.reminderEthiopianDay, reminderEthiopianDay) || other.reminderEthiopianDay == reminderEthiopianDay)&&(identical(other.reminderHour, reminderHour) || other.reminderHour == reminderHour)&&(identical(other.reminderMinute, reminderMinute) || other.reminderMinute == reminderMinute)&&(identical(other.reminderTimezone, reminderTimezone) || other.reminderTimezone == reminderTimezone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ethiopianYear,ethiopianMonth,ethiopianDay,gregorianDate,title,content,hasReminder,reminderDateTime,reminderRepeat,reminderEthiopianMonth,reminderEthiopianDay,reminderHour,reminderMinute,reminderTimezone);

@override
String toString() {
  return 'UpdateCalendarNoteDto(ethiopianYear: $ethiopianYear, ethiopianMonth: $ethiopianMonth, ethiopianDay: $ethiopianDay, gregorianDate: $gregorianDate, title: $title, content: $content, hasReminder: $hasReminder, reminderDateTime: $reminderDateTime, reminderRepeat: $reminderRepeat, reminderEthiopianMonth: $reminderEthiopianMonth, reminderEthiopianDay: $reminderEthiopianDay, reminderHour: $reminderHour, reminderMinute: $reminderMinute, reminderTimezone: $reminderTimezone)';
}


}

/// @nodoc
abstract mixin class $UpdateCalendarNoteDtoCopyWith<$Res>  {
  factory $UpdateCalendarNoteDtoCopyWith(UpdateCalendarNoteDto value, $Res Function(UpdateCalendarNoteDto) _then) = _$UpdateCalendarNoteDtoCopyWithImpl;
@useResult
$Res call({
 int? ethiopianYear, int? ethiopianMonth, int? ethiopianDay, String? gregorianDate, String? title, String? content, bool? hasReminder, String? reminderDateTime, ReminderRepeat? reminderRepeat, int? reminderEthiopianMonth, int? reminderEthiopianDay, int? reminderHour, int? reminderMinute, String? reminderTimezone
});




}
/// @nodoc
class _$UpdateCalendarNoteDtoCopyWithImpl<$Res>
    implements $UpdateCalendarNoteDtoCopyWith<$Res> {
  _$UpdateCalendarNoteDtoCopyWithImpl(this._self, this._then);

  final UpdateCalendarNoteDto _self;
  final $Res Function(UpdateCalendarNoteDto) _then;

/// Create a copy of UpdateCalendarNoteDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ethiopianYear = freezed,Object? ethiopianMonth = freezed,Object? ethiopianDay = freezed,Object? gregorianDate = freezed,Object? title = freezed,Object? content = freezed,Object? hasReminder = freezed,Object? reminderDateTime = freezed,Object? reminderRepeat = freezed,Object? reminderEthiopianMonth = freezed,Object? reminderEthiopianDay = freezed,Object? reminderHour = freezed,Object? reminderMinute = freezed,Object? reminderTimezone = freezed,}) {
  return _then(_self.copyWith(
ethiopianYear: freezed == ethiopianYear ? _self.ethiopianYear : ethiopianYear // ignore: cast_nullable_to_non_nullable
as int?,ethiopianMonth: freezed == ethiopianMonth ? _self.ethiopianMonth : ethiopianMonth // ignore: cast_nullable_to_non_nullable
as int?,ethiopianDay: freezed == ethiopianDay ? _self.ethiopianDay : ethiopianDay // ignore: cast_nullable_to_non_nullable
as int?,gregorianDate: freezed == gregorianDate ? _self.gregorianDate : gregorianDate // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,hasReminder: freezed == hasReminder ? _self.hasReminder : hasReminder // ignore: cast_nullable_to_non_nullable
as bool?,reminderDateTime: freezed == reminderDateTime ? _self.reminderDateTime : reminderDateTime // ignore: cast_nullable_to_non_nullable
as String?,reminderRepeat: freezed == reminderRepeat ? _self.reminderRepeat : reminderRepeat // ignore: cast_nullable_to_non_nullable
as ReminderRepeat?,reminderEthiopianMonth: freezed == reminderEthiopianMonth ? _self.reminderEthiopianMonth : reminderEthiopianMonth // ignore: cast_nullable_to_non_nullable
as int?,reminderEthiopianDay: freezed == reminderEthiopianDay ? _self.reminderEthiopianDay : reminderEthiopianDay // ignore: cast_nullable_to_non_nullable
as int?,reminderHour: freezed == reminderHour ? _self.reminderHour : reminderHour // ignore: cast_nullable_to_non_nullable
as int?,reminderMinute: freezed == reminderMinute ? _self.reminderMinute : reminderMinute // ignore: cast_nullable_to_non_nullable
as int?,reminderTimezone: freezed == reminderTimezone ? _self.reminderTimezone : reminderTimezone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateCalendarNoteDto].
extension UpdateCalendarNoteDtoPatterns on UpdateCalendarNoteDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateCalendarNoteDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateCalendarNoteDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateCalendarNoteDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateCalendarNoteDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateCalendarNoteDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateCalendarNoteDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? ethiopianYear,  int? ethiopianMonth,  int? ethiopianDay,  String? gregorianDate,  String? title,  String? content,  bool? hasReminder,  String? reminderDateTime,  ReminderRepeat? reminderRepeat,  int? reminderEthiopianMonth,  int? reminderEthiopianDay,  int? reminderHour,  int? reminderMinute,  String? reminderTimezone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateCalendarNoteDto() when $default != null:
return $default(_that.ethiopianYear,_that.ethiopianMonth,_that.ethiopianDay,_that.gregorianDate,_that.title,_that.content,_that.hasReminder,_that.reminderDateTime,_that.reminderRepeat,_that.reminderEthiopianMonth,_that.reminderEthiopianDay,_that.reminderHour,_that.reminderMinute,_that.reminderTimezone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? ethiopianYear,  int? ethiopianMonth,  int? ethiopianDay,  String? gregorianDate,  String? title,  String? content,  bool? hasReminder,  String? reminderDateTime,  ReminderRepeat? reminderRepeat,  int? reminderEthiopianMonth,  int? reminderEthiopianDay,  int? reminderHour,  int? reminderMinute,  String? reminderTimezone)  $default,) {final _that = this;
switch (_that) {
case _UpdateCalendarNoteDto():
return $default(_that.ethiopianYear,_that.ethiopianMonth,_that.ethiopianDay,_that.gregorianDate,_that.title,_that.content,_that.hasReminder,_that.reminderDateTime,_that.reminderRepeat,_that.reminderEthiopianMonth,_that.reminderEthiopianDay,_that.reminderHour,_that.reminderMinute,_that.reminderTimezone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? ethiopianYear,  int? ethiopianMonth,  int? ethiopianDay,  String? gregorianDate,  String? title,  String? content,  bool? hasReminder,  String? reminderDateTime,  ReminderRepeat? reminderRepeat,  int? reminderEthiopianMonth,  int? reminderEthiopianDay,  int? reminderHour,  int? reminderMinute,  String? reminderTimezone)?  $default,) {final _that = this;
switch (_that) {
case _UpdateCalendarNoteDto() when $default != null:
return $default(_that.ethiopianYear,_that.ethiopianMonth,_that.ethiopianDay,_that.gregorianDate,_that.title,_that.content,_that.hasReminder,_that.reminderDateTime,_that.reminderRepeat,_that.reminderEthiopianMonth,_that.reminderEthiopianDay,_that.reminderHour,_that.reminderMinute,_that.reminderTimezone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateCalendarNoteDto extends UpdateCalendarNoteDto {
  const _UpdateCalendarNoteDto({this.ethiopianYear, this.ethiopianMonth, this.ethiopianDay, this.gregorianDate, this.title, this.content, this.hasReminder, this.reminderDateTime, this.reminderRepeat, this.reminderEthiopianMonth, this.reminderEthiopianDay, this.reminderHour, this.reminderMinute, this.reminderTimezone}): super._();
  factory _UpdateCalendarNoteDto.fromJson(Map<String, dynamic> json) => _$UpdateCalendarNoteDtoFromJson(json);

@override final  int? ethiopianYear;
@override final  int? ethiopianMonth;
@override final  int? ethiopianDay;
@override final  String? gregorianDate;
@override final  String? title;
@override final  String? content;
@override final  bool? hasReminder;
@override final  String? reminderDateTime;
@override final  ReminderRepeat? reminderRepeat;
@override final  int? reminderEthiopianMonth;
@override final  int? reminderEthiopianDay;
@override final  int? reminderHour;
@override final  int? reminderMinute;
@override final  String? reminderTimezone;

/// Create a copy of UpdateCalendarNoteDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateCalendarNoteDtoCopyWith<_UpdateCalendarNoteDto> get copyWith => __$UpdateCalendarNoteDtoCopyWithImpl<_UpdateCalendarNoteDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateCalendarNoteDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateCalendarNoteDto&&(identical(other.ethiopianYear, ethiopianYear) || other.ethiopianYear == ethiopianYear)&&(identical(other.ethiopianMonth, ethiopianMonth) || other.ethiopianMonth == ethiopianMonth)&&(identical(other.ethiopianDay, ethiopianDay) || other.ethiopianDay == ethiopianDay)&&(identical(other.gregorianDate, gregorianDate) || other.gregorianDate == gregorianDate)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.hasReminder, hasReminder) || other.hasReminder == hasReminder)&&(identical(other.reminderDateTime, reminderDateTime) || other.reminderDateTime == reminderDateTime)&&(identical(other.reminderRepeat, reminderRepeat) || other.reminderRepeat == reminderRepeat)&&(identical(other.reminderEthiopianMonth, reminderEthiopianMonth) || other.reminderEthiopianMonth == reminderEthiopianMonth)&&(identical(other.reminderEthiopianDay, reminderEthiopianDay) || other.reminderEthiopianDay == reminderEthiopianDay)&&(identical(other.reminderHour, reminderHour) || other.reminderHour == reminderHour)&&(identical(other.reminderMinute, reminderMinute) || other.reminderMinute == reminderMinute)&&(identical(other.reminderTimezone, reminderTimezone) || other.reminderTimezone == reminderTimezone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ethiopianYear,ethiopianMonth,ethiopianDay,gregorianDate,title,content,hasReminder,reminderDateTime,reminderRepeat,reminderEthiopianMonth,reminderEthiopianDay,reminderHour,reminderMinute,reminderTimezone);

@override
String toString() {
  return 'UpdateCalendarNoteDto(ethiopianYear: $ethiopianYear, ethiopianMonth: $ethiopianMonth, ethiopianDay: $ethiopianDay, gregorianDate: $gregorianDate, title: $title, content: $content, hasReminder: $hasReminder, reminderDateTime: $reminderDateTime, reminderRepeat: $reminderRepeat, reminderEthiopianMonth: $reminderEthiopianMonth, reminderEthiopianDay: $reminderEthiopianDay, reminderHour: $reminderHour, reminderMinute: $reminderMinute, reminderTimezone: $reminderTimezone)';
}


}

/// @nodoc
abstract mixin class _$UpdateCalendarNoteDtoCopyWith<$Res> implements $UpdateCalendarNoteDtoCopyWith<$Res> {
  factory _$UpdateCalendarNoteDtoCopyWith(_UpdateCalendarNoteDto value, $Res Function(_UpdateCalendarNoteDto) _then) = __$UpdateCalendarNoteDtoCopyWithImpl;
@override @useResult
$Res call({
 int? ethiopianYear, int? ethiopianMonth, int? ethiopianDay, String? gregorianDate, String? title, String? content, bool? hasReminder, String? reminderDateTime, ReminderRepeat? reminderRepeat, int? reminderEthiopianMonth, int? reminderEthiopianDay, int? reminderHour, int? reminderMinute, String? reminderTimezone
});




}
/// @nodoc
class __$UpdateCalendarNoteDtoCopyWithImpl<$Res>
    implements _$UpdateCalendarNoteDtoCopyWith<$Res> {
  __$UpdateCalendarNoteDtoCopyWithImpl(this._self, this._then);

  final _UpdateCalendarNoteDto _self;
  final $Res Function(_UpdateCalendarNoteDto) _then;

/// Create a copy of UpdateCalendarNoteDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ethiopianYear = freezed,Object? ethiopianMonth = freezed,Object? ethiopianDay = freezed,Object? gregorianDate = freezed,Object? title = freezed,Object? content = freezed,Object? hasReminder = freezed,Object? reminderDateTime = freezed,Object? reminderRepeat = freezed,Object? reminderEthiopianMonth = freezed,Object? reminderEthiopianDay = freezed,Object? reminderHour = freezed,Object? reminderMinute = freezed,Object? reminderTimezone = freezed,}) {
  return _then(_UpdateCalendarNoteDto(
ethiopianYear: freezed == ethiopianYear ? _self.ethiopianYear : ethiopianYear // ignore: cast_nullable_to_non_nullable
as int?,ethiopianMonth: freezed == ethiopianMonth ? _self.ethiopianMonth : ethiopianMonth // ignore: cast_nullable_to_non_nullable
as int?,ethiopianDay: freezed == ethiopianDay ? _self.ethiopianDay : ethiopianDay // ignore: cast_nullable_to_non_nullable
as int?,gregorianDate: freezed == gregorianDate ? _self.gregorianDate : gregorianDate // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,hasReminder: freezed == hasReminder ? _self.hasReminder : hasReminder // ignore: cast_nullable_to_non_nullable
as bool?,reminderDateTime: freezed == reminderDateTime ? _self.reminderDateTime : reminderDateTime // ignore: cast_nullable_to_non_nullable
as String?,reminderRepeat: freezed == reminderRepeat ? _self.reminderRepeat : reminderRepeat // ignore: cast_nullable_to_non_nullable
as ReminderRepeat?,reminderEthiopianMonth: freezed == reminderEthiopianMonth ? _self.reminderEthiopianMonth : reminderEthiopianMonth // ignore: cast_nullable_to_non_nullable
as int?,reminderEthiopianDay: freezed == reminderEthiopianDay ? _self.reminderEthiopianDay : reminderEthiopianDay // ignore: cast_nullable_to_non_nullable
as int?,reminderHour: freezed == reminderHour ? _self.reminderHour : reminderHour // ignore: cast_nullable_to_non_nullable
as int?,reminderMinute: freezed == reminderMinute ? _self.reminderMinute : reminderMinute // ignore: cast_nullable_to_non_nullable
as int?,reminderTimezone: freezed == reminderTimezone ? _self.reminderTimezone : reminderTimezone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
