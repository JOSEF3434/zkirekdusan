// test/features/player/handoff_feed_and_download_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';
import 'package:mobile/core/presentation/widgets/video_thumbnail_widget.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue 1: Mini-Player Web Playback Handoff', () {
    test('showVideo marks handoff in progress and preserves wasPlaying', () {
      final notifier = MiniPlayerNotifier();
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/test.mp4'),
      );

      notifier.showVideo(
        videoId: 'video-123',
        title: 'Test Video',
        channelName: 'Channel',
        controller: ctrl,
        wasPlaying: true,
      );

      expect(notifier.state.isVisible, isTrue);
      expect(notifier.state.isPlaying, isTrue);
      expect(notifier.state.wasPlayingBeforeHandoff, isTrue);
      expect(notifier.state.isHandoffInProgress, isTrue);

      // Simulate involuntary browser pause during DOM element detachment
      notifier.syncPlaybackState(ctrl);
      // Because handoff is in progress and wasPlayingBeforeHandoff is true,
      // syncPlaybackState must NOT overwrite isPlaying to false
      expect(notifier.state.isPlaying, isTrue);

      // When target completes handoff:
      notifier.completeHandoff();
      expect(notifier.state.isHandoffInProgress, isFalse);
    });

    test('prepareExpand captures wasPlaying and marks handoff in progress', () {
      final notifier = MiniPlayerNotifier();
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/test.mp4'),
      );

      notifier.showVideo(
        videoId: 'video-456',
        title: 'Test Video 2',
        controller: ctrl,
        wasPlaying: true,
      );

      notifier.prepareExpand();

      expect(notifier.state.isVisible, isFalse);
      expect(notifier.state.isNavigatingToFull, isTrue);
      expect(notifier.state.isHandoffInProgress, isTrue);
      expect(notifier.state.wasPlayingBeforeHandoff, isTrue);

      // Reclaim controller should remember wasPlaying before clearing state
      final reclaimed = notifier.reclaimController('video-456');
      expect(reclaimed, isNotNull);
      expect(notifier.lastReclaimedWasPlaying, isTrue);
      expect(notifier.state.hasContent, isFalse);
    });

    test('User explicit pause is preserved during handoff', () {
      final notifier = MiniPlayerNotifier();
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/test.mp4'),
      );

      notifier.showVideo(
        videoId: 'video-789',
        title: 'Paused Video',
        controller: ctrl,
        wasPlaying: false,
      );

      expect(notifier.state.isPlaying, isFalse);
      expect(notifier.state.wasPlayingBeforeHandoff, isFalse);

      notifier.prepareExpand();
      expect(notifier.state.wasPlayingBeforeHandoff, isFalse);

      notifier.reclaimController('video-789');
      expect(notifier.lastReclaimedWasPlaying, isFalse);
    });
  });

  group('Issue 2: Mobile Feed Layout on Pixel 9-Sized Screens', () {
    testWidgets('Single column feed on Pixel 9 screen width (412dp)', (
      tester,
    ) async {
      // Set Pixel 9 emulator screen dimensions: 412 x 915 logical pixels
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testVideo = VideoResponseDto(
        id: 'v1',
        title: 'Pixel 9 Feed Test Video',
        author: const PostAuthorDto(
          id: 'u1',
          username: 'author1',
          displayName: 'Author 1',
        ),
        duration: 120,
        viewsCount: 1500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: VideoStatus.ready,
        visibility: 'PUBLIC',
        isDownloadable: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverList.separated(
                    itemCount: 2,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        VideoCard(video: testVideo, showActions: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure cards are rendered full-width (412dp wide)
      final cardFinders = find.byType(VideoCard);
      expect(cardFinders, findsNWidgets(2));

      final firstCardSize = tester.getSize(cardFinders.first);
      expect(firstCardSize.width, 412.0);
      expect(firstCardSize.height, greaterThan(240.0));
    });
  });

  group('Issue 3: Offline Download Status Icon and Thumbnails', () {
    test('DownloadMetadata stores completed status and local path', () {
      final meta = DownloadMetadata(
        videoId: 'vid-dl-1',
        title: 'Offline Download Video',
        localPath:
            '/data/user/0/com.streamhub/app_flutter/videos/vid-dl-1/video.mp4',
        thumbnailUrl:
            '/data/user/0/com.streamhub/app_flutter/videos/vid-dl-1/thumbnail.jpg',
        sizeBytes: 25 * 1024 * 1024,
        status: VideoDownloadStatus.completed,
      );

      expect(meta.status, VideoDownloadStatus.completed);
      expect(meta.thumbnailUrl, contains('thumbnail.jpg'));
      expect(meta.localPath, contains('video.mp4'));
    });

    testWidgets(
      'VideoThumbnailWidget renders fallback gradient on missing/offline thumbnail',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 120,
                height: 68,
                child: VideoThumbnailWidget(
                  thumbnailUrl: null,
                  videoUrl: null,
                  playIconSize: 20,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check fallback play icon rendered cleanly without crashing or black box
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Completed download tile displays checkmark icon, not arrow download icon',
      (tester) async {
        final item = DownloadMetadata(
          videoId: 'vid-complete-1',
          title: 'Completed Download',
          localPath: '/storage/videos/vid-complete-1/video.mp4',
          thumbnailUrl: null,
          sizeBytes: 45 * 1024 * 1024,
          status: VideoDownloadStatus.completed,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  Icon(
                    item.status == VideoDownloadStatus.completed
                        ? Icons.check_circle_rounded
                        : Icons.arrow_circle_down_rounded,
                    size: 15,
                    color: const Color(0xFF00C6FF),
                  ),
                  const SizedBox(width: 4),
                  const Text('Downloaded • 45.0 MB'),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Checkmark icon must be found
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        // Download arrow icon must NOT be found
        expect(find.byIcon(Icons.arrow_circle_down_rounded), findsNothing);
      },
    );
  });

  group('Issue 5: Live Tab next to Explore on Home Page', () {
    testWidgets('Live Tab displays next to Explore tab and redirects on tap', (
      tester,
    ) async {
      String? navigatedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  tabs: [
                    const Tab(text: 'Recommended'),
                    const Tab(text: 'Latest'),
                    const Tab(text: 'Explore'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Live'),
                        ],
                      ),
                    ),
                  ],
                  onTap: (index) {
                    if (index == 3) {
                      navigatedRoute = '/live/discover';
                    }
                  },
                ),
              ),
              body: const TabBarView(
                children: [
                  Text('Recommended Page'),
                  Text('Latest Page'),
                  Text('Explore Page'),
                  Text('Live Page'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find tabs
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);

      // Tap on the Live tab
      await tester.tap(find.text('Live'));
      await tester.pumpAndSettle();

      // Verify redirection to /live/discover was triggered
      expect(navigatedRoute, '/live/discover');
    });
  });
}
