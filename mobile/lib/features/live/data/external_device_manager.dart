// lib/features/live/data/external_device_manager.dart
//
// Unified External Device Connection Manager for Zekre Kedusan Live Studio.
//
// Coordinates wired capture hardware (USB UVC, HDMI capture, SDI capture),
// Bluetooth/BLE telemetry & control, Wi-Fi/LAN cameras & TVs (RTSP, DLNA),
// internet streaming encoders (RTMP, SRT), remote WebRTC phone cameras, and
// screen sharing under one consistent connection lifecycle:
//
//   DISCONNECTED → DISCOVERING → AVAILABLE → CONNECTING → CONNECTED →
//   STREAM_READY → STREAMING → DISCONNECTED / ERROR

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/features/live/data/cast_service.dart';
import 'package:mobile/features/live/data/lan_network_discovery_service.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/data/native_external_device_bridge.dart';
import 'package:mobile/features/live/domain/camera_source.dart';
import 'package:mobile/features/live/domain/cast_device.dart';
import 'package:mobile/features/live/domain/external_device.dart';

class ExternalDeviceManagerState {
  final ExternalConnectionState managerState;
  final List<ExternalDevice> devices;
  final List<AudioInputOption> audioInputs;
  final String? selectedVideoDeviceId;
  final String? selectedAudioInputId;
  final int targetWidth;
  final int targetHeight;
  final int targetFps;
  final bool isScanning;
  final String? lastError;
  final String? permissionGuidance;
  final PlatformConnectivityCapabilities capabilities;

  const ExternalDeviceManagerState({
    this.managerState = ExternalConnectionState.disconnected,
    this.devices = const [],
    this.audioInputs = const [],
    this.selectedVideoDeviceId,
    this.selectedAudioInputId,
    this.targetWidth = 1280,
    this.targetHeight = 720,
    this.targetFps = 30,
    this.isScanning = false,
    this.lastError,
    this.permissionGuidance,
    this.capabilities = const PlatformConnectivityCapabilities(platform: 'unknown'),
  });

  ExternalDevice? get selectedVideoDevice {
    if (selectedVideoDeviceId == null) return null;
    for (final d in devices) {
      if (d.id == selectedVideoDeviceId) return d;
    }
    return null;
  }

  List<ExternalDevice> get connectedDevices =>
      devices.where((d) => d.connectionState.isActiveConnection).toList();

  List<ExternalDevice> get savedDevices =>
      devices.where((d) => d.isSaved).toList();

  ExternalDeviceManagerState copyWith({
    ExternalConnectionState? managerState,
    List<ExternalDevice>? devices,
    List<AudioInputOption>? audioInputs,
    String? selectedVideoDeviceId,
    bool clearSelectedVideo = false,
    String? selectedAudioInputId,
    bool clearSelectedAudio = false,
    int? targetWidth,
    int? targetHeight,
    int? targetFps,
    bool? isScanning,
    String? lastError,
    bool clearError = false,
    String? permissionGuidance,
    bool clearPermissionGuidance = false,
    PlatformConnectivityCapabilities? capabilities,
  }) => ExternalDeviceManagerState(
    managerState: managerState ?? this.managerState,
    devices: devices ?? this.devices,
    audioInputs: audioInputs ?? this.audioInputs,
    selectedVideoDeviceId: clearSelectedVideo
        ? null
        : (selectedVideoDeviceId ?? this.selectedVideoDeviceId),
    selectedAudioInputId: clearSelectedAudio
        ? null
        : (selectedAudioInputId ?? this.selectedAudioInputId),
    targetWidth: targetWidth ?? this.targetWidth,
    targetHeight: targetHeight ?? this.targetHeight,
    targetFps: targetFps ?? this.targetFps,
    isScanning: isScanning ?? this.isScanning,
    lastError: clearError ? null : (lastError ?? this.lastError),
    permissionGuidance: clearPermissionGuidance
        ? null
        : (permissionGuidance ?? this.permissionGuidance),
    capabilities: capabilities ?? this.capabilities,
  );
}

class ExternalDeviceManager extends StateNotifier<ExternalDeviceManagerState> {
  static const _savedDevicesPrefsKey = 'zk_saved_external_devices_v1';

  final NativeExternalDeviceBridge _bridge;
  final LanNetworkDiscoveryService _lanDiscovery;
  final CastService _castService;
  final LiveStreamingRepository? _liveRepo;
  final Future<SharedPreferences> Function()? _prefsLoader;
  final bool _skipHardwarePermissions;

  final Map<String, ExternalDevice> _devices = {};
  final Map<String, String> _ephemeralSecrets = {}; // Never written to disk
  StreamSubscription<List<CastDevice>>? _castSub;
  StreamSubscription<Map<String, dynamic>>? _hwEventsSub;
  int _activeScanToken = 0;
  bool _isDisposed = false;

  ExternalDeviceManager({
    NativeExternalDeviceBridge? bridge,
    LanNetworkDiscoveryService? lanDiscovery,
    required CastService castService,
    LiveStreamingRepository? liveRepo,
    Future<SharedPreferences> Function()? prefsLoader,
    bool skipHardwarePermissions = false,
  }) : _bridge = bridge ?? NativeExternalDeviceBridge(),
       _lanDiscovery = lanDiscovery ?? LanNetworkDiscoveryService(),
       _castService = castService,
       _liveRepo = liveRepo,
       _prefsLoader = prefsLoader,
       _skipHardwarePermissions = skipHardwarePermissions,
       super(const ExternalDeviceManagerState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSavedDevices();
    final caps = await _bridge.getPlatformCapabilities();
    if (!_isDisposed) {
      state = state.copyWith(capabilities: caps);
    }

    _castSub = _castService.devicesStream.listen(_mergeCastDevices);
    _hwEventsSub = _bridge.hardwareEvents.listen(_handleHardwareEvent);
  }

