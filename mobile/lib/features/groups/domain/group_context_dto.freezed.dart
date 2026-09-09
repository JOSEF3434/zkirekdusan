// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_context_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoChannelSummaryDto {

 String get id; String get name; String get slug; String get handle; String? get description; String get status;/// Backend GroupRole string, controls who may upload
 String get uploadPermission; int get subscribersCount; int get videosCount;
/// Create a copy of VideoChannelSummaryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoChannelSummaryDtoCopyWith<VideoChannelSummaryDto> get copyWith => _$VideoChannelSummaryDtoCopyWithImpl<VideoChannelSummaryDto>(this as VideoChannelSummaryDto, _$identity);

  /// Serializes this VideoChannelSummaryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoChannelSummaryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.uploadPermission, uploadPermission) || other.uploadPermission == uploadPermission)&&(identical(other.subscribersCount, subscribersCount) || other.subscribersCount == subscribersCount)&&(identical(other.videosCount, videosCount) || other.videosCount == videosCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,handle,description,status,uploadPermission,subscribersCount,videosCount);

@override
String toString() {
  return 'VideoChannelSummaryDto(id: $id, name: $name, slug: $slug, handle: $handle, description: $description, status: $status, uploadPermission: $uploadPermission, subscribersCount: $subscribersCount, videosCount: $videosCount)';
}


}

