// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_license.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppLicense {

 bool get isValid; String? get reason; DateTime? get expiresAt; int? get daysRemaining; String? get licenseId;
/// Create a copy of AppLicense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppLicenseCopyWith<AppLicense> get copyWith => _$AppLicenseCopyWithImpl<AppLicense>(this as AppLicense, _$identity);

  /// Serializes this AppLicense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppLicense&&(identical(other.isValid, isValid) || other.isValid == isValid)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.daysRemaining, daysRemaining) || other.daysRemaining == daysRemaining)&&(identical(other.licenseId, licenseId) || other.licenseId == licenseId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isValid,reason,expiresAt,daysRemaining,licenseId);

@override
String toString() {
  return 'AppLicense(isValid: $isValid, reason: $reason, expiresAt: $expiresAt, daysRemaining: $daysRemaining, licenseId: $licenseId)';
}


}

/// @nodoc
abstract mixin class $AppLicenseCopyWith<$Res>  {
  factory $AppLicenseCopyWith(AppLicense value, $Res Function(AppLicense) _then) = _$AppLicenseCopyWithImpl;
@useResult
$Res call({
 bool isValid, String? reason, DateTime? expiresAt, int? daysRemaining, String? licenseId
});




}
/// @nodoc
class _$AppLicenseCopyWithImpl<$Res>
    implements $AppLicenseCopyWith<$Res> {
  _$AppLicenseCopyWithImpl(this._self, this._then);

  final AppLicense _self;
  final $Res Function(AppLicense) _then;

/// Create a copy of AppLicense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isValid = null,Object? reason = freezed,Object? expiresAt = freezed,Object? daysRemaining = freezed,Object? licenseId = freezed,}) {
  return _then(_self.copyWith(
isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,daysRemaining: freezed == daysRemaining ? _self.daysRemaining : daysRemaining // ignore: cast_nullable_to_non_nullable
as int?,licenseId: freezed == licenseId ? _self.licenseId : licenseId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppLicense].
extension AppLicensePatterns on AppLicense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppLicense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppLicense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppLicense value)  $default,){
final _that = this;
switch (_that) {
case _AppLicense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppLicense value)?  $default,){
final _that = this;
switch (_that) {
case _AppLicense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isValid,  String? reason,  DateTime? expiresAt,  int? daysRemaining,  String? licenseId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppLicense() when $default != null:
return $default(_that.isValid,_that.reason,_that.expiresAt,_that.daysRemaining,_that.licenseId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isValid,  String? reason,  DateTime? expiresAt,  int? daysRemaining,  String? licenseId)  $default,) {final _that = this;
switch (_that) {
case _AppLicense():
return $default(_that.isValid,_that.reason,_that.expiresAt,_that.daysRemaining,_that.licenseId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isValid,  String? reason,  DateTime? expiresAt,  int? daysRemaining,  String? licenseId)?  $default,) {final _that = this;
switch (_that) {
case _AppLicense() when $default != null:
return $default(_that.isValid,_that.reason,_that.expiresAt,_that.daysRemaining,_that.licenseId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppLicense implements AppLicense {
  const _AppLicense({this.isValid = false, this.reason, this.expiresAt, this.daysRemaining, this.licenseId});
  factory _AppLicense.fromJson(Map<String, dynamic> json) => _$AppLicenseFromJson(json);

@override@JsonKey() final  bool isValid;
@override final  String? reason;
@override final  DateTime? expiresAt;
@override final  int? daysRemaining;
@override final  String? licenseId;

/// Create a copy of AppLicense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppLicenseCopyWith<_AppLicense> get copyWith => __$AppLicenseCopyWithImpl<_AppLicense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppLicenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppLicense&&(identical(other.isValid, isValid) || other.isValid == isValid)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.daysRemaining, daysRemaining) || other.daysRemaining == daysRemaining)&&(identical(other.licenseId, licenseId) || other.licenseId == licenseId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isValid,reason,expiresAt,daysRemaining,licenseId);

@override
String toString() {
  return 'AppLicense(isValid: $isValid, reason: $reason, expiresAt: $expiresAt, daysRemaining: $daysRemaining, licenseId: $licenseId)';
}


}

/// @nodoc
abstract mixin class _$AppLicenseCopyWith<$Res> implements $AppLicenseCopyWith<$Res> {
  factory _$AppLicenseCopyWith(_AppLicense value, $Res Function(_AppLicense) _then) = __$AppLicenseCopyWithImpl;
@override @useResult
$Res call({
 bool isValid, String? reason, DateTime? expiresAt, int? daysRemaining, String? licenseId
});




}
/// @nodoc
class __$AppLicenseCopyWithImpl<$Res>
    implements _$AppLicenseCopyWith<$Res> {
  __$AppLicenseCopyWithImpl(this._self, this._then);

  final _AppLicense _self;
  final $Res Function(_AppLicense) _then;

/// Create a copy of AppLicense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isValid = null,Object? reason = freezed,Object? expiresAt = freezed,Object? daysRemaining = freezed,Object? licenseId = freezed,}) {
  return _then(_AppLicense(
isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,daysRemaining: freezed == daysRemaining ? _self.daysRemaining : daysRemaining // ignore: cast_nullable_to_non_nullable
as int?,licenseId: freezed == licenseId ? _self.licenseId : licenseId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
