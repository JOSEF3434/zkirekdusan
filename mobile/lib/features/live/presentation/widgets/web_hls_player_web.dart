// lib/features/live/presentation/widgets/web_hls_player_web.dart
//
// Flutter Web HLS (.m3u8) player powered by hls.js (loaded in web/index.html)
// with native HLS fallback for Safari. Fixes video_player_web's inability to
// decode .m3u8 streams in Chrome, Edge, and Firefox.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('Hls')
extension type _HlsJs._(JSObject _) implements JSObject {
  external factory _HlsJs([JSObject? config]);
  external static bool isSupported();
  @JS('Events')
  external static _HlsEvents get events;
  external void loadSource(String url);
  external void attachMedia(web.HTMLVideoElement media);
  external void on(String event, JSFunction handler);
  external void recoverMediaError();
  external void destroy();
}

extension type _HlsEvents._(JSObject _) implements JSObject {
  @JS('MANIFEST_PARSED')
  external String get manifestParsed;
  @JS('ERROR')
  external String get error;
}

class WebHlsPlayer extends StatefulWidget {
  final String url;
  final VoidCallback? onReady;
  final VoidCallback? onWaitingForStream;
  final void Function(String error)? onFatalError;
  final bool showControls;

  const WebHlsPlayer({
    super.key,
    required this.url,
    this.onReady,
    this.onWaitingForStream,
    this.onFatalError,
    this.showControls = false,
  });

  @override
  State<WebHlsPlayer> createState() => _WebHlsPlayerState();
}

class _WebHlsPlayerState extends State<WebHlsPlayer> {
  static int _nextViewId = 0;

  late final String _viewType;
  web.HTMLVideoElement? _video;
  _HlsJs? _hls;
  bool _mutedForAutoplay = false;
  bool _mediaErrorRecoveredOnce = false;
  bool _readyNotified = false;
  StreamSubscription<web.Event>? _canPlaySub;
  StreamSubscription<web.Event>? _errorSub;

  @override
  void initState() {
    super.initState();
    _viewType = 'zkire-web-hls-${_nextViewId++}';

    final video = web.document.createElement('video') as web.HTMLVideoElement;
    video.style
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'contain'
      ..backgroundColor = '#000000'
      ..pointerEvents = widget.showControls ? 'auto' : 'none';
    video.autoplay = true;
    video.playsInline = true;
    video.controls = widget.showControls;
    _video = video;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => video,
    );

    _attachSource(widget.url);
  }

  @override
  void didUpdateWidget(covariant WebHlsPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _attachSource(widget.url);
    } else if (oldWidget.showControls != widget.showControls && _video != null) {
      _video!.controls = widget.showControls;
      _video!.style.pointerEvents = widget.showControls ? 'auto' : 'none';
    }
  }

  void _attachSource(String url) {
    _teardownHls();
    final video = _video;
    if (video == null || url.isEmpty) return;

    _mediaErrorRecoveredOnce = false;
    _readyNotified = false;

    final hasHlsGlobal = globalContext.hasProperty('Hls'.toJS).toDart;
    if (hasHlsGlobal && _HlsJs.isSupported()) {
      final config = <String, Object?>{
        'enableWorker': true,
        'lowLatencyMode': true,
        'liveSyncDurationCount': 3,
        'manifestLoadingMaxRetry': 3,
        'manifestLoadingRetryDelay': 1500,
      }.jsify() as JSObject;

      final hls = _HlsJs(config);
      _hls = hls;

      hls.on(
        _HlsJs.events.manifestParsed,
        ((JSAny? event, JSAny? data) {
          if (!mounted) return;
          _notifyReadyOnce();
          unawaited(_playWithAutoplayFallback(video));
        }).toJS,
      );

      hls.on(
        _HlsJs.events.error,
        ((JSAny? event, JSAny? data) {
          if (!mounted) return;
          final errMap = data?.dartify();
          if (errMap is! Map) return;
          final isFatal = errMap['fatal'] == true;
          if (!isFatal) return;

          final errType = errMap['type']?.toString() ?? 'unknown';
          final resp = errMap['response'];
          final statusCode = resp is Map ? (resp['code'] as num?)?.toInt() : null;

          if (statusCode == 404 || statusCode == 423 || errType == 'networkError') {
            debugPrint(
              '[WebHlsPlayer] Stream manifest unavailable (type=$errType, status=$statusCode)',
            );
            _teardownHls();
            widget.onWaitingForStream?.call();
            return;
          }

          if (errType == 'mediaError' && !_mediaErrorRecoveredOnce) {
            _mediaErrorRecoveredOnce = true;
            debugPrint('[WebHlsPlayer] Recovering from fatal mediaError...');
            hls.recoverMediaError();
            return;
          }

          final details = errMap['details']?.toString() ?? errType;
          _teardownHls();
          widget.onFatalError?.call('HLS error ($details)');
        }).toJS,
      );

      hls.loadSource(url);
      hls.attachMedia(video);
      return;
    }

    // Native HLS fallback (e.g. Safari on macOS/iOS)
    if (video.canPlayType('application/vnd.apple.mpegurl').isNotEmpty) {
      _canPlaySub = video.onCanPlay.listen((_) {
        if (!mounted) return;
        _notifyReadyOnce();
        unawaited(_playWithAutoplayFallback(video));
      });
      _errorSub = video.onError.listen((_) {
        if (!mounted) return;
        widget.onWaitingForStream?.call();
      });
      video.src = url;
      video.load();
      return;
    }

    widget.onFatalError?.call(
      'HLS playback requires hls.js or native browser MPEGURL support.',
    );
  }

  void _notifyReadyOnce() {
    if (_readyNotified) return;
    _readyNotified = true;
    widget.onReady?.call();
  }

  Future<void> _playWithAutoplayFallback(web.HTMLVideoElement video) async {
    try {
      await video.play().toDart;
    } catch (_) {
      // Browsers may block unmuted autoplay until user interaction.
      video.muted = true;
      if (mounted) {
        setState(() => _mutedForAutoplay = true);
      }
      try {
        await video.play().toDart;
      } catch (e) {
        debugPrint('[WebHlsPlayer] Autoplay fallback failed: $e');
      }
    }
  }

  void _unmute() {
    final video = _video;
    if (video == null) return;
    video.muted = false;
    unawaited(video.play().toDart.then((_) {}, onError: (_) {}));
    if (mounted) {
      setState(() => _mutedForAutoplay = false);
    }
  }

  void _teardownHls() {
    _canPlaySub?.cancel();
    _canPlaySub = null;
    _errorSub?.cancel();
    _errorSub = null;
    try {
      _hls?.destroy();
    } catch (_) {}
    _hls = null;
  }

  @override
  void dispose() {
    _teardownHls();
    final video = _video;
    if (video != null) {
      try {
        video.pause();
        video.removeAttribute('src');
        video.load();
      } catch (_) {}
      _video = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: _viewType),
        if (_mutedForAutoplay)
          Positioned(
            left: 12,
            bottom: 12,
            child: Material(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _unmute,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_off_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Tap to unmute',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
