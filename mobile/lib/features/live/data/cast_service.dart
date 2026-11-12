// lib/features/live/data/cast_service.dart
//
// CastService — orchestrates device discovery, session management, and
// live-feed routing for cast modalities:
//
//   • Smart TV        : DLNA/UPnP (real UDP SSDP M-SEARCH + SOAP AVTransport),
//                       AirPlay (native AVRoutePickerView on iOS),
//                       Chromecast (platform channel if SDK registered).
//   • Remote Camera   : WebRTC P2P signaling via backend Socket.IO /live gateway,
//                       exposing live remote MediaStreams for Multi-Cam & Studio.
//   • Screen Share    : getDisplayMedia via flutter_webrtc.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:mobile/features/live/data/lan_network_discovery_service.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/data/native_external_device_bridge.dart';
import 'package:mobile/features/live/domain/cast_device.dart';

// ─── Cast Service ─────────────────────────────────────────────────────────────

class CastService {
  final LiveSocketService _socket;
  final LanNetworkDiscoveryService _lanDiscovery;
  final NativeExternalDeviceBridge _bridge;

  CastService(
    this._socket, {
    LanNetworkDiscoveryService? lanDiscovery,
    NativeExternalDeviceBridge? bridge,
  }) : _lanDiscovery = lanDiscovery ?? LanNetworkDiscoveryService(),
       _bridge = bridge ?? NativeExternalDeviceBridge();

  // ─── Internal state ──────────────────────────────────────────────────────

  final _devicesCtrl = StreamController<List<CastDevice>>.broadcast();
  final _devices = <String, CastDevice>{};

  // WebRTC peer connections & live media streams for remote cameras keyed by device id.
  final _peerConnections = <String, rtc.RTCPeerConnection>{};
  final _remoteStreams = <String, rtc.MediaStream>{};
  final _remoteStreamsCtrl =
      StreamController<Map<String, rtc.MediaStream>>.broadcast();

  // DLNA AVTransport control URLs keyed by device UDN.
  final _dlnaControlUrls = <String, String>{};

  Timer? _ssdpDiscoveryTimer;
  Timer? _discoveryRefreshTimer;
  final List<StreamSubscription<dynamic>> _socketSubs = [];
  bool _socketBound = false;
  bool _isDisposed = false;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Live stream of all currently known cast devices.
  Stream<List<CastDevice>> get devicesStream => _devicesCtrl.stream;

  /// Current snapshot of devices.
  List<CastDevice> get currentDevices => _devices.values.toList();

  /// Live map of connected remote-camera MediaStreams keyed by device ID.
  Stream<Map<String, rtc.MediaStream>> get remoteStreamsStream =>
      _remoteStreamsCtrl.stream;

  /// Current snapshot of remote camera streams.
  Map<String, rtc.MediaStream> get currentRemoteStreams =>
      Map.unmodifiable(_remoteStreams);

  rtc.MediaStream? getRemoteStream(String deviceId) => _remoteStreams[deviceId];

  // ─── Discovery ────────────────────────────────────────────────────────────

