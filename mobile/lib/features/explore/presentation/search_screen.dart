import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:mobile/features/explore/presentation/providers/search_provider.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            suffixIcon: searchState.query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).clear();
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            ref.read(searchProvider.notifier).setQuery(val);
          },
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', null, searchState.type),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Videos',
                  SearchEntityType.videos,
                  searchState.type,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Channels',
                  SearchEntityType.channels,
                  searchState.type,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Groups',
                  SearchEntityType.groups,
                  searchState.type,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Users',
                  SearchEntityType.users,
                  searchState.type,
                ),
              ],
            ),
          ),

          // Results
          Expanded(child: _buildResults(searchState)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    SearchEntityType? type,
    SearchEntityType? currentType,
  ) {
    final isSelected = type == currentType;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(searchProvider.notifier).setType(type);
      },
    );
  }

  Widget _buildResults(SearchState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    if (state.results == null || state.query.isEmpty) {
      return const Center(child: Text('Type to search'));
    }

    final results = state.results!;
    if (results.users.isEmpty &&
        results.videos.isEmpty &&
        results.posts.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    return ListView(
      children: [
        if (results.users.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...results.users.map((u) => _buildUserItem(u)),
        ],
        if (results.videos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Videos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...results.videos.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: VideoCard(video: v),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserItem(SearchUserDto user) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(
                user.displayName?[0].toUpperCase() ??
                    user.username?[0].toUpperCase() ??
                    '?',
              )
            : null,
      ),
      title: Text(user.displayName ?? user.username ?? 'User'),
      subtitle: user.username != null ? Text('@${user.username}') : null,
      onTap: () {
        if (user.username != null) {
          context.push('/profile/user/${user.username}');
        }
      },
    );
  }
}
