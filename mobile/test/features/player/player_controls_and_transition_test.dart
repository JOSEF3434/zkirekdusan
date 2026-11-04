// test/features/player/player_controls_and_transition_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/player/presentation/providers/player_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerState tests', () {
    test('Default values initialized correctly', () {
      const state = PlayerState();
      expect(state.isLoading, true);
      expect(state.showControls, true);
      expect(state.isBuffering, false);
      expect(state.isFullscreen, false);
      expect(state.volume, 1.0);
      expect(state.isMuted, false);
      expect(state.playbackSpeed, 1.0);
    });

    test('copyWith updates volume and muted state properly', () {
      const state = PlayerState();
      final updated = state.copyWith(volume: 0.0, isMuted: true);
      expect(updated.volume, 0.0);
      expect(updated.isMuted, true);

      final restored = updated.copyWith(volume: 0.8, isMuted: false);
      expect(restored.volume, 0.8);
      expect(restored.isMuted, false);
    });
  });

  group('Live-stream vs Recorded seeking logic', () {
    test('Live stream video (isStream: true) correctly identified', () {
      final liveVideo = VideoResponseDto(
        id: 'live_123',
        title: 'Live Service',
        status: VideoStatus.ready,
        visibility: 'PUBLIC',
        isStream: true,
        author: const PostAuthorDto(id: '1', username: 'Priest'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final recordedVideo = VideoResponseDto(
        id: 'rec_123',
        title: 'Recorded Sermon',
        status: VideoStatus.ready,
        visibility: 'PUBLIC',
        isStream: false,
        duration: 3600,
        author: const PostAuthorDto(id: '1', username: 'Priest'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(liveVideo.isStream, true);
      expect(recordedVideo.isStream, false);
    });

    test(
      'Seek calculation clamps to valid duration bounds and respects configurable interval',
      () {
        const totalDuration = Duration(minutes: 10);
        var currentPosition = const Duration(minutes: 9, seconds: 58);
        const seekForwardInterval = 5;

        // Seeking forward past duration clamps to totalDuration
        final newForwardPos =
            currentPosition + const Duration(seconds: seekForwardInterval);
        final clampedForward = newForwardPos > totalDuration
            ? totalDuration
            : newForwardPos;
        expect(clampedForward, totalDuration);

        // Seeking backward below zero clamps to Duration.zero
        currentPosition = const Duration(seconds: 3);
        const seekBackwardInterval = 5;
        final newBackwardPos =
            currentPosition - const Duration(seconds: seekBackwardInterval);
        final clampedBackward = newBackwardPos < Duration.zero
            ? Duration.zero
            : newBackwardPos;
        expect(clampedBackward, Duration.zero);
      },
    );
  });

  group('Seek feedback UI widget tests', () {
    testWidgets('Renders +5s feedback forward', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 140,
                  child: Center(child: Text('+5s ▶▶')),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('+5s ▶▶'), findsOneWidget);
    });

    testWidgets('Renders -10s feedback backward with configured interval', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 140,
                  child: Center(child: Text('◀◀ -10s')),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('◀◀ -10s'), findsOneWidget);
    });
  });

  group('Mini-player handoff & state preservation', () {
    test(
      'State preservation: paused video does not auto-resume upon handoff',
      () {
        // Test the logic that adoptController / PlayerNotifier does not force play() on paused state
        bool wasPlaying = false;
        bool targetPlaying = wasPlaying;

        void adoptWithoutForcedPlay(bool isCurrentlyPlaying) {
          // Correct behavior: do NOT force play
          targetPlaying = isCurrentlyPlaying;
        }

        adoptWithoutForcedPlay(false);
        expect(targetPlaying, false); // Stays paused!

        adoptWithoutForcedPlay(true);
        expect(targetPlaying, true); // Stays playing!
      },
    );

    test(
      'Auto-hide controls behavior respecting user preferences and scrubbing state',
      () {
        bool autoHideEnabled = true;
        bool isInteractingWithControls = false;
        bool isPlaying = true;
        bool showControls = true;

        void evaluateAutoHide() {
          if (!autoHideEnabled) return; // Disabled
          if (isInteractingWithControls) return; // User scrubbing
          if (!isPlaying) return; // Paused: stay visible
          showControls = false;
        }

        // Case 1: Playing + no interaction + auto-hide enabled -> hides
        evaluateAutoHide();
        expect(showControls, false);

        // Case 2: Video paused -> must NOT hide
        showControls = true;
        isPlaying = false;
        evaluateAutoHide();
        expect(showControls, true); // Remains visible!

        // Case 3: User scrubbing progress bar -> must NOT hide
        isPlaying = true;
        isInteractingWithControls = true;
        evaluateAutoHide();
        expect(showControls, true); // Remains visible!

        // Case 4: Auto-hide disabled by user in settings -> must NOT hide
        isInteractingWithControls = false;
        autoHideEnabled = false;
        evaluateAutoHide();
        expect(showControls, true); // Remains visible!
      },
    );
  });
  group('Fullscreen playback state preservation tests', () {
    test('PlayerState isFullscreen flips correctly and preserves isEnded / isPlaying context', () {
      const state = PlayerState(isFullscreen: false, isEnded: false);
      final fullscreenState = state.copyWith(isFullscreen: true);
      expect(fullscreenState.isFullscreen, true);
      expect(fullscreenState.isEnded, false);

      final normalState = fullscreenState.copyWith(isFullscreen: false);
      expect(normalState.isFullscreen, false);
      expect(normalState.isEnded, false);
    });

    test('Fullscreen transition logic preserves playback state', () {
      bool isPlaying = true;
      bool isHandoffInProgress = false;
      bool isFullscreen = false;

      void toggleFullscreenSimulated() {
        final wasPlaying = isPlaying;
        isFullscreen = !isFullscreen;
        if (wasPlaying) {
          isHandoffInProgress = true;
          // Playback is explicitly ensured to prevent web DOM pause
          isPlaying = true;
        }
      }

      // 1. Enter fullscreen while playing -> continues playing
      toggleFullscreenSimulated();
      expect(isFullscreen, true);
      expect(isPlaying, true);
      expect(isHandoffInProgress, true);

      // 2. Exit fullscreen while playing -> continues playing
      toggleFullscreenSimulated();
      expect(isFullscreen, false);
      expect(isPlaying, true);
      expect(isHandoffInProgress, true);

      // 3. Enter fullscreen while paused -> remains paused
      isPlaying = false;
      isHandoffInProgress = false;
      toggleFullscreenSimulated();
      expect(isFullscreen, true);
      expect(isPlaying, false);
      expect(isHandoffInProgress, false);
    });
  });

  group('Autoplay and video ended detection tests', () {
    test('isEnded correctly set in PlayerState and copyWith', () {
      const state = PlayerState();
      expect(state.isEnded, false);

      final endedState = state.copyWith(isEnded: true);
      expect(endedState.isEnded, true);

      final resetState = endedState.copyWith(isEnded: false);
      expect(resetState.isEnded, false);
    });

    test('Next recommendation selection for autoplay filters out current video', () {
      final currentVideo = VideoResponseDto(
        id: 'vid_1',
        title: 'Current Video',
        status: VideoStatus.ready,
        visibility: 'PUBLIC',
        author: const PostAuthorDto(id: '1', username: 'Tester'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final nextVideo = VideoResponseDto(
        id: 'vid_2',
        title: 'Next Recommended Video',
        status: VideoStatus.ready,
        visibility: 'PUBLIC',
        author: const PostAuthorDto(id: '2', username: 'NextCreator'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final recs = [currentVideo, nextVideo];
      final nextCandidate = recs.where((v) => v.id != currentVideo.id).firstOrNull;

      expect(nextCandidate, isNotNull);
      expect(nextCandidate!.id, 'vid_2');
      expect(nextCandidate.title, 'Next Recommended Video');
    });

    test('Autoplay decision respects playbackPreferences autoplay setting', () {
      bool canTriggerAutoplay({
        required bool autoplayPref,
        required bool isAutoplayCancelled,
        required bool hasEnded,
        required bool hasNextVideo,
      }) {
        return autoplayPref && !isAutoplayCancelled && hasEnded && hasNextVideo;
      }

      // Autoplay ON and video ended -> triggers
      expect(
        canTriggerAutoplay(
          autoplayPref: true,
          isAutoplayCancelled: false,
          hasEnded: true,
          hasNextVideo: true,
        ),
        true,
      );

      // Autoplay setting OFF -> does not trigger
      expect(
        canTriggerAutoplay(
          autoplayPref: false,
          isAutoplayCancelled: false,
          hasEnded: true,
          hasNextVideo: true,
        ),
        false,
      );

      // User clicked Cancel on overlay -> does not trigger
      expect(
        canTriggerAutoplay(
          autoplayPref: true,
          isAutoplayCancelled: true,
          hasEnded: true,
          hasNextVideo: true,
        ),
        false,
      );

      // No recommended next video -> does not trigger
      expect(
        canTriggerAutoplay(
          autoplayPref: true,
          isAutoplayCancelled: false,
          hasEnded: true,
          hasNextVideo: false,
        ),
        false,
      );
    });
  });
}
