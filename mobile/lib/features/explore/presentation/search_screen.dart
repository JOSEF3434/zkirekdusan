// lib/features/explore/presentation/search_screen.dart
// Production-quality search screen with: debounce, pagination, recent searches,
// grouped results, filter chips, loading skeletons, empty/error states, responsive layout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:mobile/features/explore/presentation/providers/search_provider.dart';
import 'package:mobile/features/explore/presentation/widgets/search_result_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= maxScroll - 300) {
      ref.read(searchProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);
    final recentSearchesAsync = ref.watch(recentSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search videos, people, groups…',
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Clear',
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchProvider.notifier).clear();
                        setState(() => _showResults = false);
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              setState(() => _showResults = val.trim().isNotEmpty);
              ref.read(searchProvider.notifier).setQuery(val);
            },
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                setState(() => _showResults = true);
                ref.read(searchProvider.notifier).setQuery(val);
              }
            },
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.isDesktop(context)
                ? 800
                : double.infinity,
          ),
          child: Column(
            children: [
              // Filter Chips
              if (_showResults || searchState.query.isNotEmpty)
                _FilterChips(searchState: searchState),

              // Main Content
              Expanded(
                child: _showResults
                    ? _buildResultsBody(searchState)
                    : _buildRecentSearches(recentSearchesAsync),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches(AsyncValue<List<String>> recentAsync) {
    return recentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (searches) {
        if (searches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 72,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                Text(
                  'Search for videos, people, and more',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent searches',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(recentSearchesProvider.notifier).clear(),
                    child: Consumer(builder: (_, ref, _) => Text(ref.watch(trProvider)('search.clear'))),
                  ),
                ],
              ),
            ),
            ...searches.map(
              (q) => ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(q),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () =>
                      ref.read(recentSearchesProvider.notifier).remove(q),
                ),
                onTap: () {
                  _searchController.text = q;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: q.length),
                  );
                  setState(() => _showResults = true);
                  ref.read(searchProvider.notifier).setQuery(q);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultsBody(SearchState state) {
    if (state.isLoading) return const SearchSkeleton();
    if (state.error != null) {
      return SearchErrorState(
        error: state.error!,
        onRetry: () => ref.read(searchProvider.notifier).retry(),
      );
    }
    if (state.results == null || state.results!.isEmpty) {
      return SearchEmptyState(
        query: state.query,
        onRetry: () => ref.read(searchProvider.notifier).retry(),
      );
    }

    final results = state.results!;
    return ListView.builder(
      controller: _scrollController,
      itemCount:
          _countItems(results) +
          (state.isLoadingMore ? 1 : 0) +
          (!state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        final items = _buildResultItems(results);
        if (index < items.length) return items[index];
        if (state.isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No more results',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      },
    );
  }

  int _countItems(SearchResultsDto results) {
    int count = 0;
    if (results.users.isNotEmpty) count += results.users.length + 1; // +1 header
    if (results.videos.isNotEmpty) count += results.videos.length + 1;
    if (results.groups.isNotEmpty) count += results.groups.length + 1;
    if (results.channels.isNotEmpty) count += results.channels.length + 1;
    if (results.streams.isNotEmpty) count += results.streams.length + 1;
    if (results.reels.isNotEmpty) count += results.reels.length + 1;
    return count;
  }

  List<Widget> _buildResultItems(SearchResultsDto results) {
    final widgets = <Widget>[];

    if (results.users.isNotEmpty) {
      widgets.add(const SearchSectionHeader(title: 'People'));
      for (final u in results.users) {
        widgets.add(SearchUserTile(user: u));
      }
    }

    if (results.videos.isNotEmpty) {
      widgets.add(const SearchSectionHeader(title: 'Videos'));
      for (final v in results.videos) {
        widgets.add(SearchVideoResultCard(video: v));
      }
    }

    if (results.groups.isNotEmpty) {
      widgets.add(const SearchSectionHeader(title: 'Groups'));
      for (final g in results.groups) {
        widgets.add(SearchGroupTile(group: g));
      }
    }

    if (results.channels.isNotEmpty) {
      widgets.add(const SearchSectionHeader(title: 'Channels'));
      for (final c in results.channels) {
        widgets.add(SearchChannelTile(channel: c));
      }
    }

    if (results.streams.isNotEmpty) {
      widgets.add(const SearchSectionHeader(title: 'Live Streams'));
      for (final s in results.streams) {
        widgets.add(SearchStreamTile(stream: s));
      }
    }

    if (results.reels.isNotEmpty) {
      widgets.add(const SearchSectionHeader(title: 'Reels'));
      for (final r in results.reels) {
        widgets.add(SearchReelTile(reel: r));
      }
    }

    return widgets;
  }
}

// ── Filter Chips ──────────────────────────────────────────────────────────────

class _FilterChips extends ConsumerWidget {
  final SearchState searchState;
  const _FilterChips({required this.searchState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = [
      (null, 'All'),
      (SearchEntityType.videos, 'Videos'),
      (SearchEntityType.users, 'People'),
      (SearchEntityType.groups, 'Groups'),
      (SearchEntityType.channels, 'Channels'),
      (SearchEntityType.reels, 'Reels'),
      (SearchEntityType.streams, 'Live'),
    ];

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: chips.map((chip) {
          final isSelected = searchState.type == chip.$1;
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final textColor = isSelected
              ? (isDark ? Colors.black87 : Colors.white)
              : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                chip.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: isDark ? const Color(0xFF242424) : Colors.grey.shade200,
              selectedColor: theme.colorScheme.primary,
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1)),
              ),
              onSelected: (_) =>
                  ref.read(searchProvider.notifier).setType(chip.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