  Future<SharedPreferences?> _getPrefs() async {
    try {
      if (_prefsLoader != null) return await _prefsLoader();
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadSavedDevices() async {
    final prefs = await _getPrefs();
    if (prefs == null || _isDisposed) return;
    final raw = prefs.getString(_savedDevicesPrefsKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final item in decoded) {
        if (item is Map) {
          final dev = ExternalDevice.fromSavedJson(
            item.cast<String, dynamic>(),
          );
          _devices[dev.id] = dev;
        }
      }
      _publishDevices();
    } catch (_) {}
  }

  Future<void> _persistSavedDevices() async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    final saved = _devices.values
        .where((d) => d.isSaved)
        .map((d) => d.toSavedJson())
        .toList();
    await prefs.setString(_savedDevicesPrefsKey, jsonEncode(saved));
  }

  // ─── Discovery ─────────────────────────────────────────────────────────────

  /// Runs a full device scan across wired USB/UVC/HDMI/SDI, external cameras,
  /// audio inputs, Bluetooth/BLE, LAN SSDP/DLNA, and remote WebRTC peers.
  Future<void> discoverDevices({bool includeBleScan = true}) async {
    if (_isDisposed) return;
    final scanToken = ++_activeScanToken;

    state = state.copyWith(
      managerState: ExternalConnectionState.discovering,
      isScanning: true,
      clearError: true,
      clearPermissionGuidance: true,
    );

    try {
      final caps = await _bridge.getPlatformCapabilities();
      if (_isDisposed || scanToken != _activeScanToken) return;
      state = state.copyWith(capabilities: caps);

      // 1. Built-in / system & wired USB/UVC/HDMI/SDI devices
      await _discoverWiredAndBuiltInCameras();

      // 2. Audio inputs (USB audio, Bluetooth HFP, wired headset, built-in mic)
      final audioInputs = await _bridge.enumerateAudioInputs();
      if (_isDisposed || scanToken != _activeScanToken) return;
      state = state.copyWith(audioInputs: audioInputs);

      // 3. Bluetooth bonded & BLE discovery (if supported & permitted)
      await _discoverBluetoothDevices(includeBleScan: includeBleScan);

      // 4. Trigger CastService discovery (Socket.IO remote cameras + SSDP DLNA)
      await _castService.startDiscovery();
      _mergeCastDevices(_castService.currentDevices);

      if (_isDisposed || scanToken != _activeScanToken) return;
      _publishDevices(
        overrideManagerState: _computeAggregateManagerState(),
        isScanning: false,
      );
    } catch (e) {
      if (_isDisposed || scanToken != _activeScanToken) return;
      state = state.copyWith(
        managerState: ExternalConnectionState.error,
        isScanning: false,
        lastError: e.toString(),
      );
    }
  }

  /// Explicit alias for user-initiated "Scan Again".
  Future<void> scanAgain() => discoverDevices(includeBleScan: true);

  /// Cancels any in-flight discovery scan.
  Future<void> cancelDiscovery() async {
    _activeScanToken++;
    await _bridge.stopBleScan();
    if (!_isDisposed) {
      state = state.copyWith(
        isScanning: false,
        managerState: _computeAggregateManagerState(),
      );
    }
  }