  /// Start discovering cast-capable devices.
  /// Call [stopDiscovery] when the studio screen is closed.
  Future<void> startDiscovery() async {
    if (_isDisposed) return;
    _listenSocketCastEvents();
    _startSsdpDiscovery();

    _discoveryRefreshTimer?.cancel();
    _discoveryRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pruneStaleDevices(),
    );
    _emit();
  }

  void stopDiscovery() {
    _ssdpDiscoveryTimer?.cancel();
    _discoveryRefreshTimer?.cancel();
    _ssdpDiscoveryTimer = null;
    _discoveryRefreshTimer = null;
    unawaited(_bridge.releaseMulticastLock());
  }

  // ─── DLNA / SSDP Discovery ────────────────────────────────────────────────

  void _startSsdpDiscovery() {
    if (kIsWeb) return;

    _ssdpDiscoveryTimer?.cancel();
    _ssdpDiscoveryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_sendSsdpSearch());
    });
    unawaited(_sendSsdpSearch());
  }

  Future<void> _sendSsdpSearch() async {
    if (kIsWeb || _isDisposed) return;
    try {
      await _bridge.acquireMulticastLock();
      final renderers = await _lanDiscovery.discoverDlnaRenderers(
        timeout: const Duration(seconds: 3),
      );
      if (_isDisposed) return;

      for (final r in renderers) {
        if (r.avTransportControlUrl != null) {
          _dlnaControlUrls[r.udn] = r.avTransportControlUrl!;
        }
        final existing = _devices[r.udn];
        final device = CastDevice(
          id: r.udn,
          name: r.friendlyName,
          model: r.modelName,
          protocol: CastProtocol.dlna,
          type: CastDeviceType.smartTv,
          status: existing?.status ?? CastSessionStatus.discovered,
          ipAddress: r.hostIp ?? r.locationUrl,
          isActiveSource: existing?.isActiveSource ?? false,
          discoveredAt: DateTime.now(),
        );
        _upsertDevice(device);
      }
    } catch (_) {
      // Non-fatal on networks blocking multicast
    } finally {
      await _bridge.releaseMulticastLock();
    }
  }

  // ─── Socket.IO Cast Events ────────────────────────────────────────────────

  void _listenSocketCastEvents() {
    if (_socketBound) return;
    _socketBound = true;

    _socketSubs.add(
      _socket.onCastDeviceAnnounce.listen((payload) {
        final peerId = payload['peerId'] as String?;
        if (peerId == null || peerId.isEmpty) return;
        final existing = _devices[peerId];
        final device = CastDevice(
          id: peerId,
          name: payload['deviceName'] as String? ?? 'Remote Camera',
          model: payload['deviceModel'] as String?,
          protocol: CastProtocol.remotePeerCamera,
          type: CastDeviceType.remoteCamera,
          status: existing?.status ?? CastSessionStatus.discovered,
          signalStrength: payload['signalStrength'] as int?,
          ipAddress: payload['ip'] as String?,
          isActiveSource: existing?.isActiveSource ?? false,
          discoveredAt: DateTime.now(),
        );
        _upsertDevice(device);
      }),
    );

    // Broadcaster initiated offer -> remote camera replies with answer
    _socketSubs.add(
      _socket.onCastCameraAnswer.listen((payload) async {
        final peerId =
            (payload['peerId'] ?? payload['fromId']) as String?;
        final sdp = payload['sdp'] as String?;
        if (peerId == null || sdp == null) return;
        await _handleIncomingCameraAnswer(peerId, sdp);
      }),
    );

    _socketSubs.add(
      _socket.onCastCameraIce.listen((payload) async {
        final peerId =
            (payload['peerId'] ?? payload['fromId']) as String?;
        final candidate = payload['candidate'];
        if (peerId == null || candidate is! Map) return;
        try {
          await _peerConnections[peerId]?.addCandidate(
            rtc.RTCIceCandidate(
              candidate['candidate'] as String?,
              candidate['sdpMid'] as String?,
              (candidate['sdpMLineIndex'] as num?)?.toInt(),
            ),
          );
        } catch (_) {}
      }),
    );

    _socketSubs.add(
      _socket.onCastDeviceLeft.listen((payload) async {
        final peerId = payload['peerId'] as String?;
        if (peerId == null) return;
        await _cleanupPeer(peerId);
        _devices.remove(peerId);
        _emit();
      }),
    );
  }

  // ─── Remote Camera WebRTC ────────────────────────────────────────────────

  /// Initiate a WebRTC connection to a remote phone camera.
  Future<void> connectRemoteCamera({
    required String streamId,
    required CastDevice device,
  }) async {
    await _cleanupPeer(device.id);
    _updateDeviceStatus(device.id, CastSessionStatus.pairing);

    final config = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    try {
      final pc = await rtc.createPeerConnection(config);
      _peerConnections[device.id] = pc;

      pc.onIceCandidate = (candidate) {
        _socket.emitCastCameraIce(
          streamId: streamId,
          peerId: device.id,
          candidate: candidate.toMap(),
        );
      };

      pc.onTrack = (event) {
        rtc.MediaStream? remoteStream = event.streams.firstOrNull;
        if (remoteStream != null) {
          _remoteStreams[device.id] = remoteStream;
          _emitRemoteStreams();
        }
        _updateDeviceStatus(device.id, CastSessionStatus.connected);
      };

      pc.onConnectionState = (state) {
        if (state == rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _updateDeviceStatus(device.id, CastSessionStatus.connected);
        } else if (state ==
            rtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          _updateDeviceStatus(device.id, CastSessionStatus.reconnecting);
        } else if (state ==
            rtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _updateDeviceStatus(
            device.id,
            CastSessionStatus.error,
            error: 'WebRTC peer connection failed. Check network or TURN.',
          );
        }
      };

      // Request receive-only video + audio transceivers (Unified Plan)
      await pc.addTransceiver(
        kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: rtc.RTCRtpTransceiverInit(
          direction: rtc.TransceiverDirection.RecvOnly,
        ),
      );
      await pc.addTransceiver(
        kind: rtc.RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: rtc.RTCRtpTransceiverInit(
          direction: rtc.TransceiverDirection.RecvOnly,
        ),
      );

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      _socket.emitCastCameraOffer(
        streamId: streamId,
        peerId: device.id,
        sdp: offer.sdp!,
      );
    } catch (e) {
      await _cleanupPeer(device.id);
      _updateDeviceStatus(
        device.id,
        CastSessionStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> _handleIncomingCameraAnswer(String peerId, String sdp) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    try {
      await pc.setRemoteDescription(
        rtc.RTCSessionDescription(sdp, 'answer'),
      );
    } catch (e) {
      _updateDeviceStatus(
        peerId,
        CastSessionStatus.error,
        error: 'Failed to apply remote camera answer: $e',
      );
    }
  }

  /// Disconnect a specific remote camera peer.
  Future<void> disconnectRemoteCamera(String deviceId) async {
    await _cleanupPeer(deviceId);
    _updateDeviceStatus(deviceId, CastSessionStatus.disconnected);
  }

  /// Request remote phone camera to start/stop its local backup recording.
  void triggerRemoteCameraRecord({
    required String streamId,
    required String deviceId,
    required String action,
  }) {
    _socket.emitCastRecordCommand(
      streamId: streamId,
      peerId: deviceId,
      action: action,
    );
  }

  Future<void> _cleanupPeer(String deviceId) async {
    final pc = _peerConnections.remove(deviceId);
    if (pc != null) {
      try {
        await pc.close();
      } catch (_) {}
    }
    final stream = _remoteStreams.remove(deviceId);
    if (stream != null) {
      try {
        for (final t in stream.getTracks()) {
          t.stop();
        }
        await stream.dispose();
      } catch (_) {}
      _emitRemoteStreams();
    }
  }

  // ─── TV Cast ─────────────────────────────────────────────────────────────

  /// Cast the HLS/DASH stream URL to a TV device.
  /// On iOS this triggers the native AVRoutePickerView (AirPlay picker).
  /// On DLNA devices this uses real UPnP AVTransport SOAP commands.
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
      _updateDeviceStatus(
        device.id,
        CastSessionStatus.error,
        error: e.toString(),
      );
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
    try {
      await channel.invokeMethod('startCast', {
        'deviceId': device.id,
        'contentUrl': hlsUrl,
        'title': title,
        'thumbnailUrl': thumbnailUrl ?? '',
        'contentType': 'application/x-mpegURL',
      });
    } on MissingPluginException {
      throw UnsupportedError(
        'Native Google Cast SDK is not bundled in this build. '
        'Use DLNA/UPnP or AirPlay instead.',
      );
    }
  }

  Future<void> _castAirPlay({required String hlsUrl}) async {
    final isApple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (!isApple) {
      throw UnsupportedError('AirPlay is only available on iOS and macOS.');
    }
    const channel = MethodChannel('com.zkirekdusan/cast_airplay');
    await channel.invokeMethod('presentRoutePickerWithUrl', {'url': hlsUrl});
  }

  Future<void> _castDlna({
    required CastDevice device,
    required String hlsUrl,
    required String title,
  }) async {
    final controlUrl = _dlnaControlUrls[device.id] ?? device.ipAddress ?? '';
    await _lanDiscovery.castDlnaMedia(
      controlUrl: controlUrl,
      mediaUrl: hlsUrl,
      title: title,
    );
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
          final controlUrl = _dlnaControlUrls[device.id] ?? '';
          await _lanDiscovery.stopDlnaMedia(controlUrl: controlUrl);
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
    if (!_devicesCtrl.isClosed && !_isDisposed) {
      _devicesCtrl.add(_devices.values.toList());
    }
  }

  void _emitRemoteStreams() {
    if (!_remoteStreamsCtrl.isClosed && !_isDisposed) {
      _remoteStreamsCtrl.add(Map.unmodifiable(_remoteStreams));
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
    _isDisposed = true;
    stopDiscovery();
    for (final sub in _socketSubs) {
      await sub.cancel();
    }
    _socketSubs.clear();
    for (final id in _peerConnections.keys.toList()) {
      await _cleanupPeer(id);
    }
    await _remoteStreamsCtrl.close();
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

final castRemoteStreamsProvider =
    StreamProvider<Map<String, rtc.MediaStream>>((ref) {
      final service = ref.watch(castServiceProvider);
      return service.remoteStreamsStream;
    });
