import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/pip_service.dart';
import 'package:mobile/core/presentation/providers/pip_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.zikrekidusan.mobile/pip');
  final List<MethodCall> channelCalls = [];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    PipService.instance.resetForTesting();
    channelCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      channelCalls.add(methodCall);
      switch (methodCall.method) {
        case 'isPipSupported':
          return true;
        case 'enableAutoPip':
        case 'disableAutoPip':
        case 'updatePlaybackState':
          return true;
        case 'enterPip':
          return true;
        case 'isInPip':
          return false;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    PipService.instance.resetForTesting();
  });

  group('PipService Native Bridge Tests', () {
    test('initialize checks hardware and OS PiP support', () async {
      final pip = PipService.instance;
      await pip.initialize();

      expect(pip.isSupported, isTrue);
      expect(channelCalls.any((c) => c.method == 'isPipSupported'), isTrue);
    });

    test('enableAutoPip sends correct rational aspect ratio and parameters', () async {
      final pip = PipService.instance;
      await pip.initialize();

      await pip.enableAutoPip(
        isPlaying: true,
        aspectRatio: 16 / 9,
        title: 'Sunday Liturgy',
      );

      final call = channelCalls.firstWhere((c) => c.method == 'enableAutoPip');
      expect(call.arguments['enabled'], isTrue);
      expect(call.arguments['isPlaying'], isTrue);
      expect(call.arguments['numerator'], equals(16));
      expect(call.arguments['denominator'], equals(9));
      expect(call.arguments['title'], equals('Sunday Liturgy'));
    });

    test('updatePlaybackState notifies native platform when video pauses or plays', () async {
      final pip = PipService.instance;
      await pip.initialize();

      await pip.updatePlaybackState(isPlaying: false);
      final pauseCall = channelCalls.lastWhere((c) => c.method == 'updatePlaybackState');
      expect(pauseCall.arguments['isPlaying'], isFalse);

      await pip.updatePlaybackState(isPlaying: true);
      final playCall = channelCalls.lastWhere((c) => c.method == 'updatePlaybackState');
      expect(playCall.arguments['isPlaying'], isTrue);
    });

    test('disableAutoPip cancels automatic PiP entrance', () async {
      final pip = PipService.instance;
      await pip.initialize();

      await pip.enableAutoPip(isPlaying: true);
      expect(pip.isAutoPipEnabled, isTrue);

      await pip.disableAutoPip();
      expect(channelCalls.any((c) => c.method == 'disableAutoPip'), isTrue);
      expect(pip.isAutoPipEnabled, isFalse);
    });

    test('native onPictureInPictureModeChanged dispatches to listeners', () async {
      final pip = PipService.instance;
      await pip.initialize();

      bool? notifiedInPip;
      pip.addPipModeListener((inPip) {
        notifiedInPip = inPip;
      });

      // Simulate native platform callback into Flutter
      final binding = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      await binding.handlePlatformMessage(
        'com.zikrekidusan.mobile/pip',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onPictureInPictureModeChanged', {'isInPip': true}),
        ),
        (_) {},
      );

      expect(notifiedInPip, isTrue);
      expect(pip.isInPip, isTrue);
    });

    test('native onPipAction dispatches remote controls (play/pause)', () async {
      final pip = PipService.instance;
      await pip.initialize();

      String? triggeredAction;
      pip.addPipActionListener((action) {
        triggeredAction = action;
      });

      final binding = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      await binding.handlePlatformMessage(
        'com.zikrekidusan.mobile/pip',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onPipAction', {'action': 'pause'}),
        ),
        (_) {},
      );

      expect(triggeredAction, equals('pause'));
    });
  });

  group('PipNotifier Riverpod Provider Tests', () {
    test('registers active media and updates provider state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pipProvider.notifier);
      await notifier.registerActiveMedia(
        contentId: 'vid-456',
        isPlaying: true,
        aspectRatio: 16 / 9,
        title: 'Sample Video',
      );

      final state = container.read(pipProvider);
      expect(state.activeContentId, equals('vid-456'));
      expect(state.isAutoPipEnabled, isTrue);

      await notifier.updatePlaybackState(isPlaying: false);
      expect(container.read(pipProvider).isAutoPipEnabled, isFalse);

      await notifier.unregisterActiveMedia('vid-456');
      expect(container.read(pipProvider).activeContentId, isNull);
    });
  });
}
