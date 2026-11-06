// lib/features/books/presentation/screens/books_screen.dart
// Main library screen: category tabs, search, filter, grid/list, download filter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import '../../data/models/book_category_model.dart';
import '../../data/models/book_model.dart';
import '../providers/books_providers.dart';
import '../providers/book_permissions_provider.dart';
import '../widgets/book_card.dart';
import '../../../../core/presentation/widgets/app_network_image.dart';
import '../../../../core/utils/media_url_resolver.dart';


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
    final bookPerms = ref.watch(bookPermissionsProvider);
    final isAuth = auth.status == AuthStatus.authenticated;
    final userId = auth.user?.id;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(context, theme, prefs, libraryState, bookPerms),
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
    BookPermissions bookPerms,
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
                      text: 'ዝክረ ክዱሳን  ',
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
        if (!_showSearch) ...[
          if (bookPerms.canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Semantics(
                button: true,
                label: 'Add Book',
                child: Tooltip(
                  message: 'Add Book',
                  child: Material(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => context.push('/books/create'),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _showSearch = true),
            tooltip: 'Search books',
          ),
        ],
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
        if (bookPerms.hasAnyManagementAccess || bookPerms.isAuthenticated)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Book Management',
            onSelected: (val) {
              if (val == 'manage') {
                context.push('/books/manage');
              } else if (val == 'categories') {
                context.push('/books/categories');
              } else if (val == 'languages') {
                context.push('/books/languages');
              } else if (val == 'create') {
                context.push('/books/create');
              } else if (val == 'history') {
                context.push('/books/history');
              }
            },
            itemBuilder: (ctx) => [
              if (bookPerms.canManageLibrary)
                const PopupMenuItem(
                  value: 'manage',
                  child: Row(
                    children: [
                      Icon(Icons.dashboard_customize_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Manage Books'),
                    ],
                  ),
                ),
              if (bookPerms.canManageCategories)
                const PopupMenuItem(
                  value: 'categories',
                  child: Row(
                    children: [
                      Icon(Icons.category_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Manage Categories'),
                    ],
                  ),
                ),
              if (bookPerms.canManageLanguages)
                const PopupMenuItem(
                  value: 'languages',
                  child: Row(
                    children: [
                      Icon(Icons.language_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Manage Languages'),
                    ],
                  ),
                ),
              if (bookPerms.canCreate)
                const PopupMenuItem(
                  value: 'create',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 20),
                      SizedBox(width: 10),
                      Text('Add Book'),
                    ],
                  ),
                ),
              if (bookPerms.isAuthenticated)
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history_edu_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Translation History'),
                    ],
                  ),
                ),
            ],
          ),
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
            Tab(icon: Icon(Icons.auto_stories_outlined, size: 14), text: 'All'),
            Tab(
              icon: Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
              text: 'Downloaded',
            ),
            Tab(
              icon: Icon(Icons.cloud_outlined, size: 14, color: Color(0xFF0284C7)),
              text: 'Online Only',
            ),
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
    final downloadedRecords =
        downloadsAsync.valueOrNull ?? <LocalDownloadedBookData>[];
    final downloadedIds = downloadedRecords.map((d) => d.bookId).toSet();
    final connectivity = ref.watch(connectivityProvider);
    final isOffline = connectivity.isOffline;

    final downloadedBooksList = downloadedRecords.map((d) {
      return BookModel(
        id: d.bookId,
        title: d.title,
        titleAm: d.titleAm,
        author: d.author,
        categoryName: d.categoryName,
        language: BookLanguage.amharic,
        format: BookFormat.values.firstWhere(
          (f) => f.name.toUpperCase() == d.format.toUpperCase(),
          orElse: () => BookFormat.pdf,
        ),
        status: BookStatus.published,
        pageCount: d.pageCount,
        tags: const [],
        sortOrder: 0,
        viewsCount: 0,
        bookmarksCount: 0,
        coverUrl: (d.localCoverPath != null && d.localCoverPath!.isNotEmpty)
            ? d.localCoverPath
            : d.coverUrl,
        contentUrl: d.localContentPath,
        chapters: const [],
        attachments: const [],
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
      );
    }).toList();

    List<BookModel> filteredBooks;

    if (_dlTabIndex == 1) {
      // Downloaded tab: show all downloaded books (match existing or map from local record)
      final existingBooksById = {for (final b in libraryState.books) b.id: b};
      filteredBooks = downloadedRecords.map((d) {
        final existing = existingBooksById[d.bookId];
        final localCover = (d.localCoverPath != null && d.localCoverPath!.trim().isNotEmpty)
            ? d.localCoverPath
            : null;
        final effectiveCover = localCover ??
            (existing?.coverUrl != null && existing!.coverUrl!.trim().isNotEmpty
                ? existing.coverUrl
                : d.coverUrl);

        if (existing != null) {
          return existing.copyWith(
            coverUrl: effectiveCover,
            contentUrl: d.localContentPath ?? existing.contentUrl,
          );
        }
        return BookModel(
          id: d.bookId,
          title: d.title,
          titleAm: d.titleAm,
          author: d.author,
          categoryName: d.categoryName,
          language: BookLanguage.amharic,
          format: BookFormat.values.firstWhere(
            (f) => f.name.toUpperCase() == d.format.toUpperCase(),
            orElse: () => BookFormat.pdf,
          ),
          status: BookStatus.published,
          pageCount: d.pageCount,
          tags: const [],
          sortOrder: 0,
          viewsCount: 0,
          bookmarksCount: 0,
          coverUrl: effectiveCover,
          contentUrl: d.localContentPath,
          chapters: const [],
          attachments: const [],
          createdAt: d.createdAt,
          updatedAt: d.updatedAt,
        );
      }).toList();

      final search = libraryState.filter.search?.trim().toLowerCase();
      if (search != null && search.isNotEmpty) {
        filteredBooks = filteredBooks.where((b) {
          final t = b.title.toLowerCase();
          final ta = b.titleAm?.toLowerCase() ?? '';
          final a = b.author?.toLowerCase() ?? '';
          return t.contains(search) || ta.contains(search) || a.contains(search);
        }).toList();
      }
    } else if (_dlTabIndex == 2) {
      // Online only tab
      filteredBooks = libraryState.books
          .where((b) => !downloadedIds.contains(b.id))
          .toList();
    } else {
      // All tab
      if (isOffline && libraryState.books.isEmpty && downloadedBooksList.isNotEmpty) {
        filteredBooks = downloadedBooksList;
      } else {
        filteredBooks = libraryState.books;
      }
    }

    if (libraryState.isLoading && libraryState.books.isEmpty && _dlTabIndex == 0 && !isOffline) {
      return _LoadingGrid(isGrid: prefs.gridView);
    }

    // 1. All tab when offline or network error and no books loaded
    if (_dlTabIndex == 0 && (isOffline || libraryState.error != null) && libraryState.books.isEmpty) {
      if (downloadedRecords.isEmpty) {
        return _OfflineLibraryState(
          downloadedCount: 0,
          onGoToDownloads: () => _downloadTabController.animateTo(1),
          onRetry: () => ref.read(libraryProvider.notifier).refresh(),
        );
      }
    }

    // 2. Downloaded tab with empty state
    if (_dlTabIndex == 1 && filteredBooks.isEmpty) {
      return _DownloadsEmptyState(
        isOffline: isOffline,
        onBrowse: () => _downloadTabController.animateTo(0),
        onRetry: () => ref.read(libraryProvider.notifier).refresh(),
      );
    }

    // 3. Online only tab
    if (_dlTabIndex == 2) {
      if (isOffline || libraryState.error != null) {
        if (filteredBooks.isEmpty) {
          return _OnlineOnlyOfflineState(
            downloadedCount: downloadedRecords.length,
            onGoToDownloads: () => _downloadTabController.animateTo(1),
            onRetry: () => ref.read(libraryProvider.notifier).refresh(),
          );
        }
      } else if (filteredBooks.isEmpty && !libraryState.isLoading) {
        final allDownloaded = libraryState.books.isNotEmpty &&
            libraryState.books.every((b) => downloadedIds.contains(b.id));
        if (allDownloaded) {
          return _AllBooksDownloadedState(
            downloadedCount: downloadedRecords.length,
            onGoToDownloads: () => _downloadTabController.animateTo(1),
            onBrowseAll: () => _downloadTabController.animateTo(0),
          );
        }
        return _NoOnlineBooksState(
          hasFilters: libraryState.filter.search != null ||
              libraryState.filter.categoryId != null,
          downloadedCount: downloadedRecords.length,
          onClearFilters: () {
            ref.read(libraryProvider.notifier).applyFilter(const LibraryFilter());
            _searchController.clear();
          },
          onGoToDownloads: () => _downloadTabController.animateTo(1),
          onBrowseAll: () => _downloadTabController.animateTo(0),
        );
      }
    }

    if (libraryState.error != null && libraryState.books.isEmpty && _dlTabIndex == 0) {
      return _ErrorState(
        message: libraryState.error!,
        onRetry: () => ref.read(libraryProvider.notifier).refresh(),
        onGoToDownloads: () => _downloadTabController.animateTo(1),
        downloadedCount: downloadedRecords.length,
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
        // Offline banner on 'All' tab when offline with downloaded books
        if (_dlTabIndex == 0 && (isOffline || libraryState.error != null) && downloadedRecords.isNotEmpty)
          _OfflineBanner(
            count: downloadedRecords.length,
            onGoToDownloads: () => _downloadTabController.animateTo(1),
          ),

        // Category chip row (only on 'All' tab when online)
        if (_dlTabIndex == 0 && !isOffline && libraryState.error == null)
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
                  hasMore: libraryState.hasMore && _dlTabIndex == 0 && !isOffline,
                  isLoadingMore: libraryState.isLoadingMore,
                  scrollController: _scrollController,
                  isAuth: isAuth,
                  userId: userId,
                  isDownloadedTab: _dlTabIndex == 1,
                )
              : _BookList(
                  books: filteredBooks,
                  hasMore: libraryState.hasMore && _dlTabIndex == 0 && !isOffline,
                  isLoadingMore: libraryState.isLoadingMore,
                  scrollController: _scrollController,
                  isAuth: isAuth,
                  userId: userId,
                  isDownloadedTab: _dlTabIndex == 1,
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

class _FilterSheet extends ConsumerStatefulWidget {
  final LibraryFilter currentFilter;
  const _FilterSheet({required this.currentFilter});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late LibraryFilter _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.currentFilter;
  }

  void _onFormatSelected(String? format) {
    final newFilter = _activeFilter.copyWith(
      format: format,
      clearFormat: format == null,
    );
    setState(() => _activeFilter = newFilter);
    ref.read(libraryProvider.notifier).applyFilter(newFilter);
  }

  void _onLanguageSelected(String? language) {
    final newFilter = _activeFilter.copyWith(
      language: language,
      clearLanguage: language == null,
    );
    setState(() => _activeFilter = newFilter);
    ref.read(libraryProvider.notifier).applyFilter(newFilter);
  }

  void _onSortSelected(String sortBy) {
    final newFilter = _activeFilter.copyWith(sortBy: sortBy);
    setState(() => _activeFilter = newFilter);
    ref.read(libraryProvider.notifier).applyFilter(newFilter);
  }

  void _onReset() {
    const defaultFilter = LibraryFilter();
    setState(() => _activeFilter = defaultFilter);
    ref.read(libraryProvider.notifier).applyFilter(defaultFilter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentFilter = _activeFilter;

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
                Text(
                  'Filter & Sort',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: _onReset,
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
                _Section(
                  title: 'Format',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: formats.map((f) {
                        final isSelected = currentFilter.format == f.$1;
                        return FilterChip(
                          label: Text(f.$2),
                          selected: isSelected,
                          showCheckmark: true,
                          checkmarkColor: Colors.white,
                          selectedColor: const Color(0xFF14B8A6),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (_) => _onFormatSelected(f.$1),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Language',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: languages.map((l) {
                        final isSelected = currentFilter.language == l.$1;
                        return FilterChip(
                          label: Text(l.$2),
                          selected: isSelected,
                          showCheckmark: true,
                          checkmarkColor: Colors.white,
                          selectedColor: const Color(0xFF14B8A6),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (_) => _onLanguageSelected(l.$1),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Sort By',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sorts.map((s) {
                        final isSelected = currentFilter.sortBy == s.$1;
                        return ChoiceChip(
                          label: Text(s.$2),
                          selected: isSelected,
                          showCheckmark: true,
                          checkmarkColor: Colors.white,
                          selectedColor: const Color(0xFF14B8A6),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (_) => _onSortSelected(s.$1),
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
  final bool isDownloadedTab;

  const _BookGrid({
    required this.books,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
    required this.isAuth,
    this.userId,
    this.isDownloadedTab = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        if (width >= 1200) {
          crossAxisCount = 6;
        } else if (width >= 960) {
          crossAxisCount = 5;
        } else if (width >= 720) {
          crossAxisCount = 4;
        } else if (width >= 480) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.70,
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
              isDownloadedTab: isDownloadedTab,
              onCoverTap: () {
                if (book.isReadable) {
                  context.push(
                    '/books/${book.id}/read',
                    extra: {'isDownloaded': isDownloadedTab},
                  );
                } else {
                  context.push('/books/${book.id}');
                }
              },
              onDetailTap: () => context.push('/books/${book.id}'),
              onDownload: isAuth && book.isReadable
                  ? () => _triggerDownload(ref, book, userId)
                  : null,
            );
          },
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
  final bool isDownloadedTab;

  const _BookList({
    required this.books,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
    required this.isAuth,
    this.userId,
    this.isDownloadedTab = false,
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
          isDownloadedTab: isDownloadedTab,
          onCoverTap: () {
            if (book.isReadable) {
              context.push(
                '/books/${book.id}/read',
                extra: {'isDownloaded': isDownloadedTab},
              );
            } else {
              context.push('/books/${book.id}');
            }
          },
          onDetailTap: () => context.push('/books/${book.id}'),
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
  final VoidCallback? onCoverTap;
  final VoidCallback? onDetailTap;
  final VoidCallback onTap;
  final VoidCallback? onDownload;
  final bool isAuth;
  final String? userId;
  final bool isDownloadedTab;

  const _BookListTile({
    required this.book,
    this.onCoverTap,
    this.onDetailTap,
    required this.onTap,
    this.onDownload,
    required this.isAuth,
    this.userId,
    this.isDownloadedTab = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final downloadState = ref.watch(downloadsNotifierProvider);
    final isDownloadedAsync = ref.watch(isBookDownloadedProvider(book.id));
    final isJustDownloaded = downloadState.lastResults[book.id]?.success == true;
    final isDownloaded = isDownloadedTab ||
        isJustDownloaded ||
        (isDownloadedAsync.valueOrNull ?? false);
    final isActive = downloadState.activeProgress.containsKey(book.id);
    final progress = downloadState.activeProgress[book.id] ?? 0.0;

    final coverAction = onCoverTap ?? onTap;
    final detailAction = onDetailTap ?? onTap;

    return Container(
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
          // Mini cover - Clicking opens the reader
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: coverAction,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 72,
                  child: () {
                    final resolvedCover = MediaUrlResolver.resolve(book.coverUrl);
                    return (resolvedCover != null && resolvedCover.isNotEmpty)
                        ? AppNetworkImage(
                            imageUrl: resolvedCover,
                            width: 56,
                            height: 72,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => _MiniPlaceholder(book: book),
                            errorWidget: (_, _, _) => _MiniPlaceholder(book: book),
                          )
                        : _MiniPlaceholder(book: book);
                  }(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info - Clicking opens book details
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: detailAction,
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
                      if (book.pageCount != null) ...[
                        _Chip('${book.pageCount} pp', theme),
                        const SizedBox(width: 6),
                      ],
                      if (isDownloaded)
                        InkWell(
                          onTap: () => _confirmRemoveDownload(context, ref, book),
                          borderRadius: BorderRadius.circular(6),
                          child: Tooltip(
                            message: 'Downloaded • Tap to delete from local storage',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF059669)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 11, color: Color(0xFF059669)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Downloaded',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF0284C7)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_outlined,
                                  size: 11, color: Color(0xFF0284C7)),
                              SizedBox(width: 3),
                              Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
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
            else if (isDownloaded)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
                tooltip: 'Delete downloaded book from local storage',
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmRemoveDownload(context, ref, book),
              )
            else if (onDownload != null)
              IconButton(
                icon: const Icon(
                  Icons.cloud_download_outlined,
                  color: Color(0xFF0284C7),
                  size: 22,
                ),
                tooltip: 'Download for offline reading',
                onPressed: onDownload,
                visualDensity: VisualDensity.compact,
              )
            else
              const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      );
  }

  void _confirmRemoveDownload(
    BuildContext context,
    WidgetRef ref,
    BookModel book,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Downloaded Book'),
        content: Text(
          'Do you want to delete "${book.title}" from local storage? This will remove the offline copy from your device and return the book to online mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final auth = ref.read(authProvider);
              final effectiveUserId = userId ?? auth.user?.id ?? 'guest';
              await ref
                  .read(downloadsNotifierProvider.notifier)
                  .removeDownload(book.id, effectiveUserId);
              ref.invalidate(isBookDownloadedProvider(book.id));
              ref.invalidate(downloadedBooksStreamProvider);
              ref.invalidate(allDownloadsStreamProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Deleted "${book.title}" from local storage. Switched back to online mode.',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete from Local Storage'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
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

class _OfflineBanner extends StatelessWidget {
  final int count;
  final VoidCallback onGoToDownloads;

  const _OfflineBanner({
    required this.count,
    required this.onGoToDownloads,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2518),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 20,
            color: Color(0xFFFFB300),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline Mode • Showing $count downloaded book${count > 1 ? "s" : ""}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFE082),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onGoToDownloads,
            icon: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFFFFE082)),
            label: const Text(
              'Downloads Tab',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFE082),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineLibraryState extends StatelessWidget {
  final int downloadedCount;
  final VoidCallback onGoToDownloads;
  final VoidCallback onRetry;

  const _OfflineLibraryState({
    required this.downloadedCount,
    required this.onGoToDownloads,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "You're in Offline Mode",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              downloadedCount > 0
                  ? 'Connect to the internet to browse the online catalog. You have $downloadedCount book${downloadedCount > 1 ? "s" : ""} downloaded and ready for offline reading.'
                  : 'An internet connection is required to browse online books. Downloaded books are accessible anytime without internet connection.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGoToDownloads,
              icon: const Icon(Icons.download_done_rounded),
              label: Text(
                downloadedCount > 0
                    ? 'Go to Downloaded Books ($downloadedCount)'
                    : 'Go to Downloaded Books',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineOnlyOfflineState extends StatelessWidget {
  final int downloadedCount;
  final VoidCallback onGoToDownloads;
  final VoidCallback onRetry;

  const _OnlineOnlyOfflineState({
    required this.downloadedCount,
    required this.onGoToDownloads,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Online Books Unavailable',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Online books require an active internet connection to browse and stream. Switch to your downloaded books to continue reading offline.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGoToDownloads,
              icon: const Icon(Icons.download_done_rounded),
              label: Text(
                downloadedCount > 0
                    ? 'Go to Downloaded Books ($downloadedCount)'
                    : 'Go to Downloaded Books',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllBooksDownloadedState extends StatelessWidget {
  final int downloadedCount;
  final VoidCallback onGoToDownloads;
  final VoidCallback onBrowseAll;

  const _AllBooksDownloadedState({
    required this.downloadedCount,
    required this.onGoToDownloads,
    required this.onBrowseAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 56,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All Books Downloaded',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ሁሉም መጽሐፍት ወርደዋል',
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF059669),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                'All available books have already been downloaded to your device for offline reading. You can read them from your Downloaded tab, or delete downloads to stream them online.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGoToDownloads,
              icon: const Icon(Icons.download_done_rounded),
              label: Text(
                downloadedCount > 0
                    ? 'Go to Downloaded Books ($downloadedCount)'
                    : 'Go to Downloaded Books',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onBrowseAll,
              icon: const Icon(Icons.library_books_rounded),
              label: const Text('Browse All Books'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoOnlineBooksState extends StatelessWidget {
  final bool hasFilters;
  final int downloadedCount;
  final VoidCallback onClearFilters;
  final VoidCallback onGoToDownloads;
  final VoidCallback onBrowseAll;

  const _NoOnlineBooksState({
    required this.hasFilters,
    required this.downloadedCount,
    required this.onClearFilters,
    required this.onGoToDownloads,
    required this.onBrowseAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_queue_rounded,
                size: 56,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No Matching Online Books' : 'No Online Books Available',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters ? 'ምንም የሚመሳሰል የመስመር ላይ መጽሐፍ የለም' : 'ምንም የመስመር ላይ መጽሐፍ የለም',
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF0284C7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                hasFilters
                    ? 'No online books match your selected search or category filters. Try clearing your filters or check your downloaded library.'
                    : 'There are currently no online-only books available in the catalog. You can explore your downloaded books or browse all library items.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (hasFilters) ...[
              FilledButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear Filters'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (downloadedCount > 0) ...[
              FilledButton.icon(
                onPressed: onGoToDownloads,
                icon: const Icon(Icons.download_done_rounded),
                label: Text('Go to Downloaded Books ($downloadedCount)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: onBrowseAll,
              icon: const Icon(Icons.library_books_rounded),
              label: const Text('Browse All Books'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onGoToDownloads;
  final int downloadedCount;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    this.onGoToDownloads,
    this.downloadedCount = 0,
  });

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
            if (onGoToDownloads != null) ...[
              FilledButton.icon(
                onPressed: onGoToDownloads,
                icon: const Icon(Icons.download_done_rounded),
                label: Text(
                  downloadedCount > 0
                      ? 'Go to Downloaded Books ($downloadedCount)'
                      : 'Go to Downloaded Books',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
              ),
            ] else
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
  final bool isOffline;
  final VoidCallback? onRetry;

  const _DownloadsEmptyState({
    required this.onBrowse,
    this.isOffline = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOffline ? Icons.cloud_off_rounded : Icons.download_outlined,
                size: 56,
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Downloaded Books',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isOffline
                  ? 'You are currently offline and do not have any downloaded books on this device yet. Connect to the internet to download books for offline reading.'
                  : 'Download books to read them offline, even without internet access.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (isOffline)
              FilledButton.icon(
                onPressed: onRetry ?? onBrowse,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
              )
            else
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
