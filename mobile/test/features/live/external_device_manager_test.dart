// test/features/live/external_device_manager_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/features/live/data/cast_service.dart';
import 'package:mobile/features/live/data/external_device_manager.dart';
import 'package:mobile/features/live/data/lan_network_discovery_service.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/data/native_external_device_bridge.dart';
import 'package:mobile/features/live/domain/camera_source.dart';
import 'package:mobile/features/live/domain/cast_device.dart';
import 'package:mobile/features/live/domain/external_device.dart';
import 'package:mobile/features/live/presentation/providers/external_device_provider.dart';
import 'package:mobile/features/live/presentation/widgets/external_device_connection_sheet.dart';

// ─── Fakes / Mocks ────────────────────────────────────────────────────────────

class _FakeBridge implements NativeExternalDeviceBridge {
  PlatformConnectivityCapabilities caps = const PlatformConnectivityCapabilities(
    platform: 'android',
    usbHostSupported: true,
    externalCameraApiSupported: true,
    bluetoothSupported: true,
    bluetoothEnabled: true,
    bleSupported: true,
    wifiMulticastSupported: true,
    screenCaptureSupported: true,
  );
  List<NativeUsbDeviceInfo> usbDevices = [];
  List<NativeCameraDescriptor> cameras = [];
  List<AudioInputOption> audioInputs = [];
  List<NativeBluetoothDeviceInfo> bondedBt = [];
  bool usbPermissionResult = true;
  bool bleScanThrowsDenied = false;
  Map<String, dynamic> bleConnectResult = {'connected': true, 'batteryLevel': 88};
  final _eventsCtrl = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get hardwareEvents => _eventsCtrl.stream;

  void emitHwEvent(Map<String, dynamic> event) => _eventsCtrl.add(event);

  @override
  Future<PlatformConnectivityCapabilities> getPlatformCapabilities() async => caps;

  @override
  Future<List<NativeUsbDeviceInfo>> enumerateUsbDevices() async => usbDevices;

  @override
  Future<bool> requestUsbPermission(String deviceName) async =>
      usbPermissionResult;

  @override
  Future<List<NativeCameraDescriptor>> enumerateCameras() async => cameras;

  @override
  Future<List<AudioInputOption>> enumerateAudioInputs() async => audioInputs;

  @override
  Future<List<NativeBluetoothDeviceInfo>> getBondedBluetoothDevices() async =>
      bondedBt;

  @override
  Future<void> startBleScan({int timeoutMs = 8000}) async {
    if (bleScanThrowsDenied) {
      throw Exception('PERMISSION_DENIED: BLUETOOTH_SCAN denied');
    }
  }

  @override
  Future<void> stopBleScan() async {}

  @override
  Future<Map<String, dynamic>> connectBleDevice(String address) async =>
      bleConnectResult;

  @override
  Future<void> disconnectBleDevice(String address) async {}

  @override
  Future<Map<String, dynamic>> readBleDeviceStatus(String address) async =>
      bleConnectResult;

  @override
  Future<void> triggerBleRemoteCommand(String address, String command) async {
    throw UnsupportedError('No standard camera recording GATT characteristic');
  }

  @override
  Future<void> acquireMulticastLock() async {}

  @override
  Future<void> releaseMulticastLock() async {}
}

class _FakeLanDiscovery implements LanNetworkDiscoveryService {
  List<DiscoveredDlnaDevice> dlnaDevices = [];
  NetworkProbeResult rtspResult = const NetworkProbeResult(
    reachable: true,
    latencyMs: 12,
    summary: 'RTSP/1.0 200 OK',
  );
  NetworkProbeResult tcpResult = const NetworkProbeResult(
    reachable: true,
    latencyMs: 18,
    summary: 'TCP reachable',
  );

  @override
  Future<List<DiscoveredDlnaDevice>> discoverDlnaRenderers({
    Duration timeout = const Duration(seconds: 3),
  }) async => dlnaDevices;

  @override
  Future<void> castDlnaMedia({
    required String controlUrl,
    required String mediaUrl,
    required String title,
  }) async {}

  @override
  Future<void> stopDlnaMedia({required String controlUrl}) async {}

  @override
  Future<NetworkProbeResult> probeRtspEndpoint(String rtspUrl) async =>
      rtspResult;

