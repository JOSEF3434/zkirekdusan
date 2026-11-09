// lib/features/groups/presentation/providers/channel_subscribe_provider.dart
// Channel subscribe/unsubscribe state with optimistic updates and rollback.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ChannelSubscribeState {
  final bool isSubscribed;
  final bool isLoading;
  final String? error;

  const ChannelSubscribeState({
    this.isSubscribed = false,
    this.isLoading = false,
    this.error,
  });

  ChannelSubscribeState copyWith({
    bool? isSubscribed,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChannelSubscribeState(
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Scoped per video-channel ID.
final channelSubscribeProvider = AsyncNotifierProviderFamily<
    ChannelSubscribeNotifier, ChannelSubscribeState, String>(
  ChannelSubscribeNotifier.new,
);

class ChannelSubscribeNotifier
    extends FamilyAsyncNotifier<ChannelSubscribeState, String> {
  String get _channelId => arg;
  bool _actionInProgress = false;

  @override
  Future<ChannelSubscribeState> build(String arg) async {
    final dio = ref.read(apiClientProvider);
    try {
      final response =
          await dio.get('/video-channels/$_channelId/subscribe-status');
      final raw = response.data;
      Map<String, dynamic> data = {};
      if (raw is Map<String, dynamic> && raw.containsKey('success')) {
        data = (raw['data'] as Map<String, dynamic>?) ?? {};
      } else if (raw is Map<String, dynamic>) {
        data = raw;
      }
      return ChannelSubscribeState(
        isSubscribed: data['isSubscribed'] as bool? ?? false,
      );
    } catch (_) {
      return const ChannelSubscribeState(isSubscribed: false);
    }
  }

  Future<void> subscribe() async {
    if (_actionInProgress) return;
    _actionInProgress = true;
    final prev = state.valueOrNull ?? const ChannelSubscribeState();

    // Optimistic update
    state = AsyncValue.data(
      prev.copyWith(isSubscribed: true, isLoading: true, clearError: true),
    );
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/video-channels/$_channelId/subscribe');
      state = AsyncValue.data(
        prev.copyWith(isSubscribed: true, isLoading: false, clearError: true),
      );
    } catch (e) {
      // Rollback
      state = AsyncValue.data(
        prev.copyWith(
          isSubscribed: false,
          isLoading: false,
          error: e.toString(),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> unsubscribe() async {
    if (_actionInProgress) return;
    _actionInProgress = true;
    final prev = state.valueOrNull ?? const ChannelSubscribeState(isSubscribed: true);

    // Optimistic update
    state = AsyncValue.data(
      prev.copyWith(isSubscribed: false, isLoading: true, clearError: true),
    );
    try {
      final dio = ref.read(apiClientProvider);
      try {
        await dio.post('/video-channels/$_channelId/unsubscribe');
      } catch (_) {
        await dio.delete('/video-channels/$_channelId/subscribe');
      }
      state = AsyncValue.data(
        prev.copyWith(
          isSubscribed: false,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      // Rollback
      state = AsyncValue.data(
        prev.copyWith(
          isSubscribed: true,
          isLoading: false,
          error: e.toString(),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> toggle([bool? currentStatus]) async {
    final isSub = state.valueOrNull?.isSubscribed ?? currentStatus ?? false;
    if (isSub) {
      await unsubscribe();
    } else {
      await subscribe();
    }
  }
}

