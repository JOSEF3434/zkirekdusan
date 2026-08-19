// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_context_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VideoChannelSummaryDto _$VideoChannelSummaryDtoFromJson(
  Map<String, dynamic> json,
) {
  return _VideoChannelSummaryDto.fromJson(json);
}

/// @nodoc
mixin _$VideoChannelSummaryDto {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Backend GroupRole string, controls who may upload
  String get uploadPermission => throw _privateConstructorUsedError;
  int get subscribersCount => throw _privateConstructorUsedError;
  int get videosCount => throw _privateConstructorUsedError;

  /// Serializes this VideoChannelSummaryDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VideoChannelSummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoChannelSummaryDtoCopyWith<VideoChannelSummaryDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoChannelSummaryDtoCopyWith<$Res> {
  factory $VideoChannelSummaryDtoCopyWith(
    VideoChannelSummaryDto value,
    $Res Function(VideoChannelSummaryDto) then,
  ) = _$VideoChannelSummaryDtoCopyWithImpl<$Res, VideoChannelSummaryDto>;
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String handle,
    String? description,
    String status,
    String uploadPermission,
    int subscribersCount,
    int videosCount,
  });
}

/// @nodoc
class _$VideoChannelSummaryDtoCopyWithImpl<
  $Res,
  $Val extends VideoChannelSummaryDto
>
    implements $VideoChannelSummaryDtoCopyWith<$Res> {
  _$VideoChannelSummaryDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoChannelSummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? handle = null,
    Object? description = freezed,
    Object? status = null,
    Object? uploadPermission = null,
    Object? subscribersCount = null,
    Object? videosCount = null,
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
                      as String,
            uploadPermission: null == uploadPermission
                ? _value.uploadPermission
                : uploadPermission // ignore: cast_nullable_to_non_nullable
                      as String,
            subscribersCount: null == subscribersCount
                ? _value.subscribersCount
                : subscribersCount // ignore: cast_nullable_to_non_nullable
                      as int,
            videosCount: null == videosCount
                ? _value.videosCount
                : videosCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VideoChannelSummaryDtoImplCopyWith<$Res>
    implements $VideoChannelSummaryDtoCopyWith<$Res> {
  factory _$$VideoChannelSummaryDtoImplCopyWith(
    _$VideoChannelSummaryDtoImpl value,
    $Res Function(_$VideoChannelSummaryDtoImpl) then,
  ) = __$$VideoChannelSummaryDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String handle,
    String? description,
    String status,
    String uploadPermission,
    int subscribersCount,
    int videosCount,
  });
}

