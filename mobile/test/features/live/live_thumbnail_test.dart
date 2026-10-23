// test/features/live/live_thumbnail_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/presentation/widgets/live_side_rail.dart';

void main() {
  group('Live Stream Thumbnail & Side Rail Tests', () {
    test(
      'CreateLiveStreamRequest serializes optional thumbnailUrl and thumbnailFileId',
      () {
        const reqWithThumb = CreateLiveStreamRequest(
          title: 'Morning Prayer Stream',
          description: 'Join us live',
          thumbnailUrl:
              'https://res.cloudinary.com/demo/image/upload/sample.jpg',
          thumbnailFileId: 'file-123-abc',
        );

        final json = reqWithThumb.toJson();
        expect(json['title'], 'Morning Prayer Stream');
        expect(json['description'], 'Join us live');
        expect(
          json['thumbnailUrl'],
          'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        );
        expect(json['thumbnailFileId'], 'file-123-abc');
      },
    );

    test('CreateLiveStreamRequest omits thumbnail fields when null', () {
      const reqWithoutThumb = CreateLiveStreamRequest(
        title: 'Stream without thumbnail',
      );

      final json = reqWithoutThumb.toJson();
      expect(json['title'], 'Stream without thumbnail');
      expect(json.containsKey('thumbnailUrl'), isFalse);
      expect(json.containsKey('thumbnailFileId'), isFalse);
    });

    testWidgets(
      'LiveSideRail renders at width 64 without horizontal overflow',
      (tester) async {
        // Set test screen size to a standard phone resolution (e.g. 390x844)
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  LiveSideRail(activeItem: LiveRailItem.studio),
                  Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify no overflow exception was thrown
        expect(tester.takeException(), isNull);

        // Verify the rail is present
        expect(find.byType(LiveSideRail), findsOneWidget);
      },
    );
  });
}
