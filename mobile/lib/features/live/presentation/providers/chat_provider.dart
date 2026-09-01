// ignore_for_file: prefer_initializing_formals
// lib/features/live/presentation/providers/chat_provider.dart
// Real-time chat state with history loading, deduplication, and send states.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/data/stream_chat_repository.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

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
  final bool _isAuthenticated;

  final List<StreamSubscription> _subs = [];

  ChatNotifier({
    required String streamId,
    required StreamChatRepository chatRepo,
    required LiveSocketService socket,
    required bool isAuthenticated,
  }) : _streamId = streamId,
       _chatRepo = chatRepo,
       _socket = socket,
       _isAuthenticated = isAuthenticated,
       super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    // Load chat history via REST
    await _loadHistory();

    // Subscribe to real-time messages
    _subs.add(_socket.onChatMessage.listen(_onNewMessage));
    _subs.add(_socket.onChatDeleted.listen(_onMessageDeleted));
    _subs.add(_socket.onChatPinned.listen(_onMessagePinned));
    _subs.add(_socket.onChatReaction.listen(_onChatReaction));
    _subs.add(_socket.onError.listen(_onSocketError));
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
    // Deduplicate: replace pending version or ignore duplicate
    final existing = state.messages.indexWhere((m) => m.id == msg.id);
    if (existing >= 0) {
      final updated = List<ChatMessageDto>.from(state.messages);
      updated[existing] = msg;
      state = state.copyWith(messages: updated, clearSendError: true);
    } else {
      state = state.copyWith(
        messages: [...state.messages, msg],
        clearSendError: true,
      );
    }
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
    // Unpin all others then pin this one
    state = state.copyWith(
      messages: state.messages
          .map((m) => m.id == pinned.id ? pinned : m.copyWith(isPinned: false))
          .toList(),
    );
  }

  void _onChatReaction(ChatReactionEvent event) {
    // Reactions are cosmetic; no state change needed for MVP
  }

  void _onSocketError(String msg) {
    if (!mounted) return;
    // Rate-limit / send error
    if (msg.toLowerCase().contains('slow down') ||
        msg.toLowerCase().contains('fast')) {
      state = state.copyWith(sendError: msg, isSending: false);
    }
  }

  Future<void> sendMessage(String content) async {
    if (!_isAuthenticated) return;
    if (content.trim().isEmpty) return;
    if (state.isSending) return;

    state = state.copyWith(isSending: true, clearSendError: true);
    // Optimistic: add pending message (no real id yet)
    final pending = ChatMessageDto(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      content: content.trim(),
      type: ChatMessageType.text,
      createdAt: DateTime.now().toIso8601String(),
      isPending: true,
    );
    state = state.copyWith(messages: [...state.messages, pending]);

    _socket.sendChat(streamId: _streamId, content: content.trim());

    // The actual confirmation comes via the onChatMessage stream event.
    // Mark pending as complete after timeout fallback (3s)
    await Future.delayed(const Duration(seconds: 3));
    if (mounted && state.isSending) {
      state = state.copyWith(isSending: false);
    }
  }

  void sendReaction(String emoji) {
    if (!_isAuthenticated) return;
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
      final auth = ref.read(authProvider);

      return ChatNotifier(
        streamId: streamId,
        chatRepo: chatRepo,
        socket: socket,
        isAuthenticated: auth.status == AuthStatus.authenticated,
      );
    });
