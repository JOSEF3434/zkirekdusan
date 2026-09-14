// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalUsersTable extends LocalUsers
    with TableInfo<$LocalUsersTable, LocalUserData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    displayName,
    avatarUrl,
    email,
    phoneNumber,
    role,
    bio,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalUserData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUserData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUserData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalUsersTable createAlias(String alias) {
    return $LocalUsersTable(attachedDatabase, alias);
  }
}

class LocalUserData extends DataClass implements Insertable<LocalUserData> {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final String? bio;
  final DateTime? updatedAt;
  const LocalUserData({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.email,
    this.phoneNumber,
    this.role,
    this.bio,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalUsersCompanion toCompanion(bool nullToAbsent) {
    return LocalUsersCompanion(
      id: Value(id),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalUserData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUserData(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String?>(json['username']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      email: serializer.fromJson<String?>(json['email']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      role: serializer.fromJson<String?>(json['role']),
      bio: serializer.fromJson<String?>(json['bio']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String?>(username),
      'displayName': serializer.toJson<String?>(displayName),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'email': serializer.toJson<String?>(email),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'role': serializer.toJson<String?>(role),
      'bio': serializer.toJson<String?>(bio),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalUserData copyWith({
    String? id,
    Value<String?> username = const Value.absent(),
    Value<String?> displayName = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> role = const Value.absent(),
    Value<String?> bio = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalUserData(
    id: id ?? this.id,
    username: username.present ? username.value : this.username,
    displayName: displayName.present ? displayName.value : this.displayName,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    email: email.present ? email.value : this.email,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    role: role.present ? role.value : this.role,
    bio: bio.present ? bio.value : this.bio,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalUserData copyWithCompanion(LocalUsersCompanion data) {
    return LocalUserData(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      email: data.email.present ? data.email.value : this.email,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      role: data.role.present ? data.role.value : this.role,
      bio: data.bio.present ? data.bio.value : this.bio,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserData(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('role: $role, ')
          ..write('bio: $bio, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    displayName,
    avatarUrl,
    email,
    phoneNumber,
    role,
    bio,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUserData &&
          other.id == this.id &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.avatarUrl == this.avatarUrl &&
          other.email == this.email &&
          other.phoneNumber == this.phoneNumber &&
          other.role == this.role &&
          other.bio == this.bio &&
          other.updatedAt == this.updatedAt);
}

class LocalUsersCompanion extends UpdateCompanion<LocalUserData> {
  final Value<String> id;
  final Value<String?> username;
  final Value<String?> displayName;
  final Value<String?> avatarUrl;
  final Value<String?> email;
  final Value<String?> phoneNumber;
  final Value<String?> role;
  final Value<String?> bio;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalUsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.role = const Value.absent(),
    this.bio = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUsersCompanion.insert({
    required String id,
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.role = const Value.absent(),
    this.bio = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<LocalUserData> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? avatarUrl,
    Expression<String>? email,
    Expression<String>? phoneNumber,
    Expression<String>? role,
    Expression<String>? bio,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (role != null) 'role': role,
      if (bio != null) 'bio': bio,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUsersCompanion copyWith({
    Value<String>? id,
    Value<String?>? username,
    Value<String?>? displayName,
    Value<String?>? avatarUrl,
    Value<String?>? email,
    Value<String?>? phoneNumber,
    Value<String?>? role,
    Value<String?>? bio,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalUsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('role: $role, ')
          ..write('bio: $bio, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalVideosTable extends LocalVideos
    with TableInfo<$LocalVideosTable, LocalVideoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalVideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hlsUrlMeta = const VerificationMeta('hlsUrl');
  @override
  late final GeneratedColumn<String> hlsUrl = GeneratedColumn<String>(
    'hls_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dashUrlMeta = const VerificationMeta(
    'dashUrl',
  );
  @override
  late final GeneratedColumn<String> dashUrl = GeneratedColumn<String>(
    'dash_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _creatorIdMeta = const VerificationMeta(
    'creatorId',
  );
  @override
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
    'creator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creatorNameMeta = const VerificationMeta(
    'creatorName',
  );
  @override
  late final GeneratedColumn<String> creatorName = GeneratedColumn<String>(
    'creator_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creatorAvatarMeta = const VerificationMeta(
    'creatorAvatar',
  );
  @override
  late final GeneratedColumn<String> creatorAvatar = GeneratedColumn<String>(
    'creator_avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDownloadedMeta = const VerificationMeta(
    'isDownloaded',
  );
  @override
  late final GeneratedColumn<bool> isDownloaded = GeneratedColumn<bool>(
    'is_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_downloaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _downloadStatusMeta = const VerificationMeta(
    'downloadStatus',
  );
  @override
  late final GeneratedColumn<String> downloadStatus = GeneratedColumn<String>(
    'download_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadProgressMeta = const VerificationMeta(
    'downloadProgress',
  );
  @override
  late final GeneratedColumn<double> downloadProgress = GeneratedColumn<double>(
    'download_progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _selectedQualityMeta = const VerificationMeta(
    'selectedQuality',
  );
  @override
  late final GeneratedColumn<String> selectedQuality = GeneratedColumn<String>(
    'selected_quality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _downloadErrorMeta = const VerificationMeta(
    'downloadError',
  );
  @override
  late final GeneratedColumn<String> downloadError = GeneratedColumn<String>(
    'download_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPlayedPositionMeta =
      const VerificationMeta('lastPlayedPosition');
  @override
  late final GeneratedColumn<int> lastPlayedPosition = GeneratedColumn<int>(
    'last_played_position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _renditionsJsonMeta = const VerificationMeta(
    'renditionsJson',
  );
  @override
  late final GeneratedColumn<String> renditionsJson = GeneratedColumn<String>(
    'renditions_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    title,
    description,
    thumbnailUrl,
    videoUrl,
    hlsUrl,
    dashUrl,
    duration,
    creatorId,
    creatorName,
    creatorAvatar,
    createdAt,
    updatedAt,
    isDownloaded,
    downloadStatus,
    localFilePath,
    downloadProgress,
    selectedQuality,
    fileSizeBytes,
    downloadError,
    lastPlayedPosition,
    lastAccessedAt,
    isFavorite,
    renditionsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_videos';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalVideoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    if (data.containsKey('hls_url')) {
      context.handle(
        _hlsUrlMeta,
        hlsUrl.isAcceptableOrUnknown(data['hls_url']!, _hlsUrlMeta),
      );
    }
    if (data.containsKey('dash_url')) {
      context.handle(
        _dashUrlMeta,
        dashUrl.isAcceptableOrUnknown(data['dash_url']!, _dashUrlMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
      );
    }
    if (data.containsKey('creator_name')) {
      context.handle(
        _creatorNameMeta,
        creatorName.isAcceptableOrUnknown(
          data['creator_name']!,
          _creatorNameMeta,
        ),
      );
    }
    if (data.containsKey('creator_avatar')) {
      context.handle(
        _creatorAvatarMeta,
        creatorAvatar.isAcceptableOrUnknown(
          data['creator_avatar']!,
          _creatorAvatarMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_downloaded')) {
      context.handle(
        _isDownloadedMeta,
        isDownloaded.isAcceptableOrUnknown(
          data['is_downloaded']!,
          _isDownloadedMeta,
        ),
      );
    }
    if (data.containsKey('download_status')) {
      context.handle(
        _downloadStatusMeta,
        downloadStatus.isAcceptableOrUnknown(
          data['download_status']!,
          _downloadStatusMeta,
        ),
      );
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    }
    if (data.containsKey('download_progress')) {
      context.handle(
        _downloadProgressMeta,
        downloadProgress.isAcceptableOrUnknown(
          data['download_progress']!,
          _downloadProgressMeta,
        ),
      );
    }
    if (data.containsKey('selected_quality')) {
      context.handle(
        _selectedQualityMeta,
        selectedQuality.isAcceptableOrUnknown(
          data['selected_quality']!,
          _selectedQualityMeta,
        ),
      );
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('download_error')) {
      context.handle(
        _downloadErrorMeta,
        downloadError.isAcceptableOrUnknown(
          data['download_error']!,
          _downloadErrorMeta,
        ),
      );
    }
    if (data.containsKey('last_played_position')) {
      context.handle(
        _lastPlayedPositionMeta,
        lastPlayedPosition.isAcceptableOrUnknown(
          data['last_played_position']!,
          _lastPlayedPositionMeta,
        ),
      );
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('renditions_json')) {
      context.handle(
        _renditionsJsonMeta,
        renditionsJson.isAcceptableOrUnknown(
          data['renditions_json']!,
          _renditionsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalVideoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalVideoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      ),
      hlsUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hls_url'],
      ),
      dashUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dash_url'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      ),
      creatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_name'],
      ),
      creatorAvatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_avatar'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_downloaded'],
      )!,
      downloadStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_status'],
      )!,
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      ),
      downloadProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}download_progress'],
      )!,
      selectedQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_quality'],
      ),
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      downloadError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_error'],
      ),
      lastPlayedPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_played_position'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      renditionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}renditions_json'],
      ),
    );
  }

  @override
  $LocalVideosTable createAlias(String alias) {
    return $LocalVideosTable(attachedDatabase, alias);
  }
}

class LocalVideoData extends DataClass implements Insertable<LocalVideoData> {
  final String id;
  final String? serverId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? hlsUrl;
  final String? dashUrl;
  final int duration;
  final String? creatorId;
  final String? creatorName;
  final String? creatorAvatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDownloaded;
  final String downloadStatus;
  final String? localFilePath;
  final double downloadProgress;
  final String? selectedQuality;
  final int fileSizeBytes;
  final String? downloadError;
  final int lastPlayedPosition;
  final DateTime? lastAccessedAt;
  final bool isFavorite;
  final String? renditionsJson;
  const LocalVideoData({
    required this.id,
    this.serverId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.hlsUrl,
    this.dashUrl,
    required this.duration,
    this.creatorId,
    this.creatorName,
    this.creatorAvatar,
    this.createdAt,
    this.updatedAt,
    required this.isDownloaded,
    required this.downloadStatus,
    this.localFilePath,
    required this.downloadProgress,
    this.selectedQuality,
    required this.fileSizeBytes,
    this.downloadError,
    required this.lastPlayedPosition,
    this.lastAccessedAt,
    required this.isFavorite,
    this.renditionsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    if (!nullToAbsent || hlsUrl != null) {
      map['hls_url'] = Variable<String>(hlsUrl);
    }
    if (!nullToAbsent || dashUrl != null) {
      map['dash_url'] = Variable<String>(dashUrl);
    }
    map['duration'] = Variable<int>(duration);
    if (!nullToAbsent || creatorId != null) {
      map['creator_id'] = Variable<String>(creatorId);
    }
    if (!nullToAbsent || creatorName != null) {
      map['creator_name'] = Variable<String>(creatorName);
    }
    if (!nullToAbsent || creatorAvatar != null) {
      map['creator_avatar'] = Variable<String>(creatorAvatar);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_downloaded'] = Variable<bool>(isDownloaded);
    map['download_status'] = Variable<String>(downloadStatus);
    if (!nullToAbsent || localFilePath != null) {
      map['local_file_path'] = Variable<String>(localFilePath);
    }
    map['download_progress'] = Variable<double>(downloadProgress);
    if (!nullToAbsent || selectedQuality != null) {
      map['selected_quality'] = Variable<String>(selectedQuality);
    }
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    if (!nullToAbsent || downloadError != null) {
      map['download_error'] = Variable<String>(downloadError);
    }
    map['last_played_position'] = Variable<int>(lastPlayedPosition);
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || renditionsJson != null) {
      map['renditions_json'] = Variable<String>(renditionsJson);
    }
    return map;
  }

  LocalVideosCompanion toCompanion(bool nullToAbsent) {
    return LocalVideosCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
      hlsUrl: hlsUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(hlsUrl),
      dashUrl: dashUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(dashUrl),
      duration: Value(duration),
      creatorId: creatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorId),
      creatorName: creatorName == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorName),
      creatorAvatar: creatorAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorAvatar),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDownloaded: Value(isDownloaded),
      downloadStatus: Value(downloadStatus),
      localFilePath: localFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localFilePath),
      downloadProgress: Value(downloadProgress),
      selectedQuality: selectedQuality == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedQuality),
      fileSizeBytes: Value(fileSizeBytes),
      downloadError: downloadError == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadError),
      lastPlayedPosition: Value(lastPlayedPosition),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
      isFavorite: Value(isFavorite),
      renditionsJson: renditionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(renditionsJson),
    );
  }

  factory LocalVideoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalVideoData(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
      hlsUrl: serializer.fromJson<String?>(json['hlsUrl']),
      dashUrl: serializer.fromJson<String?>(json['dashUrl']),
      duration: serializer.fromJson<int>(json['duration']),
      creatorId: serializer.fromJson<String?>(json['creatorId']),
      creatorName: serializer.fromJson<String?>(json['creatorName']),
      creatorAvatar: serializer.fromJson<String?>(json['creatorAvatar']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDownloaded: serializer.fromJson<bool>(json['isDownloaded']),
      downloadStatus: serializer.fromJson<String>(json['downloadStatus']),
      localFilePath: serializer.fromJson<String?>(json['localFilePath']),
      downloadProgress: serializer.fromJson<double>(json['downloadProgress']),
      selectedQuality: serializer.fromJson<String?>(json['selectedQuality']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      downloadError: serializer.fromJson<String?>(json['downloadError']),
      lastPlayedPosition: serializer.fromJson<int>(json['lastPlayedPosition']),
      lastAccessedAt: serializer.fromJson<DateTime?>(json['lastAccessedAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      renditionsJson: serializer.fromJson<String?>(json['renditionsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'videoUrl': serializer.toJson<String?>(videoUrl),
      'hlsUrl': serializer.toJson<String?>(hlsUrl),
      'dashUrl': serializer.toJson<String?>(dashUrl),
      'duration': serializer.toJson<int>(duration),
      'creatorId': serializer.toJson<String?>(creatorId),
      'creatorName': serializer.toJson<String?>(creatorName),
      'creatorAvatar': serializer.toJson<String?>(creatorAvatar),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDownloaded': serializer.toJson<bool>(isDownloaded),
      'downloadStatus': serializer.toJson<String>(downloadStatus),
      'localFilePath': serializer.toJson<String?>(localFilePath),
      'downloadProgress': serializer.toJson<double>(downloadProgress),
      'selectedQuality': serializer.toJson<String?>(selectedQuality),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'downloadError': serializer.toJson<String?>(downloadError),
      'lastPlayedPosition': serializer.toJson<int>(lastPlayedPosition),
      'lastAccessedAt': serializer.toJson<DateTime?>(lastAccessedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'renditionsJson': serializer.toJson<String?>(renditionsJson),
    };
  }

  LocalVideoData copyWith({
    String? id,
    Value<String?> serverId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    Value<String?> videoUrl = const Value.absent(),
    Value<String?> hlsUrl = const Value.absent(),
    Value<String?> dashUrl = const Value.absent(),
    int? duration,
    Value<String?> creatorId = const Value.absent(),
    Value<String?> creatorName = const Value.absent(),
    Value<String?> creatorAvatar = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isDownloaded,
    String? downloadStatus,
    Value<String?> localFilePath = const Value.absent(),
    double? downloadProgress,
    Value<String?> selectedQuality = const Value.absent(),
    int? fileSizeBytes,
    Value<String?> downloadError = const Value.absent(),
    int? lastPlayedPosition,
    Value<DateTime?> lastAccessedAt = const Value.absent(),
    bool? isFavorite,
    Value<String?> renditionsJson = const Value.absent(),
  }) => LocalVideoData(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
    hlsUrl: hlsUrl.present ? hlsUrl.value : this.hlsUrl,
    dashUrl: dashUrl.present ? dashUrl.value : this.dashUrl,
    duration: duration ?? this.duration,
    creatorId: creatorId.present ? creatorId.value : this.creatorId,
    creatorName: creatorName.present ? creatorName.value : this.creatorName,
    creatorAvatar: creatorAvatar.present
        ? creatorAvatar.value
        : this.creatorAvatar,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isDownloaded: isDownloaded ?? this.isDownloaded,
    downloadStatus: downloadStatus ?? this.downloadStatus,
    localFilePath: localFilePath.present
        ? localFilePath.value
        : this.localFilePath,
    downloadProgress: downloadProgress ?? this.downloadProgress,
    selectedQuality: selectedQuality.present
        ? selectedQuality.value
        : this.selectedQuality,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    downloadError: downloadError.present
        ? downloadError.value
        : this.downloadError,
    lastPlayedPosition: lastPlayedPosition ?? this.lastPlayedPosition,
    lastAccessedAt: lastAccessedAt.present
        ? lastAccessedAt.value
        : this.lastAccessedAt,
    isFavorite: isFavorite ?? this.isFavorite,
    renditionsJson: renditionsJson.present
        ? renditionsJson.value
        : this.renditionsJson,
  );
  LocalVideoData copyWithCompanion(LocalVideosCompanion data) {
    return LocalVideoData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      hlsUrl: data.hlsUrl.present ? data.hlsUrl.value : this.hlsUrl,
      dashUrl: data.dashUrl.present ? data.dashUrl.value : this.dashUrl,
      duration: data.duration.present ? data.duration.value : this.duration,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
      creatorName: data.creatorName.present
          ? data.creatorName.value
          : this.creatorName,
      creatorAvatar: data.creatorAvatar.present
          ? data.creatorAvatar.value
          : this.creatorAvatar,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDownloaded: data.isDownloaded.present
          ? data.isDownloaded.value
          : this.isDownloaded,
      downloadStatus: data.downloadStatus.present
          ? data.downloadStatus.value
          : this.downloadStatus,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      downloadProgress: data.downloadProgress.present
          ? data.downloadProgress.value
          : this.downloadProgress,
      selectedQuality: data.selectedQuality.present
          ? data.selectedQuality.value
          : this.selectedQuality,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      downloadError: data.downloadError.present
          ? data.downloadError.value
          : this.downloadError,
      lastPlayedPosition: data.lastPlayedPosition.present
          ? data.lastPlayedPosition.value
          : this.lastPlayedPosition,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      renditionsJson: data.renditionsJson.present
          ? data.renditionsJson.value
          : this.renditionsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalVideoData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('hlsUrl: $hlsUrl, ')
          ..write('dashUrl: $dashUrl, ')
          ..write('duration: $duration, ')
          ..write('creatorId: $creatorId, ')
          ..write('creatorName: $creatorName, ')
          ..write('creatorAvatar: $creatorAvatar, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('downloadStatus: $downloadStatus, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('downloadProgress: $downloadProgress, ')
          ..write('selectedQuality: $selectedQuality, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadError: $downloadError, ')
          ..write('lastPlayedPosition: $lastPlayedPosition, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('renditionsJson: $renditionsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    title,
    description,
    thumbnailUrl,
    videoUrl,
    hlsUrl,
    dashUrl,
    duration,
    creatorId,
    creatorName,
    creatorAvatar,
    createdAt,
    updatedAt,
    isDownloaded,
    downloadStatus,
    localFilePath,
    downloadProgress,
    selectedQuality,
    fileSizeBytes,
    downloadError,
    lastPlayedPosition,
    lastAccessedAt,
    isFavorite,
    renditionsJson,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalVideoData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.description == this.description &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.videoUrl == this.videoUrl &&
          other.hlsUrl == this.hlsUrl &&
          other.dashUrl == this.dashUrl &&
          other.duration == this.duration &&
          other.creatorId == this.creatorId &&
          other.creatorName == this.creatorName &&
          other.creatorAvatar == this.creatorAvatar &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDownloaded == this.isDownloaded &&
          other.downloadStatus == this.downloadStatus &&
          other.localFilePath == this.localFilePath &&
          other.downloadProgress == this.downloadProgress &&
          other.selectedQuality == this.selectedQuality &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.downloadError == this.downloadError &&
          other.lastPlayedPosition == this.lastPlayedPosition &&
          other.lastAccessedAt == this.lastAccessedAt &&
          other.isFavorite == this.isFavorite &&
          other.renditionsJson == this.renditionsJson);
}

class LocalVideosCompanion extends UpdateCompanion<LocalVideoData> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> thumbnailUrl;
  final Value<String?> videoUrl;
  final Value<String?> hlsUrl;
  final Value<String?> dashUrl;
  final Value<int> duration;
  final Value<String?> creatorId;
  final Value<String?> creatorName;
  final Value<String?> creatorAvatar;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDownloaded;
  final Value<String> downloadStatus;
  final Value<String?> localFilePath;
  final Value<double> downloadProgress;
  final Value<String?> selectedQuality;
  final Value<int> fileSizeBytes;
  final Value<String?> downloadError;
  final Value<int> lastPlayedPosition;
  final Value<DateTime?> lastAccessedAt;
  final Value<bool> isFavorite;
  final Value<String?> renditionsJson;
  final Value<int> rowid;
  const LocalVideosCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.hlsUrl = const Value.absent(),
    this.dashUrl = const Value.absent(),
    this.duration = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.creatorName = const Value.absent(),
    this.creatorAvatar = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.downloadStatus = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.downloadProgress = const Value.absent(),
    this.selectedQuality = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.downloadError = const Value.absent(),
    this.lastPlayedPosition = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.renditionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalVideosCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.hlsUrl = const Value.absent(),
    this.dashUrl = const Value.absent(),
    this.duration = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.creatorName = const Value.absent(),
    this.creatorAvatar = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.downloadStatus = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.downloadProgress = const Value.absent(),
    this.selectedQuality = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.downloadError = const Value.absent(),
    this.lastPlayedPosition = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.renditionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<LocalVideoData> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? thumbnailUrl,
    Expression<String>? videoUrl,
    Expression<String>? hlsUrl,
    Expression<String>? dashUrl,
    Expression<int>? duration,
    Expression<String>? creatorId,
    Expression<String>? creatorName,
    Expression<String>? creatorAvatar,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDownloaded,
    Expression<String>? downloadStatus,
    Expression<String>? localFilePath,
    Expression<double>? downloadProgress,
    Expression<String>? selectedQuality,
    Expression<int>? fileSizeBytes,
    Expression<String>? downloadError,
    Expression<int>? lastPlayedPosition,
    Expression<DateTime>? lastAccessedAt,
    Expression<bool>? isFavorite,
    Expression<String>? renditionsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      if (hlsUrl != null) 'hls_url': hlsUrl,
      if (dashUrl != null) 'dash_url': dashUrl,
      if (duration != null) 'duration': duration,
      if (creatorId != null) 'creator_id': creatorId,
      if (creatorName != null) 'creator_name': creatorName,
      if (creatorAvatar != null) 'creator_avatar': creatorAvatar,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDownloaded != null) 'is_downloaded': isDownloaded,
      if (downloadStatus != null) 'download_status': downloadStatus,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (downloadProgress != null) 'download_progress': downloadProgress,
      if (selectedQuality != null) 'selected_quality': selectedQuality,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (downloadError != null) 'download_error': downloadError,
      if (lastPlayedPosition != null)
        'last_played_position': lastPlayedPosition,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (renditionsJson != null) 'renditions_json': renditionsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalVideosCompanion copyWith({
    Value<String>? id,
    Value<String?>? serverId,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? thumbnailUrl,
    Value<String?>? videoUrl,
    Value<String?>? hlsUrl,
    Value<String?>? dashUrl,
    Value<int>? duration,
    Value<String?>? creatorId,
    Value<String?>? creatorName,
    Value<String?>? creatorAvatar,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<bool>? isDownloaded,
    Value<String>? downloadStatus,
    Value<String?>? localFilePath,
    Value<double>? downloadProgress,
    Value<String?>? selectedQuality,
    Value<int>? fileSizeBytes,
    Value<String?>? downloadError,
    Value<int>? lastPlayedPosition,
    Value<DateTime?>? lastAccessedAt,
    Value<bool>? isFavorite,
    Value<String?>? renditionsJson,
    Value<int>? rowid,
  }) {
    return LocalVideosCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      dashUrl: dashUrl ?? this.dashUrl,
      duration: duration ?? this.duration,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      localFilePath: localFilePath ?? this.localFilePath,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      selectedQuality: selectedQuality ?? this.selectedQuality,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadError: downloadError ?? this.downloadError,
      lastPlayedPosition: lastPlayedPosition ?? this.lastPlayedPosition,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      renditionsJson: renditionsJson ?? this.renditionsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (hlsUrl.present) {
      map['hls_url'] = Variable<String>(hlsUrl.value);
    }
    if (dashUrl.present) {
      map['dash_url'] = Variable<String>(dashUrl.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (creatorName.present) {
      map['creator_name'] = Variable<String>(creatorName.value);
    }
    if (creatorAvatar.present) {
      map['creator_avatar'] = Variable<String>(creatorAvatar.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDownloaded.present) {
      map['is_downloaded'] = Variable<bool>(isDownloaded.value);
    }
    if (downloadStatus.present) {
      map['download_status'] = Variable<String>(downloadStatus.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (downloadProgress.present) {
      map['download_progress'] = Variable<double>(downloadProgress.value);
    }
    if (selectedQuality.present) {
      map['selected_quality'] = Variable<String>(selectedQuality.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (downloadError.present) {
      map['download_error'] = Variable<String>(downloadError.value);
    }
    if (lastPlayedPosition.present) {
      map['last_played_position'] = Variable<int>(lastPlayedPosition.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (renditionsJson.present) {
      map['renditions_json'] = Variable<String>(renditionsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalVideosCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('hlsUrl: $hlsUrl, ')
          ..write('dashUrl: $dashUrl, ')
          ..write('duration: $duration, ')
          ..write('creatorId: $creatorId, ')
          ..write('creatorName: $creatorName, ')
          ..write('creatorAvatar: $creatorAvatar, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('downloadStatus: $downloadStatus, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('downloadProgress: $downloadProgress, ')
          ..write('selectedQuality: $selectedQuality, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadError: $downloadError, ')
          ..write('lastPlayedPosition: $lastPlayedPosition, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('renditionsJson: $renditionsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalConversationsTable extends LocalConversations
    with TableInfo<$LocalConversationsTable, LocalConversationData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageIdMeta = const VerificationMeta(
    'lastMessageId',
  );
  @override
  late final GeneratedColumn<String> lastMessageId = GeneratedColumn<String>(
    'last_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageContentMeta =
      const VerificationMeta('lastMessageContent');
  @override
  late final GeneratedColumn<String> lastMessageContent =
      GeneratedColumn<String>(
        'last_message_content',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageTypeMeta = const VerificationMeta(
    'lastMessageType',
  );
  @override
  late final GeneratedColumn<String> lastMessageType = GeneratedColumn<String>(
    'last_message_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageSenderNameMeta =
      const VerificationMeta('lastMessageSenderName');
  @override
  late final GeneratedColumn<String> lastMessageSenderName =
      GeneratedColumn<String>(
        'last_message_sender_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageSenderIdMeta =
      const VerificationMeta('lastMessageSenderId');
  @override
  late final GeneratedColumn<String> lastMessageSenderId =
      GeneratedColumn<String>(
        'last_message_sender_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastMessageAt =
      GeneratedColumn<DateTime>(
        'last_message_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isMutedMeta = const VerificationMeta(
    'isMuted',
  );
  @override
  late final GeneratedColumn<bool> isMuted = GeneratedColumn<bool>(
    'is_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _membersJsonMeta = const VerificationMeta(
    'membersJson',
  );
  @override
  late final GeneratedColumn<String> membersJson = GeneratedColumn<String>(
    'members_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    groupId,
    channelId,
    title,
    lastMessageId,
    lastMessageContent,
    lastMessageType,
    lastMessageSenderName,
    lastMessageSenderId,
    lastMessageAt,
    unreadCount,
    isMuted,
    isPinned,
    membersJson,
    metadataJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalConversationData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('last_message_id')) {
      context.handle(
        _lastMessageIdMeta,
        lastMessageId.isAcceptableOrUnknown(
          data['last_message_id']!,
          _lastMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_content')) {
      context.handle(
        _lastMessageContentMeta,
        lastMessageContent.isAcceptableOrUnknown(
          data['last_message_content']!,
          _lastMessageContentMeta,
        ),
      );
    }
    if (data.containsKey('last_message_type')) {
      context.handle(
        _lastMessageTypeMeta,
        lastMessageType.isAcceptableOrUnknown(
          data['last_message_type']!,
          _lastMessageTypeMeta,
        ),
      );
    }
    if (data.containsKey('last_message_sender_name')) {
      context.handle(
        _lastMessageSenderNameMeta,
        lastMessageSenderName.isAcceptableOrUnknown(
          data['last_message_sender_name']!,
          _lastMessageSenderNameMeta,
        ),
      );
    }
    if (data.containsKey('last_message_sender_id')) {
      context.handle(
        _lastMessageSenderIdMeta,
        lastMessageSenderId.isAcceptableOrUnknown(
          data['last_message_sender_id']!,
          _lastMessageSenderIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('is_muted')) {
      context.handle(
        _isMutedMeta,
        isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('members_json')) {
      context.handle(
        _membersJsonMeta,
        membersJson.isAcceptableOrUnknown(
          data['members_json']!,
          _membersJsonMeta,
        ),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalConversationData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalConversationData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      lastMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_id'],
      ),
      lastMessageContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_content'],
      ),
      lastMessageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_type'],
      ),
      lastMessageSenderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_sender_name'],
      ),
      lastMessageSenderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_sender_id'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_at'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      isMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_muted'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      membersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}members_json'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalConversationsTable createAlias(String alias) {
    return $LocalConversationsTable(attachedDatabase, alias);
  }
}

class LocalConversationData extends DataClass
    implements Insertable<LocalConversationData> {
  final String id;
  final String type;
  final String? groupId;
  final String? channelId;
  final String? title;
  final String? lastMessageId;
  final String? lastMessageContent;
  final String? lastMessageType;
  final String? lastMessageSenderName;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final String? membersJson;
  final String? metadataJson;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalConversationData({
    required this.id,
    required this.type,
    this.groupId,
    this.channelId,
    this.title,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageType,
    this.lastMessageSenderName,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.unreadCount,
    required this.isMuted,
    required this.isPinned,
    this.membersJson,
    this.metadataJson,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || channelId != null) {
      map['channel_id'] = Variable<String>(channelId);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<String>(lastMessageId);
    }
    if (!nullToAbsent || lastMessageContent != null) {
      map['last_message_content'] = Variable<String>(lastMessageContent);
    }
    if (!nullToAbsent || lastMessageType != null) {
      map['last_message_type'] = Variable<String>(lastMessageType);
    }
    if (!nullToAbsent || lastMessageSenderName != null) {
      map['last_message_sender_name'] = Variable<String>(lastMessageSenderName);
    }
    if (!nullToAbsent || lastMessageSenderId != null) {
      map['last_message_sender_id'] = Variable<String>(lastMessageSenderId);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    map['is_muted'] = Variable<bool>(isMuted);
    map['is_pinned'] = Variable<bool>(isPinned);
    if (!nullToAbsent || membersJson != null) {
      map['members_json'] = Variable<String>(membersJson);
    }
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalConversationsCompanion toCompanion(bool nullToAbsent) {
    return LocalConversationsCompanion(
      id: Value(id),
      type: Value(type),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      channelId: channelId == null && nullToAbsent
          ? const Value.absent()
          : Value(channelId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      lastMessageId: lastMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageId),
      lastMessageContent: lastMessageContent == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageContent),
      lastMessageType: lastMessageType == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageType),
      lastMessageSenderName: lastMessageSenderName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSenderName),
      lastMessageSenderId: lastMessageSenderId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSenderId),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      unreadCount: Value(unreadCount),
      isMuted: Value(isMuted),
      isPinned: Value(isPinned),
      membersJson: membersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(membersJson),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalConversationData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalConversationData(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      channelId: serializer.fromJson<String?>(json['channelId']),
      title: serializer.fromJson<String?>(json['title']),
      lastMessageId: serializer.fromJson<String?>(json['lastMessageId']),
      lastMessageContent: serializer.fromJson<String?>(
        json['lastMessageContent'],
      ),
      lastMessageType: serializer.fromJson<String?>(json['lastMessageType']),
      lastMessageSenderName: serializer.fromJson<String?>(
        json['lastMessageSenderName'],
      ),
      lastMessageSenderId: serializer.fromJson<String?>(
        json['lastMessageSenderId'],
      ),
      lastMessageAt: serializer.fromJson<DateTime?>(json['lastMessageAt']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      isMuted: serializer.fromJson<bool>(json['isMuted']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      membersJson: serializer.fromJson<String?>(json['membersJson']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'groupId': serializer.toJson<String?>(groupId),
      'channelId': serializer.toJson<String?>(channelId),
      'title': serializer.toJson<String?>(title),
      'lastMessageId': serializer.toJson<String?>(lastMessageId),
      'lastMessageContent': serializer.toJson<String?>(lastMessageContent),
      'lastMessageType': serializer.toJson<String?>(lastMessageType),
      'lastMessageSenderName': serializer.toJson<String?>(
        lastMessageSenderName,
      ),
      'lastMessageSenderId': serializer.toJson<String?>(lastMessageSenderId),
      'lastMessageAt': serializer.toJson<DateTime?>(lastMessageAt),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'isMuted': serializer.toJson<bool>(isMuted),
      'isPinned': serializer.toJson<bool>(isPinned),
      'membersJson': serializer.toJson<String?>(membersJson),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalConversationData copyWith({
    String? id,
    String? type,
    Value<String?> groupId = const Value.absent(),
    Value<String?> channelId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> lastMessageId = const Value.absent(),
    Value<String?> lastMessageContent = const Value.absent(),
    Value<String?> lastMessageType = const Value.absent(),
    Value<String?> lastMessageSenderName = const Value.absent(),
    Value<String?> lastMessageSenderId = const Value.absent(),
    Value<DateTime?> lastMessageAt = const Value.absent(),
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
    Value<String?> membersJson = const Value.absent(),
    Value<String?> metadataJson = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalConversationData(
    id: id ?? this.id,
    type: type ?? this.type,
    groupId: groupId.present ? groupId.value : this.groupId,
    channelId: channelId.present ? channelId.value : this.channelId,
    title: title.present ? title.value : this.title,
    lastMessageId: lastMessageId.present
        ? lastMessageId.value
        : this.lastMessageId,
    lastMessageContent: lastMessageContent.present
        ? lastMessageContent.value
        : this.lastMessageContent,
    lastMessageType: lastMessageType.present
        ? lastMessageType.value
        : this.lastMessageType,
    lastMessageSenderName: lastMessageSenderName.present
        ? lastMessageSenderName.value
        : this.lastMessageSenderName,
    lastMessageSenderId: lastMessageSenderId.present
        ? lastMessageSenderId.value
        : this.lastMessageSenderId,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
    isMuted: isMuted ?? this.isMuted,
    isPinned: isPinned ?? this.isPinned,
    membersJson: membersJson.present ? membersJson.value : this.membersJson,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalConversationData copyWithCompanion(LocalConversationsCompanion data) {
    return LocalConversationData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      title: data.title.present ? data.title.value : this.title,
      lastMessageId: data.lastMessageId.present
          ? data.lastMessageId.value
          : this.lastMessageId,
      lastMessageContent: data.lastMessageContent.present
          ? data.lastMessageContent.value
          : this.lastMessageContent,
      lastMessageType: data.lastMessageType.present
          ? data.lastMessageType.value
          : this.lastMessageType,
      lastMessageSenderName: data.lastMessageSenderName.present
          ? data.lastMessageSenderName.value
          : this.lastMessageSenderName,
      lastMessageSenderId: data.lastMessageSenderId.present
          ? data.lastMessageSenderId.value
          : this.lastMessageSenderId,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      isMuted: data.isMuted.present ? data.isMuted.value : this.isMuted,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      membersJson: data.membersJson.present
          ? data.membersJson.value
          : this.membersJson,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalConversationData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('groupId: $groupId, ')
          ..write('channelId: $channelId, ')
          ..write('title: $title, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessageContent: $lastMessageContent, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageSenderName: $lastMessageSenderName, ')
          ..write('lastMessageSenderId: $lastMessageSenderId, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('isMuted: $isMuted, ')
          ..write('isPinned: $isPinned, ')
          ..write('membersJson: $membersJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    groupId,
    channelId,
    title,
    lastMessageId,
    lastMessageContent,
    lastMessageType,
    lastMessageSenderName,
    lastMessageSenderId,
    lastMessageAt,
    unreadCount,
    isMuted,
    isPinned,
    membersJson,
    metadataJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalConversationData &&
          other.id == this.id &&
          other.type == this.type &&
          other.groupId == this.groupId &&
          other.channelId == this.channelId &&
          other.title == this.title &&
          other.lastMessageId == this.lastMessageId &&
          other.lastMessageContent == this.lastMessageContent &&
          other.lastMessageType == this.lastMessageType &&
          other.lastMessageSenderName == this.lastMessageSenderName &&
          other.lastMessageSenderId == this.lastMessageSenderId &&
          other.lastMessageAt == this.lastMessageAt &&
          other.unreadCount == this.unreadCount &&
          other.isMuted == this.isMuted &&
          other.isPinned == this.isPinned &&
          other.membersJson == this.membersJson &&
          other.metadataJson == this.metadataJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalConversationsCompanion
    extends UpdateCompanion<LocalConversationData> {
  final Value<String> id;
  final Value<String> type;
  final Value<String?> groupId;
  final Value<String?> channelId;
  final Value<String?> title;
  final Value<String?> lastMessageId;
  final Value<String?> lastMessageContent;
  final Value<String?> lastMessageType;
  final Value<String?> lastMessageSenderName;
  final Value<String?> lastMessageSenderId;
  final Value<DateTime?> lastMessageAt;
  final Value<int> unreadCount;
  final Value<bool> isMuted;
  final Value<bool> isPinned;
  final Value<String?> membersJson;
  final Value<String?> metadataJson;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalConversationsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.groupId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.title = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessageContent = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageSenderName = const Value.absent(),
    this.lastMessageSenderId = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.membersJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalConversationsCompanion.insert({
    required String id,
    required String type,
    this.groupId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.title = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessageContent = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageSenderName = const Value.absent(),
    this.lastMessageSenderId = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.membersJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type);
  static Insertable<LocalConversationData> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? groupId,
    Expression<String>? channelId,
    Expression<String>? title,
    Expression<String>? lastMessageId,
    Expression<String>? lastMessageContent,
    Expression<String>? lastMessageType,
    Expression<String>? lastMessageSenderName,
    Expression<String>? lastMessageSenderId,
    Expression<DateTime>? lastMessageAt,
    Expression<int>? unreadCount,
    Expression<bool>? isMuted,
    Expression<bool>? isPinned,
    Expression<String>? membersJson,
    Expression<String>? metadataJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (groupId != null) 'group_id': groupId,
      if (channelId != null) 'channel_id': channelId,
      if (title != null) 'title': title,
      if (lastMessageId != null) 'last_message_id': lastMessageId,
      if (lastMessageContent != null)
        'last_message_content': lastMessageContent,
      if (lastMessageType != null) 'last_message_type': lastMessageType,
      if (lastMessageSenderName != null)
        'last_message_sender_name': lastMessageSenderName,
      if (lastMessageSenderId != null)
        'last_message_sender_id': lastMessageSenderId,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (isMuted != null) 'is_muted': isMuted,
      if (isPinned != null) 'is_pinned': isPinned,
      if (membersJson != null) 'members_json': membersJson,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String?>? groupId,
    Value<String?>? channelId,
    Value<String?>? title,
    Value<String?>? lastMessageId,
    Value<String?>? lastMessageContent,
    Value<String?>? lastMessageType,
    Value<String?>? lastMessageSenderName,
    Value<String?>? lastMessageSenderId,
    Value<DateTime?>? lastMessageAt,
    Value<int>? unreadCount,
    Value<bool>? isMuted,
    Value<bool>? isPinned,
    Value<String?>? membersJson,
    Value<String?>? metadataJson,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalConversationsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      groupId: groupId ?? this.groupId,
      channelId: channelId ?? this.channelId,
      title: title ?? this.title,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSenderName:
          lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      membersJson: membersJson ?? this.membersJson,
      metadataJson: metadataJson ?? this.metadataJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String>(lastMessageId.value);
    }
    if (lastMessageContent.present) {
      map['last_message_content'] = Variable<String>(lastMessageContent.value);
    }
    if (lastMessageType.present) {
      map['last_message_type'] = Variable<String>(lastMessageType.value);
    }
    if (lastMessageSenderName.present) {
      map['last_message_sender_name'] = Variable<String>(
        lastMessageSenderName.value,
      );
    }
    if (lastMessageSenderId.present) {
      map['last_message_sender_id'] = Variable<String>(
        lastMessageSenderId.value,
      );
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (isMuted.present) {
      map['is_muted'] = Variable<bool>(isMuted.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (membersJson.present) {
      map['members_json'] = Variable<String>(membersJson.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalConversationsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('groupId: $groupId, ')
          ..write('channelId: $channelId, ')
          ..write('title: $title, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessageContent: $lastMessageContent, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageSenderName: $lastMessageSenderName, ')
          ..write('lastMessageSenderId: $lastMessageSenderId, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('isMuted: $isMuted, ')
          ..write('isPinned: $isPinned, ')
          ..write('membersJson: $membersJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMessagesTable extends LocalMessages
    with TableInfo<$LocalMessagesTable, LocalMessageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderUsernameMeta = const VerificationMeta(
    'senderUsername',
  );
  @override
  late final GeneratedColumn<String> senderUsername = GeneratedColumn<String>(
    'sender_username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senderDisplayNameMeta = const VerificationMeta(
    'senderDisplayName',
  );
  @override
  late final GeneratedColumn<String> senderDisplayName =
      GeneratedColumn<String>(
        'sender_display_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _senderAvatarUrlMeta = const VerificationMeta(
    'senderAvatarUrl',
  );
  @override
  late final GeneratedColumn<String> senderAvatarUrl = GeneratedColumn<String>(
    'sender_avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageTypeMeta = const VerificationMeta(
    'messageType',
  );
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
    'message_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('TEXT'),
  );
  static const VerificationMeta _replyToMessageIdMeta = const VerificationMeta(
    'replyToMessageId',
  );
  @override
  late final GeneratedColumn<String> replyToMessageId = GeneratedColumn<String>(
    'reply_to_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyToJsonMeta = const VerificationMeta(
    'replyToJson',
  );
  @override
  late final GeneratedColumn<String> replyToJson = GeneratedColumn<String>(
    'reply_to_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sent'),
  );
  static const VerificationMeta _isPendingSyncMeta = const VerificationMeta(
    'isPendingSync',
  );
  @override
  late final GeneratedColumn<bool> isPendingSync = GeneratedColumn<bool>(
    'is_pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEditedMeta = const VerificationMeta(
    'isEdited',
  );
  @override
  late final GeneratedColumn<bool> isEdited = GeneratedColumn<bool>(
    'is_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentUrlMeta = const VerificationMeta(
    'attachmentUrl',
  );
  @override
  late final GeneratedColumn<String> attachmentUrl = GeneratedColumn<String>(
    'attachment_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localAttachmentPathMeta =
      const VerificationMeta('localAttachmentPath');
  @override
  late final GeneratedColumn<String> localAttachmentPath =
      GeneratedColumn<String>(
        'local_attachment_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _attachmentsJsonMeta = const VerificationMeta(
    'attachmentsJson',
  );
  @override
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
    'attachments_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voiceNoteJsonMeta = const VerificationMeta(
    'voiceNoteJson',
  );
  @override
  late final GeneratedColumn<String> voiceNoteJson = GeneratedColumn<String>(
    'voice_note_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reactionsJsonMeta = const VerificationMeta(
    'reactionsJson',
  );
  @override
  late final GeneratedColumn<String> reactionsJson = GeneratedColumn<String>(
    'reactions_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readByJsonMeta = const VerificationMeta(
    'readByJson',
  );
  @override
  late final GeneratedColumn<String> readByJson = GeneratedColumn<String>(
    'read_by_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveredToJsonMeta = const VerificationMeta(
    'deliveredToJson',
  );
  @override
  late final GeneratedColumn<String> deliveredToJson = GeneratedColumn<String>(
    'delivered_to_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    serverId,
    clientId,
    conversationId,
    channelId,
    senderId,
    senderUsername,
    senderDisplayName,
    senderAvatarUrl,
    content,
    messageType,
    replyToMessageId,
    replyToJson,
    status,
    isPendingSync,
    isEdited,
    editedAt,
    isPinned,
    isDeleted,
    deletedAt,
    attachmentUrl,
    localAttachmentPath,
    attachmentsJson,
    voiceNoteJson,
    reactionsJson,
    readByJson,
    deliveredToJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMessageData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('sender_username')) {
      context.handle(
        _senderUsernameMeta,
        senderUsername.isAcceptableOrUnknown(
          data['sender_username']!,
          _senderUsernameMeta,
        ),
      );
    }
    if (data.containsKey('sender_display_name')) {
      context.handle(
        _senderDisplayNameMeta,
        senderDisplayName.isAcceptableOrUnknown(
          data['sender_display_name']!,
          _senderDisplayNameMeta,
        ),
      );
    }
    if (data.containsKey('sender_avatar_url')) {
      context.handle(
        _senderAvatarUrlMeta,
        senderAvatarUrl.isAcceptableOrUnknown(
          data['sender_avatar_url']!,
          _senderAvatarUrlMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('message_type')) {
      context.handle(
        _messageTypeMeta,
        messageType.isAcceptableOrUnknown(
          data['message_type']!,
          _messageTypeMeta,
        ),
      );
    }
    if (data.containsKey('reply_to_message_id')) {
      context.handle(
        _replyToMessageIdMeta,
        replyToMessageId.isAcceptableOrUnknown(
          data['reply_to_message_id']!,
          _replyToMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('reply_to_json')) {
      context.handle(
        _replyToJsonMeta,
        replyToJson.isAcceptableOrUnknown(
          data['reply_to_json']!,
          _replyToJsonMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_pending_sync')) {
      context.handle(
        _isPendingSyncMeta,
        isPendingSync.isAcceptableOrUnknown(
          data['is_pending_sync']!,
          _isPendingSyncMeta,
        ),
      );
    }
    if (data.containsKey('is_edited')) {
      context.handle(
        _isEditedMeta,
        isEdited.isAcceptableOrUnknown(data['is_edited']!, _isEditedMeta),
      );
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('attachment_url')) {
      context.handle(
        _attachmentUrlMeta,
        attachmentUrl.isAcceptableOrUnknown(
          data['attachment_url']!,
          _attachmentUrlMeta,
        ),
      );
    }
    if (data.containsKey('local_attachment_path')) {
      context.handle(
        _localAttachmentPathMeta,
        localAttachmentPath.isAcceptableOrUnknown(
          data['local_attachment_path']!,
          _localAttachmentPathMeta,
        ),
      );
    }
    if (data.containsKey('attachments_json')) {
      context.handle(
        _attachmentsJsonMeta,
        attachmentsJson.isAcceptableOrUnknown(
          data['attachments_json']!,
          _attachmentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('voice_note_json')) {
      context.handle(
        _voiceNoteJsonMeta,
        voiceNoteJson.isAcceptableOrUnknown(
          data['voice_note_json']!,
          _voiceNoteJsonMeta,
        ),
      );
    }
    if (data.containsKey('reactions_json')) {
      context.handle(
        _reactionsJsonMeta,
        reactionsJson.isAcceptableOrUnknown(
          data['reactions_json']!,
          _reactionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('read_by_json')) {
      context.handle(
        _readByJsonMeta,
        readByJson.isAcceptableOrUnknown(
          data['read_by_json']!,
          _readByJsonMeta,
        ),
      );
    }
    if (data.containsKey('delivered_to_json')) {
      context.handle(
        _deliveredToJsonMeta,
        deliveredToJson.isAcceptableOrUnknown(
          data['delivered_to_json']!,
          _deliveredToJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalMessageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessageData(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      ),
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      senderUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_username'],
      ),
      senderDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_display_name'],
      ),
      senderAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_avatar_url'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      messageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_type'],
      )!,
      replyToMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_message_id'],
      ),
      replyToJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_json'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isPendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_sync'],
      )!,
      isEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_edited'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}edited_at'],
      ),
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      attachmentUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_url'],
      ),
      localAttachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_attachment_path'],
      ),
      attachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments_json'],
      ),
      voiceNoteJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_note_json'],
      ),
      reactionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reactions_json'],
      ),
      readByJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}read_by_json'],
      ),
      deliveredToJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivered_to_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalMessagesTable createAlias(String alias) {
    return $LocalMessagesTable(attachedDatabase, alias);
  }
}

class LocalMessageData extends DataClass
    implements Insertable<LocalMessageData> {
  final String localId;
  final String? serverId;
  final String clientId;
  final String conversationId;
  final String? channelId;
  final String senderId;
  final String? senderUsername;
  final String? senderDisplayName;
  final String? senderAvatarUrl;
  final String? content;
  final String messageType;
  final String? replyToMessageId;
  final String? replyToJson;
  final String status;
  final bool isPendingSync;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isPinned;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? attachmentUrl;
  final String? localAttachmentPath;
  final String? attachmentsJson;
  final String? voiceNoteJson;
  final String? reactionsJson;
  final String? readByJson;
  final String? deliveredToJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalMessageData({
    required this.localId,
    this.serverId,
    required this.clientId,
    required this.conversationId,
    this.channelId,
    required this.senderId,
    this.senderUsername,
    this.senderDisplayName,
    this.senderAvatarUrl,
    this.content,
    required this.messageType,
    this.replyToMessageId,
    this.replyToJson,
    required this.status,
    required this.isPendingSync,
    required this.isEdited,
    this.editedAt,
    required this.isPinned,
    required this.isDeleted,
    this.deletedAt,
    this.attachmentUrl,
    this.localAttachmentPath,
    this.attachmentsJson,
    this.voiceNoteJson,
    this.reactionsJson,
    this.readByJson,
    this.deliveredToJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['client_id'] = Variable<String>(clientId);
    map['conversation_id'] = Variable<String>(conversationId);
    if (!nullToAbsent || channelId != null) {
      map['channel_id'] = Variable<String>(channelId);
    }
    map['sender_id'] = Variable<String>(senderId);
    if (!nullToAbsent || senderUsername != null) {
      map['sender_username'] = Variable<String>(senderUsername);
    }
    if (!nullToAbsent || senderDisplayName != null) {
      map['sender_display_name'] = Variable<String>(senderDisplayName);
    }
    if (!nullToAbsent || senderAvatarUrl != null) {
      map['sender_avatar_url'] = Variable<String>(senderAvatarUrl);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['message_type'] = Variable<String>(messageType);
    if (!nullToAbsent || replyToMessageId != null) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId);
    }
    if (!nullToAbsent || replyToJson != null) {
      map['reply_to_json'] = Variable<String>(replyToJson);
    }
    map['status'] = Variable<String>(status);
    map['is_pending_sync'] = Variable<bool>(isPendingSync);
    map['is_edited'] = Variable<bool>(isEdited);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<DateTime>(editedAt);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || attachmentUrl != null) {
      map['attachment_url'] = Variable<String>(attachmentUrl);
    }
    if (!nullToAbsent || localAttachmentPath != null) {
      map['local_attachment_path'] = Variable<String>(localAttachmentPath);
    }
    if (!nullToAbsent || attachmentsJson != null) {
      map['attachments_json'] = Variable<String>(attachmentsJson);
    }
    if (!nullToAbsent || voiceNoteJson != null) {
      map['voice_note_json'] = Variable<String>(voiceNoteJson);
    }
    if (!nullToAbsent || reactionsJson != null) {
      map['reactions_json'] = Variable<String>(reactionsJson);
    }
    if (!nullToAbsent || readByJson != null) {
      map['read_by_json'] = Variable<String>(readByJson);
    }
    if (!nullToAbsent || deliveredToJson != null) {
      map['delivered_to_json'] = Variable<String>(deliveredToJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalMessagesCompanion toCompanion(bool nullToAbsent) {
    return LocalMessagesCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      clientId: Value(clientId),
      conversationId: Value(conversationId),
      channelId: channelId == null && nullToAbsent
          ? const Value.absent()
          : Value(channelId),
      senderId: Value(senderId),
      senderUsername: senderUsername == null && nullToAbsent
          ? const Value.absent()
          : Value(senderUsername),
      senderDisplayName: senderDisplayName == null && nullToAbsent
          ? const Value.absent()
          : Value(senderDisplayName),
      senderAvatarUrl: senderAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(senderAvatarUrl),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      messageType: Value(messageType),
      replyToMessageId: replyToMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToMessageId),
      replyToJson: replyToJson == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToJson),
      status: Value(status),
      isPendingSync: Value(isPendingSync),
      isEdited: Value(isEdited),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      isPinned: Value(isPinned),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      attachmentUrl: attachmentUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentUrl),
      localAttachmentPath: localAttachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localAttachmentPath),
      attachmentsJson: attachmentsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentsJson),
      voiceNoteJson: voiceNoteJson == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceNoteJson),
      reactionsJson: reactionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(reactionsJson),
      readByJson: readByJson == null && nullToAbsent
          ? const Value.absent()
          : Value(readByJson),
      deliveredToJson: deliveredToJson == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredToJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMessageData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessageData(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      clientId: serializer.fromJson<String>(json['clientId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      channelId: serializer.fromJson<String?>(json['channelId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      senderUsername: serializer.fromJson<String?>(json['senderUsername']),
      senderDisplayName: serializer.fromJson<String?>(
        json['senderDisplayName'],
      ),
      senderAvatarUrl: serializer.fromJson<String?>(json['senderAvatarUrl']),
      content: serializer.fromJson<String?>(json['content']),
      messageType: serializer.fromJson<String>(json['messageType']),
      replyToMessageId: serializer.fromJson<String?>(json['replyToMessageId']),
      replyToJson: serializer.fromJson<String?>(json['replyToJson']),
      status: serializer.fromJson<String>(json['status']),
      isPendingSync: serializer.fromJson<bool>(json['isPendingSync']),
      isEdited: serializer.fromJson<bool>(json['isEdited']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      attachmentUrl: serializer.fromJson<String?>(json['attachmentUrl']),
      localAttachmentPath: serializer.fromJson<String?>(
        json['localAttachmentPath'],
      ),
      attachmentsJson: serializer.fromJson<String?>(json['attachmentsJson']),
      voiceNoteJson: serializer.fromJson<String?>(json['voiceNoteJson']),
      reactionsJson: serializer.fromJson<String?>(json['reactionsJson']),
      readByJson: serializer.fromJson<String?>(json['readByJson']),
      deliveredToJson: serializer.fromJson<String?>(json['deliveredToJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'clientId': serializer.toJson<String>(clientId),
      'conversationId': serializer.toJson<String>(conversationId),
      'channelId': serializer.toJson<String?>(channelId),
      'senderId': serializer.toJson<String>(senderId),
      'senderUsername': serializer.toJson<String?>(senderUsername),
      'senderDisplayName': serializer.toJson<String?>(senderDisplayName),
      'senderAvatarUrl': serializer.toJson<String?>(senderAvatarUrl),
      'content': serializer.toJson<String?>(content),
      'messageType': serializer.toJson<String>(messageType),
      'replyToMessageId': serializer.toJson<String?>(replyToMessageId),
      'replyToJson': serializer.toJson<String?>(replyToJson),
      'status': serializer.toJson<String>(status),
      'isPendingSync': serializer.toJson<bool>(isPendingSync),
      'isEdited': serializer.toJson<bool>(isEdited),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'attachmentUrl': serializer.toJson<String?>(attachmentUrl),
      'localAttachmentPath': serializer.toJson<String?>(localAttachmentPath),
      'attachmentsJson': serializer.toJson<String?>(attachmentsJson),
      'voiceNoteJson': serializer.toJson<String?>(voiceNoteJson),
      'reactionsJson': serializer.toJson<String?>(reactionsJson),
      'readByJson': serializer.toJson<String?>(readByJson),
      'deliveredToJson': serializer.toJson<String?>(deliveredToJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMessageData copyWith({
    String? localId,
    Value<String?> serverId = const Value.absent(),
    String? clientId,
    String? conversationId,
    Value<String?> channelId = const Value.absent(),
    String? senderId,
    Value<String?> senderUsername = const Value.absent(),
    Value<String?> senderDisplayName = const Value.absent(),
    Value<String?> senderAvatarUrl = const Value.absent(),
    Value<String?> content = const Value.absent(),
    String? messageType,
    Value<String?> replyToMessageId = const Value.absent(),
    Value<String?> replyToJson = const Value.absent(),
    String? status,
    bool? isPendingSync,
    bool? isEdited,
    Value<DateTime?> editedAt = const Value.absent(),
    bool? isPinned,
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> attachmentUrl = const Value.absent(),
    Value<String?> localAttachmentPath = const Value.absent(),
    Value<String?> attachmentsJson = const Value.absent(),
    Value<String?> voiceNoteJson = const Value.absent(),
    Value<String?> reactionsJson = const Value.absent(),
    Value<String?> readByJson = const Value.absent(),
    Value<String?> deliveredToJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalMessageData(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    clientId: clientId ?? this.clientId,
    conversationId: conversationId ?? this.conversationId,
    channelId: channelId.present ? channelId.value : this.channelId,
    senderId: senderId ?? this.senderId,
    senderUsername: senderUsername.present
        ? senderUsername.value
        : this.senderUsername,
    senderDisplayName: senderDisplayName.present
        ? senderDisplayName.value
        : this.senderDisplayName,
    senderAvatarUrl: senderAvatarUrl.present
        ? senderAvatarUrl.value
        : this.senderAvatarUrl,
    content: content.present ? content.value : this.content,
    messageType: messageType ?? this.messageType,
    replyToMessageId: replyToMessageId.present
        ? replyToMessageId.value
        : this.replyToMessageId,
    replyToJson: replyToJson.present ? replyToJson.value : this.replyToJson,
    status: status ?? this.status,
    isPendingSync: isPendingSync ?? this.isPendingSync,
    isEdited: isEdited ?? this.isEdited,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    isPinned: isPinned ?? this.isPinned,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    attachmentUrl: attachmentUrl.present
        ? attachmentUrl.value
        : this.attachmentUrl,
    localAttachmentPath: localAttachmentPath.present
        ? localAttachmentPath.value
        : this.localAttachmentPath,
    attachmentsJson: attachmentsJson.present
        ? attachmentsJson.value
        : this.attachmentsJson,
    voiceNoteJson: voiceNoteJson.present
        ? voiceNoteJson.value
        : this.voiceNoteJson,
    reactionsJson: reactionsJson.present
        ? reactionsJson.value
        : this.reactionsJson,
    readByJson: readByJson.present ? readByJson.value : this.readByJson,
    deliveredToJson: deliveredToJson.present
        ? deliveredToJson.value
        : this.deliveredToJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMessageData copyWithCompanion(LocalMessagesCompanion data) {
    return LocalMessageData(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderUsername: data.senderUsername.present
          ? data.senderUsername.value
          : this.senderUsername,
      senderDisplayName: data.senderDisplayName.present
          ? data.senderDisplayName.value
          : this.senderDisplayName,
      senderAvatarUrl: data.senderAvatarUrl.present
          ? data.senderAvatarUrl.value
          : this.senderAvatarUrl,
      content: data.content.present ? data.content.value : this.content,
      messageType: data.messageType.present
          ? data.messageType.value
          : this.messageType,
      replyToMessageId: data.replyToMessageId.present
          ? data.replyToMessageId.value
          : this.replyToMessageId,
      replyToJson: data.replyToJson.present
          ? data.replyToJson.value
          : this.replyToJson,
      status: data.status.present ? data.status.value : this.status,
      isPendingSync: data.isPendingSync.present
          ? data.isPendingSync.value
          : this.isPendingSync,
      isEdited: data.isEdited.present ? data.isEdited.value : this.isEdited,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      attachmentUrl: data.attachmentUrl.present
          ? data.attachmentUrl.value
          : this.attachmentUrl,
      localAttachmentPath: data.localAttachmentPath.present
          ? data.localAttachmentPath.value
          : this.localAttachmentPath,
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
      voiceNoteJson: data.voiceNoteJson.present
          ? data.voiceNoteJson.value
          : this.voiceNoteJson,
      reactionsJson: data.reactionsJson.present
          ? data.reactionsJson.value
          : this.reactionsJson,
      readByJson: data.readByJson.present
          ? data.readByJson.value
          : this.readByJson,
      deliveredToJson: data.deliveredToJson.present
          ? data.deliveredToJson.value
          : this.deliveredToJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessageData(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('clientId: $clientId, ')
          ..write('conversationId: $conversationId, ')
          ..write('channelId: $channelId, ')
          ..write('senderId: $senderId, ')
          ..write('senderUsername: $senderUsername, ')
          ..write('senderDisplayName: $senderDisplayName, ')
          ..write('senderAvatarUrl: $senderAvatarUrl, ')
          ..write('content: $content, ')
          ..write('messageType: $messageType, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('replyToJson: $replyToJson, ')
          ..write('status: $status, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('isEdited: $isEdited, ')
          ..write('editedAt: $editedAt, ')
          ..write('isPinned: $isPinned, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('attachmentUrl: $attachmentUrl, ')
          ..write('localAttachmentPath: $localAttachmentPath, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('voiceNoteJson: $voiceNoteJson, ')
          ..write('reactionsJson: $reactionsJson, ')
          ..write('readByJson: $readByJson, ')
          ..write('deliveredToJson: $deliveredToJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    localId,
    serverId,
    clientId,
    conversationId,
    channelId,
    senderId,
    senderUsername,
    senderDisplayName,
    senderAvatarUrl,
    content,
    messageType,
    replyToMessageId,
    replyToJson,
    status,
    isPendingSync,
    isEdited,
    editedAt,
    isPinned,
    isDeleted,
    deletedAt,
    attachmentUrl,
    localAttachmentPath,
    attachmentsJson,
    voiceNoteJson,
    reactionsJson,
    readByJson,
    deliveredToJson,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessageData &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.clientId == this.clientId &&
          other.conversationId == this.conversationId &&
          other.channelId == this.channelId &&
          other.senderId == this.senderId &&
          other.senderUsername == this.senderUsername &&
          other.senderDisplayName == this.senderDisplayName &&
          other.senderAvatarUrl == this.senderAvatarUrl &&
          other.content == this.content &&
          other.messageType == this.messageType &&
          other.replyToMessageId == this.replyToMessageId &&
          other.replyToJson == this.replyToJson &&
          other.status == this.status &&
          other.isPendingSync == this.isPendingSync &&
          other.isEdited == this.isEdited &&
          other.editedAt == this.editedAt &&
          other.isPinned == this.isPinned &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.attachmentUrl == this.attachmentUrl &&
          other.localAttachmentPath == this.localAttachmentPath &&
          other.attachmentsJson == this.attachmentsJson &&
          other.voiceNoteJson == this.voiceNoteJson &&
          other.reactionsJson == this.reactionsJson &&
          other.readByJson == this.readByJson &&
          other.deliveredToJson == this.deliveredToJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalMessagesCompanion extends UpdateCompanion<LocalMessageData> {
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String> clientId;
  final Value<String> conversationId;
  final Value<String?> channelId;
  final Value<String> senderId;
  final Value<String?> senderUsername;
  final Value<String?> senderDisplayName;
  final Value<String?> senderAvatarUrl;
  final Value<String?> content;
  final Value<String> messageType;
  final Value<String?> replyToMessageId;
  final Value<String?> replyToJson;
  final Value<String> status;
  final Value<bool> isPendingSync;
  final Value<bool> isEdited;
  final Value<DateTime?> editedAt;
  final Value<bool> isPinned;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<String?> attachmentUrl;
  final Value<String?> localAttachmentPath;
  final Value<String?> attachmentsJson;
  final Value<String?> voiceNoteJson;
  final Value<String?> reactionsJson;
  final Value<String?> readByJson;
  final Value<String?> deliveredToJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalMessagesCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderUsername = const Value.absent(),
    this.senderDisplayName = const Value.absent(),
    this.senderAvatarUrl = const Value.absent(),
    this.content = const Value.absent(),
    this.messageType = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.replyToJson = const Value.absent(),
    this.status = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.attachmentUrl = const Value.absent(),
    this.localAttachmentPath = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.voiceNoteJson = const Value.absent(),
    this.reactionsJson = const Value.absent(),
    this.readByJson = const Value.absent(),
    this.deliveredToJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMessagesCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String clientId,
    required String conversationId,
    this.channelId = const Value.absent(),
    required String senderId,
    this.senderUsername = const Value.absent(),
    this.senderDisplayName = const Value.absent(),
    this.senderAvatarUrl = const Value.absent(),
    this.content = const Value.absent(),
    this.messageType = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.replyToJson = const Value.absent(),
    this.status = const Value.absent(),
    this.isPendingSync = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.attachmentUrl = const Value.absent(),
    this.localAttachmentPath = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.voiceNoteJson = const Value.absent(),
    this.reactionsJson = const Value.absent(),
    this.readByJson = const Value.absent(),
    this.deliveredToJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       clientId = Value(clientId),
       conversationId = Value(conversationId),
       senderId = Value(senderId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMessageData> custom({
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? clientId,
    Expression<String>? conversationId,
    Expression<String>? channelId,
    Expression<String>? senderId,
    Expression<String>? senderUsername,
    Expression<String>? senderDisplayName,
    Expression<String>? senderAvatarUrl,
    Expression<String>? content,
    Expression<String>? messageType,
    Expression<String>? replyToMessageId,
    Expression<String>? replyToJson,
    Expression<String>? status,
    Expression<bool>? isPendingSync,
    Expression<bool>? isEdited,
    Expression<DateTime>? editedAt,
    Expression<bool>? isPinned,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<String>? attachmentUrl,
    Expression<String>? localAttachmentPath,
    Expression<String>? attachmentsJson,
    Expression<String>? voiceNoteJson,
    Expression<String>? reactionsJson,
    Expression<String>? readByJson,
    Expression<String>? deliveredToJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (clientId != null) 'client_id': clientId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (channelId != null) 'channel_id': channelId,
      if (senderId != null) 'sender_id': senderId,
      if (senderUsername != null) 'sender_username': senderUsername,
      if (senderDisplayName != null) 'sender_display_name': senderDisplayName,
      if (senderAvatarUrl != null) 'sender_avatar_url': senderAvatarUrl,
      if (content != null) 'content': content,
      if (messageType != null) 'message_type': messageType,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (replyToJson != null) 'reply_to_json': replyToJson,
      if (status != null) 'status': status,
      if (isPendingSync != null) 'is_pending_sync': isPendingSync,
      if (isEdited != null) 'is_edited': isEdited,
      if (editedAt != null) 'edited_at': editedAt,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (localAttachmentPath != null)
        'local_attachment_path': localAttachmentPath,
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (voiceNoteJson != null) 'voice_note_json': voiceNoteJson,
      if (reactionsJson != null) 'reactions_json': reactionsJson,
      if (readByJson != null) 'read_by_json': readByJson,
      if (deliveredToJson != null) 'delivered_to_json': deliveredToJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMessagesCompanion copyWith({
    Value<String>? localId,
    Value<String?>? serverId,
    Value<String>? clientId,
    Value<String>? conversationId,
    Value<String?>? channelId,
    Value<String>? senderId,
    Value<String?>? senderUsername,
    Value<String?>? senderDisplayName,
    Value<String?>? senderAvatarUrl,
    Value<String?>? content,
    Value<String>? messageType,
    Value<String?>? replyToMessageId,
    Value<String?>? replyToJson,
    Value<String>? status,
    Value<bool>? isPendingSync,
    Value<bool>? isEdited,
    Value<DateTime?>? editedAt,
    Value<bool>? isPinned,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<String?>? attachmentUrl,
    Value<String?>? localAttachmentPath,
    Value<String?>? attachmentsJson,
    Value<String?>? voiceNoteJson,
    Value<String?>? reactionsJson,
    Value<String?>? readByJson,
    Value<String?>? deliveredToJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalMessagesCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      clientId: clientId ?? this.clientId,
      conversationId: conversationId ?? this.conversationId,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToJson: replyToJson ?? this.replyToJson,
      status: status ?? this.status,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      localAttachmentPath: localAttachmentPath ?? this.localAttachmentPath,
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      voiceNoteJson: voiceNoteJson ?? this.voiceNoteJson,
      reactionsJson: reactionsJson ?? this.reactionsJson,
      readByJson: readByJson ?? this.readByJson,
      deliveredToJson: deliveredToJson ?? this.deliveredToJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (senderUsername.present) {
      map['sender_username'] = Variable<String>(senderUsername.value);
    }
    if (senderDisplayName.present) {
      map['sender_display_name'] = Variable<String>(senderDisplayName.value);
    }
    if (senderAvatarUrl.present) {
      map['sender_avatar_url'] = Variable<String>(senderAvatarUrl.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (replyToMessageId.present) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId.value);
    }
    if (replyToJson.present) {
      map['reply_to_json'] = Variable<String>(replyToJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isPendingSync.present) {
      map['is_pending_sync'] = Variable<bool>(isPendingSync.value);
    }
    if (isEdited.present) {
      map['is_edited'] = Variable<bool>(isEdited.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (attachmentUrl.present) {
      map['attachment_url'] = Variable<String>(attachmentUrl.value);
    }
    if (localAttachmentPath.present) {
      map['local_attachment_path'] = Variable<String>(
        localAttachmentPath.value,
      );
    }
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
    }
    if (voiceNoteJson.present) {
      map['voice_note_json'] = Variable<String>(voiceNoteJson.value);
    }
    if (reactionsJson.present) {
      map['reactions_json'] = Variable<String>(reactionsJson.value);
    }
    if (readByJson.present) {
      map['read_by_json'] = Variable<String>(readByJson.value);
    }
    if (deliveredToJson.present) {
      map['delivered_to_json'] = Variable<String>(deliveredToJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessagesCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('clientId: $clientId, ')
          ..write('conversationId: $conversationId, ')
          ..write('channelId: $channelId, ')
          ..write('senderId: $senderId, ')
          ..write('senderUsername: $senderUsername, ')
          ..write('senderDisplayName: $senderDisplayName, ')
          ..write('senderAvatarUrl: $senderAvatarUrl, ')
          ..write('content: $content, ')
          ..write('messageType: $messageType, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('replyToJson: $replyToJson, ')
          ..write('status: $status, ')
          ..write('isPendingSync: $isPendingSync, ')
          ..write('isEdited: $isEdited, ')
          ..write('editedAt: $editedAt, ')
          ..write('isPinned: $isPinned, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('attachmentUrl: $attachmentUrl, ')
          ..write('localAttachmentPath: $localAttachmentPath, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('voiceNoteJson: $voiceNoteJson, ')
          ..write('reactionsJson: $reactionsJson, ')
          ..write('readByJson: $readByJson, ')
          ..write('deliveredToJson: $deliveredToJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMessageAttachmentsTable extends LocalMessageAttachments
    with TableInfo<$LocalMessageAttachmentsTable, LocalMessageAttachmentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessageAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageLocalIdMeta = const VerificationMeta(
    'messageLocalId',
  );
  @override
  late final GeneratedColumn<String> messageLocalId = GeneratedColumn<String>(
    'message_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteUrlMeta = const VerificationMeta(
    'remoteUrl',
  );
  @override
  late final GeneratedColumn<String> remoteUrl = GeneratedColumn<String>(
    'remote_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localAttachmentPathMeta =
      const VerificationMeta('localAttachmentPath');
  @override
  late final GeneratedColumn<String> localAttachmentPath =
      GeneratedColumn<String>(
        'local_attachment_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IMAGE'),
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _uploadStatusMeta = const VerificationMeta(
    'uploadStatus',
  );
  @override
  late final GeneratedColumn<String> uploadStatus = GeneratedColumn<String>(
    'upload_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('uploaded'),
  );
  static const VerificationMeta _downloadStatusMeta = const VerificationMeta(
    'downloadStatus',
  );
  @override
  late final GeneratedColumn<String> downloadStatus = GeneratedColumn<String>(
    'download_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('not_downloaded'),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messageLocalId,
    fileId,
    remoteUrl,
    localAttachmentPath,
    fileType,
    mimeType,
    originalName,
    fileSize,
    uploadStatus,
    downloadStatus,
    width,
    height,
    duration,
    thumbnailUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_message_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMessageAttachmentData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('message_local_id')) {
      context.handle(
        _messageLocalIdMeta,
        messageLocalId.isAcceptableOrUnknown(
          data['message_local_id']!,
          _messageLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageLocalIdMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    }
    if (data.containsKey('remote_url')) {
      context.handle(
        _remoteUrlMeta,
        remoteUrl.isAcceptableOrUnknown(data['remote_url']!, _remoteUrlMeta),
      );
    }
    if (data.containsKey('local_attachment_path')) {
      context.handle(
        _localAttachmentPathMeta,
        localAttachmentPath.isAcceptableOrUnknown(
          data['local_attachment_path']!,
          _localAttachmentPathMeta,
        ),
      );
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('upload_status')) {
      context.handle(
        _uploadStatusMeta,
        uploadStatus.isAcceptableOrUnknown(
          data['upload_status']!,
          _uploadStatusMeta,
        ),
      );
    }
    if (data.containsKey('download_status')) {
      context.handle(
        _downloadStatusMeta,
        downloadStatus.isAcceptableOrUnknown(
          data['download_status']!,
          _downloadStatusMeta,
        ),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMessageAttachmentData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessageAttachmentData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      messageLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_local_id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      ),
      remoteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_url'],
      ),
      localAttachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_attachment_path'],
      ),
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      uploadStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_status'],
      )!,
      downloadStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_status'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
    );
  }

  @override
  $LocalMessageAttachmentsTable createAlias(String alias) {
    return $LocalMessageAttachmentsTable(attachedDatabase, alias);
  }
}

class LocalMessageAttachmentData extends DataClass
    implements Insertable<LocalMessageAttachmentData> {
  final String id;
  final String messageLocalId;
  final String? fileId;
  final String? remoteUrl;
  final String? localAttachmentPath;
  final String fileType;
  final String mimeType;
  final String originalName;
  final int fileSize;
  final String uploadStatus;
  final String downloadStatus;
  final int? width;
  final int? height;
  final double? duration;
  final String? thumbnailUrl;
  const LocalMessageAttachmentData({
    required this.id,
    required this.messageLocalId,
    this.fileId,
    this.remoteUrl,
    this.localAttachmentPath,
    required this.fileType,
    required this.mimeType,
    required this.originalName,
    required this.fileSize,
    required this.uploadStatus,
    required this.downloadStatus,
    this.width,
    this.height,
    this.duration,
    this.thumbnailUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['message_local_id'] = Variable<String>(messageLocalId);
    if (!nullToAbsent || fileId != null) {
      map['file_id'] = Variable<String>(fileId);
    }
    if (!nullToAbsent || remoteUrl != null) {
      map['remote_url'] = Variable<String>(remoteUrl);
    }
    if (!nullToAbsent || localAttachmentPath != null) {
      map['local_attachment_path'] = Variable<String>(localAttachmentPath);
    }
    map['file_type'] = Variable<String>(fileType);
    map['mime_type'] = Variable<String>(mimeType);
    map['original_name'] = Variable<String>(originalName);
    map['file_size'] = Variable<int>(fileSize);
    map['upload_status'] = Variable<String>(uploadStatus);
    map['download_status'] = Variable<String>(downloadStatus);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<double>(duration);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    return map;
  }

  LocalMessageAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return LocalMessageAttachmentsCompanion(
      id: Value(id),
      messageLocalId: Value(messageLocalId),
      fileId: fileId == null && nullToAbsent
          ? const Value.absent()
          : Value(fileId),
      remoteUrl: remoteUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUrl),
      localAttachmentPath: localAttachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localAttachmentPath),
      fileType: Value(fileType),
      mimeType: Value(mimeType),
      originalName: Value(originalName),
      fileSize: Value(fileSize),
      uploadStatus: Value(uploadStatus),
      downloadStatus: Value(downloadStatus),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
    );
  }

  factory LocalMessageAttachmentData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessageAttachmentData(
      id: serializer.fromJson<String>(json['id']),
      messageLocalId: serializer.fromJson<String>(json['messageLocalId']),
      fileId: serializer.fromJson<String?>(json['fileId']),
      remoteUrl: serializer.fromJson<String?>(json['remoteUrl']),
      localAttachmentPath: serializer.fromJson<String?>(
        json['localAttachmentPath'],
      ),
      fileType: serializer.fromJson<String>(json['fileType']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      originalName: serializer.fromJson<String>(json['originalName']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      uploadStatus: serializer.fromJson<String>(json['uploadStatus']),
      downloadStatus: serializer.fromJson<String>(json['downloadStatus']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      duration: serializer.fromJson<double?>(json['duration']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'messageLocalId': serializer.toJson<String>(messageLocalId),
      'fileId': serializer.toJson<String?>(fileId),
      'remoteUrl': serializer.toJson<String?>(remoteUrl),
      'localAttachmentPath': serializer.toJson<String?>(localAttachmentPath),
      'fileType': serializer.toJson<String>(fileType),
      'mimeType': serializer.toJson<String>(mimeType),
      'originalName': serializer.toJson<String>(originalName),
      'fileSize': serializer.toJson<int>(fileSize),
      'uploadStatus': serializer.toJson<String>(uploadStatus),
      'downloadStatus': serializer.toJson<String>(downloadStatus),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'duration': serializer.toJson<double?>(duration),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
    };
  }

  LocalMessageAttachmentData copyWith({
    String? id,
    String? messageLocalId,
    Value<String?> fileId = const Value.absent(),
    Value<String?> remoteUrl = const Value.absent(),
    Value<String?> localAttachmentPath = const Value.absent(),
    String? fileType,
    String? mimeType,
    String? originalName,
    int? fileSize,
    String? uploadStatus,
    String? downloadStatus,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<double?> duration = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
  }) => LocalMessageAttachmentData(
    id: id ?? this.id,
    messageLocalId: messageLocalId ?? this.messageLocalId,
    fileId: fileId.present ? fileId.value : this.fileId,
    remoteUrl: remoteUrl.present ? remoteUrl.value : this.remoteUrl,
    localAttachmentPath: localAttachmentPath.present
        ? localAttachmentPath.value
        : this.localAttachmentPath,
    fileType: fileType ?? this.fileType,
    mimeType: mimeType ?? this.mimeType,
    originalName: originalName ?? this.originalName,
    fileSize: fileSize ?? this.fileSize,
    uploadStatus: uploadStatus ?? this.uploadStatus,
    downloadStatus: downloadStatus ?? this.downloadStatus,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    duration: duration.present ? duration.value : this.duration,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
  );
  LocalMessageAttachmentData copyWithCompanion(
    LocalMessageAttachmentsCompanion data,
  ) {
    return LocalMessageAttachmentData(
      id: data.id.present ? data.id.value : this.id,
      messageLocalId: data.messageLocalId.present
          ? data.messageLocalId.value
          : this.messageLocalId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      remoteUrl: data.remoteUrl.present ? data.remoteUrl.value : this.remoteUrl,
      localAttachmentPath: data.localAttachmentPath.present
          ? data.localAttachmentPath.value
          : this.localAttachmentPath,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      uploadStatus: data.uploadStatus.present
          ? data.uploadStatus.value
          : this.uploadStatus,
      downloadStatus: data.downloadStatus.present
          ? data.downloadStatus.value
          : this.downloadStatus,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      duration: data.duration.present ? data.duration.value : this.duration,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessageAttachmentData(')
          ..write('id: $id, ')
          ..write('messageLocalId: $messageLocalId, ')
          ..write('fileId: $fileId, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('localAttachmentPath: $localAttachmentPath, ')
          ..write('fileType: $fileType, ')
          ..write('mimeType: $mimeType, ')
          ..write('originalName: $originalName, ')
          ..write('fileSize: $fileSize, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('downloadStatus: $downloadStatus, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('duration: $duration, ')
          ..write('thumbnailUrl: $thumbnailUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    messageLocalId,
    fileId,
    remoteUrl,
    localAttachmentPath,
    fileType,
    mimeType,
    originalName,
    fileSize,
    uploadStatus,
    downloadStatus,
    width,
    height,
    duration,
    thumbnailUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessageAttachmentData &&
          other.id == this.id &&
          other.messageLocalId == this.messageLocalId &&
          other.fileId == this.fileId &&
          other.remoteUrl == this.remoteUrl &&
          other.localAttachmentPath == this.localAttachmentPath &&
          other.fileType == this.fileType &&
          other.mimeType == this.mimeType &&
          other.originalName == this.originalName &&
          other.fileSize == this.fileSize &&
          other.uploadStatus == this.uploadStatus &&
          other.downloadStatus == this.downloadStatus &&
          other.width == this.width &&
          other.height == this.height &&
          other.duration == this.duration &&
          other.thumbnailUrl == this.thumbnailUrl);
}

class LocalMessageAttachmentsCompanion
    extends UpdateCompanion<LocalMessageAttachmentData> {
  final Value<String> id;
  final Value<String> messageLocalId;
  final Value<String?> fileId;
  final Value<String?> remoteUrl;
  final Value<String?> localAttachmentPath;
  final Value<String> fileType;
  final Value<String> mimeType;
  final Value<String> originalName;
  final Value<int> fileSize;
  final Value<String> uploadStatus;
  final Value<String> downloadStatus;
  final Value<int?> width;
  final Value<int?> height;
  final Value<double?> duration;
  final Value<String?> thumbnailUrl;
  final Value<int> rowid;
  const LocalMessageAttachmentsCompanion({
    this.id = const Value.absent(),
    this.messageLocalId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.localAttachmentPath = const Value.absent(),
    this.fileType = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.originalName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.downloadStatus = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMessageAttachmentsCompanion.insert({
    required String id,
    required String messageLocalId,
    this.fileId = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.localAttachmentPath = const Value.absent(),
    this.fileType = const Value.absent(),
    required String mimeType,
    required String originalName,
    this.fileSize = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.downloadStatus = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       messageLocalId = Value(messageLocalId),
       mimeType = Value(mimeType),
       originalName = Value(originalName);
  static Insertable<LocalMessageAttachmentData> custom({
    Expression<String>? id,
    Expression<String>? messageLocalId,
    Expression<String>? fileId,
    Expression<String>? remoteUrl,
    Expression<String>? localAttachmentPath,
    Expression<String>? fileType,
    Expression<String>? mimeType,
    Expression<String>? originalName,
    Expression<int>? fileSize,
    Expression<String>? uploadStatus,
    Expression<String>? downloadStatus,
    Expression<int>? width,
    Expression<int>? height,
    Expression<double>? duration,
    Expression<String>? thumbnailUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageLocalId != null) 'message_local_id': messageLocalId,
      if (fileId != null) 'file_id': fileId,
      if (remoteUrl != null) 'remote_url': remoteUrl,
      if (localAttachmentPath != null)
        'local_attachment_path': localAttachmentPath,
      if (fileType != null) 'file_type': fileType,
      if (mimeType != null) 'mime_type': mimeType,
      if (originalName != null) 'original_name': originalName,
      if (fileSize != null) 'file_size': fileSize,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (downloadStatus != null) 'download_status': downloadStatus,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (duration != null) 'duration': duration,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMessageAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? messageLocalId,
    Value<String?>? fileId,
    Value<String?>? remoteUrl,
    Value<String?>? localAttachmentPath,
    Value<String>? fileType,
    Value<String>? mimeType,
    Value<String>? originalName,
    Value<int>? fileSize,
    Value<String>? uploadStatus,
    Value<String>? downloadStatus,
    Value<int?>? width,
    Value<int?>? height,
    Value<double?>? duration,
    Value<String?>? thumbnailUrl,
    Value<int>? rowid,
  }) {
    return LocalMessageAttachmentsCompanion(
      id: id ?? this.id,
      messageLocalId: messageLocalId ?? this.messageLocalId,
      fileId: fileId ?? this.fileId,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      localAttachmentPath: localAttachmentPath ?? this.localAttachmentPath,
      fileType: fileType ?? this.fileType,
      mimeType: mimeType ?? this.mimeType,
      originalName: originalName ?? this.originalName,
      fileSize: fileSize ?? this.fileSize,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (messageLocalId.present) {
      map['message_local_id'] = Variable<String>(messageLocalId.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (remoteUrl.present) {
      map['remote_url'] = Variable<String>(remoteUrl.value);
    }
    if (localAttachmentPath.present) {
      map['local_attachment_path'] = Variable<String>(
        localAttachmentPath.value,
      );
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<String>(uploadStatus.value);
    }
    if (downloadStatus.present) {
      map['download_status'] = Variable<String>(downloadStatus.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (duration.present) {
      map['duration'] = Variable<double>(duration.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessageAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('messageLocalId: $messageLocalId, ')
          ..write('fileId: $fileId, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('localAttachmentPath: $localAttachmentPath, ')
          ..write('fileType: $fileType, ')
          ..write('mimeType: $mimeType, ')
          ..write('originalName: $originalName, ')
          ..write('fileSize: $fileSize, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('downloadStatus: $downloadStatus, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('duration: $duration, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalWatchHistoryTable extends LocalWatchHistory
    with TableInfo<$LocalWatchHistoryTable, LocalWatchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWatchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionSecondsMeta = const VerificationMeta(
    'positionSeconds',
  );
  @override
  late final GeneratedColumn<int> positionSeconds = GeneratedColumn<int>(
    'position_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastSyncAttemptAtMeta = const VerificationMeta(
    'lastSyncAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttemptAt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    videoId,
    userId,
    positionSeconds,
    durationSeconds,
    progress,
    watchedAt,
    completed,
    synced,
    lastSyncAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_watch_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalWatchHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('position_seconds')) {
      context.handle(
        _positionSecondsMeta,
        positionSeconds.isAcceptableOrUnknown(
          data['position_seconds']!,
          _positionSecondsMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_watchedAtMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('last_sync_attempt_at')) {
      context.handle(
        _lastSyncAttemptAtMeta,
        lastSyncAttemptAt.isAcceptableOrUnknown(
          data['last_sync_attempt_at']!,
          _lastSyncAttemptAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalWatchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWatchHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      positionSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_seconds'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      lastSyncAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt_at'],
      ),
    );
  }

  @override
  $LocalWatchHistoryTable createAlias(String alias) {
    return $LocalWatchHistoryTable(attachedDatabase, alias);
  }
}

class LocalWatchHistoryData extends DataClass
    implements Insertable<LocalWatchHistoryData> {
  final String id;
  final String videoId;
  final String userId;
  final int positionSeconds;
  final int durationSeconds;
  final double progress;
  final DateTime watchedAt;
  final bool completed;
  final bool synced;
  final DateTime? lastSyncAttemptAt;
  const LocalWatchHistoryData({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.progress,
    required this.watchedAt,
    required this.completed,
    required this.synced,
    this.lastSyncAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['video_id'] = Variable<String>(videoId);
    map['user_id'] = Variable<String>(userId);
    map['position_seconds'] = Variable<int>(positionSeconds);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['progress'] = Variable<double>(progress);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    map['completed'] = Variable<bool>(completed);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || lastSyncAttemptAt != null) {
      map['last_sync_attempt_at'] = Variable<DateTime>(lastSyncAttemptAt);
    }
    return map;
  }

  LocalWatchHistoryCompanion toCompanion(bool nullToAbsent) {
    return LocalWatchHistoryCompanion(
      id: Value(id),
      videoId: Value(videoId),
      userId: Value(userId),
      positionSeconds: Value(positionSeconds),
      durationSeconds: Value(durationSeconds),
      progress: Value(progress),
      watchedAt: Value(watchedAt),
      completed: Value(completed),
      synced: Value(synced),
      lastSyncAttemptAt: lastSyncAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttemptAt),
    );
  }

  factory LocalWatchHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWatchHistoryData(
      id: serializer.fromJson<String>(json['id']),
      videoId: serializer.fromJson<String>(json['videoId']),
      userId: serializer.fromJson<String>(json['userId']),
      positionSeconds: serializer.fromJson<int>(json['positionSeconds']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      progress: serializer.fromJson<double>(json['progress']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
      completed: serializer.fromJson<bool>(json['completed']),
      synced: serializer.fromJson<bool>(json['synced']),
      lastSyncAttemptAt: serializer.fromJson<DateTime?>(
        json['lastSyncAttemptAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'videoId': serializer.toJson<String>(videoId),
      'userId': serializer.toJson<String>(userId),
      'positionSeconds': serializer.toJson<int>(positionSeconds),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'progress': serializer.toJson<double>(progress),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
      'completed': serializer.toJson<bool>(completed),
      'synced': serializer.toJson<bool>(synced),
      'lastSyncAttemptAt': serializer.toJson<DateTime?>(lastSyncAttemptAt),
    };
  }

  LocalWatchHistoryData copyWith({
    String? id,
    String? videoId,
    String? userId,
    int? positionSeconds,
    int? durationSeconds,
    double? progress,
    DateTime? watchedAt,
    bool? completed,
    bool? synced,
    Value<DateTime?> lastSyncAttemptAt = const Value.absent(),
  }) => LocalWatchHistoryData(
    id: id ?? this.id,
    videoId: videoId ?? this.videoId,
    userId: userId ?? this.userId,
    positionSeconds: positionSeconds ?? this.positionSeconds,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    progress: progress ?? this.progress,
    watchedAt: watchedAt ?? this.watchedAt,
    completed: completed ?? this.completed,
    synced: synced ?? this.synced,
    lastSyncAttemptAt: lastSyncAttemptAt.present
        ? lastSyncAttemptAt.value
        : this.lastSyncAttemptAt,
  );
  LocalWatchHistoryData copyWithCompanion(LocalWatchHistoryCompanion data) {
    return LocalWatchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      userId: data.userId.present ? data.userId.value : this.userId,
      positionSeconds: data.positionSeconds.present
          ? data.positionSeconds.value
          : this.positionSeconds,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      progress: data.progress.present ? data.progress.value : this.progress,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
      completed: data.completed.present ? data.completed.value : this.completed,
      synced: data.synced.present ? data.synced.value : this.synced,
      lastSyncAttemptAt: data.lastSyncAttemptAt.present
          ? data.lastSyncAttemptAt.value
          : this.lastSyncAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWatchHistoryData(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('userId: $userId, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('progress: $progress, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('completed: $completed, ')
          ..write('synced: $synced, ')
          ..write('lastSyncAttemptAt: $lastSyncAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    videoId,
    userId,
    positionSeconds,
    durationSeconds,
    progress,
    watchedAt,
    completed,
    synced,
    lastSyncAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWatchHistoryData &&
          other.id == this.id &&
          other.videoId == this.videoId &&
          other.userId == this.userId &&
          other.positionSeconds == this.positionSeconds &&
          other.durationSeconds == this.durationSeconds &&
          other.progress == this.progress &&
          other.watchedAt == this.watchedAt &&
          other.completed == this.completed &&
          other.synced == this.synced &&
          other.lastSyncAttemptAt == this.lastSyncAttemptAt);
}

class LocalWatchHistoryCompanion
    extends UpdateCompanion<LocalWatchHistoryData> {
  final Value<String> id;
  final Value<String> videoId;
  final Value<String> userId;
  final Value<int> positionSeconds;
  final Value<int> durationSeconds;
  final Value<double> progress;
  final Value<DateTime> watchedAt;
  final Value<bool> completed;
  final Value<bool> synced;
  final Value<DateTime?> lastSyncAttemptAt;
  final Value<int> rowid;
  const LocalWatchHistoryCompanion({
    this.id = const Value.absent(),
    this.videoId = const Value.absent(),
    this.userId = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.progress = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.completed = const Value.absent(),
    this.synced = const Value.absent(),
    this.lastSyncAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalWatchHistoryCompanion.insert({
    required String id,
    required String videoId,
    required String userId,
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.progress = const Value.absent(),
    required DateTime watchedAt,
    this.completed = const Value.absent(),
    this.synced = const Value.absent(),
    this.lastSyncAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       videoId = Value(videoId),
       userId = Value(userId),
       watchedAt = Value(watchedAt);
  static Insertable<LocalWatchHistoryData> custom({
    Expression<String>? id,
    Expression<String>? videoId,
    Expression<String>? userId,
    Expression<int>? positionSeconds,
    Expression<int>? durationSeconds,
    Expression<double>? progress,
    Expression<DateTime>? watchedAt,
    Expression<bool>? completed,
    Expression<bool>? synced,
    Expression<DateTime>? lastSyncAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoId != null) 'video_id': videoId,
      if (userId != null) 'user_id': userId,
      if (positionSeconds != null) 'position_seconds': positionSeconds,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (progress != null) 'progress': progress,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (completed != null) 'completed': completed,
      if (synced != null) 'synced': synced,
      if (lastSyncAttemptAt != null) 'last_sync_attempt_at': lastSyncAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalWatchHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? videoId,
    Value<String>? userId,
    Value<int>? positionSeconds,
    Value<int>? durationSeconds,
    Value<double>? progress,
    Value<DateTime>? watchedAt,
    Value<bool>? completed,
    Value<bool>? synced,
    Value<DateTime?>? lastSyncAttemptAt,
    Value<int>? rowid,
  }) {
    return LocalWatchHistoryCompanion(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      progress: progress ?? this.progress,
      watchedAt: watchedAt ?? this.watchedAt,
      completed: completed ?? this.completed,
      synced: synced ?? this.synced,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (positionSeconds.present) {
      map['position_seconds'] = Variable<int>(positionSeconds.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (lastSyncAttemptAt.present) {
      map['last_sync_attempt_at'] = Variable<DateTime>(lastSyncAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWatchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('userId: $userId, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('progress: $progress, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('completed: $completed, ')
          ..write('synced: $synced, ')
          ..write('lastSyncAttemptAt: $lastSyncAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSearchHistoryTable extends LocalSearchHistory
    with TableInfo<$LocalSearchHistoryTable, LocalSearchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    query,
    category,
    userId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_search_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSearchHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSearchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSearchHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalSearchHistoryTable createAlias(String alias) {
    return $LocalSearchHistoryTable(attachedDatabase, alias);
  }
}

class LocalSearchHistoryData extends DataClass
    implements Insertable<LocalSearchHistoryData> {
  final String id;
  final String query;
  final String? category;
  final String? userId;
  final DateTime createdAt;
  const LocalSearchHistoryData({
    required this.id,
    required this.query,
    this.category,
    this.userId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['query'] = Variable<String>(query);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalSearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return LocalSearchHistoryCompanion(
      id: Value(id),
      query: Value(query),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      createdAt: Value(createdAt),
    );
  }

  factory LocalSearchHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSearchHistoryData(
      id: serializer.fromJson<String>(json['id']),
      query: serializer.fromJson<String>(json['query']),
      category: serializer.fromJson<String?>(json['category']),
      userId: serializer.fromJson<String?>(json['userId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'query': serializer.toJson<String>(query),
      'category': serializer.toJson<String?>(category),
      'userId': serializer.toJson<String?>(userId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalSearchHistoryData copyWith({
    String? id,
    String? query,
    Value<String?> category = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    DateTime? createdAt,
  }) => LocalSearchHistoryData(
    id: id ?? this.id,
    query: query ?? this.query,
    category: category.present ? category.value : this.category,
    userId: userId.present ? userId.value : this.userId,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalSearchHistoryData copyWithCompanion(LocalSearchHistoryCompanion data) {
    return LocalSearchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      query: data.query.present ? data.query.value : this.query,
      category: data.category.present ? data.category.value : this.category,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSearchHistoryData(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('category: $category, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, query, category, userId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSearchHistoryData &&
          other.id == this.id &&
          other.query == this.query &&
          other.category == this.category &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt);
}

class LocalSearchHistoryCompanion
    extends UpdateCompanion<LocalSearchHistoryData> {
  final Value<String> id;
  final Value<String> query;
  final Value<String?> category;
  final Value<String?> userId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalSearchHistoryCompanion({
    this.id = const Value.absent(),
    this.query = const Value.absent(),
    this.category = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSearchHistoryCompanion.insert({
    required String id,
    required String query,
    this.category = const Value.absent(),
    this.userId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       query = Value(query),
       createdAt = Value(createdAt);
  static Insertable<LocalSearchHistoryData> custom({
    Expression<String>? id,
    Expression<String>? query,
    Expression<String>? category,
    Expression<String>? userId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (query != null) 'query': query,
      if (category != null) 'category': category,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSearchHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? query,
    Value<String?>? category,
    Value<String?>? userId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalSearchHistoryCompanion(
      id: id ?? this.id,
      query: query ?? this.query,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSearchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('category: $category, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalFeedItemsTable extends LocalFeedItems
    with TableInfo<$LocalFeedItemsTable, LocalFeedItemData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFeedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedTypeMeta = const VerificationMeta(
    'feedType',
  );
  @override
  late final GeneratedColumn<String> feedType = GeneratedColumn<String>(
    'feed_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('HOME'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hlsUrlMeta = const VerificationMeta('hlsUrl');
  @override
  late final GeneratedColumn<String> hlsUrl = GeneratedColumn<String>(
    'hls_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorUsernameMeta = const VerificationMeta(
    'authorUsername',
  );
  @override
  late final GeneratedColumn<String> authorUsername = GeneratedColumn<String>(
    'author_username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorDisplayNameMeta = const VerificationMeta(
    'authorDisplayName',
  );
  @override
  late final GeneratedColumn<String> authorDisplayName =
      GeneratedColumn<String>(
        'author_display_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _authorAvatarUrlMeta = const VerificationMeta(
    'authorAvatarUrl',
  );
  @override
  late final GeneratedColumn<String> authorAvatarUrl = GeneratedColumn<String>(
    'author_avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _viewsCountMeta = const VerificationMeta(
    'viewsCount',
  );
  @override
  late final GeneratedColumn<int> viewsCount = GeneratedColumn<int>(
    'views_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _likesCountMeta = const VerificationMeta(
    'likesCount',
  );
  @override
  late final GeneratedColumn<int> likesCount = GeneratedColumn<int>(
    'likes_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _commentsCountMeta = const VerificationMeta(
    'commentsCount',
  );
  @override
  late final GeneratedColumn<int> commentsCount = GeneratedColumn<int>(
    'comments_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isLikedMeta = const VerificationMeta(
    'isLiked',
  );
  @override
  late final GeneratedColumn<bool> isLiked = GeneratedColumn<bool>(
    'is_liked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_liked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSavedMeta = const VerificationMeta(
    'isSaved',
  );
  @override
  late final GeneratedColumn<bool> isSaved = GeneratedColumn<bool>(
    'is_saved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_saved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    feedType,
    title,
    caption,
    thumbnailUrl,
    videoUrl,
    hlsUrl,
    duration,
    authorId,
    authorUsername,
    authorDisplayName,
    authorAvatarUrl,
    viewsCount,
    likesCount,
    commentsCount,
    isLiked,
    isSaved,
    publishedAt,
    createdAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_feed_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalFeedItemData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('feed_type')) {
      context.handle(
        _feedTypeMeta,
        feedType.isAcceptableOrUnknown(data['feed_type']!, _feedTypeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    if (data.containsKey('hls_url')) {
      context.handle(
        _hlsUrlMeta,
        hlsUrl.isAcceptableOrUnknown(data['hls_url']!, _hlsUrlMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    }
    if (data.containsKey('author_username')) {
      context.handle(
        _authorUsernameMeta,
        authorUsername.isAcceptableOrUnknown(
          data['author_username']!,
          _authorUsernameMeta,
        ),
      );
    }
    if (data.containsKey('author_display_name')) {
      context.handle(
        _authorDisplayNameMeta,
        authorDisplayName.isAcceptableOrUnknown(
          data['author_display_name']!,
          _authorDisplayNameMeta,
        ),
      );
    }
    if (data.containsKey('author_avatar_url')) {
      context.handle(
        _authorAvatarUrlMeta,
        authorAvatarUrl.isAcceptableOrUnknown(
          data['author_avatar_url']!,
          _authorAvatarUrlMeta,
        ),
      );
    }
    if (data.containsKey('views_count')) {
      context.handle(
        _viewsCountMeta,
        viewsCount.isAcceptableOrUnknown(data['views_count']!, _viewsCountMeta),
      );
    }
    if (data.containsKey('likes_count')) {
      context.handle(
        _likesCountMeta,
        likesCount.isAcceptableOrUnknown(data['likes_count']!, _likesCountMeta),
      );
    }
    if (data.containsKey('comments_count')) {
      context.handle(
        _commentsCountMeta,
        commentsCount.isAcceptableOrUnknown(
          data['comments_count']!,
          _commentsCountMeta,
        ),
      );
    }
    if (data.containsKey('is_liked')) {
      context.handle(
        _isLikedMeta,
        isLiked.isAcceptableOrUnknown(data['is_liked']!, _isLikedMeta),
      );
    }
    if (data.containsKey('is_saved')) {
      context.handle(
        _isSavedMeta,
        isSaved.isAcceptableOrUnknown(data['is_saved']!, _isSavedMeta),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalFeedItemData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFeedItemData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      feedType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      ),
      hlsUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hls_url'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      ),
      authorUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_username'],
      ),
      authorDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_display_name'],
      ),
      authorAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_avatar_url'],
      ),
      viewsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}views_count'],
      )!,
      likesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}likes_count'],
      )!,
      commentsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}comments_count'],
      )!,
      isLiked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_liked'],
      )!,
      isSaved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_saved'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $LocalFeedItemsTable createAlias(String alias) {
    return $LocalFeedItemsTable(attachedDatabase, alias);
  }
}

class LocalFeedItemData extends DataClass
    implements Insertable<LocalFeedItemData> {
  final String id;
  final String feedType;
  final String title;
  final String? caption;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? hlsUrl;
  final int duration;
  final String? authorId;
  final String? authorUsername;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime cachedAt;
  const LocalFeedItemData({
    required this.id,
    required this.feedType,
    required this.title,
    this.caption,
    this.thumbnailUrl,
    this.videoUrl,
    this.hlsUrl,
    required this.duration,
    this.authorId,
    this.authorUsername,
    this.authorDisplayName,
    this.authorAvatarUrl,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isSaved,
    this.publishedAt,
    required this.createdAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['feed_type'] = Variable<String>(feedType);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    if (!nullToAbsent || hlsUrl != null) {
      map['hls_url'] = Variable<String>(hlsUrl);
    }
    map['duration'] = Variable<int>(duration);
    if (!nullToAbsent || authorId != null) {
      map['author_id'] = Variable<String>(authorId);
    }
    if (!nullToAbsent || authorUsername != null) {
      map['author_username'] = Variable<String>(authorUsername);
    }
    if (!nullToAbsent || authorDisplayName != null) {
      map['author_display_name'] = Variable<String>(authorDisplayName);
    }
    if (!nullToAbsent || authorAvatarUrl != null) {
      map['author_avatar_url'] = Variable<String>(authorAvatarUrl);
    }
    map['views_count'] = Variable<int>(viewsCount);
    map['likes_count'] = Variable<int>(likesCount);
    map['comments_count'] = Variable<int>(commentsCount);
    map['is_liked'] = Variable<bool>(isLiked);
    map['is_saved'] = Variable<bool>(isSaved);
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  LocalFeedItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalFeedItemsCompanion(
      id: Value(id),
      feedType: Value(feedType),
      title: Value(title),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
      hlsUrl: hlsUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(hlsUrl),
      duration: Value(duration),
      authorId: authorId == null && nullToAbsent
          ? const Value.absent()
          : Value(authorId),
      authorUsername: authorUsername == null && nullToAbsent
          ? const Value.absent()
          : Value(authorUsername),
      authorDisplayName: authorDisplayName == null && nullToAbsent
          ? const Value.absent()
          : Value(authorDisplayName),
      authorAvatarUrl: authorAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(authorAvatarUrl),
      viewsCount: Value(viewsCount),
      likesCount: Value(likesCount),
      commentsCount: Value(commentsCount),
      isLiked: Value(isLiked),
      isSaved: Value(isSaved),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
      createdAt: Value(createdAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory LocalFeedItemData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFeedItemData(
      id: serializer.fromJson<String>(json['id']),
      feedType: serializer.fromJson<String>(json['feedType']),
      title: serializer.fromJson<String>(json['title']),
      caption: serializer.fromJson<String?>(json['caption']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
      hlsUrl: serializer.fromJson<String?>(json['hlsUrl']),
      duration: serializer.fromJson<int>(json['duration']),
      authorId: serializer.fromJson<String?>(json['authorId']),
      authorUsername: serializer.fromJson<String?>(json['authorUsername']),
      authorDisplayName: serializer.fromJson<String?>(
        json['authorDisplayName'],
      ),
      authorAvatarUrl: serializer.fromJson<String?>(json['authorAvatarUrl']),
      viewsCount: serializer.fromJson<int>(json['viewsCount']),
      likesCount: serializer.fromJson<int>(json['likesCount']),
      commentsCount: serializer.fromJson<int>(json['commentsCount']),
      isLiked: serializer.fromJson<bool>(json['isLiked']),
      isSaved: serializer.fromJson<bool>(json['isSaved']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'feedType': serializer.toJson<String>(feedType),
      'title': serializer.toJson<String>(title),
      'caption': serializer.toJson<String?>(caption),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'videoUrl': serializer.toJson<String?>(videoUrl),
      'hlsUrl': serializer.toJson<String?>(hlsUrl),
      'duration': serializer.toJson<int>(duration),
      'authorId': serializer.toJson<String?>(authorId),
      'authorUsername': serializer.toJson<String?>(authorUsername),
      'authorDisplayName': serializer.toJson<String?>(authorDisplayName),
      'authorAvatarUrl': serializer.toJson<String?>(authorAvatarUrl),
      'viewsCount': serializer.toJson<int>(viewsCount),
      'likesCount': serializer.toJson<int>(likesCount),
      'commentsCount': serializer.toJson<int>(commentsCount),
      'isLiked': serializer.toJson<bool>(isLiked),
      'isSaved': serializer.toJson<bool>(isSaved),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  LocalFeedItemData copyWith({
    String? id,
    String? feedType,
    String? title,
    Value<String?> caption = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    Value<String?> videoUrl = const Value.absent(),
    Value<String?> hlsUrl = const Value.absent(),
    int? duration,
    Value<String?> authorId = const Value.absent(),
    Value<String?> authorUsername = const Value.absent(),
    Value<String?> authorDisplayName = const Value.absent(),
    Value<String?> authorAvatarUrl = const Value.absent(),
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isSaved,
    Value<DateTime?> publishedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? cachedAt,
  }) => LocalFeedItemData(
    id: id ?? this.id,
    feedType: feedType ?? this.feedType,
    title: title ?? this.title,
    caption: caption.present ? caption.value : this.caption,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
    hlsUrl: hlsUrl.present ? hlsUrl.value : this.hlsUrl,
    duration: duration ?? this.duration,
    authorId: authorId.present ? authorId.value : this.authorId,
    authorUsername: authorUsername.present
        ? authorUsername.value
        : this.authorUsername,
    authorDisplayName: authorDisplayName.present
        ? authorDisplayName.value
        : this.authorDisplayName,
    authorAvatarUrl: authorAvatarUrl.present
        ? authorAvatarUrl.value
        : this.authorAvatarUrl,
    viewsCount: viewsCount ?? this.viewsCount,
    likesCount: likesCount ?? this.likesCount,
    commentsCount: commentsCount ?? this.commentsCount,
    isLiked: isLiked ?? this.isLiked,
    isSaved: isSaved ?? this.isSaved,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
    createdAt: createdAt ?? this.createdAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  LocalFeedItemData copyWithCompanion(LocalFeedItemsCompanion data) {
    return LocalFeedItemData(
      id: data.id.present ? data.id.value : this.id,
      feedType: data.feedType.present ? data.feedType.value : this.feedType,
      title: data.title.present ? data.title.value : this.title,
      caption: data.caption.present ? data.caption.value : this.caption,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      hlsUrl: data.hlsUrl.present ? data.hlsUrl.value : this.hlsUrl,
      duration: data.duration.present ? data.duration.value : this.duration,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      authorUsername: data.authorUsername.present
          ? data.authorUsername.value
          : this.authorUsername,
      authorDisplayName: data.authorDisplayName.present
          ? data.authorDisplayName.value
          : this.authorDisplayName,
      authorAvatarUrl: data.authorAvatarUrl.present
          ? data.authorAvatarUrl.value
          : this.authorAvatarUrl,
      viewsCount: data.viewsCount.present
          ? data.viewsCount.value
          : this.viewsCount,
      likesCount: data.likesCount.present
          ? data.likesCount.value
          : this.likesCount,
      commentsCount: data.commentsCount.present
          ? data.commentsCount.value
          : this.commentsCount,
      isLiked: data.isLiked.present ? data.isLiked.value : this.isLiked,
      isSaved: data.isSaved.present ? data.isSaved.value : this.isSaved,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFeedItemData(')
          ..write('id: $id, ')
          ..write('feedType: $feedType, ')
          ..write('title: $title, ')
          ..write('caption: $caption, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('hlsUrl: $hlsUrl, ')
          ..write('duration: $duration, ')
          ..write('authorId: $authorId, ')
          ..write('authorUsername: $authorUsername, ')
          ..write('authorDisplayName: $authorDisplayName, ')
          ..write('authorAvatarUrl: $authorAvatarUrl, ')
          ..write('viewsCount: $viewsCount, ')
          ..write('likesCount: $likesCount, ')
          ..write('commentsCount: $commentsCount, ')
          ..write('isLiked: $isLiked, ')
          ..write('isSaved: $isSaved, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    feedType,
    title,
    caption,
    thumbnailUrl,
    videoUrl,
    hlsUrl,
    duration,
    authorId,
    authorUsername,
    authorDisplayName,
    authorAvatarUrl,
    viewsCount,
    likesCount,
    commentsCount,
    isLiked,
    isSaved,
    publishedAt,
    createdAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFeedItemData &&
          other.id == this.id &&
          other.feedType == this.feedType &&
          other.title == this.title &&
          other.caption == this.caption &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.videoUrl == this.videoUrl &&
          other.hlsUrl == this.hlsUrl &&
          other.duration == this.duration &&
          other.authorId == this.authorId &&
          other.authorUsername == this.authorUsername &&
          other.authorDisplayName == this.authorDisplayName &&
          other.authorAvatarUrl == this.authorAvatarUrl &&
          other.viewsCount == this.viewsCount &&
          other.likesCount == this.likesCount &&
          other.commentsCount == this.commentsCount &&
          other.isLiked == this.isLiked &&
          other.isSaved == this.isSaved &&
          other.publishedAt == this.publishedAt &&
          other.createdAt == this.createdAt &&
          other.cachedAt == this.cachedAt);
}

class LocalFeedItemsCompanion extends UpdateCompanion<LocalFeedItemData> {
  final Value<String> id;
  final Value<String> feedType;
  final Value<String> title;
  final Value<String?> caption;
  final Value<String?> thumbnailUrl;
  final Value<String?> videoUrl;
  final Value<String?> hlsUrl;
  final Value<int> duration;
  final Value<String?> authorId;
  final Value<String?> authorUsername;
  final Value<String?> authorDisplayName;
  final Value<String?> authorAvatarUrl;
  final Value<int> viewsCount;
  final Value<int> likesCount;
  final Value<int> commentsCount;
  final Value<bool> isLiked;
  final Value<bool> isSaved;
  final Value<DateTime?> publishedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const LocalFeedItemsCompanion({
    this.id = const Value.absent(),
    this.feedType = const Value.absent(),
    this.title = const Value.absent(),
    this.caption = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.hlsUrl = const Value.absent(),
    this.duration = const Value.absent(),
    this.authorId = const Value.absent(),
    this.authorUsername = const Value.absent(),
    this.authorDisplayName = const Value.absent(),
    this.authorAvatarUrl = const Value.absent(),
    this.viewsCount = const Value.absent(),
    this.likesCount = const Value.absent(),
    this.commentsCount = const Value.absent(),
    this.isLiked = const Value.absent(),
    this.isSaved = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFeedItemsCompanion.insert({
    required String id,
    this.feedType = const Value.absent(),
    required String title,
    this.caption = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.hlsUrl = const Value.absent(),
    this.duration = const Value.absent(),
    this.authorId = const Value.absent(),
    this.authorUsername = const Value.absent(),
    this.authorDisplayName = const Value.absent(),
    this.authorAvatarUrl = const Value.absent(),
    this.viewsCount = const Value.absent(),
    this.likesCount = const Value.absent(),
    this.commentsCount = const Value.absent(),
    this.isLiked = const Value.absent(),
    this.isSaved = const Value.absent(),
    this.publishedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       cachedAt = Value(cachedAt);
  static Insertable<LocalFeedItemData> custom({
    Expression<String>? id,
    Expression<String>? feedType,
    Expression<String>? title,
    Expression<String>? caption,
    Expression<String>? thumbnailUrl,
    Expression<String>? videoUrl,
    Expression<String>? hlsUrl,
    Expression<int>? duration,
    Expression<String>? authorId,
    Expression<String>? authorUsername,
    Expression<String>? authorDisplayName,
    Expression<String>? authorAvatarUrl,
    Expression<int>? viewsCount,
    Expression<int>? likesCount,
    Expression<int>? commentsCount,
    Expression<bool>? isLiked,
    Expression<bool>? isSaved,
    Expression<DateTime>? publishedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (feedType != null) 'feed_type': feedType,
      if (title != null) 'title': title,
      if (caption != null) 'caption': caption,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      if (hlsUrl != null) 'hls_url': hlsUrl,
      if (duration != null) 'duration': duration,
      if (authorId != null) 'author_id': authorId,
      if (authorUsername != null) 'author_username': authorUsername,
      if (authorDisplayName != null) 'author_display_name': authorDisplayName,
      if (authorAvatarUrl != null) 'author_avatar_url': authorAvatarUrl,
      if (viewsCount != null) 'views_count': viewsCount,
      if (likesCount != null) 'likes_count': likesCount,
      if (commentsCount != null) 'comments_count': commentsCount,
      if (isLiked != null) 'is_liked': isLiked,
      if (isSaved != null) 'is_saved': isSaved,
      if (publishedAt != null) 'published_at': publishedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFeedItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? feedType,
    Value<String>? title,
    Value<String?>? caption,
    Value<String?>? thumbnailUrl,
    Value<String?>? videoUrl,
    Value<String?>? hlsUrl,
    Value<int>? duration,
    Value<String?>? authorId,
    Value<String?>? authorUsername,
    Value<String?>? authorDisplayName,
    Value<String?>? authorAvatarUrl,
    Value<int>? viewsCount,
    Value<int>? likesCount,
    Value<int>? commentsCount,
    Value<bool>? isLiked,
    Value<bool>? isSaved,
    Value<DateTime?>? publishedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return LocalFeedItemsCompanion(
      id: id ?? this.id,
      feedType: feedType ?? this.feedType,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      duration: duration ?? this.duration,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (feedType.present) {
      map['feed_type'] = Variable<String>(feedType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (hlsUrl.present) {
      map['hls_url'] = Variable<String>(hlsUrl.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (authorUsername.present) {
      map['author_username'] = Variable<String>(authorUsername.value);
    }
    if (authorDisplayName.present) {
      map['author_display_name'] = Variable<String>(authorDisplayName.value);
    }
    if (authorAvatarUrl.present) {
      map['author_avatar_url'] = Variable<String>(authorAvatarUrl.value);
    }
    if (viewsCount.present) {
      map['views_count'] = Variable<int>(viewsCount.value);
    }
    if (likesCount.present) {
      map['likes_count'] = Variable<int>(likesCount.value);
    }
    if (commentsCount.present) {
      map['comments_count'] = Variable<int>(commentsCount.value);
    }
    if (isLiked.present) {
      map['is_liked'] = Variable<bool>(isLiked.value);
    }
    if (isSaved.present) {
      map['is_saved'] = Variable<bool>(isSaved.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFeedItemsCompanion(')
          ..write('id: $id, ')
          ..write('feedType: $feedType, ')
          ..write('title: $title, ')
          ..write('caption: $caption, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('hlsUrl: $hlsUrl, ')
          ..write('duration: $duration, ')
          ..write('authorId: $authorId, ')
          ..write('authorUsername: $authorUsername, ')
          ..write('authorDisplayName: $authorDisplayName, ')
          ..write('authorAvatarUrl: $authorAvatarUrl, ')
          ..write('viewsCount: $viewsCount, ')
          ..write('likesCount: $likesCount, ')
          ..write('commentsCount: $commentsCount, ')
          ..write('isLiked: $isLiked, ')
          ..write('isSaved: $isSaved, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCalendarNotesTable extends LocalCalendarNotes
    with TableInfo<$LocalCalendarNotesTable, LocalCalendarNoteData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCalendarNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ethiopianYearMeta = const VerificationMeta(
    'ethiopianYear',
  );
  @override
  late final GeneratedColumn<int> ethiopianYear = GeneratedColumn<int>(
    'ethiopian_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ethiopianMonthMeta = const VerificationMeta(
    'ethiopianMonth',
  );
  @override
  late final GeneratedColumn<int> ethiopianMonth = GeneratedColumn<int>(
    'ethiopian_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ethiopianDayMeta = const VerificationMeta(
    'ethiopianDay',
  );
  @override
  late final GeneratedColumn<int> ethiopianDay = GeneratedColumn<int>(
    'ethiopian_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gregorianDateMeta = const VerificationMeta(
    'gregorianDate',
  );
  @override
  late final GeneratedColumn<DateTime> gregorianDate =
      GeneratedColumn<DateTime>(
        'gregorian_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasReminderMeta = const VerificationMeta(
    'hasReminder',
  );
  @override
  late final GeneratedColumn<bool> hasReminder = GeneratedColumn<bool>(
    'has_reminder',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_reminder" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderDateTimeMeta = const VerificationMeta(
    'reminderDateTime',
  );
  @override
  late final GeneratedColumn<DateTime> reminderDateTime =
      GeneratedColumn<DateTime>(
        'reminder_date_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reminderNotifiedMeta = const VerificationMeta(
    'reminderNotified',
  );
  @override
  late final GeneratedColumn<bool> reminderNotified = GeneratedColumn<bool>(
    'reminder_notified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_notified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderRepeatMeta = const VerificationMeta(
    'reminderRepeat',
  );
  @override
  late final GeneratedColumn<String> reminderRepeat = GeneratedColumn<String>(
    'reminder_repeat',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('NONE'),
  );
  static const VerificationMeta _reminderEthiopianMonthMeta =
      const VerificationMeta('reminderEthiopianMonth');
  @override
  late final GeneratedColumn<int> reminderEthiopianMonth = GeneratedColumn<int>(
    'reminder_ethiopian_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderEthiopianDayMeta =
      const VerificationMeta('reminderEthiopianDay');
  @override
  late final GeneratedColumn<int> reminderEthiopianDay = GeneratedColumn<int>(
    'reminder_ethiopian_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderHourMeta = const VerificationMeta(
    'reminderHour',
  );
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
    'reminder_hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderMinuteMeta = const VerificationMeta(
    'reminderMinute',
  );
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
    'reminder_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderTimezoneMeta = const VerificationMeta(
    'reminderTimezone',
  );
  @override
  late final GeneratedColumn<String> reminderTimezone = GeneratedColumn<String>(
    'reminder_timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Africa/Addis_Ababa'),
  );
  static const VerificationMeta _reminderNextOccurrenceMeta =
      const VerificationMeta('reminderNextOccurrence');
  @override
  late final GeneratedColumn<DateTime> reminderNextOccurrence =
      GeneratedColumn<DateTime>(
        'reminder_next_occurrence',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPendingDeleteMeta = const VerificationMeta(
    'isPendingDelete',
  );
  @override
  late final GeneratedColumn<bool> isPendingDelete = GeneratedColumn<bool>(
    'is_pending_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    ethiopianYear,
    ethiopianMonth,
    ethiopianDay,
    gregorianDate,
    title,
    content,
    hasReminder,
    reminderDateTime,
    reminderNotified,
    reminderRepeat,
    reminderEthiopianMonth,
    reminderEthiopianDay,
    reminderHour,
    reminderMinute,
    reminderTimezone,
    reminderNextOccurrence,
    createdAt,
    updatedAt,
    deletedAt,
    isSynced,
    isPendingDelete,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_calendar_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCalendarNoteData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('ethiopian_year')) {
      context.handle(
        _ethiopianYearMeta,
        ethiopianYear.isAcceptableOrUnknown(
          data['ethiopian_year']!,
          _ethiopianYearMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ethiopianYearMeta);
    }
    if (data.containsKey('ethiopian_month')) {
      context.handle(
        _ethiopianMonthMeta,
        ethiopianMonth.isAcceptableOrUnknown(
          data['ethiopian_month']!,
          _ethiopianMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ethiopianMonthMeta);
    }
    if (data.containsKey('ethiopian_day')) {
      context.handle(
        _ethiopianDayMeta,
        ethiopianDay.isAcceptableOrUnknown(
          data['ethiopian_day']!,
          _ethiopianDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ethiopianDayMeta);
    }
    if (data.containsKey('gregorian_date')) {
      context.handle(
        _gregorianDateMeta,
        gregorianDate.isAcceptableOrUnknown(
          data['gregorian_date']!,
          _gregorianDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gregorianDateMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('has_reminder')) {
      context.handle(
        _hasReminderMeta,
        hasReminder.isAcceptableOrUnknown(
          data['has_reminder']!,
          _hasReminderMeta,
        ),
      );
    }
    if (data.containsKey('reminder_date_time')) {
      context.handle(
        _reminderDateTimeMeta,
        reminderDateTime.isAcceptableOrUnknown(
          data['reminder_date_time']!,
          _reminderDateTimeMeta,
        ),
      );
    }
    if (data.containsKey('reminder_notified')) {
      context.handle(
        _reminderNotifiedMeta,
        reminderNotified.isAcceptableOrUnknown(
          data['reminder_notified']!,
          _reminderNotifiedMeta,
        ),
      );
    }
    if (data.containsKey('reminder_repeat')) {
      context.handle(
        _reminderRepeatMeta,
        reminderRepeat.isAcceptableOrUnknown(
          data['reminder_repeat']!,
          _reminderRepeatMeta,
        ),
      );
    }
    if (data.containsKey('reminder_ethiopian_month')) {
      context.handle(
        _reminderEthiopianMonthMeta,
        reminderEthiopianMonth.isAcceptableOrUnknown(
          data['reminder_ethiopian_month']!,
          _reminderEthiopianMonthMeta,
        ),
      );
    }
    if (data.containsKey('reminder_ethiopian_day')) {
      context.handle(
        _reminderEthiopianDayMeta,
        reminderEthiopianDay.isAcceptableOrUnknown(
          data['reminder_ethiopian_day']!,
          _reminderEthiopianDayMeta,
        ),
      );
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
        _reminderHourMeta,
        reminderHour.isAcceptableOrUnknown(
          data['reminder_hour']!,
          _reminderHourMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
        _reminderMinuteMeta,
        reminderMinute.isAcceptableOrUnknown(
          data['reminder_minute']!,
          _reminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('reminder_timezone')) {
      context.handle(
        _reminderTimezoneMeta,
        reminderTimezone.isAcceptableOrUnknown(
          data['reminder_timezone']!,
          _reminderTimezoneMeta,
        ),
      );
    }
    if (data.containsKey('reminder_next_occurrence')) {
      context.handle(
        _reminderNextOccurrenceMeta,
        reminderNextOccurrence.isAcceptableOrUnknown(
          data['reminder_next_occurrence']!,
          _reminderNextOccurrenceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_pending_delete')) {
      context.handle(
        _isPendingDeleteMeta,
        isPendingDelete.isAcceptableOrUnknown(
          data['is_pending_delete']!,
          _isPendingDeleteMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCalendarNoteData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCalendarNoteData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      ethiopianYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ethiopian_year'],
      )!,
      ethiopianMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ethiopian_month'],
      )!,
      ethiopianDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ethiopian_day'],
      )!,
      gregorianDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}gregorian_date'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      hasReminder: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_reminder'],
      )!,
      reminderDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reminder_date_time'],
      ),
      reminderNotified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_notified'],
      )!,
      reminderRepeat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_repeat'],
      )!,
      reminderEthiopianMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_ethiopian_month'],
      ),
      reminderEthiopianDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_ethiopian_day'],
      ),
      reminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_hour'],
      ),
      reminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute'],
      ),
      reminderTimezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_timezone'],
      )!,
      reminderNextOccurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reminder_next_occurrence'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isPendingDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_delete'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $LocalCalendarNotesTable createAlias(String alias) {
    return $LocalCalendarNotesTable(attachedDatabase, alias);
  }
}

class LocalCalendarNoteData extends DataClass
    implements Insertable<LocalCalendarNoteData> {
  final String id;
  final String userId;
  final int ethiopianYear;
  final int ethiopianMonth;
  final int ethiopianDay;
  final DateTime gregorianDate;
  final String? title;
  final String? content;
  final bool hasReminder;
  final DateTime? reminderDateTime;
  final bool reminderNotified;
  final String reminderRepeat;
  final int? reminderEthiopianMonth;
  final int? reminderEthiopianDay;
  final int? reminderHour;
  final int? reminderMinute;
  final String reminderTimezone;
  final DateTime? reminderNextOccurrence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isSynced;
  final bool isPendingDelete;
  final DateTime? lastSyncedAt;
  const LocalCalendarNoteData({
    required this.id,
    required this.userId,
    required this.ethiopianYear,
    required this.ethiopianMonth,
    required this.ethiopianDay,
    required this.gregorianDate,
    this.title,
    this.content,
    required this.hasReminder,
    this.reminderDateTime,
    required this.reminderNotified,
    required this.reminderRepeat,
    this.reminderEthiopianMonth,
    this.reminderEthiopianDay,
    this.reminderHour,
    this.reminderMinute,
    required this.reminderTimezone,
    this.reminderNextOccurrence,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    required this.isPendingDelete,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['ethiopian_year'] = Variable<int>(ethiopianYear);
    map['ethiopian_month'] = Variable<int>(ethiopianMonth);
    map['ethiopian_day'] = Variable<int>(ethiopianDay);
    map['gregorian_date'] = Variable<DateTime>(gregorianDate);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['has_reminder'] = Variable<bool>(hasReminder);
    if (!nullToAbsent || reminderDateTime != null) {
      map['reminder_date_time'] = Variable<DateTime>(reminderDateTime);
    }
    map['reminder_notified'] = Variable<bool>(reminderNotified);
    map['reminder_repeat'] = Variable<String>(reminderRepeat);
    if (!nullToAbsent || reminderEthiopianMonth != null) {
      map['reminder_ethiopian_month'] = Variable<int>(reminderEthiopianMonth);
    }
    if (!nullToAbsent || reminderEthiopianDay != null) {
      map['reminder_ethiopian_day'] = Variable<int>(reminderEthiopianDay);
    }
    if (!nullToAbsent || reminderHour != null) {
      map['reminder_hour'] = Variable<int>(reminderHour);
    }
    if (!nullToAbsent || reminderMinute != null) {
      map['reminder_minute'] = Variable<int>(reminderMinute);
    }
    map['reminder_timezone'] = Variable<String>(reminderTimezone);
    if (!nullToAbsent || reminderNextOccurrence != null) {
      map['reminder_next_occurrence'] = Variable<DateTime>(
        reminderNextOccurrence,
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_pending_delete'] = Variable<bool>(isPendingDelete);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  LocalCalendarNotesCompanion toCompanion(bool nullToAbsent) {
    return LocalCalendarNotesCompanion(
      id: Value(id),
      userId: Value(userId),
      ethiopianYear: Value(ethiopianYear),
      ethiopianMonth: Value(ethiopianMonth),
      ethiopianDay: Value(ethiopianDay),
      gregorianDate: Value(gregorianDate),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      hasReminder: Value(hasReminder),
      reminderDateTime: reminderDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderDateTime),
      reminderNotified: Value(reminderNotified),
      reminderRepeat: Value(reminderRepeat),
      reminderEthiopianMonth: reminderEthiopianMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderEthiopianMonth),
      reminderEthiopianDay: reminderEthiopianDay == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderEthiopianDay),
      reminderHour: reminderHour == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderHour),
      reminderMinute: reminderMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinute),
      reminderTimezone: Value(reminderTimezone),
      reminderNextOccurrence: reminderNextOccurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderNextOccurrence),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isSynced: Value(isSynced),
      isPendingDelete: Value(isPendingDelete),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory LocalCalendarNoteData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCalendarNoteData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      ethiopianYear: serializer.fromJson<int>(json['ethiopianYear']),
      ethiopianMonth: serializer.fromJson<int>(json['ethiopianMonth']),
      ethiopianDay: serializer.fromJson<int>(json['ethiopianDay']),
      gregorianDate: serializer.fromJson<DateTime>(json['gregorianDate']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String?>(json['content']),
      hasReminder: serializer.fromJson<bool>(json['hasReminder']),
      reminderDateTime: serializer.fromJson<DateTime?>(
        json['reminderDateTime'],
      ),
      reminderNotified: serializer.fromJson<bool>(json['reminderNotified']),
      reminderRepeat: serializer.fromJson<String>(json['reminderRepeat']),
      reminderEthiopianMonth: serializer.fromJson<int?>(
        json['reminderEthiopianMonth'],
      ),
      reminderEthiopianDay: serializer.fromJson<int?>(
        json['reminderEthiopianDay'],
      ),
      reminderHour: serializer.fromJson<int?>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int?>(json['reminderMinute']),
      reminderTimezone: serializer.fromJson<String>(json['reminderTimezone']),
      reminderNextOccurrence: serializer.fromJson<DateTime?>(
        json['reminderNextOccurrence'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isPendingDelete: serializer.fromJson<bool>(json['isPendingDelete']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'ethiopianYear': serializer.toJson<int>(ethiopianYear),
      'ethiopianMonth': serializer.toJson<int>(ethiopianMonth),
      'ethiopianDay': serializer.toJson<int>(ethiopianDay),
      'gregorianDate': serializer.toJson<DateTime>(gregorianDate),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String?>(content),
      'hasReminder': serializer.toJson<bool>(hasReminder),
      'reminderDateTime': serializer.toJson<DateTime?>(reminderDateTime),
      'reminderNotified': serializer.toJson<bool>(reminderNotified),
      'reminderRepeat': serializer.toJson<String>(reminderRepeat),
      'reminderEthiopianMonth': serializer.toJson<int?>(reminderEthiopianMonth),
      'reminderEthiopianDay': serializer.toJson<int?>(reminderEthiopianDay),
      'reminderHour': serializer.toJson<int?>(reminderHour),
      'reminderMinute': serializer.toJson<int?>(reminderMinute),
      'reminderTimezone': serializer.toJson<String>(reminderTimezone),
      'reminderNextOccurrence': serializer.toJson<DateTime?>(
        reminderNextOccurrence,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isPendingDelete': serializer.toJson<bool>(isPendingDelete),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  LocalCalendarNoteData copyWith({
    String? id,
    String? userId,
    int? ethiopianYear,
    int? ethiopianMonth,
    int? ethiopianDay,
    DateTime? gregorianDate,
    Value<String?> title = const Value.absent(),
    Value<String?> content = const Value.absent(),
    bool? hasReminder,
    Value<DateTime?> reminderDateTime = const Value.absent(),
    bool? reminderNotified,
    String? reminderRepeat,
    Value<int?> reminderEthiopianMonth = const Value.absent(),
    Value<int?> reminderEthiopianDay = const Value.absent(),
    Value<int?> reminderHour = const Value.absent(),
    Value<int?> reminderMinute = const Value.absent(),
    String? reminderTimezone,
    Value<DateTime?> reminderNextOccurrence = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? isSynced,
    bool? isPendingDelete,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => LocalCalendarNoteData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    ethiopianYear: ethiopianYear ?? this.ethiopianYear,
    ethiopianMonth: ethiopianMonth ?? this.ethiopianMonth,
    ethiopianDay: ethiopianDay ?? this.ethiopianDay,
    gregorianDate: gregorianDate ?? this.gregorianDate,
    title: title.present ? title.value : this.title,
    content: content.present ? content.value : this.content,
    hasReminder: hasReminder ?? this.hasReminder,
    reminderDateTime: reminderDateTime.present
        ? reminderDateTime.value
        : this.reminderDateTime,
    reminderNotified: reminderNotified ?? this.reminderNotified,
    reminderRepeat: reminderRepeat ?? this.reminderRepeat,
    reminderEthiopianMonth: reminderEthiopianMonth.present
        ? reminderEthiopianMonth.value
        : this.reminderEthiopianMonth,
    reminderEthiopianDay: reminderEthiopianDay.present
        ? reminderEthiopianDay.value
        : this.reminderEthiopianDay,
    reminderHour: reminderHour.present ? reminderHour.value : this.reminderHour,
    reminderMinute: reminderMinute.present
        ? reminderMinute.value
        : this.reminderMinute,
    reminderTimezone: reminderTimezone ?? this.reminderTimezone,
    reminderNextOccurrence: reminderNextOccurrence.present
        ? reminderNextOccurrence.value
        : this.reminderNextOccurrence,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    isSynced: isSynced ?? this.isSynced,
    isPendingDelete: isPendingDelete ?? this.isPendingDelete,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  LocalCalendarNoteData copyWithCompanion(LocalCalendarNotesCompanion data) {
    return LocalCalendarNoteData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      ethiopianYear: data.ethiopianYear.present
          ? data.ethiopianYear.value
          : this.ethiopianYear,
      ethiopianMonth: data.ethiopianMonth.present
          ? data.ethiopianMonth.value
          : this.ethiopianMonth,
      ethiopianDay: data.ethiopianDay.present
          ? data.ethiopianDay.value
          : this.ethiopianDay,
      gregorianDate: data.gregorianDate.present
          ? data.gregorianDate.value
          : this.gregorianDate,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      hasReminder: data.hasReminder.present
          ? data.hasReminder.value
          : this.hasReminder,
      reminderDateTime: data.reminderDateTime.present
          ? data.reminderDateTime.value
          : this.reminderDateTime,
      reminderNotified: data.reminderNotified.present
          ? data.reminderNotified.value
          : this.reminderNotified,
      reminderRepeat: data.reminderRepeat.present
          ? data.reminderRepeat.value
          : this.reminderRepeat,
      reminderEthiopianMonth: data.reminderEthiopianMonth.present
          ? data.reminderEthiopianMonth.value
          : this.reminderEthiopianMonth,
      reminderEthiopianDay: data.reminderEthiopianDay.present
          ? data.reminderEthiopianDay.value
          : this.reminderEthiopianDay,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      reminderTimezone: data.reminderTimezone.present
          ? data.reminderTimezone.value
          : this.reminderTimezone,
      reminderNextOccurrence: data.reminderNextOccurrence.present
          ? data.reminderNextOccurrence.value
          : this.reminderNextOccurrence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isPendingDelete: data.isPendingDelete.present
          ? data.isPendingDelete.value
          : this.isPendingDelete,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarNoteData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('ethiopianYear: $ethiopianYear, ')
          ..write('ethiopianMonth: $ethiopianMonth, ')
          ..write('ethiopianDay: $ethiopianDay, ')
          ..write('gregorianDate: $gregorianDate, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('hasReminder: $hasReminder, ')
          ..write('reminderDateTime: $reminderDateTime, ')
          ..write('reminderNotified: $reminderNotified, ')
          ..write('reminderRepeat: $reminderRepeat, ')
          ..write('reminderEthiopianMonth: $reminderEthiopianMonth, ')
          ..write('reminderEthiopianDay: $reminderEthiopianDay, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('reminderTimezone: $reminderTimezone, ')
          ..write('reminderNextOccurrence: $reminderNextOccurrence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isPendingDelete: $isPendingDelete, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    ethiopianYear,
    ethiopianMonth,
    ethiopianDay,
    gregorianDate,
    title,
    content,
    hasReminder,
    reminderDateTime,
    reminderNotified,
    reminderRepeat,
    reminderEthiopianMonth,
    reminderEthiopianDay,
    reminderHour,
    reminderMinute,
    reminderTimezone,
    reminderNextOccurrence,
    createdAt,
    updatedAt,
    deletedAt,
    isSynced,
    isPendingDelete,
    lastSyncedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCalendarNoteData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.ethiopianYear == this.ethiopianYear &&
          other.ethiopianMonth == this.ethiopianMonth &&
          other.ethiopianDay == this.ethiopianDay &&
          other.gregorianDate == this.gregorianDate &&
          other.title == this.title &&
          other.content == this.content &&
          other.hasReminder == this.hasReminder &&
          other.reminderDateTime == this.reminderDateTime &&
          other.reminderNotified == this.reminderNotified &&
          other.reminderRepeat == this.reminderRepeat &&
          other.reminderEthiopianMonth == this.reminderEthiopianMonth &&
          other.reminderEthiopianDay == this.reminderEthiopianDay &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.reminderTimezone == this.reminderTimezone &&
          other.reminderNextOccurrence == this.reminderNextOccurrence &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.isSynced == this.isSynced &&
          other.isPendingDelete == this.isPendingDelete &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class LocalCalendarNotesCompanion
    extends UpdateCompanion<LocalCalendarNoteData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> ethiopianYear;
  final Value<int> ethiopianMonth;
  final Value<int> ethiopianDay;
  final Value<DateTime> gregorianDate;
  final Value<String?> title;
  final Value<String?> content;
  final Value<bool> hasReminder;
  final Value<DateTime?> reminderDateTime;
  final Value<bool> reminderNotified;
  final Value<String> reminderRepeat;
  final Value<int?> reminderEthiopianMonth;
  final Value<int?> reminderEthiopianDay;
  final Value<int?> reminderHour;
  final Value<int?> reminderMinute;
  final Value<String> reminderTimezone;
  final Value<DateTime?> reminderNextOccurrence;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> isSynced;
  final Value<bool> isPendingDelete;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const LocalCalendarNotesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.ethiopianYear = const Value.absent(),
    this.ethiopianMonth = const Value.absent(),
    this.ethiopianDay = const Value.absent(),
    this.gregorianDate = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.hasReminder = const Value.absent(),
    this.reminderDateTime = const Value.absent(),
    this.reminderNotified = const Value.absent(),
    this.reminderRepeat = const Value.absent(),
    this.reminderEthiopianMonth = const Value.absent(),
    this.reminderEthiopianDay = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.reminderTimezone = const Value.absent(),
    this.reminderNextOccurrence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isPendingDelete = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCalendarNotesCompanion.insert({
    required String id,
    required String userId,
    required int ethiopianYear,
    required int ethiopianMonth,
    required int ethiopianDay,
    required DateTime gregorianDate,
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.hasReminder = const Value.absent(),
    this.reminderDateTime = const Value.absent(),
    this.reminderNotified = const Value.absent(),
    this.reminderRepeat = const Value.absent(),
    this.reminderEthiopianMonth = const Value.absent(),
    this.reminderEthiopianDay = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.reminderTimezone = const Value.absent(),
    this.reminderNextOccurrence = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isPendingDelete = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       ethiopianYear = Value(ethiopianYear),
       ethiopianMonth = Value(ethiopianMonth),
       ethiopianDay = Value(ethiopianDay),
       gregorianDate = Value(gregorianDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalCalendarNoteData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? ethiopianYear,
    Expression<int>? ethiopianMonth,
    Expression<int>? ethiopianDay,
    Expression<DateTime>? gregorianDate,
    Expression<String>? title,
    Expression<String>? content,
    Expression<bool>? hasReminder,
    Expression<DateTime>? reminderDateTime,
    Expression<bool>? reminderNotified,
    Expression<String>? reminderRepeat,
    Expression<int>? reminderEthiopianMonth,
    Expression<int>? reminderEthiopianDay,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<String>? reminderTimezone,
    Expression<DateTime>? reminderNextOccurrence,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isSynced,
    Expression<bool>? isPendingDelete,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (ethiopianYear != null) 'ethiopian_year': ethiopianYear,
      if (ethiopianMonth != null) 'ethiopian_month': ethiopianMonth,
      if (ethiopianDay != null) 'ethiopian_day': ethiopianDay,
      if (gregorianDate != null) 'gregorian_date': gregorianDate,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (hasReminder != null) 'has_reminder': hasReminder,
      if (reminderDateTime != null) 'reminder_date_time': reminderDateTime,
      if (reminderNotified != null) 'reminder_notified': reminderNotified,
      if (reminderRepeat != null) 'reminder_repeat': reminderRepeat,
      if (reminderEthiopianMonth != null)
        'reminder_ethiopian_month': reminderEthiopianMonth,
      if (reminderEthiopianDay != null)
        'reminder_ethiopian_day': reminderEthiopianDay,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (reminderTimezone != null) 'reminder_timezone': reminderTimezone,
      if (reminderNextOccurrence != null)
        'reminder_next_occurrence': reminderNextOccurrence,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (isPendingDelete != null) 'is_pending_delete': isPendingDelete,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCalendarNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? ethiopianYear,
    Value<int>? ethiopianMonth,
    Value<int>? ethiopianDay,
    Value<DateTime>? gregorianDate,
    Value<String?>? title,
    Value<String?>? content,
    Value<bool>? hasReminder,
    Value<DateTime?>? reminderDateTime,
    Value<bool>? reminderNotified,
    Value<String>? reminderRepeat,
    Value<int?>? reminderEthiopianMonth,
    Value<int?>? reminderEthiopianDay,
    Value<int?>? reminderHour,
    Value<int?>? reminderMinute,
    Value<String>? reminderTimezone,
    Value<DateTime?>? reminderNextOccurrence,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? isSynced,
    Value<bool>? isPendingDelete,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return LocalCalendarNotesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ethiopianYear: ethiopianYear ?? this.ethiopianYear,
      ethiopianMonth: ethiopianMonth ?? this.ethiopianMonth,
      ethiopianDay: ethiopianDay ?? this.ethiopianDay,
      gregorianDate: gregorianDate ?? this.gregorianDate,
      title: title ?? this.title,
      content: content ?? this.content,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      reminderNotified: reminderNotified ?? this.reminderNotified,
      reminderRepeat: reminderRepeat ?? this.reminderRepeat,
      reminderEthiopianMonth:
          reminderEthiopianMonth ?? this.reminderEthiopianMonth,
      reminderEthiopianDay: reminderEthiopianDay ?? this.reminderEthiopianDay,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderTimezone: reminderTimezone ?? this.reminderTimezone,
      reminderNextOccurrence:
          reminderNextOccurrence ?? this.reminderNextOccurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isSynced: isSynced ?? this.isSynced,
      isPendingDelete: isPendingDelete ?? this.isPendingDelete,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (ethiopianYear.present) {
      map['ethiopian_year'] = Variable<int>(ethiopianYear.value);
    }
    if (ethiopianMonth.present) {
      map['ethiopian_month'] = Variable<int>(ethiopianMonth.value);
    }
    if (ethiopianDay.present) {
      map['ethiopian_day'] = Variable<int>(ethiopianDay.value);
    }
    if (gregorianDate.present) {
      map['gregorian_date'] = Variable<DateTime>(gregorianDate.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (hasReminder.present) {
      map['has_reminder'] = Variable<bool>(hasReminder.value);
    }
    if (reminderDateTime.present) {
      map['reminder_date_time'] = Variable<DateTime>(reminderDateTime.value);
    }
    if (reminderNotified.present) {
      map['reminder_notified'] = Variable<bool>(reminderNotified.value);
    }
    if (reminderRepeat.present) {
      map['reminder_repeat'] = Variable<String>(reminderRepeat.value);
    }
    if (reminderEthiopianMonth.present) {
      map['reminder_ethiopian_month'] = Variable<int>(
        reminderEthiopianMonth.value,
      );
    }
    if (reminderEthiopianDay.present) {
      map['reminder_ethiopian_day'] = Variable<int>(reminderEthiopianDay.value);
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (reminderTimezone.present) {
      map['reminder_timezone'] = Variable<String>(reminderTimezone.value);
    }
    if (reminderNextOccurrence.present) {
      map['reminder_next_occurrence'] = Variable<DateTime>(
        reminderNextOccurrence.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isPendingDelete.present) {
      map['is_pending_delete'] = Variable<bool>(isPendingDelete.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarNotesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('ethiopianYear: $ethiopianYear, ')
          ..write('ethiopianMonth: $ethiopianMonth, ')
          ..write('ethiopianDay: $ethiopianDay, ')
          ..write('gregorianDate: $gregorianDate, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('hasReminder: $hasReminder, ')
          ..write('reminderDateTime: $reminderDateTime, ')
          ..write('reminderNotified: $reminderNotified, ')
          ..write('reminderRepeat: $reminderRepeat, ')
          ..write('reminderEthiopianMonth: $reminderEthiopianMonth, ')
          ..write('reminderEthiopianDay: $reminderEthiopianDay, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('reminderTimezone: $reminderTimezone, ')
          ..write('reminderNextOccurrence: $reminderNextOccurrence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isPendingDelete: $isPendingDelete, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCalendarNoteMediaTable extends LocalCalendarNoteMedia
    with TableInfo<$LocalCalendarNoteMediaTable, LocalCalendarNoteMediaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCalendarNoteMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileUrlMeta = const VerificationMeta(
    'fileUrl',
  );
  @override
  late final GeneratedColumn<String> fileUrl = GeneratedColumn<String>(
    'file_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPendingDeleteMeta = const VerificationMeta(
    'isPendingDelete',
  );
  @override
  late final GeneratedColumn<bool> isPendingDelete = GeneratedColumn<bool>(
    'is_pending_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    noteId,
    fileId,
    order,
    caption,
    fileUrl,
    fileName,
    mimeType,
    fileSize,
    createdAt,
    isSynced,
    isPendingDelete,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_calendar_note_media';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCalendarNoteMediaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('file_url')) {
      context.handle(
        _fileUrlMeta,
        fileUrl.isAcceptableOrUnknown(data['file_url']!, _fileUrlMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_pending_delete')) {
      context.handle(
        _isPendingDeleteMeta,
        isPendingDelete.isAcceptableOrUnknown(
          data['is_pending_delete']!,
          _isPendingDeleteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCalendarNoteMediaData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCalendarNoteMediaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      fileUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_url'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isPendingDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_delete'],
      )!,
    );
  }

  @override
  $LocalCalendarNoteMediaTable createAlias(String alias) {
    return $LocalCalendarNoteMediaTable(attachedDatabase, alias);
  }
}

class LocalCalendarNoteMediaData extends DataClass
    implements Insertable<LocalCalendarNoteMediaData> {
  final String id;
  final String noteId;
  final String fileId;
  final int order;
  final String? caption;
  final String? fileUrl;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
  final DateTime createdAt;
  final bool isSynced;
  final bool isPendingDelete;
  const LocalCalendarNoteMediaData({
    required this.id,
    required this.noteId,
    required this.fileId,
    required this.order,
    this.caption,
    this.fileUrl,
    this.fileName,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
    required this.isSynced,
    required this.isPendingDelete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['file_id'] = Variable<String>(fileId);
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    if (!nullToAbsent || fileUrl != null) {
      map['file_url'] = Variable<String>(fileUrl);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_pending_delete'] = Variable<bool>(isPendingDelete);
    return map;
  }

  LocalCalendarNoteMediaCompanion toCompanion(bool nullToAbsent) {
    return LocalCalendarNoteMediaCompanion(
      id: Value(id),
      noteId: Value(noteId),
      fileId: Value(fileId),
      order: Value(order),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      fileUrl: fileUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fileUrl),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
      isPendingDelete: Value(isPendingDelete),
    );
  }

  factory LocalCalendarNoteMediaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCalendarNoteMediaData(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      fileId: serializer.fromJson<String>(json['fileId']),
      order: serializer.fromJson<int>(json['order']),
      caption: serializer.fromJson<String?>(json['caption']),
      fileUrl: serializer.fromJson<String?>(json['fileUrl']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isPendingDelete: serializer.fromJson<bool>(json['isPendingDelete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'fileId': serializer.toJson<String>(fileId),
      'order': serializer.toJson<int>(order),
      'caption': serializer.toJson<String?>(caption),
      'fileUrl': serializer.toJson<String?>(fileUrl),
      'fileName': serializer.toJson<String?>(fileName),
      'mimeType': serializer.toJson<String?>(mimeType),
      'fileSize': serializer.toJson<int?>(fileSize),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isPendingDelete': serializer.toJson<bool>(isPendingDelete),
    };
  }

  LocalCalendarNoteMediaData copyWith({
    String? id,
    String? noteId,
    String? fileId,
    int? order,
    Value<String?> caption = const Value.absent(),
    Value<String?> fileUrl = const Value.absent(),
    Value<String?> fileName = const Value.absent(),
    Value<String?> mimeType = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    DateTime? createdAt,
    bool? isSynced,
    bool? isPendingDelete,
  }) => LocalCalendarNoteMediaData(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    fileId: fileId ?? this.fileId,
    order: order ?? this.order,
    caption: caption.present ? caption.value : this.caption,
    fileUrl: fileUrl.present ? fileUrl.value : this.fileUrl,
    fileName: fileName.present ? fileName.value : this.fileName,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    createdAt: createdAt ?? this.createdAt,
    isSynced: isSynced ?? this.isSynced,
    isPendingDelete: isPendingDelete ?? this.isPendingDelete,
  );
  LocalCalendarNoteMediaData copyWithCompanion(
    LocalCalendarNoteMediaCompanion data,
  ) {
    return LocalCalendarNoteMediaData(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      order: data.order.present ? data.order.value : this.order,
      caption: data.caption.present ? data.caption.value : this.caption,
      fileUrl: data.fileUrl.present ? data.fileUrl.value : this.fileUrl,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isPendingDelete: data.isPendingDelete.present
          ? data.isPendingDelete.value
          : this.isPendingDelete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarNoteMediaData(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('fileId: $fileId, ')
          ..write('order: $order, ')
          ..write('caption: $caption, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isPendingDelete: $isPendingDelete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    noteId,
    fileId,
    order,
    caption,
    fileUrl,
    fileName,
    mimeType,
    fileSize,
    createdAt,
    isSynced,
    isPendingDelete,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCalendarNoteMediaData &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.fileId == this.fileId &&
          other.order == this.order &&
          other.caption == this.caption &&
          other.fileUrl == this.fileUrl &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.fileSize == this.fileSize &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced &&
          other.isPendingDelete == this.isPendingDelete);
}

class LocalCalendarNoteMediaCompanion
    extends UpdateCompanion<LocalCalendarNoteMediaData> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> fileId;
  final Value<int> order;
  final Value<String?> caption;
  final Value<String?> fileUrl;
  final Value<String?> fileName;
  final Value<String?> mimeType;
  final Value<int?> fileSize;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<bool> isPendingDelete;
  final Value<int> rowid;
  const LocalCalendarNoteMediaCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.order = const Value.absent(),
    this.caption = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isPendingDelete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCalendarNoteMediaCompanion.insert({
    required String id,
    required String noteId,
    required String fileId,
    required int order,
    this.caption = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSize = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.isPendingDelete = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       noteId = Value(noteId),
       fileId = Value(fileId),
       order = Value(order),
       createdAt = Value(createdAt);
  static Insertable<LocalCalendarNoteMediaData> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? fileId,
    Expression<int>? order,
    Expression<String>? caption,
    Expression<String>? fileUrl,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<int>? fileSize,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<bool>? isPendingDelete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (fileId != null) 'file_id': fileId,
      if (order != null) 'order': order,
      if (caption != null) 'caption': caption,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSize != null) 'file_size': fileSize,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (isPendingDelete != null) 'is_pending_delete': isPendingDelete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCalendarNoteMediaCompanion copyWith({
    Value<String>? id,
    Value<String>? noteId,
    Value<String>? fileId,
    Value<int>? order,
    Value<String?>? caption,
    Value<String?>? fileUrl,
    Value<String?>? fileName,
    Value<String?>? mimeType,
    Value<int?>? fileSize,
    Value<DateTime>? createdAt,
    Value<bool>? isSynced,
    Value<bool>? isPendingDelete,
    Value<int>? rowid,
  }) {
    return LocalCalendarNoteMediaCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      fileId: fileId ?? this.fileId,
      order: order ?? this.order,
      caption: caption ?? this.caption,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isPendingDelete: isPendingDelete ?? this.isPendingDelete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (fileUrl.present) {
      map['file_url'] = Variable<String>(fileUrl.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isPendingDelete.present) {
      map['is_pending_delete'] = Variable<bool>(isPendingDelete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarNoteMediaCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('fileId: $fileId, ')
          ..write('order: $order, ')
          ..write('caption: $caption, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isPendingDelete: $isPendingDelete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationType,
    entityType,
    entityId,
    payload,
    createdAt,
    updatedAt,
    retryCount,
    lastAttemptAt,
    nextRetryAt,
    status,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String operationType;
  final String entityType;
  final String entityId;
  final String payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;
  final String status;
  final String? errorMessage;
  const SyncQueueData({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    required this.retryCount,
    this.lastAttemptAt,
    this.nextRetryAt,
    required this.status,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      operationType: Value(operationType),
      entityType: Value(entityType),
      entityId: Value(entityId),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      retryCount: Value(retryCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operationType': serializer.toJson<String>(operationType),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  SyncQueueData copyWith({
    String? id,
    String? operationType,
    String? entityType,
    String? entityId,
    String? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? retryCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> nextRetryAt = const Value.absent(),
    String? status,
    Value<String?> errorMessage = const Value.absent(),
  }) => SyncQueueData(
    id: id ?? this.id,
    operationType: operationType ?? this.operationType,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    retryCount: retryCount ?? this.retryCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationType,
    entityType,
    entityId,
    payload,
    createdAt,
    updatedAt,
    retryCount,
    lastAttemptAt,
    nextRetryAt,
    status,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.retryCount == this.retryCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextRetryAt == this.nextRetryAt &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> operationType;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> retryCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> nextRetryAt;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String operationType,
    required String entityType,
    required String entityId,
    required String payload,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.retryCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       operationType = Value(operationType),
       entityType = Value(entityType),
       entityId = Value(entityId),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? operationType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? retryCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? operationType,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? retryCount,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? nextRetryAt,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalUsersTable localUsers = $LocalUsersTable(this);
  late final $LocalVideosTable localVideos = $LocalVideosTable(this);
  late final $LocalConversationsTable localConversations =
      $LocalConversationsTable(this);
  late final $LocalMessagesTable localMessages = $LocalMessagesTable(this);
  late final $LocalMessageAttachmentsTable localMessageAttachments =
      $LocalMessageAttachmentsTable(this);
  late final $LocalWatchHistoryTable localWatchHistory =
      $LocalWatchHistoryTable(this);
  late final $LocalSearchHistoryTable localSearchHistory =
      $LocalSearchHistoryTable(this);
  late final $LocalFeedItemsTable localFeedItems = $LocalFeedItemsTable(this);
  late final $LocalCalendarNotesTable localCalendarNotes =
      $LocalCalendarNotesTable(this);
  late final $LocalCalendarNoteMediaTable localCalendarNoteMedia =
      $LocalCalendarNoteMediaTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final UsersDao usersDao = UsersDao(this as AppDatabase);
  late final VideosDao videosDao = VideosDao(this as AppDatabase);
  late final ConversationsDao conversationsDao = ConversationsDao(
    this as AppDatabase,
  );
  late final MessagesDao messagesDao = MessagesDao(this as AppDatabase);
  late final WatchHistoryDao watchHistoryDao = WatchHistoryDao(
    this as AppDatabase,
  );
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  late final FeedDao feedDao = FeedDao(this as AppDatabase);
  late final SearchHistoryDao searchHistoryDao = SearchHistoryDao(
    this as AppDatabase,
  );
  late final CalendarNotesDao calendarNotesDao = CalendarNotesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localUsers,
    localVideos,
    localConversations,
    localMessages,
    localMessageAttachments,
    localWatchHistory,
    localSearchHistory,
    localFeedItems,
    localCalendarNotes,
    localCalendarNoteMedia,
    syncQueue,
  ];
}

typedef $$LocalUsersTableCreateCompanionBuilder =
    LocalUsersCompanion Function({
      required String id,
      Value<String?> username,
      Value<String?> displayName,
      Value<String?> avatarUrl,
      Value<String?> email,
      Value<String?> phoneNumber,
      Value<String?> role,
      Value<String?> bio,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalUsersTableUpdateCompanionBuilder =
    LocalUsersCompanion Function({
      Value<String> id,
      Value<String?> username,
      Value<String?> displayName,
      Value<String?> avatarUrl,
      Value<String?> email,
      Value<String?> phoneNumber,
      Value<String?> role,
      Value<String?> bio,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalUsersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalUsersTable> {
  $$LocalUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalUsersTable,
          LocalUserData,
          $$LocalUsersTableFilterComposer,
          $$LocalUsersTableOrderingComposer,
          $$LocalUsersTableAnnotationComposer,
          $$LocalUsersTableCreateCompanionBuilder,
          $$LocalUsersTableUpdateCompanionBuilder,
          (
            LocalUserData,
            BaseReferences<_$AppDatabase, $LocalUsersTable, LocalUserData>,
          ),
          LocalUserData,
          PrefetchHooks Function()
        > {
  $$LocalUsersTableTableManager(_$AppDatabase db, $LocalUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUsersCompanion(
                id: id,
                username: username,
                displayName: displayName,
                avatarUrl: avatarUrl,
                email: email,
                phoneNumber: phoneNumber,
                role: role,
                bio: bio,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> username = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUsersCompanion.insert(
                id: id,
                username: username,
                displayName: displayName,
                avatarUrl: avatarUrl,
                email: email,
                phoneNumber: phoneNumber,
                role: role,
                bio: bio,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalUsersTable,
      LocalUserData,
      $$LocalUsersTableFilterComposer,
      $$LocalUsersTableOrderingComposer,
      $$LocalUsersTableAnnotationComposer,
      $$LocalUsersTableCreateCompanionBuilder,
      $$LocalUsersTableUpdateCompanionBuilder,
      (
        LocalUserData,
        BaseReferences<_$AppDatabase, $LocalUsersTable, LocalUserData>,
      ),
      LocalUserData,
      PrefetchHooks Function()
    >;
typedef $$LocalVideosTableCreateCompanionBuilder =
    LocalVideosCompanion Function({
      required String id,
      Value<String?> serverId,
      required String title,
      Value<String?> description,
      Value<String?> thumbnailUrl,
      Value<String?> videoUrl,
      Value<String?> hlsUrl,
      Value<String?> dashUrl,
      Value<int> duration,
      Value<String?> creatorId,
      Value<String?> creatorName,
      Value<String?> creatorAvatar,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isDownloaded,
      Value<String> downloadStatus,
      Value<String?> localFilePath,
      Value<double> downloadProgress,
      Value<String?> selectedQuality,
      Value<int> fileSizeBytes,
      Value<String?> downloadError,
      Value<int> lastPlayedPosition,
      Value<DateTime?> lastAccessedAt,
      Value<bool> isFavorite,
      Value<String?> renditionsJson,
      Value<int> rowid,
    });
typedef $$LocalVideosTableUpdateCompanionBuilder =
    LocalVideosCompanion Function({
      Value<String> id,
      Value<String?> serverId,
      Value<String> title,
      Value<String?> description,
      Value<String?> thumbnailUrl,
      Value<String?> videoUrl,
      Value<String?> hlsUrl,
      Value<String?> dashUrl,
      Value<int> duration,
      Value<String?> creatorId,
      Value<String?> creatorName,
      Value<String?> creatorAvatar,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isDownloaded,
      Value<String> downloadStatus,
      Value<String?> localFilePath,
      Value<double> downloadProgress,
      Value<String?> selectedQuality,
      Value<int> fileSizeBytes,
      Value<String?> downloadError,
      Value<int> lastPlayedPosition,
      Value<DateTime?> lastAccessedAt,
      Value<bool> isFavorite,
      Value<String?> renditionsJson,
      Value<int> rowid,
    });

class $$LocalVideosTableFilterComposer
    extends Composer<_$AppDatabase, $LocalVideosTable> {
  $$LocalVideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlsUrl => $composableBuilder(
    column: $table.hlsUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dashUrl => $composableBuilder(
    column: $table.dashUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorAvatar => $composableBuilder(
    column: $table.creatorAvatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get downloadProgress => $composableBuilder(
    column: $table.downloadProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedQuality => $composableBuilder(
    column: $table.selectedQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadError => $composableBuilder(
    column: $table.downloadError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPlayedPosition => $composableBuilder(
    column: $table.lastPlayedPosition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get renditionsJson => $composableBuilder(
    column: $table.renditionsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalVideosTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalVideosTable> {
  $$LocalVideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlsUrl => $composableBuilder(
    column: $table.hlsUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dashUrl => $composableBuilder(
    column: $table.dashUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorAvatar => $composableBuilder(
    column: $table.creatorAvatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get downloadProgress => $composableBuilder(
    column: $table.downloadProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedQuality => $composableBuilder(
    column: $table.selectedQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadError => $composableBuilder(
    column: $table.downloadError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPlayedPosition => $composableBuilder(
    column: $table.lastPlayedPosition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get renditionsJson => $composableBuilder(
    column: $table.renditionsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalVideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalVideosTable> {
  $$LocalVideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<String> get hlsUrl =>
      $composableBuilder(column: $table.hlsUrl, builder: (column) => column);

  GeneratedColumn<String> get dashUrl =>
      $composableBuilder(column: $table.dashUrl, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get creatorId =>
      $composableBuilder(column: $table.creatorId, builder: (column) => column);

  GeneratedColumn<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creatorAvatar => $composableBuilder(
    column: $table.creatorAvatar,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get downloadProgress => $composableBuilder(
    column: $table.downloadProgress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedQuality => $composableBuilder(
    column: $table.selectedQuality,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get downloadError => $composableBuilder(
    column: $table.downloadError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPlayedPosition => $composableBuilder(
    column: $table.lastPlayedPosition,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get renditionsJson => $composableBuilder(
    column: $table.renditionsJson,
    builder: (column) => column,
  );
}

class $$LocalVideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalVideosTable,
          LocalVideoData,
          $$LocalVideosTableFilterComposer,
          $$LocalVideosTableOrderingComposer,
          $$LocalVideosTableAnnotationComposer,
          $$LocalVideosTableCreateCompanionBuilder,
          $$LocalVideosTableUpdateCompanionBuilder,
          (
            LocalVideoData,
            BaseReferences<_$AppDatabase, $LocalVideosTable, LocalVideoData>,
          ),
          LocalVideoData,
          PrefetchHooks Function()
        > {
  $$LocalVideosTableTableManager(_$AppDatabase db, $LocalVideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalVideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalVideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalVideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> hlsUrl = const Value.absent(),
                Value<String?> dashUrl = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<String?> creatorName = const Value.absent(),
                Value<String?> creatorAvatar = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<String> downloadStatus = const Value.absent(),
                Value<String?> localFilePath = const Value.absent(),
                Value<double> downloadProgress = const Value.absent(),
                Value<String?> selectedQuality = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<String?> downloadError = const Value.absent(),
                Value<int> lastPlayedPosition = const Value.absent(),
                Value<DateTime?> lastAccessedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> renditionsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalVideosCompanion(
                id: id,
                serverId: serverId,
                title: title,
                description: description,
                thumbnailUrl: thumbnailUrl,
                videoUrl: videoUrl,
                hlsUrl: hlsUrl,
                dashUrl: dashUrl,
                duration: duration,
                creatorId: creatorId,
                creatorName: creatorName,
                creatorAvatar: creatorAvatar,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDownloaded: isDownloaded,
                downloadStatus: downloadStatus,
                localFilePath: localFilePath,
                downloadProgress: downloadProgress,
                selectedQuality: selectedQuality,
                fileSizeBytes: fileSizeBytes,
                downloadError: downloadError,
                lastPlayedPosition: lastPlayedPosition,
                lastAccessedAt: lastAccessedAt,
                isFavorite: isFavorite,
                renditionsJson: renditionsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> serverId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> hlsUrl = const Value.absent(),
                Value<String?> dashUrl = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<String?> creatorName = const Value.absent(),
                Value<String?> creatorAvatar = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<String> downloadStatus = const Value.absent(),
                Value<String?> localFilePath = const Value.absent(),
                Value<double> downloadProgress = const Value.absent(),
                Value<String?> selectedQuality = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<String?> downloadError = const Value.absent(),
                Value<int> lastPlayedPosition = const Value.absent(),
                Value<DateTime?> lastAccessedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> renditionsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalVideosCompanion.insert(
                id: id,
                serverId: serverId,
                title: title,
                description: description,
                thumbnailUrl: thumbnailUrl,
                videoUrl: videoUrl,
                hlsUrl: hlsUrl,
                dashUrl: dashUrl,
                duration: duration,
                creatorId: creatorId,
                creatorName: creatorName,
                creatorAvatar: creatorAvatar,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDownloaded: isDownloaded,
                downloadStatus: downloadStatus,
                localFilePath: localFilePath,
                downloadProgress: downloadProgress,
                selectedQuality: selectedQuality,
                fileSizeBytes: fileSizeBytes,
                downloadError: downloadError,
                lastPlayedPosition: lastPlayedPosition,
                lastAccessedAt: lastAccessedAt,
                isFavorite: isFavorite,
                renditionsJson: renditionsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalVideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalVideosTable,
      LocalVideoData,
      $$LocalVideosTableFilterComposer,
      $$LocalVideosTableOrderingComposer,
      $$LocalVideosTableAnnotationComposer,
      $$LocalVideosTableCreateCompanionBuilder,
      $$LocalVideosTableUpdateCompanionBuilder,
      (
        LocalVideoData,
        BaseReferences<_$AppDatabase, $LocalVideosTable, LocalVideoData>,
      ),
      LocalVideoData,
      PrefetchHooks Function()
    >;
typedef $$LocalConversationsTableCreateCompanionBuilder =
    LocalConversationsCompanion Function({
      required String id,
      required String type,
      Value<String?> groupId,
      Value<String?> channelId,
      Value<String?> title,
      Value<String?> lastMessageId,
      Value<String?> lastMessageContent,
      Value<String?> lastMessageType,
      Value<String?> lastMessageSenderName,
      Value<String?> lastMessageSenderId,
      Value<DateTime?> lastMessageAt,
      Value<int> unreadCount,
      Value<bool> isMuted,
      Value<bool> isPinned,
      Value<String?> membersJson,
      Value<String?> metadataJson,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalConversationsTableUpdateCompanionBuilder =
    LocalConversationsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String?> groupId,
      Value<String?> channelId,
      Value<String?> title,
      Value<String?> lastMessageId,
      Value<String?> lastMessageContent,
      Value<String?> lastMessageType,
      Value<String?> lastMessageSenderName,
      Value<String?> lastMessageSenderId,
      Value<DateTime?> lastMessageAt,
      Value<int> unreadCount,
      Value<bool> isMuted,
      Value<bool> isPinned,
      Value<String?> membersJson,
      Value<String?> metadataJson,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalConversationsTable> {
  $$LocalConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageContent => $composableBuilder(
    column: $table.lastMessageContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageSenderName => $composableBuilder(
    column: $table.lastMessageSenderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get membersJson => $composableBuilder(
    column: $table.membersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalConversationsTable> {
  $$LocalConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageContent => $composableBuilder(
    column: $table.lastMessageContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageSenderName => $composableBuilder(
    column: $table.lastMessageSenderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get membersJson => $composableBuilder(
    column: $table.membersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalConversationsTable> {
  $$LocalConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageContent => $composableBuilder(
    column: $table.lastMessageContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageSenderName => $composableBuilder(
    column: $table.lastMessageSenderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMuted =>
      $composableBuilder(column: $table.isMuted, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<String> get membersJson => $composableBuilder(
    column: $table.membersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalConversationsTable,
          LocalConversationData,
          $$LocalConversationsTableFilterComposer,
          $$LocalConversationsTableOrderingComposer,
          $$LocalConversationsTableAnnotationComposer,
          $$LocalConversationsTableCreateCompanionBuilder,
          $$LocalConversationsTableUpdateCompanionBuilder,
          (
            LocalConversationData,
            BaseReferences<
              _$AppDatabase,
              $LocalConversationsTable,
              LocalConversationData
            >,
          ),
          LocalConversationData,
          PrefetchHooks Function()
        > {
  $$LocalConversationsTableTableManager(
    _$AppDatabase db,
    $LocalConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalConversationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> channelId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                Value<String?> lastMessageContent = const Value.absent(),
                Value<String?> lastMessageType = const Value.absent(),
                Value<String?> lastMessageSenderName = const Value.absent(),
                Value<String?> lastMessageSenderId = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<String?> membersJson = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalConversationsCompanion(
                id: id,
                type: type,
                groupId: groupId,
                channelId: channelId,
                title: title,
                lastMessageId: lastMessageId,
                lastMessageContent: lastMessageContent,
                lastMessageType: lastMessageType,
                lastMessageSenderName: lastMessageSenderName,
                lastMessageSenderId: lastMessageSenderId,
                lastMessageAt: lastMessageAt,
                unreadCount: unreadCount,
                isMuted: isMuted,
                isPinned: isPinned,
                membersJson: membersJson,
                metadataJson: metadataJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                Value<String?> groupId = const Value.absent(),
                Value<String?> channelId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                Value<String?> lastMessageContent = const Value.absent(),
                Value<String?> lastMessageType = const Value.absent(),
                Value<String?> lastMessageSenderName = const Value.absent(),
                Value<String?> lastMessageSenderId = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<String?> membersJson = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalConversationsCompanion.insert(
                id: id,
                type: type,
                groupId: groupId,
                channelId: channelId,
                title: title,
                lastMessageId: lastMessageId,
                lastMessageContent: lastMessageContent,
                lastMessageType: lastMessageType,
                lastMessageSenderName: lastMessageSenderName,
                lastMessageSenderId: lastMessageSenderId,
                lastMessageAt: lastMessageAt,
                unreadCount: unreadCount,
                isMuted: isMuted,
                isPinned: isPinned,
                membersJson: membersJson,
                metadataJson: metadataJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalConversationsTable,
      LocalConversationData,
      $$LocalConversationsTableFilterComposer,
      $$LocalConversationsTableOrderingComposer,
      $$LocalConversationsTableAnnotationComposer,
      $$LocalConversationsTableCreateCompanionBuilder,
      $$LocalConversationsTableUpdateCompanionBuilder,
      (
        LocalConversationData,
        BaseReferences<
          _$AppDatabase,
          $LocalConversationsTable,
          LocalConversationData
        >,
      ),
      LocalConversationData,
      PrefetchHooks Function()
    >;
typedef $$LocalMessagesTableCreateCompanionBuilder =
    LocalMessagesCompanion Function({
      required String localId,
      Value<String?> serverId,
      required String clientId,
      required String conversationId,
      Value<String?> channelId,
      required String senderId,
      Value<String?> senderUsername,
      Value<String?> senderDisplayName,
      Value<String?> senderAvatarUrl,
      Value<String?> content,
      Value<String> messageType,
      Value<String?> replyToMessageId,
      Value<String?> replyToJson,
      Value<String> status,
      Value<bool> isPendingSync,
      Value<bool> isEdited,
      Value<DateTime?> editedAt,
      Value<bool> isPinned,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<String?> attachmentUrl,
      Value<String?> localAttachmentPath,
      Value<String?> attachmentsJson,
      Value<String?> voiceNoteJson,
      Value<String?> reactionsJson,
      Value<String?> readByJson,
      Value<String?> deliveredToJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalMessagesTableUpdateCompanionBuilder =
    LocalMessagesCompanion Function({
      Value<String> localId,
      Value<String?> serverId,
      Value<String> clientId,
      Value<String> conversationId,
      Value<String?> channelId,
      Value<String> senderId,
      Value<String?> senderUsername,
      Value<String?> senderDisplayName,
      Value<String?> senderAvatarUrl,
      Value<String?> content,
      Value<String> messageType,
      Value<String?> replyToMessageId,
      Value<String?> replyToJson,
      Value<String> status,
      Value<bool> isPendingSync,
      Value<bool> isEdited,
      Value<DateTime?> editedAt,
      Value<bool> isPinned,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<String?> attachmentUrl,
      Value<String?> localAttachmentPath,
      Value<String?> attachmentsJson,
      Value<String?> voiceNoteJson,
      Value<String?> reactionsJson,
      Value<String?> readByJson,
      Value<String?> deliveredToJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderUsername => $composableBuilder(
    column: $table.senderUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderDisplayName => $composableBuilder(
    column: $table.senderDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderAvatarUrl => $composableBuilder(
    column: $table.senderAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToJson => $composableBuilder(
    column: $table.replyToJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEdited => $composableBuilder(
    column: $table.isEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentUrl => $composableBuilder(
    column: $table.attachmentUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localAttachmentPath => $composableBuilder(
    column: $table.localAttachmentPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceNoteJson => $composableBuilder(
    column: $table.voiceNoteJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reactionsJson => $composableBuilder(
    column: $table.reactionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readByJson => $composableBuilder(
    column: $table.readByJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveredToJson => $composableBuilder(
    column: $table.deliveredToJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderUsername => $composableBuilder(
    column: $table.senderUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderDisplayName => $composableBuilder(
    column: $table.senderDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderAvatarUrl => $composableBuilder(
    column: $table.senderAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToJson => $composableBuilder(
    column: $table.replyToJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEdited => $composableBuilder(
    column: $table.isEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentUrl => $composableBuilder(
    column: $table.attachmentUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localAttachmentPath => $composableBuilder(
    column: $table.localAttachmentPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceNoteJson => $composableBuilder(
    column: $table.voiceNoteJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reactionsJson => $composableBuilder(
    column: $table.reactionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readByJson => $composableBuilder(
    column: $table.readByJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveredToJson => $composableBuilder(
    column: $table.deliveredToJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderUsername => $composableBuilder(
    column: $table.senderUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderDisplayName => $composableBuilder(
    column: $table.senderDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderAvatarUrl => $composableBuilder(
    column: $table.senderAvatarUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyToJson => $composableBuilder(
    column: $table.replyToJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isPendingSync => $composableBuilder(
    column: $table.isPendingSync,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEdited =>
      $composableBuilder(column: $table.isEdited, builder: (column) => column);

  GeneratedColumn<DateTime> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get attachmentUrl => $composableBuilder(
    column: $table.attachmentUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localAttachmentPath => $composableBuilder(
    column: $table.localAttachmentPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voiceNoteJson => $composableBuilder(
    column: $table.voiceNoteJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reactionsJson => $composableBuilder(
    column: $table.reactionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get readByJson => $composableBuilder(
    column: $table.readByJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveredToJson => $composableBuilder(
    column: $table.deliveredToJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMessagesTable,
          LocalMessageData,
          $$LocalMessagesTableFilterComposer,
          $$LocalMessagesTableOrderingComposer,
          $$LocalMessagesTableAnnotationComposer,
          $$LocalMessagesTableCreateCompanionBuilder,
          $$LocalMessagesTableUpdateCompanionBuilder,
          (
            LocalMessageData,
            BaseReferences<
              _$AppDatabase,
              $LocalMessagesTable,
              LocalMessageData
            >,
          ),
          LocalMessageData,
          PrefetchHooks Function()
        > {
  $$LocalMessagesTableTableManager(_$AppDatabase db, $LocalMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String?> channelId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String?> senderUsername = const Value.absent(),
                Value<String?> senderDisplayName = const Value.absent(),
                Value<String?> senderAvatarUrl = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String> messageType = const Value.absent(),
                Value<String?> replyToMessageId = const Value.absent(),
                Value<String?> replyToJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<bool> isEdited = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> attachmentUrl = const Value.absent(),
                Value<String?> localAttachmentPath = const Value.absent(),
                Value<String?> attachmentsJson = const Value.absent(),
                Value<String?> voiceNoteJson = const Value.absent(),
                Value<String?> reactionsJson = const Value.absent(),
                Value<String?> readByJson = const Value.absent(),
                Value<String?> deliveredToJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion(
                localId: localId,
                serverId: serverId,
                clientId: clientId,
                conversationId: conversationId,
                channelId: channelId,
                senderId: senderId,
                senderUsername: senderUsername,
                senderDisplayName: senderDisplayName,
                senderAvatarUrl: senderAvatarUrl,
                content: content,
                messageType: messageType,
                replyToMessageId: replyToMessageId,
                replyToJson: replyToJson,
                status: status,
                isPendingSync: isPendingSync,
                isEdited: isEdited,
                editedAt: editedAt,
                isPinned: isPinned,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                attachmentUrl: attachmentUrl,
                localAttachmentPath: localAttachmentPath,
                attachmentsJson: attachmentsJson,
                voiceNoteJson: voiceNoteJson,
                reactionsJson: reactionsJson,
                readByJson: readByJson,
                deliveredToJson: deliveredToJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> serverId = const Value.absent(),
                required String clientId,
                required String conversationId,
                Value<String?> channelId = const Value.absent(),
                required String senderId,
                Value<String?> senderUsername = const Value.absent(),
                Value<String?> senderDisplayName = const Value.absent(),
                Value<String?> senderAvatarUrl = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String> messageType = const Value.absent(),
                Value<String?> replyToMessageId = const Value.absent(),
                Value<String?> replyToJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isPendingSync = const Value.absent(),
                Value<bool> isEdited = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> attachmentUrl = const Value.absent(),
                Value<String?> localAttachmentPath = const Value.absent(),
                Value<String?> attachmentsJson = const Value.absent(),
                Value<String?> voiceNoteJson = const Value.absent(),
                Value<String?> reactionsJson = const Value.absent(),
                Value<String?> readByJson = const Value.absent(),
                Value<String?> deliveredToJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion.insert(
                localId: localId,
                serverId: serverId,
                clientId: clientId,
                conversationId: conversationId,
                channelId: channelId,
                senderId: senderId,
                senderUsername: senderUsername,
                senderDisplayName: senderDisplayName,
                senderAvatarUrl: senderAvatarUrl,
                content: content,
                messageType: messageType,
                replyToMessageId: replyToMessageId,
                replyToJson: replyToJson,
                status: status,
                isPendingSync: isPendingSync,
                isEdited: isEdited,
                editedAt: editedAt,
                isPinned: isPinned,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                attachmentUrl: attachmentUrl,
                localAttachmentPath: localAttachmentPath,
                attachmentsJson: attachmentsJson,
                voiceNoteJson: voiceNoteJson,
                reactionsJson: reactionsJson,
                readByJson: readByJson,
                deliveredToJson: deliveredToJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMessagesTable,
      LocalMessageData,
      $$LocalMessagesTableFilterComposer,
      $$LocalMessagesTableOrderingComposer,
      $$LocalMessagesTableAnnotationComposer,
      $$LocalMessagesTableCreateCompanionBuilder,
      $$LocalMessagesTableUpdateCompanionBuilder,
      (
        LocalMessageData,
        BaseReferences<_$AppDatabase, $LocalMessagesTable, LocalMessageData>,
      ),
      LocalMessageData,
      PrefetchHooks Function()
    >;
typedef $$LocalMessageAttachmentsTableCreateCompanionBuilder =
    LocalMessageAttachmentsCompanion Function({
      required String id,
      required String messageLocalId,
      Value<String?> fileId,
      Value<String?> remoteUrl,
      Value<String?> localAttachmentPath,
      Value<String> fileType,
      required String mimeType,
      required String originalName,
      Value<int> fileSize,
      Value<String> uploadStatus,
      Value<String> downloadStatus,
      Value<int?> width,
      Value<int?> height,
      Value<double?> duration,
      Value<String?> thumbnailUrl,
      Value<int> rowid,
    });
typedef $$LocalMessageAttachmentsTableUpdateCompanionBuilder =
    LocalMessageAttachmentsCompanion Function({
      Value<String> id,
      Value<String> messageLocalId,
      Value<String?> fileId,
      Value<String?> remoteUrl,
      Value<String?> localAttachmentPath,
      Value<String> fileType,
      Value<String> mimeType,
      Value<String> originalName,
      Value<int> fileSize,
      Value<String> uploadStatus,
      Value<String> downloadStatus,
      Value<int?> width,
      Value<int?> height,
      Value<double?> duration,
      Value<String?> thumbnailUrl,
      Value<int> rowid,
    });

class $$LocalMessageAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMessageAttachmentsTable> {
  $$LocalMessageAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageLocalId => $composableBuilder(
    column: $table.messageLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localAttachmentPath => $composableBuilder(
    column: $table.localAttachmentPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMessageAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMessageAttachmentsTable> {
  $$LocalMessageAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageLocalId => $composableBuilder(
    column: $table.messageLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localAttachmentPath => $composableBuilder(
    column: $table.localAttachmentPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMessageAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMessageAttachmentsTable> {
  $$LocalMessageAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageLocalId => $composableBuilder(
    column: $table.messageLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<String> get remoteUrl =>
      $composableBuilder(column: $table.remoteUrl, builder: (column) => column);

  GeneratedColumn<String> get localAttachmentPath => $composableBuilder(
    column: $table.localAttachmentPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<double> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );
}

class $$LocalMessageAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMessageAttachmentsTable,
          LocalMessageAttachmentData,
          $$LocalMessageAttachmentsTableFilterComposer,
          $$LocalMessageAttachmentsTableOrderingComposer,
          $$LocalMessageAttachmentsTableAnnotationComposer,
          $$LocalMessageAttachmentsTableCreateCompanionBuilder,
          $$LocalMessageAttachmentsTableUpdateCompanionBuilder,
          (
            LocalMessageAttachmentData,
            BaseReferences<
              _$AppDatabase,
              $LocalMessageAttachmentsTable,
              LocalMessageAttachmentData
            >,
          ),
          LocalMessageAttachmentData,
          PrefetchHooks Function()
        > {
  $$LocalMessageAttachmentsTableTableManager(
    _$AppDatabase db,
    $LocalMessageAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMessageAttachmentsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalMessageAttachmentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalMessageAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> messageLocalId = const Value.absent(),
                Value<String?> fileId = const Value.absent(),
                Value<String?> remoteUrl = const Value.absent(),
                Value<String?> localAttachmentPath = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<String> originalName = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> uploadStatus = const Value.absent(),
                Value<String> downloadStatus = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<double?> duration = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessageAttachmentsCompanion(
                id: id,
                messageLocalId: messageLocalId,
                fileId: fileId,
                remoteUrl: remoteUrl,
                localAttachmentPath: localAttachmentPath,
                fileType: fileType,
                mimeType: mimeType,
                originalName: originalName,
                fileSize: fileSize,
                uploadStatus: uploadStatus,
                downloadStatus: downloadStatus,
                width: width,
                height: height,
                duration: duration,
                thumbnailUrl: thumbnailUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String messageLocalId,
                Value<String?> fileId = const Value.absent(),
                Value<String?> remoteUrl = const Value.absent(),
                Value<String?> localAttachmentPath = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                required String mimeType,
                required String originalName,
                Value<int> fileSize = const Value.absent(),
                Value<String> uploadStatus = const Value.absent(),
                Value<String> downloadStatus = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<double?> duration = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessageAttachmentsCompanion.insert(
                id: id,
                messageLocalId: messageLocalId,
                fileId: fileId,
                remoteUrl: remoteUrl,
                localAttachmentPath: localAttachmentPath,
                fileType: fileType,
                mimeType: mimeType,
                originalName: originalName,
                fileSize: fileSize,
                uploadStatus: uploadStatus,
                downloadStatus: downloadStatus,
                width: width,
                height: height,
                duration: duration,
                thumbnailUrl: thumbnailUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMessageAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMessageAttachmentsTable,
      LocalMessageAttachmentData,
      $$LocalMessageAttachmentsTableFilterComposer,
      $$LocalMessageAttachmentsTableOrderingComposer,
      $$LocalMessageAttachmentsTableAnnotationComposer,
      $$LocalMessageAttachmentsTableCreateCompanionBuilder,
      $$LocalMessageAttachmentsTableUpdateCompanionBuilder,
      (
        LocalMessageAttachmentData,
        BaseReferences<
          _$AppDatabase,
          $LocalMessageAttachmentsTable,
          LocalMessageAttachmentData
        >,
      ),
      LocalMessageAttachmentData,
      PrefetchHooks Function()
    >;
typedef $$LocalWatchHistoryTableCreateCompanionBuilder =
    LocalWatchHistoryCompanion Function({
      required String id,
      required String videoId,
      required String userId,
      Value<int> positionSeconds,
      Value<int> durationSeconds,
      Value<double> progress,
      required DateTime watchedAt,
      Value<bool> completed,
      Value<bool> synced,
      Value<DateTime?> lastSyncAttemptAt,
      Value<int> rowid,
    });
typedef $$LocalWatchHistoryTableUpdateCompanionBuilder =
    LocalWatchHistoryCompanion Function({
      Value<String> id,
      Value<String> videoId,
      Value<String> userId,
      Value<int> positionSeconds,
      Value<int> durationSeconds,
      Value<double> progress,
      Value<DateTime> watchedAt,
      Value<bool> completed,
      Value<bool> synced,
      Value<DateTime?> lastSyncAttemptAt,
      Value<int> rowid,
    });

class $$LocalWatchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $LocalWatchHistoryTable> {
  $$LocalWatchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttemptAt => $composableBuilder(
    column: $table.lastSyncAttemptAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalWatchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalWatchHistoryTable> {
  $$LocalWatchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttemptAt => $composableBuilder(
    column: $table.lastSyncAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalWatchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalWatchHistoryTable> {
  $$LocalWatchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAttemptAt => $composableBuilder(
    column: $table.lastSyncAttemptAt,
    builder: (column) => column,
  );
}

class $$LocalWatchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalWatchHistoryTable,
          LocalWatchHistoryData,
          $$LocalWatchHistoryTableFilterComposer,
          $$LocalWatchHistoryTableOrderingComposer,
          $$LocalWatchHistoryTableAnnotationComposer,
          $$LocalWatchHistoryTableCreateCompanionBuilder,
          $$LocalWatchHistoryTableUpdateCompanionBuilder,
          (
            LocalWatchHistoryData,
            BaseReferences<
              _$AppDatabase,
              $LocalWatchHistoryTable,
              LocalWatchHistoryData
            >,
          ),
          LocalWatchHistoryData,
          PrefetchHooks Function()
        > {
  $$LocalWatchHistoryTableTableManager(
    _$AppDatabase db,
    $LocalWatchHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWatchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalWatchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalWatchHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> positionSeconds = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<DateTime?> lastSyncAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWatchHistoryCompanion(
                id: id,
                videoId: videoId,
                userId: userId,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                progress: progress,
                watchedAt: watchedAt,
                completed: completed,
                synced: synced,
                lastSyncAttemptAt: lastSyncAttemptAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String videoId,
                required String userId,
                Value<int> positionSeconds = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double> progress = const Value.absent(),
                required DateTime watchedAt,
                Value<bool> completed = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<DateTime?> lastSyncAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWatchHistoryCompanion.insert(
                id: id,
                videoId: videoId,
                userId: userId,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                progress: progress,
                watchedAt: watchedAt,
                completed: completed,
                synced: synced,
                lastSyncAttemptAt: lastSyncAttemptAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalWatchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalWatchHistoryTable,
      LocalWatchHistoryData,
      $$LocalWatchHistoryTableFilterComposer,
      $$LocalWatchHistoryTableOrderingComposer,
      $$LocalWatchHistoryTableAnnotationComposer,
      $$LocalWatchHistoryTableCreateCompanionBuilder,
      $$LocalWatchHistoryTableUpdateCompanionBuilder,
      (
        LocalWatchHistoryData,
        BaseReferences<
          _$AppDatabase,
          $LocalWatchHistoryTable,
          LocalWatchHistoryData
        >,
      ),
      LocalWatchHistoryData,
      PrefetchHooks Function()
    >;
typedef $$LocalSearchHistoryTableCreateCompanionBuilder =
    LocalSearchHistoryCompanion Function({
      required String id,
      required String query,
      Value<String?> category,
      Value<String?> userId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalSearchHistoryTableUpdateCompanionBuilder =
    LocalSearchHistoryCompanion Function({
      Value<String> id,
      Value<String> query,
      Value<String?> category,
      Value<String?> userId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalSearchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSearchHistoryTable> {
  $$LocalSearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSearchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSearchHistoryTable> {
  $$LocalSearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSearchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSearchHistoryTable> {
  $$LocalSearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalSearchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSearchHistoryTable,
          LocalSearchHistoryData,
          $$LocalSearchHistoryTableFilterComposer,
          $$LocalSearchHistoryTableOrderingComposer,
          $$LocalSearchHistoryTableAnnotationComposer,
          $$LocalSearchHistoryTableCreateCompanionBuilder,
          $$LocalSearchHistoryTableUpdateCompanionBuilder,
          (
            LocalSearchHistoryData,
            BaseReferences<
              _$AppDatabase,
              $LocalSearchHistoryTable,
              LocalSearchHistoryData
            >,
          ),
          LocalSearchHistoryData,
          PrefetchHooks Function()
        > {
  $$LocalSearchHistoryTableTableManager(
    _$AppDatabase db,
    $LocalSearchHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSearchHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> query = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSearchHistoryCompanion(
                id: id,
                query: query,
                category: category,
                userId: userId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String query,
                Value<String?> category = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalSearchHistoryCompanion.insert(
                id: id,
                query: query,
                category: category,
                userId: userId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSearchHistoryTable,
      LocalSearchHistoryData,
      $$LocalSearchHistoryTableFilterComposer,
      $$LocalSearchHistoryTableOrderingComposer,
      $$LocalSearchHistoryTableAnnotationComposer,
      $$LocalSearchHistoryTableCreateCompanionBuilder,
      $$LocalSearchHistoryTableUpdateCompanionBuilder,
      (
        LocalSearchHistoryData,
        BaseReferences<
          _$AppDatabase,
          $LocalSearchHistoryTable,
          LocalSearchHistoryData
        >,
      ),
      LocalSearchHistoryData,
      PrefetchHooks Function()
    >;
typedef $$LocalFeedItemsTableCreateCompanionBuilder =
    LocalFeedItemsCompanion Function({
      required String id,
      Value<String> feedType,
      required String title,
      Value<String?> caption,
      Value<String?> thumbnailUrl,
      Value<String?> videoUrl,
      Value<String?> hlsUrl,
      Value<int> duration,
      Value<String?> authorId,
      Value<String?> authorUsername,
      Value<String?> authorDisplayName,
      Value<String?> authorAvatarUrl,
      Value<int> viewsCount,
      Value<int> likesCount,
      Value<int> commentsCount,
      Value<bool> isLiked,
      Value<bool> isSaved,
      Value<DateTime?> publishedAt,
      required DateTime createdAt,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$LocalFeedItemsTableUpdateCompanionBuilder =
    LocalFeedItemsCompanion Function({
      Value<String> id,
      Value<String> feedType,
      Value<String> title,
      Value<String?> caption,
      Value<String?> thumbnailUrl,
      Value<String?> videoUrl,
      Value<String?> hlsUrl,
      Value<int> duration,
      Value<String?> authorId,
      Value<String?> authorUsername,
      Value<String?> authorDisplayName,
      Value<String?> authorAvatarUrl,
      Value<int> viewsCount,
      Value<int> likesCount,
      Value<int> commentsCount,
      Value<bool> isLiked,
      Value<bool> isSaved,
      Value<DateTime?> publishedAt,
      Value<DateTime> createdAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$LocalFeedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFeedItemsTable> {
  $$LocalFeedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedType => $composableBuilder(
    column: $table.feedType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlsUrl => $composableBuilder(
    column: $table.hlsUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorUsername => $composableBuilder(
    column: $table.authorUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorDisplayName => $composableBuilder(
    column: $table.authorDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorAvatarUrl => $composableBuilder(
    column: $table.authorAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get viewsCount => $composableBuilder(
    column: $table.viewsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get likesCount => $composableBuilder(
    column: $table.likesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get commentsCount => $composableBuilder(
    column: $table.commentsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLiked => $composableBuilder(
    column: $table.isLiked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSaved => $composableBuilder(
    column: $table.isSaved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalFeedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFeedItemsTable> {
  $$LocalFeedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedType => $composableBuilder(
    column: $table.feedType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlsUrl => $composableBuilder(
    column: $table.hlsUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorUsername => $composableBuilder(
    column: $table.authorUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorDisplayName => $composableBuilder(
    column: $table.authorDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorAvatarUrl => $composableBuilder(
    column: $table.authorAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get viewsCount => $composableBuilder(
    column: $table.viewsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get likesCount => $composableBuilder(
    column: $table.likesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get commentsCount => $composableBuilder(
    column: $table.commentsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLiked => $composableBuilder(
    column: $table.isLiked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSaved => $composableBuilder(
    column: $table.isSaved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalFeedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFeedItemsTable> {
  $$LocalFeedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get feedType =>
      $composableBuilder(column: $table.feedType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<String> get hlsUrl =>
      $composableBuilder(column: $table.hlsUrl, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get authorUsername => $composableBuilder(
    column: $table.authorUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorDisplayName => $composableBuilder(
    column: $table.authorDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorAvatarUrl => $composableBuilder(
    column: $table.authorAvatarUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get viewsCount => $composableBuilder(
    column: $table.viewsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get likesCount => $composableBuilder(
    column: $table.likesCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get commentsCount => $composableBuilder(
    column: $table.commentsCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLiked =>
      $composableBuilder(column: $table.isLiked, builder: (column) => column);

  GeneratedColumn<bool> get isSaved =>
      $composableBuilder(column: $table.isSaved, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LocalFeedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalFeedItemsTable,
          LocalFeedItemData,
          $$LocalFeedItemsTableFilterComposer,
          $$LocalFeedItemsTableOrderingComposer,
          $$LocalFeedItemsTableAnnotationComposer,
          $$LocalFeedItemsTableCreateCompanionBuilder,
          $$LocalFeedItemsTableUpdateCompanionBuilder,
          (
            LocalFeedItemData,
            BaseReferences<
              _$AppDatabase,
              $LocalFeedItemsTable,
              LocalFeedItemData
            >,
          ),
          LocalFeedItemData,
          PrefetchHooks Function()
        > {
  $$LocalFeedItemsTableTableManager(
    _$AppDatabase db,
    $LocalFeedItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFeedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFeedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFeedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> feedType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> hlsUrl = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String?> authorId = const Value.absent(),
                Value<String?> authorUsername = const Value.absent(),
                Value<String?> authorDisplayName = const Value.absent(),
                Value<String?> authorAvatarUrl = const Value.absent(),
                Value<int> viewsCount = const Value.absent(),
                Value<int> likesCount = const Value.absent(),
                Value<int> commentsCount = const Value.absent(),
                Value<bool> isLiked = const Value.absent(),
                Value<bool> isSaved = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFeedItemsCompanion(
                id: id,
                feedType: feedType,
                title: title,
                caption: caption,
                thumbnailUrl: thumbnailUrl,
                videoUrl: videoUrl,
                hlsUrl: hlsUrl,
                duration: duration,
                authorId: authorId,
                authorUsername: authorUsername,
                authorDisplayName: authorDisplayName,
                authorAvatarUrl: authorAvatarUrl,
                viewsCount: viewsCount,
                likesCount: likesCount,
                commentsCount: commentsCount,
                isLiked: isLiked,
                isSaved: isSaved,
                publishedAt: publishedAt,
                createdAt: createdAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> feedType = const Value.absent(),
                required String title,
                Value<String?> caption = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> hlsUrl = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String?> authorId = const Value.absent(),
                Value<String?> authorUsername = const Value.absent(),
                Value<String?> authorDisplayName = const Value.absent(),
                Value<String?> authorAvatarUrl = const Value.absent(),
                Value<int> viewsCount = const Value.absent(),
                Value<int> likesCount = const Value.absent(),
                Value<int> commentsCount = const Value.absent(),
                Value<bool> isLiked = const Value.absent(),
                Value<bool> isSaved = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalFeedItemsCompanion.insert(
                id: id,
                feedType: feedType,
                title: title,
                caption: caption,
                thumbnailUrl: thumbnailUrl,
                videoUrl: videoUrl,
                hlsUrl: hlsUrl,
                duration: duration,
                authorId: authorId,
                authorUsername: authorUsername,
                authorDisplayName: authorDisplayName,
                authorAvatarUrl: authorAvatarUrl,
                viewsCount: viewsCount,
                likesCount: likesCount,
                commentsCount: commentsCount,
                isLiked: isLiked,
                isSaved: isSaved,
                publishedAt: publishedAt,
                createdAt: createdAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalFeedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalFeedItemsTable,
      LocalFeedItemData,
      $$LocalFeedItemsTableFilterComposer,
      $$LocalFeedItemsTableOrderingComposer,
      $$LocalFeedItemsTableAnnotationComposer,
      $$LocalFeedItemsTableCreateCompanionBuilder,
      $$LocalFeedItemsTableUpdateCompanionBuilder,
      (
        LocalFeedItemData,
        BaseReferences<_$AppDatabase, $LocalFeedItemsTable, LocalFeedItemData>,
      ),
      LocalFeedItemData,
      PrefetchHooks Function()
    >;
typedef $$LocalCalendarNotesTableCreateCompanionBuilder =
    LocalCalendarNotesCompanion Function({
      required String id,
      required String userId,
      required int ethiopianYear,
      required int ethiopianMonth,
      required int ethiopianDay,
      required DateTime gregorianDate,
      Value<String?> title,
      Value<String?> content,
      Value<bool> hasReminder,
      Value<DateTime?> reminderDateTime,
      Value<bool> reminderNotified,
      Value<String> reminderRepeat,
      Value<int?> reminderEthiopianMonth,
      Value<int?> reminderEthiopianDay,
      Value<int?> reminderHour,
      Value<int?> reminderMinute,
      Value<String> reminderTimezone,
      Value<DateTime?> reminderNextOccurrence,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isSynced,
      Value<bool> isPendingDelete,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$LocalCalendarNotesTableUpdateCompanionBuilder =
    LocalCalendarNotesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> ethiopianYear,
      Value<int> ethiopianMonth,
      Value<int> ethiopianDay,
      Value<DateTime> gregorianDate,
      Value<String?> title,
      Value<String?> content,
      Value<bool> hasReminder,
      Value<DateTime?> reminderDateTime,
      Value<bool> reminderNotified,
      Value<String> reminderRepeat,
      Value<int?> reminderEthiopianMonth,
      Value<int?> reminderEthiopianDay,
      Value<int?> reminderHour,
      Value<int?> reminderMinute,
      Value<String> reminderTimezone,
      Value<DateTime?> reminderNextOccurrence,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isSynced,
      Value<bool> isPendingDelete,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$LocalCalendarNotesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCalendarNotesTable> {
  $$LocalCalendarNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ethiopianYear => $composableBuilder(
    column: $table.ethiopianYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ethiopianMonth => $composableBuilder(
    column: $table.ethiopianMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ethiopianDay => $composableBuilder(
    column: $table.ethiopianDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get gregorianDate => $composableBuilder(
    column: $table.gregorianDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasReminder => $composableBuilder(
    column: $table.hasReminder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reminderDateTime => $composableBuilder(
    column: $table.reminderDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderNotified => $composableBuilder(
    column: $table.reminderNotified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderRepeat => $composableBuilder(
    column: $table.reminderRepeat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderEthiopianMonth => $composableBuilder(
    column: $table.reminderEthiopianMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderEthiopianDay => $composableBuilder(
    column: $table.reminderEthiopianDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTimezone => $composableBuilder(
    column: $table.reminderTimezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reminderNextOccurrence => $composableBuilder(
    column: $table.reminderNextOccurrence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCalendarNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCalendarNotesTable> {
  $$LocalCalendarNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ethiopianYear => $composableBuilder(
    column: $table.ethiopianYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ethiopianMonth => $composableBuilder(
    column: $table.ethiopianMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ethiopianDay => $composableBuilder(
    column: $table.ethiopianDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get gregorianDate => $composableBuilder(
    column: $table.gregorianDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasReminder => $composableBuilder(
    column: $table.hasReminder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reminderDateTime => $composableBuilder(
    column: $table.reminderDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderNotified => $composableBuilder(
    column: $table.reminderNotified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderRepeat => $composableBuilder(
    column: $table.reminderRepeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderEthiopianMonth => $composableBuilder(
    column: $table.reminderEthiopianMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderEthiopianDay => $composableBuilder(
    column: $table.reminderEthiopianDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTimezone => $composableBuilder(
    column: $table.reminderTimezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reminderNextOccurrence => $composableBuilder(
    column: $table.reminderNextOccurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCalendarNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCalendarNotesTable> {
  $$LocalCalendarNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get ethiopianYear => $composableBuilder(
    column: $table.ethiopianYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ethiopianMonth => $composableBuilder(
    column: $table.ethiopianMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ethiopianDay => $composableBuilder(
    column: $table.ethiopianDay,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get gregorianDate => $composableBuilder(
    column: $table.gregorianDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get hasReminder => $composableBuilder(
    column: $table.hasReminder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reminderDateTime => $composableBuilder(
    column: $table.reminderDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reminderNotified => $composableBuilder(
    column: $table.reminderNotified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderRepeat => $composableBuilder(
    column: $table.reminderRepeat,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderEthiopianMonth => $composableBuilder(
    column: $table.reminderEthiopianMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderEthiopianDay => $composableBuilder(
    column: $table.reminderEthiopianDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTimezone => $composableBuilder(
    column: $table.reminderTimezone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reminderNextOccurrence => $composableBuilder(
    column: $table.reminderNextOccurrence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$LocalCalendarNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCalendarNotesTable,
          LocalCalendarNoteData,
          $$LocalCalendarNotesTableFilterComposer,
          $$LocalCalendarNotesTableOrderingComposer,
          $$LocalCalendarNotesTableAnnotationComposer,
          $$LocalCalendarNotesTableCreateCompanionBuilder,
          $$LocalCalendarNotesTableUpdateCompanionBuilder,
          (
            LocalCalendarNoteData,
            BaseReferences<
              _$AppDatabase,
              $LocalCalendarNotesTable,
              LocalCalendarNoteData
            >,
          ),
          LocalCalendarNoteData,
          PrefetchHooks Function()
        > {
  $$LocalCalendarNotesTableTableManager(
    _$AppDatabase db,
    $LocalCalendarNotesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCalendarNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCalendarNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCalendarNotesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> ethiopianYear = const Value.absent(),
                Value<int> ethiopianMonth = const Value.absent(),
                Value<int> ethiopianDay = const Value.absent(),
                Value<DateTime> gregorianDate = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<bool> hasReminder = const Value.absent(),
                Value<DateTime?> reminderDateTime = const Value.absent(),
                Value<bool> reminderNotified = const Value.absent(),
                Value<String> reminderRepeat = const Value.absent(),
                Value<int?> reminderEthiopianMonth = const Value.absent(),
                Value<int?> reminderEthiopianDay = const Value.absent(),
                Value<int?> reminderHour = const Value.absent(),
                Value<int?> reminderMinute = const Value.absent(),
                Value<String> reminderTimezone = const Value.absent(),
                Value<DateTime?> reminderNextOccurrence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isPendingDelete = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarNotesCompanion(
                id: id,
                userId: userId,
                ethiopianYear: ethiopianYear,
                ethiopianMonth: ethiopianMonth,
                ethiopianDay: ethiopianDay,
                gregorianDate: gregorianDate,
                title: title,
                content: content,
                hasReminder: hasReminder,
                reminderDateTime: reminderDateTime,
                reminderNotified: reminderNotified,
                reminderRepeat: reminderRepeat,
                reminderEthiopianMonth: reminderEthiopianMonth,
                reminderEthiopianDay: reminderEthiopianDay,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                reminderTimezone: reminderTimezone,
                reminderNextOccurrence: reminderNextOccurrence,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isSynced: isSynced,
                isPendingDelete: isPendingDelete,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required int ethiopianYear,
                required int ethiopianMonth,
                required int ethiopianDay,
                required DateTime gregorianDate,
                Value<String?> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<bool> hasReminder = const Value.absent(),
                Value<DateTime?> reminderDateTime = const Value.absent(),
                Value<bool> reminderNotified = const Value.absent(),
                Value<String> reminderRepeat = const Value.absent(),
                Value<int?> reminderEthiopianMonth = const Value.absent(),
                Value<int?> reminderEthiopianDay = const Value.absent(),
                Value<int?> reminderHour = const Value.absent(),
                Value<int?> reminderMinute = const Value.absent(),
                Value<String> reminderTimezone = const Value.absent(),
                Value<DateTime?> reminderNextOccurrence = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isPendingDelete = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarNotesCompanion.insert(
                id: id,
                userId: userId,
                ethiopianYear: ethiopianYear,
                ethiopianMonth: ethiopianMonth,
                ethiopianDay: ethiopianDay,
                gregorianDate: gregorianDate,
                title: title,
                content: content,
                hasReminder: hasReminder,
                reminderDateTime: reminderDateTime,
                reminderNotified: reminderNotified,
                reminderRepeat: reminderRepeat,
                reminderEthiopianMonth: reminderEthiopianMonth,
                reminderEthiopianDay: reminderEthiopianDay,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                reminderTimezone: reminderTimezone,
                reminderNextOccurrence: reminderNextOccurrence,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isSynced: isSynced,
                isPendingDelete: isPendingDelete,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCalendarNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCalendarNotesTable,
      LocalCalendarNoteData,
      $$LocalCalendarNotesTableFilterComposer,
      $$LocalCalendarNotesTableOrderingComposer,
      $$LocalCalendarNotesTableAnnotationComposer,
      $$LocalCalendarNotesTableCreateCompanionBuilder,
      $$LocalCalendarNotesTableUpdateCompanionBuilder,
      (
        LocalCalendarNoteData,
        BaseReferences<
          _$AppDatabase,
          $LocalCalendarNotesTable,
          LocalCalendarNoteData
        >,
      ),
      LocalCalendarNoteData,
      PrefetchHooks Function()
    >;
typedef $$LocalCalendarNoteMediaTableCreateCompanionBuilder =
    LocalCalendarNoteMediaCompanion Function({
      required String id,
      required String noteId,
      required String fileId,
      required int order,
      Value<String?> caption,
      Value<String?> fileUrl,
      Value<String?> fileName,
      Value<String?> mimeType,
      Value<int?> fileSize,
      required DateTime createdAt,
      Value<bool> isSynced,
      Value<bool> isPendingDelete,
      Value<int> rowid,
    });
typedef $$LocalCalendarNoteMediaTableUpdateCompanionBuilder =
    LocalCalendarNoteMediaCompanion Function({
      Value<String> id,
      Value<String> noteId,
      Value<String> fileId,
      Value<int> order,
      Value<String?> caption,
      Value<String?> fileUrl,
      Value<String?> fileName,
      Value<String?> mimeType,
      Value<int?> fileSize,
      Value<DateTime> createdAt,
      Value<bool> isSynced,
      Value<bool> isPendingDelete,
      Value<int> rowid,
    });

class $$LocalCalendarNoteMediaTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCalendarNoteMediaTable> {
  $$LocalCalendarNoteMediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCalendarNoteMediaTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCalendarNoteMediaTable> {
  $$LocalCalendarNoteMediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCalendarNoteMediaTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCalendarNoteMediaTable> {
  $$LocalCalendarNoteMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<String> get fileUrl =>
      $composableBuilder(column: $table.fileUrl, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => column,
  );
}

class $$LocalCalendarNoteMediaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCalendarNoteMediaTable,
          LocalCalendarNoteMediaData,
          $$LocalCalendarNoteMediaTableFilterComposer,
          $$LocalCalendarNoteMediaTableOrderingComposer,
          $$LocalCalendarNoteMediaTableAnnotationComposer,
          $$LocalCalendarNoteMediaTableCreateCompanionBuilder,
          $$LocalCalendarNoteMediaTableUpdateCompanionBuilder,
          (
            LocalCalendarNoteMediaData,
            BaseReferences<
              _$AppDatabase,
              $LocalCalendarNoteMediaTable,
              LocalCalendarNoteMediaData
            >,
          ),
          LocalCalendarNoteMediaData,
          PrefetchHooks Function()
        > {
  $$LocalCalendarNoteMediaTableTableManager(
    _$AppDatabase db,
    $LocalCalendarNoteMediaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCalendarNoteMediaTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalCalendarNoteMediaTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalCalendarNoteMediaTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> noteId = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<String?> fileUrl = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isPendingDelete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarNoteMediaCompanion(
                id: id,
                noteId: noteId,
                fileId: fileId,
                order: order,
                caption: caption,
                fileUrl: fileUrl,
                fileName: fileName,
                mimeType: mimeType,
                fileSize: fileSize,
                createdAt: createdAt,
                isSynced: isSynced,
                isPendingDelete: isPendingDelete,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String noteId,
                required String fileId,
                required int order,
                Value<String?> caption = const Value.absent(),
                Value<String?> fileUrl = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isPendingDelete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarNoteMediaCompanion.insert(
                id: id,
                noteId: noteId,
                fileId: fileId,
                order: order,
                caption: caption,
                fileUrl: fileUrl,
                fileName: fileName,
                mimeType: mimeType,
                fileSize: fileSize,
                createdAt: createdAt,
                isSynced: isSynced,
                isPendingDelete: isPendingDelete,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCalendarNoteMediaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCalendarNoteMediaTable,
      LocalCalendarNoteMediaData,
      $$LocalCalendarNoteMediaTableFilterComposer,
      $$LocalCalendarNoteMediaTableOrderingComposer,
      $$LocalCalendarNoteMediaTableAnnotationComposer,
      $$LocalCalendarNoteMediaTableCreateCompanionBuilder,
      $$LocalCalendarNoteMediaTableUpdateCompanionBuilder,
      (
        LocalCalendarNoteMediaData,
        BaseReferences<
          _$AppDatabase,
          $LocalCalendarNoteMediaTable,
          LocalCalendarNoteMediaData
        >,
      ),
      LocalCalendarNoteMediaData,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String id,
      required String operationType,
      required String entityType,
      required String entityId,
      required String payload,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> retryCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextRetryAt,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> operationType,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> retryCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextRetryAt,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                operationType: operationType,
                entityType: entityType,
                entityId: entityId,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                retryCount: retryCount,
                lastAttemptAt: lastAttemptAt,
                nextRetryAt: nextRetryAt,
                status: status,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String operationType,
                required String entityType,
                required String entityId,
                required String payload,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                operationType: operationType,
                entityType: entityType,
                entityId: entityId,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                retryCount: retryCount,
                lastAttemptAt: lastAttemptAt,
                nextRetryAt: nextRetryAt,
                status: status,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalUsersTableTableManager get localUsers =>
      $$LocalUsersTableTableManager(_db, _db.localUsers);
  $$LocalVideosTableTableManager get localVideos =>
      $$LocalVideosTableTableManager(_db, _db.localVideos);
  $$LocalConversationsTableTableManager get localConversations =>
      $$LocalConversationsTableTableManager(_db, _db.localConversations);
  $$LocalMessagesTableTableManager get localMessages =>
      $$LocalMessagesTableTableManager(_db, _db.localMessages);
  $$LocalMessageAttachmentsTableTableManager get localMessageAttachments =>
      $$LocalMessageAttachmentsTableTableManager(
        _db,
        _db.localMessageAttachments,
      );
  $$LocalWatchHistoryTableTableManager get localWatchHistory =>
      $$LocalWatchHistoryTableTableManager(_db, _db.localWatchHistory);
  $$LocalSearchHistoryTableTableManager get localSearchHistory =>
      $$LocalSearchHistoryTableTableManager(_db, _db.localSearchHistory);
  $$LocalFeedItemsTableTableManager get localFeedItems =>
      $$LocalFeedItemsTableTableManager(_db, _db.localFeedItems);
  $$LocalCalendarNotesTableTableManager get localCalendarNotes =>
      $$LocalCalendarNotesTableTableManager(_db, _db.localCalendarNotes);
  $$LocalCalendarNoteMediaTableTableManager get localCalendarNoteMedia =>
      $$LocalCalendarNoteMediaTableTableManager(
        _db,
        _db.localCalendarNoteMedia,
      );
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
