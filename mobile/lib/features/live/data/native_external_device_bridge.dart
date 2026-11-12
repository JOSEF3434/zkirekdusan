// lib/features/live/data/native_external_device_bridge.dart
//
// Platform-aware hardware bridge for wired USB/UVC/HDMI/SDI capture devices,
// external Camera2/AVCaptureDevice enumeration, audio inputs, Bluetooth/BLE
// discovery & GATT telemetry, and Wi-Fi multicast locks.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:mobile/features/live/domain/external_device.dart';

class NativeUsbDeviceInfo {
  final String deviceName;
  final String displayName;
  final int? vendorId;
  final int? productId;
  final String? manufacturerName;
  final String? productName;
  final bool hasPermission;
  final bool isUvc;
  final bool hasAudio;
  final String classification; // uvcCamera, hdmiCapture, sdiCapture, usbAudio, nonUvcCamera, unsupportedUsb
  final String? nonUvcReason;

  const NativeUsbDeviceInfo({
    required this.deviceName,
    required this.displayName,
    this.vendorId,
    this.productId,
    this.manufacturerName,
    this.productName,
    required this.hasPermission,
    required this.isUvc,
    required this.hasAudio,
    required this.classification,
    this.nonUvcReason,
  });

  factory NativeUsbDeviceInfo.fromMap(Map<String, dynamic> map) =>
      NativeUsbDeviceInfo(
        deviceName: map['deviceName']?.toString() ?? '',
        displayName: map['displayName']?.toString() ?? 'USB Device',
        vendorId: (map['vendorId'] as num?)?.toInt(),
        productId: (map['productId'] as num?)?.toInt(),
        manufacturerName: map['manufacturerName']?.toString(),
        productName: map['productName']?.toString(),
        hasPermission: map['hasPermission'] as bool? ?? false,
        isUvc: map['isUvc'] as bool? ?? false,
        hasAudio: map['hasAudio'] as bool? ?? false,
        classification: map['classification']?.toString() ?? 'unsupportedUsb',
        nonUvcReason: map['nonUvcReason']?.toString(),
      );
}

class NativeCameraDescriptor {
  final String cameraId;
  final String? name;
  final String facing; // front, back, external, unknown
  final bool isExternal;
  final List<String> resolutions;
  final List<int> supportedFps;

  const NativeCameraDescriptor({
    required this.cameraId,
    this.name,
    required this.facing,
    required this.isExternal,
    this.resolutions = const [],
    this.supportedFps = const [],
  });

