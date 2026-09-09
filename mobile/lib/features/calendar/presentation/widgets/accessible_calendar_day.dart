// lib/features/calendar/presentation/widgets/accessible_calendar_day.dart
// Accessibility-enhanced calendar day cell

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';

class AccessibleCalendarDay extends StatelessWidget {
  final int day;
  final int month;
  final int year;
  final bool isToday;
  final bool isSelected;
  final bool hasNotes;
  final int noteCount;
  final bool hasReminders;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Widget child;

  const AccessibleCalendarDay({
    super.key,
    required this.day,
    required this.month,
    required this.year,
    required this.isToday,
    required this.isSelected,
    required this.hasNotes,
    required this.noteCount,
    this.hasReminders = false,
    required this.onTap,
    required this.onLongPress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _buildSemanticLabel(),
      hint: _buildSemanticHint(),
      button: true,
      selected: isSelected,
      enabled: true,
      onTap: onTap,
      onLongPress: onLongPress,
      customSemanticsActions: {
        if (hasNotes)
          const CustomSemanticsAction(label: 'View notes'): onTap,
        const CustomSemanticsAction(label: 'Add note'): onLongPress,
      },
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }

  String _buildSemanticLabel() {
    final parts = <String>[];

    // Date
    final monthName = EthiopianCalendarUtil.getMonthName(month);
    parts.add('$monthName $day, $year');

    // Today indicator
    if (isToday) {
      parts.add('Today');
    }

    // Selected indicator
    if (isSelected) {
      parts.add('Selected');
    }

    // Notes
    if (hasNotes) {
      parts.add('$noteCount ${noteCount == 1 ? 'note' : 'notes'}');
    }

    // Reminders
    if (hasReminders) {
      parts.add('Has reminders');
    }

    return parts.join(', ');
  }

  String _buildSemanticHint() {
    if (hasNotes) {
      return 'Double tap to view notes, long press to add note';
    } else {
      return 'Double tap to select, long press to add note';
    }
  }
}
