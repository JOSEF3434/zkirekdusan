import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final ProfileModel? initialProfile;
  const EditProfileScreen({super.key, this.initialProfile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _countryCtrl;
  bool _isAvatarLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile ?? ref.read(profileProvider).profile;
    _firstNameCtrl = TextEditingController(
      text: p?.firstName ?? '',
    );
    _lastNameCtrl = TextEditingController(
      text: p?.lastName ?? '',
    );
    _displayNameCtrl = TextEditingController(
      text: p?.displayName ?? '',
    );
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _websiteCtrl = TextEditingController(
      text: p?.website ?? '',
    );
    _countryCtrl = TextEditingController(
      text: p?.country ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _websiteCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final tr = ref.read(trProvider);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      setState(() => _isAvatarLoading = true);
      final bytes = await pickedFile.readAsBytes();
      final filename = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'profile_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final success = await ref
          .read(profileProvider.notifier)
          .uploadAvatar(bytes, filename);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('profile.avatar_uploaded_success', {
                'fallback': 'Profile picture updated successfully',
              })),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          final err = ref.read(profileProvider).error ?? 'Failed to upload image';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAvatarLoading = false);
    }
  }

  Future<void> _deleteAvatar() async {
    final tr = ref.read(trProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('profile.delete_photo_title', {'fallback': 'Remove Photo'})),
        content: Text(tr('profile.delete_photo_confirm', {
          'fallback': 'Are you sure you want to remove your profile picture?',
        })),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isAvatarLoading = true);
    final success = await ref.read(profileProvider.notifier).deleteAvatar();
    if (mounted) {
      setState(() => _isAvatarLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('profile.avatar_removed_success', {
              'fallback': 'Profile picture removed',
            })),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _showImagePickerSheet(bool hasAvatar) {
    final tr = ref.read(trProvider);
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
              Text(
                tr('profile.manage_picture', {
                  'fallback': 'Profile Picture (Optional)',
                }),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF00C6FF)),
                title: Text(tr('profile.take_photo', {'fallback': 'Take photo with camera'})),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF10B981)),
                title: Text(tr('profile.choose_gallery', {'fallback': 'Choose from gallery'})),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text(
                    tr('profile.remove_photo', {'fallback': 'Remove profile picture'}),
                    style: const TextStyle(color: Colors.redAccent),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(profileProvider.notifier);
    final success = await notifier.updateMyProfile(
      firstName: _firstNameCtrl.text.trim().isNotEmpty
          ? _firstNameCtrl.text.trim()
          : null,
      lastName: _lastNameCtrl.text.trim().isNotEmpty
          ? _lastNameCtrl.text.trim()
          : null,
      displayName: _displayNameCtrl.text.trim().isNotEmpty
          ? _displayNameCtrl.text.trim()
          : null,
      bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
      website: _websiteCtrl.text.trim().isNotEmpty
          ? _websiteCtrl.text.trim()
          : null,
      country: _countryCtrl.text.trim().isNotEmpty
          ? _countryCtrl.text.trim()
          : null,
    );
    if (success && mounted) {
      context.pop();
    }
  }

  String _getInitials(ProfileModel? p) {
    if (p == null) return '?';
    if (p.firstName != null && p.lastName != null &&
        p.firstName!.isNotEmpty && p.lastName!.isNotEmpty) {
      return '${p.firstName![0]}${p.lastName![0]}'.toUpperCase();
    }
    if (p.displayName != null && p.displayName!.isNotEmpty) {
      return p.displayName![0].toUpperCase();
    }
    if (p.username != null && p.username!.isNotEmpty) {
      return p.username![0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final tr = ref.watch(trProvider);
    final currentProfile = state.profile ?? widget.initialProfile;
    final avatarUrl = currentProfile?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialProfile == null ||
                  (widget.initialProfile?.username == null)
              ? tr('profile.setup_profile')
              : tr('profile.edit_profile'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.error != null) ...[
                Text(
                  state.error!,
                  style: TextStyle(
                    color: cs.error,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Interactive Profile Picture Section ────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isAvatarLoading
                          ? null
                          : () => _showImagePickerSheet(hasAvatar),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.5),
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 54,
                              backgroundColor: cs.primaryContainer,
                              backgroundImage: hasAvatar
                                  ? CachedNetworkImageProvider(
                                      MediaUrlResolver.resolve(avatarUrl) ??
                                          avatarUrl,
                                    )
                                  : null,
                              child: _isAvatarLoading
                                  ? const SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : (!hasAvatar
                                      ? Text(
                                          _getInitials(currentProfile),
                                          style: TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.bold,
                                            color: cs.onPrimaryContainer,
                                          ),
                                        )
                                      : null),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 2.5,
                                ),
                              ),
                              child: Icon(
                                hasAvatar
                                    ? Icons.edit_rounded
                                    : Icons.camera_alt_rounded,
                                size: 18,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('profile.photo_optional_notice', {
                        'fallback': 'Profile picture (optional)',
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _isAvatarLoading
                              ? null
                              : () => _showImagePickerSheet(hasAvatar),
                          icon: Icon(
                            hasAvatar
                                ? Icons.photo_camera_rounded
                                : Icons.add_a_photo_rounded,
                            size: 18,
                          ),
                          label: Text(
                            hasAvatar
                                ? tr('profile.change_photo', {
                                    'fallback': 'Change Photo',
                                  })
                                : tr('profile.upload_photo', {
                                    'fallback': 'Upload Photo',
                                  }),
                          ),
                        ),
                        if (hasAvatar) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _isAvatarLoading ? null : _deleteAvatar,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            label: Text(
                              tr('common.delete'),
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _Field(ctrl: _firstNameCtrl, label: tr('auth.first_name_label')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(ctrl: _lastNameCtrl, label: tr('auth.last_name_label')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Field(ctrl: _displayNameCtrl, label: tr('profile.display_name_label')),
              const SizedBox(height: 16),
              _Field(ctrl: _bioCtrl, label: tr('profile.bio_label'), maxLines: 3),
              const SizedBox(height: 16),
              _Field(ctrl: _websiteCtrl, label: tr('profile.website_label')),
              const SizedBox(height: 16),
              _Field(ctrl: _countryCtrl, label: tr('profile.country_label')),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: state.isSaving ? null : _save,
                child: state.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(tr('common.save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final int maxLines;

  const _Field({required this.ctrl, required this.label, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
