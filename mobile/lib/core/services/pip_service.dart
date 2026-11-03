// lib/core/services/pip_service.dart
// Native Picture-in-Picture bridge for Android and iOS.
// Handles auto-enter PiP on Home/minimize, native OS playback controls (play/pause),
// aspect ratio negotiation, and lifecycle transition syncing.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipService {
  PipService._();
  static final PipService instance = PipService._();

  static const MethodChannel _channel = MethodChannel('com.zikrekidusan.mobile/pip');

  bool _isInitialized = false;
  bool _isPipSupported = false;
  bool _isInPip = false;
  bool _isAutoPipEnabled = false;
  bool? _lastReportedIsPlaying;

  final List<void Function(bool isInPip)> _pipModeListeners = [];
  final List<void Function(String action)> _pipActionListeners = [];

  bool get isSupported => _isPipSupported;
  bool get isInPip => _isInPip;
  bool get isAutoPipEnabled => _isAutoPipEnabled;

  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _isPipSupported = false;
    _isInPip = false;
    _isAutoPipEnabled = false;
    _lastReportedIsPlaying = null;
    _pipModeListeners.clear();
    _pipActionListeners.clear();
  }

  /// Register listeners for native PiP window transitions
  void addPipModeListener(void Function(bool isInPip) listener) {
    if (!_pipModeListeners.contains(listener)) {
      _pipModeListeners.add(listener);
    }
  }

  void removePipModeListener(void Function(bool isInPip) listener) {
    _pipModeListeners.remove(listener);
  }

  /// Register listeners for remote controls pressed inside the floating PiP window (play/pause)
  void addPipActionListener(void Function(String action) listener) {
    if (!_pipActionListeners.contains(listener)) {
      _pipActionListeners.add(listener);
    }
  }

  void removePipActionListener(void Function(String action) listener) {
    _pipActionListeners.remove(listener);
  }

  /// Initialize channel handlers and check hardware/OS support
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb || !isMobile) {
      _isPipSupported = false;
      return;
    }

    _channel.setMethodCallHandler(_handleNativeCall);

    try {
      final supported = await _channel.invokeMethod<bool>('isPipSupported');
      _isPipSupported = supported ?? false;
    } catch (e) {
      debugPrint('[PipService] isPipSupported check failed: $e');
      _isPipSupported = false;
    }
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onPictureInPictureModeChanged':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final inPip = args?['isInPip'] as bool? ?? false;
        _isInPip = inPip;
        debugPrint('[PipService] onPictureInPictureModeChanged: inPip=$inPip');
        for (final listener in List.of(_pipModeListeners)) {
          listener(inPip);
        }
        break;

      case 'onPipAction':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final action = args?['action'] as String? ?? '';
        debugPrint('[PipService] onPipAction received: action=$action');
        if (action.isNotEmpty) {
          for (final listener in List.of(_pipActionListeners)) {
            listener(action);
          }
        }
        break;

      default:
        break;
    }
  }

  /// Enable automatic OS-level PiP entry when the user minimizes or presses Home.
  Future<void> enableAutoPip({
    required bool isPlaying,
    double aspectRatio = 16 / 9,
    String? title,
  }) async {
    if (!_isPipSupported) return;

    _isAutoPipEnabled = true;
    _lastReportedIsPlaying = isPlaying;
    final rational = _toRational(aspectRatio);

    try {
      await _channel.invokeMethod('enableAutoPip', {
        'enabled': true,
        'isPlaying': isPlaying,
        'numerator': rational.numerator,
        'denominator': rational.denominator,
        'title': title,
      });
    } catch (e) {
      debugPrint('[PipService] enableAutoPip error: $e');
    }
  }

  /// Disable automatic OS-level PiP entry (e.g. when video paused, completed, or screen exited).
  Future<void> disableAutoPip() async {
    if (!_isPipSupported || !_isAutoPipEnabled) return;

    _isAutoPipEnabled = false;
    _lastReportedIsPlaying = false;
    try {
      await _channel.invokeMethod('disableAutoPip');
    } catch (e) {
      debugPrint('[PipService] disableAutoPip error: $e');
    }
  }

  /// Updates whether the active video is actively playing or paused so that
  /// native OS PiP controls reflect the accurate state, and auto-entry is inhibited while paused.
  Future<void> updatePlaybackState({required bool isPlaying}) async {
    if (!_isPipSupported) return;
    if (_lastReportedIsPlaying == isPlaying) return;
    _lastReportedIsPlaying = isPlaying;

    try {
      await _channel.invokeMethod('updatePlaybackState', {
        'isPlaying': isPlaying,
      });
    } catch (e) {
      debugPrint('[PipService] updatePlaybackState error: $e');
    }
  }

  /// Explicitly enter native Picture-in-Picture mode on demand.
  Future<bool> enterPip({double aspectRatio = 16 / 9}) async {
    if (!_isPipSupported) return false;

    final rational = _toRational(aspectRatio);
    try {
      final success = await _channel.invokeMethod<bool>('enterPip', {
        'numerator': rational.numerator,
        'denominator': rational.denominator,
      });
      return success ?? false;
    } catch (e) {
      debugPrint('[PipService] enterPip error: $e');
      return false;
    }
  }

  /// Converts float aspect ratio to safe integer ratio within Android's 1:2.39 to 2.39:1 bounds
  _Rational _toRational(double ratio) {
    if (ratio.isNaN || ratio <= 0) {
      return const _Rational(16, 9);
    }
    // Android valid range: 0.418410 to 2.390000
    final clamped = ratio.clamp(0.42, 2.38);

    // Common presets
    if ((clamped - (16 / 9)).abs() < 0.05) return const _Rational(16, 9);
    if ((clamped - (4 / 3)).abs() < 0.05) return const _Rational(4, 3);
    if ((clamped - 1.0).abs() < 0.05) return const _Rational(1, 1);
    if ((clamped - (9 / 16)).abs() < 0.05) return const _Rational(9, 16);

    final num = (clamped * 100).round();
    return _Rational(num, 100);
  }
}

class _Rational {
  final int numerator;
  final int denominator;

  const _Rational(this.numerator, this.denominator);
}
