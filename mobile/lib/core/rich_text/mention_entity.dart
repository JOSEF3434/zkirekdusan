// lib/core/rich_text/mention_entity.dart
//
// Data models for rich-text entities (@mentions and # content references).
// Storage format inside text strings:
//   @[user:uuid:username]       — user mention
//   @[group:uuid:slug]          — group mention
//   @[channel:uuid:handle]      — channel mention
//   #[video:uuid:Title]         — video content reference
//   #[book:uuid:Title]          — book content reference
//   #[post:uuid:Title]          — post reference
//   #[stream:uuid:Title]        — live stream reference
//
// Plain text (old content) renders normally — no parser change needed.

/// Recognized entity types stored inline in content strings.
enum MentionEntityType {
  user,
  group,
  channel,
  video,
  book,
  post,
  stream,
}

extension MentionEntityTypeX on MentionEntityType {
  String get prefix => switch (this) {
        MentionEntityType.user => 'user',
        MentionEntityType.group => 'group',
        MentionEntityType.channel => 'channel',
        MentionEntityType.video => 'video',
        MentionEntityType.book => 'book',
        MentionEntityType.post => 'post',
        MentionEntityType.stream => 'stream',
      };

  static MentionEntityType? fromPrefix(String s) => switch (s) {
        'user' => MentionEntityType.user,
        'group' => MentionEntityType.group,
        'channel' => MentionEntityType.channel,
        'video' => MentionEntityType.video,
        'book' => MentionEntityType.book,
        'post' => MentionEntityType.post,
        'stream' => MentionEntityType.stream,
        _ => null,
      };
}

/// A parsed entity inside a rich-text string.
class RichTextEntity {
  /// Start offset inside the raw string (inclusive).
  final int start;

  /// End offset inside the raw string (exclusive).
  final int end;

  final MentionEntityType type;

  /// Stable database ID of the referenced entity.
  final String id;

  /// Display label (username / title).
  final String label;

  const RichTextEntity({
    required this.start,
    required this.end,
    required this.type,
    required this.id,
    required this.label,
  });

  /// The trigger character: `@` for mention types, `#` for content refs.
  String get triggerChar =>
      (type == MentionEntityType.user ||
              type == MentionEntityType.group ||
              type == MentionEntityType.channel)
          ? '@'
          : '#';

  /// The raw token as stored in content, e.g. `@[user:uuid:username]`.
  String get rawToken => '$triggerChar[${type.prefix}:$id:$label]';

  /// Visible label shown to users, e.g. `@username` or `#VideoTitle`.
  String get displayText => '$triggerChar$label';
}

// ── Autocomplete suggestion returned by /api/mentions/* ───────────────────────

class MentionSuggestion {
  final String id;
  final MentionEntityType type;

  /// Unique handle used in the token (username / slug / handle).
  final String username;

  final String displayName;
  final String? avatarUrl;
  final bool isVerified;

  const MentionSuggestion({
    required this.id,
    required this.type,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isVerified = false,
  });

  factory MentionSuggestion.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'user';
    return MentionSuggestion(
      id: json['id'] as String,
      type: MentionEntityTypeX.fromPrefix(typeStr) ?? MentionEntityType.user,
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  /// Build the token string to insert into the text field.
  /// Square brackets in the username are stripped to avoid breaking the token format.
  String toToken() {
    final safeUsername = username.replaceAll('[', '(').replaceAll(']', ')');
    return '@[${type.prefix}:$id:$safeUsername]';
  }
}

// ── Content item returned by /api/search/unified ──────────────────────────────

/// Safely extracts a thumbnail/avatar URL from a unified search result JSON map.
/// Handles multiple backend structures: direct thumbnailUrl, nested avatarFile,
/// nested profile.avatar, flat avatarUrl, etc.
String? _extractThumbnail(Map<String, dynamic> json) {
  if (json['thumbnailUrl'] is String) return json['thumbnailUrl'] as String;
  if (json['thumbnailFileUrl'] is String) return json['thumbnailFileUrl'] as String;
  final avatarFile = json['avatarFile'];
  if (avatarFile is Map && avatarFile['url'] is String) return avatarFile['url'] as String;
  final avatar = json['avatar'];
  if (avatar is Map && avatar['url'] is String) return avatar['url'] as String;
  final profile = json['profile'];
  if (profile is Map) {
    final pAvatar = profile['avatar'];
    if (pAvatar is Map && pAvatar['url'] is String) return pAvatar['url'] as String;
  }
  if (json['avatarUrl'] is String) return json['avatarUrl'] as String;
  if (json['coverUrl'] is String) return json['coverUrl'] as String;
  return null;
}

class ContentSearchItem {
  final String id;
  final String entityType; // 'video' | 'book' | 'group' | 'channel' | 'post' | 'stream' | 'user'
  final String title;
  final String? thumbnailUrl;
  final String? subtitle;

  const ContentSearchItem({
    required this.id,
    required this.entityType,
    required this.title,
    this.thumbnailUrl,
    this.subtitle,
  });

  factory ContentSearchItem.fromJson(Map<String, dynamic> json) {
    final type = json['entityType'] as String? ?? 'video';

    // Title resolution — different entity types use different field names
    final title = json['title'] as String? ??
        json['name'] as String? ??
        json['content'] as String? ??
        json['username'] as String? ??
        '';

    // Thumbnail resolution — video has thumbnailUrl directly on the object;
    // channels use avatarFile.url; users use profile.avatar.url; groups avatarUrl
    final thumb = _extractThumbnail(json);

    // Subtitle resolution per entity type
    String? sub;
    if (type == 'video') {
      sub = json['channelName'] as String? ??
          (json['videoChannel'] as Map?)?['name'] as String?;
    } else if (type == 'user') {
      sub = '@${json['username'] ?? ''}';
    } else if (type == 'group') {
      sub = json['slug'] as String? ?? json['handle'] as String?;
    } else if (type == 'channel') {
      sub = json['handle'] as String? ?? json['slug'] as String?;
    } else if (type == 'post') {
      sub = json['author']?['username'] as String?;
    } else if (type == 'stream') {
      sub = json['channelName'] as String? ??
          (json['channel'] as Map?)?['name'] as String?;
    }

    return ContentSearchItem(
      id: json['id'] as String,
      entityType: type,
      title: title,
      thumbnailUrl: thumb,
      subtitle: sub,
    );
  }

  /// Build the content reference token to insert into text.
  /// Square brackets in the title are stripped to avoid breaking the token format.
  String toToken() {
    final safeTitle = title.replaceAll('[', '(').replaceAll(']', ')');
    return '#[$entityType:$id:$safeTitle]';
  }

  MentionEntityType? get mentionEntityType =>
      MentionEntityTypeX.fromPrefix(entityType);
}
