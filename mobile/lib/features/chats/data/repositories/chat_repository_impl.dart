// lib/features/chats/data/repositories/chat_repository_impl.dart
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/chats/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDatasource = ref.watch(chatRemoteDatasourceProvider);
  final db = ref.watch(appDatabaseProvider);
  return ChatRepositoryImpl(remoteDatasource, db, ref);
});

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource _remoteDatasource;
  final AppDatabase _db;
  final Ref _ref;

  ChatRepositoryImpl(this._remoteDatasource, this._db, this._ref);

  // ══════════════════════════════════════════════════════════════
  // DISCOVERY & CONVERSATIONS
  // ══════════════════════════════════════════════════════════════

  @override
  Future<List<ConversationModel>> getCachedConversations() async {
    try {
      final cached = await _db.conversationsDao.getConversations();
      return cached.map(_companionToConversation).toList();
    } catch (e) {
      debugPrint('[ChatRepo] getCachedConversations error: $e');
      return [];
    }
  }

  @override
  Future<ChatDiscoveryModel> getChatDiscovery() async {
    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (isOnline) {
      try {
        final discovery = await _remoteDatasource
            .getChatDiscovery()
            .timeout(const Duration(seconds: 15));

        // Persist remote conversations into local database
        if (discovery.conversations.isNotEmpty) {
          final companions =
              discovery.conversations.map(_conversationToCompanion).toList();
          await _db.conversationsDao.upsertConversations(companions);
        }

        // Persist remote users into local database
        if (discovery.allUsers.isNotEmpty) {
          final localUsers = discovery.allUsers.map((u) {
            return LocalUserData(
              id: u.id,
              username: u.username,
              displayName: u.displayName,
              avatarUrl: u.avatarUrl,
              bio: u.bio,
              updatedAt: DateTime.now(),
            );
          }).toList();
          await _db.usersDao.saveUsers(localUsers);
        }

        // If remote discovery conversations are empty, merge with cached conversations
        var finalConversations = discovery.conversations;
        if (finalConversations.isEmpty) {
          final cached = await getCachedConversations();
          if (cached.isNotEmpty) {
            finalConversations = cached;
          }
        }

        return ChatDiscoveryModel(
          conversations: finalConversations,
          publicGroups: discovery.publicGroups,
          myPrivateGroups: discovery.myPrivateGroups,
          allUsers: discovery.allUsers,
        );
      } catch (e) {
        debugPrint('[ChatRepo] Remote discovery error: $e');
      }
    }

    // Fallback: return cached conversations and users from Drift when offline or network fails
    final cached = await getCachedConversations();
    List<ChatUserItem> cachedUsers = [];
    try {
      final userRows = await _db.usersDao.getAllUsers();
      cachedUsers = userRows.map((u) {
        return ChatUserItem(
          id: u.id,
          username: u.username,
          displayName: u.displayName ?? u.username ?? 'User',
          avatarUrl: u.avatarUrl,
          bio: u.bio,
          createdAt: u.updatedAt ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {}

    return ChatDiscoveryModel(
      conversations: cached,
      allUsers: cachedUsers,
    );
  }

  @override
  Future<List<ConversationModel>> getUserConversations() async {
    final isOnline = _ref.read(connectivityProvider).isOnline;

    if (isOnline) {
      try {
        final remoteList = await _remoteDatasource
            .getUserConversations()
            .timeout(const Duration(seconds: 15));
        // Persist to local database
        final companions = remoteList.map(_conversationToCompanion).toList();
        await _db.conversationsDao.upsertConversations(companions);
        return remoteList;
      } catch (e) {
        debugPrint(
            '[ChatRepo] Remote conversations fetch failed: $e, falling back to cache');
      }
    }

    // Load from local Drift database
    return await getCachedConversations();
  }

  @override
  Future<ConversationModel> getConversationById(String conversationId) async {
    final isOnline = _ref.read(connectivityProvider).isOnline;

    if (isOnline) {
      try {
        final remote = await _remoteDatasource.getConversationById(conversationId);
        await _db.conversationsDao.upsertConversation(_conversationToCompanion(remote));
        return remote;
      } catch (e) {
        debugPrint('[ChatRepo] Remote getConversationById failed: $e, falling back to cache');
      }
    }

    final local = await _db.conversationsDao.getConversationById(conversationId);
    if (local != null) {
      return _companionToConversation(local);
    }
    throw Exception('Conversation not found offline');
  }

  @override
  Future<ConversationModel> createDirectConversation(String recipientId) async {
    return await _remoteDatasource.createDirectConversation(recipientId);
  }

  @override
  Future<ConversationModel> createOrGetGroupConversation(String groupId) async {
    return await _remoteDatasource.createOrGetGroupConversation(groupId);
  }

  @override
  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String slug,
    String? description,
    String visibility = 'PUBLIC',
  }) async {
    return await _remoteDatasource.createGroup(
      name: name,
      slug: slug,
      description: description,
      visibility: visibility,
    );
  }

  @override
  Future<Map<String, dynamic>> getGroupInviteLink(String groupId) async {
    return await _remoteDatasource.getGroupInviteLink(groupId);
  }

  @override
  Future<Map<String, dynamic>> joinGroupByInvite(String token) async {
    return await _remoteDatasource.joinGroupByInvite(token);
  }

  @override
  Future<void> muteConversation(String conversationId) async {
    await _remoteDatasource.muteConversation(conversationId);
  }

  @override
  Future<void> unmuteConversation(String conversationId) async {
    await _remoteDatasource.unmuteConversation(conversationId);
  }

  @override
  Future<void> pinConversation(String conversationId) async {
    await _remoteDatasource.pinConversation(conversationId);
  }

  @override
  Future<void> unpinConversation(String conversationId) async {
    await _remoteDatasource.unpinConversation(conversationId);
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    await _db.conversationsDao.resetUnreadCount(conversationId);

    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (isOnline) {
      try {
        await _remoteDatasource.markConversationAsRead(conversationId);
      } catch (e) {
        debugPrint('[ChatRepo] Remote markConversationAsRead error: $e');
      }
    } else {
      await _db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: drift.Value(const Uuid().v4()),
          operationType: const drift.Value('UPDATE_READ_STATE'),
          entityType: const drift.Value('READ_STATE'),
          entityId: drift.Value(conversationId),
          payload: drift.Value(jsonEncode({'conversationId': conversationId})),
          createdAt: drift.Value(DateTime.now()),
          updatedAt: drift.Value(DateTime.now()),
          status: const drift.Value('pending'),
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════
  // MESSAGES
  // ══════════════════════════════════════════════════════════════

  @override
  Future<PaginatedMessagesModel> getMessages({
    required String conversationId,
    String? cursor,
    int limit = 50,
  }) async {
    final isOnline = _ref.read(connectivityProvider).isOnline;

    if (isOnline) {
      try {
        final remote = await _remoteDatasource.getMessages(
          conversationId: conversationId,
          cursor: cursor,
          limit: limit,
        );

        // Cache remote messages locally
        final companions = remote.data.map(_messageToCompanion).toList();
        await _db.messagesDao.upsertMessages(companions);

        return remote;
      } catch (e) {
        debugPrint('[ChatRepo] Remote getMessages failed: $e, falling back to cache');
      }
    }

    // Load from local database
    final localMessages = await _db.messagesDao.getMessagesForConversation(
      conversationId,
      limit: limit,
    );

    final mapped = localMessages.map(_companionToMessage).toList();
    return PaginatedMessagesModel(
      data: mapped,
      nextCursor: null,
      hasMore: false,
    );
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
  }) async {
    final now = DateTime.now();
    final effectiveClientId = clientId ?? const Uuid().v4();
    final localId = const Uuid().v4();

    final currentUser = _ref.read(authProvider).user;
    final senderId = currentUser?.id ?? 'unknown_user';
    final senderUsername = currentUser?.username ?? 'me';
    final senderDisplayName = currentUser?.displayIdentifier;
    final String? senderAvatarUrl = null;

    List<MessageAttachmentModel> optimisticAttachments = initialAttachments ?? [];
    if (optimisticAttachments.isEmpty && attachmentIds != null && attachmentIds.isNotEmpty) {
      optimisticAttachments = attachmentIds.map((id) {
        return MessageAttachmentModel(
          fileId: id,
          url: '',
          fileType: type,
          mimeType: type == 'IMAGE'
              ? 'image/jpeg'
              : (type == 'AUDIO' || type == 'VOICE_NOTE'
                  ? 'audio/m4a'
                  : 'application/octet-stream'),
          originalName: 'Attachment',
        );
      }).toList();
    }

    // 1. Create local message companion with status = pending
    final localCompanion = LocalMessagesCompanion(
      localId: drift.Value(localId),
      serverId: const drift.Value.absent(),
      clientId: drift.Value(effectiveClientId),
      conversationId: drift.Value(conversationId),
      senderId: drift.Value(senderId),
      senderUsername: drift.Value(senderUsername),
      senderDisplayName: drift.Value(senderDisplayName),
      senderAvatarUrl: drift.Value(senderAvatarUrl),
      content: drift.Value(content),
      messageType: drift.Value(type),
      replyToMessageId: drift.Value(replyToId),
      attachmentsJson: drift.Value(optimisticAttachments.isNotEmpty
          ? jsonEncode(optimisticAttachments.map((a) => a.toJson()).toList())
          : null),
      voiceNoteJson: drift.Value(voiceNote != null
          ? jsonEncode(voiceNote.toJson())
          : null),
      status: const drift.Value('pending'),
      isPendingSync: const drift.Value(true),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    // 2. Atomic SQLite transaction: save message + enqueue in sync queue
    await _db.transaction(() async {
      await _db.messagesDao.insertMessage(localCompanion);
      await _db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: drift.Value(const Uuid().v4()),
          operationType: const drift.Value('CREATE_MESSAGE'),
          entityType: const drift.Value('MESSAGE'),
          entityId: drift.Value(localId),
          payload: drift.Value(jsonEncode({
            'conversationId': conversationId,
            'content': content,
            'type': type,
            'replyToId': replyToId,
            'fileIds': attachmentIds,
            'clientId': effectiveClientId,
            'localId': localId,
          })),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          status: const drift.Value('pending'),
        ),
      );

      // Also update conversation snippet locally
      await _db.conversationsDao.updateLastMessage(
        conversationId: conversationId,
        lastMessageId: localId,
        lastMessageContent: content,
        lastMessageType: type,
        lastMessageSenderName: senderDisplayName ?? senderUsername,
        lastMessageSenderId: senderId,
        lastMessageAt: now,
      );
    });

    // 3. Attempt immediate send if online
    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (isOnline) {
      try {
        final serverMessage = await _remoteDatasource.sendMessage(
          conversationId: conversationId,
          content: content,
          replyToId: replyToId,
          attachmentIds: attachmentIds,
          type: type,
          clientId: effectiveClientId,
        );

        // Reconcile temporary message with server message ID
        await _db.messagesDao.reconcileServerMessage(
          clientId: effectiveClientId,
          serverId: serverMessage.id,
          status: 'sent',
          attachmentsJson: serverMessage.attachments.isNotEmpty
              ? jsonEncode(serverMessage.attachments.map((a) => a.toJson()).toList())
              : (optimisticAttachments.isNotEmpty
                  ? jsonEncode(optimisticAttachments.map((a) => a.toJson()).toList())
                  : null),
          voiceNoteJson: serverMessage.voiceNote != null
              ? jsonEncode(serverMessage.voiceNote!.toJson())
              : (voiceNote != null ? jsonEncode(voiceNote.toJson()) : null),
        );

        // Remove from persistent sync queue
        await _db.syncQueueDao.removeEntriesForEntity(localId);

        // If server message didn't have voiceNote but we had local voiceNote, retain it
        final resolvedMessage = serverMessage.voiceNote == null && voiceNote != null
            ? serverMessage.copyWith(voiceNote: voiceNote)
            : serverMessage;

        return resolvedMessage;
      } catch (e) {
        debugPrint('[ChatRepo] Immediate send failed (queued for sync): $e');
      }
    }

    // Return optimistic local pending message
    return MessageModel(
      id: localId,
      conversationId: conversationId,
      sender: MessageSenderModel(
        id: senderId,
        username: senderUsername,
        displayName: senderDisplayName,
        avatarUrl: senderAvatarUrl,
      ),
      content: content,
      type: type,
      replyToId: replyToId,
      attachments: optimisticAttachments,
      voiceNote: voiceNote,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<MessageModel> editMessage({
    required String messageId,
    required String content,
  }) async {
    final now = DateTime.now();
    await _db.messagesDao.updateMessageContent(messageId, content, now);

    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (isOnline) {
      try {
        return await _remoteDatasource.editMessage(
          messageId: messageId,
          content: content,
        );
      } catch (e) {
        debugPrint('[ChatRepo] Remote edit error: $e');
      }
    }

    await _db.syncQueueDao.enqueue(
      SyncQueueCompanion(
        id: drift.Value(const Uuid().v4()),
        operationType: const drift.Value('EDIT_MESSAGE'),
        entityType: const drift.Value('MESSAGE'),
        entityId: drift.Value(messageId),
        payload: drift.Value(jsonEncode({
          'messageId': messageId,
          'content': content,
        })),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        status: const drift.Value('pending'),
      ),
    );

    final local = await _db.messagesDao.getMessageByLocalId(messageId);
    if (local != null) return _companionToMessage(local);

    return MessageModel(
      id: messageId,
      conversationId: '',
      sender: const MessageSenderModel(id: '', username: ''),
      content: content,
      type: 'TEXT',
      isEdited: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> deleteMessage(String messageId, {bool forEveryone = false}) async {
    final now = DateTime.now();
    await _db.messagesDao.markMessageDeleted(messageId, now);

    if (!forEveryone) {
      // Local deletion for current user only ("Delete for me")
      return;
    }

    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (isOnline) {
      try {
        await _remoteDatasource.deleteMessage(messageId);
        return;
      } catch (e) {
        debugPrint('[ChatRepo] Remote delete error: $e');
      }
    }

    await _db.syncQueueDao.enqueue(
      SyncQueueCompanion(
        id: drift.Value(const Uuid().v4()),
        operationType: const drift.Value('DELETE_MESSAGE'),
        entityType: const drift.Value('MESSAGE'),
        entityId: drift.Value(messageId),
        payload: drift.Value(jsonEncode({'messageId': messageId})),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        status: const drift.Value('pending'),
      ),
    );
  }

  @override
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (isOnline) {
      try {
        await _remoteDatasource.addReaction(messageId: messageId, emoji: emoji);
        return;
      } catch (_) {}
    }

    await _db.syncQueueDao.enqueue(
      SyncQueueCompanion(
        id: drift.Value(const Uuid().v4()),
        operationType: const drift.Value('SEND_REACTION'),
        entityType: const drift.Value('REACTION'),
        entityId: drift.Value(messageId),
        payload: drift.Value(jsonEncode({
          'messageId': messageId,
          'emoji': emoji,
        })),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
        status: const drift.Value('pending'),
      ),
    );
  }

  @override
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (isOnline) {
      try {
        await _remoteDatasource.removeReaction(messageId: messageId, emoji: emoji);
        return;
      } catch (_) {}
    }

    await _db.syncQueueDao.enqueue(
      SyncQueueCompanion(
        id: drift.Value(const Uuid().v4()),
        operationType: const drift.Value('REMOVE_REACTION'),
        entityType: const drift.Value('REACTION'),
        entityId: drift.Value(messageId),
        payload: drift.Value(jsonEncode({
          'messageId': messageId,
          'emoji': emoji,
        })),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
        status: const drift.Value('pending'),
      ),
    );
  }

  @override
  Future<void> markAsRead(String messageId) async {
    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (isOnline) {
      try {
        await _remoteDatasource.markAsRead(messageId);
        return;
      } catch (_) {}
    }

    await _db.syncQueueDao.enqueue(
      SyncQueueCompanion(
        id: drift.Value(const Uuid().v4()),
        operationType: const drift.Value('UPDATE_READ_STATE'),
        entityType: const drift.Value('READ_STATE'),
        entityId: drift.Value(messageId),
        payload: drift.Value(jsonEncode({'messageId': messageId})),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
        status: const drift.Value('pending'),
      ),
    );
  }

  @override
  Future<void> pinMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _remoteDatasource.pinMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
  }

  @override
  Future<void> unpinMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _remoteDatasource.unpinMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(String conversationId) async {
    return await _remoteDatasource.getPinnedMessages(conversationId);
  }

  @override
  Future<void> starMessage(String messageId) async {
    await _remoteDatasource.starMessage(messageId);
  }

  @override
  Future<void> unstarMessage(String messageId) async {
    await _remoteDatasource.unstarMessage(messageId);
  }

  @override
  Future<List<MessageModel>> getStarredMessages() async {
    return await _remoteDatasource.getStarredMessages();
  }

  @override
  Future<Map<String, dynamic>> uploadChatMedia({
    required String filePath,
    required String fileName,
    required String mimeType,
    String? conversationId,
    Function(int, int)? onUploadProgress,
  }) async {
    return await _remoteDatasource.uploadChatMedia(
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
      conversationId: conversationId,
      onUploadProgress: onUploadProgress,
    );
  }

  @override
  Future<List<ConversationModel>> searchConversations(String query) async {
    return await _remoteDatasource.searchConversations(query);
  }

  @override
  Future<List<MessageModel>> searchMessages({
    required String conversationId,
    required String query,
  }) async {
    return await _remoteDatasource.searchMessages(
      conversationId: conversationId,
      query: query,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // MAPPERS
  // ══════════════════════════════════════════════════════════════

  LocalConversationsCompanion _conversationToCompanion(ConversationModel m) {
    return LocalConversationsCompanion(
      id: drift.Value(m.id),
      type: drift.Value(m.type),
      groupId: drift.Value(m.groupId),
      channelId: drift.Value(m.channelId),
      title: drift.Value(m.title),
      lastMessageId: drift.Value(m.lastMessage?.id),
      lastMessageContent: drift.Value(m.lastMessage?.content),
      lastMessageType: drift.Value(m.lastMessage?.type),
      lastMessageSenderName: drift.Value(m.lastMessage?.senderName),
      lastMessageAt: drift.Value(m.lastMessageAt),
      membersJson: drift.Value(jsonEncode(m.members.map((e) => e.toJson()).toList())),
      metadataJson: drift.Value(m.metadata != null ? jsonEncode(m.metadata!.toJson()) : null),
      createdAt: drift.Value(m.createdAt),
      updatedAt: drift.Value(m.lastMessageAt ?? m.createdAt),
    );
  }

  ConversationModel _companionToConversation(LocalConversationData d) {
    List<ConversationMemberModel> members = [];
    if (d.membersJson != null && d.membersJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(d.membersJson!) as List<dynamic>;
        members = decoded
            .map((e) => ConversationMemberModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    ConversationMetadataModel? metadata;
    if (d.metadataJson != null && d.metadataJson!.isNotEmpty) {
      try {
        metadata = ConversationMetadataModel.fromJson(
            jsonDecode(d.metadataJson!) as Map<String, dynamic>);
      } catch (_) {}
    }

    MessagePreviewModel? lastMessage;
    if (d.lastMessageId != null) {
      lastMessage = MessagePreviewModel(
        id: d.lastMessageId!,
        content: d.lastMessageContent,
        type: d.lastMessageType ?? 'TEXT',
        senderName: d.lastMessageSenderName,
      );
    }

    return ConversationModel(
      id: d.id,
      type: d.type,
      groupId: d.groupId,
      channelId: d.channelId,
      title: d.title,
      lastMessageAt: d.lastMessageAt,
      lastMessage: lastMessage,
      members: members,
      createdAt: d.createdAt ?? DateTime.now(),
      metadata: metadata,
    );
  }

  LocalMessagesCompanion _messageToCompanion(MessageModel m) {
    return LocalMessagesCompanion(
      localId: drift.Value(m.id),
      serverId: drift.Value(m.id),
      clientId: drift.Value(m.id),
      conversationId: drift.Value(m.conversationId),
      channelId: drift.Value(m.channelId),
      senderId: drift.Value(m.sender.id),
      senderUsername: drift.Value(m.sender.username),
      senderDisplayName: drift.Value(m.sender.displayName),
      senderAvatarUrl: drift.Value(m.sender.avatarUrl),
      content: drift.Value(m.content),
      messageType: drift.Value(m.type),
      replyToMessageId: drift.Value(m.replyToId),
      replyToJson: drift.Value(m.replyTo != null ? jsonEncode(m.replyTo!.toJson()) : null),
      isEdited: drift.Value(m.isEdited),
      isPinned: drift.Value(m.isPinned),
      status: const drift.Value('sent'),
      isPendingSync: const drift.Value(false),
      attachmentsJson: drift.Value(
          m.attachments.isNotEmpty ? jsonEncode(m.attachments.map((a) => a.toJson()).toList()) : null),
      voiceNoteJson: drift.Value(
          m.voiceNote != null ? jsonEncode(m.voiceNote!.toJson()) : null),
      attachmentUrl: drift.Value(
          m.attachments.isNotEmpty ? m.attachments.first.url : (m.voiceNote?.url)),
      reactionsJson: drift.Value(
          m.reactions.isNotEmpty ? jsonEncode(m.reactions.map((r) => r.toJson()).toList()) : null),
      readByJson: drift.Value(m.readBy.isNotEmpty ? jsonEncode(m.readBy) : null),
      deliveredToJson: drift.Value(m.deliveredTo.isNotEmpty ? jsonEncode(m.deliveredTo) : null),
      createdAt: drift.Value(m.createdAt),
      updatedAt: drift.Value(m.updatedAt),
    );
  }

  MessageModel _companionToMessage(LocalMessageData d) {
    MessageReplyModel? replyTo;
    if (d.replyToJson != null && d.replyToJson!.isNotEmpty) {
      try {
        replyTo = MessageReplyModel.fromJson(
            jsonDecode(d.replyToJson!) as Map<String, dynamic>);
      } catch (_) {}
    }

    List<MessageAttachmentModel> attachments = [];
    if (d.attachmentsJson != null && d.attachmentsJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(d.attachmentsJson!) as List<dynamic>;
        attachments = decoded
            .map((a) => MessageAttachmentModel.fromJson(a as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    MessageVoiceNoteModel? voiceNote;
    if (d.voiceNoteJson != null && d.voiceNoteJson!.isNotEmpty) {
      try {
        voiceNote = MessageVoiceNoteModel.fromJson(
            jsonDecode(d.voiceNoteJson!) as Map<String, dynamic>);
      } catch (_) {}
    }

    List<MessageReactionModel> reactions = [];
    if (d.reactionsJson != null && d.reactionsJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(d.reactionsJson!) as List<dynamic>;
        reactions = decoded
            .map((r) => MessageReactionModel.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    List<String> readBy = [];
    if (d.readByJson != null && d.readByJson!.isNotEmpty) {
      try {
        readBy = (jsonDecode(d.readByJson!) as List<dynamic>).cast<String>();
      } catch (_) {}
    }

    List<String> deliveredTo = [];
    if (d.deliveredToJson != null && d.deliveredToJson!.isNotEmpty) {
      try {
        deliveredTo =
            (jsonDecode(d.deliveredToJson!) as List<dynamic>).cast<String>();
      } catch (_) {}
    }

    return MessageModel(
      id: d.serverId ?? d.localId,
      conversationId: d.conversationId,
      channelId: d.channelId,
      sender: MessageSenderModel(
        id: d.senderId,
        username: d.senderUsername ?? '',
        displayName: d.senderDisplayName,
        avatarUrl: d.senderAvatarUrl,
      ),
      content: d.content,
      type: d.messageType,
      replyToId: d.replyToMessageId,
      replyTo: replyTo,
      isEdited: d.isEdited,
      isPinned: d.isPinned,
      attachments: attachments,
      voiceNote: voiceNote,
      reactions: reactions,
      readBy: readBy,
      deliveredTo: deliveredTo,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
    );
  }
}
