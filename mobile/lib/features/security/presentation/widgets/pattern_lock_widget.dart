// lib/features/security/presentation/widgets/pattern_lock_widget.dart
//
// A gesture-based 3×3 pattern lock widget (Android-style).
// Uses a CustomPainter to draw connecting lines between selected nodes.
// Provides animated feedback: idle → active → success → error.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile/features/security/data/pattern_service.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum PatternLockState { idle, active, success, error }

// ── Callback types ─────────────────────────────────────────────────────────

typedef PatternCompleteCallback = void Function(List<int> nodes);

// ── Main Widget ────────────────────────────────────────────────────────────

class PatternLockWidget extends StatefulWidget {
  /// Called when the user lifts their finger (pattern complete).
  /// Receives the ordered list of node indices (0–8) that were connected.
  final PatternCompleteCallback onPatternComplete;

  /// Minimum nodes required; defaults to [kMinPatternNodes].
  final int minNodes;

  /// Visual state. Set to [PatternLockState.error] to flash the dots red,
  /// or [PatternLockState.success] to flash them green.
  final PatternLockState lockState;

  /// Whether input is disabled (e.g. during cooldown).
  final bool disabled;

  /// Size of the widget; defaults to 280×280.
  final double size;

  const PatternLockWidget({
    super.key,
    required this.onPatternComplete,
    this.minNodes = kMinPatternNodes,
    this.lockState = PatternLockState.idle,
    this.disabled = false,
    this.size = 280,
  });

  @override
  State<PatternLockWidget> createState() => PatternLockWidgetState();
}

