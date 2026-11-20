// lib/features/admin/presentation/widgets/manage_calendar_event_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_events_provider.dart';

enum CalendarConfigMode {
  specificDay,
  dateRange,
}

class ManageCalendarEventDialog extends ConsumerStatefulWidget {
  final CalendarEventModel? initialEvent;
  final int? prefillYear;
  final int? prefillMonth;
  final int? prefillDay;

  const ManageCalendarEventDialog({
    super.key,
    this.initialEvent,
    this.prefillYear,
    this.prefillMonth,
    this.prefillDay,
  });

  static Future<void> show(
    BuildContext context, {
    CalendarEventModel? event,
    int? prefillYear,
    int? prefillMonth,
    int? prefillDay,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ManageCalendarEventDialog(
        initialEvent: event,
        prefillYear: prefillYear,
        prefillMonth: prefillMonth,
        prefillDay: prefillDay,
      ),
    );
  }

  @override
  ConsumerState<ManageCalendarEventDialog> createState() =>
      _ManageCalendarEventDialogState();
}

class _ManageCalendarEventDialogState
    extends ConsumerState<ManageCalendarEventDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _nameEnController;
  late TextEditingController _descriptionController;
  late TextEditingController _spiritualMeaningController;
  late TextEditingController _fastingRulesController;
  late TextEditingController _yearController;

  late CalendarConfigMode _configMode;
  late CalendarEventType _type;
  late CalendarEventCategory _category;
  late String _importance;
  late bool _isRecurring;

  late int _startMonth;
  late int _startDay;
  late int _endMonth;
  late int _endDay;
  late bool _isMajor;
  late bool _isActive;
  late bool _markStartBadge;
  late bool _markEndBadge;
  String? _selectedColor;
  bool _isSubmitting = false;

  /// Default specifications:
  /// Orange (#F59E0B): Fasting period
  /// Red (#DC2626): Major holiday
  /// Green (#16A34A): Fasting start/end or special event markers
  static const String colorOrange = '#F59E0B';
  static const String colorRed = '#DC2626';
  static const String colorGreen = '#16A34A';

  final List<String> _colorPresets = [
    colorOrange, // Fasting period
    colorRed, // Major holiday
    colorGreen, // Fasting start/end & special event
    '#7C3AED', // Deep Purple
    '#0284C7', // Sky Blue
    '#D97706', // Amber
    '#4F46E5', // Indigo
    '#B91C1C', // Dark Crimson
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.initialEvent;
    final nowEth = EthiopianCalendarUtil.now();

    final defaultYear = widget.prefillYear ?? ev?.ethiopianYear ?? nowEth.year;
    final defaultMonth = widget.prefillMonth ?? ev?.startMonth ?? nowEth.month;
    final defaultDay = widget.prefillDay ?? ev?.startDay ?? nowEth.day;

    _nameController = TextEditingController(text: ev?.name ?? '');
    _nameEnController = TextEditingController(text: ev?.nameEn ?? '');
    _descriptionController = TextEditingController(text: ev?.description ?? '');
    _spiritualMeaningController =
        TextEditingController(text: ev?.spiritualMeaning ?? '');
    _fastingRulesController = TextEditingController(text: ev?.fastingRules ?? '');
    _yearController = TextEditingController(text: defaultYear.toString());

    if (ev != null) {
      _configMode = (ev.startMonth == ev.endMonth && ev.startDay == ev.endDay)
          ? CalendarConfigMode.specificDay
          : CalendarConfigMode.dateRange;
      _type = ev.type;
      _category = ev.category;
      _importance = ev.importance;
      _isRecurring = ev.isRecurring;
      _startMonth = ev.startMonth;
      _startDay = ev.startDay;
      _endMonth = ev.endMonth;
      _endDay = ev.endDay;
      _isMajor = ev.isMajor || ev.importance == 'MAJOR';
      _isActive = ev.isActive;
      _selectedColor = ev.primaryColor ?? ev.effectiveColorHex;
      _markStartBadge = ev.isFast;
      _markEndBadge = ev.isFast && _configMode == CalendarConfigMode.dateRange;
    } else {
      _configMode = widget.prefillDay != null
          ? CalendarConfigMode.specificDay
          : CalendarConfigMode.dateRange;
      _type = CalendarEventType.holiday;
      _category = CalendarEventCategory.majorHoliday;
      _importance = 'MAJOR';
      _isRecurring = true;
      _startMonth = defaultMonth;
      _startDay = defaultDay;
      _endMonth = defaultMonth;
      _endDay = defaultDay;
      _isMajor = true;
      _isActive = true;
      _selectedColor = colorRed;
      _markStartBadge = false;
      _markEndBadge = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    _spiritualMeaningController.dispose();
    _fastingRulesController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _onTypeChanged(CalendarEventType newType) {
    setState(() {
      _type = newType;
      if (newType == CalendarEventType.fast) {
        _category = CalendarEventCategory.majorFast;
        _selectedColor = colorOrange; // Orange for fasting
        _markStartBadge = true;
        _markEndBadge = _configMode == CalendarConfigMode.dateRange;
      } else if (newType == CalendarEventType.specialEvent) {
        _category = CalendarEventCategory.annualFeast;
        _importance = 'SPECIAL';
        _selectedColor = colorGreen; // Green for special event
        _markStartBadge = false;
        _markEndBadge = false;
      } else {
        _category = CalendarEventCategory.majorHoliday;
        _selectedColor = colorRed; // Red for major holiday
        _markStartBadge = false;
        _markEndBadge = false;
      }
    });
  }

  void _onImportanceChanged(String newImportance) {
    setState(() {
      _importance = newImportance;
      _isMajor = newImportance == 'MAJOR';
      if (_type == CalendarEventType.holiday) {
        _selectedColor = _isMajor ? colorRed : '#D97706';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final isEditing = widget.initialEvent != null;

    final parsedColor = Color(
      int.parse(
        'FF${(_selectedColor ?? colorOrange).replaceAll('#', '')}',
        radix: 16,
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: parsedColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEditing
                            ? Icons.edit_calendar_rounded
                            : Icons.add_circle_outline,
                        color: parsedColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? tr('admin.edit_event', {'fallback': 'የቀን ቅንብርን አስተካክል'})
                                : tr('admin.calendar_day_settings', {'fallback': 'የቀን ማስተካከያ እና የቀለም ቅንብር'}),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamilyFallback: const [
                                'Noto Serif Ethiopic',
                                'Noto Sans Ethiopic',
                              ],
                            ),
                          ),
                          Text(
                            tr('calendar.configure_day', {'fallback': 'ጾም፣ በዓል ወይም ልዩ ክስተት መመደቢያ'}),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Mode Selector: Specific Day vs Date Range
                SegmentedButton<CalendarConfigMode>(
                  segments: [
                    ButtonSegment(
                      value: CalendarConfigMode.specificDay,
                      icon: const Icon(Icons.today_rounded, size: 18),
                      label: Text(
                        tr('calendar.mode_specific_day', {'fallback': 'አንድ ቀን ብቻ'}),
                        style: const TextStyle(
                          fontFamilyFallback: [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                    ),
                    ButtonSegment(
                      value: CalendarConfigMode.dateRange,
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: Text(
                        tr('calendar.mode_date_range', {'fallback': 'የቀናት ወሰን'}),
                        style: const TextStyle(
                          fontFamilyFallback: [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                    ),
                  ],
                  selected: {_configMode},
                  onSelectionChanged: (set) {
                    setState(() {
                      _configMode = set.first;
                      if (_configMode == CalendarConfigMode.specificDay) {
                        _endMonth = _startMonth;
                        _endDay = _startDay;
                        _markEndBadge = false;
                      } else {
                        if (_type == CalendarEventType.fast) {
                          _markEndBadge = true;
                        }
                      }
                    });
                  },
                ),

                const Divider(height: 20),

                // Form Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Preview Section
                        _buildLivePreview(theme, tr, parsedColor),

                        const SizedBox(height: 16),

                        // Event Name (Amharic)
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: '${tr('admin.event_name', {'fallback': 'ስም (በአማርኛ)'})} *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'እባክዎ የስያሜውን ስም ያስገቡ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Event Name (English)
                        TextFormField(
                          controller: _nameEnController,
                          decoration: InputDecoration(
                            labelText: tr('admin.event_name_en', {'fallback': 'ስም በእንግሊዝኛ (አማራጭ)'}),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.translate),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Type & Importance Row
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<CalendarEventType>(
                                initialValue: _type,
                                decoration: InputDecoration(
                                  labelText: tr('admin.type', {'fallback': 'ሁነት ዓይነት'}),
                                  border: const OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: CalendarEventType.fast,
                                    child: Text(tr('calendar.event_type_fast', {'fallback': 'ጾም'})),
                                  ),
                                  DropdownMenuItem(
                                    value: CalendarEventType.holiday,
                                    child: Text(tr('calendar.event_type_holiday', {'fallback': 'በዓል'})),
                                  ),
                                  DropdownMenuItem(
                                    value: CalendarEventType.specialEvent,
                                    child: Text(tr('calendar.event_type_special_event', {'fallback': 'ልዩ ክስተት'})),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) _onTypeChanged(val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: _importance,
                                decoration: const InputDecoration(
                                  labelText: 'ደረጃ (Importance)',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'NORMAL',
                                    child: Text(tr('calendar.importance_normal', {'fallback': 'መደበኛ'})),
                                  ),
                                  DropdownMenuItem(
                                    value: 'SPECIAL',
                                    child: Text(tr('calendar.importance_special', {'fallback': 'ልዩ'})),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MAJOR',
                                    child: Text(tr('calendar.importance_major', {'fallback': 'ዓቢይ'})),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) _onImportanceChanged(val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Ethiopian Date Selection
                        Text(
                          _configMode == CalendarConfigMode.specificDay
                              ? 'የተመረጠው የኢትዮጵያ ቀን'
                              : tr('admin.date_range', {'fallback': 'የቀን ወሰን (የኢትዮጵያ አቆጣጠር)'}),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Start Date (or Specific Day)
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                initialValue: _startMonth,
                                decoration: InputDecoration(
                                  labelText: _configMode == CalendarConfigMode.specificDay
                                      ? 'ወር'
                                      : 'መጀመሪያ ወር',
                                  border: const OutlineInputBorder(),
                                ),
                                items: List.generate(
                                  13,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text(EthiopianCalendarUtil.getMonthName(i + 1)),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _startMonth = val;
                                      if (_configMode == CalendarConfigMode.specificDay) {
                                        _endMonth = val;
                                      }
                                      if (_startDay > (_startMonth == 13 ? 6 : 30)) {
                                        _startDay = _startMonth == 13 ? 5 : 30;
                                        if (_configMode == CalendarConfigMode.specificDay) {
                                          _endDay = _startDay;
                                        }
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<int>(
                                initialValue: _startDay,
                                decoration: const InputDecoration(
                                  labelText: 'ቀን',
                                  border: OutlineInputBorder(),
                                ),
                                items: List.generate(
                                  _startMonth == 13 ? 6 : 30,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text('${i + 1}'),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _startDay = val;
                                      if (_configMode == CalendarConfigMode.specificDay) {
                                        _endDay = val;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        // End Date (only for Date Range mode)
                        if (_configMode == CalendarConfigMode.dateRange) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _endMonth,
                                  decoration: const InputDecoration(
                                    labelText: 'ማብቂያ ወር',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: List.generate(
                                    13,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text(EthiopianCalendarUtil.getMonthName(i + 1)),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _endMonth = val;
                                        if (_endDay > (_endMonth == 13 ? 6 : 30)) {
                                          _endDay = _endMonth == 13 ? 5 : 30;
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _endDay,
                                  decoration: const InputDecoration(
                                    labelText: 'ቀን',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: List.generate(
                                    _endMonth == 13 ? 6 : 30,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('${i + 1}'),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _endDay = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Fasting Start / End Marker Toggles
                        if (_type == CalendarEventType.fast) ...[
                          Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    tr('calendar.mark_start_day', {'fallback': 'የመግቢያ ምልክት (መግቢያ)'}),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  value: _markStartBadge,
                                  onChanged: (val) =>
                                      setState(() => _markStartBadge = val ?? true),
                                ),
                              ),
                              if (_configMode == CalendarConfigMode.dateRange)
                                Expanded(
                                  child: CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      tr('calendar.mark_end_day', {'fallback': 'የማብቂያ ምልክት (ፍጻሜ)'}),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    value: _markEndBadge,
                                    onChanged: (val) =>
                                        setState(() => _markEndBadge = val ?? true),
                                  ),
                                ),
                            ],
                          ),
                        ],

                        // Recurring switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('admin.is_recurring', {'fallback': 'በየዓመቱ የሚደገም (ቋሚ)'})),
                          subtitle: Text(
                            tr('admin.is_recurring_sub', {'fallback': 'በየዓመቱ በተመሳሳይ ወርና ቀን ይከሰታል'}),
                            style: theme.textTheme.bodySmall,
                          ),
                          value: _isRecurring,
                          onChanged: (val) => setState(() => _isRecurring = val),
                        ),

                        if (!_isRecurring) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${tr('admin.specific_year', {'fallback': 'የተወሰነ የኢትዮጵያ ዓመት'})} (e.g. 2017)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.numbers),
                            ),
                            validator: (val) {
                              if (!_isRecurring && (val == null || int.tryParse(val) == null)) {
                                return 'ትክክለኛ የኢትዮጵያ ዓመት ያስገቡ';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Color Presets Section
                        Text(
                          'መለያ ቀለም (Color Management)',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildColorChip(colorOrange, 'Orange (ጾም)', parsedColor),
                            const SizedBox(width: 8),
                            _buildColorChip(colorRed, 'Red (ዓቢይ)', parsedColor),
                            const SizedBox(width: 8),
                            _buildColorChip(colorGreen, 'Green (መግቢያ/ልዩ)', parsedColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: _colorPresets.map((hex) {
                            final c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                            final isSel = _selectedColor == hex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = hex),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: isSel
                                      ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                                      : Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: tr('calendar.description', {'fallback': 'መግለጫ'}),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.description),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Spiritual Meaning
                        TextFormField(
                          controller: _spiritualMeaningController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: tr('calendar.spiritual_meaning', {'fallback': 'መንፈሳዊ/ታሪካዊ ትርጉም'}),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.auto_stories),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),

                        if (_type == CalendarEventType.fast) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _fastingRulesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: tr('calendar.fasting_rules', {'fallback': 'የጾም ሥርዓት እና ደንብ'}),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.rule),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Active Toggle
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('admin.active_status', {'fallback': 'ንቁ ሁነት (Active)'})),
                          value: _isActive,
                          onChanged: (val) => setState(() => _isActive = val ?? true),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: Text(tr('common.cancel', {'fallback': 'ተመለስ'})),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _saveConfiguration,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(tr('common.save', {'fallback': 'አስቀምጥ'})),
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

  Widget _buildColorChip(String hex, String label, Color currentColor) {
    final c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    final isSel = _selectedColor == hex;
    return InkWell(
      onTap: () => setState(() => _selectedColor = hex),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: isSel ? 0.2 : 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel ? c : c.withValues(alpha: 0.3),
            width: isSel ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview(ThemeData theme, String Function(String, [Map<String, dynamic>?]) tr, Color parsedColor) {
    final isDark = theme.brightness == Brightness.dark;
    final name = _nameController.text.trim().isEmpty ? 'የቀን ሁነት ስም' : _nameController.text.trim();
    final isFast = _type == CalendarEventType.fast;
    final isHoliday = _type == CalendarEventType.holiday;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: parsedColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: parsedColor),
              const SizedBox(width: 6),
              Text(
                tr('calendar.preview', {'fallback': 'የቀን ገጽታ ቅድመ እይታ (Live Preview)'}),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: parsedColor,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Simulated Calendar Cell
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: parsedColor.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: parsedColor.withValues(alpha: 0.7), width: 1.5),
                ),
                child: Stack(
                  children: [
                    if (_markStartBadge && isFast)
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'መግቢያ',
                            style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else if (_isMajor && isHoliday)
                      const Positioned(
                        top: 2,
                        left: 2,
                        child: Icon(Icons.star_rounded, size: 14, color: Color(0xFFDC2626)),
                      ),
                    Center(
                      child: Text(
                        '$_startDay',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 3,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: parsedColor, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Simulated Summary Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: parsedColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: parsedColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _configMode == CalendarConfigMode.specificDay
                            ? '${EthiopianCalendarUtil.getMonthName(_startMonth)} $_startDay'
                            : '${EthiopianCalendarUtil.getMonthName(_startMonth)} $_startDay — ${EthiopianCalendarUtil.getMonthName(_endMonth)} $_endDay',
                        style: TextStyle(
                          fontSize: 11,
                          color: parsedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_configMode == CalendarConfigMode.specificDay) {
      _endMonth = _startMonth;
      _endDay = _startDay;
    } else {
      if (_startMonth == _endMonth && _startDay > _endDay) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('መጀመሪያ ቀን ከማብቂያ ቀን መብለጥ አይችልም')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'nameEn': _nameEnController.text.trim().isEmpty ? null : _nameEnController.text.trim(),
        'type': _type.toJson(),
        'category': _category.toJson(),
        'importance': _importance,
        'isRecurring': _isRecurring,
        'ethiopianYear': _isRecurring ? null : int.tryParse(_yearController.text),
        'startMonth': _startMonth,
        'startDay': _startDay,
        'endMonth': _endMonth,
        'endDay': _endDay,
        'isMajor': _isMajor || _importance == 'MAJOR',
        'isActive': _isActive,
        'primaryColor': _selectedColor,
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'spiritualMeaning': _spiritualMeaningController.text.trim().isEmpty ? null : _spiritualMeaningController.text.trim(),
        'fastingRules': _fastingRulesController.text.trim().isEmpty ? null : _fastingRulesController.text.trim(),
      };

      final notifier = ref.read(adminCalendarEventsProvider.notifier);
      if (widget.initialEvent != null) {
        await notifier.updateEvent(widget.initialEvent!.id, payload);
      } else {
        await notifier.createEvent(payload);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialEvent != null
                  ? 'የቀን ቅንብሩ በተሳካ ሁኔታ ተሻሽሏል'
                  : 'አዲሱ የቀን ቅንብር በተሳካ ሁኔታ ተመዝግቧል',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ስህተት ተከስቷል፡ $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
