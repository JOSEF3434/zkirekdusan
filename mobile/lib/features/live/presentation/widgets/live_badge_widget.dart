// lib/features/live/presentation/widgets/live_badge_widget.dart
// Animated pulsing LIVE badge for stream cards and player overlay.
// Supports server-sourced elapsed timer (startedAt) matching Screenshot B.

import 'dart:async';
import 'package:flutter/material.dart';

class LiveBadgeWidget extends StatefulWidget {
  final bool small;
  final String? startedAt;
  final String? elapsed;

  const LiveBadgeWidget({
    super.key,
    this.small = false,
    this.startedAt,
    this.elapsed,
  });

  @override
  State<LiveBadgeWidget> createState() => _LiveBadgeWidgetState();
}

class _LiveBadgeWidgetState extends State<LiveBadgeWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  Timer? _timer;
  DateTime? _startTime;
  String _computedElapsed = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _parseAndStart();
  }

  @override
  void didUpdateWidget(covariant LiveBadgeWidget oldWidget) {
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
      if (_computedElapsed.isNotEmpty) {
        setState(() => _computedElapsed = '');
      }
      return;
    }

    final now = DateTime.now();
    final diff = now.isAfter(_startTime!) ? now.difference(_startTime!) : Duration.zero;
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    final formatted = diff.inHours > 0 ? '$h:$m:$s' : '$m:$s';

    if (_computedElapsed != formatted) {
      setState(() => _computedElapsed = formatted);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _calculateElapsed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double dotSize = widget.small ? 6 : 8;
    final double fontSize = widget.small ? 10 : 12;
    final double hPad = widget.small ? 6 : 8;
    final double vPad = widget.small ? 3 : 4;

    final String? elapsedText = widget.elapsed ?? (_computedElapsed.isNotEmpty ? _computedElapsed : null);
    final String label = elapsedText != null ? 'LIVE $elapsedText' : 'LIVE';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66E53935),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Opacity(
              opacity: _pulse.value,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
