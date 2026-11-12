import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live/domain/live_dvr_state.dart';
import 'package:mobile/features/live/presentation/widgets/dvr_seek_bar.dart';
import 'package:mobile/features/live/presentation/widgets/live_player_controls_overlay.dart';
import 'package:mobile/features/live/presentation/widgets/responsive_video_stage.dart';

void main() {
  group('Responsive aspect-ratio & viewport sizing calculations', () {
    test('uses full-width 16:9 controlled height across portrait 9:16, landscape 16:9, and square 1:1 on mobile & wide desktop', () {
      // Portrait 9:16 video on portrait mobile viewport uses full width with 16:9 controlled height (not tall 9:16 height)
      final mobilePortraitVideo = computeResponsiveVideoFrame(
        maxWidth: 390,
        maxHeight: 520,
        sourceVideoSize: const Size(720, 1280),
        isWideScreen: false,
        isFullscreen: false,
      );
      expect(mobilePortraitVideo.isPortraitVideo, isTrue);
      expect(mobilePortraitVideo.videoAspectRatio, closeTo(9 / 16, 0.01));
      expect(mobilePortraitVideo.stageWidth, 390);
      expect(mobilePortraitVideo.stageHeight, closeTo(390 * 9 / 16, 0.5));

      // Landscape 16:9 video on mobile occupies 100% width with 16:9 height
      final mobileLandscapeVideo = computeResponsiveVideoFrame(
        maxWidth: 390,
        maxHeight: 520,
        sourceVideoSize: const Size(1920, 1080),
        isWideScreen: false,
        isFullscreen: false,
      );
      expect(mobileLandscapeVideo.isPortraitVideo, isFalse);
      expect(mobileLandscapeVideo.stageWidth, 390);
      expect(mobileLandscapeVideo.stageHeight, closeTo(390 * 9 / 16, 0.5));

      // Portrait 9:16 video on desktop wide stage occupies 100% playerW with controlled 16:9 height (bounded by maxHeight)
      final desktopPortraitVideo = computeResponsiveVideoFrame(
        maxWidth: 920,
        maxHeight: 720,
        sourceVideoSize: const Size(1080, 1920),
        isWideScreen: true,
        isFullscreen: false,
      );
      expect(desktopPortraitVideo.isPortraitVideo, isTrue);
      expect(desktopPortraitVideo.stageWidth, 920);
      expect(desktopPortraitVideo.stageHeight, closeTo(920 * 9 / 16, 0.5));

      // Short desktop window bounds 16:9 height cleanly without overflow
      final boundedDesktop = computeResponsiveVideoFrame(
        maxWidth: 920,
        maxHeight: 400,
        sourceVideoSize: const Size(1080, 1920),
        isWideScreen: true,
        isFullscreen: false,
      );
      expect(boundedDesktop.stageWidth, 920);
      expect(boundedDesktop.stageHeight, 400);

      // Square 1:1 video keeps stage at 16:9 full width while preserving 1:1 metadata for cover crop
      final squareVideo = computeResponsiveVideoFrame(
        maxWidth: 360,
        maxHeight: 600,
        sourceVideoSize: const Size(1080, 1080),
        isWideScreen: false,
        isFullscreen: false,
      );
      expect(squareVideo.videoAspectRatio, closeTo(1.0, 0.01));
      expect(squareVideo.stageWidth, 360);
      expect(squareVideo.stageHeight, closeTo(360 * 9 / 16, 0.5));
    });
  });

  group('DVR window timeline math & JSON parsing', () {
    test('computes behindLive duration, edge status, and sliding eviction bounds', () {
      final serverTimeline = DvrTimelineSnapshot.fromJson({
        'streamId': 'st-1',
        'dvrEnabled': true,
        'active': true,
        'ended': false,
        'hasSegments': true,
        'dvrWindowSeconds': 1800,
        'retentionMinutes': 30,
        'targetDurationSec': 4,
        'dvrStartOffsetSec': 120.0,
        'liveEdgeOffsetSec': 1920.0,
        'retainedDurationSec': 1800.0,
        'segmentCount': 450,
        'masterPlaylistPath': '/api/streams/st-1/dvr/master.m3u8',
        'variants': [
          {
            'id': 0,
            'label': '720p',
            'bandwidth': 2000000,
            'width': 720,
            'height': 1280,
            'playlistPath': '/api/streams/st-1/dvr/variant/0/playlist.m3u8',
          },
        ],
      });

      expect(serverTimeline.variants.single.label, '720p');

      // Delayed viewer rewound 3 minutes behind live edge
      final delayed = computeDvrWindowMath(
        currentPosition: const Duration(minutes: 29),
        reportedDuration: const Duration(minutes: 32),
        seekableStart: const Duration(minutes: 2),
        seekableEnd: const Duration(minutes: 32),
        liveSyncPosition: const Duration(minutes: 31, seconds: 54),
        serverTimeline: serverTimeline,
      );
      expect(delayed.isAtLiveEdge, isFalse);
      expect(delayed.behindLive, const Duration(minutes: 2, seconds: 54));
      expect(delayed.formattedBehindLive, '-02:54');

      // Viewer caught up to live sync
      final atEdge = computeDvrWindowMath(
        currentPosition: const Duration(minutes: 31, seconds: 50),
        reportedDuration: const Duration(minutes: 32),
        seekableStart: const Duration(minutes: 2),
        seekableEnd: const Duration(minutes: 32),
        liveSyncPosition: const Duration(minutes: 31, seconds: 54),
      );
      expect(atEdge.isAtLiveEdge, isTrue);
    });
  });

  group('ResponsiveVideoStage, DvrSeekBar, and LivePlayerControlsOverlay UI', () {
    testWidgets('Defaults to ClipRect + FittedBox(BoxFit.cover) with no blurred backdrop; Fill & opt-in Fit behave cleanly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 450,
              child: ResponsiveVideoStage(
                sourceVideoSize: Size(720, 1280),
                child: SizedBox(key: Key('video_child')),
              ),
            ),
          ),
        ),
      );
      final fittedBox = tester.widget<FittedBox>(find.byType(FittedBox));
      expect(fittedBox.fit, BoxFit.cover);
      expect(find.byType(ClipRect), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);

      // Opt-in Fit mode keeps AspectRatio uncropped when explicitly requested
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 450,
              child: ResponsiveVideoStage(
                sourceVideoSize: Size(720, 1280),
                fitMode: VideoFitMode.fit,
                child: SizedBox(key: Key('video_child')),
              ),
            ),
          ),
        ),
      );
      final aspectWidget = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectWidget.aspectRatio, closeTo(9 / 16, 0.01));
    });

    testWidgets(
      'Overlay renders LIVE vs GO LIVE states, transport callbacks, DVR_EXPIRED banner, and fits narrow widths cleanly',
      (tester) async {
        int rewinds = 0;
        int forwards = 0;
        int playToggles = 0;
        int goLives = 0;
        int fitToggles = 0;
        int castOpens = 0;

        final behindWindow = DvrWindowMath(
          windowStart: Duration.zero,
          windowEnd: const Duration(minutes: 10),
          currentPosition: const Duration(minutes: 8),
          bufferedEnd: const Duration(minutes: 8, seconds: 20),
          behindLive: const Duration(minutes: 2),
          isAtLiveEdge: false,
          progress: 0.8,
          bufferedProgress: 0.83,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320, // Narrow phone width regression check (no RenderFlex overflow)
                height: 260,
                child: LivePlayerControlsOverlay(
                  streamTitle: 'Sunday Morning Liturgy',
                  playbackState: LivePlaybackState.paused,
                  window: behindWindow,
                  visible: true,
                  isFullscreen: false,
                  dvrEnabled: true,
                  viewerCount: 42,
                  fitMode: VideoFitMode.fit,
                  volume: 1.0,
                  isMuted: false,
                  qualities: const [
                    VideoQualityOption.auto,
                    VideoQualityOption(index: 0, label: '720p'),
                  ],
                  currentQualityIndex: -1,
                  onMinimize: () {},
                  onTogglePlayPause: () => playToggles++,
                  onRewind10: () => rewinds++,
                  onForward10: () => forwards++,
                  onSeek: (_) {},
                  onGoLive: () => goLives++,
                  onToggleFullscreen: () {},
                  onToggleFitMode: () => fitToggles++,
                  onToggleMute: () {},
                  onQualitySelected: (_) {},
                  onOpenCast: () => castOpens++,
                ),
              ),
            ),
          ),
        );

        expect(find.textContaining('PAUSED -02:00'), findsOneWidget);
        expect(find.byType(DvrSeekBar), findsOneWidget);

        await tester.tap(find.byIcon(Icons.replay_10_rounded));
        await tester.tap(find.byIcon(Icons.forward_10_rounded));
        await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
        await tester.tap(find.byIcon(Icons.crop_free_rounded));
        await tester.tap(find.byIcon(Icons.cast_rounded));
        await tester.tap(find.textContaining('PAUSED -02:00'));

        expect(rewinds, 1);
        expect(forwards, 1);
        expect(playToggles, 1);
        expect(fitToggles, 1);
        expect(castOpens, 1);
        expect(goLives, 1);

        // Verify DVR_EXPIRED recovery banner renders and invokes onGoLive
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 480,
                height: 300,
                child: LivePlayerControlsOverlay(
                  streamTitle: 'Sunday Morning Liturgy',
                  playbackState: LivePlaybackState.dvrExpired,
                  window: behindWindow,
                  visible: true,
                  isFullscreen: false,
                  dvrEnabled: true,
                  viewerCount: 42,
                  fitMode: VideoFitMode.fit,
                  volume: 1.0,
                  isMuted: false,
                  onMinimize: () {},
                  onTogglePlayPause: () {},
                  onRewind10: () {},
                  onForward10: () {},
                  onSeek: (_) {},
                  onGoLive: () => goLives++,
                  onToggleFullscreen: () {},
                  onToggleFitMode: () {},
                  onToggleMute: () {},
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Paused segment aged out of the DVR buffer.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Go Live'));
        expect(goLives, 2);
      },
    );
  });
}
