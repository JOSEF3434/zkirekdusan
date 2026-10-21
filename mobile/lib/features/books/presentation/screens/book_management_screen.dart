// lib/features/books/presentation/screens/book_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/book_model.dart';
import '../providers/book_admin_providers.dart';
import '../providers/book_download_settings_provider.dart';
import '../providers/book_permissions_provider.dart';
import '../providers/books_providers.dart';
import '../widgets/book_download_settings_dialog.dart';

class BookManagementScreen extends ConsumerStatefulWidget {
  const BookManagementScreen({super.key});

  @override
  ConsumerState<BookManagementScreen> createState() =>
      _BookManagementScreenState();
}

class _BookManagementScreenState extends ConsumerState<BookManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _statusTabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _statusTabs = ['ALL', 'PUBLISHED', 'DRAFT', 'ARCHIVED'];

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: _statusTabs.length, vsync: this);
    _statusTabController.addListener(() {
      if (!_statusTabController.indexIsChanging) {
        final status = _statusTabs[_statusTabController.index];
        final currentFilter = ref.read(bookAdminListProvider).filter;
        ref.read(bookAdminListProvider.notifier).applyFilter(
              currentFilter.copyWith(status: status == 'ALL' ? null : status),
            );
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(bookAdminListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Status Action Handlers ──────────────────────────────────────────────

  Future<void> _togglePublish(BookModel book) async {
    final isPublished = book.status == BookStatus.published;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPublished ? 'Unpublish Book' : 'Publish Book'),
        content: Text(
          isPublished
              ? 'Are you sure you want to unpublish "${book.title}"? It will become a draft and hidden from readers.'
              : 'Are you sure you want to publish "${book.title}"? It will become visible in the public library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isPublished ? 'Unpublish' : 'Publish'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(booksRepositoryProvider);
      if (isPublished) {
        await repo.unpublishBook(book.id);
      } else {
        await repo.publishBook(book.id);
      }
      ref.read(bookAdminListProvider.notifier).refresh();
      ref.read(libraryProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPublished
                  ? 'Book moved to draft'
                  : 'Book published successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleArchive(BookModel book) async {
    final isArchived = book.status == BookStatus.archived;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArchived ? 'Restore Book' : 'Archive Book'),
        content: Text(
          isArchived
              ? 'Restore "${book.title}" from archive? It will be restored as a draft.'
              : 'Archive "${book.title}"? It will be hidden from the library but preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isArchived ? 'Restore' : 'Archive'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(booksRepositoryProvider);
      if (isArchived) {
        await repo.restoreBook(book.id);
      } else {
        await repo.archiveBook(book.id);
      }
      ref.read(bookAdminListProvider.notifier).refresh();
      ref.read(libraryProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArchived ? 'Book restored to drafts' : 'Book archived',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteBook(BookModel book, {bool permanent = false}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(permanent ? 'Permanently Delete Book' : 'Delete Book'),
        content: Text(
          permanent
              ? 'WARNING: This will permanently erase "${book.title}", including chapters and bookmarks. This action cannot be undone!'
              : 'Are you sure you want to delete "${book.title}"? It will be moved to deleted items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(permanent ? 'Permanently Delete' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(booksRepositoryProvider);
      await repo.deleteBook(book.id, permanent: permanent);
      ref.read(bookAdminListProvider.notifier).refresh();
      ref.read(libraryProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              permanent ? 'Book permanently deleted' : 'Book deleted',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perms = ref.watch(bookPermissionsProvider);
    final adminState = ref.watch(bookAdminListProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Book Management',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Book Download Settings',
            onPressed: () => showBookDownloadSettingsDialog(context),
          ),
          if (perms.canManageCategories)
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Manage Categories',
              onPressed: () => context.push('/books/categories'),
            ),
          if (perms.canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add Book',
                onPressed: () => context.push('/books/create'),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search books by title, author, tag...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(bookAdminListProvider.notifier).applyFilter(
                                      adminState.filter.copyWith(clearSearch: true),
                                    );
                              },
                            )
                          : null,
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (q) {
                      ref.read(bookAdminListProvider.notifier).applyFilter(
                            adminState.filter.copyWith(search: q),
                          );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Status tabs
              TabBar(
                controller: _statusTabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5),
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Published'),
                  Tab(text: 'Drafts'),
                  Tab(text: 'Archived'),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: perms.canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/books/create'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Book'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(bookAdminListProvider.notifier).refresh(),
        child: _buildBody(theme, adminState, perms),
      ),
    );
  }

  Widget _buildDownloadSettingsCard(ThemeData theme) {
    final settingsState = ref.watch(bookDownloadSettingsProvider);
    final destination = settingsState.setting.destination;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(isDark ? 35 : 18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(isDark ? 80 : 40),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_special_rounded,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Download Destination: ',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: destination.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  switch (destination) {
                    BookDownloadDestination.inApp =>
                      'In-app offline storage only',
                    BookDownloadDestination.deviceFileManager =>
                      'Device Downloads / File Manager',
                    BookDownloadDestination.both =>
                      'In-app + Device Downloads folder',
                  },
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.settings_outlined, size: 16),
            label: const Text('Configure', style: TextStyle(fontSize: 12)),
            onPressed: () => showBookDownloadSettingsDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    BookAdminState state,
    BookPermissions perms,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(bookAdminListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.books.isEmpty) {
      return Column(
        children: [
          _buildDownloadSettingsCard(theme),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No books found',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or add a new book.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildDownloadSettingsCard(theme),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: state.books.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.books.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final book = state.books[index];
              return _buildBookAdminTile(theme, book, perms);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookAdminTile(
    ThemeData theme,
    BookModel book,
    BookPermissions perms,
  ) {
    final statusColor = _statusColor(theme, book.status);
    final statusLabel = _statusLabel(book.status);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 72,
                child: book.coverUrl != null
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.book, size: 24),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.book, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Book Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Format badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatLabel(book.format),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Spacer(),
                      // Last updated
                      Flexible(
                        child: Text(
                          dateFormat.format(book.updatedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    book.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Author & Category
                  const SizedBox(height: 2),
                  Text(
                    '${book.author ?? "Unknown"} • ${book.categoryName ?? "General"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Actions dropdown menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: 'Options',
              onSelected: (action) {
                switch (action) {
                  case 'view':
                    context.push('/books/${book.id}');
                    break;
                  case 'edit':
                    context.push('/books/${book.id}/edit', extra: book);
                    break;
                  case 'publish':
                    _togglePublish(book);
                    break;
                  case 'archive':
                    _toggleArchive(book);
                    break;
                  case 'delete':
                    _deleteBook(book, permanent: false);
                    break;
                  case 'perm_delete':
                    _deleteBook(book, permanent: true);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('View Reader'),
                    ],
                  ),
                ),
                if (perms.canUpdate)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Book'),
                      ],
                    ),
                  ),
                if (perms.canPublish)
                  PopupMenuItem(
                    value: 'publish',
                    child: Row(
                      children: [
                        Icon(
                          book.status == BookStatus.published
                              ? Icons.unpublished_outlined
                              : Icons.publish_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          book.status == BookStatus.published
                              ? 'Unpublish'
                              : 'Publish',
                        ),
                      ],
                    ),
                  ),
                if (perms.canUpdate)
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(
                          book.status == BookStatus.archived
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          book.status == BookStatus.archived
                              ? 'Restore'
                              : 'Archive',
                        ),
                      ],
                    ),
                  ),
                if (perms.canDelete) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Delete',
                            style:
                                TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                  if (perms.isSuperAdmin)
                    PopupMenuItem(
                      value: 'perm_delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever,
                              size: 18, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Text('Delete Permanently',
                              style:
                                  TextStyle(color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ThemeData theme, BookStatus status) {
    switch (status) {
      case BookStatus.published:
        return Colors.green;
      case BookStatus.draft:
        return Colors.orange;
      case BookStatus.archived:
        return Colors.blueGrey;
      case BookStatus.deleted:
        return theme.colorScheme.error;
    }
  }

  String _statusLabel(BookStatus status) {
    switch (status) {
      case BookStatus.published:
        return 'PUBLISHED';
      case BookStatus.draft:
        return 'DRAFT';
      case BookStatus.archived:
        return 'ARCHIVED';
      case BookStatus.deleted:
        return 'DELETED';
    }
  }

  String _formatLabel(BookFormat format) {
    switch (format) {
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.epub:
        return 'EPUB';
      case BookFormat.text:
        return 'TEXT';
      case BookFormat.audio:
        return 'AUDIO';
      case BookFormat.externalLink:
        return 'LINK';
    }
  }
}
