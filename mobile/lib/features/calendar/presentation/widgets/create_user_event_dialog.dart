// lib/features/calendar/presentation/widgets/create_user_event_dialog.dart
// Modern, advanced dialog for users to create personal events and calendar reminders with Ethiopian date and time.

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_reminder_provider.dart';

class CreateUserEventDialog extends ConsumerStatefulWidget {
  final int? initialYear;
  final int? initialMonth;
  final int? initialDay;

  const CreateUserEventDialog({
    super.key,
    this.initialYear,
    this.initialMonth,
    this.initialDay,
  });

  static Future<bool?> show(
    BuildContext context, {
    int? initialYear,
    int? initialMonth,
    int? initialDay,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateUserEventDialog(
        initialYear: initialYear,
        initialMonth: initialMonth,
        initialDay: initialDay,
      ),
    );
  }

  @override
  ConsumerState<CreateUserEventDialog> createState() =>
      _CreateUserEventDialogState();
}

class _CreateUserEventDialogState extends ConsumerState<CreateUserEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  // Default time: 08:00 AM (Ethiopian ጧት 2:00)
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _enableReminder = true;
  ReminderRepeat _repeat = ReminderRepeat.none;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final nowEt = EthiopianCalendarUtil.now();
    _selectedYear = widget.initialYear ?? nowEt.year;
    _selectedMonth = widget.initialMonth ?? nowEt.month;
    _selectedDay = widget.initialDay ?? nowEt.day;

    final maxDays = EthiopianCalendarUtil.getDaysInMonth(
      _selectedYear,
      _selectedMonth,
    );
    if (_selectedDay > maxDays) {
      _selectedDay = maxDays;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  int get _daysInSelectedMonth =>
      EthiopianCalendarUtil.getDaysInMonth(_selectedYear, _selectedMonth);

  DateTime get _targetGregorianDate {
    final etDate = EthiopianCalendarUtil.create(
      _selectedYear,
      _selectedMonth,
      _selectedDay,
    );
    final baseGreg = EthiopianCalendarUtil.toGregorian(etDate);
    return DateTime(
      baseGreg.year,
      baseGreg.month,
      baseGreg.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'የሁነቱን ሰዓት ይምረጡ (Select Event Time)',
      cancelText: 'ይቅር',
      confirmText: 'ምረጥ',
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id ?? 'local_user';

      final gregorianTarget = _targetGregorianDate;

      final createNote = ref.read(createCalendarNoteProvider);
      final note = await createNote(
        userId: userId,
        ethiopianYear: _selectedYear,
        ethiopianMonth: _selectedMonth,
        ethiopianDay: _selectedDay,
        gregorianDate: gregorianTarget,
        title: _titleController.text.trim(),
        content: _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
        hasReminder: _enableReminder,
        reminderDateTime: _enableReminder ? gregorianTarget : null,
        reminderRepeat: _repeat,
        reminderEthiopianMonth: _selectedMonth,
        reminderEthiopianDay: _selectedDay,
        reminderHour: _selectedTime.hour,
        reminderMinute: _selectedTime.minute,
        reminderTimezone: 'Africa/Addis_Ababa',
        reminderNextOccurrence: _enableReminder ? gregorianTarget : null,
      );

      // Schedule exact local notification alarm for this user's event
      if (_enableReminder) {
        try {
          final scheduler = ref.read(scheduleReminderProvider);
          await scheduler(note);
        } catch (e) {
          developer.log('Failed to schedule local reminder for note: $e');
        }
      }

      // Invalidate calendar notes queries so it immediately appears
      ref.invalidate(calendarNotesForMonthProvider((
        year: _selectedYear,
        month: _selectedMonth,
      )));
      ref.invalidate(calendarNotesForDateProvider((
        year: _selectedYear,
        month: _selectedMonth,
        day: _selectedDay,
      )));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ሁነቱ ተመዝግቧል! ማሳወቂያው ${_enableReminder ? "በሰዓቱ ይደርስዎታል" : "ተቀምጧል"}።',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e, st) {
      developer.log('Error creating user event: $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('ስህተት ተፈጥሯል፦ $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = ref.watch(trProvider);

    final etTime = EthiopianCalendarUtil.toEthiopianTime(
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final targetGreg = _targetGregorianDate;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_alarm_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(
                              'calendar.add_user_event',
                              {'fallback': 'አዲስ ሁነት / ማሳሰቢያ መዝግብ'},
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamilyFallback: const [
                                'Noto Serif Ethiopic',
                                'Noto Sans Ethiopic',
                              ],
                            ),
                          ),
                          Text(
                            'ቀን እና ሰዓት መርጠው የግል ማሳሰቢያ ያዘጋጁ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Event Title Input
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: tr('calendar.event_title', {'fallback': 'የሁነቱ ስም / ርዕስ *'}),
                    hintText: 'ለምሳሌ፦ የቅዱስ ሚካኤል ማኅበር፣ የጸሎት ሰዓት...',
                    prefixIcon: const Icon(Icons.title_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'እባክዎ የሁነቱን ስም ያስገቡ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Event Description / Note (Optional)
                TextFormField(
                  controller: _contentController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: tr('calendar.event_desc', {'fallback': 'ዝርዝር ማብራሪያ (አማራጭ)'}),
                    hintText: 'ተጨማሪ ዝርዝር ማስታወሻ...',
                    prefixIcon: const Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 16),

                // Ethiopian Date Selection
                Text(
                  'የቀን መቁጠሪያ (Ethiopian Date)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    // Day Selector
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedDay,
                        decoration: InputDecoration(
                          labelText: 'ቀን',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: List.generate(_daysInSelectedMonth, (index) {
                          final day = index + 1;
                          return DropdownMenuItem(
                            value: day,
                            child: Text('$day'),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDay = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Month Selector
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'ወር',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: List.generate(13, (index) {
                          final month = index + 1;
                          return DropdownMenuItem(
                            value: month,
                            child: Text(
                              EthiopianCalendarUtil.getMonthName(month),
                              style: const TextStyle(
                                fontFamilyFallback: [
                                  'Noto Serif Ethiopic',
                                  'Noto Sans Ethiopic',
                                ],
                              ),
                            ),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedMonth = val;
                              final maxDays =
                                  EthiopianCalendarUtil.getDaysInMonth(
                                    _selectedYear,
                                    _selectedMonth,
                                  );
                              if (_selectedDay > maxDays) {
                                _selectedDay = maxDays;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Year Selector
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedYear,
                        decoration: InputDecoration(
                          labelText: 'ዓመት',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: List.generate(8, (index) {
                          final year = 2016 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedYear = val;
                              final maxDays =
                                  EthiopianCalendarUtil.getDaysInMonth(
                                    _selectedYear,
                                    _selectedMonth,
                                  );
                              if (_selectedDay > maxDays) {
                                _selectedDay = maxDays;
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Live Date Preview Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${EthiopianCalendarUtil.getMonthName(_selectedMonth)} $_selectedDay፣ $_selectedYear ዓ.ም (${EthiopianCalendarUtil.formatGregorianDate(targetGreg)})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Time Selection Card
                Text(
                  'የማሳወቂያ ሰዓት (Notification Time)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),

                InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: isDark ? 0.35 : 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled_rounded,
                          color: Color(0xFFF59E0B),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'በኢትዮጵያ ሰዓት አቆጣጠር',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    etTime.formatAmharic(),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontFamilyFallback: const [
                                        'Noto Serif Ethiopic',
                                        'Noto Sans Ethiopic',
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${etTime.formatGregorian()})',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFFF59E0B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ሰዓት ቀይር',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reminder Toggle & Recurrence
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ማሳወቂያ ይድረሰኝ (Notify Me)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'በተመረጠው ቀን እና ሰዓት ማሳወቂያ ይደርሳል',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enableReminder,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: (val) => setState(() => _enableReminder = val),
                    ),
                  ],
                ),

                if (_enableReminder) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ReminderRepeat>(
                    initialValue: _repeat,
                    decoration: InputDecoration(
                      labelText: 'ድግግሞሽ (Repeat)',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ReminderRepeat.none,
                        child: Text('አንዴ ብቻ (Once)'),
                      ),
                      DropdownMenuItem(
                        value: ReminderRepeat.daily,
                        child: Text('በየቀኑ (Daily)'),
                      ),
                      DropdownMenuItem(
                        value: ReminderRepeat.weekly,
                        child: Text('በየሳምንቱ (Weekly)'),
                      ),
                      DropdownMenuItem(
                        value: ReminderRepeat.monthly,
                        child: Text('በየወሩ (Monthly)'),
                      ),
                      DropdownMenuItem(
                        value: ReminderRepeat.yearly,
                        child: Text('በየዓመቱ (Yearly)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _repeat = val);
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: Text(tr('common.cancel', {'fallback': 'ይቅር'})),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveEvent,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'በመመዝገብ ላይ...' : 'ሁነቱን መዝግብ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
