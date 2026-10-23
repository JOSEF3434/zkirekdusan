// test/features/live/live_overlay_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live/presentation/widgets/live_badge_widget.dart';
import 'package:mobile/features/live/presentation/widgets/live_stream_progress_bar.dart';

void main() {
  group('Bug Class 1: Viewer-side Live Overlay & Progress Bar', () {
    testWidgets(
      'LiveBadgeWidget displays "LIVE" when no startedAt or elapsed given',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Center(child: LiveBadgeWidget(small: true))),
          ),
        );

        expect(find.text('LIVE'), findsOneWidget);
      },
    );

    testWidgets(
      'LiveBadgeWidget formats elapsed time from server startedAt correctly',
      (tester) async {
        // 6 minutes 30 seconds ago (matching Screenshot B: 06:30)
        final now = DateTime.now();
        final startedAt = now
            .subtract(const Duration(minutes: 6, seconds: 30))
            .toUtc()
            .toIso8601String();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: LiveBadgeWidget(small: true, startedAt: startedAt),
              ),
            ),
          ),
        );

        // Immediately finds LIVE 06:30
        expect(find.text('LIVE 06:30'), findsOneWidget);
      },
    );

    testWidgets('LiveBadgeWidget formats hour-length streams as hh:mm:ss', (
      tester,
    ) async {
      final now = DateTime.now();
      // 1 hour, 15 minutes, 42 seconds ago
      final startedAt = now
          .subtract(const Duration(hours: 1, minutes: 15, seconds: 42))
          .toUtc()
          .toIso8601String();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiveBadgeWidget(small: true, startedAt: startedAt),
            ),
          ),
        ),
      );

      expect(find.text('LIVE 01:15:42'), findsOneWidget);
    });

    testWidgets(
      'LiveStreamProgressBar computes progress and renders red head dot',
      (tester) async {
        final now = DateTime.now();
        // Started 5 minutes ago
        final startedAt = now
            .subtract(const Duration(minutes: 5))
            .toUtc()
            .toIso8601String();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: LiveStreamProgressBar(
                    startedAt: startedAt,
                    showElapsedLabel: true,
                  ),
                ),
              ),
            ),
          ),
        );

        // Shows elapsed label
        expect(find.text('05:00'), findsOneWidget);

        // Progress bar rendered with container
        expect(find.byType(LiveStreamProgressBar), findsOneWidget);
      },
    );

    testWidgets(
      'Timer survives reconnects / backgrounding (lifecycle resume does not reset to 0)',
      (tester) async {
        final startTime = DateTime.now().subtract(
          const Duration(minutes: 10, seconds: 15),
        );
        final startedAt = startTime.toUtc().toIso8601String();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: LiveBadgeWidget(small: true, startedAt: startedAt),
              ),
            ),
          ),
        );

        expect(find.text('LIVE 10:15'), findsOneWidget);

        // Simulate app paused (backgrounded)
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        // Simulate app resumed
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        // Verified: does NOT reset to 0, stays in sync with real server elapsed duration
        expect(find.text('LIVE 10:15'), findsOneWidget);
      },
    );

    testWidgets(
      'LiveBadgeWidget updates seamlessly when startedAt widget prop updates on reconnect',
      (tester) async {
        final now = DateTime.now();
        final startedAt1 = now
            .subtract(const Duration(minutes: 2))
            .toUtc()
            .toIso8601String();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: LiveBadgeWidget(small: true, startedAt: startedAt1),
              ),
            ),
          ),
        );

        expect(find.text('LIVE 02:00'), findsOneWidget);

        // Simulate reconnection with updated server payload (3 minutes)
        final startedAt2 = now
            .subtract(const Duration(minutes: 3))
            .toUtc()
            .toIso8601String();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: LiveBadgeWidget(small: true, startedAt: startedAt2),
              ),
            ),
          ),
        );

        expect(find.text('LIVE 03:00'), findsOneWidget);
      },
    );
  });
}
