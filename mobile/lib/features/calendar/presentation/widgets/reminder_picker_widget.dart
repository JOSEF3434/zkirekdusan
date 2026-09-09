// lib/features/calendar/presentation/widgets/reminder_picker_widget.dart
// Reminder date/time picker widget

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReminderPickerWidget extends StatefulWidget {
  final bool hasReminder;
  final DateTime? reminderDateTime;
  final DateTime minDate;
  final Function(bool hasReminder, DateTime? dateTime) onChanged;

  const ReminderPickerWidget({
    super.key,
    required this.hasReminder,
    this.reminderDateTime,
    required this.minDate,
    required this.onChanged,
  });

  @override
  State<ReminderPickerWidget> createState() => _ReminderPickerWidgetState();
}

class _ReminderPickerWidgetState extends State<ReminderPickerWidget> {
  late bool _hasReminder;
  late DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _hasReminder = widget.hasReminder;
    _selectedDateTime = widget.reminderDateTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Toggle reminder switch
          SwitchListTile(
            title: Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Set Reminder',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            subtitle: _hasReminder && _selectedDateTime != null
                ? Text(
                    _formatReminderTime(_selectedDateTime!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Text(
                    'Get notified about this note',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
            value: _hasReminder,
            onChanged: (value) {
              setState(() {
                _hasReminder = value;
                if (value && _selectedDateTime == null) {
                  // Default to 8 AM on the note's date
                  _selectedDateTime = DateTime(
                    widget.minDate.year,
                    widget.minDate.month,
                    widget.minDate.day,
                    8,
                    0,
                  );
                  // If that's in the past, add 1 day
                  if (_selectedDateTime!.isBefore(DateTime.now())) {
                    _selectedDateTime = _selectedDateTime!.add(const Duration(days: 1));
                  }
                }
                widget.onChanged(_hasReminder, _selectedDateTime);
              });
            },
          ),

          // Date/Time picker (shown when reminder is enabled)
          if (_hasReminder) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Time',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Date button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(context),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _selectedDateTime != null
                                ? DateFormat('MMM dd, yyyy').format(_selectedDateTime!)
                                : 'Pick Date',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Time button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickTime(context),
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(
                            _selectedDateTime != null
                                ? DateFormat('h:mm a').format(_selectedDateTime!)
                                : 'Pick Time',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Quick reminder presets
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickReminderChip(
                        label: 'Morning (8 AM)',
                        icon: Icons.wb_sunny_outlined,
                        onTap: () => _setQuickReminder(8, 0),
                      ),
                      _QuickReminderChip(
                        label: 'Afternoon (2 PM)',
                        icon: Icons.brightness_5_outlined,
                        onTap: () => _setQuickReminder(14, 0),
                      ),
                      _QuickReminderChip(
                        label: 'Evening (6 PM)',
                        icon: Icons.nights_stay_outlined,
                        onTap: () => _setQuickReminder(18, 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedDateTime ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime?.hour ?? 8,
          _selectedDateTime?.minute ?? 0,
        );
        widget.onChanged(_hasReminder, _selectedDateTime);
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final initialTime = _selectedDateTime != null
        ? TimeOfDay.fromDateTime(_selectedDateTime!)
        : const TimeOfDay(hour: 8, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final baseDate = _selectedDateTime ?? now;
        _selectedDateTime = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          picked.hour,
          picked.minute,
        );

        // If the selected time is in the past, move to tomorrow
        if (_selectedDateTime!.isBefore(now)) {
          _selectedDateTime = _selectedDateTime!.add(const Duration(days: 1));
        }

        widget.onChanged(_hasReminder, _selectedDateTime);
      });
    }
  }

  void _setQuickReminder(int hour, int minute) {
    final now = DateTime.now();
    final noteDate = widget.minDate;

    var reminderTime = DateTime(
      noteDate.year,
      noteDate.month,
      noteDate.day,
      hour,
      minute,
    );

    // If time is in the past, use the note's date or tomorrow
    if (reminderTime.isBefore(now)) {
      reminderTime = DateTime(
        noteDate.year,
        noteDate.month,
        noteDate.day,
        hour,
        minute,
      );
      if (reminderTime.isBefore(now)) {
        reminderTime = reminderTime.add(const Duration(days: 1));
      }
    }

    setState(() {
      _selectedDateTime = reminderTime;
      widget.onChanged(_hasReminder, _selectedDateTime);
    });
  }

  String _formatReminderTime(DateTime dateTime) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final isToday = dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
    final isTomorrow = dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day;

    final timeStr = DateFormat('h:mm a').format(dateTime);

    if (isToday) {
      return 'Today at $timeStr';
    } else if (isTomorrow) {
      return 'Tomorrow at $timeStr';
    } else {
      return '${DateFormat('MMM dd').format(dateTime)} at $timeStr';
    }
  }
}

class _QuickReminderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickReminderChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
