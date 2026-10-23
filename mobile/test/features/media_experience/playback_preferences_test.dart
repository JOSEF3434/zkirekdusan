// test/features/media_experience/playback_preferences_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/media_experience/data/playback_preferences_repository.dart';
import 'package:mobile/features/media_experience/domain/playback_preferences.dart';
import 'package:mobile/features/media_experience/presentation/providers/playback_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlaybackPreferences Domain & Persistence Tests', () {
    test('Default values match expected requirements', () {
      const prefs = PlaybackPreferences();
      expect(prefs.autoplay, true);
      expect(prefs.defaultSpeed, 1.0);
      expect(prefs.downloadOnWifiOnly, true);
      expect(prefs.doubleTapSeekEnabled, true);
      expect(prefs.seekForwardSeconds, 5);
      expect(prefs.seekBackwardSeconds, 5);
      expect(prefs.autoHideControls, true);
      expect(prefs.autoHideDelaySeconds, 3);
    });

    test(
      'Allowed seek intervals and auto-hide delays contain standard options',
      () {
        expect(
          PlaybackPreferences.allowedSeekIntervals,
          containsAll([5, 10, 15, 20, 30]),
        );
        expect(
          PlaybackPreferences.allowedAutoHideDelays,
          containsAll([3, 5, 8, 10]),
        );
      },
    );

    test('Serialization and deserialization preserve all fields', () {
      const original = PlaybackPreferences(
        autoplay: false,
        defaultSpeed: 1.5,
        downloadOnWifiOnly: false,
        doubleTapSeekEnabled: false,
        seekForwardSeconds: 15,
        seekBackwardSeconds: 20,
        autoHideControls: false,
        autoHideDelaySeconds: 8,
      );

      final json = original.toJson();
      final restored = PlaybackPreferences.fromJson(json);

      expect(restored.autoplay, false);
      expect(restored.defaultSpeed, 1.5);
      expect(restored.downloadOnWifiOnly, false);
      expect(restored.doubleTapSeekEnabled, false);
      expect(restored.seekForwardSeconds, 15);
      expect(restored.seekBackwardSeconds, 20);
      expect(restored.autoHideControls, false);
      expect(restored.autoHideDelaySeconds, 8);
    });

    test(
      'Repository loads default preferences when storage is empty',
      () async {
        SharedPreferences.setMockInitialValues({});
        final sp = await SharedPreferences.getInstance();
        final repo = PlaybackPreferencesRepository(sp);

        final loaded = repo.load();
        expect(loaded.seekForwardSeconds, 5);
        expect(loaded.seekBackwardSeconds, 5);
        expect(loaded.doubleTapSeekEnabled, true);
        expect(loaded.autoHideControls, true);
      },
    );

    test('Repository persists and reloads custom preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final repo = PlaybackPreferencesRepository(sp);

      const toSave = PlaybackPreferences(
        seekForwardSeconds: 10,
        seekBackwardSeconds: 15,
        autoHideDelaySeconds: 5,
        doubleTapSeekEnabled: false,
        autoHideControls: false,
      );

      await repo.save(toSave);

      final reloaded = repo.load();
      expect(reloaded.seekForwardSeconds, 10);
      expect(reloaded.seekBackwardSeconds, 15);
      expect(reloaded.autoHideDelaySeconds, 5);
      expect(reloaded.doubleTapSeekEnabled, false);
      expect(reloaded.autoHideControls, false);
    });

    test(
      'Notifier setters validate allowed intervals and persist state',
      () async {
        SharedPreferences.setMockInitialValues({});
        final sp = await SharedPreferences.getInstance();
        final repo = PlaybackPreferencesRepository(sp);
        final notifier = PlaybackPreferencesNotifier(repo);

        // Seek forward valid update
        await notifier.setSeekForwardSeconds(10);
        expect(notifier.state.seekForwardSeconds, 10);

        // Seek forward invalid update rejected
        await notifier.setSeekForwardSeconds(999);
        expect(notifier.state.seekForwardSeconds, 10);

        // Seek backward valid update
        await notifier.setSeekBackwardSeconds(30);
        expect(notifier.state.seekBackwardSeconds, 30);

        // Double-tap toggle
        await notifier.setDoubleTapSeekEnabled(false);
        expect(notifier.state.doubleTapSeekEnabled, false);

        // Auto-hide controls toggle
        await notifier.setAutoHideControls(false);
        expect(notifier.state.autoHideControls, false);

        // Auto-hide delay valid update
        await notifier.setAutoHideDelaySeconds(8);
        expect(notifier.state.autoHideDelaySeconds, 8);

        // Auto-hide delay invalid update rejected
        await notifier.setAutoHideDelaySeconds(42);
        expect(notifier.state.autoHideDelaySeconds, 8);
      },
    );
  });
}
