// lib/features/admin/presentation/widgets/manage_calendar_event_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_events_provider.dart';

class ManageCalendarEventDialog extends ConsumerStatefulWidget {
  final CalendarEventModel? initialEvent;

  const ManageCalendarEventDialog({
    super.key,
    this.initialEvent,
  });

  static Future<void> show(
    BuildContext context, {
    CalendarEventModel? event,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ManageCalendarEventDialog(initialEvent: event),
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

  late CalendarEventType _type;
  late CalendarEventCategory _category;
  late bool _isRecurring;
  late int _startMonth;
  late int _startDay;
  late int _endMonth;
  late int _endDay;
  late bool _isMajor;
  late bool _isActive;
  String? _selectedColor;
  bool _isSubmitting = false;

  final List<String> _colorPresets = [
    '#7C3AED', // Deep Purple
    '#D97706', // Amber / Gold
    '#059669', // Emerald
    '#0284C7', // Sky Blue
    '#DC2626', // Crimson Red
    '#EA580C', // Orange
    '#4F46E5', // Indigo
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.initialEvent;
    _nameController = TextEditingController(text: ev?.name ?? '');
    _nameEnController = TextEditingController(text: ev?.nameEn ?? '');
    _descriptionController = TextEditingController(text: ev?.description ?? '');
    _spiritualMeaningController =
        TextEditingController(text: ev?.spiritualMeaning ?? '');
    _fastingRulesController = TextEditingController(text: ev?.fastingRules ?? '');
    _yearController =
        TextEditingController(text: ev?.ethiopianYear?.toString() ?? '2017');

    _type = ev?.type ?? CalendarEventType.holiday;
    _category = ev?.category ?? CalendarEventCategory.majorHoliday;
    _isRecurring = ev?.isRecurring ?? true;
    _startMonth = ev?.startMonth ?? 1;
    _startDay = ev?.startDay ?? 1;
    _endMonth = ev?.endMonth ?? 1;
    _endDay = ev?.endDay ?? 1;
    _isMajor = ev?.isMajor ?? false;
    _isActive = ev?.isActive ?? true;
    _selectedColor = ev?.primaryColor ?? _colorPresets[0];
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final isEditing = widget.initialEvent != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Title
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit_calendar_rounded : Icons.add_circle_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEditing
                            ? tr('admin.edit_event', {'fallback': 'አጽዋማት/በዓላትን አስተካክል'})
                            : tr('admin.add_event', {'fallback': 'አዲስ ጾም/በዓል መዝግብ'}),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamilyFallback: const [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const Divider(),
                const SizedBox(height: 8),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name (Amharic)
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: '${tr('admin.event_name', {'fallback': 'ስም (በአማርኛ)'})} *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'እባክዎ የበዓሉን/ጾሙን ስም ያስገቡ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Name (English)
                        TextFormField(
                          controller: _nameEnController,
                          decoration: InputDecoration(
                            labelText: tr('admin.event_name_en', {'fallback': 'ስም በእንግሊዝኛ (አማራጭ)'}),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.translate),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Type & Category Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<CalendarEventType>(
                                initialValue: _type,
                                decoration: InputDecoration(
                                  labelText: tr('admin.type', {'fallback': 'ዓይነት'}),
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
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _type = val;
                                      if (val == CalendarEventType.fast) {
                                        _category = CalendarEventCategory.majorFast;
                                      } else {
                                        _category = CalendarEventCategory.majorHoliday;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<CalendarEventCategory>(
                                initialValue: _category,
                                decoration: InputDecoration(
                                  labelText: tr('admin.event_category', {'fallback': 'ምድብ'}),
                                  border: const OutlineInputBorder(),
                                ),
                                items: (_type == CalendarEventType.fast
                                        ? [
                                            CalendarEventCategory.majorFast,
                                            CalendarEventCategory.minorFast,
                                          ]
                                        : [
                                            CalendarEventCategory.majorHoliday,
                                            CalendarEventCategory.minorHoliday,
                                            CalendarEventCategory.monthlyFeast,
                                            CalendarEventCategory.annualFeast,
                                          ])
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(_categoryLabel(cat, tr)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _category = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Recurring switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('admin.is_recurring', {'fallback': 'በየዓመቱ የሚደገም (ቋሚ በዓል/ጾም)'})),
                          subtitle: Text(
                            tr('admin.is_recurring_sub', {
                              'fallback': 'በየዓመቱ በተመሳሳይ የኢትዮጵያ ወርና ቀን ይከበራል',
                            }),
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

                        const SizedBox(height: 16),
                        Text(
                          tr('admin.date_range', {'fallback': 'የቀን ወሰን (የኢትዮጵያ አቆጣጠር)'}),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Start Month & Day
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                initialValue: _startMonth,
                                decoration: const InputDecoration(
                                  labelText: 'መጀመሪያ ወር',
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
                                  if (val != null) setState(() => _startMonth = val);
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
                                  if (val != null) setState(() => _startDay = val);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // End Month & Day
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
                                  if (val != null) setState(() => _endMonth = val);
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
                                  if (val != null) setState(() => _endDay = val);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Major & Active toggles
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(tr('admin.is_major', {'fallback': 'ዓቢይ በዓል/ጾም'})),
                                value: _isMajor,
                                onChanged: (val) => setState(() => _isMajor = val ?? false),
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(tr('admin.active_status', {'fallback': 'ንቁ'})),
                                value: _isActive,
                                onChanged: (val) => setState(() => _isActive = val ?? true),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Color Presets
                        Text(
                          'መለያ ቀለም (Display Color)',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children: _colorPresets.map((hex) {
                            final c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                            final isSel = _selectedColor == hex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = hex),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: isSel
                                      ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                                      : null,
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
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Spiritual Meaning
                        TextFormField(
                          controller: _spiritualMeaningController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: tr('calendar.spiritual_meaning', {'fallback': 'መንፈሳዊ እና ታሪካዊ ትርጉም'}),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Fasting Rules
                        TextFormField(
                          controller: _fastingRulesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: tr('calendar.fasting_rules', {'fallback': 'የጾም ሥርዓት እና መመሪያ'}),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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
                      onPressed: _isSubmitting ? null : _saveEvent,
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

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startMonth == _endMonth && _startDay > _endDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('መጀመሪያ ቀን ከማብቂያ ቀን መብለጥ አይችልም')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'nameEn': _nameEnController.text.trim().isEmpty ? null : _nameEnController.text.trim(),
        'type': _type.toJson(),
        'category': _category.toJson(),
        'isRecurring': _isRecurring,
        'ethiopianYear': _isRecurring ? null : int.tryParse(_yearController.text),
        'startMonth': _startMonth,
        'startDay': _startDay,
        'endMonth': _endMonth,
        'endDay': _endDay,
        'isMajor': _isMajor,
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
          const SnackBar(content: Text('በዓሉ/ጾሙ በተሳካ ሁኔታ ተቀምጧል')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ስህተት፡ $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _categoryLabel(
      CalendarEventCategory cat, String Function(String, [Map<String, dynamic>?]) tr) {
    switch (cat) {
      case CalendarEventCategory.majorFast:
        return tr('calendar.major_fast', {'fallback': 'ዐቢይ ጾም'});
      case CalendarEventCategory.minorFast:
        return tr('calendar.minor_fast', {'fallback': 'ንኡስ ጾም'});
      case CalendarEventCategory.majorHoliday:
        return tr('calendar.major_holiday', {'fallback': 'ዓቢይ በዓል'});
      case CalendarEventCategory.minorHoliday:
        return tr('calendar.minor_holiday', {'fallback': 'ንኡስ በዓል'});
      case CalendarEventCategory.monthlyFeast:
        return tr('calendar.monthly_feast', {'fallback': 'ወርሃዊ በዓል'});
      case CalendarEventCategory.annualFeast:
        return tr('calendar.annual_feast', {'fallback': 'ዓመታዊ በዓል'});
    }
  }
}
