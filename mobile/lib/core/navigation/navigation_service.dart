// lib/core/navigation/navigation_service.dart
// Singleton navigation service that allows navigation from static/non-widget contexts
// (e.g., notification tap handlers) using GoRouter.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  NavigationService._internal();

  static final NavigationService instance = NavigationService._internal();

  GoRouter? _router;

  /// Call this once after the GoRouter is created (in app_router.dart).
  void setRouter(GoRouter router) {
    _router = router;
  }

  /// Navigate to any named GoRouter path.
  bool navigateTo(String path, {Object? extra}) {
    final router = _router;
    if (router == null) {
      debugPrint(
        '[NavigationService] Router not set — cannot navigate to $path',
      );
      return false;
    }
    router.push(path, extra: extra);
    return true;
  }

  /// Replace the current location without depending on a widget context.
  bool goTo(String path, {Object? extra}) {
    final router = _router;
    if (router == null) {
      debugPrint('[NavigationService] Router not set — cannot go to $path');
      return false;
    }
    router.go(path, extra: extra);
    return true;
  }

  /// Navigate to the calendar note detail screen.
  ///
  /// [noteId] — the UUID of the note (also the notification payload).
  void navigateToCalendarNote(String noteId) {
    navigateTo('/calendar/note/$noteId');
  }
}
