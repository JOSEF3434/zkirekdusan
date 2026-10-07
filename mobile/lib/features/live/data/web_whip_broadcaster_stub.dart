// lib/features/live/data/web_whip_broadcaster_stub.dart
//
// Stub implementation of WebWhipBroadcaster for non-web platforms.
// All methods are no-ops; the real implementation lives in
// web_whip_broadcaster.dart (web only).

import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Lifecycle state of a WHIP broadcast session.
enum WhipState {
  idle,
  acquiringMedia,
  connecting,
  connected,
  reconnecting,
  failed,
  stopped,
}

/// Callbacks
typedef WhipStateCallback = void Function(WhipState state);
typedef WhipErrorCallback = void Function(String error);

/// No-op stub — only the web implementation does real work.
class WebWhipBroadcaster {
  final String whipUrl;
  final Map<String, dynamic> videoConstraints;
  final Map<String, dynamic> audioConstraints;
  final WhipStateCallback? onStateChange;
  final WhipErrorCallback? onError;

  WebWhipBroadcaster({
    required this.whipUrl,
    this.videoConstraints = const {},
    this.audioConstraints = const {},
    this.onStateChange,
    this.onError,
  });

  WhipState get state => WhipState.idle;
  bool get isConnected => false;
  MediaStream? get localStream => null;

  Future<void> start({MediaStream? existingStream}) async {}
  Future<void> stop() async {}
  Future<void> switchCamera(bool isFrontCamera) async {}
  void setMuted(bool muted) {}
}
