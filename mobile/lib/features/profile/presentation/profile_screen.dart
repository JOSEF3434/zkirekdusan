// lib/features/profile/presentation/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile when screen first appears
    Future.microtask(() => ref.read(profileProvider.notifier).loadMyProfile());
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (profileState.profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () => _showEditDialog(context, profileState.profile!),
            ),
        ],
      ),
      body: _buildBody(context, profileState, authState, cs),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProfileState state,
    AuthState authState,
    ColorScheme cs,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadMyProfile(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return const Center(child: Text('No profile data'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(profileProvider.notifier).loadMyProfile(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: profile.avatarUrl != null
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              backgroundColor: cs.primaryContainer,
              child: profile.avatarUrl == null
                  ? Text(
                      _initials(profile),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Display name / username
          Center(
            child: Column(
              children: [
                Text(
                  profile.displayName ??
                      _fullName(profile) ??
                      profile.username ??
                      authState.user?.displayIdentifier ??
                      'User',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (profile.username != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${profile.username}',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'No username set',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (profile.isVerified) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(color: cs.primary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
          ],

          // Stats row
          _StatsRow(stats: profile.stats, profileId: profile.id),
          const SizedBox(height: 24),

          // Profile details card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _DetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: authState.user?.email ?? '—',
                  ),
                  if (profile.website != null)
                    _DetailRow(
                      icon: Icons.link,
                      label: 'Website',
                      value: profile.website!,
                    ),
                  if (profile.country != null)
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Country',
                      value: profile.country!,
                    ),
                  _DetailRow(
                    icon: Icons.visibility_outlined,
                    label: 'Visibility',
                    value: profile.visibility,
                  ),
                ],
              ),
            ),
          ),

          // Username setup CTA
          if (profile.username == null) ...[
            const SizedBox(height: 16),
            Card(
              color: cs.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.alternate_email, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set your username',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'A unique username lets others find you easily.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showEditDialog(context, profile),
                      child: const Text('Set Now'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(ProfileModel profile) {
    if (profile.firstName != null && profile.lastName != null) {
      return '${profile.firstName![0]}${profile.lastName![0]}'.toUpperCase();
    }
    if (profile.username != null && profile.username!.isNotEmpty) {
      return profile.username![0].toUpperCase();
    }
    return '?';
  }

  String? _fullName(ProfileModel profile) {
    if (profile.firstName != null || profile.lastName != null) {
      return '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
    }
    return null;
  }

  void _showEditDialog(BuildContext context, ProfileModel profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }
}

// ── Edit Profile Bottom Sheet ───────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final ProfileModel profile;
  const _EditProfileSheet({required this.profile});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
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
      text: widget.profile.firstName ?? '',
    );
    _lastNameCtrl = TextEditingController(text: widget.profile.lastName ?? '');
    _displayNameCtrl = TextEditingController(
      text: widget.profile.displayName ?? '',
    );
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? '');
    _websiteCtrl = TextEditingController(text: widget.profile.website ?? '');
    _countryCtrl = TextEditingController(text: widget.profile.country ?? '');
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
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit Profile',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (state.error != null) ...[
            Text(
              state.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              Expanded(
                child: _Field(ctrl: _firstNameCtrl, label: 'First Name'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(ctrl: _lastNameCtrl, label: 'Last Name'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Field(ctrl: _displayNameCtrl, label: 'Display Name'),
          const SizedBox(height: 12),
          _Field(ctrl: _bioCtrl, label: 'Bio', maxLines: 3),
          const SizedBox(height: 12),
          _Field(ctrl: _websiteCtrl, label: 'Website'),
          const SizedBox(height: 12),
          _Field(ctrl: _countryCtrl, label: 'Country'),
          const SizedBox(height: 20),

          FilledButton(
            onPressed: state.isSaving ? null : _save,
            child: state.isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ],
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
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

// ── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ProfileStatsModel stats;
  final String? profileId;

  const _StatsRow({required this.stats, this.profileId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(
          value: stats.followersCount,
          label: 'Followers',
          onTap: () {
            if (profileId != null) {
              context.push('/profile/$profileId/followers');
            }
          },
        ),
        _Stat(
          value: stats.followingCount,
          label: 'Following',
          onTap: () {
            if (profileId != null) {
              context.push('/profile/$profileId/following');
            }
          },
        ),
        _Stat(value: stats.postsCount, label: 'Posts'),
        _Stat(value: stats.videosCount, label: 'Videos'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _Stat({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Row ──────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
