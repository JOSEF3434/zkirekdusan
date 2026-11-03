// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';
import 'package:mobile/core/presentation/widgets/floating_mini_player.dart';

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Widget buildView(int textureId) {
    return const SizedBox(key: Key('FakeVideoView'));
  }
}

class MockVideoPlayerController extends Fake implements VideoPlayerController {
  bool _isPlaying = true;
  bool _isDisposed = false;
  final List<void Function()> _listeners = [];

  int get textureId => 0;

  @override
  int get playerId => 0;

  @override
  VideoPlayerValue get value => VideoPlayerValue(
        duration: const Duration(minutes: 10),
        position: const Duration(minutes: 1),
        isPlaying: _isPlaying,
        isInitialized: true,
        size: const Size(1920, 1080),
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVideoPlayerController mockCtrl;

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  setUp(() {
    mockCtrl = MockVideoPlayerController();
  });

  Widget buildTestWidget({required ProviderContainer container}) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingMiniPlayer(),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('FloatingMiniPlayer close button dismisses miniplayer cleanly', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(miniPlayerProvider.notifier).showVideo(
      videoId: 'test-v1',
      title: 'Amazing Video',
      channelName: 'Channel One',
      controller: mockCtrl,
      wasPlaying: true,
    );

    await tester.pumpWidget(buildTestWidget(container: container));
    await tester.pump();

    expect(find.text('Amazing Video'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Tap Close Button (X)
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // MiniPlayer must be dismissed and invisible
    expect(container.read(miniPlayerProvider).isVisible, isFalse);
    expect(find.text('Amazing Video'), findsNothing);
  });

  testWidgets('FloatingMiniPlayer double tap toggles play/pause with feedback icon', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(miniPlayerProvider.notifier).showVideo(
      videoId: 'test-v1',
      title: 'Amazing Video',
      channelName: 'Channel One',
      controller: mockCtrl,
      wasPlaying: true,
    );

    await tester.pumpWidget(buildTestWidget(container: container));
    await tester.pump();

    expect(container.read(miniPlayerProvider).isPlaying, isTrue);

    // Double tap the preview area
    final videoFinder = find.byType(VideoPlayer);
    expect(videoFinder, findsOneWidget);

    await tester.tap(videoFinder, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(videoFinder, warnIfMissed: false);
    await tester.pump();

    // Double tap pauses playback
    expect(container.read(miniPlayerProvider).isPlaying, isFalse);

    // Wait for the double tap feedback timer (650ms) to settle
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(videoFinder, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(videoFinder, warnIfMissed: false);
    await tester.pump();

    expect(container.read(miniPlayerProvider).isPlaying, isTrue);

    // Dismiss and settle so all timers are cleanly flushed
    container.read(miniPlayerProvider.notifier).dismiss();
    await tester.pumpAndSettle();
  });
}
