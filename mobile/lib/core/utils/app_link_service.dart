// lib/core/utils/app_link_service.dart

import 'package:mobile/app/env/env.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';

/// Identifies the kind of entity an app link or QR code points to.
enum AppLinkEntityType {
  user,
  group,
  channel,
  chat,
  groupInvite,
  unknown,
}

/// Parsed result from scanning or reading an app link.
class AppLinkParsedResult {
  final AppLinkEntityType type;
  final String identifier;
  final String rawUrl;

  const AppLinkParsedResult({
    required this.type,
    required this.identifier,
    required this.rawUrl,
  });
}

/// Centralized link and QR payload service for ዝክረ ክዱሳን.
///
/// Rules:
/// - User with username: `https://<frontendHost>/<username>`
/// - User without username: `https://<frontendHost>/u/<userId>`
/// - Group with slug: `https://<frontendHost>/<slug>`
/// - Group with invite token: `https://<frontendHost>/join/group/<token>`
/// - Group fallback: `https://<frontendHost>/g/<groupId>`
/// - Channel with handle/slug: `https://<frontendHost>/<handle>`
/// - Channel fallback: `https://<frontendHost>/c/<channelId>`
class AppLinkService {
  /// Returns the configured frontend base URL (e.g. "https://zikire-kdusan.onrender.com").
  static String get baseHttps =>
      Env.frontendBaseUrl.replaceAll(RegExp(r'/+$'), '');

  /// Returns the configured frontend host (e.g. "zikire-kdusan.onrender.com").
  static String get baseHost {
    final uri = Uri.tryParse(baseHttps);
    final host = uri?.host;
    return (host != null && host.isNotEmpty) ? host : 'zikire-kdusan.onrender.com';
  }

  /// Checks if the host belongs to one of the platform frontend/app domains.
  static bool isKnownHost(String? host) {
    if (host == null || host.isEmpty) return false;
    final lower = host.toLowerCase();
    return lower == baseHost.toLowerCase() ||
        lower == 'zikire-kdusan.onrender.com' ||
        lower == 'zikrekidusan.onrender.com' ||
        lower == 'app.zikrekidusan.com' ||
        lower == 'zikrekidusan.com';
  }

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Reserved paths that cannot be treated as a direct username or slug.
  static const Set<String> reservedPaths = {
    '',
    'u',
    'g',
    'c',
    'user',
    'users',
    'group',
    'groups',
    'channel',
    'channels',
    'chat',
    'chats',
    'login',
    'register',
    'home',
    'explore',
    'profile',
    'settings',
    'admin',
    'notifications',
    'search',
    'creator',
    'library',
    'live',
    'downloads',
    'video',
    'posts',
    'share',
    'playlists',
    'calendar',
    'join',
    'qr-scan',
    'lock',
    'onboarding',
    'forgot-password',
    'verify-otp',
    'reset-password',
    'recovery-success',
    // Static web files and framework endpoints
    'index.html',
    'flutter_bootstrap.js',
    'flutter_service_worker.js',
    'main.dart.js',
    'favicon.ico',
    'favicon.png',
    'manifest.json',
    'version.json',
    'assets',
    'icons',
    'splash',
    'canvaskit',
    'api',
    'auth',
  };

  /// Returns true if the string is formatted as a standard UUID (v4/etc).
  static bool isUuid(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    return _uuidRegex.hasMatch(trimmed);
  }

