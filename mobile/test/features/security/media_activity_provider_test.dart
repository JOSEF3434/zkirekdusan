import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/security/presentation/providers/media_activity_provider.dart';

void main() {
  group('MediaActivityNotifier Lifecycle and State Tests', () {
    test('startSession registers session and updates state in microtask', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mediaActivityProvider.notifier);
      expect(container.read(mediaActivityProvider).hasActiveSession, isFalse);

      notifier.startSession('session-1', MediaSessionKind.liveViewer);
      // Wait for deferred microtask update
      await Future<void>.delayed(Duration.zero);

      final state = container.read(mediaActivityProvider);
      expect(state.hasActiveSession, isTrue);
      expect(state.hasLiveViewer, isTrue);
      expect(state.kindOf('session-1'), MediaSessionKind.liveViewer);
    });

    test('endSession unregisters session safely without throwing in dispose lifecycles', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mediaActivityProvider.notifier);
      notifier.startSession('session-1', MediaSessionKind.videoPlayback);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(mediaActivityProvider).hasActiveSession, isTrue);

      // Calling endSession modifies the state safely via microtask
      notifier.endSession('session-1');
      await Future<void>.delayed(Duration.zero);

      expect(container.read(mediaActivityProvider).hasActiveSession, isFalse);
    });

    test('multiple session tracking with distinct kinds', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mediaActivityProvider.notifier);
      notifier.startSession('s-viewer', MediaSessionKind.liveViewer);
      notifier.startSession('s-broadcaster', MediaSessionKind.liveBroadcaster);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(mediaActivityProvider);
      expect(state.sessions.length, 2);
      expect(state.hasLiveViewer, isTrue);
      expect(state.hasLiveBroadcaster, isTrue);

      notifier.clearSessionsOfKind(MediaSessionKind.liveBroadcaster);
      await Future<void>.delayed(Duration.zero);

      final updatedState = container.read(mediaActivityProvider);
      expect(updatedState.sessions.length, 1);
      expect(updatedState.hasLiveViewer, isTrue);
      expect(updatedState.hasLiveBroadcaster, isFalse);

      notifier.clearAll();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(mediaActivityProvider).sessions.isEmpty, isTrue);
    });
  });
}