  @override
  Future<NetworkProbeResult> probeTcpEndpoint(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async => tcpResult;
}

class _FakeCastService extends Mock implements CastService {
  final _devicesCtrl = StreamController<List<CastDevice>>.broadcast();
  final List<CastDevice> devicesList = [];
  final List<(String streamId, String deviceId, String action)> recordCalls = [];

  @override
  Stream<List<CastDevice>> get devicesStream => _devicesCtrl.stream;

  @override
  List<CastDevice> get currentDevices => devicesList;

  @override
  Future<void> startDiscovery() async {
    _devicesCtrl.add(devicesList);
  }

  @override
  void stopDiscovery() {}

  @override
  void triggerRemoteCameraRecord({
    required String streamId,
    required String deviceId,
    required String action,
  }) {
    recordCalls.add((streamId, deviceId, action));
  }
}

class _FakeLiveRepo extends Mock implements LiveStreamingRepository {
  Map<String, dynamic> ingestResponse = {
    'stage': 'mediamtx_ingesting',
    'mediaMtx': {'ready': true, 'bytesReceived': 4096},
  };

  @override
  Future<Map<String, dynamic>> getIngestStatus(String streamId) async =>
      ingestResponse;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ExternalDeviceManager Discovery, Permissions & Lifecycle', () {
    test('discovers built-in, UVC/HDMI/SDI capture, non-UVC warning, audio & BLE', () async {
      final bridge = _FakeBridge()
        ..usbDevices = [
          const NativeUsbDeviceInfo(
            deviceName: '/dev/bus/usb/001/002',
            displayName: 'Elgato Cam Link 4K',
            hasPermission: true,
            isUvc: true,
            hasAudio: true,
            classification: 'hdmiCapture',
          ),
          const NativeUsbDeviceInfo(
            deviceName: '/dev/bus/usb/001/003',
            displayName: 'Blackmagic SDI-to-USB',
            hasPermission: true,
            isUvc: true,
            hasAudio: true,
            classification: 'sdiCapture',
          ),
          const NativeUsbDeviceInfo(
            deviceName: '/dev/bus/usb/001/004',
            displayName: 'DSLR PTP Camera',
            hasPermission: true,
            isUvc: false,
            hasAudio: false,
            classification: 'nonUvcCamera',
            nonUvcReason: 'Connected in PTP mode without UVC video output.',
          ),
        ]
        ..cameras = [
          const NativeCameraDescriptor(
            cameraId: '100',
            name: 'External UVC Camera',
            facing: 'external',
            isExternal: true,
            resolutions: ['1920x1080', '1280x720'],
            supportedFps: [30, 60],
          ),
        ]
        ..audioInputs = [
          const AudioInputOption(
            id: 'usb-1',
            name: 'USB Audio Interface',
            kind: 'usb',
          ),
        ]
        ..bondedBt = [
          const NativeBluetoothDeviceInfo(
            address: 'AA:BB:CC:11:22:33',
            name: 'Sony Remote Grip',
            paired: true,
          ),
        ];

      final manager = ExternalDeviceManager(
        bridge: bridge,
        lanDiscovery: _FakeLanDiscovery(),
        castService: _FakeCastService(),
        liveRepo: _FakeLiveRepo(),
        skipHardwarePermissions: true,
      );

      await manager.discoverDevices();
      final devs = manager.state.devices;

      expect(devs.any((d) => d.id == 'builtin:front'), isTrue);
      expect(devs.any((d) => d.id == 'builtin:rear'), isTrue);
      expect(devs.any((d) => d.kind == ExternalDeviceKind.hdmiCapture), isTrue);
      expect(devs.any((d) => d.kind == ExternalDeviceKind.sdiCapture), isTrue);
      expect(devs.any((d) => d.kind == ExternalDeviceKind.bluetoothController), isTrue);

      final nonUvc = devs.firstWhere(
        (d) => d.kind == ExternalDeviceKind.nonUvcUsbDevice,
      );
      expect(nonUvc.connectionState, ExternalConnectionState.error);
      expect(nonUvc.lastError, contains('PTP mode'));
      expect(manager.toCameraSource(nonUvc), isNull);

      expect(manager.state.audioInputs.length, 1);
      manager.dispose();
    });