/// @nodoc
abstract mixin class $VideoChannelSummaryDtoCopyWith<$Res>  {
  factory $VideoChannelSummaryDtoCopyWith(VideoChannelSummaryDto value, $Res Function(VideoChannelSummaryDto) _then) = _$VideoChannelSummaryDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug, String handle, String? description, String status, String uploadPermission, int subscribersCount, int videosCount
});




}
/// @nodoc
class _$VideoChannelSummaryDtoCopyWithImpl<$Res>
    implements $VideoChannelSummaryDtoCopyWith<$Res> {
  _$VideoChannelSummaryDtoCopyWithImpl(this._self, this._then);

  final VideoChannelSummaryDto _self;
  final $Res Function(VideoChannelSummaryDto) _then;

/// Create a copy of VideoChannelSummaryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? handle = null,Object? description = freezed,Object? status = null,Object? uploadPermission = null,Object? subscribersCount = null,Object? videosCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,uploadPermission: null == uploadPermission ? _self.uploadPermission : uploadPermission // ignore: cast_nullable_to_non_nullable
as String,subscribersCount: null == subscribersCount ? _self.subscribersCount : subscribersCount // ignore: cast_nullable_to_non_nullable
as int,videosCount: null == videosCount ? _self.videosCount : videosCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoChannelSummaryDto].
extension VideoChannelSummaryDtoPatterns on VideoChannelSummaryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoChannelSummaryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoChannelSummaryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoChannelSummaryDto value)  $default,){
final _that = this;
switch (_that) {
case _VideoChannelSummaryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoChannelSummaryDto value)?  $default,){
final _that = this;
switch (_that) {
case _VideoChannelSummaryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String handle,  String? description,  String status,  String uploadPermission,  int subscribersCount,  int videosCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoChannelSummaryDto() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.handle,_that.description,_that.status,_that.uploadPermission,_that.subscribersCount,_that.videosCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String handle,  String? description,  String status,  String uploadPermission,  int subscribersCount,  int videosCount)  $default,) {final _that = this;
switch (_that) {
case _VideoChannelSummaryDto():
return $default(_that.id,_that.name,_that.slug,_that.handle,_that.description,_that.status,_that.uploadPermission,_that.subscribersCount,_that.videosCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String slug,  String handle,  String? description,  String status,  String uploadPermission,  int subscribersCount,  int videosCount)?  $default,) {final _that = this;
switch (_that) {
case _VideoChannelSummaryDto() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.handle,_that.description,_that.status,_that.uploadPermission,_that.subscribersCount,_that.videosCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoChannelSummaryDto implements VideoChannelSummaryDto {
  const _VideoChannelSummaryDto({required this.id, required this.name, required this.slug, required this.handle, this.description, required this.status, required this.uploadPermission, required this.subscribersCount, required this.videosCount});
  factory _VideoChannelSummaryDto.fromJson(Map<String, dynamic> json) => _$VideoChannelSummaryDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String slug;
@override final  String handle;
@override final  String? description;
@override final  String status;
/// Backend GroupRole string, controls who may upload
@override final  String uploadPermission;
@override final  int subscribersCount;
@override final  int videosCount;

/// Create a copy of VideoChannelSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoChannelSummaryDtoCopyWith<_VideoChannelSummaryDto> get copyWith => __$VideoChannelSummaryDtoCopyWithImpl<_VideoChannelSummaryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoChannelSummaryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoChannelSummaryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.uploadPermission, uploadPermission) || other.uploadPermission == uploadPermission)&&(identical(other.subscribersCount, subscribersCount) || other.subscribersCount == subscribersCount)&&(identical(other.videosCount, videosCount) || other.videosCount == videosCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,handle,description,status,uploadPermission,subscribersCount,videosCount);

@override
String toString() {
  return 'VideoChannelSummaryDto(id: $id, name: $name, slug: $slug, handle: $handle, description: $description, status: $status, uploadPermission: $uploadPermission, subscribersCount: $subscribersCount, videosCount: $videosCount)';
}


}

/// @nodoc
abstract mixin class _$VideoChannelSummaryDtoCopyWith<$Res> implements $VideoChannelSummaryDtoCopyWith<$Res> {
  factory _$VideoChannelSummaryDtoCopyWith(_VideoChannelSummaryDto value, $Res Function(_VideoChannelSummaryDto) _then) = __$VideoChannelSummaryDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug, String handle, String? description, String status, String uploadPermission, int subscribersCount, int videosCount
});




}
/// @nodoc
class __$VideoChannelSummaryDtoCopyWithImpl<$Res>
    implements _$VideoChannelSummaryDtoCopyWith<$Res> {
  __$VideoChannelSummaryDtoCopyWithImpl(this._self, this._then);

  final _VideoChannelSummaryDto _self;
  final $Res Function(_VideoChannelSummaryDto) _then;

/// Create a copy of VideoChannelSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? handle = null,Object? description = freezed,Object? status = null,Object? uploadPermission = null,Object? subscribersCount = null,Object? videosCount = null,}) {
  return _then(_VideoChannelSummaryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,uploadPermission: null == uploadPermission ? _self.uploadPermission : uploadPermission // ignore: cast_nullable_to_non_nullable
as String,subscribersCount: null == subscribersCount ? _self.subscribersCount : subscribersCount // ignore: cast_nullable_to_non_nullable
as int,videosCount: null == videosCount ? _self.videosCount : videosCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GroupCapabilities {

 bool get canViewGroup; bool get canUploadVideo; bool get canManageVideos; bool get canCreatePlaylist; bool get canManagePlaylists; bool get canViewMembers; bool get canManageMembers; bool get canEditGroup; bool get canUpdateGroup; bool get canDeleteGroup; bool get canManagePermissions; bool get canManageChannels; bool get canManageSettings; bool get canModerateChat; bool get canStartLive; bool get canApproveGroup; bool get canArchiveGroup;
/// Create a copy of GroupCapabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupCapabilitiesCopyWith<GroupCapabilities> get copyWith => _$GroupCapabilitiesCopyWithImpl<GroupCapabilities>(this as GroupCapabilities, _$identity);

  /// Serializes this GroupCapabilities to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupCapabilities&&(identical(other.canViewGroup, canViewGroup) || other.canViewGroup == canViewGroup)&&(identical(other.canUploadVideo, canUploadVideo) || other.canUploadVideo == canUploadVideo)&&(identical(other.canManageVideos, canManageVideos) || other.canManageVideos == canManageVideos)&&(identical(other.canCreatePlaylist, canCreatePlaylist) || other.canCreatePlaylist == canCreatePlaylist)&&(identical(other.canManagePlaylists, canManagePlaylists) || other.canManagePlaylists == canManagePlaylists)&&(identical(other.canViewMembers, canViewMembers) || other.canViewMembers == canViewMembers)&&(identical(other.canManageMembers, canManageMembers) || other.canManageMembers == canManageMembers)&&(identical(other.canEditGroup, canEditGroup) || other.canEditGroup == canEditGroup)&&(identical(other.canUpdateGroup, canUpdateGroup) || other.canUpdateGroup == canUpdateGroup)&&(identical(other.canDeleteGroup, canDeleteGroup) || other.canDeleteGroup == canDeleteGroup)&&(identical(other.canManagePermissions, canManagePermissions) || other.canManagePermissions == canManagePermissions)&&(identical(other.canManageChannels, canManageChannels) || other.canManageChannels == canManageChannels)&&(identical(other.canManageSettings, canManageSettings) || other.canManageSettings == canManageSettings)&&(identical(other.canModerateChat, canModerateChat) || other.canModerateChat == canModerateChat)&&(identical(other.canStartLive, canStartLive) || other.canStartLive == canStartLive)&&(identical(other.canApproveGroup, canApproveGroup) || other.canApproveGroup == canApproveGroup)&&(identical(other.canArchiveGroup, canArchiveGroup) || other.canArchiveGroup == canArchiveGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,canViewGroup,canUploadVideo,canManageVideos,canCreatePlaylist,canManagePlaylists,canViewMembers,canManageMembers,canEditGroup,canUpdateGroup,canDeleteGroup,canManagePermissions,canManageChannels,canManageSettings,canModerateChat,canStartLive,canApproveGroup,canArchiveGroup);

@override
String toString() {
  return 'GroupCapabilities(canViewGroup: $canViewGroup, canUploadVideo: $canUploadVideo, canManageVideos: $canManageVideos, canCreatePlaylist: $canCreatePlaylist, canManagePlaylists: $canManagePlaylists, canViewMembers: $canViewMembers, canManageMembers: $canManageMembers, canEditGroup: $canEditGroup, canUpdateGroup: $canUpdateGroup, canDeleteGroup: $canDeleteGroup, canManagePermissions: $canManagePermissions, canManageChannels: $canManageChannels, canManageSettings: $canManageSettings, canModerateChat: $canModerateChat, canStartLive: $canStartLive, canApproveGroup: $canApproveGroup, canArchiveGroup: $canArchiveGroup)';
}


}

/// @nodoc
abstract mixin class $GroupCapabilitiesCopyWith<$Res>  {
  factory $GroupCapabilitiesCopyWith(GroupCapabilities value, $Res Function(GroupCapabilities) _then) = _$GroupCapabilitiesCopyWithImpl;
@useResult
$Res call({
 bool canViewGroup, bool canUploadVideo, bool canManageVideos, bool canCreatePlaylist, bool canManagePlaylists, bool canViewMembers, bool canManageMembers, bool canEditGroup, bool canUpdateGroup, bool canDeleteGroup, bool canManagePermissions, bool canManageChannels, bool canManageSettings, bool canModerateChat, bool canStartLive, bool canApproveGroup, bool canArchiveGroup
});




}
/// @nodoc
class _$GroupCapabilitiesCopyWithImpl<$Res>
    implements $GroupCapabilitiesCopyWith<$Res> {
  _$GroupCapabilitiesCopyWithImpl(this._self, this._then);

  final GroupCapabilities _self;
  final $Res Function(GroupCapabilities) _then;

/// Create a copy of GroupCapabilities
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canViewGroup = null,Object? canUploadVideo = null,Object? canManageVideos = null,Object? canCreatePlaylist = null,Object? canManagePlaylists = null,Object? canViewMembers = null,Object? canManageMembers = null,Object? canEditGroup = null,Object? canUpdateGroup = null,Object? canDeleteGroup = null,Object? canManagePermissions = null,Object? canManageChannels = null,Object? canManageSettings = null,Object? canModerateChat = null,Object? canStartLive = null,Object? canApproveGroup = null,Object? canArchiveGroup = null,}) {
  return _then(_self.copyWith(
canViewGroup: null == canViewGroup ? _self.canViewGroup : canViewGroup // ignore: cast_nullable_to_non_nullable
as bool,canUploadVideo: null == canUploadVideo ? _self.canUploadVideo : canUploadVideo // ignore: cast_nullable_to_non_nullable
as bool,canManageVideos: null == canManageVideos ? _self.canManageVideos : canManageVideos // ignore: cast_nullable_to_non_nullable
as bool,canCreatePlaylist: null == canCreatePlaylist ? _self.canCreatePlaylist : canCreatePlaylist // ignore: cast_nullable_to_non_nullable
as bool,canManagePlaylists: null == canManagePlaylists ? _self.canManagePlaylists : canManagePlaylists // ignore: cast_nullable_to_non_nullable
as bool,canViewMembers: null == canViewMembers ? _self.canViewMembers : canViewMembers // ignore: cast_nullable_to_non_nullable
as bool,canManageMembers: null == canManageMembers ? _self.canManageMembers : canManageMembers // ignore: cast_nullable_to_non_nullable
as bool,canEditGroup: null == canEditGroup ? _self.canEditGroup : canEditGroup // ignore: cast_nullable_to_non_nullable
as bool,canUpdateGroup: null == canUpdateGroup ? _self.canUpdateGroup : canUpdateGroup // ignore: cast_nullable_to_non_nullable
as bool,canDeleteGroup: null == canDeleteGroup ? _self.canDeleteGroup : canDeleteGroup // ignore: cast_nullable_to_non_nullable
as bool,canManagePermissions: null == canManagePermissions ? _self.canManagePermissions : canManagePermissions // ignore: cast_nullable_to_non_nullable
as bool,canManageChannels: null == canManageChannels ? _self.canManageChannels : canManageChannels // ignore: cast_nullable_to_non_nullable
as bool,canManageSettings: null == canManageSettings ? _self.canManageSettings : canManageSettings // ignore: cast_nullable_to_non_nullable
as bool,canModerateChat: null == canModerateChat ? _self.canModerateChat : canModerateChat // ignore: cast_nullable_to_non_nullable
as bool,canStartLive: null == canStartLive ? _self.canStartLive : canStartLive // ignore: cast_nullable_to_non_nullable
as bool,canApproveGroup: null == canApproveGroup ? _self.canApproveGroup : canApproveGroup // ignore: cast_nullable_to_non_nullable
as bool,canArchiveGroup: null == canArchiveGroup ? _self.canArchiveGroup : canArchiveGroup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupCapabilities].
extension GroupCapabilitiesPatterns on GroupCapabilities {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupCapabilities value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupCapabilities() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupCapabilities value)  $default,){
final _that = this;
switch (_that) {
case _GroupCapabilities():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupCapabilities value)?  $default,){
final _that = this;
switch (_that) {
case _GroupCapabilities() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool canViewGroup,  bool canUploadVideo,  bool canManageVideos,  bool canCreatePlaylist,  bool canManagePlaylists,  bool canViewMembers,  bool canManageMembers,  bool canEditGroup,  bool canUpdateGroup,  bool canDeleteGroup,  bool canManagePermissions,  bool canManageChannels,  bool canManageSettings,  bool canModerateChat,  bool canStartLive,  bool canApproveGroup,  bool canArchiveGroup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupCapabilities() when $default != null:
return $default(_that.canViewGroup,_that.canUploadVideo,_that.canManageVideos,_that.canCreatePlaylist,_that.canManagePlaylists,_that.canViewMembers,_that.canManageMembers,_that.canEditGroup,_that.canUpdateGroup,_that.canDeleteGroup,_that.canManagePermissions,_that.canManageChannels,_that.canManageSettings,_that.canModerateChat,_that.canStartLive,_that.canApproveGroup,_that.canArchiveGroup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool canViewGroup,  bool canUploadVideo,  bool canManageVideos,  bool canCreatePlaylist,  bool canManagePlaylists,  bool canViewMembers,  bool canManageMembers,  bool canEditGroup,  bool canUpdateGroup,  bool canDeleteGroup,  bool canManagePermissions,  bool canManageChannels,  bool canManageSettings,  bool canModerateChat,  bool canStartLive,  bool canApproveGroup,  bool canArchiveGroup)  $default,) {final _that = this;
switch (_that) {
case _GroupCapabilities():
return $default(_that.canViewGroup,_that.canUploadVideo,_that.canManageVideos,_that.canCreatePlaylist,_that.canManagePlaylists,_that.canViewMembers,_that.canManageMembers,_that.canEditGroup,_that.canUpdateGroup,_that.canDeleteGroup,_that.canManagePermissions,_that.canManageChannels,_that.canManageSettings,_that.canModerateChat,_that.canStartLive,_that.canApproveGroup,_that.canArchiveGroup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool canViewGroup,  bool canUploadVideo,  bool canManageVideos,  bool canCreatePlaylist,  bool canManagePlaylists,  bool canViewMembers,  bool canManageMembers,  bool canEditGroup,  bool canUpdateGroup,  bool canDeleteGroup,  bool canManagePermissions,  bool canManageChannels,  bool canManageSettings,  bool canModerateChat,  bool canStartLive,  bool canApproveGroup,  bool canArchiveGroup)?  $default,) {final _that = this;
switch (_that) {
case _GroupCapabilities() when $default != null:
return $default(_that.canViewGroup,_that.canUploadVideo,_that.canManageVideos,_that.canCreatePlaylist,_that.canManagePlaylists,_that.canViewMembers,_that.canManageMembers,_that.canEditGroup,_that.canUpdateGroup,_that.canDeleteGroup,_that.canManagePermissions,_that.canManageChannels,_that.canManageSettings,_that.canModerateChat,_that.canStartLive,_that.canApproveGroup,_that.canArchiveGroup);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupCapabilities implements GroupCapabilities {
  const _GroupCapabilities({this.canViewGroup = false, this.canUploadVideo = false, this.canManageVideos = false, this.canCreatePlaylist = false, this.canManagePlaylists = false, this.canViewMembers = false, this.canManageMembers = false, this.canEditGroup = false, this.canUpdateGroup = false, this.canDeleteGroup = false, this.canManagePermissions = false, this.canManageChannels = false, this.canManageSettings = false, this.canModerateChat = false, this.canStartLive = false, this.canApproveGroup = false, this.canArchiveGroup = false});
  factory _GroupCapabilities.fromJson(Map<String, dynamic> json) => _$GroupCapabilitiesFromJson(json);

@override@JsonKey() final  bool canViewGroup;
@override@JsonKey() final  bool canUploadVideo;
@override@JsonKey() final  bool canManageVideos;
@override@JsonKey() final  bool canCreatePlaylist;
@override@JsonKey() final  bool canManagePlaylists;
@override@JsonKey() final  bool canViewMembers;
@override@JsonKey() final  bool canManageMembers;
@override@JsonKey() final  bool canEditGroup;
@override@JsonKey() final  bool canUpdateGroup;
@override@JsonKey() final  bool canDeleteGroup;
@override@JsonKey() final  bool canManagePermissions;
@override@JsonKey() final  bool canManageChannels;
@override@JsonKey() final  bool canManageSettings;
@override@JsonKey() final  bool canModerateChat;
@override@JsonKey() final  bool canStartLive;
@override@JsonKey() final  bool canApproveGroup;
@override@JsonKey() final  bool canArchiveGroup;

/// Create a copy of GroupCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupCapabilitiesCopyWith<_GroupCapabilities> get copyWith => __$GroupCapabilitiesCopyWithImpl<_GroupCapabilities>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupCapabilitiesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupCapabilities&&(identical(other.canViewGroup, canViewGroup) || other.canViewGroup == canViewGroup)&&(identical(other.canUploadVideo, canUploadVideo) || other.canUploadVideo == canUploadVideo)&&(identical(other.canManageVideos, canManageVideos) || other.canManageVideos == canManageVideos)&&(identical(other.canCreatePlaylist, canCreatePlaylist) || other.canCreatePlaylist == canCreatePlaylist)&&(identical(other.canManagePlaylists, canManagePlaylists) || other.canManagePlaylists == canManagePlaylists)&&(identical(other.canViewMembers, canViewMembers) || other.canViewMembers == canViewMembers)&&(identical(other.canManageMembers, canManageMembers) || other.canManageMembers == canManageMembers)&&(identical(other.canEditGroup, canEditGroup) || other.canEditGroup == canEditGroup)&&(identical(other.canUpdateGroup, canUpdateGroup) || other.canUpdateGroup == canUpdateGroup)&&(identical(other.canDeleteGroup, canDeleteGroup) || other.canDeleteGroup == canDeleteGroup)&&(identical(other.canManagePermissions, canManagePermissions) || other.canManagePermissions == canManagePermissions)&&(identical(other.canManageChannels, canManageChannels) || other.canManageChannels == canManageChannels)&&(identical(other.canManageSettings, canManageSettings) || other.canManageSettings == canManageSettings)&&(identical(other.canModerateChat, canModerateChat) || other.canModerateChat == canModerateChat)&&(identical(other.canStartLive, canStartLive) || other.canStartLive == canStartLive)&&(identical(other.canApproveGroup, canApproveGroup) || other.canApproveGroup == canApproveGroup)&&(identical(other.canArchiveGroup, canArchiveGroup) || other.canArchiveGroup == canArchiveGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,canViewGroup,canUploadVideo,canManageVideos,canCreatePlaylist,canManagePlaylists,canViewMembers,canManageMembers,canEditGroup,canUpdateGroup,canDeleteGroup,canManagePermissions,canManageChannels,canManageSettings,canModerateChat,canStartLive,canApproveGroup,canArchiveGroup);

@override
String toString() {
  return 'GroupCapabilities(canViewGroup: $canViewGroup, canUploadVideo: $canUploadVideo, canManageVideos: $canManageVideos, canCreatePlaylist: $canCreatePlaylist, canManagePlaylists: $canManagePlaylists, canViewMembers: $canViewMembers, canManageMembers: $canManageMembers, canEditGroup: $canEditGroup, canUpdateGroup: $canUpdateGroup, canDeleteGroup: $canDeleteGroup, canManagePermissions: $canManagePermissions, canManageChannels: $canManageChannels, canManageSettings: $canManageSettings, canModerateChat: $canModerateChat, canStartLive: $canStartLive, canApproveGroup: $canApproveGroup, canArchiveGroup: $canArchiveGroup)';
}


}

/// @nodoc
abstract mixin class _$GroupCapabilitiesCopyWith<$Res> implements $GroupCapabilitiesCopyWith<$Res> {
  factory _$GroupCapabilitiesCopyWith(_GroupCapabilities value, $Res Function(_GroupCapabilities) _then) = __$GroupCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 bool canViewGroup, bool canUploadVideo, bool canManageVideos, bool canCreatePlaylist, bool canManagePlaylists, bool canViewMembers, bool canManageMembers, bool canEditGroup, bool canUpdateGroup, bool canDeleteGroup, bool canManagePermissions, bool canManageChannels, bool canManageSettings, bool canModerateChat, bool canStartLive, bool canApproveGroup, bool canArchiveGroup
});




}
/// @nodoc
class __$GroupCapabilitiesCopyWithImpl<$Res>
    implements _$GroupCapabilitiesCopyWith<$Res> {
  __$GroupCapabilitiesCopyWithImpl(this._self, this._then);

  final _GroupCapabilities _self;
  final $Res Function(_GroupCapabilities) _then;

/// Create a copy of GroupCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canViewGroup = null,Object? canUploadVideo = null,Object? canManageVideos = null,Object? canCreatePlaylist = null,Object? canManagePlaylists = null,Object? canViewMembers = null,Object? canManageMembers = null,Object? canEditGroup = null,Object? canUpdateGroup = null,Object? canDeleteGroup = null,Object? canManagePermissions = null,Object? canManageChannels = null,Object? canManageSettings = null,Object? canModerateChat = null,Object? canStartLive = null,Object? canApproveGroup = null,Object? canArchiveGroup = null,}) {
  return _then(_GroupCapabilities(
canViewGroup: null == canViewGroup ? _self.canViewGroup : canViewGroup // ignore: cast_nullable_to_non_nullable
as bool,canUploadVideo: null == canUploadVideo ? _self.canUploadVideo : canUploadVideo // ignore: cast_nullable_to_non_nullable
as bool,canManageVideos: null == canManageVideos ? _self.canManageVideos : canManageVideos // ignore: cast_nullable_to_non_nullable
as bool,canCreatePlaylist: null == canCreatePlaylist ? _self.canCreatePlaylist : canCreatePlaylist // ignore: cast_nullable_to_non_nullable
as bool,canManagePlaylists: null == canManagePlaylists ? _self.canManagePlaylists : canManagePlaylists // ignore: cast_nullable_to_non_nullable
as bool,canViewMembers: null == canViewMembers ? _self.canViewMembers : canViewMembers // ignore: cast_nullable_to_non_nullable
as bool,canManageMembers: null == canManageMembers ? _self.canManageMembers : canManageMembers // ignore: cast_nullable_to_non_nullable
as bool,canEditGroup: null == canEditGroup ? _self.canEditGroup : canEditGroup // ignore: cast_nullable_to_non_nullable
as bool,canUpdateGroup: null == canUpdateGroup ? _self.canUpdateGroup : canUpdateGroup // ignore: cast_nullable_to_non_nullable
as bool,canDeleteGroup: null == canDeleteGroup ? _self.canDeleteGroup : canDeleteGroup // ignore: cast_nullable_to_non_nullable
as bool,canManagePermissions: null == canManagePermissions ? _self.canManagePermissions : canManagePermissions // ignore: cast_nullable_to_non_nullable
as bool,canManageChannels: null == canManageChannels ? _self.canManageChannels : canManageChannels // ignore: cast_nullable_to_non_nullable
as bool,canManageSettings: null == canManageSettings ? _self.canManageSettings : canManageSettings // ignore: cast_nullable_to_non_nullable
as bool,canModerateChat: null == canModerateChat ? _self.canModerateChat : canModerateChat // ignore: cast_nullable_to_non_nullable
as bool,canStartLive: null == canStartLive ? _self.canStartLive : canStartLive // ignore: cast_nullable_to_non_nullable
as bool,canApproveGroup: null == canApproveGroup ? _self.canApproveGroup : canApproveGroup // ignore: cast_nullable_to_non_nullable
as bool,canArchiveGroup: null == canArchiveGroup ? _self.canArchiveGroup : canArchiveGroup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$GroupContextDto {

// Group identity
 String get id; String get name; String get slug; String? get description; GroupStatus get status; GroupVisibility get visibility; int get membersCount; String? get avatarUrl; String? get coverUrl; String? get website; String? get country; String get createdById; String? get approvedById; DateTime? get approvedAt; DateTime get createdAt;// Caller membership info
/// null = not a member or unauthenticated
 GroupRole? get callerRole; GroupCapabilities get capabilities;// Video channels
 List<VideoChannelSummaryDto> get videoChannels;/// Deterministically resolved primary channel ID.
/// null means the group has no active video channels.
 String? get defaultVideoChannelId;
/// Create a copy of GroupContextDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupContextDtoCopyWith<GroupContextDto> get copyWith => _$GroupContextDtoCopyWithImpl<GroupContextDto>(this as GroupContextDto, _$identity);

  /// Serializes this GroupContextDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupContextDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.membersCount, membersCount) || other.membersCount == membersCount)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.website, website) || other.website == website)&&(identical(other.country, country) || other.country == country)&&(identical(other.createdById, createdById) || other.createdById == createdById)&&(identical(other.approvedById, approvedById) || other.approvedById == approvedById)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.callerRole, callerRole) || other.callerRole == callerRole)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&const DeepCollectionEquality().equals(other.videoChannels, videoChannels)&&(identical(other.defaultVideoChannelId, defaultVideoChannelId) || other.defaultVideoChannelId == defaultVideoChannelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,slug,description,status,visibility,membersCount,avatarUrl,coverUrl,website,country,createdById,approvedById,approvedAt,createdAt,callerRole,capabilities,const DeepCollectionEquality().hash(videoChannels),defaultVideoChannelId]);

@override
String toString() {
  return 'GroupContextDto(id: $id, name: $name, slug: $slug, description: $description, status: $status, visibility: $visibility, membersCount: $membersCount, avatarUrl: $avatarUrl, coverUrl: $coverUrl, website: $website, country: $country, createdById: $createdById, approvedById: $approvedById, approvedAt: $approvedAt, createdAt: $createdAt, callerRole: $callerRole, capabilities: $capabilities, videoChannels: $videoChannels, defaultVideoChannelId: $defaultVideoChannelId)';
}


}

/// @nodoc
abstract mixin class $GroupContextDtoCopyWith<$Res>  {
  factory $GroupContextDtoCopyWith(GroupContextDto value, $Res Function(GroupContextDto) _then) = _$GroupContextDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug, String? description, GroupStatus status, GroupVisibility visibility, int membersCount, String? avatarUrl, String? coverUrl, String? website, String? country, String createdById, String? approvedById, DateTime? approvedAt, DateTime createdAt, GroupRole? callerRole, GroupCapabilities capabilities, List<VideoChannelSummaryDto> videoChannels, String? defaultVideoChannelId
});


$GroupCapabilitiesCopyWith<$Res> get capabilities;

}
/// @nodoc
class _$GroupContextDtoCopyWithImpl<$Res>
    implements $GroupContextDtoCopyWith<$Res> {
  _$GroupContextDtoCopyWithImpl(this._self, this._then);

  final GroupContextDto _self;
  final $Res Function(GroupContextDto) _then;

/// Create a copy of GroupContextDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? description = freezed,Object? status = null,Object? visibility = null,Object? membersCount = null,Object? avatarUrl = freezed,Object? coverUrl = freezed,Object? website = freezed,Object? country = freezed,Object? createdById = null,Object? approvedById = freezed,Object? approvedAt = freezed,Object? createdAt = null,Object? callerRole = freezed,Object? capabilities = null,Object? videoChannels = null,Object? defaultVideoChannelId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GroupStatus,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as GroupVisibility,membersCount: null == membersCount ? _self.membersCount : membersCount // ignore: cast_nullable_to_non_nullable
as int,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,createdById: null == createdById ? _self.createdById : createdById // ignore: cast_nullable_to_non_nullable
as String,approvedById: freezed == approvedById ? _self.approvedById : approvedById // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,callerRole: freezed == callerRole ? _self.callerRole : callerRole // ignore: cast_nullable_to_non_nullable
as GroupRole?,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as GroupCapabilities,videoChannels: null == videoChannels ? _self.videoChannels : videoChannels // ignore: cast_nullable_to_non_nullable
as List<VideoChannelSummaryDto>,defaultVideoChannelId: freezed == defaultVideoChannelId ? _self.defaultVideoChannelId : defaultVideoChannelId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of GroupContextDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupCapabilitiesCopyWith<$Res> get capabilities {
  
  return $GroupCapabilitiesCopyWith<$Res>(_self.capabilities, (value) {
    return _then(_self.copyWith(capabilities: value));
  });
}
}


/// Adds pattern-matching-related methods to [GroupContextDto].
extension GroupContextDtoPatterns on GroupContextDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupContextDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupContextDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupContextDto value)  $default,){
final _that = this;
switch (_that) {
case _GroupContextDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupContextDto value)?  $default,){
final _that = this;
switch (_that) {
case _GroupContextDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String? description,  GroupStatus status,  GroupVisibility visibility,  int membersCount,  String? avatarUrl,  String? coverUrl,  String? website,  String? country,  String createdById,  String? approvedById,  DateTime? approvedAt,  DateTime createdAt,  GroupRole? callerRole,  GroupCapabilities capabilities,  List<VideoChannelSummaryDto> videoChannels,  String? defaultVideoChannelId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupContextDto() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.description,_that.status,_that.visibility,_that.membersCount,_that.avatarUrl,_that.coverUrl,_that.website,_that.country,_that.createdById,_that.approvedById,_that.approvedAt,_that.createdAt,_that.callerRole,_that.capabilities,_that.videoChannels,_that.defaultVideoChannelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String? description,  GroupStatus status,  GroupVisibility visibility,  int membersCount,  String? avatarUrl,  String? coverUrl,  String? website,  String? country,  String createdById,  String? approvedById,  DateTime? approvedAt,  DateTime createdAt,  GroupRole? callerRole,  GroupCapabilities capabilities,  List<VideoChannelSummaryDto> videoChannels,  String? defaultVideoChannelId)  $default,) {final _that = this;
switch (_that) {
case _GroupContextDto():
return $default(_that.id,_that.name,_that.slug,_that.description,_that.status,_that.visibility,_that.membersCount,_that.avatarUrl,_that.coverUrl,_that.website,_that.country,_that.createdById,_that.approvedById,_that.approvedAt,_that.createdAt,_that.callerRole,_that.capabilities,_that.videoChannels,_that.defaultVideoChannelId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String slug,  String? description,  GroupStatus status,  GroupVisibility visibility,  int membersCount,  String? avatarUrl,  String? coverUrl,  String? website,  String? country,  String createdById,  String? approvedById,  DateTime? approvedAt,  DateTime createdAt,  GroupRole? callerRole,  GroupCapabilities capabilities,  List<VideoChannelSummaryDto> videoChannels,  String? defaultVideoChannelId)?  $default,) {final _that = this;
switch (_that) {
case _GroupContextDto() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.description,_that.status,_that.visibility,_that.membersCount,_that.avatarUrl,_that.coverUrl,_that.website,_that.country,_that.createdById,_that.approvedById,_that.approvedAt,_that.createdAt,_that.callerRole,_that.capabilities,_that.videoChannels,_that.defaultVideoChannelId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupContextDto implements GroupContextDto {
  const _GroupContextDto({required this.id, required this.name, required this.slug, this.description, required this.status, required this.visibility, required this.membersCount, this.avatarUrl, this.coverUrl, this.website, this.country, required this.createdById, this.approvedById, this.approvedAt, required this.createdAt, this.callerRole, required this.capabilities, required final  List<VideoChannelSummaryDto> videoChannels, this.defaultVideoChannelId}): _videoChannels = videoChannels;
  factory _GroupContextDto.fromJson(Map<String, dynamic> json) => _$GroupContextDtoFromJson(json);

// Group identity
@override final  String id;
@override final  String name;
@override final  String slug;
@override final  String? description;
@override final  GroupStatus status;
@override final  GroupVisibility visibility;
@override final  int membersCount;
@override final  String? avatarUrl;
@override final  String? coverUrl;
@override final  String? website;
@override final  String? country;
@override final  String createdById;
@override final  String? approvedById;
@override final  DateTime? approvedAt;
@override final  DateTime createdAt;
// Caller membership info
/// null = not a member or unauthenticated
@override final  GroupRole? callerRole;
@override final  GroupCapabilities capabilities;
// Video channels
 final  List<VideoChannelSummaryDto> _videoChannels;
// Video channels
@override List<VideoChannelSummaryDto> get videoChannels {
  if (_videoChannels is EqualUnmodifiableListView) return _videoChannels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videoChannels);
}

/// Deterministically resolved primary channel ID.
/// null means the group has no active video channels.
@override final  String? defaultVideoChannelId;

/// Create a copy of GroupContextDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupContextDtoCopyWith<_GroupContextDto> get copyWith => __$GroupContextDtoCopyWithImpl<_GroupContextDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupContextDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupContextDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.membersCount, membersCount) || other.membersCount == membersCount)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.website, website) || other.website == website)&&(identical(other.country, country) || other.country == country)&&(identical(other.createdById, createdById) || other.createdById == createdById)&&(identical(other.approvedById, approvedById) || other.approvedById == approvedById)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.callerRole, callerRole) || other.callerRole == callerRole)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&const DeepCollectionEquality().equals(other._videoChannels, _videoChannels)&&(identical(other.defaultVideoChannelId, defaultVideoChannelId) || other.defaultVideoChannelId == defaultVideoChannelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,slug,description,status,visibility,membersCount,avatarUrl,coverUrl,website,country,createdById,approvedById,approvedAt,createdAt,callerRole,capabilities,const DeepCollectionEquality().hash(_videoChannels),defaultVideoChannelId]);

@override
String toString() {
  return 'GroupContextDto(id: $id, name: $name, slug: $slug, description: $description, status: $status, visibility: $visibility, membersCount: $membersCount, avatarUrl: $avatarUrl, coverUrl: $coverUrl, website: $website, country: $country, createdById: $createdById, approvedById: $approvedById, approvedAt: $approvedAt, createdAt: $createdAt, callerRole: $callerRole, capabilities: $capabilities, videoChannels: $videoChannels, defaultVideoChannelId: $defaultVideoChannelId)';
}


}

/// @nodoc
abstract mixin class _$GroupContextDtoCopyWith<$Res> implements $GroupContextDtoCopyWith<$Res> {
  factory _$GroupContextDtoCopyWith(_GroupContextDto value, $Res Function(_GroupContextDto) _then) = __$GroupContextDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug, String? description, GroupStatus status, GroupVisibility visibility, int membersCount, String? avatarUrl, String? coverUrl, String? website, String? country, String createdById, String? approvedById, DateTime? approvedAt, DateTime createdAt, GroupRole? callerRole, GroupCapabilities capabilities, List<VideoChannelSummaryDto> videoChannels, String? defaultVideoChannelId
});


@override $GroupCapabilitiesCopyWith<$Res> get capabilities;

}
/// @nodoc
class __$GroupContextDtoCopyWithImpl<$Res>
    implements _$GroupContextDtoCopyWith<$Res> {
  __$GroupContextDtoCopyWithImpl(this._self, this._then);

  final _GroupContextDto _self;
  final $Res Function(_GroupContextDto) _then;

/// Create a copy of GroupContextDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? description = freezed,Object? status = null,Object? visibility = null,Object? membersCount = null,Object? avatarUrl = freezed,Object? coverUrl = freezed,Object? website = freezed,Object? country = freezed,Object? createdById = null,Object? approvedById = freezed,Object? approvedAt = freezed,Object? createdAt = null,Object? callerRole = freezed,Object? capabilities = null,Object? videoChannels = null,Object? defaultVideoChannelId = freezed,}) {
  return _then(_GroupContextDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GroupStatus,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as GroupVisibility,membersCount: null == membersCount ? _self.membersCount : membersCount // ignore: cast_nullable_to_non_nullable
as int,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,createdById: null == createdById ? _self.createdById : createdById // ignore: cast_nullable_to_non_nullable
as String,approvedById: freezed == approvedById ? _self.approvedById : approvedById // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,callerRole: freezed == callerRole ? _self.callerRole : callerRole // ignore: cast_nullable_to_non_nullable
as GroupRole?,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as GroupCapabilities,videoChannels: null == videoChannels ? _self._videoChannels : videoChannels // ignore: cast_nullable_to_non_nullable
as List<VideoChannelSummaryDto>,defaultVideoChannelId: freezed == defaultVideoChannelId ? _self.defaultVideoChannelId : defaultVideoChannelId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of GroupContextDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupCapabilitiesCopyWith<$Res> get capabilities {
  
  return $GroupCapabilitiesCopyWith<$Res>(_self.capabilities, (value) {
    return _then(_self.copyWith(capabilities: value));
  });
}
}

// dart format on
