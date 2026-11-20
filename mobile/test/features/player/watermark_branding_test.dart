// test/features/player/watermark_branding_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/watermark_service.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildWatermarkTestHarness({
    required Widget child,
    Size size = const Size(800, 600),
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Watermark Duration-Based Positioning and Progress Tests', () {
    const totalDuration = Duration(minutes: 10); // 600 seconds

    testWidgets('At 10% playback: watermark appears at the bottom', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 1), // 10%
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alignWidget = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(alignWidget.alignment, Alignment.bottomLeft);
    });

    testWidgets('At 30% playback: watermark remains at the bottom', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 3), // 30%
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alignWidget = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(alignWidget.alignment, Alignment.bottomLeft);
    });

    testWidgets('At 49% playback: watermark remains at the bottom', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(seconds: 294), // 49%
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alignWidget = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(alignWidget.alignment, Alignment.bottomLeft);
    });

    testWidgets('At 50% playback: watermark smoothly transitions to the top', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 5), // 50.0%
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alignWidget = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(alignWidget.alignment, Alignment.topLeft);
      expect(alignWidget.duration, const Duration(milliseconds: 700));
      expect(alignWidget.curve, Curves.easeInOutCubic);
    });

    testWidgets('At 70% playback: watermark remains at the top', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 7), // 70%
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alignWidget = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(alignWidget.alignment, Alignment.topLeft);
    });

    testWidgets('At 90% playback: watermark remains at the top', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 9), // 90%
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alignWidget = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(alignWidget.alignment, Alignment.topLeft);
    });

    testWidgets('Seeking backward (70% -> 20%) smoothly returns watermark to bottom', (tester) async {
      // Start at 70%
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 7), // 70%
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.topLeft);

      // Seek backward to 20%
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 2), // 20%
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.bottomLeft);
    });

    testWidgets('Seeking forward (20% -> 80%) smoothly transitions watermark to top', (tester) async {
      // Start at 20%
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 2), // 20%
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.bottomLeft);

      // Seek forward to 80%
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 8), // 80%
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.topLeft);
    });

    testWidgets('Replaying / looping (100% -> 0%) restores watermark to bottom', (tester) async {
      // Video at completion (100%)
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: totalDuration,
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.topLeft);

      // Video loops back to beginning (0%)
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration.zero,
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.bottomLeft);
    });

    testWidgets('Pausing and resuming maintains consistent position without animation jumps', (tester) async {
      // Playing at 25%
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 2, seconds: 30),
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.bottomLeft);

      // Paused at same position
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: totalDuration,
            position: Duration(minutes: 2, seconds: 30),
            publisherUsername: 'test_user',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.bottomLeft);
    });
  });

  group('Live Stream and Unknown Duration Tests', () {
    testWidgets('Live stream with isLive: true stays at bottom', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            isLive: true,
            duration: Duration(hours: 2),
            position: Duration(hours: 1, minutes: 30), // Even if 75%, live streams stay at bottom
            publisherUsername: 'live_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.bottomLeft);
    });

    testWidgets('Live stream video (video.isStream: true) stays at bottom', (tester) async {
      final liveVideo = VideoResponseDto(
        id: 'stream_1',
        title: 'Live Liturgy',
        status: VideoStatus.ready,
        visibility: 'PUBLIC',
        isStream: true,
        author: const PostAuthorDto(id: 'u1', username: 'deacon_solomon', displayName: 'Deacon Solomon'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: TikTokWatermarkOverlay(
            video: liveVideo,
            duration: const Duration(hours: 3),
            position: const Duration(hours: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.bottomLeft);
    });

    testWidgets('Media with unknown duration (Duration.zero) defaults safely to bottom', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            duration: Duration.zero,
            position: Duration.zero,
            publisherUsername: 'user_x',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment, Alignment.bottomLeft);
    });
  });

  group('Layout and Dynamic Publisher Identity Tests', () {
    testWidgets('Single horizontal layout: logo on left, publisher on right, vertically center-aligned', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            publisherName: 'Debre Tsion St. Mary',
            publisherIdentity: '@debre_tsion',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Row exists with center vertical alignment
      final rowFinder = find.byWidgetPredicate(
        (w) => w is Row && w.crossAxisAlignment == CrossAxisAlignment.center,
      );
      expect(rowFinder, findsOneWidget);

      final row = tester.widget<Row>(rowFinder);
      expect(row.children.length, 3); // Logo Container, SizedBox spacing, Flexible text Column

      // Verify Logo Container has circle shape and 36x36 dimensions
      final logoContainer = row.children[0] as Container;
      expect(logoContainer.constraints?.maxWidth, 36);
      expect(logoContainer.constraints?.maxHeight, 36);
      final decoration = logoContainer.decoration as BoxDecoration?;
      expect(decoration?.shape, BoxShape.circle);

      // Verify text Column
      expect(find.text('Debre Tsion St. Mary'), findsOneWidget);
      expect(find.text('@debre_tsion'), findsOneWidget);
    });

    testWidgets('Channel publisher: displays channel name and channel identity handle', (tester) async {
      final channelVideo = VideoResponseDto(
        id: 'v_chan',
        title: 'Spiritual Teachings',
        status: VideoStatus.ready,
        visibility: 'PUBLIC',
        channelName: 'Mahbere Kidusan Media',
        channelHandle: '@mk_media',
        author: const PostAuthorDto(id: 'u1', username: 'uploader1', displayName: 'Uploader'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: TikTokWatermarkOverlay(
            video: channelVideo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mahbere Kidusan Media'), findsOneWidget);
      expect(find.text('@mk_media'), findsOneWidget);
    });

    testWidgets('Group publisher: displays group name and group identity slug', (tester) async {
      final groupVideo = VideoResponseDto(
        id: 'v_grp',
        title: 'Choir Service',
        status: VideoStatus.ready,
        visibility: 'PUBLIC',
        groupName: 'Debre Amin Youth Group',
        groupSlug: 'debre_amin_youth',
        author: const PostAuthorDto(id: 'u2', username: 'choir_leader', displayName: 'Choir Leader'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: TikTokWatermarkOverlay(
            video: groupVideo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Debre Amin Youth Group'), findsOneWidget);
      expect(find.text('@debre_amin_youth'), findsOneWidget);
    });

    testWidgets('Regular user: displays profile display name and username', (tester) async {
      final userVideo = VideoResponseDto(
        id: 'v_usr',
        title: 'Personal Reflection',
        status: VideoStatus.ready,
        visibility: 'PUBLIC',
        author: const PostAuthorDto(id: 'u3', username: 'yared_solomon', displayName: 'Yared Solomon'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: TikTokWatermarkOverlay(
            video: userVideo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yared Solomon'), findsOneWidget);
      expect(find.text('@yared_solomon'), findsOneWidget);
    });

    testWidgets('Handles long publisher names without overflow or distortion', (tester) async {
      const veryLongName = 'Very Long Official Ethiopian Orthodox Tewahedo Church Media Network Channel';
      const veryLongHandle = '@very_long_official_eotc_media_network_handle_2026';

      await tester.pumpWidget(
        buildWatermarkTestHarness(
          size: const Size(360, 640), // Standard phone portrait width
          child: const TikTokWatermarkOverlay(
            publisherName: veryLongName,
            publisherIdentity: veryLongHandle,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow exception
      expect(tester.takeException(), isNull);
      expect(find.text(veryLongName), findsOneWidget);
      expect(find.text(veryLongHandle), findsOneWidget);

      // Verify text widgets have ellipsis overflow
      final primaryText = tester.widget<Text>(find.text(veryLongName));
      expect(primaryText.overflow, TextOverflow.ellipsis);
      expect(primaryText.maxLines, 1);

      final secondaryText = tester.widget<Text>(find.text(veryLongHandle));
      expect(secondaryText.overflow, TextOverflow.ellipsis);
      expect(secondaryText.maxLines, 1);
    });

    testWidgets('Controls visibility: opacity fades out when isVisible is false', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            publisherUsername: 'user_opacity',
            isVisible: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final opacityWidget = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(opacityWidget.opacity, 0.0);
    });

    testWidgets('Controls visibility: opacity is 1.0 when isVisible is true', (tester) async {
      await tester.pumpWidget(
        buildWatermarkTestHarness(
          child: const TikTokWatermarkOverlay(
            publisherUsername: 'user_opacity',
            isVisible: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final opacityWidget = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(opacityWidget.opacity, 1.0);
    });
  });

  group('Aspect Ratio and Responsive Video Frame Positioning', () {
    const totalDuration = Duration(minutes: 4);

    for (final ratio in [16 / 9, 9 / 16, 1.0, 21 / 9]) {
      testWidgets('Watermark renders correctly inside aspect ratio $ratio', (tester) async {
        await tester.pumpWidget(
          buildWatermarkTestHarness(
            size: const Size(600, 600),
            child: Center(
              child: AspectRatio(
                aspectRatio: ratio,
                child: const TikTokWatermarkOverlay(
                  duration: totalDuration,
                  position: Duration(minutes: 1), // 25% -> bottom
                  publisherName: 'Aspect Channel',
                  publisherIdentity: '@aspect_channel',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final alignWidget = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
        expect(alignWidget.alignment, Alignment.bottomLeft);
      });
    }
  });
}
