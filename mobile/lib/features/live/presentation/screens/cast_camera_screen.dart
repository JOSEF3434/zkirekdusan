// lib/features/live/presentation/screens/cast_camera_screen.dart
//
// "Use As Camera" screen — runs on a second phone or tablet that
// is being used as a wireless remote camera for the broadcaster.
//
// Flow:
//   1. User opens this screen (from discovery or QR scan).
//   2. Device announces itself via cast:announce socket event.
//   3. Broadcaster's CastService sees the peer and initiates WebRTC offer.
//   4. This screen accepts the offer, sends back answer, then streams
//      its camera feed to the broadcaster via WebRTC.
//   5. The broadcaster can "Go Live" this source at any time.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:go_router/go_router.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';

class CastCameraScreen extends ConsumerStatefulWidget {
  /// The stream ID to join as a remote camera.
  final String streamId;

  const CastCameraScreen({super.key, required this.streamId});

  @override
  ConsumerState<CastCameraScreen> createState() => _CastCameraScreenState();
}

class _CastCameraScreenState extends ConsumerState<CastCameraScreen>
    with WidgetsBindingObserver {
  // WebRTC
  rtc.RTCPeerConnection? _pc;
  rtc.MediaStream? _localStream;
  final _localRenderer = rtc.RTCVideoRenderer();
  bool _rendererInit = false;

  // Camera state
  bool _isFrontCamera = true;
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isConnected = false;
  bool _isAnnouncing = false;
  bool _isOnAir = false;
  String? _errorMsg;

  // Socket subscriptions
  StreamSubscription? _offerSub;
  StreamSubscription? _iceSub;
  StreamSubscription? _sourceSwitchedSub;

  // Stream info
  LiveStreamDto? _streamInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initRenderer();
    _loadStreamInfo();
    _connectSocket();
  }

  Future<void> _initRenderer() async {
    await _localRenderer.initialize();
    if (mounted) setState(() => _rendererInit = true);
  }

  Future<void> _loadStreamInfo() async {
    try {
      final repo = ref.read(liveStreamingRepositoryProvider);
      final info = await repo.getStreamById(widget.streamId);
      if (mounted) setState(() => _streamInfo = info);
    } catch (_) {}
  }

  Future<void> _connectSocket() async {
    final token = await ref.read(storageServiceProvider).getToken();
    if (token == null) return;
    final socket = ref.read(liveSocketServiceProvider);
    await socket.connect(token);
    socket.joinStream(widget.streamId);
    _announceCamera(socket);
    _listenForOffer(socket);
  }

  void _announceCamera(LiveSocketService socket) {
    if (!mounted) return;
    final deviceName = _getDeviceName();
    setState(() => _isAnnouncing = true);
    socket.emitCastAnnounce(
      streamId: widget.streamId,
      deviceName: deviceName,
      deviceModel: _getPlatformModel(),
    );
    // Re-announce every 10 s so the broadcaster's panel stays fresh.
    Timer.periodic(const Duration(seconds: 10), (t) {
      if (!mounted) { t.cancel(); return; }
      socket.emitCastAnnounce(
        streamId: widget.streamId,
        deviceName: deviceName,
      );
    });
  }

  void _listenForOffer(LiveSocketService socket) {
    _offerSub?.cancel();
    _offerSub = socket.onCastCameraOffer.listen((payload) async {
      final peerId = payload['peerId'] as String?;
      if (peerId == null) return;
      await _handleOffer(
        sdp: payload['sdp'] as String,
        peerId: peerId,
        socket: socket,
      );
    });

    _iceSub?.cancel();
    _iceSub = socket.onCastCameraIce.listen((payload) {
      final candidate = payload['candidate'];
      if (candidate == null) return;
      _pc?.addCandidate(rtc.RTCIceCandidate(
        candidate['candidate'] as String,
        candidate['sdpMid'] as String?,
        candidate['sdpMLineIndex'] as int?,
      ));
    });

    _sourceSwitchedSub?.cancel();
    _sourceSwitchedSub = socket.onCastSourceSwitched.listen((payload) {
      final sourceId = payload['sourceId'] as String?;
      if (!mounted) return;
      setState(() => _isOnAir = sourceId != null);
    });
  }

  Future<void> _handleOffer({
    required String sdp,
    required String peerId,
    required LiveSocketService socket,
  }) async {
    try {
      await _startLocalCamera();

      final config = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      };

      _pc = await rtc.createPeerConnection(config, {});

      // Add local tracks
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await _pc!.addTrack(track, _localStream!);
        }
      }

      _pc!.onIceCandidate = (c) {
        socket.emitCastCameraIce(
          streamId: widget.streamId,
          peerId: peerId,
          candidate: c.toMap(),
        );
      };

      _pc!.onConnectionState = (state) {
        if (!mounted) return;
        setState(() {
          _isConnected = state ==
              rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected;
        });
      };

      await _pc!.setRemoteDescription(
        rtc.RTCSessionDescription(sdp, 'offer'),
      );
      final answer = await _pc!.createAnswer({});
      await _pc!.setLocalDescription(answer);

      socket.emitCastCameraAnswer(peerId: peerId, sdp: answer.sdp!);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    }
  }

  Future<void> _startLocalCamera() async {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();

    _localStream = await rtc.navigator.mediaDevices.getUserMedia({
      'video': {
        'facingMode': _isFrontCamera ? 'user' : 'environment',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
        'frameRate': {'ideal': 30},
      },
      'audio': !_isMicMuted,
    });

    if (_rendererInit) {
      _localRenderer.srcObject = _localStream;
    }
    if (mounted) setState(() {});
  }

  void _flipCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);
    await _startLocalCamera();
    // Replace tracks in existing peer connection
    if (_pc != null && _localStream != null) {
      final senders = await _pc!.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind == 'video') {
          final videoTrack = _localStream!.getVideoTracks().firstOrNull;
          if (videoTrack != null) await sender.replaceTrack(videoTrack);
        }
      }
    }
  }

  void _toggleMic() {
    setState(() => _isMicMuted = !_isMicMuted);
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !_isMicMuted);
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !_isCameraOff);
  }

  String _getDeviceName() {
    // In a real app use device_info_plus; static for now.
    return 'Remote Camera';
  }

  String? _getPlatformModel() {
    return null; // Populated via device_info_plus in production.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offerSub?.cancel();
    _iceSub?.cancel();
    _sourceSwitchedSub?.cancel();
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _pc?.close();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera preview ──────────────────────────────────────────────
          if (_rendererInit && _localStream != null && !_isCameraOff)
            Positioned.fill(
              child: rtc.RTCVideoView(
                _localRenderer,
                mirror: _isFrontCamera,
                objectFit: rtc.RTCVideoViewObjectFit
                    .RTCVideoViewObjectFitCover,
              ),
            )
          else
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xFF0A0A0A),
                child: Center(
                  child: Icon(Icons.videocam_off_rounded,
                      color: Colors.white24, size: 64),
                ),
              ),
            ),

          // ── Gradient overlay (top + bottom) ──────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0, 0.25, 0.65, 1],
                ),
              ),
            ),
          ),

          // ── Top Bar ───────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remote Camera Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (_streamInfo != null)
                            Text(
                              _streamInfo!.title,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Status badges
                    if (_isOnAir)
                      _StatusBadge(
                        label: '● ON AIR',
                        color: Colors.red,
                      ),
                    if (!_isOnAir && _isConnected)
                      _StatusBadge(
                        label: '◉ READY',
                        color: Colors.green,
                      ),
                    if (!_isConnected && _isAnnouncing)
                      _StatusBadge(
                        label: '⟳ WAITING',
                        color: Colors.orange,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Error banner ──────────────────────────────────────────────
          if (_errorMsg != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                      onPressed: () => setState(() => _errorMsg = null),
                    ),
                  ],
                ),
              ),
            ),

          // ── ON AIR indicator (pulsing red banner) ─────────────────────
          if (_isOnAir)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: _OnAirBanner(),
              ),
            ),

          // ── Info panel (when not yet connected) ───────────────────────
          if (!_isConnected)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sensors_rounded,
                        color: Colors.white70, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Waiting for broadcaster to connect',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'The broadcaster will see this device in their '
                      '"Cast & Connect" panel. They must tap Connect to '
                      'start receiving your camera feed.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2,
                    ),
                  ],
                ),
              ),
            ),

          // ── Bottom Controls ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: _isMicMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: _isMicMuted ? 'Muted' : 'Mic',
                      color: _isMicMuted ? Colors.red : Colors.white,
                      onTap: _toggleMic,
                    ),
                    _ControlButton(
                      icon: _isCameraOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      label: _isCameraOff ? 'Camera Off' : 'Camera',
                      color: _isCameraOff ? Colors.red : Colors.white,
                      onTap: _toggleCamera,
                    ),
                    _ControlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Flip',
                      color: Colors.white,
                      onTap: _flipCamera,
                    ),
                    _ControlButton(
                      icon: Icons.call_end_rounded,
                      label: 'Leave',
                      color: Colors.red,
                      onTap: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color == Colors.red
                  ? Colors.red.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnAirBanner extends StatefulWidget {
  @override
  State<_OnAirBanner> createState() => _OnAirBannerState();
}

class _OnAirBannerState extends State<_OnAirBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.6, end: 1.0).animate(_ctrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Colors.white, size: 10),
            SizedBox(width: 6),
            Text(
              'ON AIR — YOUR FEED IS LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