class PatternLockWidgetState extends State<PatternLockWidget>
    with SingleTickerProviderStateMixin {
  // The ordered list of nodes (0–8) the user has traced.
  final List<int> _selectedNodes = [];

  // Current finger position for the "tail" line from the last node.
  Offset? _currentPoint;

  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  // Cached node centre positions, populated in the first build.
  late List<Offset> _nodeCentres;
  late double _nodeRadius;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _computeLayout(widget.size);
  }

  @override
  void didUpdateWidget(PatternLockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lockState != widget.lockState) {
      if (widget.lockState == PatternLockState.error ||
          widget.lockState == PatternLockState.success) {
        _animController.forward(from: 0).then((_) {
          if (mounted) _animController.reverse();
        });
      }
    }
    if (oldWidget.size != widget.size) {
      _computeLayout(widget.size);
    }
  }

  void _computeLayout(double size) {
    final cellSize = size / 3;
    _nodeRadius = cellSize * 0.14;
    _nodeCentres = List.generate(9, (i) {
      final row = i ~/ 3;
      final col = i % 3;
      return Offset(
        col * cellSize + cellSize / 2,
        row * cellSize + cellSize / 2,
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Gesture handlers ───────────────────────────────────────────────────

  int? _hitTest(Offset pos) {
    final hitRadius = _nodeRadius * 2.5;
    for (int i = 0; i < 9; i++) {
      if ((_nodeCentres[i] - pos).distance <= hitRadius) return i;
    }
    return null;
  }

  void _onPanStart(DragStartDetails d) {
    if (widget.disabled) return;
    setState(() {
      _selectedNodes.clear();
      _currentPoint = d.localPosition;
      final hit = _hitTest(d.localPosition);
      if (hit != null) _selectedNodes.add(hit);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (widget.disabled) return;
    setState(() {
      _currentPoint = d.localPosition;
      final hit = _hitTest(d.localPosition);
      if (hit != null && !_selectedNodes.contains(hit)) {
        _selectedNodes.add(hit);
      }
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (widget.disabled) return;
    setState(() => _currentPoint = null);

    if (_selectedNodes.length >= widget.minNodes) {
      widget.onPatternComplete(List.unmodifiable(_selectedNodes));
    } else if (_selectedNodes.isNotEmpty) {
      // Pattern too short — flash error briefly then clear
      _flashError();
    } else {
      setState(() => _selectedNodes.clear());
    }
  }

  void _flashError() {
    _animController.forward(from: 0).then((_) {
      if (mounted) {
        _animController.reverse();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _selectedNodes.clear());
        });
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Choose dot colour based on state
    Color dotColor;
    Color lineColor;
    switch (widget.lockState) {
      case PatternLockState.error:
        dotColor = Colors.redAccent;
        lineColor = Colors.redAccent.withValues(alpha: 0.7);
        break;
      case PatternLockState.success:
        dotColor = const Color(0xFF43E97B);
        lineColor = const Color(0xFF43E97B).withValues(alpha: 0.7);
        break;
      case PatternLockState.active:
        dotColor = cs.primary;
        lineColor = cs.primary.withValues(alpha: 0.6);
        break;
      default:
        dotColor = Colors.white.withValues(alpha: 0.7);
        lineColor = Colors.white.withValues(alpha: 0.4);
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _PatternPainter(
              nodeCentres: _nodeCentres,
              nodeRadius: _nodeRadius,
              selectedNodes: List.unmodifiable(_selectedNodes),
              currentPoint: _currentPoint,
              dotColor: dotColor,
              lineColor: lineColor,
              pulseScale: (widget.lockState == PatternLockState.error ||
                      widget.lockState == PatternLockState.success)
                  ? _pulseAnim.value
                  : 1.0,
            ),
          ),
        ),
      ),
    );
  }

  /// Called externally to reset the drawn pattern.
  void reset() => setState(() {
        _selectedNodes.clear();
        _currentPoint = null;
      });
}

// ── CustomPainter ──────────────────────────────────────────────────────────

class _PatternPainter extends CustomPainter {
  final List<Offset> nodeCentres;
  final double nodeRadius;
  final List<int> selectedNodes;
  final Offset? currentPoint;
  final Color dotColor;
  final Color lineColor;
  final double pulseScale;

  _PatternPainter({
    required this.nodeCentres,
    required this.nodeRadius,
    required this.selectedNodes,
    required this.currentPoint,
    required this.dotColor,
    required this.lineColor,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final outerRingPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final idlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    // ── Draw lines between selected nodes ──────────────────────────────
    for (int i = 0; i < selectedNodes.length - 1; i++) {
      canvas.drawLine(
        nodeCentres[selectedNodes[i]],
        nodeCentres[selectedNodes[i + 1]],
        linePaint,
      );
    }

    // ── Tail line from last node to current finger position ────────────
    if (selectedNodes.isNotEmpty && currentPoint != null) {
      canvas.drawLine(
        nodeCentres[selectedNodes.last],
        currentPoint!,
        linePaint..color = lineColor.withValues(alpha: 0.4),
      );
    }

    // ── Draw all 9 nodes ───────────────────────────────────────────────
    for (int i = 0; i < 9; i++) {
      final center = nodeCentres[i];
      final isSelected = selectedNodes.contains(i);
      final scale = isSelected ? pulseScale : 1.0;

      if (isSelected) {
        // Outer glow ring
        canvas.drawCircle(center, nodeRadius * 2.2 * scale, outerRingPaint);
        // Filled dot
        canvas.drawCircle(center, nodeRadius * scale, dotPaint);
        // Direction arrow (small triangle pointing toward next node)
        if (selectedNodes.indexOf(i) < selectedNodes.length - 1) {
          final nextIndex = selectedNodes[selectedNodes.indexOf(i) + 1];
          final nextCenter = nodeCentres[nextIndex];
          _drawArrow(canvas, center, nextCenter, dotPaint);
        }
      } else {
        // Idle ring
        canvas.drawCircle(center, nodeRadius * 0.45, idlePaint);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final mid = Offset(
      (from.dx + to.dx) / 2,
      (from.dy + to.dy) / 2,
    );
    final arrowSize = nodeRadius * 0.55;
    final path = Path()
      ..moveTo(
        mid.dx + arrowSize * math.cos(angle),
        mid.dy + arrowSize * math.sin(angle),
      )
      ..lineTo(
        mid.dx + arrowSize * math.cos(angle + 2.5),
        mid.dy + arrowSize * math.sin(angle + 2.5),
      )
      ..lineTo(
        mid.dx + arrowSize * math.cos(angle - 2.5),
        mid.dy + arrowSize * math.sin(angle - 2.5),
      )
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.selectedNodes != selectedNodes ||
      old.currentPoint != currentPoint ||
      old.dotColor != dotColor ||
      old.pulseScale != pulseScale;
}