/// @nodoc
class __$$VideoChannelSummaryDtoImplCopyWithImpl<$Res>
    extends
        _$VideoChannelSummaryDtoCopyWithImpl<$Res, _$VideoChannelSummaryDtoImpl>
    implements _$$VideoChannelSummaryDtoImplCopyWith<$Res> {
  __$$VideoChannelSummaryDtoImplCopyWithImpl(
    _$VideoChannelSummaryDtoImpl _value,
    $Res Function(_$VideoChannelSummaryDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VideoChannelSummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? handle = null,
    Object? description = freezed,
    Object? status = null,
    Object? uploadPermission = null,
    Object? subscribersCount = null,
    Object? videosCount = null,
  }) {
    return _then(
      _$VideoChannelSummaryDtoImpl(
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
                  as String,
        uploadPermission: null == uploadPermission
            ? _value.uploadPermission
            : uploadPermission // ignore: cast_nullable_to_non_nullable
                  as String,
        subscribersCount: null == subscribersCount
            ? _value.subscribersCount
            : subscribersCount // ignore: cast_nullable_to_non_nullable
                  as int,
        videosCount: null == videosCount
            ? _value.videosCount
            : videosCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoChannelSummaryDtoImpl implements _VideoChannelSummaryDto {
  const _$VideoChannelSummaryDtoImpl({
    required this.id,
    required this.name,
    required this.slug,
    required this.handle,
    this.description,
    required this.status,
    required this.uploadPermission,
    required this.subscribersCount,
    required this.videosCount,
  });

  factory _$VideoChannelSummaryDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoChannelSummaryDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String handle;
  @override
  final String? description;
  @override
  final String status;

  /// Backend GroupRole string, controls who may upload
  @override
  final String uploadPermission;
  @override
  final int subscribersCount;
  @override
  final int videosCount;

  @override
  String toString() {
    return 'VideoChannelSummaryDto(id: $id, name: $name, slug: $slug, handle: $handle, description: $description, status: $status, uploadPermission: $uploadPermission, subscribersCount: $subscribersCount, videosCount: $videosCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoChannelSummaryDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.uploadPermission, uploadPermission) ||
                other.uploadPermission == uploadPermission) &&
            (identical(other.subscribersCount, subscribersCount) ||
                other.subscribersCount == subscribersCount) &&
            (identical(other.videosCount, videosCount) ||
                other.videosCount == videosCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    slug,
    handle,
    description,
    status,
    uploadPermission,
    subscribersCount,
    videosCount,
  );

  /// Create a copy of VideoChannelSummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoChannelSummaryDtoImplCopyWith<_$VideoChannelSummaryDtoImpl>
  get copyWith =>
      __$$VideoChannelSummaryDtoImplCopyWithImpl<_$VideoChannelSummaryDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoChannelSummaryDtoImplToJson(this);
  }
}

abstract class _VideoChannelSummaryDto implements VideoChannelSummaryDto {
  const factory _VideoChannelSummaryDto({
    required final String id,
    required final String name,
    required final String slug,
    required final String handle,
    final String? description,
    required final String status,
    required final String uploadPermission,
    required final int subscribersCount,
    required final int videosCount,
  }) = _$VideoChannelSummaryDtoImpl;

  factory _VideoChannelSummaryDto.fromJson(Map<String, dynamic> json) =
      _$VideoChannelSummaryDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get slug;
  @override
  String get handle;
  @override
  String? get description;
  @override
  String get status;

  /// Backend GroupRole string, controls who may upload
  @override
  String get uploadPermission;
  @override
  int get subscribersCount;
  @override
  int get videosCount;

  /// Create a copy of VideoChannelSummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoChannelSummaryDtoImplCopyWith<_$VideoChannelSummaryDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

GroupCapabilities _$GroupCapabilitiesFromJson(Map<String, dynamic> json) {
  return _GroupCapabilities.fromJson(json);
}

/// @nodoc
mixin _$GroupCapabilities {
  bool get canViewGroup => throw _privateConstructorUsedError;
  bool get canUploadVideo => throw _privateConstructorUsedError;
  bool get canManageVideos => throw _privateConstructorUsedError;
  bool get canCreatePlaylist => throw _privateConstructorUsedError;
  bool get canManagePlaylists => throw _privateConstructorUsedError;
  bool get canViewMembers => throw _privateConstructorUsedError;
  bool get canManageMembers => throw _privateConstructorUsedError;
  bool get canEditGroup => throw _privateConstructorUsedError;
  bool get canUpdateGroup => throw _privateConstructorUsedError;
  bool get canDeleteGroup => throw _privateConstructorUsedError;
  bool get canManagePermissions => throw _privateConstructorUsedError;
  bool get canManageChannels => throw _privateConstructorUsedError;
  bool get canManageSettings => throw _privateConstructorUsedError;
  bool get canModerateChat => throw _privateConstructorUsedError;
  bool get canStartLive => throw _privateConstructorUsedError;
  bool get canApproveGroup => throw _privateConstructorUsedError;
  bool get canArchiveGroup => throw _privateConstructorUsedError;

  /// Serializes this GroupCapabilities to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupCapabilitiesCopyWith<GroupCapabilities> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupCapabilitiesCopyWith<$Res> {
  factory $GroupCapabilitiesCopyWith(
    GroupCapabilities value,
    $Res Function(GroupCapabilities) then,
  ) = _$GroupCapabilitiesCopyWithImpl<$Res, GroupCapabilities>;
  @useResult
  $Res call({
    bool canViewGroup,
    bool canUploadVideo,
    bool canManageVideos,
    bool canCreatePlaylist,
    bool canManagePlaylists,
    bool canViewMembers,
    bool canManageMembers,
    bool canEditGroup,
    bool canUpdateGroup,
    bool canDeleteGroup,
    bool canManagePermissions,
    bool canManageChannels,
    bool canManageSettings,
    bool canModerateChat,
    bool canStartLive,
    bool canApproveGroup,
    bool canArchiveGroup,
  });
}

/// @nodoc
class _$GroupCapabilitiesCopyWithImpl<$Res, $Val extends GroupCapabilities>
    implements $GroupCapabilitiesCopyWith<$Res> {
  _$GroupCapabilitiesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? canViewGroup = null,
    Object? canUploadVideo = null,
    Object? canManageVideos = null,
    Object? canCreatePlaylist = null,
    Object? canManagePlaylists = null,
    Object? canViewMembers = null,
    Object? canManageMembers = null,
    Object? canEditGroup = null,
    Object? canUpdateGroup = null,
    Object? canDeleteGroup = null,
    Object? canManagePermissions = null,
    Object? canManageChannels = null,
    Object? canManageSettings = null,
    Object? canModerateChat = null,
    Object? canStartLive = null,
    Object? canApproveGroup = null,
    Object? canArchiveGroup = null,
  }) {
    return _then(
      _value.copyWith(
            canViewGroup: null == canViewGroup
                ? _value.canViewGroup
                : canViewGroup // ignore: cast_nullable_to_non_nullable
                      as bool,
            canUploadVideo: null == canUploadVideo
                ? _value.canUploadVideo
                : canUploadVideo // ignore: cast_nullable_to_non_nullable
                      as bool,
            canManageVideos: null == canManageVideos
                ? _value.canManageVideos
                : canManageVideos // ignore: cast_nullable_to_non_nullable
                      as bool,
            canCreatePlaylist: null == canCreatePlaylist
                ? _value.canCreatePlaylist
                : canCreatePlaylist // ignore: cast_nullable_to_non_nullable
                      as bool,
            canManagePlaylists: null == canManagePlaylists
                ? _value.canManagePlaylists
                : canManagePlaylists // ignore: cast_nullable_to_non_nullable
                      as bool,
            canViewMembers: null == canViewMembers
                ? _value.canViewMembers
                : canViewMembers // ignore: cast_nullable_to_non_nullable
                      as bool,
            canManageMembers: null == canManageMembers
                ? _value.canManageMembers
                : canManageMembers // ignore: cast_nullable_to_non_nullable
                      as bool,
            canEditGroup: null == canEditGroup
                ? _value.canEditGroup
                : canEditGroup // ignore: cast_nullable_to_non_nullable
                      as bool,
            canUpdateGroup: null == canUpdateGroup
                ? _value.canUpdateGroup
                : canUpdateGroup // ignore: cast_nullable_to_non_nullable
                      as bool,
            canDeleteGroup: null == canDeleteGroup
                ? _value.canDeleteGroup
                : canDeleteGroup // ignore: cast_nullable_to_non_nullable
                      as bool,
            canManagePermissions: null == canManagePermissions
                ? _value.canManagePermissions
                : canManagePermissions // ignore: cast_nullable_to_non_nullable
                      as bool,
            canManageChannels: null == canManageChannels
                ? _value.canManageChannels
                : canManageChannels // ignore: cast_nullable_to_non_nullable
                      as bool,
            canManageSettings: null == canManageSettings
                ? _value.canManageSettings
                : canManageSettings // ignore: cast_nullable_to_non_nullable
                      as bool,
            canModerateChat: null == canModerateChat
                ? _value.canModerateChat
                : canModerateChat // ignore: cast_nullable_to_non_nullable
                      as bool,
            canStartLive: null == canStartLive
                ? _value.canStartLive
                : canStartLive // ignore: cast_nullable_to_non_nullable
                      as bool,
            canApproveGroup: null == canApproveGroup
                ? _value.canApproveGroup
                : canApproveGroup // ignore: cast_nullable_to_non_nullable
                      as bool,
            canArchiveGroup: null == canArchiveGroup
                ? _value.canArchiveGroup
                : canArchiveGroup // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GroupCapabilitiesImplCopyWith<$Res>
    implements $GroupCapabilitiesCopyWith<$Res> {
  factory _$$GroupCapabilitiesImplCopyWith(
    _$GroupCapabilitiesImpl value,
    $Res Function(_$GroupCapabilitiesImpl) then,
  ) = __$$GroupCapabilitiesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool canViewGroup,
    bool canUploadVideo,
    bool canManageVideos,
    bool canCreatePlaylist,
    bool canManagePlaylists,
    bool canViewMembers,
    bool canManageMembers,
    bool canEditGroup,
    bool canUpdateGroup,
    bool canDeleteGroup,
    bool canManagePermissions,
    bool canManageChannels,
    bool canManageSettings,
    bool canModerateChat,
    bool canStartLive,
    bool canApproveGroup,
    bool canArchiveGroup,
  });
}

/// @nodoc
class __$$GroupCapabilitiesImplCopyWithImpl<$Res>
    extends _$GroupCapabilitiesCopyWithImpl<$Res, _$GroupCapabilitiesImpl>
    implements _$$GroupCapabilitiesImplCopyWith<$Res> {
  __$$GroupCapabilitiesImplCopyWithImpl(
    _$GroupCapabilitiesImpl _value,
    $Res Function(_$GroupCapabilitiesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroupCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? canViewGroup = null,
    Object? canUploadVideo = null,
    Object? canManageVideos = null,
    Object? canCreatePlaylist = null,
    Object? canManagePlaylists = null,
    Object? canViewMembers = null,
    Object? canManageMembers = null,
    Object? canEditGroup = null,
    Object? canUpdateGroup = null,
    Object? canDeleteGroup = null,
    Object? canManagePermissions = null,
    Object? canManageChannels = null,
    Object? canManageSettings = null,
    Object? canModerateChat = null,
    Object? canStartLive = null,
    Object? canApproveGroup = null,
    Object? canArchiveGroup = null,
  }) {
    return _then(
      _$GroupCapabilitiesImpl(
        canViewGroup: null == canViewGroup
            ? _value.canViewGroup
            : canViewGroup // ignore: cast_nullable_to_non_nullable
                  as bool,
        canUploadVideo: null == canUploadVideo
            ? _value.canUploadVideo
            : canUploadVideo // ignore: cast_nullable_to_non_nullable
                  as bool,
        canManageVideos: null == canManageVideos
            ? _value.canManageVideos
            : canManageVideos // ignore: cast_nullable_to_non_nullable
                  as bool,
        canCreatePlaylist: null == canCreatePlaylist
            ? _value.canCreatePlaylist
            : canCreatePlaylist // ignore: cast_nullable_to_non_nullable
                  as bool,
        canManagePlaylists: null == canManagePlaylists
            ? _value.canManagePlaylists
            : canManagePlaylists // ignore: cast_nullable_to_non_nullable
                  as bool,
        canViewMembers: null == canViewMembers
            ? _value.canViewMembers
            : canViewMembers // ignore: cast_nullable_to_non_nullable
                  as bool,
        canManageMembers: null == canManageMembers
            ? _value.canManageMembers
            : canManageMembers // ignore: cast_nullable_to_non_nullable
                  as bool,
        canEditGroup: null == canEditGroup
            ? _value.canEditGroup
            : canEditGroup // ignore: cast_nullable_to_non_nullable
                  as bool,
        canUpdateGroup: null == canUpdateGroup
            ? _value.canUpdateGroup
            : canUpdateGroup // ignore: cast_nullable_to_non_nullable
                  as bool,
        canDeleteGroup: null == canDeleteGroup
            ? _value.canDeleteGroup
            : canDeleteGroup // ignore: cast_nullable_to_non_nullable
                  as bool,
        canManagePermissions: null == canManagePermissions
            ? _value.canManagePermissions
            : canManagePermissions // ignore: cast_nullable_to_non_nullable
                  as bool,
        canManageChannels: null == canManageChannels
            ? _value.canManageChannels
            : canManageChannels // ignore: cast_nullable_to_non_nullable
                  as bool,
        canManageSettings: null == canManageSettings
            ? _value.canManageSettings
            : canManageSettings // ignore: cast_nullable_to_non_nullable
                  as bool,
        canModerateChat: null == canModerateChat
            ? _value.canModerateChat
            : canModerateChat // ignore: cast_nullable_to_non_nullable
                  as bool,
        canStartLive: null == canStartLive
            ? _value.canStartLive
            : canStartLive // ignore: cast_nullable_to_non_nullable
                  as bool,
        canApproveGroup: null == canApproveGroup
            ? _value.canApproveGroup
            : canApproveGroup // ignore: cast_nullable_to_non_nullable
                  as bool,
        canArchiveGroup: null == canArchiveGroup
            ? _value.canArchiveGroup
            : canArchiveGroup // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupCapabilitiesImpl implements _GroupCapabilities {
  const _$GroupCapabilitiesImpl({
    this.canViewGroup = false,
    this.canUploadVideo = false,
    this.canManageVideos = false,
    this.canCreatePlaylist = false,
    this.canManagePlaylists = false,
    this.canViewMembers = false,
    this.canManageMembers = false,
    this.canEditGroup = false,
    this.canUpdateGroup = false,
    this.canDeleteGroup = false,
    this.canManagePermissions = false,
    this.canManageChannels = false,
    this.canManageSettings = false,
    this.canModerateChat = false,
    this.canStartLive = false,
    this.canApproveGroup = false,
    this.canArchiveGroup = false,
  });

  factory _$GroupCapabilitiesImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupCapabilitiesImplFromJson(json);

  @override
  @JsonKey()
  final bool canViewGroup;
  @override
  @JsonKey()
  final bool canUploadVideo;
  @override
  @JsonKey()
  final bool canManageVideos;
  @override
  @JsonKey()
  final bool canCreatePlaylist;
  @override
  @JsonKey()
  final bool canManagePlaylists;
  @override
  @JsonKey()
  final bool canViewMembers;
  @override
  @JsonKey()
  final bool canManageMembers;
  @override
  @JsonKey()
  final bool canEditGroup;
  @override
  @JsonKey()
  final bool canUpdateGroup;
  @override
  @JsonKey()
  final bool canDeleteGroup;
  @override
  @JsonKey()
  final bool canManagePermissions;
  @override
  @JsonKey()
  final bool canManageChannels;
  @override
  @JsonKey()
  final bool canManageSettings;
  @override
  @JsonKey()
  final bool canModerateChat;
  @override
  @JsonKey()
  final bool canStartLive;
  @override
  @JsonKey()
  final bool canApproveGroup;
  @override
  @JsonKey()
  final bool canArchiveGroup;

  @override
  String toString() {
    return 'GroupCapabilities(canViewGroup: $canViewGroup, canUploadVideo: $canUploadVideo, canManageVideos: $canManageVideos, canCreatePlaylist: $canCreatePlaylist, canManagePlaylists: $canManagePlaylists, canViewMembers: $canViewMembers, canManageMembers: $canManageMembers, canEditGroup: $canEditGroup, canUpdateGroup: $canUpdateGroup, canDeleteGroup: $canDeleteGroup, canManagePermissions: $canManagePermissions, canManageChannels: $canManageChannels, canManageSettings: $canManageSettings, canModerateChat: $canModerateChat, canStartLive: $canStartLive, canApproveGroup: $canApproveGroup, canArchiveGroup: $canArchiveGroup)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupCapabilitiesImpl &&
            (identical(other.canViewGroup, canViewGroup) ||
                other.canViewGroup == canViewGroup) &&
            (identical(other.canUploadVideo, canUploadVideo) ||
                other.canUploadVideo == canUploadVideo) &&
            (identical(other.canManageVideos, canManageVideos) ||
                other.canManageVideos == canManageVideos) &&
            (identical(other.canCreatePlaylist, canCreatePlaylist) ||
                other.canCreatePlaylist == canCreatePlaylist) &&
            (identical(other.canManagePlaylists, canManagePlaylists) ||
                other.canManagePlaylists == canManagePlaylists) &&
            (identical(other.canViewMembers, canViewMembers) ||
                other.canViewMembers == canViewMembers) &&
            (identical(other.canManageMembers, canManageMembers) ||
                other.canManageMembers == canManageMembers) &&
            (identical(other.canEditGroup, canEditGroup) ||
                other.canEditGroup == canEditGroup) &&
            (identical(other.canUpdateGroup, canUpdateGroup) ||
                other.canUpdateGroup == canUpdateGroup) &&
            (identical(other.canDeleteGroup, canDeleteGroup) ||
                other.canDeleteGroup == canDeleteGroup) &&
            (identical(other.canManagePermissions, canManagePermissions) ||
                other.canManagePermissions == canManagePermissions) &&
            (identical(other.canManageChannels, canManageChannels) ||
                other.canManageChannels == canManageChannels) &&
            (identical(other.canManageSettings, canManageSettings) ||
                other.canManageSettings == canManageSettings) &&
            (identical(other.canModerateChat, canModerateChat) ||
                other.canModerateChat == canModerateChat) &&
            (identical(other.canStartLive, canStartLive) ||
                other.canStartLive == canStartLive) &&
            (identical(other.canApproveGroup, canApproveGroup) ||
                other.canApproveGroup == canApproveGroup) &&
            (identical(other.canArchiveGroup, canArchiveGroup) ||
                other.canArchiveGroup == canArchiveGroup));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    canViewGroup,
    canUploadVideo,
    canManageVideos,
    canCreatePlaylist,
    canManagePlaylists,
    canViewMembers,
    canManageMembers,
    canEditGroup,
    canUpdateGroup,
    canDeleteGroup,
    canManagePermissions,
    canManageChannels,
    canManageSettings,
    canModerateChat,
    canStartLive,
    canApproveGroup,
    canArchiveGroup,
  );

  /// Create a copy of GroupCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupCapabilitiesImplCopyWith<_$GroupCapabilitiesImpl> get copyWith =>
      __$$GroupCapabilitiesImplCopyWithImpl<_$GroupCapabilitiesImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupCapabilitiesImplToJson(this);
  }
}

abstract class _GroupCapabilities implements GroupCapabilities {
  const factory _GroupCapabilities({
    final bool canViewGroup,
    final bool canUploadVideo,
    final bool canManageVideos,
    final bool canCreatePlaylist,
    final bool canManagePlaylists,
    final bool canViewMembers,
    final bool canManageMembers,
    final bool canEditGroup,
    final bool canUpdateGroup,
    final bool canDeleteGroup,
    final bool canManagePermissions,
    final bool canManageChannels,
    final bool canManageSettings,
    final bool canModerateChat,
    final bool canStartLive,
    final bool canApproveGroup,
    final bool canArchiveGroup,
  }) = _$GroupCapabilitiesImpl;

  factory _GroupCapabilities.fromJson(Map<String, dynamic> json) =
      _$GroupCapabilitiesImpl.fromJson;

  @override
  bool get canViewGroup;
  @override
  bool get canUploadVideo;
  @override
  bool get canManageVideos;
  @override
  bool get canCreatePlaylist;
  @override
  bool get canManagePlaylists;
  @override
  bool get canViewMembers;
  @override
  bool get canManageMembers;
  @override
  bool get canEditGroup;
  @override
  bool get canUpdateGroup;
  @override
  bool get canDeleteGroup;
  @override
  bool get canManagePermissions;
  @override
  bool get canManageChannels;
  @override
  bool get canManageSettings;
  @override
  bool get canModerateChat;
  @override
  bool get canStartLive;
  @override
  bool get canApproveGroup;
  @override
  bool get canArchiveGroup;

  /// Create a copy of GroupCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupCapabilitiesImplCopyWith<_$GroupCapabilitiesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupContextDto _$GroupContextDtoFromJson(Map<String, dynamic> json) {
  return _GroupContextDto.fromJson(json);
}

/// @nodoc
mixin _$GroupContextDto {
  // Group identity
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  GroupStatus get status => throw _privateConstructorUsedError;
  GroupVisibility get visibility => throw _privateConstructorUsedError;
  int get membersCount => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;
  String? get website => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String get createdById => throw _privateConstructorUsedError;
  String? get approvedById => throw _privateConstructorUsedError;
  DateTime? get approvedAt => throw _privateConstructorUsedError;
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // Caller membership info
  /// null = not a member or unauthenticated
  GroupRole? get callerRole => throw _privateConstructorUsedError;
  GroupCapabilities get capabilities =>
      throw _privateConstructorUsedError; // Video channels
  List<VideoChannelSummaryDto> get videoChannels =>
      throw _privateConstructorUsedError;

  /// Deterministically resolved primary channel ID.
  /// null means the group has no active video channels.
  String? get defaultVideoChannelId => throw _privateConstructorUsedError;

  /// Serializes this GroupContextDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupContextDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupContextDtoCopyWith<GroupContextDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupContextDtoCopyWith<$Res> {
  factory $GroupContextDtoCopyWith(
    GroupContextDto value,
    $Res Function(GroupContextDto) then,
  ) = _$GroupContextDtoCopyWithImpl<$Res, GroupContextDto>;
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String? description,
    GroupStatus status,
    GroupVisibility visibility,
    int membersCount,
    String? avatarUrl,
    String? coverUrl,
    String? website,
    String? country,
    String createdById,
    String? approvedById,
    DateTime? approvedAt,
    DateTime createdAt,
    GroupRole? callerRole,
    GroupCapabilities capabilities,
    List<VideoChannelSummaryDto> videoChannels,
    String? defaultVideoChannelId,
  });

  $GroupCapabilitiesCopyWith<$Res> get capabilities;
}

/// @nodoc
class _$GroupContextDtoCopyWithImpl<$Res, $Val extends GroupContextDto>
    implements $GroupContextDtoCopyWith<$Res> {
  _$GroupContextDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupContextDto
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
    Object? membersCount = null,
    Object? avatarUrl = freezed,
    Object? coverUrl = freezed,
    Object? website = freezed,
    Object? country = freezed,
    Object? createdById = null,
    Object? approvedById = freezed,
    Object? approvedAt = freezed,
    Object? createdAt = null,
    Object? callerRole = freezed,
    Object? capabilities = null,
    Object? videoChannels = null,
    Object? defaultVideoChannelId = freezed,
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
            membersCount: null == membersCount
                ? _value.membersCount
                : membersCount // ignore: cast_nullable_to_non_nullable
                      as int,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            coverUrl: freezed == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            website: freezed == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String?,
            country: freezed == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String?,
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
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            callerRole: freezed == callerRole
                ? _value.callerRole
                : callerRole // ignore: cast_nullable_to_non_nullable
                      as GroupRole?,
            capabilities: null == capabilities
                ? _value.capabilities
                : capabilities // ignore: cast_nullable_to_non_nullable
                      as GroupCapabilities,
            videoChannels: null == videoChannels
                ? _value.videoChannels
                : videoChannels // ignore: cast_nullable_to_non_nullable
                      as List<VideoChannelSummaryDto>,
            defaultVideoChannelId: freezed == defaultVideoChannelId
                ? _value.defaultVideoChannelId
                : defaultVideoChannelId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of GroupContextDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GroupCapabilitiesCopyWith<$Res> get capabilities {
    return $GroupCapabilitiesCopyWith<$Res>(_value.capabilities, (value) {
      return _then(_value.copyWith(capabilities: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GroupContextDtoImplCopyWith<$Res>
    implements $GroupContextDtoCopyWith<$Res> {
  factory _$$GroupContextDtoImplCopyWith(
    _$GroupContextDtoImpl value,
    $Res Function(_$GroupContextDtoImpl) then,
  ) = __$$GroupContextDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String? description,
    GroupStatus status,
    GroupVisibility visibility,
    int membersCount,
    String? avatarUrl,
    String? coverUrl,
    String? website,
    String? country,
    String createdById,
    String? approvedById,
    DateTime? approvedAt,
    DateTime createdAt,
    GroupRole? callerRole,
    GroupCapabilities capabilities,
    List<VideoChannelSummaryDto> videoChannels,
    String? defaultVideoChannelId,
  });

  @override
  $GroupCapabilitiesCopyWith<$Res> get capabilities;
}

/// @nodoc
class __$$GroupContextDtoImplCopyWithImpl<$Res>
    extends _$GroupContextDtoCopyWithImpl<$Res, _$GroupContextDtoImpl>
    implements _$$GroupContextDtoImplCopyWith<$Res> {
  __$$GroupContextDtoImplCopyWithImpl(
    _$GroupContextDtoImpl _value,
    $Res Function(_$GroupContextDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroupContextDto
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
    Object? membersCount = null,
    Object? avatarUrl = freezed,
    Object? coverUrl = freezed,
    Object? website = freezed,
    Object? country = freezed,
    Object? createdById = null,
    Object? approvedById = freezed,
    Object? approvedAt = freezed,
    Object? createdAt = null,
    Object? callerRole = freezed,
    Object? capabilities = null,
    Object? videoChannels = null,
    Object? defaultVideoChannelId = freezed,
  }) {
    return _then(
      _$GroupContextDtoImpl(
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
        membersCount: null == membersCount
            ? _value.membersCount
            : membersCount // ignore: cast_nullable_to_non_nullable
                  as int,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        coverUrl: freezed == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        website: freezed == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String?,
        country: freezed == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String?,
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
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        callerRole: freezed == callerRole
            ? _value.callerRole
            : callerRole // ignore: cast_nullable_to_non_nullable
                  as GroupRole?,
        capabilities: null == capabilities
            ? _value.capabilities
            : capabilities // ignore: cast_nullable_to_non_nullable
                  as GroupCapabilities,
        videoChannels: null == videoChannels
            ? _value._videoChannels
            : videoChannels // ignore: cast_nullable_to_non_nullable
                  as List<VideoChannelSummaryDto>,
        defaultVideoChannelId: freezed == defaultVideoChannelId
            ? _value.defaultVideoChannelId
            : defaultVideoChannelId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupContextDtoImpl implements _GroupContextDto {
  const _$GroupContextDtoImpl({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.status,
    required this.visibility,
    required this.membersCount,
    this.avatarUrl,
    this.coverUrl,
    this.website,
    this.country,
    required this.createdById,
    this.approvedById,
    this.approvedAt,
    required this.createdAt,
    this.callerRole,
    required this.capabilities,
    required final List<VideoChannelSummaryDto> videoChannels,
    this.defaultVideoChannelId,
  }) : _videoChannels = videoChannels;

  factory _$GroupContextDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupContextDtoImplFromJson(json);

  // Group identity
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
  final int membersCount;
  @override
  final String? avatarUrl;
  @override
  final String? coverUrl;
  @override
  final String? website;
  @override
  final String? country;
  @override
  final String createdById;
  @override
  final String? approvedById;
  @override
  final DateTime? approvedAt;
  @override
  final DateTime createdAt;
  // Caller membership info
  /// null = not a member or unauthenticated
  @override
  final GroupRole? callerRole;
  @override
  final GroupCapabilities capabilities;
  // Video channels
  final List<VideoChannelSummaryDto> _videoChannels;
  // Video channels
  @override
  List<VideoChannelSummaryDto> get videoChannels {
    if (_videoChannels is EqualUnmodifiableListView) return _videoChannels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_videoChannels);
  }

  /// Deterministically resolved primary channel ID.
  /// null means the group has no active video channels.
  @override
  final String? defaultVideoChannelId;

  @override
  String toString() {
    return 'GroupContextDto(id: $id, name: $name, slug: $slug, description: $description, status: $status, visibility: $visibility, membersCount: $membersCount, avatarUrl: $avatarUrl, coverUrl: $coverUrl, website: $website, country: $country, createdById: $createdById, approvedById: $approvedById, approvedAt: $approvedAt, createdAt: $createdAt, callerRole: $callerRole, capabilities: $capabilities, videoChannels: $videoChannels, defaultVideoChannelId: $defaultVideoChannelId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupContextDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.membersCount, membersCount) ||
                other.membersCount == membersCount) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.createdById, createdById) ||
                other.createdById == createdById) &&
            (identical(other.approvedById, approvedById) ||
                other.approvedById == approvedById) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.callerRole, callerRole) ||
                other.callerRole == callerRole) &&
            (identical(other.capabilities, capabilities) ||
                other.capabilities == capabilities) &&
            const DeepCollectionEquality().equals(
              other._videoChannels,
              _videoChannels,
            ) &&
            (identical(other.defaultVideoChannelId, defaultVideoChannelId) ||
                other.defaultVideoChannelId == defaultVideoChannelId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    slug,
    description,
    status,
    visibility,
    membersCount,
    avatarUrl,
    coverUrl,
    website,
    country,
    createdById,
    approvedById,
    approvedAt,
    createdAt,
    callerRole,
    capabilities,
    const DeepCollectionEquality().hash(_videoChannels),
    defaultVideoChannelId,
  ]);

  /// Create a copy of GroupContextDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupContextDtoImplCopyWith<_$GroupContextDtoImpl> get copyWith =>
      __$$GroupContextDtoImplCopyWithImpl<_$GroupContextDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupContextDtoImplToJson(this);
  }
}

abstract class _GroupContextDto implements GroupContextDto {
  const factory _GroupContextDto({
    required final String id,
    required final String name,
    required final String slug,
    final String? description,
    required final GroupStatus status,
    required final GroupVisibility visibility,
    required final int membersCount,
    final String? avatarUrl,
    final String? coverUrl,
    final String? website,
    final String? country,
    required final String createdById,
    final String? approvedById,
    final DateTime? approvedAt,
    required final DateTime createdAt,
    final GroupRole? callerRole,
    required final GroupCapabilities capabilities,
    required final List<VideoChannelSummaryDto> videoChannels,
    final String? defaultVideoChannelId,
  }) = _$GroupContextDtoImpl;

  factory _GroupContextDto.fromJson(Map<String, dynamic> json) =
      _$GroupContextDtoImpl.fromJson;

  // Group identity
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
  int get membersCount;
  @override
  String? get avatarUrl;
  @override
  String? get coverUrl;
  @override
  String? get website;
  @override
  String? get country;
  @override
  String get createdById;
  @override
  String? get approvedById;
  @override
  DateTime? get approvedAt;
  @override
  DateTime get createdAt; // Caller membership info
  /// null = not a member or unauthenticated
  @override
  GroupRole? get callerRole;
  @override
  GroupCapabilities get capabilities; // Video channels
  @override
  List<VideoChannelSummaryDto> get videoChannels;

  /// Deterministically resolved primary channel ID.
  /// null means the group has no active video channels.
  @override
  String? get defaultVideoChannelId;

  /// Create a copy of GroupContextDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupContextDtoImplCopyWith<_$GroupContextDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