    test('USB permission denied sets error state and blocks connection', () async {
      final bridge = _FakeBridge()
        ..usbDevices = [
          const NativeUsbDeviceInfo(
            deviceName: '/dev/bus/usb/001/009',
            displayName: 'Generic UVC Webcam',
            hasPermission: false,
            isUvc: true,
            hasAudio: false,
            classification: 'uvcCamera',
          ),
        ]
        ..usbPermissionResult = false;

      final manager = ExternalDeviceManager(
        bridge: bridge,
        lanDiscovery: _FakeLanDiscovery(),
        castService: _FakeCastService(),
        skipHardwarePermissions: true,
      );

      await manager.discoverDevices();
      final ok = await manager.connectDevice('usb:/dev/bus/usb/001/009');
      expect(ok, isFalse);

      final dev = manager.state.devices.firstWhere(
        (d) => d.id == 'usb:/dev/bus/usb/001/009',
      );
      expect(dev.connectionState, ExternalConnectionState.error);
      expect(dev.lastError, contains('denied'));
      manager.dispose();
    });

    test('BLE scan permission denied populates actionable guidance', () async {
      final bridge = _FakeBridge()..bleScanThrowsDenied = true;
      final manager = ExternalDeviceManager(
        bridge: bridge,
        lanDiscovery: _FakeLanDiscovery(),
        castService: _FakeCastService(),
        skipHardwarePermissions: true,
      );

      await manager.discoverDevices(includeBleScan: true);
      expect(manager.state.permissionGuidance, contains('Bluetooth permission denied'));
      manager.dispose();
    });

    test('BLE connection reads battery telemetry without faking video', () async {
      final bridge = _FakeBridge()
        ..bondedBt = [
          const NativeBluetoothDeviceInfo(
            address: '11:22:33:44:55:66',
            name: 'Encoder Mic BT',
            paired: true,
          ),
        ]
        ..bleConnectResult = {'connected': true, 'batteryLevel': 74, 'model': 'BT-PRO'};

      final manager = ExternalDeviceManager(
        bridge: bridge,
        lanDiscovery: _FakeLanDiscovery(),
        castService: _FakeCastService(),
        skipHardwarePermissions: true,
      );

      await manager.discoverDevices(includeBleScan: false);
      final ok = await manager.connectDevice('ble:11:22:33:44:55:66');
      expect(ok, isTrue);

      final dev = manager.state.devices.firstWhere((d) => d.id == 'ble:11:22:33:44:55:66');
      expect(dev.connectionState, ExternalConnectionState.connected);
      expect(dev.diagnostics.batteryPercent, 74);
      expect(dev.capabilities.hasVideoInput, isFalse);
      expect(manager.toCameraSource(dev), isNull);

      // Remote recording on unsupported BT returns false cleanly
      final recOk = await manager.triggerRemoteRecording(dev.id, start: true);
      expect(recOk, isFalse);
      manager.dispose();
    });

