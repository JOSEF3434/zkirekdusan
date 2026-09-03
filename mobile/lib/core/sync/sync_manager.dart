// lib/core/sync/sync_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/sync/retry_strategy.dart';
import 'package:mobile/core/sync/sync_types.dart';

class SyncManager extends StateNotifier<SyncStatus> {
  final Dio _apiClient;
  final AppDatabase _db;
  final ConnectivityNotifier _connectivity;

  bool _isSyncing = false;
  Timer? _successResetTimer;

  SyncManager(this._apiClient, this._db, this._connectivity)
      : super(SyncStatus.idle) {
    _init();
  }

  void _init() {
    // Automatically trigger sync when transitioning to online
    _connectivity.addOnlineStatusListener((isOnline) {
      if (isOnline) {
        triggerSync();
      } else {
        state = SyncStatus.offline;
      }
    });

    // Check on startup
    if (_connectivity.state.isOnline) {
      // Delay slightly on startup to let UI initialize
      Future.delayed(const Duration(seconds: 2), () {
        triggerSync();
      });
    } else {
      state = SyncStatus.offline;
    }
  }

  /// Triggers a full synchronization pass.
  /// Non-reentrant (prevents concurrent sync executions).
  Future<void> triggerSync() async {
    if (_isSyncing) return;

    if (!_connectivity.state.isOnline) {
      state = SyncStatus.offline;
      return;
    }

    _isSyncing = true;
    state = SyncStatus.syncing;
    _successResetTimer?.cancel();

    try {
      final pendingEntries = await _db.syncQueueDao.getPendingEntries();
      if (pendingEntries.isEmpty) {
        state = SyncStatus.idle;
        _isSyncing = false;
        return;
      }

      bool anyFailed = false;

      for (final entry in pendingEntries) {
        if (!_connectivity.state.isOnline) {
          anyFailed = true;
          break;
        }

        try {
          await _processEntry(entry);
          await _db.syncQueueDao.removeEntry(entry.id);
        } catch (e) {
          anyFailed = true;
          final isNetworkError = _isRecoverableError(e);

          if (isNetworkError && RetryStrategy.shouldRetry(entry.retryCount)) {
            final nextRetry = RetryStrategy.getNextRetryTime(entry.retryCount);
            await _db.syncQueueDao.updateEntryStatus(
              entry.id,
              'failed',
              retryCount: entry.retryCount + 1,
              nextRetryAt: nextRetry,
              error: e.toString(),
            );
          } else {
            // Max retries reached or non-recoverable error
            await _db.syncQueueDao.updateEntryStatus(
              entry.id,
              'failed',
              retryCount: entry.retryCount + 1,
              nextRetryAt: null,
              error: e.toString(),
            );
          }
        }
      }

      // Cleanup completed entries
      await _db.syncQueueDao.clearCompleted();

      if (anyFailed) {
        state = SyncStatus.failed;
      } else {
        state = SyncStatus.success;
        _successResetTimer = Timer(const Duration(seconds: 3), () {
          if (state == SyncStatus.success) {
            state = SyncStatus.idle;
          }
        });
      }
    } catch (e) {
      debugPrint('[SyncManager] Top-level sync error: $e');
      state = SyncStatus.failed;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processEntry(SyncQueueData entry) async {
    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final op = SyncOperationType.fromString(entry.operationType);

    switch (op) {
      case SyncOperationType.createMessage:
        await _handleCreateMessage(payload);
        break;
      case SyncOperationType.editMessage:
        await _handleEditMessage(payload);
        break;
      case SyncOperationType.deleteMessage:
        await _handleDeleteMessage(payload);
        break;
      case SyncOperationType.sendReaction:
        await _handleSendReaction(payload);
        break;
      case SyncOperationType.removeReaction:
        await _handleRemoveReaction(payload);
        break;
      case SyncOperationType.updateReadState:
        await _handleUpdateReadState(payload);
        break;
      case SyncOperationType.updateWatchHistory:
        await _handleUpdateWatchHistory(payload, entry.entityId);
        break;
      case SyncOperationType.createLike:
        await _handleCreateLike(payload);
        break;
      case SyncOperationType.removeLike:
        await _handleRemoveLike(payload);
        break;
    }
  }

  Future<void> _handleCreateMessage(Map<String, dynamic> payload) async {
    final conversationId = payload['conversationId'] as String;
    final clientId = payload['clientId'] as String;
    final content = payload['content'] as String?;
    final type = payload['type'] as String? ?? 'TEXT';
    final replyToId = payload['replyToId'] as String?;
    final fileIds = (payload['fileIds'] as List<dynamic>?)?.cast<String>();

    final Map<String, dynamic> requestData = {
      'type': type,
      'clientId': clientId,
    };
    if (content != null) {
      requestData['content'] = content;
    }
    if (replyToId != null) {
      requestData['replyToId'] = replyToId;
    }
    if (fileIds != null && fileIds.isNotEmpty) {
      requestData['fileIds'] = fileIds;
    }

    final response = await _apiClient.post(
      '/conversations/$conversationId/messages',
      data: requestData,
    );

    final data = parseEnvelope(response.data);
    final serverId = data['id'] as String?;

    if (serverId != null) {
      await _db.messagesDao.reconcileServerMessage(
        clientId: clientId,
        serverId: serverId,
        status: 'sent',
      );
    }
  }

  Future<void> _handleEditMessage(Map<String, dynamic> payload) async {
    final rawMessageId = payload['messageId'] as String;
    final content = payload['content'] as String;

    // Check if messageId is a localId; resolve serverId if so
    String serverId = rawMessageId;
    final localMsg = await _db.messagesDao.getMessageByLocalId(rawMessageId);
    if (localMsg != null && localMsg.serverId != null) {
      serverId = localMsg.serverId!;
    }

    await _apiClient.patch(
      '/messages/$serverId',
      data: {'content': content},
    );
  }

  Future<void> _handleDeleteMessage(Map<String, dynamic> payload) async {
    final rawMessageId = payload['messageId'] as String;
    String serverId = rawMessageId;
    final localMsg = await _db.messagesDao.getMessageByLocalId(rawMessageId);
    if (localMsg != null && localMsg.serverId != null) {
      serverId = localMsg.serverId!;
    }

    await _apiClient.delete('/messages/$serverId');
  }

  Future<void> _handleSendReaction(Map<String, dynamic> payload) async {
    final rawMessageId = payload['messageId'] as String;
    final emoji = payload['emoji'] as String;
    String serverId = rawMessageId;
    final localMsg = await _db.messagesDao.getMessageByLocalId(rawMessageId);
    if (localMsg != null && localMsg.serverId != null) {
      serverId = localMsg.serverId!;
    }

    await _apiClient.post(
      '/messages/$serverId/reactions',
      data: {'emoji': emoji},
    );
  }

  Future<void> _handleRemoveReaction(Map<String, dynamic> payload) async {
    final rawMessageId = payload['messageId'] as String;
    final emoji = payload['emoji'] as String;
    String serverId = rawMessageId;
    final localMsg = await _db.messagesDao.getMessageByLocalId(rawMessageId);
    if (localMsg != null && localMsg.serverId != null) {
      serverId = localMsg.serverId!;
    }

    await _apiClient.delete(
      '/messages/$serverId/reactions/${Uri.encodeComponent(emoji)}',
    );
  }

  Future<void> _handleUpdateReadState(Map<String, dynamic> payload) async {
    final rawMessageId = payload['messageId'] as String?;
    final conversationId = payload['conversationId'] as String?;

    if (rawMessageId != null) {
      String serverId = rawMessageId;
      final localMsg = await _db.messagesDao.getMessageByLocalId(rawMessageId);
      if (localMsg != null && localMsg.serverId != null) {
        serverId = localMsg.serverId!;
      }
      await _apiClient.post('/messages/$serverId/read');
    } else if (conversationId != null) {
      await _apiClient.post('/conversations/$conversationId/read');
    }
  }

  Future<void> _handleUpdateWatchHistory(
    Map<String, dynamic> payload,
    String entityId,
  ) async {
    final videoId = payload['videoId'] as String;
    final watchedSeconds = (payload['watchedSeconds'] as num).toInt();

    await _apiClient.patch(
      '/videos/$videoId/progress',
      data: {'watchedSeconds': watchedSeconds},
    );

    await _db.watchHistoryDao.markSynced(entityId);
  }

  Future<void> _handleCreateLike(Map<String, dynamic> payload) async {
    final videoId = payload['videoId'] as String;
    await _apiClient.post('/videos/$videoId/like');
  }

  Future<void> _handleRemoveLike(Map<String, dynamic> payload) async {
    final videoId = payload['videoId'] as String;
    await _apiClient.delete('/videos/$videoId/like');
  }

  bool _isRecoverableError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return true;
      }
      final code = error.response?.statusCode;
      if (code != null && code >= 500) {
        return true; // Server error: retryable
      }
      if (code == 429) {
        return true; // Rate limit: retryable
      }
      return false; // Client error (400, 403, 404): non-recoverable
    }
    return true;
  }

  @override
  void dispose() {
    _successResetTimer?.cancel();
    super.dispose();
  }
}
