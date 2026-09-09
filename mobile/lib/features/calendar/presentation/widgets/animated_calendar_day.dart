// lib/features/calendar/presentation/widgets/animated_calendar_day.dart
// Animated calendar day cell with smooth transitions

import 'package:flutter/material.dart';

class AnimatedCalendarDay extends StatefulWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasNotes;
  final int noteCount;
  final bool hasReminders;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AnimatedCalendarDay({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasNotes,
    required this.noteCount,
    this.hasReminders = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<AnimatedCalendarDay> createState() => _AnimatedCalendarDayState();
}

class _AnimatedCalendarDayState extends State<AnimatedCalendarDay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? theme.colorScheme.primaryContainer
                : (widget.isToday
                      ? theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.3,
                        )
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: widget.isToday && !widget.isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontWeight: (widget.isToday || widget.isSelected)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: widget.isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : (widget.isToday
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyLarge?.color),
                  ),
                  child: Text('${widget.day}'),
                ),
              ),

              // Note indicator with animation
              if (widget.hasNotes)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: 1.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Note count badge
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.noteCount > 9
                                  ? '9+'
                                  : '${widget.noteCount}',
                              style: TextStyle(
                                color: widget.isSelected
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.onPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Reminder indicator
                          if (widget.hasReminders) ...[
                            const SizedBox(width: 2),
                            Icon(
                              Icons.notifications_active,
                              size: 10,
                              color: widget.isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.error,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
