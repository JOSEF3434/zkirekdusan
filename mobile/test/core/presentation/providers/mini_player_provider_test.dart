import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';

class FakeVideoPlayerController extends Fake implements VideoPlayerController {
  bool _isPlaying = true;
  bool _isDisposed = false;
  final List<void Function()> _listeners = [];

  @override
  VideoPlayerValue get value => VideoPlayerValue(
        duration: const Duration(minutes: 5),
        position: const Duration(seconds: 30),
        isPlaying: _isPlaying,
        isInitialized: true,
      );

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  @override
  void notifyListeners() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  @override
  Future<void> play() {
    _isPlaying = true;
    notifyListeners();
    return Future.value();
  }

  @override
  Future<void> pause() {
    _isPlaying = false;
    notifyListeners();
    return Future.value();
  }

  @override
  Future<void> dispose() {
    _isDisposed = true;
    return Future.value();
  }

  bool get isDisposed => _isDisposed;
}

void main() {
  group('MiniPlayerNotifier Handoff & Controls Tests', () {
    late ProviderContainer container;
    late FakeVideoPlayerController fakeCtrl;

    setUp(() {
      container = ProviderContainer();
      fakeCtrl = FakeVideoPlayerController();
    });

    tearDown(() {
      container.dispose();
    });

    test('showVideo activates miniplayer with handoff grace period and playing state', () {
      final notifier = container.read(miniPlayerProvider.notifier);

      notifier.showVideo(
        videoId: 'vid-123',
        title: 'Test Video',
        channelName: 'Channel A',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        controller: fakeCtrl,
        wasPlaying: true,
      );

      final state = container.read(miniPlayerProvider);
      expect(state.isVisible, isTrue);
      expect(state.contentId, equals('vid-123'));
      expect(state.isPlaying, isTrue);
      expect(state.wasPlayingBeforeHandoff, isTrue);
      expect(state.isHandoffInProgress, isTrue);
    });

    test('syncPlaybackState protects against involuntary DOM pause during handoff', () async {
      final notifier = container.read(miniPlayerProvider.notifier);

      notifier.showVideo(
        videoId: 'vid-123',
        title: 'Test Video',
        controller: fakeCtrl,
        wasPlaying: true,
      );

      // Simulate browser DOM unmounting emitting an involuntary pause event
      fakeCtrl._isPlaying = false;
      notifier.syncPlaybackState(fakeCtrl);

      // Playback state in provider must remain true during handoff
      final state = container.read(miniPlayerProvider);
      expect(state.isPlaying, isTrue);
    });

    test('togglePlayPause correctly switches playback and respects user pause', () {
      final notifier = container.read(miniPlayerProvider.notifier);

      notifier.showVideo(
        videoId: 'vid-123',
        title: 'Test Video',
        controller: fakeCtrl,
        wasPlaying: true,
      );

      expect(container.read(miniPlayerProvider).isPlaying, isTrue);

      notifier.togglePlayPause();
      expect(container.read(miniPlayerProvider).isPlaying, isFalse);

      notifier.togglePlayPause();
      expect(container.read(miniPlayerProvider).isPlaying, isTrue);
    });

    test('prepareExpand and reclaimController transfer controller smoothly', () {
      final notifier = container.read(miniPlayerProvider.notifier);

      notifier.showVideo(
        videoId: 'vid-123',
        title: 'Test Video',
        controller: fakeCtrl,
        wasPlaying: true,
      );

      notifier.prepareExpand();
      final expandingState = container.read(miniPlayerProvider);
      expect(expandingState.isVisible, isFalse);
      expect(expandingState.isNavigatingToFull, isTrue);
      expect(expandingState.wasPlayingBeforeHandoff, isTrue);

      final reclaimed = notifier.reclaimController('vid-123');
      expect(reclaimed, equals(fakeCtrl));
      expect(notifier.lastReclaimedWasPlaying, isTrue);

      // State is reset after reclamation
      final finalState = container.read(miniPlayerProvider);
      expect(finalState.isVisible, isFalse);
      expect(finalState.contentId, isNull);
    });

    test('dismiss terminates playback and resets mini player state', () {
      final notifier = container.read(miniPlayerProvider.notifier);

      notifier.showVideo(
        videoId: 'vid-123',
        title: 'Test Video',
        controller: fakeCtrl,
        wasPlaying: true,
      );

      notifier.dismiss();

      final state = container.read(miniPlayerProvider);
      expect(state.isVisible, isFalse);
      expect(state.hasContent, isFalse);
      expect(fakeCtrl.isDisposed, isTrue);
    });
  });
}
