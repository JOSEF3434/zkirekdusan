// lib/features/live/data/web_whip_broadcaster.dart
//
// WebRTC WHIP broadcaster for Flutter Web.
//
// Protocol: WHIP (WebRTC-HTTP Ingest Protocol — RFC draft-ietf-wish-whip)
//   1. Capture browser media (getUserMedia) via flutter_webrtc
//   2. Create RTCPeerConnection and add all tracks
//   3. Create SDP offer, wait for ICE gathering, POST to WHIP endpoint
//   4. Parse SDP answer from HTTP 201 response → setRemoteDescription
//   5. Media flows:  Browser → MediaMTX (WHIP) → ffmpeg → Cloudinary RTMP → HLS
//
// This class is Web-only. On mobile, ApiVideoLiveStreamController is used.

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:flutter/foundation.dart';
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

class WebWhipBroadcaster {
  /// Full WHIP endpoint URL returned by the backend.
  /// Example: https://mtx.zikrekidusan.com/stream_abc123/whip
  final String whipUrl;

  final Map<String, dynamic> videoConstraints;
  final Map<String, dynamic> audioConstraints;
  final WhipStateCallback? onStateChange;
  final WhipErrorCallback? onError;

  WebWhipBroadcaster({
    required this.whipUrl,
    this.videoConstraints = const {
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
      'frameRate': {'ideal': 30, 'max': 30},
      'facingMode': 'user',
    },
    this.audioConstraints = const {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
    this.onStateChange,
    this.onError,
  });

  // ─── State ─────────────────────────────────────────────────────────────────

  WhipState _state = WhipState.idle;
  WhipState get state => _state;
  bool get isConnected => _state == WhipState.connected;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  String? _whipResourceUrl; // DELETE this on teardown (WHIP spec Location header)

  MediaStream? get localStream => _localStream;

  void _setState(WhipState s) {
    _state = s;
    onStateChange?.call(s);
    debugPrint('[WHIP] state → ${s.name}');
  }

  void _emitError(String msg) {
    debugPrint('[WHIP] ERROR: $msg');
    onError?.call(msg);
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Acquire camera/mic, create RTCPeerConnection, perform WHIP handshake.
  Future<void> start() async {
    assert(kIsWeb, 'WebWhipBroadcaster is Web-only');
    if (_state != WhipState.idle && _state != WhipState.stopped) {
      _emitError('start() called in invalid state: ${_state.name}');
      return;
    }

    try {
      // ── 1. Acquire media ──────────────────────────────────────────────────
      _setState(WhipState.acquiringMedia);
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': videoConstraints,
        'audio': audioConstraints,
      });
      debugPrint(
        '[WHIP] Media acquired: '
        'video=${_localStream!.getVideoTracks().length} '
        'audio=${_localStream!.getAudioTracks().length}',
      );

      // ── 2. Create PeerConnection ──────────────────────────────────────────
      _setState(WhipState.connecting);
      _pc = await createPeerConnection(_iceConfiguration());
      _pc!.onIceConnectionState = _handleIceConnectionState;
      _pc!.onConnectionState = _handleConnectionState;
      _pc!.onIceCandidate = (c) {
        debugPrint('[WHIP] ICE candidate type=${c.candidate?.split(" ")[7] ?? "?"}');
      };

      // Add tracks to the peer connection
      for (final track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }

      // ── 3. Create SDP offer ───────────────────────────────────────────────
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': false,
        'offerToReceiveVideo': false,
      });
      await _pc!.setLocalDescription(offer);

      // Wait for all ICE candidates (send full SDP to avoid trickle ICE complexity)
      await _waitForIceGathering();

      final localDesc = await _pc!.getLocalDescription();
      if (localDesc == null || localDesc.sdp == null) {
        throw Exception('Failed to generate SDP offer — localDescription is null');
      }

      // ── 4. POST SDP offer to WHIP endpoint ───────────────────────────────
      debugPrint('[WHIP] POSTing SDP offer to $whipUrl');
      final (statusCode, responseBody, locationHeader) =
          await _whipPost(whipUrl, localDesc.sdp!);

      debugPrint('[WHIP] WHIP response: HTTP $statusCode');

      if (statusCode != 201) {
        throw Exception(
          'WHIP server rejected the offer (HTTP $statusCode). '
          'Ensure MediaMTX is running and the stream path is correct. '
          'Response: $responseBody',
        );
      }

      _whipResourceUrl = locationHeader ?? whipUrl;

      // ── 5. Set SDP answer ─────────────────────────────────────────────────
      if (responseBody.isEmpty || !responseBody.trimLeft().startsWith('v=')) {
        throw Exception('WHIP server returned invalid or empty SDP answer');
      }

      await _pc!.setRemoteDescription(
        RTCSessionDescription(responseBody, 'answer'),
      );

