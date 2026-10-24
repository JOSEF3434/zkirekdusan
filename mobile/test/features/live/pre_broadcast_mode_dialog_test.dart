// test/features/live/pre_broadcast_mode_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live/domain/camera_source.dart';
import 'package:mobile/features/live/presentation/widgets/pre_broadcast_mode_dialog.dart';

void main() {
  group('PreBroadcastModeDialog Widget Tests', () {
    testWidgets('renders dialog with BuiltInCameraSource and options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PreBroadcastModeDialog.show(
                  context,
                  cameraSource: const BuiltInCameraSource(),
                  initialRecordLocally: false,
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Go Live Confirmation'), findsOneWidget);
      expect(find.text('Source: Device Camera'), findsOneWidget);
      expect(find.text('Live Stream Only'), findsOneWidget);
      expect(find.text('Stream & Record Audio Locally'), findsOneWidget);
      expect(find.text('Go Live Now'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('displays external encoder credentials when external encoder source is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PreBroadcastModeDialog.show(
                  context,
                  cameraSource: const ExternalEncoderSource(encoderName: 'ATEM Mini Pro'),
                  initialRecordLocally: false,
                  rtmpServerUrl: 'rtmp://ingest.zikrekidusan.org/live',
                  streamKey: 'live_test_stream_key_12345',
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Source: Hardware / Software Encoder'), findsOneWidget);
      expect(find.text('External Encoder Ingest'), findsOneWidget);
      expect(find.textContaining('rtmp://ingest.zikrekidusan.org/live'), findsOneWidget);
    });

    testWidgets('selecting Stream & Record Audio Locally returns streamAndRecordLocally mode', (
      tester,
    ) async {
      BroadcastRecordingMode? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await PreBroadcastModeDialog.show(
                    context,
                    cameraSource: const BuiltInCameraSource(),
                    initialRecordLocally: false,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap on the Stream & Record Audio Locally option
      await tester.tap(find.text('Stream & Record Audio Locally'));
      await tester.pumpAndSettle();

      // Tap Go Live Now
      await tester.tap(find.text('Go Live Now'));
      await tester.pumpAndSettle();

      expect(result, BroadcastRecordingMode.streamAndRecordLocally);
    });
  });
}
