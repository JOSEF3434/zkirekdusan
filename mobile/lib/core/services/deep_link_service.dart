// lib/core/services/deep_link_service.dart
//
// Listens for incoming deep links (Android App Links, iOS Universal Links,
// and custom zikrekidusan:// scheme) and dispatches them to GoRouter.
//
// Lifecycle:
//   - On cold start: app_links.getInitialLink() is called once to get the
//     launch link before the Flutter engine processes any navigation.
//   - While running/backgrounded: the uriLinkStream subscription delivers
//     subsequent links.
//
// Integration:
//   Call DeepLinkService.initialize(router) ONCE from app.dart after the
//   router is available. The service guards against duplicate handling of
//   the same URI (initial link vs stream).

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/app_link_service.dart';

class DeepLinkService {
  DeepLinkService._();

  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static Uri? _initialUri;
  static bool _initialUriHandled = false;

  /// Call once from app startup (after GoRouter is ready).
  static Future<void> initialize(GoRouter router) async {
    if (kIsWeb) return; // Web routing is handled by GoRouter URL strategy

    // 1. Fetch the launch URI (app was opened from a cold start via a link)
    try {
      _initialUri = await _appLinks.getInitialLink();
    } catch (_) {
      _initialUri = null;
    }

    if (_initialUri != null && !_initialUriHandled) {
      _initialUriHandled = true;
      await Future.delayed(const Duration(milliseconds: 400));
      _dispatch(_initialUri!, router);
    }

    // 2. Listen for subsequent links while app is running / resuming
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        // Skip if this is the same URI that was already handled as initial link
        if (_initialUri != null && uri == _initialUri && _initialUriHandled) {
          return;
        }
        _dispatch(uri, router);
      },
      onError: (err) {
        debugPrint('[DeepLinkService] Stream error: $err');
      },
    );
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  /// Routes a URI to the correct GoRouter path.
  static void _dispatch(Uri uri, GoRouter router) {
    debugPrint('[DeepLinkService] Incoming link: $uri');
    final path = _uriToAppPath(uri);
    if (path != null) {
      debugPrint('[DeepLinkService] Navigating to: $path');
      router.go(path);
    } else {
      debugPrint('[DeepLinkService] No matching route for: $uri');
    }
  }

  /// Converts an incoming URI to an in-app GoRouter path.
  ///
  /// Handles:
  ///   https://zikire-kdusan.onrender.com/u/{userId}  -> /u/{userId}
  ///   https://zikire-kdusan.onrender.com/{username}  -> /u/{username} (via AppLinkService)
  ///   zikrekidusan://profile/user/{id}               -> /u/{id}
  ///   zikrekidusan://groups/{id}                     -> /groups/{id}
  ///   https://.../video/{id}                         -> /video/{id}
  ///   https://.../g/{id}                             -> /g/{id}
  ///   https://.../c/{id}                             -> /c/{id}
  ///   https://.../join/group/{token}                 -> /join/group/{token}
  static String? _uriToAppPath(Uri uri) {
    // ── Custom scheme: zikrekidusan:// ────────────────────────────────────────
    if (uri.scheme == 'zikrekidusan') {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'profile' && segments[1] == 'user') {
        final id = segments.length >= 3 ? segments[2] : null;
        if (id != null && id.isNotEmpty) return '/u/$id';
      }
      if (segments.isNotEmpty && segments[0] == 'groups') {
        final id = segments.length >= 2 ? segments[1] : null;
        if (id != null && id.isNotEmpty) return '/groups/$id';
      }
      return null;
    }

    // ── HTTPS links ────────────────────────────────────────────────────────────
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;

    final host = uri.host.toLowerCase();
    if (!AppLinkService.isKnownHost(host)) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '/home';

    // /u/{userId} — canonical UUID-based profile link
    if (segments[0] == 'u' && segments.length >= 2) {
      return '/u/${segments[1]}';
    }

    // /g/{groupId}
    if (segments[0] == 'g' && segments.length >= 2) {
      return '/g/${segments[1]}';
    }

    // /c/{channelId}
    if (segments[0] == 'c' && segments.length >= 2) {
      return '/c/${segments[1]}';
    }

    // /join/group/{token}
    if (segments[0] == 'join' && segments.length >= 3 && segments[1] == 'group') {
      return '/join/group/${segments[2]}';
    }

    // /video/{id}
    if (segments[0] == 'video' && segments.length >= 2) {
      return '/video/${segments[1]}';
    }

    // /groups/{id}
    if (segments[0] == 'groups' && segments.length >= 2) {
      return '/groups/${segments[1]}';
    }

    // /chats/conversation/{id}
    if (segments[0] == 'chats' && segments.length >= 3 && segments[1] == 'conversation') {
      return '/chats/conversation/${segments[2]}';
    }

    // /{username} — single-segment, non-reserved path (e.g. /sara_bi)
    if (segments.length == 1) {
      final seg = segments[0];
      final clean = AppLinkService.cleanIdentifier(seg);
      if (clean != null && !AppLinkService.reservedPaths.contains(clean.toLowerCase())) {
        // Could be username or UUID — route to /u/ which handles both
        return '/u/$clean';
      }
    }

    return null;
  }
}
