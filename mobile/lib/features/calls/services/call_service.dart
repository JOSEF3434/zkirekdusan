// lib/features/calls/services/call_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mobile/app/env/env.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/calls/providers/call_state_provider.dart';

final callServiceProvider = Provider<CallService>((ref) {
  final notifier = ref.read(callStateProvider.notifier);
  final service = CallService(ref, notifier);
  ref.onDispose(() => service.dispose());
  return service;
});

class CallService {
  final Ref _ref;
  final CallStateNotifier _notifier;
  io.Socket? _socket;
  bool _isConnectingSocket = false;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  MediaStream? _screenStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  Timer? _durationTimer;
  Timer? _callTimeoutTimer;
  Timer? _recoveryTimer;
  bool _renderersInitialized = false;

  CallService(this._ref, this._notifier);

  CallState get state => _notifier.currentState;
 
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
    if (_socket != null && (_socket!.connected || _isConnectingSocket)) return;
    _isConnectingSocket = true;

    final storage = _ref.read(storageServiceProvider);
    final token = await storage.getToken(key: 'access_token');
    if (token == null) {
      debugPrint('[CallService] No auth token found');
      _isConnectingSocket = false;
      return;
    }

    String baseUrl = Env.apiBaseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    } else if (baseUrl.endsWith('/api/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 5);
    }
    final socketUrl = baseUrl.endsWith('/') ? '${baseUrl}chat' : '$baseUrl/chat';

    if (_socket != null) {
      try {
        _socket!.clearListeners();
        _socket!.disconnect();
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .setAuth({'token': token})
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _socket!.onConnect((_) {
      _recoveryTimer?.cancel();
      _isConnectingSocket = false;
      debugPrint('[CallService] Connected to chat/call signaling gateway');
    });

    _socket!.onConnectError((err) {
      _isConnectingSocket = false;
      debugPrint('[CallService] Signaling socket connect error: $err');
      if (err.toString().contains('No transports available')) {
        _scheduleCleanRecovery();
      }
    });

    _socket!.onError((err) {
      _isConnectingSocket = false;
      debugPrint('[CallService] Signaling socket error: $err');
      if (err.toString().contains('No transports available')) {
        _scheduleCleanRecovery();
      }
    });

    _socket!.onDisconnect((_) {
      _isConnectingSocket = false;
    });

    // Handle Incoming Call from another peer
    _socket!.on('call:incoming', (data) async {
      debugPrint('[CallService] Received call:incoming: $data');
      if (data == null || data is! Map) return;
      final map = Map<String, dynamic>.from(data);

      final callerId = map['callerId']?.toString() ?? '';
      final conversationId = map['conversationId']?.toString() ?? '';
      if (callerId.isEmpty || conversationId.isEmpty) {
        debugPrint('[CallService] Invalid call:incoming - missing callerId or conversationId');
        return;
      }

      // If already in an active call, reject automatically
      if (state.isActive) {
        _socket?.emit('call:reject', {
          'callerId': callerId,
          'conversationId': conversationId,
          'reason': 'busy',
        });
        return;
      }

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
        if (state.status == CallStatus.ringing) {
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
        final sdp = answerMap['sdp']?.toString();
        final type = answerMap['type']?.toString();
        if (sdp != null && type != null) {
          final answer = RTCSessionDescription(sdp, type);
          await _peerConnection?.setRemoteDescription(answer);
          _onCallConnected();
        } else {
          debugPrint('[CallService] Missing SDP in call:answered');
          hangUp();
        }
      } catch (e) {
        debugPrint('[CallService] Error setting remote description: $e');
        hangUp();
      }
    });

    // Handle Call Answered Elsewhere (multi-device callee stopped ringing)
    _socket!.on('call:answered_elsewhere', (data) {
      debugPrint('[CallService] Call answered on another device: $data');
      _callTimeoutTimer?.cancel();
      _cleanupPeerConnection();
      _notifier.setIdle(reason: 'answered_elsewhere');
    });

    // Handle Call Rejected
    _socket!.on('call:rejected', (data) {
      debugPrint('[CallService] Received call:rejected: $data');
      _callTimeoutTimer?.cancel();
      final reason =
          data is Map ? (data['reason'] as String? ?? 'declined') : 'declined';
      _cleanupPeerConnection();
      _notifier.setEnded(reason: reason);
    });

    // Handle Call Ended / Hangup
    _socket!.on('call:ended', (data) {
      debugPrint('[CallService] Received call:ended: $data');
      _callTimeoutTimer?.cancel();
      _cleanupPeerConnection();
      final reason =
          data is Map ? (data['reason'] as String? ?? 'hangup') : 'hangup';
      if (reason == 'answered_elsewhere') {
        _notifier.setIdle(reason: 'answered_elsewhere');
      } else {
        _notifier.setEnded(reason: reason);
      }
    });

    // Handle Remote ICE Candidate
    _socket!.on('call:ice', (data) async {
      if (data == null || data is! Map) return;
      final candidateMap = Map<String, dynamic>.from(data['candidate'] ?? {});
      final candidateStr = candidateMap['candidate']?.toString();
      if (candidateStr == null || candidateStr.isEmpty) return;
      try {
        final candidate = RTCIceCandidate(
          candidateStr,
          candidateMap['sdpMid']?.toString(),
          candidateMap['sdpMLineIndex'] as int?,
        );
        await _peerConnection?.addCandidate(candidate);
      } catch (e) {
        debugPrint('[CallService] Error adding ICE candidate: $e');
      }
    });

    // Handle Real-time Reactions
    _socket!.on('call:reaction', (data) {
      if (data != null && data is Map) {
        final emoji = data['emoji'] as String?;
        if (emoji != null && emoji.isNotEmpty) {
          _notifier.setReaction(emoji);
        }
      }
    });

    // Handle Remote Media State
    _socket!.on('call:media-state', (data) {
      if (data != null && data is Map) {
        _notifier.setRemoteMediaState(
          isMuted: data['isMuted'] as bool?,
          isVideoEnabled: data['isVideoEnabled'] as bool?,
          isScreenSharing: data['isScreenSharing'] as bool?,
        );
      }
    });

    _socket!.connect();
  }

  void _scheduleCleanRecovery() {
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer(const Duration(seconds: 2), () {
      debugPrint('[CallService] Recovering signaling socket after transport failure...');
      _isConnectingSocket = false;
      if (_socket != null) {
        try {
          _socket!.clearListeners();
          _socket!.disconnect();
          _socket!.dispose();
        } catch (_) {}
        _socket = null;
      }
      _connectSignalingSocket();
    });
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

    // Set state immediately so CallScreen doesn't show blank/User
    _notifier.setCalling(
      conversationId: conversationId,
      remoteUserId: targetUserId,
      remoteDisplayName: targetDisplayName,
      remoteAvatarUrl: targetAvatarUrl,
      isVideoCall: isVideo,
    );

    // Check permissions on native platforms
    if (!kIsWeb) {
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
    }

    try {
      // 1. Create Media Stream
      _localStream = await _getUserMedia(isVideo: isVideo);
      localRenderer.srcObject = _localStream;

      // 2. Create Peer Connection
      _peerConnection = await createPeerConnection(_iceServers);
      _registerPeerConnectionListeners(
        targetUserId: targetUserId,
        conversationId: conversationId,
      );

      // 3. Add Local Tracks
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await _peerConnection?.addTrack(track, _localStream!);
        }
      }

      // 4. Create Offer
      final offer = await _peerConnection?.createOffer(_offerAnswerConstraints);
      if (offer == null) throw Exception('Failed to create WebRTC offer');
      await _peerConnection?.setLocalDescription(offer);

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
        if (state.status == CallStatus.calling) {
          hangUp();
          _notifier.setEnded(reason: 'no_answer');
        }
      });
    } catch (e) {
      debugPrint('[CallService] Error initiating call: $e');
      _cleanupPeerConnection();

      final errStr = e.toString().toLowerCase();
      String reason = 'call_failed';
      if (errStr.contains('notfounderror') ||
          errStr.contains('device not found')) {
        reason = 'device_not_found';
      } else if (errStr.contains('notallowederror') ||
          errStr.contains('permission denied')) {
        reason = 'permission_denied';
      } else {
        reason = e.toString();
      }

      // If peer connection was established and offer sent, notify server of hangup
      if (_peerConnection != null) {
        _socket?.emit('call:hangup', {
          'targetUserId': targetUserId,
          'conversationId': conversationId,
        });
      }

      _notifier.setEnded(reason: reason);
    }
  }

  // ─── Accept Incoming Call ──────────────────────────────────────────────────
  Future<void> acceptCall() async {
    final curState = state;
    final offerData = curState.incomingOffer;
    final callerId = curState.callerId ?? curState.remoteUserId;
    final conversationId = curState.conversationId;
    final isVideo = curState.isVideoCall;

    if (offerData == null || callerId == null || conversationId == null) {
      debugPrint('[CallService] Missing data to accept call');
      return;
    }

    _callTimeoutTimer?.cancel();
    _notifier.setConnecting();

    try {
      // Check permissions on native platforms
      if (!kIsWeb) {
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
      }

      // 1. Create Media Stream
      _localStream = await _getUserMedia(isVideo: isVideo);
      localRenderer.srcObject = _localStream;

      // 2. Create Peer Connection
      _peerConnection = await createPeerConnection(_iceServers);
      _registerPeerConnectionListeners(
        targetUserId: callerId,
        conversationId: conversationId,
      );

      // 3. Add Local Tracks
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await _peerConnection?.addTrack(track, _localStream!);
        }
      }

      // 4. Set Remote Description (Caller's Offer)
      final sdp = offerData['sdp']?.toString();
      final type = offerData['type']?.toString();
      if (sdp == null || type == null) {
        throw Exception('Invalid offer SDP in incoming offer');
      }
      final offer = RTCSessionDescription(sdp, type);
      await _peerConnection?.setRemoteDescription(offer);

      // 5. Create & Set Local Answer
      final answer =
          await _peerConnection?.createAnswer(_offerAnswerConstraints);
      if (answer == null) throw Exception('Failed to create WebRTC answer');
      await _peerConnection?.setLocalDescription(answer);

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
    _callTimeoutTimer?.cancel();
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
    _callTimeoutTimer?.cancel();
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
          ? (kIsWeb
              ? {'facingMode': 'user'}
              : {
                  'mandatory': {
                    'minWidth': '640',
                    'minHeight': '480',
                    'minFrameRate': '30',
                  },
                  'facingMode': 'user',
                  'optional': [],
                })
          : false,
    };

    try {
      return await navigator.mediaDevices.getUserMedia(mediaConstraints);
    } catch (e) {
      debugPrint(
        '[CallService] getUserMedia with constraints failed ($e), falling back to basic constraints',
      );
      try {
        return await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': isVideo,
        });
      } catch (fallbackErr) {
        debugPrint('[CallService] Basic getUserMedia failed: $fallbackErr');
        // If video device not found (e.g. desktop PC without webcam), fallback to audio-only
        if (isVideo) {
          debugPrint(
            '[CallService] Video device unavailable, attempting audio-only fallback',
          );
          try {
            final audioStream = await navigator.mediaDevices.getUserMedia({
              'audio': true,
              'video': false,
            });
            _notifier.setVideoEnabled(false);
            return audioStream;
          } catch (audioErr) {
            debugPrint('[CallService] Audio-only fallback also failed: $audioErr');
          }
        }
        rethrow;
      }
    }
  }

  void _registerPeerConnectionListeners({
    required String targetUserId,
    required String conversationId,
  }) {
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate == null) return;
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
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
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
        sendMediaState(isMuted: !currentEnabled);
      }
    }
  }

  void toggleSpeaker() {
    _notifier.toggleSpeaker();
    if (!kIsWeb) {
      Helper.setSpeakerphoneOn(state.isSpeakerOn);
    }
  }

  void toggleVideo() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final currentEnabled = videoTracks.first.enabled;
        videoTracks.first.enabled = !currentEnabled;
        _notifier.toggleVideo();
        sendMediaState(isVideoEnabled: !currentEnabled);
      }
    }
  }

  void switchCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        if (!kIsWeb) {
          Helper.switchCamera(videoTracks.first);
        }
        _notifier.toggleCamera();
      }
    }
  }

  // ─── Screen Sharing ────────────────────────────────────────────────────────
  Future<bool> startScreenShare() async {
    try {
      _screenStream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false,
      });
      final screenTrack = _screenStream!.getVideoTracks().first;

      final senders = await _peerConnection?.getSenders();
      final videoSender = senders?.firstWhere(
        (s) => s.track?.kind == 'video',
        orElse: () => throw Exception('No video sender found'),
      );
      await videoSender?.replaceTrack(screenTrack);
      localRenderer.srcObject = _screenStream;
      _notifier.setRemoteMediaState(isScreenSharing: true);
      sendMediaState(isScreenSharing: true);

      screenTrack.onEnded = () {
        stopScreenShare();
      };
      return true;
    } catch (e) {
      debugPrint('[CallService] Screen share error: $e');
      return false;
    }
  }

  Future<void> stopScreenShare() async {
    try {
      if (_screenStream != null) {
        _screenStream!.getTracks().forEach((track) => track.stop());
        _screenStream!.dispose();
        _screenStream = null;
      }

      if (_localStream != null) {
        final cameraTrack = _localStream!.getVideoTracks().firstOrNull;
        if (cameraTrack != null) {
          final senders = await _peerConnection?.getSenders();
          final videoSender = senders?.firstWhere(
            (s) => s.track?.kind == 'video',
            orElse: () => throw Exception('No video sender found'),
          );
          await videoSender?.replaceTrack(cameraTrack);
          localRenderer.srcObject = _localStream;
        }
      }

      _notifier.setRemoteMediaState(isScreenSharing: false);
      sendMediaState(isScreenSharing: false);
    } catch (e) {
      debugPrint('[CallService] Stop screen share error: $e');
    }
  }

  // ─── Signaling Relays ──────────────────────────────────────────────────────
  void sendReaction(String emoji, {String? action}) {
    final targetUserId = state.remoteUserId ?? state.callerId;
    final conversationId = state.conversationId;
    if (targetUserId == null || conversationId == null) return;

    _notifier.setReaction(emoji);
    _socket?.emit('call:reaction', {
      'targetUserId': targetUserId,
      'conversationId': conversationId,
      'emoji': emoji,
      'action': action,
    });
  }

  void sendMediaState({
    bool? isMuted,
    bool? isVideoEnabled,
    bool? isScreenSharing,
  }) {
    final targetUserId = state.remoteUserId ?? state.callerId;
    final conversationId = state.conversationId;
    if (targetUserId == null || conversationId == null) return;

    _socket?.emit('call:media-state', {
      'targetUserId': targetUserId,
      'conversationId': conversationId,
      'isMuted': isMuted ?? state.isMuted,
      'isVideoEnabled': isVideoEnabled ?? state.isVideoEnabled,
      'isScreenSharing': isScreenSharing ?? state.isScreenSharing,
    });
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────────
  void _cleanupPeerConnection() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;

    try {
      if (_screenStream != null) {
        _screenStream!.getTracks().forEach((track) => track.stop());
        _screenStream!.dispose();
        _screenStream = null;
      }

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
    _recoveryTimer?.cancel();
    _cleanupPeerConnection();
    if (_socket != null) {
      try {
        _socket!.clearListeners();
        _socket!.disconnect();
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }
    if (_renderersInitialized) {
      localRenderer.dispose();
      remoteRenderer.dispose();
      _renderersInitialized = false;
    }
  }
}
