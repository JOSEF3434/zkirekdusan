import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('library.title'))),
      body: ListView(
        children: [
          _LibraryItem(
            icon: Icons.play_circle_outline,
            title: tr('home.continue_watching'),
            onTap: () => context.push('/library/continue-watching'),
          ),
          _LibraryItem(
            icon: Icons.history,
            title: tr('library.history'),
            onTap: () => context.push('/library/history'),
          ),
          _LibraryItem(
            icon: Icons.download_done,
            title: tr('library.downloads'),
            onTap: () => context.push('/library/downloads'),
          ),
          _LibraryItem(
            icon: Icons.bookmark_border,
            title: tr('library.bookmarks'),
            onTap: () => context.push('/library/bookmarks'),
          ),
          _LibraryItem(
            icon: Icons.thumb_up_outlined,
            title: tr('library.liked'),
            onTap: () => context.push('/library/liked'),
          ),
          const Divider(),
          _LibraryItem(
            icon: Icons.playlist_play,
            title: tr('library.playlists'),
            onTap: () => context.push('/library/playlists'),
          ),
          _LibraryItem(
            icon: Icons.groups_outlined,
            title: tr('library.groups'),
            onTap: () => context.push('/library/groups'),
          ),
        ],
      ),
    );
  }
}

class _LibraryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LibraryItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
