// lib/features/groups/presentation/widgets/edit_group_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/rich_text/mention_text_controller.dart';
import 'package:mobile/core/rich_text/rich_text_composer.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
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
  final String? initialAvatarUrl;

  const EditGroupSheet({
    super.key,
    required this.groupId,
    required this.initialName,
    this.initialDescription,
    this.initialVisibility,
    this.initialWebsite,
    this.initialCountry,
    this.initialAvatarUrl,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String groupId,
    required String initialName,
    String? initialDescription,
    String? initialVisibility,
    String? initialWebsite,
    String? initialCountry,
    String? initialAvatarUrl,
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
        initialAvatarUrl: initialAvatarUrl,
      ),
    );
  }

  @override
  ConsumerState<EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends ConsumerState<EditGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final MentionTextController _descController;
  late final TextEditingController _websiteController;
  late final TextEditingController _countryController;
  late String _visibility;
  String? _avatarUrl;
  bool _isAvatarLoading = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descController = MentionTextController(
      text: widget.initialDescription ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.initialWebsite ?? '',
    );
    _countryController = TextEditingController(
      text: widget.initialCountry ?? '',
    );
    _visibility = widget.initialVisibility ?? 'PUBLIC';
    _avatarUrl = widget.initialAvatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isAvatarLoading = true);
      final bytes = await picked.readAsBytes();
      final filename = picked.name.isNotEmpty
          ? picked.name
          : 'group_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final repo = ref.read(groupRepositoryProvider);
      final newUrl = await repo.uploadGroupAvatar(widget.groupId, bytes, filename);

      setState(() {
        _avatarUrl = newUrl;
        _isAvatarLoading = false;
      });

      ref.invalidate(groupDetailProvider(widget.groupId));
      ref.read(creatorWorkspaceProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group picture updated successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAvatarLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload picture: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Group Picture'),
        content: const Text('Are you sure you want to remove the group profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      setState(() => _isAvatarLoading = true);
      final repo = ref.read(groupRepositoryProvider);
      await repo.deleteGroupAvatar(widget.groupId);

      setState(() {
        _avatarUrl = null;
        _isAvatarLoading = false;
      });

      ref.invalidate(groupDetailProvider(widget.groupId));
      ref.read(creatorWorkspaceProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group picture removed'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAvatarLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove picture: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showAvatarPickerSheet() {
    final hasPic = _avatarUrl != null && _avatarUrl!.isNotEmpty;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Group Profile Picture (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF00C6FF)),
                title: const Text('Take photo with camera'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF10B981)),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              if (hasPic)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text(
                    'Remove group picture',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _deleteAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
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
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasPic = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
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
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: cs.primary,
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
              const SizedBox(height: 16),

              // ── Group Picture Management ──────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isAvatarLoading ? null : _showAvatarPickerSheet,
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.5),
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: cs.primaryContainer,
                              backgroundImage: hasPic
                                  ? CachedNetworkImageProvider(
                                      MediaUrlResolver.resolve(_avatarUrl!) ??
                                          _avatarUrl!,
                                    )
                                  : null,
                              child: _isAvatarLoading
                                  ? const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : (!hasPic
                                      ? Text(
                                          widget.initialName.isNotEmpty
                                              ? (widget.initialName.length > 2
                                                  ? widget.initialName.substring(0, 2)
                                                  : widget.initialName)
                                              : 'G',
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: cs.onPrimaryContainer,
                                          ),
                                        )
                                      : null),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                hasPic ? Icons.edit_rounded : Icons.camera_alt_rounded,
                                size: 16,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Group profile picture (optional)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _isAvatarLoading ? null : _showAvatarPickerSheet,
                          icon: Icon(
                            hasPic ? Icons.photo_camera_rounded : Icons.add_a_photo_rounded,
                            size: 16,
                          ),
                          label: Text(hasPic ? 'Change Photo' : 'Upload Photo'),
                        ),
                        if (hasPic) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _isAvatarLoading ? null : _deleteAvatar,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: cs.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onErrorContainer,
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
                decoration: InputDecoration(
                  labelText: 'Group Name *',
                  hintText: 'Enter group name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.group_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Group name is required';
                  }
                  if (val.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              RichTextComposer(
                controller: _descController,
                child: TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'What is this group about? (Supports @mentions)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 4,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: InputDecoration(
                  labelText: 'Visibility',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.visibility_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'PUBLIC',
                    child: Text('Public — Anyone can discover and join'),
                  ),
                  DropdownMenuItem(
                    value: 'PRIVATE',
                    child: Text('Private — Approval required to join'),
                  ),
                  DropdownMenuItem(
                    value: 'INVITE_ONLY',
                    child: Text('Invite Only — Explicit invites only'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _visibility = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: InputDecoration(
                  labelText: 'Website',
                  hintText: 'https://example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.language_outlined),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: 'Country',
                  hintText: 'e.g., Ethiopia',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
