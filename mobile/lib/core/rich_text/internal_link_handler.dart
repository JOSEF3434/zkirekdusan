// lib/core/rich_text/internal_link_handler.dart
//
// Central GoRouter navigation handler for all internal entity references.
// Always navigates by stable database UUID (never display label or title)
// so links remain valid even when a user changes their username or a title changes.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';

class InternalLinkHandler {
  static void navigate(BuildContext context, RichTextEntity entity) {
    final id = entity.id.trim();
    if (id.isEmpty) {
      _showUnavailable(context);
      return;
    }

    switch (entity.type) {
      case MentionEntityType.user:
        // PublicProfileScreen accepts stable UUID via /u/:id (ProfilesService.findByUserId)
        context.push('/u/$id');

      case MentionEntityType.group:
        context.push('/groups/$id');

      case MentionEntityType.channel:
        context.push('/channel/$id');

      case MentionEntityType.video:
        context.push('/video/$id');

      case MentionEntityType.book:
        context.push('/books/$id');

      case MentionEntityType.post:
        context.push('/posts/$id');

      case MentionEntityType.stream:
        context.push('/live/$id');

      case MentionEntityType.reel:
        context.push('/explore');
    }
  }

  static void navigateToContent(BuildContext context, ContentSearchItem item) {
    final type = item.mentionEntityType;
    if (type == null || item.id.trim().isEmpty) {
      _showUnavailable(context);
      return;
    }
    navigate(
      context,
      RichTextEntity(
        start: 0,
        end: 0,
        triggerChar: '#',
        type: type,
        id: item.id,
        label: item.title,
      ),
    );
  }

  static void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Referenced content is unavailable.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
