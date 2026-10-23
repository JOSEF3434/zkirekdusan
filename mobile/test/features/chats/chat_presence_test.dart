import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/chat_activity_indicator.dart';

import 'dart:async';
import 'package:mobile/features/chats/domain/repositories/chat_repository.dart';
import 'package:mobile/features/chats/data/datasources/messaging_socket_service.dart';

class FakeMessagingSocketService implements MessagingSocketService {
  @override
  Stream<MessageModel> get messageReceived => const Stream.empty();
  @override
  Stream<MessageModel> get messageUpdated => const Stream.empty();
  @override
  Stream<Map<String, String>> get messageDeleted => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get typing => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get activity => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get presence => const Stream.empty();
  @override
  Stream<List<Map<String, dynamic>>> get presenceQueryResponse =>
      const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get reaction => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get readReceipt => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get deliveryReceipt => const Stream.empty();
  @override
  Stream<bool> get connectionStatus => const Stream.empty();
  @override
  bool get isConnected => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeChatRepository implements ChatRepository {
  @override
  Future<List<ConversationModel>> getCachedConversations() async => [];
  @override
  Future<ChatDiscoveryModel> getChatDiscovery() async =>
      const ChatDiscoveryModel();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeChatDiscoveryNotifier extends ChatDiscoveryNotifier {
  FakeChatDiscoveryNotifier([ChatDiscoveryModel? initial])
    : super(
        FakeChatRepository(),
        FakeMessagingSocketService(),
        'user-current',
      ) {
    state = AsyncValue.data(initial ?? const ChatDiscoveryModel());
  }

  @override
  Future<void> loadDiscovery({bool forceRefresh = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Presence Resolution & Synchronization', () {
    const currentUserId = 'user-current';
    const otherUserId = 'user-peer';

    test(
      'Initial discovery model with offline member reports isOnline = false',
      () {
        final member = const ConversationMemberModel(
          userId: otherUserId,
          username: 'peer',
          displayName: 'Peer User',
          isOnline: false,
        );

        final conv = ConversationModel(
          id: 'conv-123',
          type: 'DIRECT',
          members: [
            const ConversationMemberModel(
              userId: currentUserId,
              username: 'me',
            ),
            member,
          ],
          createdAt: DateTime.now(),
        );

        final other = conv.members.firstWhere((m) => m.userId != currentUserId);
        expect(other.isOnline, isFalse);
      },
    );

    test(
      'Presence cache merges live online status into conversation members',
      () {
        final initialMember = const ConversationMemberModel(
          userId: otherUserId,
          username: 'peer',
          displayName: 'Peer User',
          isOnline: false,
        );

        final initialConv = ConversationModel(
          id: 'conv-123',
          type: 'DIRECT',
          members: [
            const ConversationMemberModel(
              userId: currentUserId,
              username: 'me',
            ),
            initialMember,
          ],
          createdAt: DateTime.now(),
        );

        final discovery = ChatDiscoveryModel(conversations: [initialConv]);

        // Simulate presence update
        final updatedConvs = discovery.conversations.map((c) {
          final members = c.members.map((m) {
            if (m.userId == otherUserId) {
              return m.copyWith(isOnline: true);
            }
            return m;
          }).toList();
          return c.copyWith(members: members);
        }).toList();

        final updatedDiscovery = discovery.copyWith(
          conversations: updatedConvs,
        );
        final updatedOther = updatedDiscovery.conversations.first.members
            .firstWhere((m) => m.userId != currentUserId);

        expect(updatedOther.isOnline, isTrue);
      },
    );

    test(
      'userOnlineStatusProvider derives true when livePresenceMapProvider contains online user',
      () {
        final container = ProviderContainer(
          overrides: [
            chatDiscoveryProvider.overrideWith(
              (ref) => FakeChatDiscoveryNotifier(),
            ),
            livePresenceMapProvider.overrideWith((ref) => {otherUserId: true}),
          ],
        );
        addTearDown(container.dispose);

        final isOnline = container.read(userOnlineStatusProvider(otherUserId));
        expect(isOnline, isTrue);

        final isOffline = container.read(
          userOnlineStatusProvider('non-existent-user'),
        );
        expect(isOffline, isFalse);
      },
    );

    test(
      'userOnlineStatusProvider updates reactively when presence map changes',
      () {
        final container = ProviderContainer(
          overrides: [
            chatDiscoveryProvider.overrideWith(
              (ref) => FakeChatDiscoveryNotifier(),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Initially false
        expect(container.read(userOnlineStatusProvider(otherUserId)), isFalse);

        // User comes online
        container.read(livePresenceMapProvider.notifier).state = {
          otherUserId: true,
        };
        expect(container.read(userOnlineStatusProvider(otherUserId)), isTrue);

        // User goes offline
        container.read(livePresenceMapProvider.notifier).state = {
          otherUserId: false,
        };
        expect(container.read(userOnlineStatusProvider(otherUserId)), isFalse);
      },
    );

    test(
      'userLastSeenStatusProvider updates reactively when lastSeen map changes',
      () {
        final container = ProviderContainer(
          overrides: [
            chatDiscoveryProvider.overrideWith(
              (ref) => FakeChatDiscoveryNotifier(),
            ),
          ],
        );
        addTearDown(container.dispose);

        const timestamp = '2026-10-16T12:00:00.000Z';
        container.read(liveLastSeenMapProvider.notifier).state = {
          otherUserId: timestamp,
        };

        expect(
          container.read(userLastSeenStatusProvider(otherUserId)),
          equals(timestamp),
        );
      },
    );
  });

  group('Chat Activity Status Resolution & Indicators', () {
    test(
      'ChatActivityHelper resolves labels correctly without generic active...',
      () {
        expect(ChatActivityHelper.getLabel('typing'), equals('typing'));
        expect(
          ChatActivityHelper.getLabel('recording_audio'),
          equals('recording audio'),
        );
        expect(
          ChatActivityHelper.getLabel('recording_voice'),
          equals('recording audio'),
        );
        expect(
          ChatActivityHelper.getLabel('uploading_photo'),
          equals('sending photo'),
        );
        expect(
          ChatActivityHelper.getLabel('sending_photo'),
          equals('sending photo'),
        );
        expect(
          ChatActivityHelper.getLabel('uploading_video'),
          equals('sending video'),
        );
        expect(
          ChatActivityHelper.getLabel('uploading_audio'),
          equals('sending audio'),
        );
        expect(
          ChatActivityHelper.getLabel('uploading_file'),
          equals('sending file'),
        );
        expect(
          ChatActivityHelper.getLabel('uploading_media'),
          equals('sending file'),
        );
        expect(
          ChatActivityHelper.getLabel('unknown_action'),
          equals('typing'),
        ); // never active...
      },
    );

    test(
      'ChatActivityHelper resolves icons accurately for each media action',
      () {
        expect(
          ChatActivityHelper.getIcon('typing'),
          equals(Icons.edit_note_rounded),
        );
        expect(
          ChatActivityHelper.getIcon('recording_audio'),
          equals(Icons.mic_rounded),
        );
        expect(
          ChatActivityHelper.getIcon('uploading_photo'),
          equals(Icons.image_rounded),
        );
        expect(
          ChatActivityHelper.getIcon('uploading_video'),
          equals(Icons.videocam_rounded),
        );
        expect(
          ChatActivityHelper.getIcon('uploading_audio'),
          equals(Icons.audiotrack_rounded),
        );
        expect(
          ChatActivityHelper.getIcon('uploading_file'),
          equals(Icons.insert_drive_file_rounded),
        );
      },
    );

    testWidgets('ChatActivityRow renders label and icon in MaterialApp', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChatActivityRow(activity: 'uploading_photo')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('sending photo'), findsOneWidget);
      expect(find.byIcon(Icons.image_rounded), findsOneWidget);
    });

    testWidgets('ChatActivityBubble renders label and icon in MaterialApp', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatActivityBubble(activity: 'recording_audio', isDark: true),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('recording audio'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });
  });
}
