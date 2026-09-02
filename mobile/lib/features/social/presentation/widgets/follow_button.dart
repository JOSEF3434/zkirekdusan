// lib/features/social/presentation/widgets/follow_button.dart
// Reusable follow button connected to the scoped followProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/social/presentation/providers/follow_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';

class FollowButton extends ConsumerWidget {
  final String targetUserId;
  final bool isDense;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final followStateAsync = ref.watch(followProvider(targetUserId));
    final auth = ref.watch(authProvider);

    return followStateAsync.when(
      loading: () => const _LoadingButton(),
      error: (error, stackTrace) => _ErrorButton(
        onRetry: () => ref.refresh(followProvider(targetUserId)),
      ),
      data: (state) {
        final isFollowing = state.isFollowing;
        final isLoading = state.isLoading;

        if (isFollowing) {
          return OutlinedButton(
            style: isDense
                ? OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 32),
                  )
                : null,
            onPressed: isLoading
                ? null
                : () {
                    // Auth guard
                    if (auth.status != AuthStatus.authenticated) {
                      context.push('/login');
                      return;
                    }
                    ref.read(followProvider(targetUserId).notifier).unfollow();
                  },
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(tr('follow.following')),
          );
        }

        return FilledButton(
          style: isDense
              ? FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 32),
                )
              : null,
          onPressed: isLoading
              ? null
              : () {
                  // Auth guard
                  if (auth.status != AuthStatus.authenticated) {
                    context.push('/login');
                    return;
                  }
                  ref.read(followProvider(targetUserId).notifier).follow();
                },
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(tr('follow.follow')),
        );
      },
    );
  }
}

class _LoadingButton extends StatelessWidget {
  const _LoadingButton();

  @override
  Widget build(BuildContext context) {
    return const OutlinedButton(
      onPressed: null,
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _ErrorButton extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: const Text('Error'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
