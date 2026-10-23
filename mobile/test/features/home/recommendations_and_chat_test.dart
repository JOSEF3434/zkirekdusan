import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';

void main() {
  group('Recommendations & Pagination Envelope Tests', () {
    test(
      'parsePaginatedEnvelope correctly normalizes flat pagination fields on empty data',
      () {
        final rawResponse = {
          'success': true,
          'data': {'data': [], 'page': 1, 'limit': 10, 'source': 'popular'},
        };

        final parsed = parsePaginatedEnvelope(rawResponse);
        expect(parsed['data'], isEmpty);
        expect(parsed['meta'], isA<Map<String, dynamic>>());
        expect(parsed['meta']['page'], 1);
        expect(parsed['meta']['limit'], 10);
        expect(parsed['meta']['total'], 0);
      },
    );

    test('parsePaginatedEnvelope correctly normalizes when data has items', () {
      final rawResponse = {
        'success': true,
        'data': {
          'data': [
            {'id': 'v1', 'title': 'Sample Video'},
          ],
          'page': 2,
          'limit': 10,
          'total': 25,
          'source': 'popular',
        },
      };

      final parsed = parsePaginatedEnvelope(rawResponse);
      expect(parsed['data'], hasLength(1));
      expect(parsed['meta']['page'], 2);
      expect(parsed['meta']['limit'], 10);
      expect(parsed['meta']['total'], 25);
    });
  });

  group('Chat Discovery Model & Safe Members Tests', () {
    test('ChatDiscoveryModel safely parses empty conversation lists', () {
      final json = {
        'conversations': [],
        'publicGroups': [],
        'myPrivateGroups': [],
        'allUsers': [],
      };

      final model = ChatDiscoveryModel.fromJson(json);
      expect(model.conversations, isEmpty);
      expect(model.publicGroups, isEmpty);
      expect(model.myPrivateGroups, isEmpty);
      expect(model.allUsers, isEmpty);
    });

    test(
      'Conversation with empty members list does not crash member lookup',
      () {
        final conv = ConversationModel(
          id: 'c1',
          type: 'DIRECT',
          createdAt: DateTime.now(),
          members: const [],
        );

        final member = conv.members.firstWhere(
          (m) => m.userId == 'user123',
          orElse: () => conv.members.isNotEmpty
              ? conv.members.first
              : const ConversationMemberModel(userId: '', username: ''),
        );

        expect(member.userId, '');
        expect(member.username, '');
        expect(member.unreadCount, 0);
      },
    );
  });
}