      _setState(WhipState.connected);
      debugPrint('[WHIP] ✓ WHIP session established — media flowing to MediaMTX');
    } catch (e, st) {
      debugPrint('[WHIP] start() failed: $e\n$st');
      _setState(WhipState.failed);
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) msg = msg.substring(11);
      _emitError(msg);
      await _cleanup();
    }
  }

  /// Gracefully tear down the session and release all resources.
  Future<void> stop() async {
    debugPrint('[WHIP] stop() called (state=${_state.name})');
    _setState(WhipState.stopped);
    await _cleanup();
  }

  /// Replace the video track without renegotiating (facingMode switch).
  Future<void> switchCamera(bool useFront) async {
    if (_localStream == null || _pc == null) return;
    try {
      final newStream = await navigator.mediaDevices.getUserMedia({
        'video': {
          ...videoConstraints,
          'facingMode': useFront ? 'user' : 'environment',
        },
        'audio': false,
      });

      final newVideoTrack = newStream.getVideoTracks().firstOrNull;
      if (newVideoTrack == null) return;

      final senders = await _pc!.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind == 'video') {
          await sender.replaceTrack(newVideoTrack);
          break;
        }
      }

      // Stop the old video tracks and update _localStream reference
      for (final t in _localStream!.getVideoTracks()) {
        t.stop();
      }
      _localStream = newStream;
    } catch (e) {
      _emitError('Camera switch failed: $e');
    }
  }

  /// Enable or disable the microphone without disconnecting.
  void setMuted(bool muted) {
    for (final track in _localStream?.getAudioTracks() ?? []) {
      track.enabled = !muted;
    }
  }

  // ─── WHIP HTTP POST (package:web XHR — no dart:html) ──────────────────────

  Future<(int statusCode, String body, String? location)> _whipPost(
    String url,
    String sdpOffer,
  ) async {
    final completer = Completer<(int, String, String?)>();
    final xhr = web.XMLHttpRequest();
    xhr.open('POST', url);
    xhr.setRequestHeader('Content-Type', 'application/sdp');
    xhr.setRequestHeader('Accept', 'application/sdp');

    xhr.onLoad.listen((_) {
      final location = xhr.getResponseHeader('Location');
      completer.complete((
        xhr.status,
        xhr.responseText,
        location,
      ));
    });

    xhr.onError.listen((_) {
      completer.completeError(
        Exception(
          'Network error reaching WHIP endpoint $url — '
          'verify the MediaMTX server is reachable and CORS is configured.',
        ),
      );
    });

    xhr.send(sdpOffer.toJS);
    return completer.future;
  }

  Future<void> _deleteWhipResource(String url) async {
    try {
      final xhr = web.XMLHttpRequest();
      xhr.open('DELETE', url);
      xhr.send();
    } catch (_) {}
  }

  // ─── ICE / Connection State Handlers ─────────────────────────────────────

  void _handleIceConnectionState(RTCIceConnectionState state) {
    debugPrint('[WHIP] ICE: ${state.name}');
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        _setState(WhipState.failed);
        _emitError(
          'ICE connection failed. If behind NAT/firewall, a TURN server is required. '
          'Contact your administrator to configure TURN credentials in MediaMTX.',
        );
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        if (_state == WhipState.connected) _setState(WhipState.reconnecting);
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        if (_state == WhipState.reconnecting) _setState(WhipState.connected);
      default:
        break;
    }
  }

  void _handleConnectionState(RTCPeerConnectionState state) {
    debugPrint('[WHIP] PC: ${state.name}');
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      _setState(WhipState.failed);
      _emitError('WebRTC PeerConnection permanently failed. Please retry.');
    }
  }

  // ─── ICE Gathering Wait ────────────────────────────────────────────────────

  Future<void> _waitForIceGathering() async {
    // iceGatheringState is a synchronous getter in flutter_webrtc, not a Future.
    final gathering = _pc!.iceGatheringState;
    if (gathering == RTCIceGatheringState.RTCIceGatheringStateComplete) return;

    final completer = Completer<void>();
    Timer? timeoutTimer;

    _pc!.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    };

    // Fallback: don't block forever if ICE gathering stalls
    timeoutTimer = Timer(const Duration(seconds: 4), () {
      debugPrint('[WHIP] ICE gathering timeout — proceeding with partial candidates');
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future;
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────

  Future<void> _cleanup() async {
    if (_whipResourceUrl != null) {
      await _deleteWhipResource(_whipResourceUrl!);
      _whipResourceUrl = null;
    }
    try {
      for (final t in _localStream?.getTracks() ?? []) {
        t.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;

    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
  }

  // ─── RTCPeerConnection Config ─────────────────────────────────────────────

  Map<String, dynamic> _iceConfiguration() => {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    'sdpSemantics': 'unified-plan',
  };
}
