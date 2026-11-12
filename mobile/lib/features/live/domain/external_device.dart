// lib/features/live/domain/external_device.dart
//
// Unified domain models for the External Device Connection Manager.
// Covers wired USB/UVC/HDMI/SDI capture, Bluetooth/BLE control & audio,
// Wi-Fi/LAN IP cameras & receivers, internet RTMP/SRT encoders, and remote
// WebRTC camera peers.

import 'package:flutter/material.dart';

/// Strict unified connection lifecycle state machine required across all
/// external cameras, capture devices, encoders, and receivers.
///
/// Lifecycle:
///   DISCONNECTED → DISCOVERING → AVAILABLE → CONNECTING → CONNECTED →
///   STREAM_READY → STREAMING → DISCONNECTED / ERROR
enum ExternalConnectionState {
  disconnected,
  discovering,
  available,
  connecting,
  connected,
  streamReady,
  streaming,
  error,
}

extension ExternalConnectionStateMeta on ExternalConnectionState {
  String get label {
    switch (this) {
      case ExternalConnectionState.disconnected:
        return 'Disconnected';
      case ExternalConnectionState.discovering:
        return 'Discovering…';
      case ExternalConnectionState.available:
        return 'Available';
      case ExternalConnectionState.connecting:
        return 'Connecting…';
      case ExternalConnectionState.connected:
        return 'Connected';
      case ExternalConnectionState.streamReady:
        return 'Stream Ready';
      case ExternalConnectionState.streaming:
        return 'Streaming';
      case ExternalConnectionState.error:
        return 'Error';
    }
  }

  Color color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (this) {
      case ExternalConnectionState.disconnected:
        return cs.onSurfaceVariant;
      case ExternalConnectionState.discovering:
      case ExternalConnectionState.connecting:
        return Colors.orange;
      case ExternalConnectionState.available:
        return Colors.blue;
      case ExternalConnectionState.connected:
        return Colors.teal;
      case ExternalConnectionState.streamReady:
        return Colors.green;
      case ExternalConnectionState.streaming:
        return Colors.red;
      case ExternalConnectionState.error:
        return cs.error;
    }
  }

  bool get isActiveConnection =>
      this == ExternalConnectionState.connected ||
      this == ExternalConnectionState.streamReady ||
      this == ExternalConnectionState.streaming;
}

/// Functional device classification.
enum ExternalDeviceKind {
  builtInCamera,
  usbUvcCamera,
  hdmiCapture,
  sdiCapture,
  nonUvcUsbDevice,
  bluetoothController,
  bluetoothAudio,
  ipCameraRtsp,
  wirelessCameraSystem,
  externalRtmpEncoder,
  externalSrtEncoder,
  smartTvReceiver,
  screenShare,
}

/// Physical or network connection method.
enum ExternalConnectionMethod {
  builtIn,
  usbOtg,
  bluetoothBle,
  wifiLan,
  internetIngest,
  webrtcPeer,
  systemCapture,
}

extension ExternalConnectionMethodMeta on ExternalConnectionMethod {
  String get label {
    switch (this) {
      case ExternalConnectionMethod.builtIn:
        return 'Built-in';
      case ExternalConnectionMethod.usbOtg:
        return 'USB / Capture';
      case ExternalConnectionMethod.bluetoothBle:
        return 'Bluetooth / BLE';
      case ExternalConnectionMethod.wifiLan:
        return 'Wi-Fi / LAN';
      case ExternalConnectionMethod.internetIngest:
        return 'Internet Ingest';
      case ExternalConnectionMethod.webrtcPeer:
        return 'Wireless WebRTC';
      case ExternalConnectionMethod.systemCapture:
        return 'Screen Capture';
    }
  }
}

/// Hardware & protocol capabilities honestly exposed by a device.
class ExternalDeviceCapabilities {
  final List<String> supportedVideoFormats;
  final List<String> supportedResolutions;
  final List<int> supportedFps;
  final bool hasVideoInput;
  final bool hasAudioInput;
  final int audioChannels;
  final bool supportsRemoteRecording;
  final bool supportsSdCardRecording;
  final bool supportsBatteryTelemetry;
  final bool supportsVideoPreview;
  final bool requiresUsbPermission;
  final bool isUvcCompliant;

  const ExternalDeviceCapabilities({
    this.supportedVideoFormats = const [],
    this.supportedResolutions = const ['1280x720'],
    this.supportedFps = const [30],
    this.hasVideoInput = true,
    this.hasAudioInput = false,
    this.audioChannels = 0,
    this.supportsRemoteRecording = false,
    this.supportsSdCardRecording = false,
    this.supportsBatteryTelemetry = false,
    this.supportsVideoPreview = false,
    this.requiresUsbPermission = false,
    this.isUvcCompliant = true,
  });

