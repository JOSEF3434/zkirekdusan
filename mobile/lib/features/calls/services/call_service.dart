// lib/features/calls/services/call_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mobile/app/env/env.dart';
import 'package:mobile/features/calls/providers/call_state_provider.dart';

final callServiceProvider = Provider<CallService>((ref) {
  final service = CallService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class CallService {
  final Ref _ref;
  io.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  Timer? _durationTimer;
  Timer? _callTimeoutTimer;
  bool _renderersInitialized = false;

  CallService(this._ref);

  CallStateNotifier get _notifier => _ref.read(callStateProvider.notifier);
  CallState get state => _ref.read(callStateProvider);

  // ─── WebRTC Configuration ──────────────────────────────────────────────────
  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  static const Map<String, dynamic> _offerAnswerConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  // ─── Initialization & Socket Connection ────────────────────────────────────
  Future<void> init() async {
    if (!_renderersInitialized) {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _renderersInitialized = true;
    }
    await _connectSignalingSocket();
  }

  Future<void> _connectSignalingSocket() async {
    if (_socket != null && _socket!.connected) return;

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token == null) {
      debugPrint('[CallService] No auth token found');
      return;
    }

    final baseUrl = Env.apiBaseUrl.replaceFirst('/api', '');
    _socket = io.io(
      '$baseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[CallService] Connected to chat/call signaling gateway');
    });

    // Handle Incoming Call from another peer
    _socket!.on('call:incoming', (data) async {
      debugPrint('[CallService] Received call:incoming: $data');
      if (data == null || data is! Map) return;
      final map = Map<String, dynamic>.from(data);

      // If already in a call, reject automatically
      if (state.isActive) {
        _socket?.emit('call:reject', {
          'callerId': map['callerId'],
          'conversationId': map['conversationId'],
          'reason': 'busy',
        });
        return;
      }

      final callerId = map['callerId'] as String;
      final conversationId = map['conversationId'] as String;
      final callType = map['callType'] as String? ?? 'audio';
      final callerName = map['callerName'] as String? ?? 'Caller';
      final callerAvatar = map['callerAvatar'] as String?;
      final offerMap = Map<String, dynamic>.from(map['offer'] ?? {});

      _notifier.setRinging(
        callerId: callerId,
        conversationId: conversationId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        isVideoCall: callType == 'video',
        offer: offerMap,
      );

      // Auto-cancel after 45 seconds of unanswered ringing
      _callTimeoutTimer?.cancel();
      _callTimeoutTimer = Timer(const Duration(seconds: 45), () {
        if (_ref.read(callStateProvider).status == CallStatus.ringing) {
          rejectCall(reason: 'timeout');
        }
      });
    });

    // Handle Callee Answered
    _socket!.on('call:answered', (data) async {
      debugPrint('[CallService] Received call:answered: $data');
      if (data == null || data is! Map) return;
      final map = Map<String, dynamic>.from(data);
      final answerMap = Map<String, dynamic>.from(map['answer'] ?? {});

      _callTimeoutTimer?.cancel();
      _notifier.setConnecting();

      try {
        final answer = RTCSessionDescription(
          answerMap['sdp'] as String,
          answerMap['type'] as String,
        );
        await _peerConnection?.setRemoteDescription(answer);
        _onCallConnected();
      } catch (e) {
        debugPrint('[CallService] Error setting remote description: $e');
        hangUp();
      }
    });

    // Handle Call Rejected
    _socket!.on('call:rejected', (data) {
      debugPrint('[CallService] Received call:rejected: $data');
      final reason = data is Map ? (data['reason'] as String? ?? 'declined') : 'declined';
      _cleanupPeerConnection();
      _notifier.setEnded(reason: reason);
    });

    // Handle Call Ended / Hangup
    _socket!.on('call:ended', (_) {
      debugPrint('[CallService] Received call:ended');
      _cleanupPeerConnection();
      _notifier.setEnded(reason: 'hangup');
    });

    // Handle Remote ICE Candidate
    _socket!.on('call:ice', (data) async {
      if (data == null || data is! Map) return;
      final candidateMap = Map<String, dynamic>.from(data['candidate'] ?? {});
      try {
        final candidate = RTCIceCandidate(
          candidateMap['candidate'],
          candidateMap['sdpMid'],
          candidateMap['sdpMLineIndex'],
        );
        await _peerConnection?.addCandidate(candidate);
      } catch (e) {
        debugPrint('[CallService] Error adding ICE candidate: $e');
      }
    });

    _socket!.connect();
  }

  // ─── Initiate Outgoing Call ────────────────────────────────────────────────
  Future<void> initiateCall({
    required String targetUserId,
    required String conversationId,
    required String targetDisplayName,
    String? targetAvatarUrl,
    required bool isVideo,
    required String myDisplayName,
    String? myAvatarUrl,
  }) async {
    await init();

    // Check permissions
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _notifier.setEnded(reason: 'Microphone permission denied');
      return;
    }
    if (isVideo) {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        _notifier.setEnded(reason: 'Camera permission denied');
        return;
      }
    }

    _notifier.setCalling(
      conversationId: conversationId,
      remoteUserId: targetUserId,
      remoteDisplayName: targetDisplayName,
      remoteAvatarUrl: targetAvatarUrl,
      isVideoCall: isVideo,
    );

    try {
      // 1. Create Media Stream
      _localStream = await _getUserMedia(isVideo: isVideo);
      localRenderer.srcObject = _localStream;

      // 2. Create Peer Connection
      _peerConnection = await createPeerConnection(_iceServers);
      _registerPeerConnectionListeners(targetUserId: targetUserId, conversationId: conversationId);

      // 3. Add Local Tracks
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      // 4. Create Offer
      final offer = await _peerConnection!.createOffer(_offerAnswerConstraints);
      await _peerConnection!.setLocalDescription(offer);

      // 5. Send Offer via Signaling Socket
      _socket?.emit('call:initiate', {
        'targetUserId': targetUserId,
        'conversationId': conversationId,
        'callType': isVideo ? 'video' : 'audio',
        'offer': {'sdp': offer.sdp, 'type': offer.type},
        'callerName': myDisplayName,
        'callerAvatar': myAvatarUrl,
      });

      // Timeout if not answered in 45s
      _callTimeoutTimer?.cancel();
      _callTimeoutTimer = Timer(const Duration(seconds: 45), () {
        if (_ref.read(callStateProvider).status == CallStatus.calling) {
          hangUp();
          _notifier.setEnded(reason: 'no_answer');
        }
      });
    } catch (e) {
      debugPrint('[CallService] Error initiating call: $e');
      hangUp();
      _notifier.setEnded(reason: e.toString());
    }
  }

  // ─── Accept Incoming Call ──────────────────────────────────────────────────
  Future<void> acceptCall() async {
    final curState = state;
    final offerData = curState.incomingOffer;
    final callerId = curState.callerId;
    final conversationId = curState.conversationId;
    final isVideo = curState.isVideoCall;

    if (offerData == null || callerId == null || conversationId == null) {
      debugPrint('[CallService] Missing data to accept call');
      return;
    }

    _callTimeoutTimer?.cancel();
    _notifier.setConnecting();

    try {
      // Check permissions
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        rejectCall(reason: 'Microphone permission denied');
        return;
      }
      if (isVideo) {
        final camStatus = await Permission.camera.request();
        if (!camStatus.isGranted) {
          rejectCall(reason: 'Camera permission denied');
          return;
        }
      }

      // 1. Create Media Stream
      _localStream = await _getUserMedia(isVideo: isVideo);
      localRenderer.srcObject = _localStream;

      // 2. Create Peer Connection
      _peerConnection = await createPeerConnection(_iceServers);
      _registerPeerConnectionListeners(targetUserId: callerId, conversationId: conversationId);

      // 3. Add Local Tracks
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      // 4. Set Remote Description (Caller's Offer)
      final offer = RTCSessionDescription(
        offerData['sdp'] as String,
        offerData['type'] as String,
      );
      await _peerConnection!.setRemoteDescription(offer);

      // 5. Create & Set Local Answer
      final answer = await _peerConnection!.createAnswer(_offerAnswerConstraints);
      await _peerConnection!.setLocalDescription(answer);

      // 6. Send Answer to Caller
      _socket?.emit('call:accept', {
        'callerId': callerId,
        'conversationId': conversationId,
        'answer': {'sdp': answer.sdp, 'type': answer.type},
      });

      _onCallConnected();
    } catch (e) {
      debugPrint('[CallService] Error accepting call: $e');
      rejectCall(reason: e.toString());
    }
  }

  // ─── Reject Incoming Call ──────────────────────────────────────────────────
  void rejectCall({String reason = 'declined'}) {
    final callerId = state.callerId ?? state.remoteUserId;
    final conversationId = state.conversationId;

    if (callerId != null && conversationId != null) {
      _socket?.emit('call:reject', {
        'callerId': callerId,
        'conversationId': conversationId,
        'reason': reason,
      });
    }

    _cleanupPeerConnection();
    _notifier.setEnded(reason: reason);
  }

  // ─── Hang Up Active / Outgoing Call ────────────────────────────────────────
  void hangUp() {
    final targetUserId = state.remoteUserId ?? state.callerId;
    final conversationId = state.conversationId;

    if (targetUserId != null && conversationId != null) {
      _socket?.emit('call:hangup', {
        'targetUserId': targetUserId,
        'conversationId': conversationId,
      });
    }

    _cleanupPeerConnection();
    _notifier.setEnded(reason: 'hangup');
  }

  // ─── WebRTC Stream Helpers ─────────────────────────────────────────────────
  Future<MediaStream> _getUserMedia({required bool isVideo}) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideo
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    return await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  void _registerPeerConnectionListeners({
    required String targetUserId,
    required String conversationId,
  }) {
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _socket?.emit('call:ice-candidate', {
        'targetUserId': targetUserId,
        'conversationId': conversationId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
      }
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('[CallService] PeerConnection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _onCallConnected();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        hangUp();
      }
    };
  }

  void _onCallConnected() {
    _callTimeoutTimer?.cancel();
    _notifier.setConnected();
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _notifier.tickDuration();
    });
  }

  // ─── Call Controls ─────────────────────────────────────────────────────────
  void toggleMute() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final currentEnabled = audioTracks.first.enabled;
        audioTracks.first.enabled = !currentEnabled;
        _notifier.toggleMute();
      }
    }
  }

  void toggleSpeaker() {
    _notifier.toggleSpeaker();
    // In mobile WebRTC, audio output routing can be switched
    Helper.setSpeakerphoneOn(state.isSpeakerOn);
  }

  void toggleVideo() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final currentEnabled = videoTracks.first.enabled;
        videoTracks.first.enabled = !currentEnabled;
        _notifier.toggleVideo();
      }
    }
  }

  void switchCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        Helper.switchCamera(videoTracks.first);
        _notifier.toggleCamera();
      }
    }
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────────
  void _cleanupPeerConnection() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;

    try {
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      _localStream = null;

      _remoteStream?.getTracks().forEach((track) => track.stop());
      _remoteStream?.dispose();
      _remoteStream = null;

      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;

      _peerConnection?.close();
      _peerConnection?.dispose();
      _peerConnection = null;
    } catch (e) {
      debugPrint('[CallService] Error during cleanup: $e');
    }
  }

  void dispose() {
    _cleanupPeerConnection();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    if (_renderersInitialized) {
      localRenderer.dispose();
      remoteRenderer.dispose();
      _renderersInitialized = false;
    }
  }
}
