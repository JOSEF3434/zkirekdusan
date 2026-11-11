// lib/features/live/presentation/widgets/dvr_seek_bar.dart
//
// Interactive YouTube-style DVR scrubber bound directly to real media bounds
// [windowStart .. windowEnd]. Never fakes positions when DVR is unavailable.

import 'package:flutter/material.dart';
import 'package:mobile/features/live/domain/live_dvr_state.dart';

class DvrSeekBar extends StatefulWidget {
  final DvrWindowMath window;
  final bool enabled;
  final bool compact;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onGoLive;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;

  const DvrSeekBar({
    super.key,
    required this.window,
    required this.enabled,
    this.compact = false,
    required this.onSeek,
    required this.onGoLive,
    this.onScrubStart,
    this.onScrubEnd,
  });

  @override
  State<DvrSeekBar> createState() => _DvrSeekBarState();
}

class _DvrSeekBarState extends State<DvrSeekBar> {
  double? _dragRatio;
  bool _isHovered = false;

  void _updateDrag(Offset localPos, double trackWidth) {
    if (!widget.enabled || trackWidth <= 0) return;
    final ratio = (localPos.dx / trackWidth).clamp(0.0, 1.0);
    setState(() => _dragRatio = ratio);
  }

  void _commitDrag() {
    final ratio = _dragRatio;
    setState(() => _dragRatio = null);
    widget.onScrubEnd?.call();
    if (ratio == null) return;

    if (ratio >= 0.985) {
      widget.onGoLive();
      return;
    }

    final spanMs = widget.window.windowSpan.inMilliseconds;
    final target = widget.window.windowStart +
        Duration(milliseconds: (spanMs * ratio).round());
    widget.onSeek(target);
  }

  String _previewLabelForRatio(double ratio) {
    if (ratio >= 0.985) return 'LIVE';
    final spanMs = widget.window.windowSpan.inMilliseconds;
    final target = widget.window.windowStart +
        Duration(milliseconds: (spanMs * ratio).round());
    final delta = widget.window.windowEnd - target;
    return delta <= const Duration(seconds: 2)
        ? 'LIVE'
        : '-${formatDvrDuration(delta)}';
  }

  @override
  Widget build(BuildContext context) {
    final activeRatio = _dragRatio ?? widget.window.progress;
    final bufferedRatio = widget.window.bufferedProgress.clamp(0.0, 1.0);
    final barHeight = _dragRatio != null || _isHovered
        ? (widget.compact ? 4.5 : 5.5)
        : (widget.compact ? 3.0 : 3.5);
    final thumbRadius = _dragRatio != null
        ? 8.5
        : (_isHovered ? 7.0 : (widget.compact ? 5.5 : 6.0));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final handleX = (width * activeRatio).clamp(0.0, width);
          final bufW = (width * bufferedRatio).clamp(0.0, width);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: widget.enabled
                ? (d) {
                    widget.onScrubStart?.call();
                    _updateDrag(d.localPosition, width);
                  }
                : null,
            onHorizontalDragUpdate: widget.enabled
                ? (d) => _updateDrag(d.localPosition, width)
                : null,
            onHorizontalDragEnd: widget.enabled ? (_) => _commitDrag() : null,
            onTapDown: widget.enabled
                ? (d) {
                    widget.onScrubStart?.call();
                    _updateDrag(d.localPosition, width);
                  }
                : null,
            onTapUp: widget.enabled ? (_) => _commitDrag() : null,
            child: SizedBox(
              height: widget.compact ? 24 : 28,
              width: width,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Base track
                  Container(
                    height: barHeight,
                    width: width,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(barHeight),
                    ),
                  ),

                  // Buffered portion
                  Container(
                    height: barHeight,
                    width: bufW,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.50),
                      borderRadius: BorderRadius.circular(barHeight),
                    ),
                  ),

                  // Played red track
                  Container(
                    height: barHeight,
                    width: handleX,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(barHeight),
                    ),
                  ),

                  // Live edge end notch
                  if (widget.enabled)
                    Positioned(
                      right: 0,
                      child: Container(
                        width: 4,
                        height: barHeight + 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                  // Scrubber handle
                  if (widget.enabled)
                    Positioned(
                      left: (handleX - thumbRadius).clamp(
                        0.0,
                        (width - thumbRadius * 2).clamp(0.0, width),
                      ),
                      child: Container(
                        width: thumbRadius * 2,
                        height: thumbRadius * 2,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF1744),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x88000000),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Floating drag time preview tooltip
                  if (_dragRatio != null)
                    Positioned(
                      left: (handleX - 28).clamp(
                        0.0,
                        (width - 56).clamp(0.0, width),
                      ),
                      bottom: 26,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          _previewLabelForRatio(_dragRatio!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
