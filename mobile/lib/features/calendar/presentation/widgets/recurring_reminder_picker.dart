import 'package:abushakir/abushakir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/domain/calendar_reminder_schedule.dart';

class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.repeat,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final ReminderRepeat repeat;
  final int hour;
  final int minute;
}

class RecurringReminderPicker extends StatelessWidget {
  const RecurringReminderPicker({
    super.key,
    required this.selectedDate,
    required this.settings,
    required this.onChanged,
  });

  final EtDatetime selectedDate;
  final ReminderSettings settings;
  final ValueChanged<ReminderSettings> onChanged;

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );
    if (picked == null) return;
    onChanged(
      ReminderSettings(
        enabled: true,
        repeat: settings.repeat == ReminderRepeat.none
            ? ReminderRepeat.monthly
            : settings.repeat,
        hour: picked.hour,
        minute: picked.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedule = CalendarReminderSchedule.forEvent(
      year: selectedDate.year,
      month: selectedDate.month,
      day: selectedDate.day,
      hour: settings.hour,
      minute: settings.minute,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reminder', style: theme.textTheme.titleMedium),
            RadioGroup<ReminderRepeat>(
              groupValue: settings.enabled
                  ? settings.repeat
                  : ReminderRepeat.none,
              onChanged: (value) {
                switch (value) {
                  case ReminderRepeat.none:
                    onChanged(
                      const ReminderSettings(
                        enabled: false,
                        repeat: ReminderRepeat.none,
                        hour: 8,
                        minute: 0,
                      ),
                    );
                  case ReminderRepeat.monthly:
                  case ReminderRepeat.yearly:
                    onChanged(
                      ReminderSettings(
                        enabled: true,
                        repeat: value!,
                        hour: settings.hour,
                        minute: settings.minute,
                      ),
                    );
                  case null:
                    break;
                }
              },
              child: Column(
                children: [
                  RadioListTile<ReminderRepeat>(
                    contentPadding: EdgeInsets.zero,
                    title: Consumer(
                      builder: (_, ref, _) =>
                          Text(ref.watch(trProvider)('common.none')),
                    ),
                    value: ReminderRepeat.none,
                  ),
                  RadioListTile<ReminderRepeat>(
                    contentPadding: EdgeInsets.zero,
                    title: Consumer(
                      builder: (_, ref, _) =>
                          Text(ref.watch(trProvider)('calendar.prev_month')),
                    ),
                    value: ReminderRepeat.monthly,
                  ),
                  RadioListTile<ReminderRepeat>(
                    contentPadding: EdgeInsets.zero,
                    title: Consumer(
                      builder: (_, ref, _) =>
                          Text(ref.watch(trProvider)('common.years')),
                    ),
                    value: ReminderRepeat.yearly,
                  ),
                ],
              ),
            ),
            if (settings.enabled) ...[
              OutlinedButton.icon(
                onPressed: () => _pickTime(context),
                icon: const Icon(Icons.access_time),
                label: Text(
                  '${settings.hour.toString().padLeft(2, '0')}:${settings.minute.toString().padLeft(2, '0')}',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Notify: ${schedule.notification.day} ${_monthName(schedule.notification.month)} at ${settings.hour.toString().padLeft(2, '0')}:${settings.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _monthName(int month) => month >= 1 && month <= 13
      ? const [
          'መስከረም',
          'ጥቅምት',
          'ኅዳር',
          'ታኅሣሥ',
          'ጥር',
          'የካቲት',
          'መጋቢት',
          'ሚያዝያ',
          'ግንቦት',
          'ሰኔ',
          'ሐምሌ',
          'ነሐሴ',
          'ጳጉሜን',
        ][month - 1]
      : '';
}
