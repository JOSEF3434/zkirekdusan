// lib/features/admin/presentation/widgets/manage_mesbak_dialog.dart
import 'package:abushakir/abushakir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';

class ManageMesbakDialog extends ConsumerStatefulWidget {
  final CalendarNoteModel? existingNote;
  final int? prefillYear;
  final int? prefillMonth;
  final int? prefillDay;

  const ManageMesbakDialog({
    super.key,
    this.existingNote,
    this.prefillYear,
    this.prefillMonth,
    this.prefillDay,
  });

  static Future<void> show(
    BuildContext context, {
    CalendarNoteModel? existingNote,
    int? prefillYear,
    int? prefillMonth,
    int? prefillDay,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ManageMesbakDialog(
        existingNote: existingNote,
        prefillYear: prefillYear,
        prefillMonth: prefillMonth,
        prefillDay: prefillDay,
      ),
    );
  }

  @override
  ConsumerState<ManageMesbakDialog> createState() => _ManageMesbakDialogState();
}

class _ManageMesbakDialogState extends ConsumerState<ManageMesbakDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _yearController;

  late int _selectedMonth;
  late int _selectedDay;
  bool _allowDownload = false;
  bool _isAutoPublishEnabled = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = EthiopianCalendarUtil.now();

    final note = widget.existingNote;
    _yearController = TextEditingController(
      text: (note?.ethiopianYear ?? widget.prefillYear ?? now.year).toString(),
    );
    _selectedMonth = note?.ethiopianMonth ?? widget.prefillMonth ?? now.month;
    _selectedDay = note?.ethiopianDay ?? widget.prefillDay ?? now.day;

    _titleController = TextEditingController(
      text: note?.title ?? 'የእለቱ ምስባክ',
    );
    _contentController = TextEditingController(
      text: note?.content ?? '',
    );

    _allowDownload = note?.allowDownload ?? false;
    _isAutoPublishEnabled = note?.isAutoPublishEnabled ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎ መጀመሪያ ይግቡ')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final year = int.tryParse(_yearController.text.trim()) ?? EthiopianCalendarUtil.now().year;
      final ethDate = EtDatetime(year: year, month: _selectedMonth, day: _selectedDay);
      final gregDate = EthiopianCalendarUtil.toGregorian(ethDate);

      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      if (widget.existingNote != null) {
        // Update
        await ref.read(updateCalendarNoteProvider)(
          widget.existingNote!.id,
          title: title,
          content: content,
          allowDownload: _allowDownload,
          isAutoPublishEnabled: _isAutoPublishEnabled,
        );
      } else {
        // Create
        await ref.read(createCalendarNoteProvider)(
          userId: user.id,
          ethiopianYear: year,
          ethiopianMonth: _selectedMonth,
          ethiopianDay: _selectedDay,
          gregorianDate: gregDate,
          title: title,
          content: content,
          allowDownload: _allowDownload,
          isAutoPublishEnabled: _isAutoPublishEnabled,
          category: 'MESBAK',
        );
      }

      // Refresh providers
      ref.invalidate(calendarNotesForDateProvider);
      ref.invalidate(calendarNotesForMonthProvider);
      ref.invalidate(calendarNotesForCurrentWeekProvider);
      ref.invalidate(calendarNotesForRangeProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingNote != null
                  ? 'ምስባኩ በተሳካ ሁኔታ ተሻሽሏል'
                  : 'አዲስ ምስባክ በተሳካ ሁኔታ ተመዝግቧል',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ስህተት ተከስቷል: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final isEditing = widget.existingNote != null;

    final daysInMonth = EthiopianCalendarUtil.getDaysInMonth(
      int.tryParse(_yearController.text.trim()) ?? 2019,
      _selectedMonth,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'ምስባክ ማስተካከያ' : 'አዲስ ምስባክ መመዝገቢያ',
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

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ethiopian Date Row (Year | Month | Day)
                        Text(
                          'የኢትዮጵያ ቀን',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Year
                            SizedBox(
                              width: 90,
                              child: TextFormField(
                                controller: _yearController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'ዓመተ ምሕረት',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'አስፈላጊ';
                                  final num = int.tryParse(val.trim());
                                  if (num == null || num < 1900 || num > 2200) return 'ልክ ያልሆነ';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Month
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                initialValue: _selectedMonth,
                                decoration: InputDecoration(
                                  labelText: 'ወር',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: List.generate(13, (i) {
                                  final m = i + 1;
                                  return DropdownMenuItem<int>(
                                    value: m,
                                    child: Text(
                                      EthiopianCalendarUtil.getMonthName(m),
                                      style: const TextStyle(
                                        fontFamilyFallback: ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                                      ),
                                    ),
                                  );
                                }),
                                onChanged: isEditing
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedMonth = val;
                                            if (_selectedDay > EthiopianCalendarUtil.getDaysInMonth(
                                              int.tryParse(_yearController.text.trim()) ?? 2019,
                                              val,
                                            )) {
                                              _selectedDay = 1;
                                            }
                                          });
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Day
                            SizedBox(
                              width: 85,
                              child: DropdownButtonFormField<int>(
                                initialValue: _selectedDay > daysInMonth ? 1 : _selectedDay,
                                decoration: InputDecoration(
                                  labelText: 'ቀን',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: List.generate(
                                  daysInMonth,
                                  (i) => DropdownMenuItem<int>(
                                    value: i + 1,
                                    child: Text('${i + 1}'),
                                  ),
                                ),
                                onChanged: isEditing
                                    ? null
                                    : (val) {
                                        if (val != null) setState(() => _selectedDay = val);
                                      },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Mesbak Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'የምስባክ ርእስ (ለምሳሌ፡ ምስባክ ዘታኅሣሥ ፭ ወይም መዝሙር ፹፱፥፳)',
                            hintText: 'ምስባክ - መዝሙር ...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'እባክዎ ርእስ ያስገቡ';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Mesbak Content (Multiline)
                        TextFormField(
                          controller: _contentController,
                          maxLines: 8,
                          decoration: InputDecoration(
                            labelText: 'የምስባኩ ቃላት / መዝሙር (ግዕዝ እና አማርኛ ትርጉም)',
                            hintText:
                                'ረከብክዎ ለዳዊት ገብርየ ወቀባእክዎ ቅብዐ ቅዱሰየ ወእዴየ ትረድኦ።\n\nትርጉም፡- ባሪያዬን ዳዊትን አገኘሁት፥ የተቀደሰ ዘይቴንም ቀባሁት፤ እጄም ትረዳዋለች።',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'እባክዎ የምስባኩን ቃላት ያስገቡ';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Options
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('ተጠቃሚዎች እንዲያወርዱት ፍቀድ (Allow Download)'),
                          value: _allowDownload,
                          onChanged: (val) => setState(() => _allowDownload = val),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('በዕለቱ በራስ-ሰር ይለጠፍ (Auto Publish)'),
                          value: _isAutoPublishEnabled,
                          onChanged: (val) => setState(() => _isAutoPublishEnabled = val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: Text(tr('common.cancel', {'fallback': 'ሰርዝ'})),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        isEditing ? 'አሻሽል' : 'መዝግብ',
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
