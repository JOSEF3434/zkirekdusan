// lib/core/rich_text/mention_entity.dart
//
// Data models for rich-text entities (@mentions and # content references).
// Canonical inline storage format:
//   @[user:uuid:username]       — user mention (sends MENTION notification)
//   @[group:uuid:slug]          — group mention
//   @[channel:uuid:handle]      — channel mention
//   #[video:uuid:Title]         — video reference
//   #[book:uuid:Title]          — book / dictionary reference
//   #[post:uuid:Title]          — post reference
//   #[stream:uuid:Title]        — live / scheduled stream reference
//   #[reel:uuid:Title]          — reel reference
//   #[user:uuid:Name]           — user reference from # search (no mention notification)
//   #[group:uuid:Name]          — group reference from # search
//   #[channel:uuid:Name]        — channel reference from # search

import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';

/// Recognized entity types stored inline in content strings.
enum MentionEntityType {
  user,
  group,
  channel,
  video,
  book,
  post,
  stream,
  reel,
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
    MentionEntityType.reel => 'reel',
  };

  static MentionEntityType? fromPrefix(String s) => switch (s.toLowerCase()) {
    'user' => MentionEntityType.user,
    'group' => MentionEntityType.group,
    'channel' => MentionEntityType.channel,
    'video' => MentionEntityType.video,
    'book' => MentionEntityType.book,
    'post' => MentionEntityType.post,
    'stream' => MentionEntityType.stream,
    'reel' => MentionEntityType.reel,
    _ => null,
  };
}

String sanitizeTokenLabel(String raw) {
  return raw
      .replaceAll('[', '(')
      .replaceAll(']', ')')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// A parsed entity inside a rich-text string.
class RichTextEntity {
  final int start;
  final int end;
  final String triggerChar; // '@' or '#'
  final MentionEntityType type;
  final String id;
  final String label;

  const RichTextEntity({
    required this.start,
    required this.end,
    required this.triggerChar,
    required this.type,
    required this.id,
    required this.label,
  });

  String get rawToken => '$triggerChar[${type.prefix}:$id:$label]';
  String get displayText => '$triggerChar$label';
}

// ── Autocomplete suggestion returned by /api/mentions/* ───────────────────────

class MentionSuggestion {
  final String id;
  final MentionEntityType type;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final String? subtitle;

  const MentionSuggestion({
    required this.id,
    required this.type,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isVerified = false,
    this.subtitle,
  });

  factory MentionSuggestion.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'user';
    final rawUsername = (json['username'] as String? ?? '').replaceFirst(
      RegExp(r'^@+'),
      '',
    );
    return MentionSuggestion(
      id: json['id'] as String? ?? '',
      type: MentionEntityTypeX.fromPrefix(typeStr) ?? MentionEntityType.user,
      username: rawUsername,
      displayName: json['displayName'] as String? ?? rawUsername,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      subtitle: json['subtitle'] as String?,
    );
  }

  /// Inserts an explicit `@[type:id:label]` mention token.
  String toToken() {
    final labelSource = username.isNotEmpty ? username : displayName;
    final safeLabel = sanitizeTokenLabel(labelSource);
    return '@[${type.prefix}:$id:${safeLabel.isEmpty ? 'user' : safeLabel}]';
  }
}

// ── Unified Global Search item used by the # content picker ───────────────────

class ContentSearchItem {
  final String id;
  final String entityType; // 'video' | 'book' | 'channel' | 'group' | 'user' | 'post' | 'stream' | 'reel'
  final String title;
  final String? thumbnailUrl;
  final String? subtitle;
  final String? badgeLabel;
  final bool isVerified;
  final bool isLive;

  const ContentSearchItem({
    required this.id,
    required this.entityType,
    required this.title,
    this.thumbnailUrl,
    this.subtitle,
    this.badgeLabel,
    this.isVerified = false,
    this.isLive = false,
  });

  factory ContentSearchItem.fromVideo(VideoResponseDto v) {
    final parts = <String>[
      if (v.channelName != null && v.channelName!.isNotEmpty) v.channelName!,
      if (v.viewsCount > 0) '${v.viewsCount} views',
    ];
    return ContentSearchItem(
      id: v.id,
      entityType: 'video',
      title: v.title,
      thumbnailUrl: v.thumbnailUrl,
      subtitle: parts.isEmpty ? 'Video' : parts.join(' · '),
      badgeLabel: 'Video',
    );
  }