  factory NativeCameraDescriptor.fromMap(Map<String, dynamic> map) =>
      NativeCameraDescriptor(
        cameraId: map['cameraId']?.toString() ?? '',
        name: map['name']?.toString(),
        facing: map['facing']?.toString() ?? 'unknown',
        isExternal: map['isExternal'] as bool? ?? false,
        resolutions:
            (map['resolutions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        supportedFps:
            (map['supportedFps'] as List?)
                ?.whereType<num>()
                .map((e) => e.toInt())
                .toList() ??
            const [],
      );
}

class NativeBluetoothDeviceInfo {
  final String address;
  final String name;
  final int? rssi;
  final bool paired;
  final bool connected;

  const NativeBluetoothDeviceInfo({
    required this.address,
    required this.name,
    this.rssi,
    this.paired = false,
    this.connected = false,
  });

  factory NativeBluetoothDeviceInfo.fromMap(Map<String, dynamic> map) =>
      NativeBluetoothDeviceInfo(
        address: map['address']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Bluetooth Device',
        rssi: (map['rssi'] as num?)?.toInt(),
        paired: map['paired'] as bool? ?? false,
        connected: map['connected'] as bool? ?? false,
      );
}

class NativeExternalDeviceBridge {
  static const MethodChannel _method =
      MethodChannel('com.zkirekdusan/external_devices');
  static const EventChannel _events =
      EventChannel('com.zkirekdusan/external_devices_events');

  Stream<Map<String, dynamic>>? _cachedEventStream;

  bool get _isMobileNative =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Live stream of USB attach/detach and BLE scan/status events.
  Stream<Map<String, dynamic>> get hardwareEvents {
    if (!_isMobileNative) {
      return const Stream.empty();
    }
    _cachedEventStream ??= _events
        .receiveBroadcastStream()
        .map((e) => (e as Map).cast<String, dynamic>())
        .handleError((_) {});
    return _cachedEventStream!;
  }

  /// Reports platform hardware/API capabilities honestly.
  Future<PlatformConnectivityCapabilities> getPlatformCapabilities() async {
    if (kIsWeb) {
      return PlatformConnectivityCapabilities.webDefaults();
    }
    if (!_isMobileNative) {
      return PlatformConnectivityCapabilities(
        platform: defaultTargetPlatform.name,
        usbHostSupported: true,
        externalCameraApiSupported: true,
        bluetoothSupported: false,
        bluetoothEnabled: false,
        bleSupported: false,
        wifiMulticastSupported: true,
        screenCaptureSupported: true,
        rawRtspProbeSupported: true,
        usbNote:
            'Desktop enumerates USB UVC webcams, HDMI-to-USB, and SDI-to-USB capture devices via WebRTC MediaDevices.',
        bluetoothNote:
            'Desktop BLE camera control is not bound; use OS Bluetooth audio settings.',
      );
    }

    try {
      final raw = await _method.invokeMapMethod<String, dynamic>(
        'getPlatformCapabilities',
      );
      final map = raw ?? const <String, dynamic>{};
      final platform = map['platform']?.toString() ?? defaultTargetPlatform.name;
      final usbHost = map['usbHostSupported'] as bool? ?? false;
      final extCam = map['externalCamera2Supported'] as bool? ?? false;
      return PlatformConnectivityCapabilities(
        platform: platform,
        usbHostSupported: usbHost,
        externalCameraApiSupported: extCam,
        bluetoothSupported: map['bluetoothSupported'] as bool? ?? false,
        bluetoothEnabled: map['bluetoothEnabled'] as bool? ?? false,
        bleSupported: map['bleSupported'] as bool? ?? false,
        wifiMulticastSupported: map['wifiMulticastSupported'] as bool? ?? true,
        screenCaptureSupported: map['screenCaptureSupported'] as bool? ?? true,
        rawRtspProbeSupported: true,
        usbNote: platform == 'ios'
            ? (extCam
                  ? 'iOS 17+ supports external UVC USB-C capture devices via AVFoundation.'
                  : 'iOS versions prior to 17 do not support generic USB UVC video input.')
            : (usbHost
                  ? 'USB Host mode active. Cameras must expose UVC video output or use an HDMI/SDI-to-USB capture card.'
                  : 'This device does not report Android USB Host mode.'),
        bluetoothNote:
            'Bluetooth/BLE supports device pairing, battery/status telemetry, and compatible audio or control profiles (not live HD video).',
        networkNote:
            'Supports LAN SSDP discovery, RTSP TCP/UDP reachability checks, SRT, and external RTMP encoders.',
      );
    } catch (_) {
      return PlatformConnectivityCapabilities(
        platform: defaultTargetPlatform.name,
      );
    }
  }

  /// Enumerate USB devices on Android/iOS native, or WebRTC video inputs on Web/Desktop.
  Future<List<NativeUsbDeviceInfo>> enumerateUsbDevices() async {
    if (kIsWeb || !_isMobileNative) {
      return _enumerateWebRtcVideoDevicesAsUsb();
    }
    try {
      final list = await _method.invokeListMethod<dynamic>('enumerateUsbDevices');
      if (list == null) return const [];
      return list
          .whereType<Map>()
          .map((m) => NativeUsbDeviceInfo.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Uses WebRTC MediaDevices.enumerateDevices() on Web & Desktop to discover
  /// real USB UVC cameras, HDMI capture cards, and SDI capture cards.
  Future<List<NativeUsbDeviceInfo>> _enumerateWebRtcVideoDevicesAsUsb() async {
    try {
      final devices = await rtc.navigator.mediaDevices.enumerateDevices();
      final videoInputs =
          devices.where((d) => d.kind == 'videoinput').toList();
      final audioInputs =
          devices.where((d) => d.kind == 'audioinput').toList();
      final results = <NativeUsbDeviceInfo>[];

      for (int i = 0; i < videoInputs.length; i++) {
        final d = videoInputs[i];
        final label = d.label.trim().isNotEmpty
            ? d.label.trim()
            : 'Camera ${i + 1}';
        final lower = label.toLowerCase();
        // Identify capture hardware vs standard webcam
        final classification = _classifyCaptureLabel(lower);
        final hasMatchingAudio = audioInputs.any(
          (a) =>
              a.groupId != null &&
              a.groupId!.isNotEmpty &&
              a.groupId == d.groupId,
        );
        results.add(
          NativeUsbDeviceInfo(
            deviceName: d.deviceId,
            displayName: label,
            hasPermission: d.label.trim().isNotEmpty,
            isUvc: true,
            hasAudio: hasMatchingAudio,
            classification: classification,
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  static String _classifyCaptureLabel(String lower) {
    if (lower.contains('sdi') || lower.contains('blackmagic')) {
      return 'sdiCapture';
    }
    if (lower.contains('hdmi') ||
        lower.contains('cam link') ||
        lower.contains('elgato') ||
        lower.contains('avermedia') ||
        lower.contains('magewell') ||
        lower.contains('capture') ||
        lower.contains('usb video')) {
      return 'hdmiCapture';
    }
    return 'uvcCamera';
  }

  Future<bool> requestUsbPermission(String deviceName) async {
    if (!_isMobileNative) return true;
    try {
      final granted = await _method.invokeMethod<bool>(
        'requestUsbPermission',
        {'deviceName': deviceName},
      );
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<NativeCameraDescriptor>> enumerateCameras() async {
    if (!_isMobileNative) {
      try {
        final devices = await rtc.navigator.mediaDevices.enumerateDevices();
        return devices
            .where((d) => d.kind == 'videoinput')
            .map(
              (d) => NativeCameraDescriptor(
                cameraId: d.deviceId,
                name: d.label.isNotEmpty ? d.label : 'Video Device',
                facing: 'external',
                isExternal: true,
                resolutions: const ['1920x1080', '1280x720'],
                supportedFps: const [30, 60],
              ),
            )
            .toList();
      } catch (_) {
        return const [];
      }
    }
    try {
      final list = await _method.invokeListMethod<dynamic>(
        'enumerateExternalCameras',
      );
      if (list == null) return const [];
      return list
          .whereType<Map>()
          .map((m) => NativeCameraDescriptor.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AudioInputOption>> enumerateAudioInputs() async {
    if (!_isMobileNative) {
      try {
        final devices = await rtc.navigator.mediaDevices.enumerateDevices();
        return devices
            .where((d) => d.kind == 'audioinput')
            .map(
              (d) => AudioInputOption(
                id: d.deviceId,
                name: d.label.isNotEmpty ? d.label : 'Microphone',
                kind: d.label.toLowerCase().contains('usb')
                    ? 'usb'
                    : d.label.toLowerCase().contains('bluetooth')
                    ? 'bluetooth'
                    : 'builtin',
              ),
            )
            .toList();
      } catch (_) {
        return const [];
      }
    }
    try {
      final list = await _method.invokeListMethod<dynamic>(
        'enumerateAudioInputs',
      );
      if (list == null) return const [];
      return list
          .whereType<Map>()
          .map((m) => AudioInputOption.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<NativeBluetoothDeviceInfo>> getBondedBluetoothDevices() async {
    if (!_isMobileNative) return const [];
    try {
      final list = await _method.invokeListMethod<dynamic>(
        'getBondedBluetoothDevices',
      );
      if (list == null) return const [];
      return list
          .whereType<Map>()
          .map((m) => NativeBluetoothDeviceInfo.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> startBleScan({int timeoutMs = 8000}) async {
    if (!_isMobileNative) return;
    await _method.invokeMethod('startBleScan', {'timeoutMs': timeoutMs});
  }

  Future<void> stopBleScan() async {
    if (!_isMobileNative) return;
    try {
      await _method.invokeMethod('stopBleScan');
    } catch (_) {}
  }

  Future<Map<String, dynamic>> connectBleDevice(String address) async {
    if (!_isMobileNative) {
      throw UnsupportedError('BLE control requires native Android or iOS.');
    }
    final res = await _method.invokeMapMethod<String, dynamic>(
      'connectBleDevice',
      {'address': address},
    );
    return res ?? const {'connected': false};
  }

  Future<void> disconnectBleDevice(String address) async {
    if (!_isMobileNative) return;
    try {
      await _method.invokeMethod('disconnectBleDevice', {'address': address});
    } catch (_) {}
  }

  Future<Map<String, dynamic>> readBleDeviceStatus(String address) async {
    if (!_isMobileNative) return const {'connected': false};
    try {
      final res = await _method.invokeMapMethod<String, dynamic>(
        'readBleDeviceStatus',
        {'address': address},
      );
      return res ?? const {'connected': false};
    } catch (_) {
      return const {'connected': false};
    }
  }

  Future<void> triggerBleRemoteCommand(String address, String command) async {
    if (!_isMobileNative) {
      throw UnsupportedError('BLE commands require native Android or iOS.');
    }
    await _method.invokeMethod('triggerBleRemoteCommand', {
      'address': address,
      'command': command,
    });
  }

  Future<void> acquireMulticastLock() async {
    if (!_isMobileNative || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _method.invokeMethod('acquireMulticastLock');
    } catch (_) {}
  }

  Future<void> releaseMulticastLock() async {
    if (!_isMobileNative || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _method.invokeMethod('releaseMulticastLock');
    } catch (_) {}
  }
}
