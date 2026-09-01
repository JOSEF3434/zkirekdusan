// lib/features/live/presentation/widgets/reaction_animation_widget.dart
// Floating emoji reactions that animate upward and fade out.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';

class ReactionAnimationWidget extends StatefulWidget {
  final Stream<ReactionBroadcastEvent> reactionStream;

  const ReactionAnimationWidget({super.key, required this.reactionStream});

  @override
  State<ReactionAnimationWidget> createState() =>
      _ReactionAnimationWidgetState();
}

class _ReactionParticle {
  final String emoji;
  final double xOffset;
  late AnimationController controller;
  late Animation<double> opacity;
  late Animation<double> yOffset;

  _ReactionParticle({required this.emoji, required this.xOffset});
}

class _ReactionAnimationWidgetState extends State<ReactionAnimationWidget>
    with TickerProviderStateMixin {
  final List<_ReactionParticle> _particles = [];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    widget.reactionStream.listen(_addReaction);
  }

  void _addReaction(ReactionBroadcastEvent event) {
    if (!mounted) return;
    final count = min(event.count, 5); // max 5 particles per burst
    for (int i = 0; i < count; i++) {
      final particle = _ReactionParticle(
        emoji: event.emoji,
        xOffset: (_rng.nextDouble() - 0.5) * 80,
      );
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );
      particle.controller = ctrl;
      particle.opacity = Tween<double>(
        begin: 1,
        end: 0,
      ).animate(CurvedAnimation(parent: ctrl, curve: const Interval(0.6, 1.0)));
      particle.yOffset = Tween<double>(
        begin: 0,
        end: -180,
      ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
      setState(() => _particles.add(particle));
      ctrl.forward().then((_) {
        if (mounted) {
          setState(() => _particles.remove(particle));
          ctrl.dispose();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final p in _particles) {
      p.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _particles.map((p) {
          return Positioned(
            bottom: 80,
            right: 20 + p.xOffset,
            child: AnimatedBuilder(
              animation: p.controller,
              builder: (_, __) => Transform.translate(
                offset: Offset(p.xOffset * 0.3, p.yOffset.value),
                child: Opacity(
                  opacity: p.opacity.value,
                  child: Text(p.emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
