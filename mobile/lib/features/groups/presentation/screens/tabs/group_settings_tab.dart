// lib/features/groups/presentation/screens/tabs/group_settings_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/domain/group_context_dto.dart';
import 'package:mobile/features/groups/presentation/providers/group_detail_provider.dart';

class GroupSettingsTab extends ConsumerStatefulWidget {
  final GroupContextDto groupContext;

  const GroupSettingsTab({super.key, required this.groupContext});

  @override
  ConsumerState<GroupSettingsTab> createState() => _GroupSettingsTabState();
}

class _GroupSettingsTabState extends ConsumerState<GroupSettingsTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _websiteController;
  late final TextEditingController _countryController;
  late GroupVisibility _visibility;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.groupContext.name);
    _descController = TextEditingController(
      text: widget.groupContext.description ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.groupContext.website ?? '',
    );
    _countryController = TextEditingController(
      text: widget.groupContext.country ?? '',
    );
    _visibility = widget.groupContext.visibility;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.updateGroup(
        widget.groupContext.id,
        name: name,
        description: _descController.text.trim(),
        visibility: _visibility.name.toUpperCase(),
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        country: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : null,
      );

      // Invalidate context provider so it refreshes everywhere
      ref.invalidate(groupDetailProvider(widget.groupContext.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canEdit = widget.groupContext.capabilities.canEditGroup;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Group Info Section
        Text(
          'Group Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          enabled: canEdit,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          enabled: canEdit,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _websiteController,
          enabled: canEdit,
          decoration: const InputDecoration(
            labelText: 'Website (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _countryController,
          enabled: canEdit,
          decoration: const InputDecoration(
            labelText: 'Country (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        // Privacy / Visibility Section
        Text(
          'Privacy & Access',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<GroupVisibility>(
          initialValue: _visibility,
          decoration: const InputDecoration(
            labelText: 'Visibility',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: GroupVisibility.public,
              child: Text('Public — Anyone can view videos and playlists'),
            ),
            DropdownMenuItem(
              value: GroupVisibility.private,
              child: Text('Private — Only group members can view content'),
            ),
            DropdownMenuItem(
              value: GroupVisibility.inviteOnly,
              child: Text('Invite Only — Invitation required to join'),
            ),
          ],
          onChanged: canEdit ? (v) => setState(() => _visibility = v!) : null,
        ),
        if (canEdit) ...[
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ],
        const SizedBox(height: 32),
        // Group Meta Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Group',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${widget.groupContext.status.name.toUpperCase()}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${widget.groupContext.createdAt.toLocal().toString().split(" ")[0]}',
                ),
                const SizedBox(height: 4),
                Text('Channels: ${widget.groupContext.videoChannels.length}'),
                const SizedBox(height: 4),
                Text('Members: ${widget.groupContext.membersCount}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
