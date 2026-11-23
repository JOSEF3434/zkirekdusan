// lib/features/calendar/presentation/widgets/ethiopian_date_picker_dialog.dart
import 'package:flutter/material.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';

class EthiopianDatePickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final int? initialDay;
  final void Function(int year, int month, int? day) onDateSelected;

  const EthiopianDatePickerDialog({
    super.key,
    required this.initialYear,
    required this.initialMonth,
    this.initialDay,
    required this.onDateSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required int initialYear,
    required int initialMonth,
    int? initialDay,
    required void Function(int year, int month, int? day) onDateSelected,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
          child: EthiopianDatePickerDialog(
            initialYear: initialYear,
            initialMonth: initialMonth,
            initialDay: initialDay,
            onDateSelected: onDateSelected,
          ),
        ),
      ),
    );
  }

  @override
  State<EthiopianDatePickerDialog> createState() =>
      _EthiopianDatePickerDialogState();
}

class _EthiopianDatePickerDialogState extends State<EthiopianDatePickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  int? _selectedDay;
  bool _includeDay = false;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
    _selectedDay = widget.initialDay;
    _includeDay = widget.initialDay != null;
  }

  int get _maxDaysInSelectedMonth =>
      EthiopianCalendarUtil.getDaysInMonth(_selectedYear, _selectedMonth);

  String _getGregorianPreview() {
    try {
      final startEt = EthiopianCalendarUtil.create(_selectedYear, _selectedMonth, 1);
      final days = _maxDaysInSelectedMonth;
      final endEt = EthiopianCalendarUtil.create(_selectedYear, _selectedMonth, days);
      final startG = EthiopianCalendarUtil.toGregorian(startEt);
      final endG = EthiopianCalendarUtil.toGregorian(endEt);

      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      final startStr = '${months[startG.month - 1]} ${startG.day}, ${startG.year}';
      final endStr = '${months[endG.month - 1]} ${endG.day}, ${endG.year}';
      return '$startStr – $endStr (እ.ኤ.አ)';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = EthiopianCalendarUtil.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'የኢትዮጵያ ቀን መቁጠሪያ ምረጥ',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ቀጥታ ወደፈለጉት ወር እና ዓመት ይሂዱ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const Divider(height: 24),

          // Year Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'ያለፈው ዓመት',
                onPressed: () {
                  setState(() {
                    _selectedYear--;
                    final max = _maxDaysInSelectedMonth;
                    if (_selectedDay != null && _selectedDay! > max) {
                      _selectedDay = max;
                    }
                  });
                },
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(100, (i) {
                    final yr = 1970 + i;
                    return DropdownMenuItem<int>(
                      value: yr,
                      child: Text(
                        '$yr ዓ.ም',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedYear = val;
                        final max = _maxDaysInSelectedMonth;
                        if (_selectedDay != null && _selectedDay! > max) {
                          _selectedDay = max;
                        }
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'የሚቀጥለው ዓመት',
                onPressed: () {
                  setState(() {
                    _selectedYear++;
                    final max = _maxDaysInSelectedMonth;
                    if (_selectedDay != null && _selectedDay! > max) {
                      _selectedDay = max;
                    }
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Gregorian Preview Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getGregorianPreview(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 14),

          // Month Selection Grid (13 Ethiopian Months)
          Text(
            'ወር ይምረጡ',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(13, (index) {
              final m = index + 1;
              final isSel = _selectedMonth == m;
              final name = EthiopianCalendarUtil.getMonthName(m);

              return ChoiceChip(
                label: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? theme.colorScheme.onPrimary : null,
                    fontFamilyFallback: const [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                ),
                selected: isSel,
                selectedColor: theme.colorScheme.primary,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMonth = m;
                      final max = _maxDaysInSelectedMonth;
                      if (_selectedDay != null && _selectedDay! > max) {
                        _selectedDay = max;
                      }
                    });
                  }
                },
              );
            }),
          ),

          const SizedBox(height: 14),

          // Optional Day selection toggle
          Row(
            children: [
              Text(
                'የተወሰነ ቀን መምረጥ ይፈልጋሉ?',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Switch(
                value: _includeDay,
                onChanged: (val) {
                  setState(() {
                    _includeDay = val;
                    if (val && _selectedDay == null) {
                      _selectedDay = 1;
                    } else if (!val) {
                      _selectedDay = null;
                    }
                  });
                },
              ),
            ],
          ),

          // Day Grid if enabled
          if (_includeDay) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(_maxDaysInSelectedMonth, (index) {
                final d = index + 1;
                final isSel = _selectedDay == d;

                return InkWell(
                  onTap: () => setState(() => _selectedDay = d),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSel
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '$d',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        color: isSel
                            ? theme.colorScheme.onPrimary
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],

          const SizedBox(height: 20),

          // Action Buttons: Today, Cancel, Apply
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.today_rounded, size: 16),
                label: const Text(
                  'ዛሬ',
                  style: TextStyle(
                    fontFamilyFallback: [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDateSelected(now.year, now.month, now.day);
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ሰርዝ'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDateSelected(
                    _selectedYear,
                    _selectedMonth,
                    _includeDay ? _selectedDay : null,
                  );
                },
                child: const Text(
                  'ምረጥ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamilyFallback: [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
