// lib/features/calls/providers/call_state_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Call Status ──────────────────────────────────────────────────────────────
enum CallStatus {
  idle,       // no call
  calling,    // we initiated, waiting for answer
  ringing,    // incoming call waiting for us to answer
  connecting, // WebRTC negotiation in progress
  connected,  // media flowing
  ended,      // call finished (transient, resets to idle)
}

// ─── Call State ───────────────────────────────────────────────────────────────
class CallState {
  final CallStatus status;
  final String? conversationId;
  final String? remoteUserId;
  final String? remoteDisplayName;
  final String? remoteAvatarUrl;
  final bool isVideoCall;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isVideoEnabled;
  final bool isFrontCamera;
  final Duration callDuration;
  final String? endReason; // 'declined' | 'offline' | 'timeout' | 'hangup'

  // Incoming-call specific: SDP offer from caller (serialised)
  final Map<String, dynamic>? incomingOffer;
  final String? callerId; // only set when status == ringing

  const CallState({
    this.status = CallStatus.idle,
    this.conversationId,
    this.remoteUserId,
    this.remoteDisplayName,
    this.remoteAvatarUrl,
    this.isVideoCall = false,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isVideoEnabled = true,
    this.isFrontCamera = true,
    this.callDuration = Duration.zero,
    this.endReason,
    this.incomingOffer,
    this.callerId,
  });

  bool get isActive =>
      status == CallStatus.calling ||
      status == CallStatus.ringing ||
      status == CallStatus.connecting ||
      status == CallStatus.connected;

  CallState copyWith({
    CallStatus? status,
    String? conversationId,
    String? remoteUserId,
    String? remoteDisplayName,
    String? remoteAvatarUrl,
    bool? isVideoCall,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isVideoEnabled,
    bool? isFrontCamera,
    Duration? callDuration,
    String? endReason,
    Map<String, dynamic>? incomingOffer,
    String? callerId,
  }) {
    return CallState(
      status: status ?? this.status,
      conversationId: conversationId ?? this.conversationId,
      remoteUserId: remoteUserId ?? this.remoteUserId,
      remoteDisplayName: remoteDisplayName ?? this.remoteDisplayName,
      remoteAvatarUrl: remoteAvatarUrl ?? this.remoteAvatarUrl,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      callDuration: callDuration ?? this.callDuration,
      endReason: endReason ?? this.endReason,
      incomingOffer: incomingOffer ?? this.incomingOffer,
      callerId: callerId ?? this.callerId,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
class CallStateNotifier extends StateNotifier<CallState> {
  CallStateNotifier() : super(const CallState());

  void setIdle({String? reason}) {
    state = CallState(status: CallStatus.idle, endReason: reason);
  }

  void setCalling({
    required String conversationId,
    required String remoteUserId,
    required String remoteDisplayName,
    String? remoteAvatarUrl,
    required bool isVideoCall,
  }) {
    state = CallState(
      status: CallStatus.calling,
      conversationId: conversationId,
      remoteUserId: remoteUserId,
      remoteDisplayName: remoteDisplayName,
      remoteAvatarUrl: remoteAvatarUrl,
      isVideoCall: isVideoCall,
    );
  }

  void setRinging({
    required String callerId,
    required String conversationId,
    required String callerName,
    String? callerAvatar,
    required bool isVideoCall,
    required Map<String, dynamic> offer,
  }) {
    state = CallState(
      status: CallStatus.ringing,
      callerId: callerId,
      conversationId: conversationId,
      remoteUserId: callerId,
      remoteDisplayName: callerName,
      remoteAvatarUrl: callerAvatar,
      isVideoCall: isVideoCall,
      incomingOffer: offer,
    );
  }

  void setConnecting() {
    state = state.copyWith(status: CallStatus.connecting);
  }

  void setConnected() {
    state = state.copyWith(
      status: CallStatus.connected,
      callDuration: Duration.zero,
    );
  }

  void setEnded({String? reason}) {
    state = state.copyWith(status: CallStatus.ended, endReason: reason);
    // Auto-reset after short delay so UI can show "Call ended"
    Future.delayed(const Duration(seconds: 2), () {
      if (state.status == CallStatus.ended) {
        state = const CallState();
      }
    });
  }

  void tickDuration() {
    if (state.status == CallStatus.connected) {
      state = state.copyWith(
        callDuration: state.callDuration + const Duration(seconds: 1),
      );
    }
  }

  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);
  void toggleSpeaker() =>
      state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
  void toggleVideo() =>
      state = state.copyWith(isVideoEnabled: !state.isVideoEnabled);
  void toggleCamera() =>
      state = state.copyWith(isFrontCamera: !state.isFrontCamera);
}

final callStateProvider =
    StateNotifierProvider<CallStateNotifier, CallState>((ref) {
  return CallStateNotifier();
});
