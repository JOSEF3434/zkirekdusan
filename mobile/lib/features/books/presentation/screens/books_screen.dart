// lib/features/books/presentation/screens/books_screen.dart
// Main library screen: category tabs, search, filter, grid/list, download filter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import '../../data/models/book_category_model.dart';
import '../../data/models/book_model.dart';
import '../providers/books_providers.dart';
import '../widgets/book_card.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen>
    with TickerProviderStateMixin {
  late TabController _downloadTabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearch = false;

  // Download filter tabs: All / Downloaded / Not Downloaded
  static const _dlTabs = ['all', 'downloaded', 'notDownloaded'];
  int _dlTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _downloadTabController = TabController(length: 3, vsync: this);
    _downloadTabController.addListener(() {
      if (!_downloadTabController.indexIsChanging) {
        setState(() => _dlTabIndex = _downloadTabController.index);
        ref.read(libraryProvider.notifier).applyFilter(
              ref.read(libraryProvider).filter.copyWith(
                    downloadFilter: _dlTabs[_downloadTabController.index],
                  ),
            );
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(libraryProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _downloadTabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cats = ref.watch(bookCategoriesProvider);
    final libraryState = ref.watch(libraryProvider);
    final prefs = ref.watch(readingPrefsProvider);
    final auth = ref.watch(authProvider);
    final isAuth = auth.status == AuthStatus.authenticated;
    final userId = auth.user?.id;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(context, theme, prefs, libraryState),
          _buildDownloadTabBar(theme),
        ],
        body: RefreshIndicator(
          onRefresh: () async => ref.read(libraryProvider.notifier).refresh(),
          child: _buildBody(context, theme, libraryState, cats, prefs, isAuth, userId),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ReadingPrefsState prefs,
    LibraryState libraryState,
  ) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      snap: false,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
        title: _showSearch
            ? _SearchBar(
                controller: _searchController,
                onChanged: (q) => ref.read(libraryProvider.notifier).search(q),
                onClose: () {
                  setState(() => _showSearch = false);
                  _searchController.clear();
                  ref.read(libraryProvider.notifier).search('');
                },
              )
            : RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'ዝክረ ',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        fontSize: 22,
                      ),
                    ),
                    TextSpan(
                      text: 'Library',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: theme.colorScheme.onSurface,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.surface,
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!_showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _showSearch = true),
            tooltip: 'Search books',
          ),
        IconButton(
          icon: Icon(prefs.gridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
          onPressed: () {
            ref.read(readingPrefsProvider.notifier).update(
                  prefs.copyWith(gridView: !prefs.gridView),
                );
          },
          tooltip: prefs.gridView ? 'List view' : 'Grid view',
        ),
        _FilterMenuButton(libraryState: libraryState),
        const SizedBox(width: 4),
      ],
    );
  }

  SliverPersistentHeader _buildDownloadTabBar(ThemeData theme) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _downloadTabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(text: 'All'),
            Tab(icon: Icon(Icons.offline_pin, size: 14), text: 'Downloaded'),
            Tab(text: 'Online Only'),
          ],
        ),
        color: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    LibraryState libraryState,
    AsyncValue<List<BookCategoryModel>> cats,
    ReadingPrefsState prefs,
    bool isAuth,
    String? userId,
  ) {
    // Get download records for filtering
    final downloadsAsync = ref.watch(downloadedBooksStreamProvider);
    final downloadedIds = downloadsAsync.valueOrNull
            ?.map((d) => d.bookId)
            .toSet() ??
        <String>{};

    List<BookModel> filteredBooks = libraryState.books;

    // Apply download filter client-side (data already fetched)
    if (_dlTabIndex == 1) {
      filteredBooks = filteredBooks
          .where((b) => downloadedIds.contains(b.id))
          .toList();
    } else if (_dlTabIndex == 2) {
      filteredBooks = filteredBooks
          .where((b) => !downloadedIds.contains(b.id))
          .toList();
    }

    if (libraryState.isLoading && libraryState.books.isEmpty) {
      return _LoadingGrid(isGrid: prefs.gridView);
    }

    if (libraryState.error != null && libraryState.books.isEmpty) {
      return _ErrorState(
        message: libraryState.error!,
        onRetry: () => ref.read(libraryProvider.notifier).refresh(),
      );
    }

    // Downloads-only tab with empty state
    if (_dlTabIndex == 1 && filteredBooks.isEmpty) {
      return _DownloadsEmptyState(
        onBrowse: () {
          _downloadTabController.animateTo(0);
        },
      );
    }

    if (filteredBooks.isEmpty && !libraryState.isLoading) {
      return _EmptyState(
        hasFilters: libraryState.filter.search != null ||
            libraryState.filter.categoryId != null,
        onClear: () {
          ref.read(libraryProvider.notifier).applyFilter(
                const LibraryFilter(),
              );
          _searchController.clear();
        },
      );
    }

    return Column(
      children: [
        // Category chip row (only on 'All' tab)
        if (_dlTabIndex == 0)
          cats.when(
            data: (categories) => _CategoryChips(
              categories: categories,
              selectedId: libraryState.filter.categoryId,
              onSelect: (id) {
                final current = libraryState.filter;
                ref.read(libraryProvider.notifier).applyFilter(
                      current.categoryId == id
                          ? current.copyWith(clearCategory: true)
                          : current.copyWith(categoryId: id),
                    );
              },
            ),
            loading: () => const SizedBox(height: 48),
            error: (_, _) => const SizedBox.shrink(),
          ),

        // Book grid / list
        Expanded(
          child: prefs.gridView
              ? _BookGrid(
                  books: filteredBooks,
                  hasMore: libraryState.hasMore && _dlTabIndex == 0,
                  isLoadingMore: libraryState.isLoadingMore,
                  scrollController: _scrollController,
                  isAuth: isAuth,
                  userId: userId,
                )
              : _BookList(
                  books: filteredBooks,
                  hasMore: libraryState.hasMore && _dlTabIndex == 0,
                  isLoadingMore: libraryState.isLoadingMore,
                  scrollController: _scrollController,
                  isAuth: isAuth,
                  userId: userId,
                ),
        ),
      ],
    );
  }
}

