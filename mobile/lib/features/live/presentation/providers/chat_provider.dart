// ignore_for_file: prefer_initializing_formals
// lib/features/live/presentation/providers/chat_provider.dart
// Real-time chat state with history loading, deduplication, and send states.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/data/stream_chat_repository.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

import 'package:mobile/core/storage/secure_storage.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessageDto> messages;
  final bool isLoadingHistory;
  final bool hasMore;
  final String? nextCursor;
  final String? error;
  final bool isSending;
  final String? sendError;

  const ChatState({
    this.messages = const [],
    this.isLoadingHistory = true,
    this.hasMore = false,
    this.nextCursor,
    this.error,
    this.isSending = false,
    this.sendError,
  });

  ChatState copyWith({
    List<ChatMessageDto>? messages,
    bool? isLoadingHistory,
    bool? hasMore,
    String? nextCursor,
    String? error,
    bool clearError = false,
    bool? isSending,
    String? sendError,
    bool clearSendError = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    hasMore: hasMore ?? this.hasMore,
    nextCursor: nextCursor ?? this.nextCursor,
    error: clearError ? null : (error ?? this.error),
    isSending: isSending ?? this.isSending,
    sendError: clearSendError ? null : (sendError ?? this.sendError),
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final String _streamId;
  final StreamChatRepository _chatRepo;
  final LiveSocketService _socket;
  final StorageService _storage;
  final bool _isAuthenticated;

  final List<StreamSubscription> _subs = [];

  ChatNotifier({
    required String streamId,
    required StreamChatRepository chatRepo,
    required LiveSocketService socket,
    required StorageService storage,
    required bool isAuthenticated,
  }) : _streamId = streamId,
       _chatRepo = chatRepo,
       _socket = socket,
       _storage = storage,
       _isAuthenticated = isAuthenticated,
       super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    // Load chat history via REST
    await _loadHistory();

    // Ensure socket connected & joined stream room
    await _ensureSocketConnected();

    // Subscribe to real-time messages
    _subs.add(_socket.onChatMessage.listen(_onNewMessage));
    _subs.add(_socket.onChatDeleted.listen(_onMessageDeleted));
    _subs.add(_socket.onChatPinned.listen(_onMessagePinned));
    _subs.add(_socket.onChatReaction.listen(_onChatReaction));
    _subs.add(_socket.onError.listen(_onSocketError));
  }

  Future<void> _ensureSocketConnected() async {
    try {
      if (!_socket.isConnected) {
        final token = await _storage.getToken();
        if (token != null && token.isNotEmpty) {
          await _socket.connect(token);
        }
      }
      _socket.joinStream(_streamId);
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final hist = await _chatRepo.getChatHistory(_streamId, limit: 50);
      // Deduplicate by id
      final seen = <String>{};
      final msgs = hist.messages.reversed
          .where((m) => seen.add(m.id))
          .toList()
          .reversed
          .toList();
      state = state.copyWith(
        messages: msgs,
        isLoadingHistory: false,
        hasMore: hist.hasMore,
        nextCursor: hist.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false, error: e.toString());
    }
  }

  Future<void> loadOlderMessages() async {
    if (!state.hasMore || state.nextCursor == null) return;
    try {
      final hist = await _chatRepo.getChatHistory(
        _streamId,
        limit: 50,
        cursor: state.nextCursor,
      );
      final existingIds = {for (final m in state.messages) m.id};
      final older = hist.messages
          .where((m) => !existingIds.contains(m.id))
          .toList();
      state = state.copyWith(
        messages: [...older, ...state.messages],
        hasMore: hist.hasMore,
        nextCursor: hist.nextCursor,
      );
    } catch (_) {}
  }

  void _onNewMessage(ChatMessageDto msg) {
    if (!mounted) return;

    // 1. Deduplicate by exact message ID
    final existingIndex = state.messages.indexWhere((m) => m.id == msg.id);
    if (existingIndex >= 0) {
      final updated = List<ChatMessageDto>.from(state.messages);
      updated[existingIndex] = msg;
      state = state.copyWith(messages: updated, clearSendError: true, isSending: false);
      return;
    }

    // 2. Replace pending version matching the same content
    final pendingIndex = state.messages.indexWhere(
      (m) => m.isPending && m.content.trim() == msg.content.trim(),
    );
    if (pendingIndex >= 0) {
      final updated = List<ChatMessageDto>.from(state.messages);
      updated[pendingIndex] = msg;
      state = state.copyWith(messages: updated, clearSendError: true, isSending: false);
      return;
    }

    // 3. Append incoming message
    state = state.copyWith(
      messages: [...state.messages, msg],
      clearSendError: true,
      isSending: false,
    );
  }

  void _onMessageDeleted(String messageId) {
    if (!mounted) return;
    state = state.copyWith(
      messages: state.messages
          .map(
            (m) => m.id == messageId
                ? m.copyWith(isDeleted: true, content: '[Message deleted]')
                : m,
          )
          .toList(),
    );
  }

  void _onMessagePinned(ChatMessageDto pinned) {
    if (!mounted) return;
    state = state.copyWith(
      messages: state.messages
          .map((m) => m.id == pinned.id ? pinned : m.copyWith(isPinned: false))
          .toList(),
    );
  }

  void _onChatReaction(ChatReactionEvent event) {
    // Reactions are cosmetic
  }

  void _onSocketError(String msg) {
    if (!mounted) return;
    // Mark pending messages as sent or clear pending state on error
    final updated = state.messages.map((m) {
      if (m.isPending) return m.copyWith(isPending: false);
      return m;
    }).toList();
    state = state.copyWith(sendError: msg, isSending: false, messages: updated);
  }

  Future<void> sendMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty) return;
    if (state.isSending) return;
    if (!_isAuthenticated) {
      state = state.copyWith(sendError: 'Please log in to participate in chat');
      return;
    }

    await _ensureSocketConnected();

    state = state.copyWith(isSending: true, clearSendError: true);
    final pendingId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final pending = ChatMessageDto(
      id: pendingId,
      content: text,
      type: ChatMessageType.text,
      createdAt: DateTime.now().toIso8601String(),
      isPending: true,
    );
    state = state.copyWith(messages: [...state.messages, pending]);

    _socket.sendChat(streamId: _streamId, content: text);

    // Timeout fallback (4s): clear isSending and remove pending spinner
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        final hasPending = state.messages.any((m) => m.id == pendingId && m.isPending);
        if (hasPending) {
          final updated = state.messages.map((m) {
            if (m.id == pendingId) return m.copyWith(isPending: false);
            return m;
          }).toList();
          state = state.copyWith(messages: updated, isSending: false);
        } else if (state.isSending) {
          state = state.copyWith(isSending: false);
        }
      }
    });
  }

  Future<void> sendReaction(String emoji) async {
    await _ensureSocketConnected();
    _socket.sendReaction(streamId: _streamId, emoji: emoji);
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>((
      ref,
      streamId,
    ) {
      final chatRepo = ref.read(streamChatRepositoryProvider);
      final socket = ref.read(liveSocketServiceProvider);
      final storage = ref.read(storageServiceProvider);
      final auth = ref.read(authProvider);

      return ChatNotifier(
        streamId: streamId,
        chatRepo: chatRepo,
        socket: socket,
        storage: storage,
        isAuthenticated: auth.status == AuthStatus.authenticated,
      );
    });
