import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_provider.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const PublicProfileScreen({super.key, required this.username});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(publicProfileProvider(widget.username));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.username)),
      body: profileState.when(
        data: (profile) => _buildBody(context, profile, cs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e'),
              ElevatedButton(
                onPressed: () => ref
                    .read(publicProfileProvider(widget.username).notifier)
                    .refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProfileModel profile,
    ColorScheme cs,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            backgroundColor: cs.primaryContainer,
            child: profile.avatarUrl == null
                ? Text(
                    profile.username?[0].toUpperCase() ?? '?',
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
        Center(
          child: Column(
            children: [
              Text(
                profile.displayName ?? profile.username ?? 'User',
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
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          Text(
            profile.bio!,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
        ],
        // Follow Button
        Center(
          child: FilledButton(
            onPressed: () {
              // TODO: Implement Follow
            },
            child: const Text('Follow'),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(
              value: profile.stats.followersCount,
              label: 'Followers',
              onTap: () => context.push('/profile/${profile.id}/followers'),
            ),
            _Stat(
              value: profile.stats.followingCount,
              label: 'Following',
              onTap: () => context.push('/profile/${profile.id}/following'),
            ),
            _Stat(value: profile.stats.postsCount, label: 'Posts'),
            _Stat(value: profile.stats.videosCount, label: 'Videos'),
          ],
        ),
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
