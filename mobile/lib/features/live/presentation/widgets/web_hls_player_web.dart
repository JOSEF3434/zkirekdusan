// lib/features/live/presentation/widgets/web_hls_player_web.dart
//
// Flutter Web HLS (.m3u8) player powered by hls.js (loaded in web/index.html)
// with native HLS fallback for Safari, live DVR seekable range reporting,
// quality level switching, Fit/Fill scaling, and dynamic source size detection.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:mobile/features/live/domain/live_dvr_state.dart';
import 'package:mobile/features/live/presentation/widgets/web_hls_controller.dart';
import 'package:web/web.dart' as web;

@JS('Hls')
extension type _HlsJs._(JSObject _) implements JSObject {
  external factory _HlsJs([JSObject? config]);
  external static bool isSupported();
  @JS('Events')
  external static _HlsEvents get events;
  external double? get liveSyncPosition;
  external int get currentLevel;
  external set currentLevel(int level);
  external JSArray<JSObject>? get levels;
  external void loadSource(String url);
  external void attachMedia(web.HTMLVideoElement media);
  external void on(String event, JSFunction handler);
  external void recoverMediaError();
  external void destroy();
}

extension type _HlsEvents._(JSObject _) implements JSObject {
  @JS('MANIFEST_PARSED')
  external String get manifestParsed;
  @JS('LEVEL_SWITCHED')
  external String get levelSwitched;
  @JS('ERROR')
  external String get error;
}

class WebHlsPlayer extends StatefulWidget {
  final String url;
  final WebHlsController? controller;
  final VideoFitMode fitMode;
  final VoidCallback? onReady;
  final VoidCallback? onWaitingForStream;
  final VoidCallback? onDvrExpired;
  final VoidCallback? onStreamEnded;
  final void Function(String error)? onFatalError;
  final void Function(Size size)? onVideoSizeChanged;
  final bool showControls;

  const WebHlsPlayer({
    super.key,
    required this.url,
    this.controller,
    this.fitMode = VideoFitMode.fill,
    this.onReady,
    this.onWaitingForStream,
    this.onDvrExpired,
    this.onStreamEnded,
    this.onFatalError,
    this.onVideoSizeChanged,
    this.showControls = false,
  });

  @override
  State<WebHlsPlayer> createState() => _WebHlsPlayerState();
}

class _WebHlsPlayerState extends State<WebHlsPlayer> {
  static int _nextViewId = 0;

  late final String _viewType;
  web.HTMLDivElement? _container;
  web.HTMLVideoElement? _video;
  _HlsJs? _hls;
  bool _mutedForAutoplay = false;
  bool _mediaErrorRecoveredOnce = false;
  bool _readyNotified = false;
  bool _isBuffering = false;
  Size? _lastReportedSize;
  Timer? _syncTimer;
  web.HTMLCanvasElement? _sampleCanvas;
  int _sampleTick = 0;
  double _pendingPillarboxScale = 1.0;
  int _pendingPillarboxHits = 0;
  double _appliedPillarboxScale = 1.0;
  VideoFitMode _activeFitMode = VideoFitMode.fill;

  final List<StreamSubscription<web.Event>> _videoSubs = [];

  @override
  void initState() {
    super.initState();
    _viewType = 'zkire-web-hls-${_nextViewId++}';

    _activeFitMode = widget.fitMode;
    final container = web.document.createElement('div') as web.HTMLDivElement;
    container.style
      ..display = 'block'
      ..position = 'relative'
      ..width = '100%'
      ..height = '100%'
      ..overflow = 'hidden'
      ..margin = '0'
      ..padding = '0'
      ..backgroundColor = '#000000'
      ..pointerEvents = widget.showControls ? 'auto' : 'none';

    final video = web.document.createElement('video') as web.HTMLVideoElement;
    video.crossOrigin = 'anonymous';
    video.style
      ..position = 'absolute'
      ..top = '0'
      ..left = '0'
      ..right = '0'
      ..bottom = '0'
      ..display = 'block'
      ..width = '100%'
      ..height = '100%'
      ..maxWidth = 'none'
      ..maxHeight = 'none'
      ..objectFit = widget.fitMode == VideoFitMode.fill ? 'cover' : 'contain'
      ..objectPosition = 'center center'
      ..transformOrigin = 'center center'
      ..transition = 'transform 180ms ease-out'
      ..backgroundColor = 'transparent'
      ..pointerEvents = widget.showControls ? 'auto' : 'none';
    video.autoplay = true;
    video.playsInline = true;
    video.controls = widget.showControls;
    container.appendChild(video);
    _container = container;
    _video = video;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => container,
    );

    _bindVideoListeners(video);
    _attachController();
    _attachSource(widget.url);

