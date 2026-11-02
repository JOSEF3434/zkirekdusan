// lib/features/live/data/cast_service.dart
//
// CastService — orchestrates device discovery, session management, and
// live-feed routing for all cast modalities:
//
//   • Smart TV  : Chromecast (google_cast_sdk / platform channel), AirPlay
//                 (AVRoutePickerView iOS / platform channel), DLNA (UDP SSDP).
//   • Remote Camera : WebRTC signaling via backend Socket.IO live-gateway.
//   • Screen Share  : MediaProjection (Android) / ReplayKit (iOS) via
//                     flutter_webrtc's getDisplayMedia.
//   • USB Camera    : UVC enumeration via platform channel (future).
//
// All discovered devices are emitted as a stream so Riverpod providers
// can reactively update the UI without polling.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:mobile/features/live/domain/cast_device.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';

// ─── Cast Service ─────────────────────────────────────────────────────────────

class CastService {
  final LiveSocketService _socket;

  CastService(this._socket);

  // ─── Internal state ──────────────────────────────────────────────────────

  final _devicesCtrl = StreamController<List<CastDevice>>.broadcast();
  final _devices = <String, CastDevice>{};

  // WebRTC peer connections for remote cameras keyed by device id.
  final _peerConnections = <String, rtc.RTCPeerConnection>{};

  // SSDP socket for DLNA discovery (null on web platform).
  Timer? _ssdpDiscoveryTimer;
  Timer? _discoveryRefreshTimer;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Live stream of all currently known cast devices.
  Stream<List<CastDevice>> get devicesStream => _devicesCtrl.stream;

  /// Current snapshot of devices.
  List<CastDevice> get currentDevices => _devices.values.toList();

  // ─── Discovery ────────────────────────────────────────────────────────────

