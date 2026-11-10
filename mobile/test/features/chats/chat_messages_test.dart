import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/chats/data/datasources/messaging_socket_service.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/data/repositories/chat_repository_impl.dart';
import 'package:mobile/features/chats/domain/repositories/chat_repository.dart';
import 'package:mobile/features/chats/presentation/providers/chat_messages_provider.dart';
import 'package:mobile/features/chats/presentation/providers/conversations_provider.dart';
import 'package:mobile/features/chats/presentation/widgets/conversation_list_tile.dart';
import 'package:mobile/features/chats/presentation/widgets/message_bubble.dart';
import 'package:mobile/features/chats/presentation/widgets/message_status_indicator.dart';

double _relativeLuminance(Color c) {
  double linearize(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linearize(c.r) +
      0.7152 * linearize(c.g) +
      0.0722 * linearize(c.b);
}

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

class _FakeChatRepository extends Fake implements ChatRepository {
  Completer<MessageModel>? nextSendCompleter;
  Completer<ChatDiscoveryModel>? nextDiscoveryCompleter;
  bool shouldFailSend = false;
  int sendCallCount = 0;
  final List<String> markedReadMessageIds = [];
  final List<String> markedConversationReadIds = [];
  List<ConversationModel> discoveryConversations = [];

  @override
  Future<PaginatedMessagesModel> getMessages({
    required String conversationId,
    String? cursor,
    int limit = 50,
  }) async {
    return const PaginatedMessagesModel(data: [], hasMore: false);
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(String conversationId) async =>
      [];

  @override
  Future<List<ConversationModel>> getCachedConversations() async =>
      discoveryConversations;

  @override
  Future<ChatDiscoveryModel> getChatDiscovery() async {
    if (nextDiscoveryCompleter != null) {
      return nextDiscoveryCompleter!.future;
    }
    return ChatDiscoveryModel(conversations: discoveryConversations);
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    markedConversationReadIds.add(conversationId);
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    String? content,
    String? replyToId,
    List<String>? attachmentIds,
    String type = 'TEXT',
    String? clientId,
    List<MessageAttachmentModel>? initialAttachments,
    MessageVoiceNoteModel? voiceNote,
    List<String>? mentionedUserIds,
  }) async {
    sendCallCount++;
    if (nextSendCompleter != null) {
      return nextSendCompleter!.future;
    }
    if (shouldFailSend) {
      throw Exception('Simulated network error');
    }
    final now = DateTime.now();
    return MessageModel(
      id: 'srv-$sendCallCount',
      conversationId: conversationId,
      sender: const MessageSenderModel(
        id: 'user-1',
        username: 'me',
        displayName: 'Me',
      ),
      content: content,
      type: type,
      readBy: const [],
      deliveredTo: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> markAsRead(String messageId) async {
    markedReadMessageIds.add(messageId);
  }
}

class _FakeSocketService extends Fake implements MessagingSocketService {
  final _msgCtrl = StreamController<MessageModel>.broadcast();
  final _updCtrl = StreamController<MessageModel>.broadcast();
  final _delCtrl = StreamController<Map<String, String>>.broadcast();
  final _reactCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _readCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _delivCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _unreadCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _connCtrl = StreamController<bool>.broadcast();
  final _presCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _presQueryCtrl =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  final List<String> deliveredCalls = [];
  final List<String> readCalls = [];
  final List<String> conversationReadCalls = [];

  @override
  bool get isConnected => true;

  @override
  Stream<MessageModel> get messageReceived => _msgCtrl.stream;
  @override
  Stream<MessageModel> get messageUpdated => _updCtrl.stream;
  @override
  Stream<Map<String, String>> get messageDeleted => _delCtrl.stream;
  @override
  Stream<Map<String, dynamic>> get reaction => _reactCtrl.stream;
  @override
  Stream<Map<String, dynamic>> get readReceipt => _readCtrl.stream;
  @override
  Stream<Map<String, dynamic>> get deliveryReceipt => _delivCtrl.stream;
  @override
  Stream<Map<String, dynamic>> get unreadUpdate => _unreadCtrl.stream;
  @override
  Stream<bool> get connectionStatus => _connCtrl.stream;
  @override
  Stream<Map<String, dynamic>> get presence => _presCtrl.stream;
  @override
  Stream<List<Map<String, dynamic>>> get presenceQueryResponse =>
      _presQueryCtrl.stream;

  void emitIncomingMessage(MessageModel m) => _msgCtrl.add(m);
  void emitMessageDeleted(String convId, String msgId) =>
      _delCtrl.add({'conversationId': convId, 'messageId': msgId});
  void emitDelivery(Map<String, dynamic> data) => _delivCtrl.add(data);
  void emitRead(Map<String, dynamic> data) => _readCtrl.add(data);
  void emitUnread(Map<String, dynamic> data) => _unreadCtrl.add(data);
  void emitConnection(bool connected) => _connCtrl.add(connected);

  @override
  void joinConversation(String conversationId) {}
  @override
  void leaveConversation(String conversationId) {}
  @override
  void queryPresence(List<String> userIds) {}

  @override
  void markDelivered(String conversationId, String messageId) {
    deliveredCalls.add('$conversationId:$messageId');
  }

  @override
  void markAsRead(String conversationId, String messageId) {
    readCalls.add('$conversationId:$messageId');
  }

  @override
  void markConversationAsRead(String conversationId) {
    conversationReadCalls.add(conversationId);
  }

  Future<void> close() async {
    await _msgCtrl.close();
    await _updCtrl.close();
    await _delCtrl.close();
    await _reactCtrl.close();
    await _readCtrl.close();
    await _delivCtrl.close();
    await _unreadCtrl.close();
    await _connCtrl.close();
    await _presCtrl.close();
    await _presQueryCtrl.close();
  }
}

class _FakeAuthRepository extends Fake implements AuthRepository {
  final AuthUser user;
  _FakeAuthRepository(this.user);

  @override
  Future<String?> getStoredFlag(String key) async => null;

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<AuthUser?> getCachedUser() async => user;
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthUser user) : super(_FakeAuthRepository(user)) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

void main() {
  const currentUserId = 'user-1';
  const peerUserId = 'user-2';
  const sender = MessageSenderModel(
    id: currentUserId,
    username: 'me',
    displayName: 'Me',
  );
  const peerSender = MessageSenderModel(
    id: peerUserId,
    username: 'peer',
    displayName: 'Peer',
  );

  group('resolveMessageDeliveryStatus & resolvePreviewDeliveryStatus', () {
    test('Optimistic message evaluates to sending', () {
      final msg = MessageModel(
        id: 'temp_12345-abcde',
        conversationId: 'conv-1',
        sender: sender,
        type: 'TEXT',
        content: 'Hello world',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        resolveMessageDeliveryStatus(msg, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.sending),
      );
    });

    test('Failed flag takes precedence over temp_ ID', () {
      final msg = MessageModel(
        id: 'temp_failed',
        conversationId: 'conv-1',
        sender: sender,
        type: 'TEXT',
        content: 'Failed send',
        isFailed: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        resolveMessageDeliveryStatus(msg, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.failed),
      );
    });

    test('Persisted message without receipts resolves to sent', () {
      final msg = MessageModel(
        id: 'msg-1',
        conversationId: 'conv-1',
        sender: sender,
        type: 'TEXT',
        content: 'Hello world',
        readBy: const [],
        deliveredTo: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        resolveMessageDeliveryStatus(msg, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.sent),
      );
    });

    test('Sender ID in readBy or deliveredTo is ignored (prevents false ticks)',
        () {
      final msg = MessageModel(
        id: 'msg-1b',
        conversationId: 'conv-1',
        sender: sender,
        type: 'TEXT',
        content: 'Self-read should never count',
        readBy: const [currentUserId],
        deliveredTo: const [currentUserId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        resolveMessageDeliveryStatus(msg, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.sent),
      );
    });

    test('Recipient delivery evaluates to delivered (not read)', () {
      final msg = MessageModel(
        id: 'msg-2',
        conversationId: 'conv-1',
        sender: sender,
        type: 'TEXT',
        content: 'Delivered message',
        readBy: const [],
        deliveredTo: const [peerUserId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        resolveMessageDeliveryStatus(msg, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.delivered),
      );
    });

    test('Genuine recipient read evaluates to read', () {
      final msg = MessageModel(
        id: 'msg-3',
        conversationId: 'conv-1',
        sender: sender,
        type: 'TEXT',
        content: 'Read message',
        readBy: const [peerUserId],
        deliveredTo: const [peerUserId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        resolveMessageDeliveryStatus(msg, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.read),
      );
    });

    test('Preview resolver maps pending/sent/delivered/read/failed consistently',
        () {
      expect(
        resolvePreviewDeliveryStatus(
          const MessagePreviewModel(
            id: 'temp_1',
            type: 'TEXT',
            isMe: true,
            isPending: true,
          ),
        ),
        equals(MessageDeliveryStatus.sending),
      );
      expect(
        resolvePreviewDeliveryStatus(
          const MessagePreviewModel(id: 'm1', type: 'TEXT', isMe: true),
        ),
        equals(MessageDeliveryStatus.sent),
      );
      expect(
        resolvePreviewDeliveryStatus(
          const MessagePreviewModel(
            id: 'm2',
            type: 'TEXT',
            isMe: true,
            isDelivered: true,
            isSeen: false,
          ),
        ),
        equals(MessageDeliveryStatus.delivered),
      );
      expect(
        resolvePreviewDeliveryStatus(
          const MessagePreviewModel(
            id: 'm3',
            type: 'TEXT',
            isMe: true,
            isDelivered: true,
            isSeen: true,
          ),
        ),
        equals(MessageDeliveryStatus.read),
      );
      expect(
        resolvePreviewDeliveryStatus(
          const MessagePreviewModel(
            id: 'temp_err',
            type: 'TEXT',
            isMe: true,
            isFailed: true,
          ),
        ),
        equals(MessageDeliveryStatus.failed),
      );
    });
  });

  group('MessageStatusIndicator widget & visual rules', () {
    testWidgets('sending renders compact CircularProgressIndicator and no ticks',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageStatusIndicator(
              status: MessageDeliveryStatus.sending,
              surface: MessageStatusSurface.outgoingBubble,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.done_rounded), findsNothing);
      expect(find.byIcon(Icons.done_all_rounded), findsNothing);
      expect(find.bySemanticsLabel('Sending'), findsOneWidget);
    });

    testWidgets(
        'sent and delivered BOTH render ONE gray checkmark (never double checkmark for delivered)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MessageStatusIndicator(
                  key: Key('sent-ind'),
                  status: MessageDeliveryStatus.sent,
                  surface: MessageStatusSurface.outgoingBubble,
                ),
                MessageStatusIndicator(
                  key: Key('deliv-ind'),
                  status: MessageDeliveryStatus.delivered,
                  surface: MessageStatusSurface.outgoingBubble,
                ),
              ],
            ),
          ),
        ),
      );

      final sentIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('sent-ind')),
          matching: find.byType(Icon),
        ),
      );
      final delivIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('deliv-ind')),
          matching: find.byType(Icon),
        ),
      );

      expect(sentIcon.icon, equals(Icons.done_rounded));
      expect(delivIcon.icon, equals(Icons.done_rounded));
      expect(sentIcon.color, equals(delivIcon.color));
      expect(find.byIcon(Icons.done_all_rounded), findsNothing);
      expect(
        _contrastRatio(sentIcon.color!, const Color(0xFF06B6D4)),
        greaterThanOrEqualTo(3.0),
      );
    });

    testWidgets(
        'read renders TWO colored checkmarks with >= 3.0:1 contrast in dark & light themes and on bubble',
        (tester) async {
      for (final theme in [ThemeData.light(), ThemeData.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Column(
                children: [
                  MessageStatusIndicator(
                    key: Key('bubble-read'),
                    status: MessageDeliveryStatus.read,
                    surface: MessageStatusSurface.outgoingBubble,
                  ),
                  MessageStatusIndicator(
                    key: Key('surface-read'),
                    status: MessageDeliveryStatus.read,
                    surface: MessageStatusSurface.surface,
                  ),
                  MessageStatusIndicator(
                    key: Key('surface-sent'),
                    status: MessageDeliveryStatus.sent,
                    surface: MessageStatusSurface.surface,
                  ),
                ],
              ),
            ),
          ),
        );

        final bubbleRead = tester.widget<Icon>(
          find.descendant(
            of: find.byKey(const Key('bubble-read')),
            matching: find.byType(Icon),
          ),
        );
        final surfaceRead = tester.widget<Icon>(
          find.descendant(
            of: find.byKey(const Key('surface-read')),
            matching: find.byType(Icon),
          ),
        );
        final surfaceSent = tester.widget<Icon>(
          find.descendant(
            of: find.byKey(const Key('surface-sent')),
            matching: find.byType(Icon),
          ),
        );

        expect(bubbleRead.icon, equals(Icons.done_all_rounded));
        expect(surfaceRead.icon, equals(Icons.done_all_rounded));
        expect(surfaceRead.color, isNot(equals(surfaceSent.color)));
        expect(
          _contrastRatio(bubbleRead.color!, const Color(0xFF06B6D4)),
          greaterThanOrEqualTo(3.0),
        );
        final bg = theme.brightness == Brightness.dark
            ? const Color(0xFF0A0E17)
            : Colors.white;
        expect(
          _contrastRatio(surfaceRead.color!, bg),
          greaterThanOrEqualTo(3.0),
        );
        expect(
          _contrastRatio(surfaceSent.color!, bg),
          greaterThanOrEqualTo(3.0),
        );
      }
    });

    testWidgets('failed renders red error indicator and invokes onRetry when tapped',
        (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageStatusIndicator(
              status: MessageDeliveryStatus.failed,
              surface: MessageStatusSurface.outgoingBubble,
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done_rounded), findsNothing);
      expect(find.byIcon(Icons.done_all_rounded), findsNothing);
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_rounded));
      expect(icon.color, equals(const Color(0xFFDC2626)));

      await tester.tap(find.byIcon(Icons.error_rounded));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('MessageBubble & UnifiedChatListTile consistency', () {
    testWidgets(
        'MessageBubble uses MessageStatusIndicator for outgoing only, never incoming',
        (tester) async {
      final now = DateTime.now();
      final outgoingDelivered = MessageModel(
        id: 'm-deliv',
        conversationId: 'conv-1',
        sender: sender,
        type: 'TEXT',
        content: 'Delivered to B',
        deliveredTo: const [peerUserId],
        createdAt: now,
        updatedAt: now,
      );
      final incomingRead = MessageModel(
        id: 'm-in',
        conversationId: 'conv-1',
        sender: peerSender,
        type: 'TEXT',
        content: 'Hello from B',
        deliveredTo: const [currentUserId],
        readBy: const [currentUserId],
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  MessageBubble(
                    message: outgoingDelivered,
                    isMe: true,
                    currentUserId: currentUserId,
                  ),
                  MessageBubble(
                    message: incomingRead,
                    isMe: false,
                    currentUserId: currentUserId,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Only outgoing bubble has MessageStatusIndicator, displaying 1 gray checkmark
      expect(find.byType(MessageStatusIndicator), findsOneWidget);
      expect(find.byIcon(Icons.done_rounded), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsNothing);
    });

    testWidgets(
        'UnifiedChatListTile shows same 1 gray tick for delivered, 2 colored for read, none for incoming',
        (tester) async {
      final now = DateTime.now();
      UnifiedChatItem buildItem({
        required bool isMe,
        bool isDelivered = false,
        bool isSeen = false,
      }) {
        final conv = ConversationModel(
          id: 'conv-x',
          type: 'DIRECT',
          createdAt: now,
          lastMessageAt: now,
          lastMessage: MessagePreviewModel(
            id: 'msg-last',
            content: 'Preview',
            type: 'TEXT',
            isMe: isMe,
            isDelivered: isDelivered,
            isSeen: isSeen,
          ),
        );
        return UnifiedChatItem(
          id: 'conv-x',
          title: 'Peer',
          subtitle: 'Preview',
          type: UnifiedChatType.conversation,
          sortDate: now,
          conversation: conv,
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Column(
                children: [
                  UnifiedChatListTile(
                    key: const Key('tile-deliv'),
                    item: buildItem(isMe: true, isDelivered: true),
                    onTap: () {},
                  ),
                  UnifiedChatListTile(
                    key: const Key('tile-read'),
                    item: buildItem(isMe: true, isDelivered: true, isSeen: true),
                    onTap: () {},
                  ),
                  UnifiedChatListTile(
                    key: const Key('tile-incoming'),
                    item: buildItem(isMe: false, isDelivered: true, isSeen: true),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('tile-deliv')),
          matching: find.byIcon(Icons.done_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('tile-deliv')),
          matching: find.byIcon(Icons.done_all_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('tile-read')),
          matching: find.byIcon(Icons.done_all_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('tile-incoming')),
          matching: find.byType(MessageStatusIndicator),
        ),
        findsNothing,
      );
    });
  });

  group('ChatMessagesNotifier & ChatDiscoveryNotifier end-to-end receipt lifecycle',
      () {
    late _FakeChatRepository fakeRepo;
    late _FakeSocketService fakeSocket;
    late ProviderContainer container;
    const meUser = AuthUser(
      id: currentUserId,
      username: 'me',
      email: 'me@example.com',
      role: 'USER',
    );

    setUp(() {
      fakeRepo = _FakeChatRepository();
      fakeSocket = _FakeSocketService();
      fakeRepo.discoveryConversations = [
        ConversationModel(
          id: 'conv-1',
          type: 'DIRECT',
          createdAt: DateTime.now(),
          members: const [
            ConversationMemberModel(userId: currentUserId, username: 'me'),
            ConversationMemberModel(userId: peerUserId, username: 'peer'),
          ],
        ),
      ];
      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(fakeRepo),
          messagingSocketServiceProvider.overrideWithValue(fakeSocket),
          authProvider.overrideWith((ref) => _TestAuthNotifier(meUser)),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await fakeSocket.close();
    });

    test(
        'send -> pending spinner -> sent (1 tick) -> delivered (1 tick) -> read (2 ticks) + ignores self-read',
        () async {
      final messagesNotifier =
          container.read(chatMessagesProvider('conv-1').notifier);
      final discoveryNotifier =
          container.read(chatDiscoveryProvider.notifier);

      await discoveryNotifier.loadDiscovery();
      await messagesNotifier.loadMessages();

      final sendCompleter = Completer<MessageModel>();
      fakeRepo.nextSendCompleter = sendCompleter;

      final sendFuture = messagesNotifier.sendMessage(content: 'Track me');
      await Future<void>.delayed(Duration.zero);

      // 1. Optimistic SENDING in both messages and conversation preview
      var msgs = container.read(chatMessagesProvider('conv-1')).value!;
      expect(msgs.length, 1);
      expect(
        resolveMessageDeliveryStatus(msgs.first, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.sending),
      );
      var preview = container
          .read(chatDiscoveryProvider)
          .value!
          .conversations
          .first
          .lastMessage!;
      expect(
        resolvePreviewDeliveryStatus(preview),
        equals(MessageDeliveryStatus.sending),
      );

      // 2. Backend persists (SENT)
      final now = DateTime.now();
      sendCompleter.complete(
        MessageModel(
          id: 'srv-msg-1',
          conversationId: 'conv-1',
          sender: sender,
          content: 'Track me',
          type: 'TEXT',
          readBy: const [],
          deliveredTo: const [],
          createdAt: now,
          updatedAt: now,
        ),
      );
      await sendFuture;
      await Future<void>.delayed(Duration.zero);

      msgs = container.read(chatMessagesProvider('conv-1')).value!;
      expect(
        resolveMessageDeliveryStatus(msgs.first, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.sent),
      );
      preview = container
          .read(chatDiscoveryProvider)
          .value!
          .conversations
          .first
          .lastMessage!;
      expect(
        resolvePreviewDeliveryStatus(preview),
        equals(MessageDeliveryStatus.sent),
      );

      // 3. Self read receipt arriving over socket must NOT mark read!
      fakeSocket.emitRead({
        'conversationId': 'conv-1',
        'messageId': 'srv-msg-1',
        'userId': currentUserId,
      });
      await Future<void>.delayed(Duration.zero);
      msgs = container.read(chatMessagesProvider('conv-1')).value!;
      expect(
        resolveMessageDeliveryStatus(msgs.first, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.sent),
      );
      preview = container
          .read(chatDiscoveryProvider)
          .value!
          .conversations
          .first
          .lastMessage!;
      expect(
        resolvePreviewDeliveryStatus(preview),
        equals(MessageDeliveryStatus.sent),
      );

      // 4. Genuine delivery receipt -> backend delivered (visually STILL 1 tick)
      fakeSocket.emitDelivery({
        'conversationId': 'conv-1',
        'messageId': 'srv-msg-1',
        'userId': peerUserId,
      });
      await Future<void>.delayed(Duration.zero);
      msgs = container.read(chatMessagesProvider('conv-1')).value!;
      expect(
        resolveMessageDeliveryStatus(msgs.first, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.delivered),
      );

      // 5. Read receipt for an OLDER messageId must NOT mark srv-msg-1 as read
      fakeSocket.emitRead({
        'conversationId': 'conv-1',
        'messageId': 'older-msg-0',
        'userId': peerUserId,
      });
      await Future<void>.delayed(Duration.zero);
      preview = container
          .read(chatDiscoveryProvider)
          .value!
          .conversations
          .first
          .lastMessage!;
      expect(
        resolvePreviewDeliveryStatus(preview),
        equals(MessageDeliveryStatus.delivered),
      );

      // 6. Genuine peer read receipt -> READ (2 colored ticks)
      fakeSocket.emitRead({
        'conversationId': 'conv-1',
        'messageId': 'srv-msg-1',
        'userId': peerUserId,
      });
      await Future<void>.delayed(Duration.zero);
      msgs = container.read(chatMessagesProvider('conv-1')).value!;
      expect(
        resolveMessageDeliveryStatus(msgs.first, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.read),
      );
      preview = container
          .read(chatDiscoveryProvider)
          .value!
          .conversations
          .first
          .lastMessage!;
      expect(
        resolvePreviewDeliveryStatus(preview),
        equals(MessageDeliveryStatus.read),
      );
    });

    test('failed send marks message FAILED and retry recovers to SENT',
        () async {
      final messagesNotifier =
          container.read(chatMessagesProvider('conv-1').notifier);
      final discoveryNotifier =
          container.read(chatDiscoveryProvider.notifier);

      await discoveryNotifier.loadDiscovery();
      await messagesNotifier.loadMessages();

      fakeRepo.shouldFailSend = true;
      await expectLater(
        () => messagesNotifier.sendMessage(content: 'Retryable'),
        throwsException,
      );

      var msgs = container.read(chatMessagesProvider('conv-1')).value!;
      expect(msgs.length, 1);
      final failedId = msgs.first.id;
      expect(
        resolveMessageDeliveryStatus(msgs.first, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.failed),
      );
      var preview = container
          .read(chatDiscoveryProvider)
          .value!
          .conversations
          .first
          .lastMessage!;
      expect(
        resolvePreviewDeliveryStatus(preview),
        equals(MessageDeliveryStatus.failed),
      );

      // Retry after transient failure clears
      fakeRepo.shouldFailSend = false;
      await messagesNotifier.retryFailedMessage(failedId);

      msgs = container.read(chatMessagesProvider('conv-1')).value!;
      expect(msgs.length, 1);
      expect(
        resolveMessageDeliveryStatus(msgs.first, currentUserId: currentUserId),
        equals(MessageDeliveryStatus.sent),
      );
      preview = container
          .read(chatDiscoveryProvider)
          .value!
          .conversations
          .first
          .lastMessage!;
      expect(
        resolvePreviewDeliveryStatus(preview),
        equals(MessageDeliveryStatus.sent),
      );
    });
  });

  group('Real-time Unread Count Synchronization & Deduplication', () {
    late _FakeChatRepository fakeRepo;
    late _FakeSocketService fakeSocket;
    late ProviderContainer container;
    const meUser = AuthUser(
      id: currentUserId,
      username: 'me',
      email: 'me@example.com',
      role: 'USER',
    );

    int convUnread(String convId) {
      final convs = container.read(chatDiscoveryProvider).value!.conversations;
      final conv = convs.firstWhere((c) => c.id == convId);
      return conv.members.firstWhere((m) => m.userId == currentUserId).unreadCount;
    }

    setUp(() {
      fakeRepo = _FakeChatRepository();
      fakeSocket = _FakeSocketService();
      final now = DateTime.now();
      fakeRepo.discoveryConversations = [
        ConversationModel(
          id: 'conv-1',
          type: 'DIRECT',
          createdAt: now.subtract(const Duration(minutes: 10)),
          lastMessageAt: now.subtract(const Duration(minutes: 10)),
          members: const [
            ConversationMemberModel(userId: currentUserId, username: 'me'),
            ConversationMemberModel(userId: peerUserId, username: 'peer'),
          ],
        ),
        ConversationModel(
          id: 'conv-2',
          type: 'DIRECT',
          createdAt: now.subtract(const Duration(minutes: 5)),
          lastMessageAt: now.subtract(const Duration(minutes: 5)),
          members: const [
            ConversationMemberModel(userId: currentUserId, username: 'me'),
            ConversationMemberModel(userId: 'user-3', username: 'peer3'),
          ],
        ),
      ];
      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(fakeRepo),
          messagingSocketServiceProvider.overrideWithValue(fakeSocket),
          authProvider.overrideWith((ref) => _TestAuthNotifier(meUser)),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await fakeSocket.close();
    });

    test(
        'Test 1-3: new incoming messages increment immediately, deduplicate by ID, and isolate per conversation',
        () async {
      await container.read(chatDiscoveryProvider.notifier).loadDiscovery();
      expect(container.read(totalUnreadChatCountProvider), 0);

      final t0 = DateTime.now();
      // Test 1: 1 new message in conv-1 immediately updates unread badge without refresh
      final m1 = MessageModel(
        id: 'msg-1',
        conversationId: 'conv-1',
        sender: peerSender,
        content: 'First',
        type: 'TEXT',
        createdAt: t0,
        updatedAt: t0,
      );
      fakeSocket.emitIncomingMessage(m1);
      await Future<void>.delayed(Duration.zero);

      expect(convUnread('conv-1'), 1);
      expect(convUnread('conv-2'), 0);
      expect(container.read(totalUnreadChatCountProvider), 1);
      // conv-1 moved to front
      expect(
        container.read(chatDiscoveryProvider).value!.conversations.first.id,
        'conv-1',
      );
      // Duplicate emit of same message ID must not increment again
      fakeSocket.emitIncomingMessage(m1);
      await Future<void>.delayed(Duration.zero);
      expect(convUnread('conv-1'), 1);

      // Test 2: 4 more messages -> total 5 immediately
      for (var i = 2; i <= 5; i++) {
        fakeSocket.emitIncomingMessage(
          MessageModel(
            id: 'msg-$i',
            conversationId: 'conv-1',
            sender: peerSender,
            content: 'Msg $i',
            type: 'TEXT',
            createdAt: t0.add(Duration(seconds: i)),
            updatedAt: t0.add(Duration(seconds: i)),
          ),
        );
      }
      await Future<void>.delayed(Duration.zero);
      expect(convUnread('conv-1'), 5);
      expect(container.read(totalUnreadChatCountProvider), 5);

      // Sender's own message never increments unread count
      fakeSocket.emitIncomingMessage(
        MessageModel(
          id: 'own-msg-1',
          conversationId: 'conv-2',
          sender: sender,
          content: 'My own msg',
          type: 'TEXT',
          createdAt: t0.add(const Duration(seconds: 10)),
          updatedAt: t0.add(const Duration(seconds: 10)),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(convUnread('conv-2'), 0);

      // Test 3: Another conversation receives 2 messages -> separate counts & sum = 7
      for (var i = 1; i <= 2; i++) {
        fakeSocket.emitIncomingMessage(
          MessageModel(
            id: 'c2-msg-$i',
            conversationId: 'conv-2',
            sender: const MessageSenderModel(id: 'user-3', username: 'peer3'),
            content: 'Conv2 $i',
            type: 'TEXT',
            createdAt: t0.add(Duration(seconds: 20 + i)),
            updatedAt: t0.add(Duration(seconds: 20 + i)),
          ),
        );
      }
      await Future<void>.delayed(Duration.zero);
      expect(convUnread('conv-1'), 5);
      expect(convUnread('conv-2'), 2);
      expect(container.read(totalUnreadChatCountProvider), 7);
    });

    test(
        'Test 4: active viewing keeps open chat at 0 & marks read, while hidden tab or other chats increment',
        () async {
      await container.read(chatDiscoveryProvider.notifier).loadDiscovery();
      final messagesNotifier =
          container.read(chatMessagesProvider('conv-1').notifier);
      await messagesNotifier.loadMessages();

      // User actively views conv-1 in foreground
      container.read(activeViewingConversationProvider.notifier).state =
          'conv-1';

      final now = DateTime.now();
      fakeSocket.emitIncomingMessage(
        MessageModel(
          id: 'live-open-1',
          conversationId: 'conv-1',
          sender: peerSender,
          content: 'Looking right at it',
          type: 'TEXT',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(convUnread('conv-1'), 0);
      expect(
        fakeSocket.readCalls.contains('conv-1:live-open-1'),
        isTrue,
      );

      // Message to conv-2 while user is still viewing conv-1 increments conv-2 only
      fakeSocket.emitIncomingMessage(
        MessageModel(
          id: 'bg-conv2-1',
          conversationId: 'conv-2',
          sender: const MessageSenderModel(id: 'user-3', username: 'peer3'),
          content: 'Other chat',
          type: 'TEXT',
          createdAt: now.add(const Duration(seconds: 1)),
          updatedAt: now.add(const Duration(seconds: 1)),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(convUnread('conv-1'), 0);
      expect(convUnread('conv-2'), 1);

      // User switches to Home tab / backgrounds app -> activeViewingConversation becomes null
      container.read(activeViewingConversationProvider.notifier).state = null;
      fakeSocket.emitIncomingMessage(
        MessageModel(
          id: 'live-bg-2',
          conversationId: 'conv-1',
          sender: peerSender,
          content: 'Arrived while away from Chats',
          type: 'TEXT',
          createdAt: now.add(const Duration(seconds: 2)),
          updatedAt: now.add(const Duration(seconds: 2)),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(convUnread('conv-1'), 1);
      expect(fakeSocket.readCalls.contains('conv-1:live-bg-2'), isFalse);
      expect(container.read(totalUnreadChatCountProvider), 2);
    });

    test(
        'Test 5-7: multi-device unread sync, read reset isolation, and HTTP-vs-socket race protection',
        () async {
      await container.read(chatDiscoveryProvider.notifier).loadDiscovery();
      final discoveryNotifier = container.read(chatDiscoveryProvider.notifier);

      // Start a slow HTTP discovery refresh returning old unreadCount = 0
      final slowRefresh = Completer<ChatDiscoveryModel>();
      fakeRepo.nextDiscoveryCompleter = slowRefresh;
      final refreshFuture = discoveryNotifier.refreshDiscovery();

      // While HTTP refresh is in-flight, a newer real-time message arrives in conv-1!
      final msgTime = DateTime.now().add(const Duration(seconds: 5));
      fakeSocket.emitIncomingMessage(
        MessageModel(
          id: 'race-msg-1',
          conversationId: 'conv-1',
          sender: peerSender,
          content: 'Arrived mid-refresh',
          type: 'TEXT',
          createdAt: msgTime,
          updatedAt: msgTime,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(convUnread('conv-1'), 1);

      // Now stale HTTP snapshot (0 unread, older lastMessageAt) resolves
      slowRefresh.complete(
        ChatDiscoveryModel(
          conversations: [
            fakeRepo.discoveryConversations.first,
            fakeRepo.discoveryConversations[1],
          ],
        ),
      );
      await refreshFuture;

      // Newer socket unread count (1) is preserved instead of overwritten by stale HTTP!
      expect(convUnread('conv-1'), 1);

      // Multi-device unread sync for conv-2 sets unread = 3 immediately
      fakeSocket.emitUnread({'conversationId': 'conv-2', 'unreadCount': 3});
      await Future<void>.delayed(Duration.zero);
      expect(convUnread('conv-2'), 3);
      expect(container.read(totalUnreadChatCountProvider), 4);

      // Open & mark conv-1 read clears ONLY conv-1, leaving conv-2 at 3
      await discoveryNotifier.markAsRead('conv-1');
      expect(convUnread('conv-1'), 0);
      expect(convUnread('conv-2'), 3);
      expect(container.read(totalUnreadChatCountProvider), 3);

      // Another device reads 1 message in conv-2 / message deleted -> server broadcasts unreadCount: 2
      fakeSocket.emitUnread({'conversationId': 'conv-2', 'unreadCount': 2});
      await Future<void>.delayed(Duration.zero);
      expect(convUnread('conv-2'), 2);
      expect(container.read(totalUnreadChatCountProvider), 2);
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
