// test/features/splash/splash_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/splash/presentation/providers/splash_provider.dart';
import 'package:mobile/features/splash/presentation/splash_screen.dart';

void main() {
  group('SplashScreen Tests', () {
    testWidgets(
      'SplashScreen renders logo, app title, dynamic Amharic quote, and loading bar',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

        // Advance animation to complete entrance sequence and loading
        await tester.pump(const Duration(milliseconds: 2500));

        // Verify app title is displayed
        expect(find.text('ዝክረ ክዱሳን'), findsOneWidget);

        // Verify Amharic quote is rendered
        expect(find.text('✝️ፍቅር ያጌብረኒ ከመ እንግር ዜናሆሙ ለቅዱሳን!🌿'), findsOneWidget);

        // Verify author attribution is rendered
        expect(find.text('አባ ጊዮርጊስ ዘጋስጫ (መጽሐፈ ምሥጢር)'), findsOneWidget);

        // Verify loading text indicator is rendered
        expect(find.text('በመጫን ላይ...'), findsOneWidget);

        // Verify CircularProgressIndicator is present
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    test('SplashNotifier updates state to true after duration', () async {
      final container = ProviderContainer(
        overrides: [
          splashLoadingDurationProvider.overrideWithValue(
            const Duration(milliseconds: 100),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(splashCompletedProvider), false);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(container.read(splashCompletedProvider), true);
    });

    test('SplashNotifier completeImmediately sets state to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(splashCompletedProvider.notifier);
      expect(container.read(splashCompletedProvider), false);

      notifier.completeImmediately();
      expect(container.read(splashCompletedProvider), true);
    });

    const screenSizes = [
      Size(320, 480), // Compact screen
      Size(375, 812), // Standard phone
      Size(414, 896), // Large phone
      Size(800, 1280), // Tablet
    ];

    for (final size in screenSizes) {
      testWidgets(
        'SplashScreen renders without overflow on size ${size.width}x${size.height}',
        (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

          await tester.pump(const Duration(milliseconds: 2500));

          expect(tester.takeException(), isNull);
          expect(find.byType(SplashScreen), findsOneWidget);
        },
      );
    }
  });
}
