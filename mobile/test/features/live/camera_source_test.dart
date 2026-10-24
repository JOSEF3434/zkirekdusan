// test/features/live/camera_source_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live/domain/camera_source.dart';

void main() {
  group('CameraSource Domain Models & Protocol Validation', () {
    test('BuiltInCameraSource defaults and hardware requirement', () {
      const source = BuiltInCameraSource();
      expect(source.type, CameraSourceType.builtIn);
      expect(source.requiresLocalHardware, isTrue);
      expect(source.isFront, isTrue);
      expect(source.resolutionWidth, 1280);
      expect(source.resolutionHeight, 720);
      expect(source.targetFps, 30);

      final rear1080p = source.copyWith(
        isFront: false,
        resolutionWidth: 1920,
        resolutionHeight: 1080,
        targetFps: 60,
      );
      expect(rear1080p.isFront, isFalse);
      expect(rear1080p.resolutionWidth, 1920);
      expect(rear1080p.resolutionHeight, 1080);
      expect(rear1080p.targetFps, 60);
    });

    test('ExternalEncoderSource defaults and direct server push', () {
      const source = ExternalEncoderSource();
      expect(source.type, CameraSourceType.externalEncoder);
      expect(source.requiresLocalHardware, isFalse);
      expect(source.encoderName, 'OBS / ATEM Mini');
      expect(source.recommendedBitrateKbps, 3500);
      expect(source.keyframeIntervalSeconds, 2);

      final custom = source.copyWith(
        encoderName: 'Yolobox Pro',
        recommendedBitrateKbps: 5000,
        keyframeIntervalSeconds: 2,
      );
      expect(custom.encoderName, 'Yolobox Pro');
      expect(custom.recommendedBitrateKbps, 5000);
    });

    test('NetworkCameraSource RTSP URL validation and protocols', () {
      expect(NetworkCameraSource.isValidRtspUrl('rtsp://192.168.1.50:554/live/ch0'), isTrue);
      expect(NetworkCameraSource.isValidRtspUrl('rtsps://camera.lan:322/stream1'), isTrue);
      expect(NetworkCameraSource.isValidRtspUrl('rtsp://admin:pass123@10.0.0.12:554/feed'), isTrue);

      // Invalid schemes
      expect(NetworkCameraSource.isValidRtspUrl('http://192.168.1.50/stream.m3u8'), isFalse);
      expect(NetworkCameraSource.isValidRtspUrl('srt://192.168.1.50:9000'), isFalse);
      expect(NetworkCameraSource.isValidRtspUrl(''), isFalse);
      expect(NetworkCameraSource.isValidRtspUrl('not-a-url'), isFalse);

      const source = NetworkCameraSource(
        rtspUrl: 'rtsp://192.168.1.50:554/live',
        transport: RtspTransport.tcp,
        port: 554,
      );
      expect(source.requiresLocalHardware, isFalse);
      expect(source.transport, RtspTransport.tcp);

      final udpSource = source.copyWith(transport: RtspTransport.udp, port: 8554);
      expect(udpSource.transport, RtspTransport.udp);
      expect(udpSource.port, 8554);
    });

    test('SrtEncoderSource SRT URL validation and modes', () {
      expect(SrtEncoderSource.isValidSrtUrl('srt://192.168.1.100:9000?latency=200'), isTrue);
      expect(SrtEncoderSource.isValidSrtUrl('srt://broadcast.stream.org:9000'), isTrue);

      // RTSP or RTMP must not be accepted as SRT
      expect(SrtEncoderSource.isValidSrtUrl('rtsp://192.168.1.100:554'), isFalse);
      expect(SrtEncoderSource.isValidSrtUrl('rtmp://192.168.1.100:1935/live'), isFalse);

      const source = SrtEncoderSource(
        host: '192.168.1.100',
        port: 9000,
        mode: SrtMode.caller,
        latencyMs: 250,
      );
      expect(source.requiresLocalHardware, isFalse);
      expect(source.mode, SrtMode.caller);
      expect(source.latencyMs, 250);

      final listenerSource = source.copyWith(
        mode: SrtMode.listener,
        streamId: 'channel_1_hd',
      );
      expect(listenerSource.mode, SrtMode.listener);
      expect(listenerSource.streamId, 'channel_1_hd');
    });
  });
}
