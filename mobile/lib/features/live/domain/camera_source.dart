// lib/features/live/domain/camera_source.dart
//
// Camera & Encoder Source domain models for live broadcast capture.
//
// Supports:
// 1. Built-in Camera: Device front/back camera (phone/webcam).
// 2. External Hardware Encoder: ATEM Mini, OBS Studio, vMix, Teradek pushing RTMP directly.
// 3. Network Camera: RTSP IP Camera on local LAN or WAN (e.g., PTZ cameras, security cameras).
// 4. SRT Broadcast Encoder: Secure Reliable Transport (caller/listener) low-latency stream.

import 'package:flutter/material.dart';

/// Available camera and video encoder source types for broadcasting.
enum CameraSourceType {
  /// Local device camera (front or back) captured via native camera/WHIP.
  builtIn,

  /// External hardware/software encoder (ATEM Mini, OBS Studio, vMix, Teradek, Yolobox)
  /// pushing RTMP directly to the ingest server. Studio acts as monitor & control desk.
  externalEncoder,

  /// Network/IP camera streaming RTSP over TCP/UDP on local network or public IP.
  networkCamera,

  /// Secure Reliable Transport (SRT) encoder operating in caller or listener mode.
  srtEncoder,
}

/// Transport protocol for RTSP connections.
enum RtspTransport {
  /// TCP interleaved (RFC 2326) — recommended for reliable transmission through firewalls.
  tcp,

  /// UDP unicast — lower latency but subject to packet drop and firewall traversal issues.
  udp,
}

/// Operating mode for SRT connections.
enum SrtMode {
  /// Mobile studio / server acts as caller (connects to remote encoder listener).
  caller,

  /// Mobile studio / server acts as listener (waits for encoder to call in).
  listener,
}

/// Abstract representation of any video source configurable in the Live Studio.
abstract class CameraSource {
  final CameraSourceType type;
  final String label;
  final String subtitle;
  final IconData icon;

  /// Whether the phone itself runs local capture (camera + mic hardware).
  /// False for external encoders where media is sent directly to the server.
  final bool requiresLocalHardware;

  const CameraSource({
    required this.type,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.requiresLocalHardware,
  });
}

/// Built-in mobile device camera or desktop webcam.
class BuiltInCameraSource extends CameraSource {
  final bool isFront;
  final int resolutionWidth;
  final int resolutionHeight;
  final int targetFps;

  const BuiltInCameraSource({
    this.isFront = true,
    this.resolutionWidth = 1280,
    this.resolutionHeight = 720,
    this.targetFps = 30,
  }) : super(
          type: CameraSourceType.builtIn,
          label: 'Device Camera',
          subtitle: 'Front or rear camera on this device',
          icon: Icons.camera_alt_outlined,
          requiresLocalHardware: true,
        );

  BuiltInCameraSource copyWith({
    bool? isFront,
    int? resolutionWidth,
    int? resolutionHeight,
    int? targetFps,
  }) =>
      BuiltInCameraSource(
        isFront: isFront ?? this.isFront,
        resolutionWidth: resolutionWidth ?? this.resolutionWidth,
        resolutionHeight: resolutionHeight ?? this.resolutionHeight,
        targetFps: targetFps ?? this.targetFps,
      );
}

/// External hardware or software encoder pushing RTMP directly to ingest.
class ExternalEncoderSource extends CameraSource {
  final String encoderName;
  final String? customRtmpUrl;
  final int recommendedBitrateKbps;
  final int keyframeIntervalSeconds;

  const ExternalEncoderSource({
    this.encoderName = 'OBS / ATEM Mini',
    this.customRtmpUrl,
    this.recommendedBitrateKbps = 3500,
    this.keyframeIntervalSeconds = 2,
  }) : super(
          type: CameraSourceType.externalEncoder,
          label: 'Hardware / Software Encoder',
          subtitle: 'OBS, ATEM Mini, vMix, Teradek pushing directly to RTMP',
          icon: Icons.settings_input_hdmi_rounded,
          requiresLocalHardware: false,
        );

  ExternalEncoderSource copyWith({
    String? encoderName,
    String? customRtmpUrl,
    int? recommendedBitrateKbps,
    int? keyframeIntervalSeconds,
  }) =>
      ExternalEncoderSource(
        encoderName: encoderName ?? this.encoderName,
        customRtmpUrl: customRtmpUrl ?? this.customRtmpUrl,
        recommendedBitrateKbps:
            recommendedBitrateKbps ?? this.recommendedBitrateKbps,
        keyframeIntervalSeconds:
            keyframeIntervalSeconds ?? this.keyframeIntervalSeconds,
      );
}

/// Network IP Camera streaming RTSP (Real-Time Streaming Protocol).
class NetworkCameraSource extends CameraSource {
  final String rtspUrl;
  final RtspTransport transport;
  final int port;
  final String? username;
  final String? password;

  const NetworkCameraSource({
    this.rtspUrl = '',
    this.transport = RtspTransport.tcp,
    this.port = 554,
    this.username,
    this.password,
  }) : super(
          type: CameraSourceType.networkCamera,
          label: 'IP Camera (RTSP)',
          subtitle: 'PTZ or network camera streaming via RTSP',
          icon: Icons.videocam_outlined,
          requiresLocalHardware: false,
        );

  /// Validates RTSP URL format (must begin with rtsp:// or rtsps://).
  static bool isValidRtspUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    return uri.scheme == 'rtsp' || uri.scheme == 'rtsps';
  }

  NetworkCameraSource copyWith({
    String? rtspUrl,
    RtspTransport? transport,
    int? port,
    String? username,
    String? password,
  }) =>
      NetworkCameraSource(
        rtspUrl: rtspUrl ?? this.rtspUrl,
        transport: transport ?? this.transport,
        port: port ?? this.port,
        username: username ?? this.username,
        password: password ?? this.password,
      );
}

/// SRT (Secure Reliable Transport) source.
class SrtEncoderSource extends CameraSource {
  final String host;
  final int port;
  final SrtMode mode;
  final int latencyMs;
  final String? streamId;
  final String? passphrase;

  const SrtEncoderSource({
    this.host = '',
    this.port = 9000,
    this.mode = SrtMode.caller,
    this.latencyMs = 200,
    this.streamId,
    this.passphrase,
  }) : super(
          type: CameraSourceType.srtEncoder,
          label: 'SRT Encoder',
          subtitle: 'Ultra-low latency Secure Reliable Transport',
          icon: Icons.speed_rounded,
          requiresLocalHardware: false,
        );

  /// Validates SRT URL or host.
  static bool isValidSrtUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    return uri.scheme == 'srt';
  }

  SrtEncoderSource copyWith({
    String? host,
    int? port,
    SrtMode? mode,
    int? latencyMs,
    String? streamId,
    String? passphrase,
  }) =>
      SrtEncoderSource(
        host: host ?? this.host,
        port: port ?? this.port,
        mode: mode ?? this.mode,
        latencyMs: latencyMs ?? this.latencyMs,
        streamId: streamId ?? this.streamId,
        passphrase: passphrase ?? this.passphrase,
      );
}
