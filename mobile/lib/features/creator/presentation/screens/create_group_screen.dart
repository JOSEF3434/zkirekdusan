// lib/features/creator/presentation/screens/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';
import 'package:mobile/features/creator/presentation/providers/creator_workspace_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();

  GroupVisibility _visibility = GroupVisibility.public;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final name = _nameController.text;
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    _slugController.text = slug;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(creatorWorkspaceProvider.notifier)
        .createGroup(
          name: _nameController.text,
          slug: _slugController.text,
          description: _descriptionController.text,
          visibility: _visibility,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes on the create operation
    ref.listen(creatorWorkspaceProvider.select((s) => s.createGroupStatus), (
      previous,
      status,
    ) {
      if (status == CreateGroupStatus.success) {
        final group = ref.read(creatorWorkspaceProvider).lastCreatedGroup;
        if (group != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                group.status == GroupStatus.active
                    ? 'Channel created and is now active!'
                    : 'Channel created! Waiting for admin approval.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        ref.read(creatorWorkspaceProvider.notifier).resetCreateState();
        // Use context.go to replace the stack and land firmly on the workspace
        context.go('/creator/workspace');
      } else if (status == CreateGroupStatus.error) {
        final error = ref.read(creatorWorkspaceProvider).createGroupError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(creatorWorkspaceProvider.notifier).resetCreateState();
      }
    });

    final isSubmitting = ref.watch(
      creatorWorkspaceProvider.select(
        (s) => s.createGroupStatus == CreateGroupStatus.loading,
      ),
    );
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('creator.create_channel_action'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: tr('live.channel_name_label'),
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? tr('live.channel_name_required')
                  : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Slug (URL friendly)',
                border: OutlineInputBorder(),
                helperText: 'Auto-generated from name, but can be customized.',
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a slug' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Visibility',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<GroupVisibility>(
                  value: _visibility,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(
                      value: GroupVisibility.public,
                      child: Text('Public'),
                    ),
                    DropdownMenuItem(
                      value: GroupVisibility.private,
                      child: Text('Private'),
                    ),
                    DropdownMenuItem(
                      value: GroupVisibility.inviteOnly,
                      child: Text('Invite Only'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _visibility = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(tr('creator.create_channel_action')),
            ),
          ],
        ),
      ),
    );
  }
}