  factory ContentSearchItem.fromBook(SearchBookDto b) {
    final parts = <String>[
      if (b.isDictionary) 'Dictionary',
      if (b.author != null && b.author!.isNotEmpty) b.author!,
      if (b.titleAm != null && b.titleAm!.isNotEmpty && b.titleAm != b.title)
        b.titleAm!,
    ];
    return ContentSearchItem(
      id: b.id,
      entityType: 'book',
      title: b.title,
      thumbnailUrl: b.coverUrl,
      subtitle: parts.isEmpty ? 'Book' : parts.join(' · '),
      badgeLabel: b.isDictionary ? 'Dictionary' : 'Book',
    );
  }

  factory ContentSearchItem.fromUser(SearchUserDto u) {
    final name = (u.displayName != null && u.displayName!.isNotEmpty)
        ? u.displayName!
        : (u.username ?? 'User');
    return ContentSearchItem(
      id: u.id,
      entityType: 'user',
      title: name,
      thumbnailUrl: u.avatarUrl,
      subtitle: u.username != null && u.username!.isNotEmpty
          ? '@${u.username}'
          : 'User profile',
      badgeLabel: 'User',
      isVerified: u.isVerified,
    );
  }

  factory ContentSearchItem.fromGroup(SearchGroupDto g) {
    return ContentSearchItem(
      id: g.id,
      entityType: 'group',
      title: g.name ?? 'Group',
      thumbnailUrl: g.avatarUrl,
      subtitle: g.slug != null && g.slug!.isNotEmpty
          ? '@${g.slug} · ${g.membersCount} members'
          : '${g.membersCount} members',
      badgeLabel: 'Group',
    );
  }

  factory ContentSearchItem.fromChannel(SearchChannelDto c) {
    final handle = c.cleanHandle;
    return ContentSearchItem(
      id: c.id,
      entityType: 'channel',
      title: c.name ?? 'Channel',
      thumbnailUrl: c.avatarUrl,
      subtitle: handle != null && handle.isNotEmpty
          ? '@$handle · ${c.subscribersCount} subscribers'
          : '${c.subscribersCount} subscribers',
      badgeLabel: 'Channel',
      isVerified: c.isVerified,
    );
  }

  factory ContentSearchItem.fromPost(SearchPostDto p) {
    final snippet = sanitizeTokenLabel(p.content);
    final previewTitle = snippet.length > 60
        ? '${snippet.substring(0, 57)}...'
        : (snippet.isEmpty ? 'Post' : snippet);
    final author = p.authorDisplayName ??
        (p.authorUsername != null ? '@${p.authorUsername}' : 'Post');
    return ContentSearchItem(
      id: p.id,
      entityType: 'post',
      title: previewTitle,
      thumbnailUrl: p.thumbnailUrl ?? p.authorAvatarUrl,
      subtitle: '$author · ${p.likesCount} likes',
      badgeLabel: 'Post',
    );
  }

  factory ContentSearchItem.fromStream(SearchStreamDto s) {
    final parts = <String>[
      if (s.channelName != null && s.channelName!.isNotEmpty) s.channelName!,
      if (s.creatorUsername != null && s.creatorUsername!.isNotEmpty)
        '@${s.creatorUsername}',
      if (s.viewerCount != null && s.isLive) '${s.viewerCount} watching',
      if (s.isScheduled && s.scheduledAt != null) 'Scheduled',
    ];
    return ContentSearchItem(
      id: s.id,
      entityType: 'stream',
      title: s.title ?? 'Live Stream',
      thumbnailUrl: s.thumbnailUrl,
      subtitle: parts.isEmpty ? (s.status ?? 'Stream') : parts.join(' · '),
      badgeLabel: s.isLive ? 'LIVE' : (s.isScheduled ? 'Scheduled' : 'Stream'),
      isLive: s.isLive,
    );
  }

  factory ContentSearchItem.fromReel(SearchReelDto r) {
    final caption = (r.description ?? '').trim();
    final preview = caption.length > 50
        ? '${caption.substring(0, 47)}...'
        : (caption.isEmpty ? 'Reel' : caption);
    return ContentSearchItem(
      id: r.id,
      entityType: 'reel',
      title: preview,
      thumbnailUrl: r.thumbnailUrl,
      subtitle: r.authorUsername != null ? '@${r.authorUsername}' : 'Reel',
      badgeLabel: 'Reel',
    );
  }

  /// Inserts a structured `#[entityType:id:safeTitle]` internal link token.
  /// Even when `entityType == 'user'`, this preserves `#` so choosing a user
  /// from `#` Global Search links cleanly without creating a mention notification.
  String toToken() {
    final safeTitle = sanitizeTokenLabel(title);
    return '#[$entityType:$id:${safeTitle.isEmpty ? entityType : safeTitle}]';
  }

  MentionEntityType? get mentionEntityType =>
      MentionEntityTypeX.fromPrefix(entityType);
}