  /// Start discovering cast-capable devices.
  /// Call [stopDiscovery] when the studio screen is closed.
  Future<void> startDiscovery() async {
    _startSsdpDiscovery();
    _listenSocketCastEvents();
    // Periodic refresh to flush stale discovered devices.
    _discoveryRefreshTimer?.cancel();
    _discoveryRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pruneStaleDevices(),
    );
  }

  void stopDiscovery() {
    _ssdpDiscoveryTimer?.cancel();
    _discoveryRefreshTimer?.cancel();
    _ssdpDiscoveryTimer = null;
    _discoveryRefreshTimer = null;
  }

  // ─── DLNA / SSDP Discovery ────────────────────────────────────────────────

  void _startSsdpDiscovery() {
    // On web, SSDP (UDP multicast) is not available. Skip gracefully.
    if (kIsWeb) return;

    // Simulate SSDP M-SEARCH via platform channel (real impl uses a native plugin).
    // We schedule periodic discovery bursts every 15 s.
    _ssdpDiscoveryTimer?.cancel();
    _ssdpDiscoveryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _sendSsdpSearch();
    });
    // Also fire immediately.
    _sendSsdpSearch();
  }

  void _sendSsdpSearch() {
    // Invoke native platform channel that handles UDP multicast 239.255.255.250:1900
    // and returns discovered UPnP / DLNA renderer URNs.
    const channel = MethodChannel('com.zkirekdusan/cast_discovery');
    channel.invokeMethod<List<dynamic>>('discoverDlna').then((results) {
      if (results == null) return;
      for (final raw in results) {
        if (raw is! Map) continue;
        final device = CastDevice(
          id: raw['udn'] as String? ?? 'dlna-${raw['friendlyName']}',
          name: raw['friendlyName'] as String? ?? 'DLNA Device',
          model: raw['modelName'] as String?,
          protocol: CastProtocol.dlna,
          type: CastDeviceType.smartTv,
          status: CastSessionStatus.discovered,
          ipAddress: raw['location'] as String?,
          discoveredAt: DateTime.now(),
        );
        _upsertDevice(device);
      }
    }).catchError((_) {
      // Native channel not yet registered in this build — non-fatal.
    });
  }

  // ─── Socket.IO Cast Events ────────────────────────────────────────────────

  void _listenSocketCastEvents() {
    // Remote camera peers announce themselves via the live gateway.
    _socket.onCastDeviceAnnounce.listen((payload) {
      final device = CastDevice(
        id: payload['peerId'] as String,
        name: payload['deviceName'] as String? ?? 'Remote Camera',
        model: payload['deviceModel'] as String?,
        protocol: CastProtocol.remotePeerCamera,
        type: CastDeviceType.remoteCamera,
        status: CastSessionStatus.discovered,
        signalStrength: payload['signalStrength'] as int?,
        ipAddress: payload['ip'] as String?,
        discoveredAt: DateTime.now(),
      );
      _upsertDevice(device);
    });

    _socket.onCastCameraOffer.listen((payload) async {
      final peerId = payload['peerId'] as String;
      final sdp = payload['sdp'] as String;
      await _handleIncomingCameraOffer(peerId, sdp);
    });

    _socket.onCastCameraIce.listen((payload) {
      final peerId = payload['peerId'] as String;
      final candidate = payload['candidate'];
      _peerConnections[peerId]?.addCandidate(
        rtc.RTCIceCandidate(
          candidate['candidate'] as String,
          candidate['sdpMid'] as String?,
          candidate['sdpMLineIndex'] as int?,
        ),
      );
    });
  }

  // ─── Remote Camera WebRTC ────────────────────────────────────────────────

  /// Initiate a WebRTC connection to a remote phone camera.
  Future<void> connectRemoteCamera({
    required String streamId,
    required CastDevice device,
  }) async {
    _updateDeviceStatus(device.id, CastSessionStatus.pairing);

    final config = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    final constraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true}
      ],
    };

    try {
      final pc = await rtc.createPeerConnection(config, constraints);
      _peerConnections[device.id] = pc;

      pc.onIceCandidate = (candidate) {
        _socket.emitCastCameraIce(
          streamId: streamId,
          peerId: device.id,
          candidate: candidate.toMap(),
        );
      };

      pc.onTrack = (event) {
        // Remote camera track received — notify provider.
        _updateDeviceStatus(device.id, CastSessionStatus.connected);
      };

      pc.onConnectionState = (state) {
        if (state == rtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          _updateDeviceStatus(device.id, CastSessionStatus.reconnecting);
        } else if (state == rtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _updateDeviceStatus(device.id, CastSessionStatus.error);
        }
      };

      // Create offer to pull the remote camera track.
      final offer = await pc.createOffer({'offerToReceiveVideo': true, 'offerToReceiveAudio': true});
      await pc.setLocalDescription(offer);

      _socket.emitCastCameraOffer(
        streamId: streamId,
        peerId: device.id,
        sdp: offer.sdp!,
      );
    } catch (e) {
      _updateDeviceStatus(device.id, CastSessionStatus.error);
      rethrow;
    }
  }

  Future<void> _handleIncomingCameraOffer(String peerId, String sdp) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    await pc.setRemoteDescription(
      rtc.RTCSessionDescription(sdp, 'offer'),
    );
    final answer = await pc.createAnswer({});
    await pc.setLocalDescription(answer);

    _socket.emitCastCameraAnswer(peerId: peerId, sdp: answer.sdp!);
  }

  /// Disconnect a specific remote camera peer.
  Future<void> disconnectRemoteCamera(String deviceId) async {
    final pc = _peerConnections.remove(deviceId);
    await pc?.close();
    _updateDeviceStatus(deviceId, CastSessionStatus.disconnected);
  }

  // ─── TV Cast ─────────────────────────────────────────────────────────────

  /// Cast the HLS/DASH stream URL to a TV device.
  /// On iOS this triggers the native AVRoutePickerView (AirPlay picker).
  /// On Android this routes through the Google Cast SDK platform channel.
  Future<void> castToTv({
    required CastDevice device,
    required String hlsUrl,
    required String streamTitle,
    String? thumbnailUrl,
  }) async {
    _updateDeviceStatus(device.id, CastSessionStatus.pairing);

    try {
      switch (device.protocol) {
        case CastProtocol.chromecast:
          await _castChromecast(
            device: device,
            hlsUrl: hlsUrl,
            title: streamTitle,
            thumbnailUrl: thumbnailUrl,
          );
          break;
        case CastProtocol.airplay:
          await _castAirPlay(hlsUrl: hlsUrl);
          break;
        case CastProtocol.dlna:
          await _castDlna(
            device: device,
            hlsUrl: hlsUrl,
            title: streamTitle,
          );
          break;
        default:
          throw UnsupportedError('Protocol ${device.protocol} cannot cast to TV.');
      }
      _updateDeviceStatus(device.id, CastSessionStatus.connected);
    } catch (e) {
      _updateDeviceStatus(device.id, CastSessionStatus.error);
      rethrow;
    }
  }

  Future<void> _castChromecast({
    required CastDevice device,
    required String hlsUrl,
    required String title,
    String? thumbnailUrl,
  }) async {
    const channel = MethodChannel('com.zkirekdusan/cast_chromecast');
    await channel.invokeMethod('startCast', {
      'deviceId': device.id,
      'contentUrl': hlsUrl,
      'title': title,
      'thumbnailUrl': thumbnailUrl ?? '',
      'contentType': 'application/x-mpegURL',
    });
  }

  Future<void> _castAirPlay({required String hlsUrl}) async {
    const channel = MethodChannel('com.zkirekdusan/cast_airplay');
    await channel.invokeMethod('presentRoutePickerWithUrl', {'url': hlsUrl});
  }

  Future<void> _castDlna({
    required CastDevice device,
    required String hlsUrl,
    required String title,
  }) async {
    const channel = MethodChannel('com.zkirekdusan/cast_discovery');
    await channel.invokeMethod('castDlna', {
      'controlUrl': device.ipAddress ?? '',
      'contentUrl': hlsUrl,
      'title': title,
    });
  }

  Future<void> stopTvCast(CastDevice device) async {
    try {
      switch (device.protocol) {
        case CastProtocol.chromecast:
          const channel = MethodChannel('com.zkirekdusan/cast_chromecast');
          await channel.invokeMethod('stopCast', {'deviceId': device.id});
          break;
        case CastProtocol.airplay:
          const channel = MethodChannel('com.zkirekdusan/cast_airplay');
          await channel.invokeMethod('stopCast');
          break;
        case CastProtocol.dlna:
          const channel = MethodChannel('com.zkirekdusan/cast_discovery');
          await channel.invokeMethod('stopDlnaCast', {'controlUrl': device.ipAddress ?? ''});
          break;
        default:
          break;
      }
    } catch (_) {}
    _updateDeviceStatus(device.id, CastSessionStatus.disconnected);
  }

  // ─── Screen Share ─────────────────────────────────────────────────────────

  /// Capture the device screen using platform screen capture APIs.
  /// Returns a [MediaStream] ready to be added to an existing broadcast.
  Future<rtc.MediaStream?> startScreenShare() async {
    try {
      if (kIsWeb) {
        return await rtc.navigator.mediaDevices.getDisplayMedia({
          'video': {
            'frameRate': {'ideal': 30},
          },
          'audio': true,
        });
      }
      // Mobile: flutter_webrtc getDisplayMedia (requires MediaProjection on Android,
      // ReplayKit broadcast extension on iOS).
      return await rtc.navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false,
      });
    } catch (e) {
      debugPrint('[CastService] Screen share failed: $e');
      return null;
    }
  }

  void stopScreenShare(rtc.MediaStream stream) {
    for (final track in stream.getTracks()) {
      track.stop();
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _upsertDevice(CastDevice device) {
    _devices[device.id] = device;
    _emit();
  }

  void _updateDeviceStatus(String id, CastSessionStatus status, {String? error}) {
    final existing = _devices[id];
    if (existing == null) return;
    _devices[id] = existing.copyWith(status: status, lastError: error);
    _emit();
  }

  void _emit() {
    if (!_devicesCtrl.isClosed) {
      _devicesCtrl.add(_devices.values.toList());
    }
  }

  void _pruneStaleDevices() {
    final now = DateTime.now();
    _devices.removeWhere((_, d) =>
        d.status == CastSessionStatus.discovered &&
        now.difference(d.discoveredAt).inMinutes > 2);
    _emit();
  }

  Future<void> dispose() async {
    stopDiscovery();
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
    await _devicesCtrl.close();
  }
}

// ─── Riverpod Provider ────────────────────────────────────────────────────────

final castServiceProvider = Provider<CastService>((ref) {
  final socket = ref.watch(liveSocketServiceProvider);
  final service = CastService(socket);
  ref.onDispose(() => service.dispose());
  return service;
});

final castDevicesProvider = StreamProvider<List<CastDevice>>((ref) {
  final service = ref.watch(castServiceProvider);
  service.startDiscovery();
  ref.onDispose(service.stopDiscovery);
  return service.devicesStream;
});

