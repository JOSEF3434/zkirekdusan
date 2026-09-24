// lib/features/live/presentation/widgets/live_stream_progress_bar.dart
// A persistent horizontal live-position progress bar and elapsed duration indicator
// for the viewer screen (YouTube Live style).
//
// Key requirements met:
// - Server-sourced start time (startedAt) to compute elapsed time.
// - Survives viewer reconnects and app backgrounding without resetting to 0.
// - Pure elapsed-time indicator (non-seekable live position bar).
// - Thin horizontal bar with a pulsing red live marker moving left-to-right.

import 'dart:async';
import 'package:flutter/material.dart';

class LiveStreamProgressBar extends StatefulWidget {
  final String? startedAt;
  final bool showElapsedLabel;
  final double barHeight;

  const LiveStreamProgressBar({
    super.key,
    required this.startedAt,
    this.showElapsedLabel = false,
    this.barHeight = 3.5,
  });

  @override
  State<LiveStreamProgressBar> createState() => _LiveStreamProgressBarState();
}

class _LiveStreamProgressBarState extends State<LiveStreamProgressBar>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? _timer;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  String _formattedElapsed = '00:00';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _parseAndStart();
  }

  @override
  void didUpdateWidget(covariant LiveStreamProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt) {
      _parseAndStart();
    }
  }

  void _parseAndStart() {
    _timer?.cancel();
    if (widget.startedAt != null && widget.startedAt!.isNotEmpty) {
      _startTime = DateTime.tryParse(widget.startedAt!)?.toLocal();
    } else {
      _startTime = null;
    }

    _calculateElapsed();

    if (_startTime != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _calculateElapsed();
      });
    }
  }

  void _calculateElapsed() {
    if (_startTime == null) {
      if (_formattedElapsed != '00:00') {
        setState(() {
          _elapsed = Duration.zero;
          _formattedElapsed = '00:00';
        });
      }
      return;
    }

    final now = DateTime.now();
    final diff = now.isAfter(_startTime!) ? now.difference(_startTime!) : Duration.zero;
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    final formatted = diff.inHours > 0 ? '$h:$m:$s' : '$m:$s';

    if (_formattedElapsed != formatted) {
      setState(() {
        _elapsed = diff;
        _formattedElapsed = formatted;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-synchronize immediately when returning to foreground.
      // Because elapsed is derived from the server start timestamp,
      // it never drifts and never resets to 0.
      _calculateElapsed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  double _computeProgress() {
    if (_startTime == null || _elapsed.inSeconds <= 0) return 0.02;

    final seconds = _elapsed.inSeconds;
    // Dynamic progressive window scale (YouTube Live style)
    final int windowSeconds;
    if (seconds < 900) {
      windowSeconds = 900; // 15 mins
    } else if (seconds < 1800) {
      windowSeconds = 1800; // 30 mins
    } else if (seconds < 3600) {
      windowSeconds = 3600; // 1 hour
    } else if (seconds < 7200) {
      windowSeconds = 7200; // 2 hours
    } else {
      windowSeconds = seconds + 1800;
    }

    return (seconds / windowSeconds).clamp(0.02, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _computeProgress();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showElapsedLabel) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _formattedElapsed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ],
            ),
          ),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final fillWidth = (width * progress).clamp(4.0, width);

            return Container(
              height: widget.barHeight,
              width: width,
              color: Colors.white.withValues(alpha: 0.25),
              alignment: Alignment.centerLeft,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Active red fill
                  Container(
                    width: fillWidth,
                    height: widget.barHeight,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66E53935),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),

                  // Red LIVE head dot marker (pulsing)
                  Positioned(
                    left: (fillWidth - 4).clamp(0.0, width - 8),
                    top: -(8 - widget.barHeight) / 2,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE53935),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935).withValues(
                                  alpha: _pulseAnimation.value * 0.8,
                                ),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
