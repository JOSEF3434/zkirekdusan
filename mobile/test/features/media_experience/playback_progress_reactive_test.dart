import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';
import 'package:mobile/features/media_experience/data/playback_progress_repository.dart';
import 'package:mobile/features/media_experience/domain/playback_progress.dart';
import 'package:mobile/features/media_experience/presentation/providers/continue_watching_provider.dart';

class FakeTestVideoPlayerController extends Fake implements VideoPlayerController {
  bool _isPlaying = true;
  final Duration _position;
  final Duration _duration;

  FakeTestVideoPlayerController({
    Duration position = const Duration(seconds: 38),
    Duration duration = const Duration(minutes: 2, seconds: 3),
  })  : _position = position,
        _duration = duration;

  @override
  VideoPlayerValue get value => VideoPlayerValue(
        duration: _duration,
        position: _position,
        isPlaying: _isPlaying,
        isInitialized: true,
      );

  @override
  void addListener(void Function() listener) {}

  @override
  void removeListener(void Function() listener) {}

  @override
  Future<void> play() {
    _isPlaying = true;
    return Future.value();
  }

  @override
  Future<void> pause() {
    _isPlaying = false;
    return Future.value();
  }

  @override
  Future<void> dispose() {
    return Future.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlaybackProgress Domain Model Tests', () {
    test('Calculates remaining time and unfinished status accurately (user screenshot case)', () {
      final progress = PlaybackProgress(
        videoId: 'vid-user-screenshot',
        videoTitle: 'እክብር ሠንበትክ',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        positionSeconds: 38,
        durationSeconds: 123, // 02:03
        updatedAt: DateTime.now(),
      );

      expect(progress.isTrivial, isFalse);
      expect(progress.isComplete, isFalse);
      expect(progress.remainingSeconds, equals(85));
      expect(progress.fraction, closeTo(38 / 123, 0.01));
    });

    test('Identifies trivial and completed states correctly', () {
      final trivialProgress = PlaybackProgress(
        videoId: 'v1',
        videoTitle: 'Trivial',
        positionSeconds: 2,
        durationSeconds: 120,
        updatedAt: DateTime.now(),
      );
      expect(trivialProgress.isTrivial, isTrue);

      final completedProgress = PlaybackProgress(
        videoId: 'v2',
        videoTitle: 'Finished',
        positionSeconds: 119,
        durationSeconds: 120,
        updatedAt: DateTime.now(),
      );
      expect(completedProgress.isComplete, isTrue);
    });
  });

  group('Reactive PlaybackProgressRepository & ContinueWatchingNotifier Tests', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('ContinueWatching updates immediately when progress is saved anywhere', () async {
      final repo = container.read(playbackProgressRepositoryProvider);
      final initialCw = container.read(continueWatchingProvider);
      expect(initialCw.items, isEmpty);

      final progress = PlaybackProgress(
        videoId: 'video-456',
        videoTitle: 'እክብር ሠንበትክ',
        thumbnailUrl: 'https://example.com/img.jpg',
        positionSeconds: 40,
        durationSeconds: 120,
        updatedAt: DateTime.now(),
      );

      // Save to repository (simulating PlayerNotifier or MiniPlayerNotifier)
      await repo.save(progress);

      // Wait a microtask for reactive stream
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final updatedCw = container.read(continueWatchingProvider);
      expect(updatedCw.items.length, equals(1));
      expect(updatedCw.items.first.videoId, equals('video-456'));
      expect(updatedCw.items.first.videoTitle, equals('እክብር ሠንበትክ'));
      expect(updatedCw.items.first.positionSeconds, equals(40));
    });

    test('MiniPlayer dismiss saves progress and immediately reveals Continue Watching', () async {
      final fakeCtrl = FakeTestVideoPlayerController(
        position: const Duration(seconds: 45),
        duration: const Duration(minutes: 2),
      );

      final miniNotifier = container.read(miniPlayerProvider.notifier);
      miniNotifier.showVideo(
        videoId: 'mini-vid-999',
        title: 'Mini Video Test',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        controller: fakeCtrl,
        wasPlaying: true,
      );

      // Dismiss mini-player (e.g. user taps 'X')
      miniNotifier.dismiss();

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final cwState = container.read(continueWatchingProvider);
      expect(cwState.items.any((item) => item.videoId == 'mini-vid-999'), isTrue);
      final item = cwState.items.firstWhere((e) => e.videoId == 'mini-vid-999');
      expect(item.positionSeconds, equals(45));
    });

    test('Removing from Continue Watching updates provider reactively', () async {
      final repo = container.read(playbackProgressRepositoryProvider);
      await repo.save(PlaybackProgress(
        videoId: 'to-remove',
        videoTitle: 'Remove Me',
        positionSeconds: 30,
        durationSeconds: 100,
        updatedAt: DateTime.now(),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(container.read(continueWatchingProvider).items.length, equals(1));

      // Remove item via ContinueWatchingNotifier
      await container.read(continueWatchingProvider.notifier).removeItem('to-remove');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(continueWatchingProvider).items, isEmpty);
    });
  });
}
