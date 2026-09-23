// lib/features/notifications/core/notification_navigation_resolver.dart
// Central resolver for notification deep-links.
// Inspects notification type and data, then navigates safely.
// Never crashes on malformed data — always falls back gracefully.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/notifications/domain/notification_model.dart';

class NotificationNavigationResolver {
  static void navigate(
    BuildContext context,
    NotificationResponseDto notification,
  ) {
    try {
      final data = notification.data ?? {};
      final type = notification.type.toUpperCase();
      final action = data['action']?.toString().toUpperCase();
      final streamId = _streamIdFrom(data);

      // Live stream notifications are persisted as SYSTEM notifications by
      // the backend, so their action is the reliable navigation discriminator.
      if (streamId != null &&
          (type == 'STREAM_LIVE' ||
              action == 'LIVE_STREAM_CREATED' ||
              action == 'LIVE_STREAM_STARTED' ||
              action == 'LIVE_STREAM_SCHEDULED' ||
              action == 'LIVE_STREAM_REMINDER')) {
        debugPrint(
          '[NotificationNavigationResolver] Opening live stream $streamId '
          'from type=$type action=$action',
        );
        context.push('/live/$streamId');
        return;
      }

      switch (type) {
        case 'MESSAGE':
        case 'MENTION':
          final conversationId = data['conversationId'] as String?;
          if (conversationId != null && conversationId.isNotEmpty) {
            context.push('/chats');
          } else {
            context.push('/notifications');
          }
          break;

        case 'LIKE':
        case 'COMMENT':
          final videoId = data['videoId'] as String?;
          final postId = data['postId'] as String?;
          if (videoId != null && videoId.isNotEmpty) {
            context.push('/video/$videoId');
          } else if (postId != null && postId.isNotEmpty) {
            // Navigate to home/feed as we don't have a dedicated post route
            context.push('/home');
          } else {
            context.push('/notifications');
          }
          break;

        case 'FOLLOW':
          final username = data['username'] as String?;
          if (username != null && username.isNotEmpty) {
            context.push('/profile/user/$username');
          } else {
            context.push('/notifications');
          }
          break;

        case 'GROUP_INVITE':
        case 'GROUP_JOIN_REQUEST':
        case 'GROUP_APPROVE':
          // Navigate to creator workspace where group management lives
          context.push('/creator/workspace');
          break;

        case 'REACTION':
          // Navigate to chats (reaction is on a message)
          context.push('/chats');
          break;

        case 'STREAM_LIVE':
          if (streamId != null && streamId.isNotEmpty) {
            context.push('/live/$streamId');
          } else {
            context.push('/live/discover');
          }
          break;

        case 'VIDEO_READY':
          final videoId = data['videoId'] as String?;
          if (videoId != null && videoId.isNotEmpty) {
            context.push('/video/$videoId');
          } else {
            context.push('/library');
          }
          break;

        case 'CALENDAR_NOTE':
        case 'CALENDAR_REMINDER':
          final noteId =
              (data['noteId'] ?? data['calendarNoteId'] ?? data['id'])
                  as String?;
          if (noteId != null && noteId.isNotEmpty) {
            context.push('/calendar/note/$noteId');
          } else {
            context.push('/calendar');
          }
          break;

        case 'SYSTEM':
        default:
          final noteId = (data['noteId'] ?? data['calendarNoteId']) as String?;
          if (noteId != null && noteId.isNotEmpty) {
            context.push('/calendar/note/$noteId');
          } else {
            context.push('/notifications');
          }
          break;
      }
    } catch (e) {
      // Never let notification navigation crash the app
      debugPrint('[NotificationNavigationResolver] Navigation error: $e');
      try {
        context.push('/notifications');
      } catch (_) {}
    }
  }

  static String? _streamIdFrom(Map<String, dynamic> data) {
    final value =
        data['streamId'] ??
        data['liveStreamId'] ??
        data['stream_id'] ??
        data['id'];
    final streamId = value?.toString().trim();
    return streamId == null || streamId.isEmpty ? null : streamId;
  }
}
