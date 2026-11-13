import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/live/domain/camera_source.dart';
import 'package:mobile/features/live/presentation/providers/live_discovery_provider.dart';
import 'package:mobile/features/live/presentation/screens/live_discovery_screen.dart';
import 'package:mobile/features/live/presentation/screens/local_recordings_screen.dart';
import 'package:mobile/features/live/presentation/widgets/live_network_diagnostics_widget.dart';
import 'package:mobile/features/live/presentation/widgets/live_side_rail.dart';

class FakeLiveDiscoveryNotifier extends StateNotifier<LiveDiscoveryState>
    implements LiveStreamsNotifier, ScheduledStreamsNotifier, MyScheduledStreamsNotifier {
  FakeLiveDiscoveryNotifier() : super(const LiveDiscoveryState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockConnectivityNotifier extends StateNotifier<ConnectivityState>
    implements ConnectivityNotifier {
  MockConnectivityNotifier()
      : super(
          const ConnectivityState(
            status: ConnectivityStatus.online,
            connectionType: NetworkConnectionType.wifi,
            isInitialized: true,
            isReachable: true,
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Live streaming UI overflow fixes & recordings navigation tests', () {
    testWidgets('LiveSideRail renders cleanly in short landscape constraints (360px height) without overflow', (tester) async {
      // Simulate short landscape phone screen: width 800, height 360
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 64,
              height: 360,
              child: LiveSideRail(activeItem: LiveRailItem.studio),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow exceptions occurred
      expect(tester.takeException(), isNull);

      // Verify the Recordings icon (Icons.folder_special_outlined) is rendered in the rail
      expect(find.byIcon(Icons.folder_special_outlined), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sensors_rounded), findsOneWidget);
      expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
    });

    testWidgets('LiveSideRail expanded mode (width 184) renders without overflow on 360px height', (tester) async {
      tester.view.physicalSize = const Size(1000, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 184,
              height: 360,
              child: LiveSideRail(activeItem: LiveRailItem.live),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Recordings'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Studio'), findsOneWidget);
    });

    testWidgets('LiveNetworkDiagnosticsWidget does not overflow horizontally in narrow 280px container', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((ref) => MockConnectivityNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280,
                  child: LiveNetworkDiagnosticsWidget(
                    cameraSource: BuiltInCameraSource(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Wi-Fi Network Active (Optimal)'), findsOneWidget);
      expect(find.text('Latency: Low'), findsOneWidget);
    });

    testWidgets('LocalRecordingsScreen renders recordings list and play controls cleanly', (tester) async {
      final sampleRecordings = <LocalLiveRecordingData>[
        LocalLiveRecordingData(
          id: 'rec-1',
          streamId: 'stream-1',
          streamTitle: 'Morning Broadcast',
          mimeType: 'audio/mp4',
          recordingType: 'audio',
          status: 'complete',
          durationSeconds: 160,
          fileSizeBytes: 2500000,
          uploadProgress: 0.0,
          uploadAttempts: 0,
          startedAt: DateTime(2026, 11, 12, 15, 35),
          updatedAt: DateTime(2026, 11, 12, 15, 38),
          localFilePath: null, // null avoids attempting real disk I/O in widget test
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localRecordingsStreamProvider.overrideWith(
              (ref) => Stream.value(sampleRecordings),
            ),
          ],
          child: const MaterialApp(
            home: LocalRecordingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Local Recordings'), findsOneWidget);
      expect(find.text('Morning Broadcast'), findsOneWidget);
      expect(find.text('Audio Recording (microphone only)'), findsOneWidget);
      expect(find.text('02:40'), findsOneWidget);
      expect(find.text('2.4 MB'), findsOneWidget);
    });

    testWidgets('LiveDiscoveryScreen has back arrow icon with tooltip Back in AppBar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trProvider.overrideWithValue((key, [args]) => key),
            liveStreamsProvider.overrideWith((ref) => FakeLiveDiscoveryNotifier()),
            scheduledStreamsProvider.overrideWith((ref) => FakeLiveDiscoveryNotifier()),
            myScheduledStreamsProvider.overrideWith((ref) => FakeLiveDiscoveryNotifier()),
          ],
          child: const MaterialApp(
            home: LiveDiscoveryScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(tester.takeException(), isNull);
      // Verify back arrow icon is present in leading position of AppBar
      final backButton = find.widgetWithIcon(IconButton, Icons.arrow_back);
      expect(backButton, findsOneWidget);

      final iconButtonWidget = tester.widget<IconButton>(backButton);
      expect(iconButtonWidget.tooltip, 'Back');
    });
  });
}