    test('RTSP manual device persists redacted endpoint, reconnects, and forgets cleanly', () async {
      final lan = _FakeLanDiscovery();
      final manager = ExternalDeviceManager(
        bridge: _FakeBridge(),
        lanDiscovery: lan,
        castService: _FakeCastService(),
        skipHardwarePermissions: true,
      );

      final added = await manager.addOrUpdateManualDevice(
        kind: ExternalDeviceKind.ipCameraRtsp,
        name: 'Altar PTZ',
        endpoint: 'rtsp://admin:supersecret@192.168.1.50:554/live',
        secret: 'supersecret',
        metadata: {'port': 554, 'transport': 'tcp', 'username': 'admin'},
      );

      // Password stripped from persisted endpoint
      expect(added.endpoint, 'rtsp://192.168.1.50:554/live');

      final connected = await manager.connectDevice(added.id);
      expect(connected, isTrue);
      final afterConnect = manager.state.devices.firstWhere((d) => d.id == added.id);
      expect(afterConnect.connectionState, ExternalConnectionState.streamReady);

      // Convert to NetworkCameraSource
      final source = manager.toCameraSource(afterConnect);
      expect(source, isA<NetworkCameraSource>());
      expect((source as NetworkCameraSource).password, 'supersecret');

      // Reload from SharedPreferences in a new manager instance
      final manager2 = ExternalDeviceManager(
        bridge: _FakeBridge(),
        lanDiscovery: lan,
        castService: _FakeCastService(),
        skipHardwarePermissions: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(manager2.state.devices.any((d) => d.id == added.id), isTrue);

      await manager2.removeOrForgetDevice(added.id);
      expect(manager2.state.devices.any((d) => d.id == added.id), isFalse);

      manager.dispose();
      manager2.dispose();
    });

    test('External RTMP encoder testVideoFeed verifies real MediaMTX ingest status', () async {
      final repo = _FakeLiveRepo()
        ..ingestResponse = {
          'stage': 'mediamtx_ingesting',
          'mediaMtx': {'ready': true, 'bytesReceived': 8192},
        };
      final manager = ExternalDeviceManager(
        bridge: _FakeBridge(),
        lanDiscovery: _FakeLanDiscovery(),
        castService: _FakeCastService(),
        liveRepo: repo,
        skipHardwarePermissions: true,
      );

      final enc = await manager.addOrUpdateManualDevice(
        kind: ExternalDeviceKind.externalRtmpEncoder,
        name: 'ATEM Mini Extreme',
        endpoint: 'rtmp://live.cloudinary.com/streams',
      );
      final ok = await manager.testVideoFeed(enc.id, streamId: 'stream-123');
      expect(ok, isTrue);

      final updated = manager.state.devices.firstWhere((d) => d.id == enc.id);
      expect(updated.connectionState, ExternalConnectionState.streamReady);
      expect(updated.diagnostics.videoFeedVerified, isTrue);

      // Streaming state transition
      manager.markStreaming(enc.id, true);
      expect(
        manager.state.devices.firstWhere((d) => d.id == enc.id).connectionState,
        ExternalConnectionState.streaming,
      );

      manager.dispose();
    });

    test('Remote WebRTC camera triggers remote recording command & RecordingTargetMode honesty', () async {
      final cast = _FakeCastService();
      cast.devicesList.add(
        CastDevice(
          id: 'peer-cam-1',
          name: 'Side Angle Phone',
          protocol: CastProtocol.remotePeerCamera,
          type: CastDeviceType.remoteCamera,
          status: CastSessionStatus.connected,
          discoveredAt: DateTime.now(),
        ),
      );

      final manager = ExternalDeviceManager(
        bridge: _FakeBridge(),
        lanDiscovery: _FakeLanDiscovery(),
        castService: cast,
        skipHardwarePermissions: true,
      );

      await manager.discoverDevices(includeBleScan: false);
      final ok = await manager.triggerRemoteRecording(
        'cast:peer-cam-1',
        start: true,
        streamId: 'stream-99',
      );
      expect(ok, isTrue);
      expect(cast.recordCalls, [('stream-99', 'peer-cam-1', 'start')]);

      // Verify audio-only backup never claims to include video
      expect(RecordingTargetMode.localAudioBackup.includesVideo, isFalse);
      expect(RecordingTargetMode.localDeviceAv.includesVideo, isTrue);
      expect(RecordingTargetMode.cameraSdCard.includesVideo, isTrue);

      manager.dispose();
    });
  });

  group('ExternalDeviceConnectionSheet Widget Tests', () {
    testWidgets('renders devices, Simple/Pro toggle, and selects video source', (tester) async {
      final bridge = _FakeBridge()
        ..usbDevices = [
          const NativeUsbDeviceInfo(
            deviceName: '/dev/bus/usb/001/002',
            displayName: 'Cam Link HDMI',
            hasPermission: true,
            isUvc: true,
            hasAudio: true,
            classification: 'hdmiCapture',
          ),
        ];

      final manager = ExternalDeviceManager(
        bridge: bridge,
        lanDiscovery: _FakeLanDiscovery(),
        castService: _FakeCastService(),
        skipHardwarePermissions: true,
      );

      CameraSource? picked;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            externalDeviceManagerProvider.overrideWith((ref) => manager),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ExternalDeviceConnectionSheet(
                currentSource: const BuiltInCameraSource(),
                onSelectSource: (s) => picked = s,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('External Device Manager'), findsOneWidget);
      expect(find.text('Cam Link HDMI'), findsOneWidget);
      expect(find.text('Simple'), findsOneWidget);

      // Toggle Pro mode
      await tester.tap(find.text('Simple'));
      await tester.pumpAndSettle();
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('60 fps'), findsOneWidget);
      expect(find.text('Test Audio'), findsWidgets);

      // Select Cam Link HDMI (sorted first due to USB OTG priority) as video source
      final useButtons = find.text('Use Video Source');
      expect(useButtons, findsWidgets);
      await tester.ensureVisible(useButtons.first);
      await tester.tap(useButtons.first);
      await tester.pumpAndSettle();

      expect(picked, isA<WiredCaptureCameraSource>());
      expect((picked as WiredCaptureCameraSource).deviceName, 'Cam Link HDMI');
    });
  });
}
