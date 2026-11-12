// test/features/live/cast_service_signaling_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:mobile/features/live/data/cast_service.dart';
import 'package:mobile/features/live/data/lan_network_discovery_service.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/data/native_external_device_bridge.dart';
import 'package:mobile/features/live/domain/cast_device.dart';

class _FakeSocketService extends Mock implements LiveSocketService {
  final announceCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final offerCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final answerCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final iceCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final leftCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final recordCalls = <Map<String, dynamic>>[];

  @override
  Stream<Map<String, dynamic>> get onCastDeviceAnnounce => announceCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get onCastCameraOffer => offerCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get onCastCameraAnswer => answerCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get onCastCameraIce => iceCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get onCastDeviceLeft => leftCtrl.stream;

  @override
  void emitCastRecordCommand({
    required String streamId,
    required String peerId,
    required String action,
  }) {
    recordCalls.add({
      'streamId': streamId,
      'peerId': peerId,
      'action': action,
    });
  }

  Future<void> closeAll() async {
    await announceCtrl.close();
    await offerCtrl.close();
    await answerCtrl.close();
    await iceCtrl.close();
    await leftCtrl.close();
  }
}

class _FakeLan implements LanNetworkDiscoveryService {
  bool castCalled = false;
  bool stopCalled = false;
  String? lastControlUrl;
  String? lastMediaUrl;

  @override
  Future<List<DiscoveredDlnaDevice>> discoverDlnaRenderers({
    Duration timeout = const Duration(seconds: 3),
  }) async => const [
    DiscoveredDlnaDevice(
      udn: 'uuid:living-room-tv',
      friendlyName: 'Living Room TV',
      modelName: 'Samsung QLED',
      locationUrl: 'http://192.168.1.25:8080/desc.xml',
      avTransportControlUrl: 'http://192.168.1.25:8080/AVTransport/control',
      hostIp: '192.168.1.25',
    ),
  ];

  @override
  Future<void> castDlnaMedia({
    required String controlUrl,
    required String mediaUrl,
    required String title,
  }) async {
    castCalled = true;
    lastControlUrl = controlUrl;
    lastMediaUrl = mediaUrl;
  }

  @override
  Future<void> stopDlnaMedia({required String controlUrl}) async {
    stopCalled = true;
  }

  @override
  Future<NetworkProbeResult> probeRtspEndpoint(String rtspUrl) async =>
      const NetworkProbeResult(reachable: true, summary: 'OK');

  @override
  Future<NetworkProbeResult> probeTcpEndpoint(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async => const NetworkProbeResult(reachable: true, summary: 'OK');
}

class _NoopBridge extends NativeExternalDeviceBridge {
  @override
  Future<void> acquireMulticastLock() async {}

  @override
  Future<void> releaseMulticastLock() async {}
}

void main() {
  group('CastService Discovery, DLNA & Signaling Lifecycle', () {
    test('discovers DLNA renderer via SSDP and casts/stops using AVTransport controlUrl', () async {
      final socket = _FakeSocketService();
      final lan = _FakeLan();
      final service = CastService(
        socket,
        lanDiscovery: lan,
        bridge: _NoopBridge(),
      );

      final emissions = <List<CastDevice>>[];
      final sub = service.devicesStream.listen(emissions.add);

      await service.startDiscovery();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.currentDevices.length, 1);
      final tv = service.currentDevices.first;
      expect(tv.id, 'uuid:living-room-tv');
      expect(tv.name, 'Living Room TV');
      expect(tv.protocol, CastProtocol.dlna);

      await service.castToTv(
        device: tv,
        hlsUrl: 'https://cdn.example.com/live/master.m3u8',
        streamTitle: 'Sunday Service',
      );
      expect(lan.castCalled, isTrue);
      expect(lan.lastControlUrl, 'http://192.168.1.25:8080/AVTransport/control');
      expect(service.currentDevices.first.status, CastSessionStatus.connected);

      await service.stopTvCast(tv);
      expect(lan.stopCalled, isTrue);
      expect(service.currentDevices.first.status, CastSessionStatus.disconnected);

      await sub.cancel();
      await service.dispose();
      await socket.closeAll();
    });

    test('handles remote camera announce, leave cleanup, and record command', () async {
      final socket = _FakeSocketService();
      final service = CastService(
        socket,
        lanDiscovery: _FakeLan(),
        bridge: _NoopBridge(),
      );

      await service.startDiscovery();

      socket.announceCtrl.add({
        'peerId': 'socket-peer-1',
        'deviceName': 'Choir Balcony Camera',
        'deviceModel': 'Pixel 8',
        'signalStrength': 90,
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(service.currentDevices.any((d) => d.id == 'socket-peer-1'), isTrue);

      service.triggerRemoteCameraRecord(
        streamId: 'stream-1',
        deviceId: 'socket-peer-1',
        action: 'start',
      );
      expect(socket.recordCalls.length, 1);
      expect(socket.recordCalls.first['action'], 'start');

      socket.leftCtrl.add({'peerId': 'socket-peer-1'});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(service.currentDevices.any((d) => d.id == 'socket-peer-1'), isFalse);

      await service.dispose();
      await socket.closeAll();
    });
  });
}
