// lib/core/rich_text/internal_link_handler.dart
//
// Resolves a RichTextEntity to its GoRouter destination and navigates there.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';

class InternalLinkHandler {
  /// Navigate to the correct screen for the given entity.
  static void navigate(BuildContext context, RichTextEntity entity) {
    switch (entity.type) {
      case MentionEntityType.user:
        // /u/:username — existing PublicProfileScreen
        context.push('/u/${entity.label}');

      case MentionEntityType.group:
        // /g/:id — existing Group screen
        context.push('/g/${entity.id}');

      case MentionEntityType.channel:
        // /c/:id — existing Channel screen
        context.push('/c/${entity.id}');

      case MentionEntityType.video:
        // /video/:id — existing VideoDetailScreen
        context.push('/video/${entity.id}');

      case MentionEntityType.book:
        // Book detail — check existing route; fallback to /books/:id
        context.push('/books/${entity.id}');

      case MentionEntityType.post:
        // No dedicated post detail route exists — navigate to home feed.
        // When a post detail screen is added, update to: context.push('/posts/${entity.id}')
        context.go('/home');

      case MentionEntityType.stream:
        // /live/:id
        context.push('/live/${entity.id}');
    }
  }

  /// Navigate from a ContentSearchItem directly (used in # picker without
  /// inserting a token when the user just wants to open the item).
  static void navigateToContent(BuildContext context, ContentSearchItem item) {
    switch (item.entityType) {
      case 'user':
        final username = item.subtitle?.replaceFirst('@', '') ?? item.id;
        context.push('/u/$username');
      case 'group':
        context.push('/g/${item.id}');
      case 'channel':
        context.push('/c/${item.id}');
      case 'video':
        context.push('/video/${item.id}');
      case 'book':
        context.push('/books/${item.id}');
      case 'post':
        // No dedicated post detail route — navigate to home feed.
        context.go('/home');
      case 'stream':
        context.push('/live/${item.id}');
      default:
        break;
    }
  }
}
