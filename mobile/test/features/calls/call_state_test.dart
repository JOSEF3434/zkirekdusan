// test/features/calls/call_state_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/calls/providers/call_state_provider.dart';

void main() {
  group('CallState and CallStateNotifier Tests', () {
    late CallStateNotifier notifier;

    setUp(() {
      notifier = CallStateNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('initial state should be idle', () {
      expect(notifier.state.status, equals(CallStatus.idle));
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.callDuration, equals(Duration.zero));
      expect(notifier.state.isMuted, isFalse);
      expect(notifier.state.isSpeakerOn, isTrue);
      expect(notifier.state.isVideoEnabled, isTrue);
    });

    test('setCalling sets active calling state with contact details', () {
      notifier.setCalling(
        conversationId: 'conv_123',
        remoteUserId: 'user_456',
        remoteDisplayName: 'Aidyn Cody',
        remoteAvatarUrl: 'https://example.com/avatar.jpg',
        isVideoCall: false,
      );

      final state = notifier.state;
      expect(state.status, equals(CallStatus.calling));
      expect(state.isActive, isTrue);
      expect(state.conversationId, equals('conv_123'));
      expect(state.remoteUserId, equals('user_456'));
      expect(state.remoteDisplayName, equals('Aidyn Cody'));
      expect(state.remoteAvatarUrl, equals('https://example.com/avatar.jpg'));
      expect(state.isVideoCall, isFalse);
    });

    test(
      'setRinging sets incoming call state with SDP offer and caller info',
      () {
        notifier.setRinging(
          callerId: 'user_789',
          conversationId: 'conv_999',
          callerName: 'John Paul',
          callerAvatar: 'https://example.com/john.jpg',
          isVideoCall: true,
          offer: {'sdp': 'v=0...', 'type': 'offer'},
        );

        final state = notifier.state;
        expect(state.status, equals(CallStatus.ringing));
        expect(state.isActive, isTrue);
        expect(state.callerId, equals('user_789'));
        expect(state.remoteDisplayName, equals('John Paul'));
        expect(state.incomingOffer?['type'], equals('offer'));
        expect(state.isVideoCall, isTrue);
      },
    );

    test('setConnecting and setConnected transition appropriately', () {
      notifier.setCalling(
        conversationId: 'conv_123',
        remoteUserId: 'user_456',
        remoteDisplayName: 'Aidyn Cody',
        isVideoCall: false,
      );

      notifier.setConnecting();
      expect(notifier.state.status, equals(CallStatus.connecting));
      expect(notifier.state.isActive, isTrue);

      notifier.setConnected();
      expect(notifier.state.status, equals(CallStatus.connected));
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.callDuration, equals(Duration.zero));
    });

    test('tickDuration increments duration only when connected', () {
      notifier.setConnected();
      notifier.tickDuration();
      notifier.tickDuration();
      expect(notifier.state.callDuration, equals(const Duration(seconds: 2)));

      notifier.setIdle();
      notifier.tickDuration();
      // Should reset or not increment when idle
      expect(notifier.state.callDuration, equals(Duration.zero));
    });

    test(
      'toggleMute, toggleSpeaker, toggleVideo, toggleCamera flip states',
      () {
        expect(notifier.state.isMuted, isFalse);
        notifier.toggleMute();
        expect(notifier.state.isMuted, isTrue);
        notifier.toggleMute();
        expect(notifier.state.isMuted, isFalse);

        expect(notifier.state.isSpeakerOn, isTrue);
        notifier.toggleSpeaker();
        expect(notifier.state.isSpeakerOn, isFalse);

        expect(notifier.state.isVideoEnabled, isTrue);
        notifier.toggleVideo();
        expect(notifier.state.isVideoEnabled, isFalse);

        expect(notifier.state.isFrontCamera, isTrue);
        notifier.toggleCamera();
        expect(notifier.state.isFrontCamera, isFalse);
      },
    );

    test(
      'reactions, hand raised, recording, and collapsed mode work correctly',
      () {
        notifier.setReaction('🎉');
        expect(notifier.state.activeReaction, equals('🎉'));

        expect(notifier.state.isHandRaised, isFalse);
        notifier.toggleHandRaised();
        expect(notifier.state.isHandRaised, isTrue);

        expect(notifier.state.isRecording, isFalse);
        notifier.toggleRecording();
        expect(notifier.state.isRecording, isTrue);

        expect(notifier.state.isCollapsed, isFalse);
        notifier.setCollapsed(true);
        expect(notifier.state.isCollapsed, isTrue);
      },
    );

    test('remote media state updates properly', () {
      notifier.setRemoteMediaState(
        isMuted: true,
        isVideoEnabled: false,
        isScreenSharing: true,
      );

      expect(notifier.state.isRemoteMuted, isTrue);
      expect(notifier.state.isRemoteVideoEnabled, isFalse);
      expect(notifier.state.isScreenSharing, isTrue);
    });

    test('setEnded resets collapsed and sets end reason', () {
      notifier.setCollapsed(true);
      notifier.setEnded(reason: 'declined');

      expect(notifier.state.status, equals(CallStatus.ended));
      expect(notifier.state.endReason, equals('declined'));
      expect(notifier.state.isCollapsed, isFalse);
    });
  });
}
