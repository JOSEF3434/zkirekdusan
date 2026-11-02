// lib/features/live/domain/cast_device.dart
//
// Cast device domain models — covers all device-casting scenarios:
//  1. Smart TV (Chromecast, AirPlay, DLNA/UPnP)
//  2. Remote Phone Camera (another phone acting as a wireless camera via WebRTC)
//  3. Screen Share (broadcasting the phone screen or a connected display)
//  4. Wired / USB Camera (UVC-compatible USB webcam connected to device)
//  5. Mirror to External Display (HDMI out or AirPlay mirroring for monitoring)

import 'package:flutter/material.dart';

// ─── Cast Protocol ─────────────────────────────────────────────────────────────

/// Underlying transport / discovery protocol for the cast session.
enum CastProtocol {
  /// Google Cast SDK — Chromecast, Chromecast-built-in TVs, Nest Hub, etc.
  chromecast,

  /// Apple AirPlay 2 — Apple TV, AirPlay-capable smart TVs, HomePod.
  airplay,

  /// DLNA/UPnP (SSDP discovery) — generic smart TVs, projectors, monitors.
  dlna,

  /// Proprietary WebRTC P2P — another phone/tablet running the app in "Camera" mode.
  remotePeerCamera,

  /// System screen capture API — device screen or connected external display.
  screenCapture,

  /// USB Video Class (UVC) — wired USB camera / webcam.
  uvcUsb,

  /// HDMI-in / capture card connected via OTG adapter.
  hdmiCapture,
}

// ─── Cast Device Type ──────────────────────────────────────────────────────────

enum CastDeviceType {
  /// Smart TV or streaming dongle that can receive the broadcast for monitoring.
  smartTv,

  /// Another phone / tablet running the app in "Remote Camera" mode.
  remoteCamera,

  /// The local device's own screen (for PiP/monitoring on external monitor).
  screenShare,

  /// A wired USB camera (UVC webcam / capture card).
  usbCamera,
}

// ─── Cast Session Status ──────────────────────────────────────────────────────

enum CastSessionStatus {
  /// Device was discovered but not yet connected.
  discovered,

  /// Pairing / handshake in progress.
  pairing,

  /// Fully connected and streaming.
  connected,

  /// Connection lost but attempting to recover.
  reconnecting,

  /// Session intentionally or unexpectedly terminated.
  disconnected,

  /// Error state — details in [CastDevice.lastError].
  error,
}

// ─── Cast Device Model ────────────────────────────────────────────────────────

/// Represents a single cast-capable device visible to the Live Studio.
class CastDevice {
  /// Unique runtime identifier (may be MAC, UDN, or peer WebRTC session ID).
  final String id;

  /// Human-readable display name (e.g. "Living Room TV", "iPhone 14 – Sara").
  final String name;

  /// Optional model/manufacturer hint (e.g. "Samsung QLED 4K").
  final String? model;

  /// Protocol used to communicate with this device.
  final CastProtocol protocol;

  /// Functional category of the device.
  final CastDeviceType type;

  /// Current connection state.
  final CastSessionStatus status;

  /// Signal strength 0-100 for wireless devices (null = wired / unknown).
  final int? signalStrength;

  /// Optional IP address of the device on the LAN.
  final String? ipAddress;

  /// Whether this remote camera is currently the active "on-air" source.
  final bool isActiveSource;

  /// Thumbnail / preview URL for remote cameras (updated periodically).
  final String? previewThumbnailUrl;

  /// Last error message, if [status] == [CastSessionStatus.error].
  final String? lastError;

  /// When this device was first discovered (for sorting).
  final DateTime discoveredAt;

  const CastDevice({
    required this.id,
    required this.name,
    this.model,
    required this.protocol,
    required this.type,
    this.status = CastSessionStatus.discovered,
    this.signalStrength,
    this.ipAddress,
    this.isActiveSource = false,
    this.previewThumbnailUrl,
    this.lastError,
    required this.discoveredAt,
  });

  CastDevice copyWith({
    String? id,
    String? name,
    String? model,
    CastProtocol? protocol,
    CastDeviceType? type,
    CastSessionStatus? status,
    int? signalStrength,
    String? ipAddress,
    bool? isActiveSource,
    String? previewThumbnailUrl,
    String? lastError,
    DateTime? discoveredAt,
  }) =>
      CastDevice(
        id: id ?? this.id,
        name: name ?? this.name,
        model: model ?? this.model,
        protocol: protocol ?? this.protocol,
        type: type ?? this.type,
        status: status ?? this.status,
        signalStrength: signalStrength ?? this.signalStrength,
        ipAddress: ipAddress ?? this.ipAddress,
        isActiveSource: isActiveSource ?? this.isActiveSource,
        previewThumbnailUrl: previewThumbnailUrl ?? this.previewThumbnailUrl,
        lastError: lastError ?? this.lastError,
        discoveredAt: discoveredAt ?? this.discoveredAt,
      );

  // ─── Helpers ────────────────────────────────────────────────────────────────

  IconData get icon {
    switch (type) {
      case CastDeviceType.smartTv:
        return Icons.tv_rounded;
      case CastDeviceType.remoteCamera:
        return Icons.phone_android_rounded;
      case CastDeviceType.screenShare:
        return Icons.screen_share_rounded;
      case CastDeviceType.usbCamera:
        return Icons.usb_rounded;
    }
  }

  String get protocolLabel {
    switch (protocol) {
      case CastProtocol.chromecast:
        return 'Chromecast';
      case CastProtocol.airplay:
        return 'AirPlay';
      case CastProtocol.dlna:
        return 'DLNA';
      case CastProtocol.remotePeerCamera:
        return 'Wireless Camera';
      case CastProtocol.screenCapture:
        return 'Screen Share';
      case CastProtocol.uvcUsb:
        return 'USB Camera';
      case CastProtocol.hdmiCapture:
        return 'HDMI Capture';
    }
  }

  Color statusColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case CastSessionStatus.connected:
        return Colors.green;
      case CastSessionStatus.pairing:
        return Colors.orange;
      case CastSessionStatus.reconnecting:
        return Colors.amber;
      case CastSessionStatus.error:
        return cs.error;
      default:
        return cs.onSurfaceVariant;
    }
  }

  String get statusLabel {
    switch (status) {
      case CastSessionStatus.discovered:
        return 'Tap to Connect';
      case CastSessionStatus.pairing:
        return 'Pairing…';
      case CastSessionStatus.connected:
        return 'Connected';
      case CastSessionStatus.reconnecting:
        return 'Reconnecting…';
      case CastSessionStatus.disconnected:
        return 'Disconnected';
      case CastSessionStatus.error:
        return 'Error';
    }
  }
}

// ─── Cast Source domain extensions ───────────────────────────────────────────
// These extend camera_source.dart enums without creating circular imports.

/// Source type representing a remote phone camera cast session.
class RemotePhoneCameraSource {
  final String peerSessionId;
  final String peerDeviceName;
  final String signalingToken;

  const RemotePhoneCameraSource({
    required this.peerSessionId,
    required this.peerDeviceName,
    required this.signalingToken,
  });
}

/// Source type representing the local device screen capture.
class ScreenCaptureSource {
  /// If null, captures the entire device screen. Otherwise captures a
  /// specific window or display index (platform-dependent).
  final int? displayIndex;
  final int targetFps;
  final int maxBitrateKbps;

  const ScreenCaptureSource({
    this.displayIndex,
    this.targetFps = 30,
    this.maxBitrateKbps = 4000,
  });
}