    _syncTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _emitSnapshot(),
    );
  }

  @override
  void didUpdateWidget(covariant WebHlsPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      _attachController();
    }
    if (oldWidget.fitMode != widget.fitMode && _video != null) {
      _activeFitMode = widget.fitMode;
      _applyVideoFitStyles();
    }
    if (oldWidget.showControls != widget.showControls && _video != null) {
      _video!.controls = widget.showControls;
      final ptr = widget.showControls ? 'auto' : 'none';
      _video!.style.pointerEvents = ptr;
      _container?.style.pointerEvents = ptr;
    }
    if (oldWidget.url != widget.url) {
      _attachSource(widget.url);
    }
  }

  void _attachController() {
    widget.controller?.attach(
      play: () async {
        final v = _video;
        if (v == null) return;
        await _playWithAutoplayFallback(v);
        _emitSnapshot();
      },
      pause: () {
        _video?.pause();
        _emitSnapshot();
      },
      seekTo: (target) {
        final v = _video;
        if (v == null) return;
        var targetSec = target.inMilliseconds / 1000.0;
        final seekable = v.seekable;
        if (seekable.length > 0) {
          final start = seekable.start(0);
          final end = seekable.end(seekable.length - 1);
          if (targetSec < start) targetSec = start;
          if (targetSec > end) targetSec = end;
        }
        v.currentTime = targetSec;
        _emitSnapshot();
      },
      seekToLiveEdge: () {
        final v = _video;
        if (v == null) return;
        final liveSync = _hls?.liveSyncPosition;
        if (liveSync != null && liveSync.isFinite && liveSync > 0) {
          v.currentTime = liveSync;
        } else if (v.seekable.length > 0) {
          final end = v.seekable.end(v.seekable.length - 1);
          v.currentTime = (end - 4.0).clamp(0.0, end);
        }
        if (v.paused) {
          unawaited(_playWithAutoplayFallback(v));
        }
        _emitSnapshot();
      },
      setVolume: (vol) {
        final v = _video;
        if (v == null) return;
        final clamped = vol.clamp(0.0, 1.0);
        v.volume = clamped;
        v.muted = clamped == 0.0;
        if (clamped > 0 && mounted && _mutedForAutoplay) {
          setState(() => _mutedForAutoplay = false);
        }
        _emitSnapshot();
      },
      setMuted: (muted) {
        final v = _video;
        if (v == null) return;
        v.muted = muted;
        if (!muted && mounted && _mutedForAutoplay) {
          setState(() => _mutedForAutoplay = false);
        }
        _emitSnapshot();
      },
      setQuality: (levelIndex) {
        final h = _hls;
        if (h == null) return;
        h.currentLevel = levelIndex;
        _emitSnapshot();
      },
      setFitMode: (mode) {
        _activeFitMode = mode;
        _applyVideoFitStyles();
      },
    );
  }

  void _bindVideoListeners(web.HTMLVideoElement video) {
    _videoSubs.addAll([
      video.onLoadedMetadata.listen((_) => _checkVideoSize(video)),
      video.onResize.listen((_) => _checkVideoSize(video)),
      video.onPlaying.listen((_) {
        _isBuffering = false;
        _checkVideoSize(video);
        _emitSnapshot();
      }),
      video.onPause.listen((_) => _emitSnapshot()),
      video.onWaiting.listen((_) {
        _isBuffering = true;
        _emitSnapshot();
      }),
      video.onCanPlay.listen((_) {
        _isBuffering = false;
        _checkVideoSize(video);
        _emitSnapshot();
      }),
      video.onSeeked.listen((_) => _emitSnapshot()),
      video.onVolumeChange.listen((_) => _emitSnapshot()),
      video.onEnded.listen((_) {
        _isBuffering = false;
        _emitSnapshot();
        widget.onStreamEnded?.call();
      }),
    ]);
  }

  void _applyVideoFitStyles() {
    final v = _video;
    if (v == null) return;
    final isFill = _activeFitMode == VideoFitMode.fill;
    final scale = isFill ? _appliedPillarboxScale : 1.0;
    v.style
      ..objectFit = isFill ? 'cover' : 'contain'
      ..objectPosition = 'center center'
      ..transform = scale > 1.02 ? 'scale(${scale.toStringAsFixed(3)})' : 'none';
  }

  void _probePillarboxCrop(web.HTMLVideoElement video) {
    if (_activeFitMode != VideoFitMode.fill) {
      if (_appliedPillarboxScale != 1.0) {
        _appliedPillarboxScale = 1.0;
        _applyVideoFitStyles();
      }
      return;
    }

    final vw = video.videoWidth;
    final vh = video.videoHeight;
    if (vw <= 0 || vh <= 0 || vw <= vh || video.paused || video.ended) {
      return;
    }

    const int sampleW = 64;
    const int sampleH = 36;
    try {
      final canvas = _sampleCanvas ??=
          (web.document.createElement('canvas') as web.HTMLCanvasElement)
            ..width = sampleW
            ..height = sampleH;
      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
      if (ctx == null) return;
      ctx.drawImage(video, 0, 0, sampleW, sampleH);
      final data = ctx.getImageData(0, 0, sampleW, sampleH).data.toDart;

      const sampleRows = [5, 11, 18, 25, 31];
      int colPeak(int x) {
        int peak = 0;
        for (final y in sampleRows) {
          final idx = (y * sampleW + x) * 4;
          final r = data[idx];
          final g = data[idx + 1];
          final b = data[idx + 2];
          final m = r > g ? (r > b ? r : b) : (g > b ? g : b);
          if (m > peak) peak = m;
        }
        return peak;
      }

      int leftBar = 0;
      while (leftBar < 24 && colPeak(leftBar) <= 14) {
        leftBar++;
      }
      int rightBar = 0;
      while (rightBar < 24 && colPeak(sampleW - 1 - rightBar) <= 14) {
        rightBar++;
      }

      int centerPeak = 0;
      for (int x = leftBar; x < sampleW - rightBar; x++) {
        final p = colPeak(x);
        if (p > centerPeak) centerPeak = p;
      }

      double candidateScale = 1.0;
      if (leftBar >= 8 &&
          rightBar >= 8 &&
          (leftBar - rightBar).abs() <= 3 &&
          centerPeak >= 24) {
        final bar = leftBar < rightBar ? leftBar : rightBar;
        final activeFrac = (sampleW - bar * 2) / sampleW;
        if (activeFrac >= 0.26 && activeFrac <= 0.80) {
          candidateScale = (1.0 / activeFrac).clamp(1.0, 3.25);
        }
      }

      if ((candidateScale - _pendingPillarboxScale).abs() <= 0.12) {
        _pendingPillarboxHits++;
      } else {
        _pendingPillarboxScale = candidateScale;
        _pendingPillarboxHits = 1;
      }

      if (_pendingPillarboxHits >= 2 &&
          (_appliedPillarboxScale - candidateScale).abs() > 0.08) {
        _appliedPillarboxScale = candidateScale;
        _applyVideoFitStyles();
      }
    } catch (_) {
      // Cross-origin native stream without CORS headers: ignore silently.
    }
  }

  void _checkVideoSize(web.HTMLVideoElement video) {
    final w = video.videoWidth.toDouble();
    final h = video.videoHeight.toDouble();
    if (w > 0 && h > 0) {
      final size = Size(w, h);
      if (_lastReportedSize != size) {
        _lastReportedSize = size;
        widget.onVideoSizeChanged?.call(size);
      }
    }
  }

  List<VideoQualityOption> _readQualities() {
    final h = _hls;
    if (h == null) return const [VideoQualityOption.auto];
    final rawLevels = h.levels?.dartify();
    if (rawLevels is! List || rawLevels.isEmpty) {
      return const [VideoQualityOption.auto];
    }

    final options = <VideoQualityOption>[VideoQualityOption.auto];
    for (int i = 0; i < rawLevels.length; i++) {
      final item = rawLevels[i];
      if (item is Map) {
        final height = (item['height'] as num?)?.toInt();
        final width = (item['width'] as num?)?.toInt();
        final bitrate = (item['bitrate'] as num?)?.toInt();
        final label = height != null && height > 0
            ? '${height}p'
            : (bitrate != null && bitrate > 0
                ? '${(bitrate / 1000).round()} kbps'
                : 'Quality ${i + 1}');
        options.add(
          VideoQualityOption(
            index: i,
            label: label,
            bitrate: bitrate,
            width: width,
            height: height,
          ),
        );
      }
    }
    return options;
  }

  void _emitSnapshot() {
    final ctrl = widget.controller;
    final video = _video;
    if (!mounted || ctrl == null || video == null) return;

    _sampleTick = (_sampleTick + 1) % 4;
    if (_sampleTick == 0) {
      _probePillarboxCrop(video);
    }

    Duration seekStart = Duration.zero;
    Duration seekEnd = Duration.zero;
    final seekable = video.seekable;
    if (seekable.length > 0) {
      seekStart = _secToDuration(seekable.start(0));
      seekEnd = _secToDuration(seekable.end(seekable.length - 1));
    }

    Duration bufEnd = Duration.zero;
    final buffered = video.buffered;
    if (buffered.length > 0) {
      bufEnd = _secToDuration(buffered.end(buffered.length - 1));
    }

    final liveSyncSec = _hls?.liveSyncPosition;
    final liveSync = (liveSyncSec != null && liveSyncSec.isFinite)
        ? _secToDuration(liveSyncSec)
        : null;

    ctrl.value = ctrl.value.copyWith(
      isReady: _readyNotified,
      isPlaying: !video.paused && !video.ended,
      isBuffering: _isBuffering,
      isSeeking: video.seeking,
      isMuted: video.muted,
      volume: video.volume.toDouble().clamp(0.0, 1.0),
      position: _secToDuration(video.currentTime),
      seekableStart: seekStart,
      seekableEnd: seekEnd,
      bufferedEnd: bufEnd,
      liveSyncPosition: liveSync,
      videoSize: _lastReportedSize,
      qualities: _readQualities(),
      currentQualityIndex: _hls?.currentLevel ?? -1,
      isEnded: video.ended,
    );
  }

  Duration _secToDuration(num sec) {
    final s = sec.toDouble();
    if (!s.isFinite || s <= 0) return Duration.zero;
    return Duration(milliseconds: (s * 1000).round());
  }

  void _attachSource(String url) {
    _teardownHls();
    final video = _video;
    if (video == null || url.isEmpty) return;

    _mediaErrorRecoveredOnce = false;
    _readyNotified = false;
    _isBuffering = true;
    _pendingPillarboxScale = 1.0;
    _pendingPillarboxHits = 0;
    _appliedPillarboxScale = 1.0;
    _applyVideoFitStyles();

    final hasHlsGlobal = globalContext.hasProperty('Hls'.toJS).toDart;
    if (hasHlsGlobal && _HlsJs.isSupported()) {
      final config = <String, Object?>{
        'enableWorker': true,
        'lowLatencyMode': false,
        'liveSyncDurationCount': 3,
        'liveMaxLatencyDurationCount': 99999,
        'maxBufferLength': 30,
        'maxMaxBufferLength': 60,
        'backBufferLength': 90,
        'manifestLoadingMaxRetry': 4,
        'manifestLoadingRetryDelay': 1500,
      }.jsify() as JSObject;

      final hls = _HlsJs(config);
      _hls = hls;

      hls.on(
        _HlsJs.events.manifestParsed,
        ((JSAny? event, JSAny? data) {
          if (!mounted) return;
          _notifyReadyOnce();
          _checkVideoSize(video);
          unawaited(_playWithAutoplayFallback(video));
          _emitSnapshot();
        }).toJS,
      );

      hls.on(
        _HlsJs.events.levelSwitched,
        ((JSAny? event, JSAny? data) {
          if (!mounted) return;
          _checkVideoSize(video);
          _emitSnapshot();
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
          final details = errMap['details']?.toString() ?? errType;
          final resp = errMap['response'];
          final statusCode =
              resp is Map ? (resp['code'] as num?)?.toInt() : null;

          // HTTP 410 Gone (or 404 fragment fetch after ready playback) means paused
          // playhead fell outside the retained server DVR retention window.
          if (statusCode == 410 ||
              (_readyNotified &&
                  statusCode == 404 &&
                  details.contains('fragLoad'))) {
            debugPrint(
              '[WebHlsPlayer] DVR window expired (details=$details, status=$statusCode)',
            );
            widget.controller?.value =
                widget.controller!.value.copyWith(dvrExpired: true);
            widget.onDvrExpired?.call();
            return;
          }

          if (statusCode == 404 ||
              statusCode == 423 ||
              errType == 'networkError') {
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
      _videoSubs.add(
        video.onCanPlay.listen((_) {
          if (!mounted) return;
          _notifyReadyOnce();
          _checkVideoSize(video);
          unawaited(_playWithAutoplayFallback(video));
        }),
      );
      _videoSubs.add(
        video.onError.listen((_) {
          if (!mounted) return;
          widget.onWaitingForStream?.call();
        }),
      );
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
    _emitSnapshot();
  }

  void _unmute() {
    final video = _video;
    if (video == null) return;
    video.muted = false;
    unawaited(video.play().toDart.then((_) {}, onError: (_) {}));
    if (mounted) {
      setState(() => _mutedForAutoplay = false);
    }
    _emitSnapshot();
  }

  void _teardownHls() {
    try {
      _hls?.destroy();
    } catch (_) {}
    _hls = null;
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    for (final s in _videoSubs) {
      unawaited(s.cancel());
    }
    _videoSubs.clear();
    widget.controller?.detach();
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
    _container = null;
    _sampleCanvas = null;
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
            top: 52,
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
                      Icon(
                        Icons.volume_off_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
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