  /// Cleans a username or handle by removing leading '@' and trimming whitespace.
  static String? cleanIdentifier(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().replaceFirst(RegExp(r'^@+'), '');
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Checks if a username is valid (non-null, non-empty, and not a raw UUID).
  static bool hasValidUsername(String? username) {
    final clean = cleanIdentifier(username);
    if (clean == null || clean.isEmpty) return false;
    if (isUuid(clean)) return false;
    return true;
  }

  /// Link generation for Users / Profiles:
  /// - If user has a username (e.g. "sara_bi"): `https://<frontendHost>/sara_bi`
  /// - If user has NO username (null, empty, or UUID): `https://<frontendHost>/u/<userId>`
  static String userLink({String? username, required String userId}) {
    final clean = cleanIdentifier(username);
    if (clean != null && !isUuid(clean)) {
      return '$baseHttps/$clean';
    }
    final cleanId = cleanIdentifier(userId) ?? userId.trim();
    return '$baseHttps/u/$cleanId';
  }

  /// Formatted display string for user handle or link.
  static String userDisplay({String? username, required String userId}) {
    final clean = cleanIdentifier(username);
    if (clean != null && !isUuid(clean)) {
      return '@$clean';
    }
    return '$baseHost/u/$userId';
  }

  /// Link generation for Groups:
  /// - If group has a slug (e.g. "orthodox_tewahedo"): `https://<frontendHost>/orthodox_tewahedo`
  /// - If group has an invite token: `https://<frontendHost>/join/group/<token>`
  /// - Fallback: `https://<frontendHost>/g/<groupId>`
  static String groupLink({
    String? slug,
    required String groupId,
    String? inviteToken,
  }) {
    final cleanSlug = cleanIdentifier(slug);
    if (cleanSlug != null && !isUuid(cleanSlug)) {
      return '$baseHttps/$cleanSlug';
    }
    if (inviteToken != null && inviteToken.trim().isNotEmpty) {
      return '$baseHttps/join/group/${inviteToken.trim()}';
    }
    return '$baseHttps/g/$groupId';
  }

  /// Formatted display string for group link.
  static String groupDisplay({String? slug, required String groupId}) {
    final cleanSlug = cleanIdentifier(slug);
    if (cleanSlug != null && !isUuid(cleanSlug)) {
      return '$baseHost/$cleanSlug';
    }
    return '$baseHost/g/$groupId';
  }

  /// Link generation for Channels:
  /// - If channel has a handle or slug: `https://<frontendHost>/<handle>`
  /// - Fallback: `https://<frontendHost>/c/<channelId>`
  static String channelLink({
    String? handle,
    String? slug,
    required String channelId,
  }) {
    final cleanHandle = cleanIdentifier(handle) ?? cleanIdentifier(slug);
    if (cleanHandle != null && !isUuid(cleanHandle)) {
      return '$baseHttps/$cleanHandle';
    }
    return '$baseHttps/c/$channelId';
  }

  /// Formatted display string for channel link.
  static String channelDisplay({
    String? handle,
    String? slug,
    required String channelId,
  }) {
    final cleanHandle = cleanIdentifier(handle) ?? cleanIdentifier(slug);
    if (cleanHandle != null && !isUuid(cleanHandle)) {
      return '@$cleanHandle';
    }
    return '$baseHost/c/$channelId';
  }

  /// Canonical link for Posts
  static String postLink(String postId) => '$baseHttps/posts/$postId';

  /// Canonical link for Videos
  static String videoLink(String videoId) => '$baseHttps/video/$videoId';

  /// Resolves the canonical link for a conversation/chat:
  /// - Direct chat: link to the other participant's profile (with username if available)
  /// - Group chat: group canonical link
  /// - Channel chat: channel canonical link
  static String chatLink({
    required ConversationModel conversation,
    String? currentUserId,
  }) {
    // If it's a direct chat or has other member
    if (conversation.type == 'DIRECT' || conversation.groupId == null) {
      final other = conversation.members.firstWhere(
        (m) => m.userId != currentUserId,
        orElse: () => conversation.members.isNotEmpty
            ? conversation.members.first
            : const ConversationMemberModel(userId: '', username: ''),
      );
      if (other.userId.isNotEmpty || other.username.isNotEmpty) {
        return userLink(username: other.username, userId: other.userId);
      }
    }

    // If it has a groupId
    if (conversation.groupId != null && conversation.groupId!.isNotEmpty) {
      return groupLink(
        slug: conversation.metadata?.channelName,
        groupId: conversation.groupId!,
      );
    }

    // If it has a channelId
    if (conversation.channelId != null && conversation.channelId!.isNotEmpty) {
      return channelLink(
        handle: conversation.metadata?.channelName,
        channelId: conversation.channelId!,
      );
    }

    return '$baseHttps/chats/conversation/${conversation.id}';
  }

  /// Clean display link (without https://)
  static String displayLink(String url) {
    return url
        .replaceFirst(RegExp(r'^https?:\/\/'), '')
        .replaceFirst(RegExp(r'\/$'), '');
  }

  /// Universal parser for QR code data, deep links, or manually entered handles.
  static AppLinkParsedResult parse(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return AppLinkParsedResult(
        type: AppLinkEntityType.unknown,
        identifier: '',
        rawUrl: trimmed,
      );
    }

    // 1. Group Invite Token link: .../join/group/<token>
    final inviteMatch = RegExp(
      r'(?:https?:\/\/)?(?:[a-zA-Z0-9_\.\-]+\/)?join\/group\/([a-zA-Z0-9_\.\-]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (inviteMatch != null) {
      return AppLinkParsedResult(
        type: AppLinkEntityType.groupInvite,
        identifier: inviteMatch.group(1)!,
        rawUrl: trimmed,
      );
    }

    // 2. Custom URI Schemes:
    // zikrekidusan://profile/user/<username>
    final schemeUserMatch = RegExp(
      r'zikrekidusan:\/\/profile\/user\/([a-zA-Z0-9_\.\-]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (schemeUserMatch != null) {
      return AppLinkParsedResult(
        type: AppLinkEntityType.user,
        identifier: schemeUserMatch.group(1)!,
        rawUrl: trimmed,
      );
    }

    // zikrekidusan://groups/<id>
    final schemeGroupMatch = RegExp(
      r'zikrekidusan:\/\/groups\/([a-zA-Z0-9_\.\-]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (schemeGroupMatch != null) {
      return AppLinkParsedResult(
        type: AppLinkEntityType.group,
        identifier: schemeGroupMatch.group(1)!,
        rawUrl: trimmed,
      );
    }

    // 3. Match against URLs (with or without protocol)
    final urlMatch = RegExp(
      r'^(?:https?:\/\/)?([a-zA-Z0-9\.\-]+)?\/(.*)$',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (urlMatch != null) {
      final host = urlMatch.group(1);
      final pathWithQuery = urlMatch.group(2) ?? '';
      final pathOnly = pathWithQuery.split('?').first.split('#').first;
      final segments = pathOnly.split('/').where((s) => s.isNotEmpty).toList();

      if (host == null || host.isEmpty || isKnownHost(host)) {
        if (segments.length >= 2 && segments[0].toLowerCase() == 'u') {
          return AppLinkParsedResult(
            type: AppLinkEntityType.user,
            identifier: segments[1],
            rawUrl: trimmed,
          );
        }
        if (segments.length >= 2 && segments[0].toLowerCase() == 'g') {
          return AppLinkParsedResult(
            type: AppLinkEntityType.group,
            identifier: segments[1],
            rawUrl: trimmed,
          );
        }
        if (segments.length >= 2 && segments[0].toLowerCase() == 'c') {
          return AppLinkParsedResult(
            type: AppLinkEntityType.channel,
            identifier: segments[1],
            rawUrl: trimmed,
          );
        }
        if (segments.length >= 3 &&
            segments[0].toLowerCase() == 'profile' &&
            segments[1].toLowerCase() == 'user') {
          return AppLinkParsedResult(
            type: AppLinkEntityType.user,
            identifier: segments[2],
            rawUrl: trimmed,
          );
        }
        if (segments.length >= 2 && segments[0].toLowerCase() == 'groups') {
          return AppLinkParsedResult(
            type: AppLinkEntityType.group,
            identifier: segments[1],
            rawUrl: trimmed,
          );
        }
        if (segments.length >= 3 &&
            segments[0].toLowerCase() == 'chats' &&
            segments[1].toLowerCase() == 'conversation') {
          return AppLinkParsedResult(
            type: AppLinkEntityType.chat,
            identifier: segments[2],
            rawUrl: trimmed,
          );
        }
        if (segments.length == 1) {
          final seg = segments[0];
          final clean = cleanIdentifier(seg);
          if (clean != null && !reservedPaths.contains(clean.toLowerCase())) {
            return AppLinkParsedResult(
              type: AppLinkEntityType.user,
              identifier: clean,
              rawUrl: trimmed,
            );
          }
        }
      }
    }

    // 4. Legacy t.me group link: t.me/<slug>
    final tmeMatch = RegExp(
      r'^(?:https?:\/\/)?t\.me\/([a-zA-Z0-9_\.\-]+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (tmeMatch != null) {
      return AppLinkParsedResult(
        type: AppLinkEntityType.group,
        identifier: tmeMatch.group(1)!,
        rawUrl: trimmed,
      );
    }

    // 5. @username prefix
    if (trimmed.startsWith('@')) {
      final clean = cleanIdentifier(trimmed);
      if (clean != null && clean.isNotEmpty) {
        return AppLinkParsedResult(
          type: AppLinkEntityType.user,
          identifier: clean,
          rawUrl: trimmed,
        );
      }
    }

    // 6. Plain username / identifier fallback (e.g. "sara_bi", UUID, or "orthodox_group")
    if (!trimmed.contains(' ') &&
        !trimmed.contains('/') &&
        trimmed.length >= 3) {
      return AppLinkParsedResult(
        type: AppLinkEntityType.user,
        identifier: trimmed,
        rawUrl: trimmed,
      );
    }

    return AppLinkParsedResult(
      type: AppLinkEntityType.unknown,
      identifier: trimmed,
      rawUrl: trimmed,
    );
  }
}