  Map<String, dynamic> toJson() => {
    'supportedVideoFormats': supportedVideoFormats,
    'supportedResolutions': supportedResolutions,
    'supportedFps': supportedFps,
    'hasVideoInput': hasVideoInput,
    'hasAudioInput': hasAudioInput,
    'audioChannels': audioChannels,
    'supportsRemoteRecording': supportsRemoteRecording,
    'supportsSdCardRecording': supportsSdCardRecording,
    'supportsBatteryTelemetry': supportsBatteryTelemetry,
    'supportsVideoPreview': supportsVideoPreview,
    'requiresUsbPermission': requiresUsbPermission,
    'isUvcCompliant': isUvcCompliant,
  };

  factory ExternalDeviceCapabilities.fromJson(Map<String, dynamic> json) =>
      ExternalDeviceCapabilities(
        supportedVideoFormats:
            (json['supportedVideoFormats'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        supportedResolutions:
            (json['supportedResolutions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['1280x720'],
        supportedFps:
            (json['supportedFps'] as List?)
                ?.whereType<num>()
                .map((e) => e.toInt())
                .toList() ??
            const [30],
        hasVideoInput: json['hasVideoInput'] as bool? ?? true,
        hasAudioInput: json['hasAudioInput'] as bool? ?? false,
        audioChannels: (json['audioChannels'] as num?)?.toInt() ?? 0,
        supportsRemoteRecording:
            json['supportsRemoteRecording'] as bool? ?? false,
        supportsSdCardRecording:
            json['supportsSdCardRecording'] as bool? ?? false,
        supportsBatteryTelemetry:
            json['supportsBatteryTelemetry'] as bool? ?? false,
        supportsVideoPreview: json['supportsVideoPreview'] as bool? ?? false,
        requiresUsbPermission:
            json['requiresUsbPermission'] as bool? ?? false,
        isUvcCompliant: json['isUvcCompliant'] as bool? ?? true,
      );
}

/// Live telemetry and verification results for an external device.
class ExternalDeviceDiagnostics {
  final int? bitrateKbps;
  final String? activeResolution;
  final int? activeFps;
  final int? latencyMs;
  final int? batteryPercent;
  final int? signalStrength;
  final bool? videoFeedVerified;
  final String? videoTestSummary;
  final bool? audioVerified;
  final String? audioTestSummary;
  final bool isRemoteRecording;

  const ExternalDeviceDiagnostics({
    this.bitrateKbps,
    this.activeResolution,
    this.activeFps,
    this.latencyMs,
    this.batteryPercent,
    this.signalStrength,
    this.videoFeedVerified,
    this.videoTestSummary,
    this.audioVerified,
    this.audioTestSummary,
    this.isRemoteRecording = false,
  });

  ExternalDeviceDiagnostics copyWith({
    int? bitrateKbps,
    String? activeResolution,
    int? activeFps,
    int? latencyMs,
    int? batteryPercent,
    int? signalStrength,
    bool? videoFeedVerified,
    String? videoTestSummary,
    bool? audioVerified,
    String? audioTestSummary,
    bool? isRemoteRecording,
  }) => ExternalDeviceDiagnostics(
    bitrateKbps: bitrateKbps ?? this.bitrateKbps,
    activeResolution: activeResolution ?? this.activeResolution,
    activeFps: activeFps ?? this.activeFps,
    latencyMs: latencyMs ?? this.latencyMs,
    batteryPercent: batteryPercent ?? this.batteryPercent,
    signalStrength: signalStrength ?? this.signalStrength,
    videoFeedVerified: videoFeedVerified ?? this.videoFeedVerified,
    videoTestSummary: videoTestSummary ?? this.videoTestSummary,
    audioVerified: audioVerified ?? this.audioVerified,
    audioTestSummary: audioTestSummary ?? this.audioTestSummary,
    isRemoteRecording: isRemoteRecording ?? this.isRemoteRecording,
  );
}

/// Discovered or saved external device managed by [ExternalDeviceManager].
class ExternalDevice {
  final String id;
  final String name;
  final String? manufacturer;
  final String? model;
  final ExternalDeviceKind kind;
  final ExternalConnectionMethod connectionMethod;
  final ExternalConnectionState connectionState;
  final ExternalDeviceCapabilities capabilities;
  final ExternalDeviceDiagnostics diagnostics;

  /// Connection endpoint or native identifier (e.g. USB deviceName, Camera2 ID,
  /// BLE address, RTSP URL without secret query params, SRT host:port, peerId).
  final String? endpoint;

  /// Optional non-secret metadata (e.g., transport=tcp, srtMode=caller, port=554).
  final Map<String, dynamic> metadata;

  final bool isPaired;
  final bool isSaved;
  final bool isUsbPermissionGranted;
  final String? lastError;
  final DateTime discoveredAt;
  final DateTime? lastConnectedAt;

  const ExternalDevice({
    required this.id,
    required this.name,
    this.manufacturer,
    this.model,
    required this.kind,
    required this.connectionMethod,
    this.connectionState = ExternalConnectionState.available,
    this.capabilities = const ExternalDeviceCapabilities(),
    this.diagnostics = const ExternalDeviceDiagnostics(),
    this.endpoint,
    this.metadata = const {},
    this.isPaired = false,
    this.isSaved = false,
    this.isUsbPermissionGranted = true,
    this.lastError,
    required this.discoveredAt,
    this.lastConnectedAt,
  });

  IconData get icon {
    switch (kind) {
      case ExternalDeviceKind.builtInCamera:
        return Icons.camera_alt_outlined;
      case ExternalDeviceKind.usbUvcCamera:
        return Icons.usb_rounded;
      case ExternalDeviceKind.hdmiCapture:
        return Icons.settings_input_hdmi_rounded;
      case ExternalDeviceKind.sdiCapture:
        return Icons.settings_input_component_rounded;
      case ExternalDeviceKind.nonUvcUsbDevice:
        return Icons.usb_off_rounded;
      case ExternalDeviceKind.bluetoothController:
      case ExternalDeviceKind.bluetoothAudio:
        return Icons.bluetooth_connected_rounded;
      case ExternalDeviceKind.ipCameraRtsp:
        return Icons.videocam_outlined;
      case ExternalDeviceKind.wirelessCameraSystem:
        return Icons.wifi_tethering_rounded;
      case ExternalDeviceKind.externalRtmpEncoder:
        return Icons.router_rounded;
      case ExternalDeviceKind.externalSrtEncoder:
        return Icons.speed_rounded;
      case ExternalDeviceKind.smartTvReceiver:
        return Icons.tv_rounded;
      case ExternalDeviceKind.screenShare:
        return Icons.screen_share_rounded;
    }
  }

  String get kindLabel {
    switch (kind) {
      case ExternalDeviceKind.builtInCamera:
        return 'Built-in Camera';
      case ExternalDeviceKind.usbUvcCamera:
        return 'USB / UVC Camera';
      case ExternalDeviceKind.hdmiCapture:
        return 'HDMI Capture';
      case ExternalDeviceKind.sdiCapture:
        return 'SDI Capture';
      case ExternalDeviceKind.nonUvcUsbDevice:
        return 'USB (Non-UVC)';
      case ExternalDeviceKind.bluetoothController:
        return 'Bluetooth Control';
      case ExternalDeviceKind.bluetoothAudio:
        return 'Bluetooth Audio';
      case ExternalDeviceKind.ipCameraRtsp:
        return 'IP Camera (RTSP)';
      case ExternalDeviceKind.wirelessCameraSystem:
        return 'Wireless Camera';
      case ExternalDeviceKind.externalRtmpEncoder:
        return 'RTMP Encoder';
      case ExternalDeviceKind.externalSrtEncoder:
        return 'SRT Encoder';
      case ExternalDeviceKind.smartTvReceiver:
        return 'Smart TV / Display';
      case ExternalDeviceKind.screenShare:
        return 'Screen Share';
    }
  }

  ExternalDevice copyWith({
    String? id,
    String? name,
    String? manufacturer,
    String? model,
    ExternalDeviceKind? kind,
    ExternalConnectionMethod? connectionMethod,
    ExternalConnectionState? connectionState,
    ExternalDeviceCapabilities? capabilities,
    ExternalDeviceDiagnostics? diagnostics,
    String? endpoint,
    Map<String, dynamic>? metadata,
    bool? isPaired,
    bool? isSaved,
    bool? isUsbPermissionGranted,
    String? lastError,
    bool clearError = false,
    DateTime? discoveredAt,
    DateTime? lastConnectedAt,
  }) => ExternalDevice(
    id: id ?? this.id,
    name: name ?? this.name,
    manufacturer: manufacturer ?? this.manufacturer,
    model: model ?? this.model,
    kind: kind ?? this.kind,
    connectionMethod: connectionMethod ?? this.connectionMethod,
    connectionState: connectionState ?? this.connectionState,
    capabilities: capabilities ?? this.capabilities,
    diagnostics: diagnostics ?? this.diagnostics,
    endpoint: endpoint ?? this.endpoint,
    metadata: metadata ?? this.metadata,
    isPaired: isPaired ?? this.isPaired,
    isSaved: isSaved ?? this.isSaved,
    isUsbPermissionGranted:
        isUsbPermissionGranted ?? this.isUsbPermissionGranted,
    lastError: clearError ? null : (lastError ?? this.lastError),
    discoveredAt: discoveredAt ?? this.discoveredAt,
    lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
  );

  /// Serializes device metadata for one-tap reconnection.
  /// Never persists raw passwords, stream keys, or passphrases.
  Map<String, dynamic> toSavedJson() {
    final safeMeta = Map<String, dynamic>.from(metadata)
      ..remove('password')
      ..remove('passphrase')
      ..remove('streamKey');
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'model': model,
      'kind': kind.name,
      'connectionMethod': connectionMethod.name,
      'endpoint': redactEndpoint(endpoint),
      'metadata': safeMeta,
      'isPaired': isPaired,
      'discoveredAt': discoveredAt.toIso8601String(),
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    };
  }

  static String? redactEndpoint(String? raw) {
    if (raw == null) return null;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.userInfo.isNotEmpty) {
      return uri.replace(userInfo: '').toString();
    }
    return raw;
  }

  factory ExternalDevice.fromSavedJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'externalRtmpEncoder';
    final methodName = json['connectionMethod'] as String? ?? 'internetIngest';
    return ExternalDevice(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Saved Device',
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      kind: ExternalDeviceKind.values.firstWhere(
        (e) => e.name == kindName,
        orElse: () => ExternalDeviceKind.externalRtmpEncoder,
      ),
      connectionMethod: ExternalConnectionMethod.values.firstWhere(
        (e) => e.name == methodName,
        orElse: () => ExternalConnectionMethod.internetIngest,
      ),
      connectionState: ExternalConnectionState.disconnected,
      endpoint: json['endpoint'] as String?,
      metadata:
          (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      isPaired: json['isPaired'] as bool? ?? false,
      isSaved: true,
      discoveredAt:
          DateTime.tryParse(json['discoveredAt'] as String? ?? '') ??
          DateTime.now(),
      lastConnectedAt: DateTime.tryParse(
        json['lastConnectedAt'] as String? ?? '',
      ),
    );
  }
}

/// Discovered audio input option (built-in mic, USB audio, Bluetooth HFP, wired).
class AudioInputOption {
  final String id;
  final String name;
  final String kind; // builtin, usb, bluetooth, wired, other
  final List<int> sampleRates;
  final List<int> channelCounts;

  const AudioInputOption({
    required this.id,
    required this.name,
    required this.kind,
    this.sampleRates = const [],
    this.channelCounts = const [],
  });

  factory AudioInputOption.fromMap(Map<String, dynamic> map) =>
      AudioInputOption(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Audio Input',
        kind: map['kind']?.toString() ?? 'other',
        sampleRates:
            (map['sampleRates'] as List?)
                ?.whereType<num>()
                .map((e) => e.toInt())
                .toList() ??
            const [],
        channelCounts:
            (map['channelCounts'] as List?)
                ?.whereType<num>()
                .map((e) => e.toInt())
                .toList() ??
            const [],
      );
}

/// Honest runtime report of platform & hardware connectivity capabilities.
class PlatformConnectivityCapabilities {
  final String platform;
  final bool usbHostSupported;
  final bool externalCameraApiSupported;
  final bool bluetoothSupported;
  final bool bluetoothEnabled;
  final bool bleSupported;
  final bool wifiMulticastSupported;
  final bool screenCaptureSupported;
  final bool rawRtspProbeSupported;
  final String? usbNote;
  final String? bluetoothNote;
  final String? networkNote;

  const PlatformConnectivityCapabilities({
    required this.platform,
    this.usbHostSupported = false,
    this.externalCameraApiSupported = false,
    this.bluetoothSupported = false,
    this.bluetoothEnabled = false,
    this.bleSupported = false,
    this.wifiMulticastSupported = false,
    this.screenCaptureSupported = true,
    this.rawRtspProbeSupported = true,
    this.usbNote,
    this.bluetoothNote,
    this.networkNote,
  });

  factory PlatformConnectivityCapabilities.webDefaults() =>
      const PlatformConnectivityCapabilities(
        platform: 'web',
        usbHostSupported: true, // via browser getUserMedia / enumerateDevices
        externalCameraApiSupported: true,
        bluetoothSupported: false,
        bluetoothEnabled: false,
        bleSupported: false,
        wifiMulticastSupported: false,
        screenCaptureSupported: true,
        rawRtspProbeSupported: false,
        usbNote:
            'Browser enumerates UVC webcams and USB HDMI/SDI capture cards via MediaDevices API after camera permission.',
        bluetoothNote:
            'Browser background BLE scanning is restricted; use Bluetooth audio via OS settings or use native mobile.',
        networkNote:
            'Browsers cannot open raw UDP SSDP or direct RTSP/SRT sockets; use WHIP or an external encoder pushing to RTMP.',
      );
}