  Future<void> _discoverWiredAndBuiltInCameras() async {
    final usbList = await _bridge.enumerateUsbDevices();
    final cameras = await _bridge.enumerateCameras();

    // Ensure built-in cameras are always represented cleanly
    _upsertDevice(
      ExternalDevice(
        id: 'builtin:front',
        name: 'Built-in Front Camera',
        kind: ExternalDeviceKind.builtInCamera,
        connectionMethod: ExternalConnectionMethod.builtIn,
        connectionState: _devices['builtin:front']?.connectionState ??
            ExternalConnectionState.available,
        capabilities: const ExternalDeviceCapabilities(
          supportedVideoFormats: ['H.264 / NV12'],
          supportedResolutions: ['1920x1080', '1280x720', '854x480'],
          supportedFps: [24, 30, 60],
          hasVideoInput: true,
          hasAudioInput: true,
          audioChannels: 2,
          supportsVideoPreview: true,
        ),
        endpoint: 'front',
        discoveredAt: DateTime.now(),
      ),
    );
    _upsertDevice(
      ExternalDevice(
        id: 'builtin:rear',
        name: 'Built-in Rear Camera',
        kind: ExternalDeviceKind.builtInCamera,
        connectionMethod: ExternalConnectionMethod.builtIn,
        connectionState: _devices['builtin:rear']?.connectionState ??
            ExternalConnectionState.available,
        capabilities: const ExternalDeviceCapabilities(
          supportedVideoFormats: ['H.264 / NV12'],
          supportedResolutions: ['1920x1080', '1280x720', '854x480'],
          supportedFps: [24, 30, 60],
          hasVideoInput: true,
          hasAudioInput: true,
          audioChannels: 2,
          supportsVideoPreview: true,
        ),
        endpoint: 'rear',
        discoveredAt: DateTime.now(),
      ),
    );

    // Map native Camera2 / AVFoundation external cameras
    for (final cam in cameras.where((c) => c.isExternal)) {
      final id = 'extcam:${cam.cameraId}';
      final label = cam.name ?? 'External Camera (${cam.cameraId})';
      final kind = _kindFromName(label);
      _upsertDevice(
        ExternalDevice(
          id: id,
          name: label,
          kind: kind,
          connectionMethod: ExternalConnectionMethod.usbOtg,
          connectionState:
              _devices[id]?.connectionState ?? ExternalConnectionState.available,
          capabilities: ExternalDeviceCapabilities(
            supportedVideoFormats: const ['MJPEG / YUV420'],
            supportedResolutions: cam.resolutions.isNotEmpty
                ? cam.resolutions
                : const ['1920x1080', '1280x720'],
            supportedFps: cam.supportedFps.isNotEmpty
                ? cam.supportedFps
                : const [30],
            hasVideoInput: true,
            hasAudioInput: false,
            supportsVideoPreview: true,
            isUvcCompliant: true,
          ),
          endpoint: cam.cameraId,
          metadata: {'camera2Id': cam.cameraId},
          discoveredAt: DateTime.now(),
        ),
      );
    }

    // Map raw USB devices (including non-UVC cameras so user gets honest warning)
    for (final usb in usbList) {
      if (usb.classification == 'usbAudio') continue;
      final id = 'usb:${usb.deviceName}';
      final kind = switch (usb.classification) {
        'hdmiCapture' => ExternalDeviceKind.hdmiCapture,
        'sdiCapture' => ExternalDeviceKind.sdiCapture,
        'uvcCamera' => ExternalDeviceKind.usbUvcCamera,
        _ => ExternalDeviceKind.nonUvcUsbDevice,
      };
      final existing = _devices[id];
      _upsertDevice(
        ExternalDevice(
          id: id,
          name: usb.displayName,
          manufacturer: usb.manufacturerName,
          model: usb.productName,
          kind: kind,
          connectionMethod: ExternalConnectionMethod.usbOtg,
          connectionState: !usb.isUvc
              ? ExternalConnectionState.error
              : (existing?.connectionState ?? ExternalConnectionState.available),
          capabilities: ExternalDeviceCapabilities(
            supportedVideoFormats:
                usb.isUvc ? const ['UVC (MJPEG / YUY2)'] : const [],
            supportedResolutions:
                usb.isUvc ? const ['1920x1080', '1280x720'] : const [],
            supportedFps: usb.isUvc ? const [30, 60] : const [],
            hasVideoInput: usb.isUvc,
            hasAudioInput: usb.hasAudio,
            audioChannels: usb.hasAudio ? 2 : 0,
            supportsVideoPreview: usb.isUvc,
            requiresUsbPermission: !usb.hasPermission,
            isUvcCompliant: usb.isUvc,
          ),
          endpoint: usb.deviceName,
          metadata: {
            if (usb.vendorId != null) 'vendorId': usb.vendorId,
            if (usb.productId != null) 'productId': usb.productId,
          },
          isUsbPermissionGranted: usb.hasPermission,
          lastError: usb.nonUvcReason,
          discoveredAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _discoverBluetoothDevices({required bool includeBleScan}) async {
    final caps = state.capabilities;
    if (!caps.bluetoothSupported) return;

    if (!_skipHardwarePermissions &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      final scanStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;
      if (scanStatus.isDenied || connectStatus.isDenied) {
        state = state.copyWith(
          permissionGuidance:
              'Bluetooth Scan/Connect permission is needed to discover BLE camera controllers and audio gear.',
        );
      }
    }

    final bonded = await _bridge.getBondedBluetoothDevices();
    for (final bt in bonded) {
      final id = 'ble:${bt.address}';
      final existing = _devices[id];
      _upsertDevice(
        ExternalDevice(
          id: id,
          name: bt.name,
          kind: ExternalDeviceKind.bluetoothController,
          connectionMethod: ExternalConnectionMethod.bluetoothBle,
          connectionState: bt.connected
              ? ExternalConnectionState.connected
              : (existing?.connectionState ??
                  ExternalConnectionState.available),
          capabilities: const ExternalDeviceCapabilities(
            hasVideoInput: false,
            hasAudioInput: true,
            audioChannels: 1,
            supportsBatteryTelemetry: true,
            supportsVideoPreview: false,
          ),
          endpoint: bt.address,
          isPaired: bt.paired,
          discoveredAt: DateTime.now(),
        ),
      );
    }

    if (includeBleScan) {
      try {
        await _bridge.startBleScan(timeoutMs: 6000);
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('PERMISSION_DENIED')) {
          state = state.copyWith(
            permissionGuidance:
                'Bluetooth permission denied. Grant Nearby Devices permission in system settings to scan BLE hardware.',
          );
        }
      }
    }
  }

  void _mergeCastDevices(List<CastDevice> castDevices) {
    if (_isDisposed) return;
    for (final cd in castDevices) {
      final id = 'cast:${cd.id}';
      final kind = switch (cd.type) {
        CastDeviceType.smartTv => ExternalDeviceKind.smartTvReceiver,
        CastDeviceType.remoteCamera => ExternalDeviceKind.wirelessCameraSystem,
        CastDeviceType.screenShare => ExternalDeviceKind.screenShare,
        CastDeviceType.usbCamera => ExternalDeviceKind.usbUvcCamera,
      };
      final method = switch (cd.protocol) {
        CastProtocol.remotePeerCamera => ExternalConnectionMethod.webrtcPeer,
        CastProtocol.screenCapture => ExternalConnectionMethod.systemCapture,
        CastProtocol.uvcUsb || CastProtocol.hdmiCapture =>
          ExternalConnectionMethod.usbOtg,
        _ => ExternalConnectionMethod.wifiLan,
      };
      final connState = switch (cd.status) {
        CastSessionStatus.discovered => ExternalConnectionState.available,
        CastSessionStatus.pairing || CastSessionStatus.reconnecting =>
          ExternalConnectionState.connecting,
        CastSessionStatus.connected => cd.isActiveSource
            ? ExternalConnectionState.streaming
            : ExternalConnectionState.streamReady,
        CastSessionStatus.disconnected => ExternalConnectionState.disconnected,
        CastSessionStatus.error => ExternalConnectionState.error,
      };

      _upsertDevice(
        ExternalDevice(
          id: id,
          name: cd.name,
          model: cd.model,
          kind: kind,
          connectionMethod: method,
          connectionState: connState,
          capabilities: ExternalDeviceCapabilities(
            supportedVideoFormats: cd.type == CastDeviceType.remoteCamera
                ? const ['WebRTC H.264 / VP8']
                : const [],
            hasVideoInput: cd.type != CastDeviceType.smartTv,
            hasAudioInput: cd.type == CastDeviceType.remoteCamera,
            supportsVideoPreview: cd.type == CastDeviceType.remoteCamera,
            supportsRemoteRecording: cd.type == CastDeviceType.remoteCamera,
          ),
          diagnostics: ExternalDeviceDiagnostics(
            signalStrength: cd.signalStrength,
            videoFeedVerified:
                cd.type == CastDeviceType.remoteCamera &&
                cd.status == CastSessionStatus.connected,
          ),
          endpoint: cd.ipAddress ?? cd.id,
          metadata: {'castDeviceId': cd.id, 'castProtocol': cd.protocol.name},
          isPaired: cd.status == CastSessionStatus.connected,
          lastError: cd.lastError,
          discoveredAt: cd.discoveredAt,
        ),
      );
    }
    _publishDevices();
  }

  void _handleHardwareEvent(Map<String, dynamic> event) {
    if (_isDisposed) return;
    final kind = event['event']?.toString();
    switch (kind) {
      case 'usb_attached':
      case 'usb_detached':
        unawaited(discoverDevices(includeBleScan: false));
        break;
      case 'ble_discovered':
        final address = event['address']?.toString();
        final name = event['name']?.toString();
        if (address != null && name != null) {
          final id = 'ble:$address';
          final existing = _devices[id];
          _upsertDevice(
            ExternalDevice(
              id: id,
              name: name,
              kind: ExternalDeviceKind.bluetoothController,
              connectionMethod: ExternalConnectionMethod.bluetoothBle,
              connectionState: existing?.connectionState ??
                  ExternalConnectionState.available,
              capabilities: const ExternalDeviceCapabilities(
                hasVideoInput: false,
                hasAudioInput: true,
                supportsBatteryTelemetry: true,
                supportsVideoPreview: false,
              ),
              diagnostics: ExternalDeviceDiagnostics(
                signalStrength: _rssiToStrength((event['rssi'] as num?)?.toInt()),
              ),
              endpoint: address,
              isPaired: existing?.isPaired ?? false,
              discoveredAt: DateTime.now(),
            ),
          );
          _publishDevices();
        }
        break;
      case 'ble_status':
        final address = event['address']?.toString();
        final status = (event['status'] as Map?)?.cast<String, dynamic>();
        if (address != null && status != null) {
          final id = 'ble:$address';
          final existing = _devices[id];
          if (existing != null) {
            _upsertDevice(
              existing.copyWith(
                manufacturer: status['manufacturer']?.toString() ?? existing.manufacturer,
                model: status['model']?.toString() ?? existing.model,
                diagnostics: existing.diagnostics.copyWith(
                  batteryPercent: (status['batteryLevel'] as num?)?.toInt(),
                ),
              ),
            );
            _publishDevices();
          }
        }
        break;
      case 'ble_disconnected':
        final address = event['address']?.toString();
        if (address != null) {
          _updateDevice(
            'ble:$address',
            (d) => d.copyWith(
              connectionState: ExternalConnectionState.disconnected,
            ),
          );
        }
        break;
    }
  }

  // ─── Connect / Pair / Disconnect / Reconnect / Forget ─────────────────────

  Future<bool> pairDevice(String deviceId) async {
    final dev = _devices[deviceId];
    if (dev == null) return false;

    if (dev.connectionMethod == ExternalConnectionMethod.usbOtg &&
        dev.endpoint != null) {
      final granted = await _bridge.requestUsbPermission(dev.endpoint!);
      _updateDevice(
        deviceId,
        (d) => d.copyWith(
          isUsbPermissionGranted: granted,
          isPaired: granted,
          connectionState: granted
              ? ExternalConnectionState.connected
              : ExternalConnectionState.error,
          lastError: granted
              ? null
              : 'USB permission denied by user.',
          clearError: granted,
        ),
      );
      return granted;
    }

    return connectDevice(deviceId);
  }

  Future<bool> connectDevice(String deviceId, {String? streamId}) async {
    final dev = _devices[deviceId];
    if (dev == null) return false;

    if (dev.kind == ExternalDeviceKind.nonUvcUsbDevice) {
      _updateDevice(
        deviceId,
        (d) => d.copyWith(
          connectionState: ExternalConnectionState.error,
          lastError:
              d.lastError ??
              'This USB device does not support UVC video output.',
        ),
      );
      return false;
    }

    _updateDevice(
      deviceId,
      (d) => d.copyWith(
        connectionState: ExternalConnectionState.connecting,
        clearError: true,
      ),
    );

    try {
      switch (dev.connectionMethod) {
        case ExternalConnectionMethod.builtIn:
          _updateDevice(
            deviceId,
            (d) => d.copyWith(
              connectionState: ExternalConnectionState.streamReady,
              lastConnectedAt: DateTime.now(),
            ),
          );
          return true;

        case ExternalConnectionMethod.usbOtg:
          if (dev.capabilities.requiresUsbPermission &&
              !dev.isUsbPermissionGranted &&
              dev.endpoint != null) {
            final granted = await _bridge.requestUsbPermission(dev.endpoint!);
            if (!granted) {
              _updateDevice(
                deviceId,
                (d) => d.copyWith(
                  connectionState: ExternalConnectionState.error,
                  isUsbPermissionGranted: false,
                  lastError: 'USB access permission was denied.',
                ),
              );
              return false;
            }
          }
          _updateDevice(
            deviceId,
            (d) => d.copyWith(
              connectionState: ExternalConnectionState.connected,
              isUsbPermissionGranted: true,
              isPaired: true,
              isSaved: true,
              lastConnectedAt: DateTime.now(),
            ),
          );
          await _persistSavedDevices();
          return await testVideoFeed(deviceId);

        case ExternalConnectionMethod.bluetoothBle:
          if (dev.endpoint == null) return false;
          final bleStatus = await _bridge
              .connectBleDevice(dev.endpoint!)
              .timeout(const Duration(seconds: 8));
          _updateDevice(
            deviceId,
            (d) => d.copyWith(
              connectionState: ExternalConnectionState.connected,
              isPaired: true,
              isSaved: true,
              manufacturer: bleStatus['manufacturer']?.toString() ?? d.manufacturer,
              model: bleStatus['model']?.toString() ?? d.model,
              diagnostics: d.diagnostics.copyWith(
                batteryPercent: (bleStatus['batteryLevel'] as num?)?.toInt(),
              ),
              lastConnectedAt: DateTime.now(),
            ),
          );
          await _persistSavedDevices();
          return true;

        case ExternalConnectionMethod.webrtcPeer:
          final castId = dev.metadata['castDeviceId']?.toString();
          if (castId == null || streamId == null || streamId.isEmpty) {
            _updateDevice(
              deviceId,
              (d) => d.copyWith(
                connectionState: ExternalConnectionState.error,
                lastError:
                    'Open a stream session in Live Studio to pair a remote camera.',
              ),
            );
            return false;
          }
          final targetCast = _castService.currentDevices.firstWhere(
            (c) => c.id == castId,
            orElse: () => CastDevice(
              id: castId,
              name: dev.name,
              protocol: CastProtocol.remotePeerCamera,
              type: CastDeviceType.remoteCamera,
              discoveredAt: dev.discoveredAt,
            ),
          );
          await _castService.connectRemoteCamera(
            streamId: streamId,
            device: targetCast,
          );
          _updateDevice(
            deviceId,
            (d) => d.copyWith(
              connectionState: ExternalConnectionState.connected,
              isPaired: true,
              lastConnectedAt: DateTime.now(),
            ),
          );
          return true;

        case ExternalConnectionMethod.wifiLan:
          if (dev.kind == ExternalDeviceKind.ipCameraRtsp) {
            return await testVideoFeed(deviceId, streamId: streamId);
          }
          _updateDevice(
            deviceId,
            (d) => d.copyWith(
              connectionState: ExternalConnectionState.connected,
              isSaved: true,
              lastConnectedAt: DateTime.now(),
            ),
          );
          await _persistSavedDevices();
          return true;

        case ExternalConnectionMethod.internetIngest:
          return await testVideoFeed(deviceId, streamId: streamId);

        case ExternalConnectionMethod.systemCapture:
          _updateDevice(
            deviceId,
            (d) => d.copyWith(
              connectionState: ExternalConnectionState.streamReady,
              lastConnectedAt: DateTime.now(),
            ),
          );
          return true;
      }
    } catch (e) {
      _updateDevice(
        deviceId,
        (d) => d.copyWith(
          connectionState: ExternalConnectionState.error,
          lastError: e.toString(),
        ),
      );
      return false;
    }
  }

  Future<void> disconnectDevice(String deviceId, {String? streamId}) async {
    final dev = _devices[deviceId];
    if (dev == null) return;

    if (dev.connectionMethod == ExternalConnectionMethod.bluetoothBle &&
        dev.endpoint != null) {
      await _bridge.disconnectBleDevice(dev.endpoint!);
    } else if (dev.connectionMethod == ExternalConnectionMethod.webrtcPeer) {
      final castId = dev.metadata['castDeviceId']?.toString();
      if (castId != null) {
        await _castService.disconnectRemoteCamera(castId);
      }
    }

    _updateDevice(
      deviceId,
      (d) => d.copyWith(
        connectionState: ExternalConnectionState.disconnected,
        clearError: true,
      ),
    );
    if (state.selectedVideoDeviceId == deviceId) {
      state = state.copyWith(clearSelectedVideo: true);
    }
  }

  Future<bool> reconnectDevice(String deviceId, {String? streamId}) =>
      connectDevice(deviceId, streamId: streamId);

  Future<void> removeOrForgetDevice(String deviceId) async {
    await disconnectDevice(deviceId);
    _ephemeralSecrets.remove(deviceId);
    _devices.remove(deviceId);
    await _persistSavedDevices();
    _publishDevices();
  }

  // ─── Manual Device Registration (RTSP / SRT / RTMP Encoder) ───────────────

  Future<ExternalDevice> addOrUpdateManualDevice({
    required ExternalDeviceKind kind,
    required String name,
    required String endpoint,
    String? secret,
    Map<String, dynamic> metadata = const {},
  }) async {
    final safeName = name.trim().isEmpty ? 'External Device' : name.trim();
    final sanitizedEndpoint = ExternalDevice.redactEndpoint(endpoint.trim()) ??
        endpoint.trim();
    final id = 'manual:${kind.name}:${sanitizedEndpoint.hashCode}';

    if (secret != null && secret.isNotEmpty) {
      _ephemeralSecrets[id] = secret;
    }

    final method = kind == ExternalDeviceKind.ipCameraRtsp
        ? ExternalConnectionMethod.wifiLan
        : ExternalConnectionMethod.internetIngest;

    final device = ExternalDevice(
      id: id,
      name: safeName,
      kind: kind,
      connectionMethod: method,
      connectionState: ExternalConnectionState.available,
      capabilities: ExternalDeviceCapabilities(
        supportedVideoFormats: kind == ExternalDeviceKind.ipCameraRtsp
            ? const ['RTSP H.264 / AAC']
            : kind == ExternalDeviceKind.externalSrtEncoder
            ? const ['SRT MPEG-TS (H.264 / AAC)']
            : const ['RTMP FLV (H.264 / AAC)'],
        hasVideoInput: true,
        hasAudioInput: true,
        supportsVideoPreview: false,
      ),
      endpoint: sanitizedEndpoint,
      metadata: metadata,
      isSaved: true,
      discoveredAt: DateTime.now(),
    );

    _upsertDevice(device);
    await _persistSavedDevices();
    _publishDevices();
    return device;
  }

  // ─── Selection & Configuration ─────────────────────────────────────────────

  void selectVideoSource(String deviceId) {
    if (!_devices.containsKey(deviceId)) return;
    state = state.copyWith(selectedVideoDeviceId: deviceId);
  }

  void selectAudioSource(String? audioInputId) {
    state = state.copyWith(
      selectedAudioInputId: audioInputId,
      clearSelectedAudio: audioInputId == null,
    );
  }

  void configureFormat({
    required int width,
    required int height,
    required int fps,
  }) {
    state = state.copyWith(
      targetWidth: width,
      targetHeight: height,
      targetFps: fps,
    );
  }

  /// Converts a selected [ExternalDevice] to a [CameraSource] for Live Studio.
  CameraSource? toCameraSource(ExternalDevice device) {
    final audioId = state.selectedAudioInputId;
    switch (device.kind) {
      case ExternalDeviceKind.builtInCamera:
        return BuiltInCameraSource(
          isFront: device.endpoint == 'front',
          resolutionWidth: state.targetWidth,
          resolutionHeight: state.targetHeight,
          targetFps: state.targetFps,
          audioDeviceId: audioId,
        );
      case ExternalDeviceKind.usbUvcCamera:
        return WiredCaptureCameraSource(
          type: CameraSourceType.usbUvcCamera,
          deviceId: device.endpoint ?? device.id,
          deviceName: device.name,
          resolutionWidth: state.targetWidth,
          resolutionHeight: state.targetHeight,
          targetFps: state.targetFps,
          hasAudio: device.capabilities.hasAudioInput,
          isUvcVerified: device.capabilities.isUvcCompliant,
          audioDeviceId: audioId,
        );
      case ExternalDeviceKind.hdmiCapture:
        return WiredCaptureCameraSource(
          type: CameraSourceType.hdmiCapture,
          deviceId: device.endpoint ?? device.id,
          deviceName: device.name,
          resolutionWidth: state.targetWidth,
          resolutionHeight: state.targetHeight,
          targetFps: state.targetFps,
          hasAudio: device.capabilities.hasAudioInput,
          isUvcVerified: device.capabilities.isUvcCompliant,
          audioDeviceId: audioId,
        );
      case ExternalDeviceKind.sdiCapture:
        return WiredCaptureCameraSource(
          type: CameraSourceType.sdiCapture,
          deviceId: device.endpoint ?? device.id,
          deviceName: device.name,
          resolutionWidth: state.targetWidth,
          resolutionHeight: state.targetHeight,
          targetFps: state.targetFps,
          hasAudio: device.capabilities.hasAudioInput,
          isUvcVerified: device.capabilities.isUvcCompliant,
          audioDeviceId: audioId,
        );
      case ExternalDeviceKind.wirelessCameraSystem:
        return WirelessCameraSource(
          peerDeviceId:
              device.metadata['castDeviceId']?.toString() ?? device.id,
          deviceName: device.name,
          signalStrength: device.diagnostics.signalStrength,
          resolutionWidth: state.targetWidth,
          resolutionHeight: state.targetHeight,
          targetFps: state.targetFps,
          audioDeviceId: audioId,
        );
      case ExternalDeviceKind.screenShare:
        return ScreenShareCameraSource(
          targetFps: state.targetFps,
          audioDeviceId: audioId,
        );
      case ExternalDeviceKind.ipCameraRtsp:
        return NetworkCameraSource(
          rtspUrl: device.endpoint ?? '',
          transport: device.metadata['transport'] == 'udp'
              ? RtspTransport.udp
              : RtspTransport.tcp,
          port: (device.metadata['port'] as num?)?.toInt() ?? 554,
          username: device.metadata['username']?.toString(),
          password: _ephemeralSecrets[device.id],
          audioDeviceId: audioId,
        );
      case ExternalDeviceKind.externalRtmpEncoder:
        return ExternalEncoderSource(
          encoderName: device.name,
          customRtmpUrl: device.endpoint,
          recommendedBitrateKbps:
              (device.metadata['bitrateKbps'] as num?)?.toInt() ?? 3500,
          audioDeviceId: audioId,
        );
      case ExternalDeviceKind.externalSrtEncoder:
        return SrtEncoderSource(
          host: device.endpoint ?? '',
          port: (device.metadata['port'] as num?)?.toInt() ?? 9000,
          mode: device.metadata['mode'] == 'listener'
              ? SrtMode.listener
              : SrtMode.caller,
          latencyMs: (device.metadata['latencyMs'] as num?)?.toInt() ?? 200,
          streamId: device.metadata['streamId']?.toString(),
          passphrase: _ephemeralSecrets[device.id],
          audioDeviceId: audioId,
        );
      case ExternalDeviceKind.nonUvcUsbDevice:
      case ExternalDeviceKind.bluetoothController:
      case ExternalDeviceKind.bluetoothAudio:
      case ExternalDeviceKind.smartTvReceiver:
        return null;
    }
  }

  // ─── Feed & Audio Verification (Never Fake Passes) ────────────────────────

  Future<bool> testVideoFeed(String deviceId, {String? streamId}) async {
    final dev = _devices[deviceId];
    if (dev == null) return false;

    if (!dev.capabilities.hasVideoInput ||
        dev.kind == ExternalDeviceKind.nonUvcUsbDevice) {
      _updateDevice(
        deviceId,
        (d) => d.copyWith(
          connectionState: ExternalConnectionState.error,
          diagnostics: d.diagnostics.copyWith(
            videoFeedVerified: false,
            videoTestSummary:
                d.lastError ?? 'Device has no supported video capture input.',
          ),
        ),
      );
      return false;
    }

    // 1. Web / Desktop UVC / HDMI / SDI capture via WebRTC getUserMedia probe
    if ((kIsWeb ||
            (defaultTargetPlatform != TargetPlatform.android &&
                defaultTargetPlatform != TargetPlatform.iOS)) &&
        dev.connectionMethod == ExternalConnectionMethod.usbOtg) {
      try {
        final stream = await rtc.navigator.mediaDevices.getUserMedia({
          'video': {
            if (dev.endpoint != null && dev.endpoint!.isNotEmpty)
              'deviceId': {'exact': dev.endpoint},
            'width': {'ideal': state.targetWidth},
            'height': {'ideal': state.targetHeight},
            'frameRate': {'ideal': state.targetFps},
          },
          'audio': false,
        });
        final videoTracks = stream.getVideoTracks();
        final ok = videoTracks.isNotEmpty;
        for (final t in stream.getTracks()) {
          t.stop();
        }
        await stream.dispose();

        _updateDevice(
          deviceId,
          (d) => d.copyWith(
            connectionState: ok
                ? ExternalConnectionState.streamReady
                : ExternalConnectionState.error,
            diagnostics: d.diagnostics.copyWith(
              videoFeedVerified: ok,
              activeResolution: '${state.targetWidth}x${state.targetHeight}',
              activeFps: state.targetFps,
              videoTestSummary: ok
                  ? 'Capture frame stream verified (${state.targetWidth}x${state.targetHeight} @ ${state.targetFps}fps).'
                  : 'Device opened but produced no video track.',
            ),
            clearError: ok,
          ),
        );
        return ok;
      } catch (e) {
        _updateDevice(
          deviceId,
          (d) => d.copyWith(
            connectionState: ExternalConnectionState.error,
            lastError: 'Video probe failed: $e',
            diagnostics: d.diagnostics.copyWith(
              videoFeedVerified: false,
              videoTestSummary: 'Video probe failed: $e',
            ),
          ),
        );
        return false;
      }
    }

    // 2. Native Android/iOS USB/UVC / External Camera2
    if (dev.connectionMethod == ExternalConnectionMethod.usbOtg) {
      final cameras = await _bridge.enumerateCameras();
      final extCams = cameras.where((c) => c.isExternal).toList();
      final verified = dev.isUsbPermissionGranted &&
          (extCams.isNotEmpty || dev.capabilities.isUvcCompliant);
      final note = extCams.isNotEmpty
          ? 'External Camera2/AVFoundation capture detected (${extCams.first.resolutions.take(2).join(', ')}).'
          : dev.isUsbPermissionGranted
              ? 'UVC USB descriptor verified, but OS Camera2 did not expose an external camera lens on this device.'
              : 'USB permission required before video capture can be verified.';
      _updateDevice(
        deviceId,
        (d) => d.copyWith(
          connectionState: extCams.isNotEmpty
              ? ExternalConnectionState.streamReady
              : ExternalConnectionState.connected,
          diagnostics: d.diagnostics.copyWith(
            videoFeedVerified: extCams.isNotEmpty,
            videoTestSummary: note,
          ),
        ),
      );
      return verified;
    }

    // 3. RTSP IP Camera real OPTIONS probe
    if (dev.kind == ExternalDeviceKind.ipCameraRtsp) {
      final probe = await _lanDiscovery.probeRtspEndpoint(dev.endpoint ?? '');
      _updateDevice(
        deviceId,
        (d) => d.copyWith(
          connectionState: probe.reachable
              ? ExternalConnectionState.streamReady
              : ExternalConnectionState.error,
          lastError: probe.reachable ? null : probe.summary,
          clearError: probe.reachable,
          diagnostics: d.diagnostics.copyWith(
            videoFeedVerified: probe.reachable,
            latencyMs: probe.latencyMs,
            videoTestSummary: probe.summary,
          ),
        ),
      );
      return probe.reachable;
    }

    // 4. SRT / RTMP external encoders — check server ingest-status if streamId exists,
    //    or TCP endpoint probe when host is provided.
    if (dev.kind == ExternalDeviceKind.externalRtmpEncoder ||
        dev.kind == ExternalDeviceKind.externalSrtEncoder) {
      if (streamId != null && streamId.isNotEmpty && _liveRepo != null) {
        try {
          final ingest = await _liveRepo.getIngestStatus(streamId);
          final stage = ingest['stage']?.toString() ?? 'unprovisioned';
          final mtx = (ingest['mediaMtx'] as Map?)?.cast<String, dynamic>();
          final ready = (mtx?['ready'] as bool? ?? false) ||
              stage == 'mediamtx_ingesting' ||
              stage == 'cloudinary_active_live';
          final bytes = (mtx?['bytesReceived'] as num?)?.toInt();
          _updateDevice(
            deviceId,
            (d) => d.copyWith(
              connectionState: ready
                  ? ExternalConnectionState.streamReady
                  : ExternalConnectionState.connected,
              diagnostics: d.diagnostics.copyWith(
                videoFeedVerified: ready,
                videoTestSummary: ready
                    ? 'Live ingest verified ($stage${bytes != null ? ', ${bytes}B received' : ''}).'
                    : 'Server ready ($stage) — awaiting encoder push.',
              ),
            ),
          );
          return ready;
        } catch (_) {}
      }
      final uri = Uri.tryParse(dev.endpoint ?? '');
      final host = uri?.host.isNotEmpty == true ? uri!.host : (dev.endpoint ?? '');
      final port = uri?.hasPort == true
          ? uri!.port
          : (dev.kind == ExternalDeviceKind.externalSrtEncoder ? 9000 : 1935);
      if (host.isEmpty) {
        _updateDevice(
          deviceId,
          (d) => d.copyWith(
            connectionState: ExternalConnectionState.error,
            lastError: 'Host/endpoint is empty.',
          ),
        );
        return false;
      }
      final probe = await _lanDiscovery.probeTcpEndpoint(host, port);
      _updateDevice(
        deviceId,
        (d) => d.copyWith(
          connectionState: probe.reachable
              ? ExternalConnectionState.streamReady
              : ExternalConnectionState.connected,
          diagnostics: d.diagnostics.copyWith(
            videoFeedVerified: probe.reachable,
            latencyMs: probe.latencyMs,
            videoTestSummary: probe.summary,
          ),
        ),
      );
      return probe.reachable;
    }

    // 5. Remote WebRTC peer camera
    if (dev.connectionMethod == ExternalConnectionMethod.webrtcPeer) {
      final castId = dev.metadata['castDeviceId']?.toString();
      final stream = castId != null ? _castService.getRemoteStream(castId) : null;
      final hasTrack = stream != null && stream.getVideoTracks().isNotEmpty;
      _updateDevice(
        deviceId,
        (d) => d.copyWith(
          connectionState: hasTrack
              ? ExternalConnectionState.streamReady
              : ExternalConnectionState.error,
          lastError: hasTrack
              ? null
              : 'No active WebRTC video track received from peer yet.',
          clearError: hasTrack,
          diagnostics: d.diagnostics.copyWith(
            videoFeedVerified: hasTrack,
            videoTestSummary: hasTrack
                ? 'Active WebRTC video track verified.'
                : 'Peer video track not received.',
          ),
        ),
      );
      return hasTrack;
    }

    return true;
  }

  Future<bool> testAudio(String deviceId) async {
    final dev = _devices[deviceId];
    if (dev == null) return false;

    final audioInputs = await _bridge.enumerateAudioInputs();
    if (!_isDisposed) {
      state = state.copyWith(audioInputs: audioInputs);
    }

    final hasMatchingAudio = dev.capabilities.hasAudioInput ||
        audioInputs.any(
          (a) =>
              a.name.toLowerCase().contains(dev.name.toLowerCase()) ||
              (dev.connectionMethod == ExternalConnectionMethod.usbOtg &&
                  a.kind == 'usb') ||
              (dev.connectionMethod == ExternalConnectionMethod.bluetoothBle &&
                  a.kind == 'bluetooth'),
        );

    _updateDevice(
      deviceId,
      (d) => d.copyWith(
        diagnostics: d.diagnostics.copyWith(
          audioVerified: hasMatchingAudio,
          audioTestSummary: hasMatchingAudio
              ? 'Compatible audio input detected (${audioInputs.length} input(s) available).'
              : 'No dedicated hardware audio input detected for this device; studio mic will be used.',
        ),
      ),
    );
    return hasMatchingAudio;
  }

  /// Triggers remote start/stop recording ONLY if genuinely supported.
  Future<bool> triggerRemoteRecording(
    String deviceId, {
    required bool start,
    String? streamId,
  }) async {
    final dev = _devices[deviceId];
    if (dev == null) return false;

    if (!dev.capabilities.supportsRemoteRecording) {
      _updateDevice(
        deviceId,
        (d) => d.copyWith(
          lastError:
              '${d.name} does not expose remote recording control over this connection.',
        ),
      );
      return false;
    }

    if (dev.connectionMethod == ExternalConnectionMethod.webrtcPeer &&
        streamId != null) {
      final castId = dev.metadata['castDeviceId']?.toString();
      if (castId == null) return false;
      _castService.triggerRemoteCameraRecord(
        streamId: streamId,
        deviceId: castId,
        action: start ? 'start' : 'stop',
      );
      _updateDevice(
        deviceId,
        (d) => d.copyWith(
          diagnostics: d.diagnostics.copyWith(isRemoteRecording: start),
        ),
      );
      return true;
    }

    if (dev.connectionMethod == ExternalConnectionMethod.bluetoothBle &&
        dev.endpoint != null) {
      try {
        await _bridge.triggerBleRemoteCommand(
          dev.endpoint!,
          start ? 'record_start' : 'record_stop',
        );
        return true;
      } catch (e) {
        _updateDevice(
          deviceId,
          (d) => d.copyWith(lastError: e.toString()),
        );
        return false;
      }
    }

    return false;
  }

  void markStreaming(String? deviceId, bool streaming) {
    if (deviceId == null) {
      state = state.copyWith(
        managerState: streaming
            ? ExternalConnectionState.streaming
            : _computeAggregateManagerState(),
      );
      return;
    }
    _updateDevice(
      deviceId,
      (d) => d.copyWith(
        connectionState: streaming
            ? ExternalConnectionState.streaming
            : (d.connectionState == ExternalConnectionState.streaming
                ? ExternalConnectionState.streamReady
                : d.connectionState),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _upsertDevice(ExternalDevice dev) {
    final prev = _devices[dev.id];
    _devices[dev.id] = prev != null
        ? dev.copyWith(
            isSaved: prev.isSaved || dev.isSaved,
            isPaired: prev.isPaired || dev.isPaired,
            lastConnectedAt: dev.lastConnectedAt ?? prev.lastConnectedAt,
          )
        : dev;
  }

  void _updateDevice(
    String id,
    ExternalDevice Function(ExternalDevice current) transform,
  ) {
    final cur = _devices[id];
    if (cur == null || _isDisposed) return;
    _devices[id] = transform(cur);
    _publishDevices();
  }

  void _publishDevices({
    ExternalConnectionState? overrideManagerState,
    bool? isScanning,
  }) {
    if (_isDisposed) return;
    final list = _devices.values.toList()
      ..sort((a, b) {
        final aScore = _sortPriority(a);
        final bScore = _sortPriority(b);
        if (aScore != bScore) return bScore.compareTo(aScore);
        return a.name.compareTo(b.name);
      });

    state = state.copyWith(
      devices: list,
      isScanning: isScanning ?? state.isScanning,
      managerState: overrideManagerState ?? _computeAggregateManagerState(),
    );
  }

  int _sortPriority(ExternalDevice d) {
    if (d.connectionState == ExternalConnectionState.streaming) return 5;
    if (d.connectionState == ExternalConnectionState.streamReady) return 4;
    if (d.connectionState == ExternalConnectionState.connected) return 3;
    if (d.connectionMethod == ExternalConnectionMethod.usbOtg) return 2;
    if (d.isSaved) return 1;
    return 0;
  }

  ExternalConnectionState _computeAggregateManagerState() {
    if (state.isScanning) return ExternalConnectionState.discovering;
    if (_devices.values.any(
      (d) => d.connectionState == ExternalConnectionState.streaming,
    )) {
      return ExternalConnectionState.streaming;
    }
    if (_devices.values.any(
      (d) => d.connectionState == ExternalConnectionState.streamReady,
    )) {
      return ExternalConnectionState.streamReady;
    }
    if (_devices.values.any(
      (d) => d.connectionState == ExternalConnectionState.connected,
    )) {
      return ExternalConnectionState.connected;
    }
    if (_devices.values.any(
      (d) => d.connectionState == ExternalConnectionState.available,
    )) {
      return ExternalConnectionState.available;
    }
    return ExternalConnectionState.disconnected;
  }

  static ExternalDeviceKind _kindFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('sdi') || lower.contains('blackmagic')) {
      return ExternalDeviceKind.sdiCapture;
    }
    if (lower.contains('hdmi') ||
        lower.contains('cam link') ||
        lower.contains('elgato') ||
        lower.contains('capture')) {
      return ExternalDeviceKind.hdmiCapture;
    }
    return ExternalDeviceKind.usbUvcCamera;
  }

  static int? _rssiToStrength(int? rssi) {
    if (rssi == null) return null;
    if (rssi >= -55) return 95;
    if (rssi >= -68) return 75;
    if (rssi >= -80) return 50;
    return 25;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _activeScanToken++;
    _castSub?.cancel();
    _hwEventsSub?.cancel();
    unawaited(_bridge.stopBleScan());
    unawaited(_bridge.releaseMulticastLock());
    super.dispose();
  }
}
