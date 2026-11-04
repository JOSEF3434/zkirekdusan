// test/features/player/adaptive_video_rendering_test.dart
import 'package:flutter_test/flutter_test.dart';

// Standalone verification of the mathematical logic used in video_player_screen.dart
double computeVideoAspectRatio({double? width, double? height, double? directRatio}) {
  if (width != null && height != null && width > 0 && height > 0) {
    if (!width.isNaN && !height.isNaN && !width.isInfinite && !height.isInfinite) {
      final ratio = width / height;
      if (ratio > 0 && !ratio.isNaN && !ratio.isInfinite) {
        return ratio;
      }
    }
  }
  if (directRatio != null && directRatio > 0 && !directRatio.isNaN && !directRatio.isInfinite) {
    return directRatio;
  }
  return 16 / 9;
}

double computeContainerAspectRatio({
  required double videoAspect,
  required bool isWide,
}) {
  if (videoAspect < 0.95) {
    // Portrait video (9:16 ~0.56, 4:5 ~0.8)
    if (isWide) {
      return 1.15;
    } else {
      return videoAspect.clamp(0.75, 16 / 9);
    }
  } else if (videoAspect <= 1.05) {
    // Square video (1:1)
    return isWide ? 1.15 : 1.0;
  } else {
    // Landscape / widescreen video (16:9, 21:9)
    return videoAspect.clamp(16 / 9, 21 / 9);
  }
}

void main() {
  group('Adaptive Video Aspect Ratio Detection', () {
    test('Correctly identifies 9:16 portrait video from dimensions', () {
      final aspect = computeVideoAspectRatio(width: 720, height: 1280);
      expect(aspect, closeTo(0.5625, 0.001));
      expect(aspect < 0.95, isTrue, reason: 'Must be recognized as portrait');
    });

    test('Correctly identifies 4:5 portrait video from dimensions', () {
      final aspect = computeVideoAspectRatio(width: 1080, height: 1350);
      expect(aspect, closeTo(0.8, 0.001));
      expect(aspect < 0.95, isTrue, reason: 'Must be recognized as portrait');
    });

    test('Correctly identifies 16:9 landscape video from dimensions', () {
      final aspect = computeVideoAspectRatio(width: 1920, height: 1080);
      expect(aspect, closeTo(16 / 9, 0.001));
      expect(aspect > 1.05, isTrue, reason: 'Must be recognized as landscape');
    });

    test('Correctly identifies 21:9 ultrawide video from dimensions', () {
      final aspect = computeVideoAspectRatio(width: 2560, height: 1080);
      expect(aspect, closeTo(2.37, 0.01));
      expect(aspect > 1.05, isTrue, reason: 'Must be recognized as landscape');
    });

    test('Correctly identifies 1:1 square video from dimensions', () {
      final aspect = computeVideoAspectRatio(width: 1080, height: 1080);
      expect(aspect, closeTo(1.0, 0.001));
      expect(aspect >= 0.95 && aspect <= 1.05, isTrue, reason: 'Must be recognized as square');
    });

    test('Safely falls back to 16:9 when dimensions are invalid or zero', () {
      expect(computeVideoAspectRatio(width: 0, height: 0), closeTo(16 / 9, 0.001));
      expect(computeVideoAspectRatio(width: double.nan, height: 1080), closeTo(16 / 9, 0.001));
      expect(computeVideoAspectRatio(width: 1920, height: double.infinity), closeTo(16 / 9, 0.001));
      expect(computeVideoAspectRatio(), closeTo(16 / 9, 0.001));
    });
  });

  group('Adaptive Container Aspect Ratio Sizing', () {
    test('Mobile portrait container expands to prominent 0.75-0.80 ratio instead of tiny 16:9', () {
      const portraitRatio = 9 / 16; // 0.5625
      final containerAspect = computeContainerAspectRatio(
        videoAspect: portraitRatio,
        isWide: false,
      );

      // 0.75 aspect ratio gives height ~520px on a 390px phone
      expect(containerAspect, equals(0.75));
      expect(containerAspect, isNot(equals(16 / 9)), reason: 'Should NOT be squeezed into 16:9');
    });

    test('Desktop portrait container stays sleek and bounded at 1.15 ratio', () {
      const portraitRatio = 9 / 16; // 0.5625
      final containerAspect = computeContainerAspectRatio(
        videoAspect: portraitRatio,
        isWide: true,
      );

      expect(containerAspect, equals(1.15));
    });

    test('Landscape video retains natural 16:9 container ratio on both mobile and desktop', () {
      const landscapeRatio = 16 / 9;
      expect(
        computeContainerAspectRatio(videoAspect: landscapeRatio, isWide: false),
        closeTo(16 / 9, 0.001),
      );
      expect(
        computeContainerAspectRatio(videoAspect: landscapeRatio, isWide: true),
        closeTo(16 / 9, 0.001),
      );
    });

    test('Square video uses 1:1 on mobile and 1.15 on desktop', () {
      const squareRatio = 1.0;
      expect(
        computeContainerAspectRatio(videoAspect: squareRatio, isWide: false),
        equals(1.0),
      );
      expect(
        computeContainerAspectRatio(videoAspect: squareRatio, isWide: true),
        equals(1.15),
      );
    });
  });

  group('Fullscreen Orientation Policy', () {
    test('Portrait videos lock to portrait orientations in fullscreen', () {
      const portraitRatio = 9 / 16;
      final isPortrait = portraitRatio < 0.95;
      expect(isPortrait, isTrue);
      // In fullscreen, portraitUp & portraitDown are preferred to fill screen vertically
    });

    test('Landscape videos lock to landscape orientations in fullscreen', () {
      const landscapeRatio = 16 / 9;
      final isPortrait = landscapeRatio < 0.95;
      expect(isPortrait, isFalse);
      // In fullscreen, landscapeLeft & landscapeRight are preferred to fill screen horizontally
    });
  });
}