// ─────────────────── Sub-widgets ────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search books, authors...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onClose,
          ),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _FilterMenuButton extends ConsumerWidget {
  final LibraryState libraryState;
  const _FilterMenuButton({required this.libraryState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFilters =
        libraryState.filter.format != null || libraryState.filter.language != null;
    return IconButton(
      icon: Badge(
        isLabelVisible: hasFilters,
        child: const Icon(Icons.filter_list),
      ),
      onPressed: () => _showFilterSheet(context, ref, libraryState),
      tooltip: 'Filter',
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref, LibraryState s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(currentFilter: s.filter),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  final LibraryFilter currentFilter;
  const _FilterSheet({required this.currentFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final formats = [
      (null, 'All Formats'),
      ('PDF', 'PDF'),
      ('TEXT', 'Text'),
      ('AUDIO', 'Audio'),
    ];

    final languages = [
      (null, 'All Languages'),
      ('AMHARIC', 'Amharic'),
      ('GEEZ', 'Geez'),
      ('ENGLISH', 'English'),
    ];

    final sorts = [
      ('sortOrder', 'Default'),
      ('title', 'Title'),
      ('author', 'Author'),
      ('createdAt', 'Newest'),
      ('publishedYear', 'Year'),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, sc) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter & Sort',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () {
                    ref.read(libraryProvider.notifier).applyFilter(
                          const LibraryFilter(),
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _Section(title: 'Format', children: [
                  Wrap(
                    spacing: 8,
                    children: formats.map((f) {
                      final isSelected = currentFilter.format == f.$1;
                      return FilterChip(
                        label: Text(f.$2),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(libraryProvider.notifier).applyFilter(
                                currentFilter.copyWith(format: f.$1),
                              );
                        },
                      );
                    }).toList(),
                  ),
                ]),
                const SizedBox(height: 16),
                _Section(title: 'Language', children: [
                  Wrap(
                    spacing: 8,
                    children: languages.map((l) {
                      final isSelected = currentFilter.language == l.$1;
                      return FilterChip(
                        label: Text(l.$2),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(libraryProvider.notifier).applyFilter(
                                currentFilter.copyWith(language: l.$1),
                              );
                        },
                      );
                    }).toList(),
                  ),
                ]),
                const SizedBox(height: 16),
                _Section(title: 'Sort By', children: [
                  Wrap(
                    spacing: 8,
                    children: sorts.map((s) {
                      final isSelected = currentFilter.sortBy == s.$1;
                      return ChoiceChip(
                        label: Text(s.$2),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(libraryProvider.notifier).applyFilter(
                                currentFilter.copyWith(sortBy: s.$1),
                              );
                        },
                      );
                    }).toList(),
                  ),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<BookCategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = selectedId == cat.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat.name),
              selected: isSelected,
              onSelected: (_) => onSelect(cat.id),
              avatar: cat.booksCount > 0
                  ? CircleAvatar(
                      radius: 8,
                      child: Text(
                        cat.booksCount > 99 ? '99+' : '${cat.booksCount}',
                        style: const TextStyle(fontSize: 8),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _BookGrid extends ConsumerWidget {
  final List<BookModel> books;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final bool isAuth;
  final String? userId;

  const _BookGrid({
    required this.books,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
    required this.isAuth,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.60,
      ),
      itemCount: books.length + (hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == books.length) {
          return isLoadingMore
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink();
        }
        final book = books[i];
        return BookCard(
          book: book,
          onTap: () => context.push('/books/${book.id}'),
          onDownload: isAuth && book.isReadable
              ? () => _triggerDownload(ref, book, userId)
              : null,
        );
      },
    );
  }

  void _triggerDownload(WidgetRef ref, BookModel book, String? userId) {
    if (userId == null) return;
    ref.read(downloadsNotifierProvider.notifier).startDownload(book, userId);
  }
}

class _BookList extends ConsumerWidget {
  final List<BookModel> books;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final bool isAuth;
  final String? userId;

  const _BookList({
    required this.books,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
    required this.isAuth,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: books.length + (hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == books.length) {
          return isLoadingMore
              ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              : const SizedBox.shrink();
        }
        final book = books[i];
        return _BookListTile(
          book: book,
          isAuth: isAuth,
          userId: userId,
          onTap: () => context.push('/books/${book.id}'),
          onDownload: isAuth && book.isReadable
              ? () {
                  if (userId != null) {
                    ref
                        .read(downloadsNotifierProvider.notifier)
                        .startDownload(book, userId!);
                  }
                }
              : null,
        );
      },
    );
  }
}

class _BookListTile extends ConsumerWidget {
  final BookModel book;
  final VoidCallback onTap;
  final VoidCallback? onDownload;
  final bool isAuth;
  final String? userId;

  const _BookListTile({
    required this.book,
    required this.onTap,
    this.onDownload,
    required this.isAuth,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDownloadedAsync = ref.watch(isBookDownloadedProvider(book.id));
    final isDownloaded = isDownloadedAsync.valueOrNull ?? false;
    final downloadState = ref.watch(downloadsNotifierProvider);
    final isActive = downloadState.activeProgress.containsKey(book.id);
    final progress = downloadState.activeProgress[book.id] ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mini cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 72,
                child: book.coverUrl != null
                    ? Image.network(book.coverUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _MiniPlaceholder(book: book))
                    : _MiniPlaceholder(book: book),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.author != null && book.author!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        book.author!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Chip(book.format.name.toUpperCase(), theme),
                      const SizedBox(width: 6),
                      if (book.pageCount != null)
                        _Chip('${book.pageCount} pp', theme),
                      if (isDownloaded)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.offline_pin,
                              size: 14, color: Colors.green),
                        ),
                    ],
                  ),
                  if (book.myProgress != null &&
                      book.myProgress!.percentComplete > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: LinearProgressIndicator(
                        value: book.myProgress!.percentComplete / 100,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.primary),
                        minHeight: 2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.orange.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.orange),
                        minHeight: 2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            // Action
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (!isDownloaded && onDownload != null)
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 20),
                onPressed: onDownload,
                visualDensity: VisualDensity.compact,
              )
            else
              const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MiniPlaceholder extends StatelessWidget {
  final BookModel book;
  const _MiniPlaceholder({required this.book});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          book.format == BookFormat.audio ? Icons.headphones : Icons.menu_book,
          color: theme.colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _Chip(this.label, this.theme);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          )),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  final bool isGrid;
  const _LoadingGrid({required this.isGrid});
  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.60,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => _ShimmerCard(),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      itemBuilder: (_, _) => _ShimmerListItem(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ShimmerListItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Could not load library',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;
  const _EmptyState({required this.hasFilters, required this.onClear});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(hasFilters ? 'No books match your filters' : 'No books yet',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onClear, child: const Text('Clear filters')),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadsEmptyState extends StatelessWidget {
  final VoidCallback onBrowse;
  const _DownloadsEmptyState({required this.onBrowse});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_outlined, size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No downloaded books',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Download books to read them offline, even without internet access.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.library_books),
              label: const Text('Browse Library'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  const _TabBarDelegate(this.tabBar, {required this.color});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: color, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar || color != oldDelegate.color;
}
