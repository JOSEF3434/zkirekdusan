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
  String toToken() => '@[${type.prefix}:$id:$username]';
}

// ── Content item returned by /api/search/unified ──────────────────────────────

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
    final title = json['title'] as String? ??
        json['name'] as String? ??
        json['content'] as String? ??
        json['username'] as String? ??
        '';
    final thumb = json['thumbnailUrl'] as String? ??
        json['thumbnailFileUrl'] as String? ??
        json['avatarUrl'] as String? ??
        json['coverUrl'] as String?;

    String? sub;
    if (type == 'video') sub = json['channelName'] as String?;
    if (type == 'user') sub = '@${json['username'] ?? ''}';
    if (type == 'group' || type == 'channel') sub = json['slug'] as String?;

    return ContentSearchItem(
      id: json['id'] as String,
      entityType: type,
      title: title,
      thumbnailUrl: thumb,
      subtitle: sub,
    );
  }

  /// Build the content reference token to insert into text.
  String toToken() => '#[$entityType:$id:$title]';

  MentionEntityType? get mentionEntityType =>
      MentionEntityTypeX.fromPrefix(entityType);
}
