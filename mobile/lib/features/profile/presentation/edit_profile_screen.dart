import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
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

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(
      text: widget.initialProfile?.firstName ?? '',
    );
    _lastNameCtrl = TextEditingController(
      text: widget.initialProfile?.lastName ?? '',
    );
    _displayNameCtrl = TextEditingController(
      text: widget.initialProfile?.displayName ?? '',
    );
    _bioCtrl = TextEditingController(text: widget.initialProfile?.bio ?? '');
    _websiteCtrl = TextEditingController(
      text: widget.initialProfile?.website ?? '',
    );
    _countryCtrl = TextEditingController(
      text: widget.initialProfile?.country ?? '',
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final tr = ref.watch(trProvider);

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
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
