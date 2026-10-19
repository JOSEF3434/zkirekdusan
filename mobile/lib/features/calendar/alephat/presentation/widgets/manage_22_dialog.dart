// lib/features/calendar/alephat/presentation/widgets/manage_22_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/alephat/data/alephat_repository.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_22_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';

class Manage22Dialog extends ConsumerStatefulWidget {
  final Alephat22Model? entry;

  const Manage22Dialog({
    super.key,
    this.entry,
  });

  @override
  ConsumerState<Manage22Dialog> createState() => _Manage22DialogState();
}

class _Manage22DialogState extends ConsumerState<Manage22Dialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _letterCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _meaningCtrl;
  late TextEditingController _orderCtrl;
  late TextEditingController _noteCtrl;
  late TextEditingController _suppCtrl;
  late bool _isPublished;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _letterCtrl = TextEditingController(text: e?.letter ?? '');
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _meaningCtrl = TextEditingController(text: e?.meaning ?? '');
    _orderCtrl = TextEditingController(text: (e?.order ?? 1).toString());
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _suppCtrl = TextEditingController(text: e?.supplementaryInfo ?? '');
    _isPublished = e?.isPublished ?? true;
  }

  @override
  void dispose() {
    _letterCtrl.dispose();
    _titleCtrl.dispose();
    _meaningCtrl.dispose();
    _orderCtrl.dispose();
    _noteCtrl.dispose();
    _suppCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repo = ref.read(alephatRepositoryProvider);
    final data = {
      'letter': _letterCtrl.text.trim(),
      'title': _titleCtrl.text.trim(),
      'meaning': _meaningCtrl.text.trim().isEmpty ? null : _meaningCtrl.text.trim(),
      'order': int.tryParse(_orderCtrl.text.trim()) ?? 1,
      'note': _noteCtrl.text.trim(),
      'supplementaryInfo': _suppCtrl.text.trim().isEmpty ? null : _suppCtrl.text.trim(),
      'isPublished': _isPublished,
    };

    try {
      if (widget.entry != null) {
        await repo.update22(widget.entry!.id, data);
      } else {
        await repo.create22(data);
      }
      ref.invalidate(alephat22ListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.entry != null
                ? 'የ22 አሌፋት መረጃ ተስተካክሏል'
                : 'አዲስ የ22 አሌፋት መረጃ ተመዝግቧል'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.entry != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'የ22 አሌፋት መረጃ አርትዕ' : 'አዲስ የ22 አሌፋት መረጃ መዝግብ',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),

                // Form fields scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Letter & Order
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _letterCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'ፊደል (ምሳሌ፡ አ)*',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'ፊደል ያስገቡ';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _orderCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'ተራ ቁጥር (1-22)*',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || int.tryParse(val.trim()) == null) {
                                    return 'ቁጥር ያስገቡ';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Title
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ርዕስ (ምሳሌ፡ አሌፍ (አ))*',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'ርዕስ ያስገቡ';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Meaning
                        TextFormField(
                          controller: _meaningCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ትርጓሜ (ምሳሌ፡ አምላክ / መጀመሪያ)',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Note
                        TextFormField(
                          controller: _noteCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'የፊደሉ ምስጢርና ማብራሪያ*',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'ማብራሪያ ያስገቡ';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Supplementary Info
                        TextFormField(
                          controller: _suppCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'ተጨማሪ መንፈሳዊና ታሪካዊ መረጃ (አማራጭ)',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Published toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('ለተጠቃሚዎች ይፋ ይሁን (Published)'),
                          subtitle: const Text('ይህ ካልበራ መረጃው ለአስተዳዳሪዎች ብቻ ይታያል'),
                          value: _isPublished,
                          onChanged: (val) {
                            setState(() => _isPublished = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('ይቅር'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'አድስ' : 'መዝግብ'),
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
