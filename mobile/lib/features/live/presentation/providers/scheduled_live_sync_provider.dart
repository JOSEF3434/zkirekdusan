// lib/features/live/presentation/providers/scheduled_live_sync_provider.dart
// Provides real-time synchronization and automatic transitions for scheduled live streams
// across Explore, Live Discovery, and all relevant screens.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';

/// Periodic 1-second ticker stream provider used to trigger automatic UI transitions
/// precisely when a scheduled stream's start time arrives.
final scheduledCountdownTickerProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// Map of streamId -> LiveStreamStatus override for streams that have transitioned
/// in real-time (via start time arrival or socket event).
class ScheduledLiveSyncNotifier extends StateNotifier<Map<String, LiveStreamStatus>> {
  final Ref _ref;
  StreamSubscription<LiveStreamDto>? _startedSub;
  StreamSubscription<LiveStreamDto>? _updatedSub;
  StreamSubscription<StreamEndedEvent>? _endedSub;

  ScheduledLiveSyncNotifier(this._ref) : super({}) {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    final socket = _ref.read(liveSocketServiceProvider);

    _startedSub = socket.onStreamStarted.listen((stream) {
      markStreamLive(stream.id);
    });

    _updatedSub = socket.onStreamUpdated.listen((stream) {
      if (stream.status == LiveStreamStatus.live) {
        markStreamLive(stream.id);
      } else if (stream.status == LiveStreamStatus.ended) {
        markStreamEnded(stream.id);
      }
    });

    _endedSub = socket.onStreamEnded.listen((event) {
      markStreamEnded(event.streamId);
    });
  }

  void markStreamLive(String streamId) {
    if (state[streamId] != LiveStreamStatus.live) {
      state = {...state, streamId: LiveStreamStatus.live};
    }
  }

  void markStreamEnded(String streamId) {
    if (state[streamId] != LiveStreamStatus.ended) {
      state = {...state, streamId: LiveStreamStatus.ended};
    }
  }


  LiveStreamStatus getEffectiveStatus(String streamId, LiveStreamStatus fallback) {
    return state[streamId] ?? fallback;
  }

  @override
  void dispose() {
    _startedSub?.cancel();
    _updatedSub?.cancel();
    _endedSub?.cancel();
    super.dispose();
  }
}

final scheduledLiveSyncProvider =
    StateNotifierProvider<ScheduledLiveSyncNotifier, Map<String, LiveStreamStatus>>(
  (ref) => ScheduledLiveSyncNotifier(ref),
);
