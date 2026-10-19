// lib/features/calendar/alephat/presentation/widgets/manage_letter_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/alephat/data/alephat_repository.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';

class ManageLetterDialog extends ConsumerStatefulWidget {
  final AlephatLetterModel? letter;
  final int initialTab;

  const ManageLetterDialog({
    super.key,
    this.letter,
    this.initialTab = 0,
  });

  @override
  ConsumerState<ManageLetterDialog> createState() => _ManageLetterDialogState();
}

class _ManageLetterDialogState extends ConsumerState<ManageLetterDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _letterFormKey = GlobalKey<FormState>();

  late TextEditingController _letterCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _orderCtrl;
  late TextEditingController _noteCtrl;
  late TextEditingController _pronunciationCtrl;
  late bool _isPublished;
  late List<AlephatFamilyMemberModel> _familyMembers;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final l = widget.letter;
    _tabController = TabController(
      length: widget.letter != null ? 2 : 1,
      vsync: this,
      initialIndex: (widget.letter != null && widget.initialTab == 1) ? 1 : 0,
    );

    _letterCtrl = TextEditingController(text: l?.letter ?? '');
    _nameCtrl = TextEditingController(text: l?.name ?? '');
    _orderCtrl = TextEditingController(text: (l?.order ?? 1).toString());
    _noteCtrl = TextEditingController(text: l?.defaultNote ?? '');
    _pronunciationCtrl = TextEditingController(text: l?.pronunciationGuide ?? '');
    _isPublished = l?.isPublished ?? true;
    _familyMembers = l != null ? List.from(l.familyMembers) : [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _letterCtrl.dispose();
    _nameCtrl.dispose();
    _orderCtrl.dispose();
    _noteCtrl.dispose();
    _pronunciationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLetter() async {
    if (!_letterFormKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repo = ref.read(alephatRepositoryProvider);
    final data = {
      'letter': _letterCtrl.text.trim(),
      'name': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      'order': int.tryParse(_orderCtrl.text.trim()) ?? 1,
      'defaultNote': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      'pronunciationGuide': _pronunciationCtrl.text.trim().isEmpty
          ? null
          : _pronunciationCtrl.text.trim(),
      'isPublished': _isPublished,
    };

    try {
      if (widget.letter != null) {
        await repo.updateLetter(widget.letter!.id, data);
      } else {
        final created = await repo.createLetter(data);
        ref.read(selectedBaseLetterIdProvider.notifier).state = created.id;
      }
      ref.invalidate(alephatLettersProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.letter != null
                ? 'የፊደል መረጃ ተስተካክሏል'
                : 'አዲስ ፊደል ተመዝግቧል'),
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

  void _showAddOrEditMemberDialog([AlephatFamilyMemberModel? member]) {
    final formKey = GlobalKey<FormState>();
    final glyphCtrl = TextEditingController(text: member?.glyph ?? '');
    final orderIndexCtrl =
        TextEditingController(text: (member?.orderIndex ?? (_familyMembers.length + 1)).toString());
    final orderNameCtrl = TextEditingController(text: member?.orderName ?? '');
    final noteCtrl = TextEditingController(text: member?.note ?? '');
    final pronCtrl = TextEditingController(text: member?.pronunciation ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(member != null ? 'የቤተሰብ አባል አርትዕ' : 'አዲስ የቤተሰብ አባል ጨምር'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: glyphCtrl,
                  decoration: const InputDecoration(labelText: 'ምልክት (ፊደል)*'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'ያስገቡ' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: orderIndexCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ቅደም ተከተል (1-8)*'),
                  validator: (v) => int.tryParse(v ?? '') == null ? 'ቁጥር ያስገቡ' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: orderNameCtrl,
                  decoration: const InputDecoration(labelText: 'የድምጽ ስም (ምሳሌ፡ ካዕብ)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'የዚህ ድምጽ ማብራሪያ (አማራጭ)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pronCtrl,
                  decoration: const InputDecoration(labelText: 'አጠራር (ምሳሌ፡ hu)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ይቅር'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              final repo = ref.read(alephatRepositoryProvider);
              final memberData = {
                'glyph': glyphCtrl.text.trim(),
                'orderIndex': int.parse(orderIndexCtrl.text.trim()),
                'orderName': orderNameCtrl.text.trim().isEmpty ? null : orderNameCtrl.text.trim(),
                'note': noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                'pronunciation': pronCtrl.text.trim().isEmpty ? null : pronCtrl.text.trim(),
                'isPublished': true,
              };

              try {
                if (widget.letter != null) {
                  if (member != null) {
                    await repo.updateFamilyMember(widget.letter!.id, member.id, memberData);
                  } else {
                    await repo.addFamilyMember(widget.letter!.id, memberData);
                  }
                  ref.invalidate(alephatLettersProvider);
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('የቤተሰብ መረጃ ተቀይሯል')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ስህተት፡ $e')),
                );
              }
            },
            child: const Text('አስቀምጥ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.letter != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'ፊደል "${widget.letter!.letter}" አስተዳድር' : 'አዲስ ፊደል መዝግብ',
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

              if (isEditing) ...[
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'ጠቅላላ መረጃ'),
                    Tab(text: 'የፊደል ቤተሰብ (Orders)'),
                  ],
                ),
              ],

              const SizedBox(height: 12),

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

              // Tab contents
              Expanded(
                child: isEditing
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGeneralTab(),
                          _buildFamilyTab(theme),
                        ],
                      )
                    : _buildGeneralTab(),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('ዝጋ'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submitLetter,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'ለውጦችን መዝግብ' : 'አስቀምጥ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    return Form(
      key: _letterFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _letterCtrl,
                    decoration: const InputDecoration(
                      labelText: 'መሠረታዊ ፊደል (ምሳሌ፡ ሀ)*',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'ፊደል ያስገቡ' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'የፊደል ስም (ምሳሌ፡ ሆይ)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _orderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ተራ*',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => int.tryParse(v ?? '') == null ? 'ቁጥር' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pronunciationCtrl,
              decoration: const InputDecoration(
                labelText: 'የአጠራር መመሪያ (Pronunciation Guide)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'ጠቅላላ የትምህርት ማብራሪያ (General Educational Note)*',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ይፋ ይሁን (Published)'),
              subtitle: const Text('ካተጠፋ ለአስተዳዳሪዎች ብቻ ይታያል'),
              value: _isPublished,
              onChanged: (v) => setState(() => _isPublished = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyTab(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'የቤተሰብ አባላት (${_familyMembers.length})',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('አዲስ አባል'),
              onPressed: () => _showAddOrEditMemberDialog(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _familyMembers.isEmpty
              ? const Center(child: Text('ምንም የቤተሰብ አባል የለም'))
              : ListView.builder(
                  itemCount: _familyMembers.length,
                  itemBuilder: (itemCtx, index) {
                    final m = _familyMembers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            m.glyph,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('${m.glyph} (${m.orderName ?? '${m.orderIndex}ኛ'})'),
                        subtitle: Text(
                          m.note != null && m.note!.isNotEmpty
                              ? m.note!
                              : (m.pronunciation != null ? 'አጠራር፡ ${m.pronunciation}' : 'ማብራሪያ የለም'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showAddOrEditMemberDialog(m),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () async {
                                if (widget.letter == null) return;
                                try {
                                  final repo = ref.read(alephatRepositoryProvider);
                                  await repo.deleteFamilyMember(widget.letter!.id, m.id);
                                  setState(() {
                                    _familyMembers.removeAt(index);
                                  });
                                  ref.invalidate(alephatLettersProvider);
                                } catch (e) {
                                  if (!itemCtx.mounted) return;
                                  ScaffoldMessenger.of(itemCtx).showSnackBar(
                                    SnackBar(content: Text('ስህተት፡ $e')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
