import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';

void main() {
  group('Chat Message Status & Receipts Logic', () {
    const currentUserId = 'user-1';
    const peerUserId = 'user-2';

    test('Optimistic message has temp_ ID and evaluates to isSending', () {
      final message = MessageModel(
        id: 'temp_12345-abcde',
        conversationId: 'conv-1',
        sender: const MessageSenderModel(
          id: currentUserId,
          username: 'me',
          displayName: 'Me',
        ),
        type: 'TEXT',
        content: 'Hello world',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isSending =
          message.id.startsWith('temp_') || message.id.startsWith('local_');
      final isSeen =
          message.readBy.isNotEmpty &&
          message.readBy.any((u) => u != currentUserId);
      final isDelivered =
          message.deliveredTo.isNotEmpty &&
          message.deliveredTo.any((u) => u != currentUserId);

      expect(isSending, isTrue);
      expect(isSeen, isFalse);
      expect(isDelivered, isFalse);
    });

    test(
      'Server message with empty deliveredTo and readBy is Sent (single tick)',
      () {
        final message = MessageModel(
          id: 'msg-uuid-1',
          conversationId: 'conv-1',
          sender: const MessageSenderModel(
            id: currentUserId,
            username: 'me',
            displayName: 'Me',
          ),
          type: 'TEXT',
          content: 'Hello world',
          readBy: [],
          deliveredTo: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final isSending =
            message.id.startsWith('temp_') || message.id.startsWith('local_');
        final isSeen =
            message.readBy.isNotEmpty &&
            message.readBy.any((u) => u != currentUserId);
        final isDelivered =
            message.deliveredTo.isNotEmpty &&
            message.deliveredTo.any((u) => u != currentUserId);

        expect(isSending, isFalse);
        expect(isSeen, isFalse);
        expect(isDelivered, isFalse);
      },
    );

    test(
      'Server message with peer in deliveredTo is Delivered (double grey tick)',
      () {
        final message = MessageModel(
          id: 'msg-uuid-2',
          conversationId: 'conv-1',
          sender: const MessageSenderModel(
            id: currentUserId,
            username: 'me',
            displayName: 'Me',
          ),
          type: 'TEXT',
          content: 'Delivered message',
          readBy: [],
          deliveredTo: [peerUserId],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final isSending =
            message.id.startsWith('temp_') || message.id.startsWith('local_');
        final isSeen =
            message.readBy.isNotEmpty &&
            message.readBy.any((u) => u != currentUserId);
        final isDelivered =
            message.deliveredTo.isNotEmpty &&
            message.deliveredTo.any((u) => u != currentUserId);

        expect(isSending, isFalse);
        expect(isSeen, isFalse);
        expect(isDelivered, isTrue);
      },
    );

    test('Server message with peer in readBy is Seen (double cyan tick)', () {
      final message = MessageModel(
        id: 'msg-uuid-3',
        conversationId: 'conv-1',
        sender: const MessageSenderModel(
          id: currentUserId,
          username: 'me',
          displayName: 'Me',
        ),
        type: 'TEXT',
        content: 'Read message',
        readBy: [peerUserId],
        deliveredTo: [peerUserId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isSending =
          message.id.startsWith('temp_') || message.id.startsWith('local_');
      final isSeen =
          message.readBy.isNotEmpty &&
          message.readBy.any((u) => u != currentUserId);
      final isDelivered =
          message.deliveredTo.isNotEmpty &&
          message.deliveredTo.any((u) => u != currentUserId);

      expect(isSending, isFalse);
      expect(isSeen, isTrue);
      expect(isDelivered, isTrue);
    });
  });

  group('Profile Navigation Identifier Resolution', () {
    String resolveProfileIdentifier(ConversationMemberModel member) {
      return (member.username.isNotEmpty && !member.username.contains(' '))
          ? member.username
          : member.userId;
    }

    test('Uses username when valid without spaces', () {
      const member = ConversationMemberModel(
        userId: '11111111-2222-3333-4444-555555555555',
        username: 'solomon_k',
        displayName: 'Solomon Kedir',
      );

      expect(resolveProfileIdentifier(member), equals('solomon_k'));
    });

    test(
      'Falls back to userId when username has spaces (e.g. display name leak)',
      () {
        const member = ConversationMemberModel(
          userId: '11111111-2222-3333-4444-555555555555',
          username: 'Solomon Kedir',
          displayName: 'Solomon Kedir',
        );

        expect(
          resolveProfileIdentifier(member),
          equals('11111111-2222-3333-4444-555555555555'),
        );
      },
    );

    test('Falls back to userId when username is empty', () {
      const member = ConversationMemberModel(
        userId: '22222222-3333-4444-5555-666666666666',
        username: '',
        displayName: 'Anonymous',
      );

      expect(
        resolveProfileIdentifier(member),
        equals('22222222-3333-4444-5555-666666666666'),
      );
    });
  });

  group('Activity Status Text Resolution', () {
    String formatActivity(String activity) {
      switch (activity) {
        case 'typing':
          return 'typing...';
        case 'recording_audio':
          return 'recording audio...';
        case 'uploading_photo':
          return 'sending photo...';
        case 'uploading_video':
          return 'sending video...';
        case 'uploading_audio':
          return 'sending audio...';
        case 'uploading_file':
        case 'uploading_media':
          return 'sending file...';
        default:
          return 'active...';
      }
    }

    test('Formats all real-time activity events correctly', () {
      expect(formatActivity('typing'), equals('typing...'));
      expect(formatActivity('recording_audio'), equals('recording audio...'));
      expect(formatActivity('uploading_photo'), equals('sending photo...'));
      expect(formatActivity('uploading_video'), equals('sending video...'));
      expect(formatActivity('uploading_audio'), equals('sending audio...'));
      expect(formatActivity('uploading_file'), equals('sending file...'));
      expect(formatActivity('uploading_media'), equals('sending file...'));
      expect(formatActivity('unknown_state'), equals('active...'));
    });
  });
}
