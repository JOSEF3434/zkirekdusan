// lib/features/groups/presentation/widgets/edit_group_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/creator/presentation/providers/creator_workspace_provider.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/presentation/providers/group_detail_provider.dart';

class EditGroupSheet extends ConsumerStatefulWidget {
  final String groupId;
  final String initialName;
  final String? initialDescription;
  final String? initialVisibility;
  final String? initialWebsite;
  final String? initialCountry;

  const EditGroupSheet({
    super.key,
    required this.groupId,
    required this.initialName,
    this.initialDescription,
    this.initialVisibility,
    this.initialWebsite,
    this.initialCountry,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String groupId,
    required String initialName,
    String? initialDescription,
    String? initialVisibility,
    String? initialWebsite,
    String? initialCountry,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditGroupSheet(
        groupId: groupId,
        initialName: initialName,
        initialDescription: initialDescription,
        initialVisibility: initialVisibility,
        initialWebsite: initialWebsite,
        initialCountry: initialCountry,
      ),
    );
  }

  @override
  ConsumerState<EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends ConsumerState<EditGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _websiteController;
  late final TextEditingController _countryController;
  late String _visibility;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.initialWebsite ?? '',
    );
    _countryController = TextEditingController(
      text: widget.initialCountry ?? '',
    );
    _visibility = widget.initialVisibility ?? 'PUBLIC';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.updateGroup(
        widget.groupId,
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        visibility: _visibility,
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
      );

      // Invalidate relevant providers to force fresh data
      ref.invalidate(groupDetailProvider(widget.groupId));
      ref.read(creatorWorkspaceProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e is Failure) {
            _errorMessage = e.message;
          } else {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Group Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: const InputDecoration(
                  labelText: 'Visibility',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.visibility),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'PUBLIC',
                    child: Text('Public (Anyone can see)'),
                  ),
                  DropdownMenuItem(
                    value: 'PRIVATE',
                    child: Text('Private (Members only)'),
                  ),
                  DropdownMenuItem(
                    value: 'INVITE_ONLY',
                    child: Text('Invite Only'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _visibility = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country / Location (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
