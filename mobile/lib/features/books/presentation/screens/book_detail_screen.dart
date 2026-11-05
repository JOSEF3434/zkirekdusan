// lib/features/books/presentation/screens/book_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import '../../data/models/book_attachment_model.dart';
import '../../data/models/book_model.dart';
import '../providers/books_providers.dart';
import '../providers/book_permissions_provider.dart';

class BookDetailScreen extends ConsumerWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailProvider(bookId));
    final auth = ref.watch(authProvider);
    final isAuth = auth.status == AuthStatus.authenticated;
    final userId = auth.user?.id;

    return bookAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Book')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Book Unavailable Offline',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'This book is not downloaded on this device or could not be loaded without an active internet connection.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/books'),
                  icon: const Icon(Icons.download_done_rounded),
                  label: const Text('Go to Downloaded Books'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(bookDetailProvider(bookId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (book) => _BookDetailContent(
        book: book,
        isAuth: isAuth,
        userId: userId,
      ),
    );
  }
}

class _BookDetailContent extends ConsumerStatefulWidget {
  final BookModel book;
  final bool isAuth;
  final String? userId;

  const _BookDetailContent({
    required this.book,
    required this.isAuth,
    required this.userId,
  });

  @override
  ConsumerState<_BookDetailContent> createState() =>
      _BookDetailContentState();
}

class _BookDetailContentState extends ConsumerState<_BookDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _descExpanded = false;

  int get _tabCount {
    int count = 1;
    if (widget.book.chapters.isNotEmpty) count++;
    if (widget.book.attachments.isNotEmpty) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void didUpdateWidget(_BookDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.chapters.length != widget.book.chapters.length ||
        oldWidget.book.attachments.length != widget.book.attachments.length) {
      _tabController.dispose();
      _tabController = TabController(length: _tabCount, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final theme = Theme.of(context);
    final downloadState = ref.watch(downloadsNotifierProvider);
    final isActiveDownload =
        downloadState.activeProgress.containsKey(book.id);
    final progress = downloadState.activeProgress[book.id] ?? 0.0;
    final isDownloadedAsync = ref.watch(isBookDownloadedProvider(book.id));
    final isJustDownloaded = downloadState.lastResults[book.id]?.success == true;
    final isDownloaded =
        isJustDownloaded || (isDownloadedAsync.valueOrNull ?? false);
    final bookPerms = ref.watch(bookPermissionsProvider);
    final lastResult = downloadState.lastResults[book.id];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildCoverHero(book, theme),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (bookPerms.canUpdate)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          color: Colors.white, size: 18),
                    ),
                    onPressed: () =>
                        context.push('/books/${book.id}/edit', extra: book),
                    tooltip: 'Edit Book',
                  ),
                ),
              // Download / options button
              if (widget.isAuth && book.isReadable)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: isActiveDownload
                      ? Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : isDownloaded
                          ? IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF059669)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 18),
                              ),
                              tooltip: 'Downloaded (Offline Options)',
                              onPressed: () =>
                                  _showDownloadedBookOptions(context, ref),
                            )
                          : IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7)
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.6),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0284C7)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.cloud_download_outlined,
                                    color: Colors.white, size: 18),
                              ),
                              tooltip: 'Download Book (Online Only)',
                              onPressed: () async {
                                if (widget.userId != null) {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final res = await ref
                                      .read(downloadsNotifierProvider.notifier)
                                      .startDownload(book, widget.userId!);
                                  if (res != null && mounted) {
                                    if (res.success) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            res.externalPath != null
                                                ? 'Saved to Downloads: ${book.title}'
                                                : 'Downloaded for offline reading: ${book.title}',
                                          ),
                                          action: res.externalPath != null
                                              ? SnackBarAction(
                                                  label: 'Open',
                                                  textColor: Colors.tealAccent,
                                                  onPressed: () {
                                                    ref
                                                        .read(booksRepositoryProvider)
                                                        .openDownloadedFile(
                                                          book: book,
                                                          userId: widget.userId!,
                                                          preferredPath: res.externalPath,
                                                        );
                                                  },
                                                )
                                              : null,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                ),
            ],
          ),
        ],
        body: Column(
          children: [
            // Book info
            _BookInfoHeader(book: book, theme: theme),

            // Partial download failure banner
            if (lastResult != null && lastResult.isPartial)
              _buildPartialDownloadBanner(theme, book),

            // Download error
            if (downloadState.errors.containsKey(book.id))
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(downloadState.errors[book.id]!,
                          style: TextStyle(
                              color: theme.colorScheme.error, fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      onPressed: () => ref
                          .read(downloadsNotifierProvider.notifier)
                          .clearError(book.id),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

            // Tabs: show TabBar only if multiple tabs exist
            if (_tabCount > 1) ...[
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                indicatorColor: theme.colorScheme.primary,
                tabs: [
                  const Tab(text: 'Details'),
                  if (book.chapters.isNotEmpty)
                    Tab(text: 'Chapters (${book.chapters.length})'),
                  if (book.attachments.isNotEmpty)
                    Tab(text: 'Attachments (${book.attachments.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DetailsTab(
                      book: book,
                      expanded: _descExpanded,
                      onExpand: () =>
                          setState(() => _descExpanded = !_descExpanded),
                    ),
                    if (book.chapters.isNotEmpty)
                      _ChaptersTab(
                        book: book,
                        isDownloaded: isDownloaded,
                      ),
                    if (book.attachments.isNotEmpty)
                      _AttachmentsTab(
                        attachments: book.attachments,
                        book: book,
                      ),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: _DetailsTab(
                  book: book,
                  expanded: _descExpanded,
                  onExpand: () =>
                      setState(() => _descExpanded = !_descExpanded),
                ),
              ),
            ],
          ],
        ),
      ),

      // Read / Open CTA
      bottomNavigationBar: _ReadButton(
        book: book,
        isAuth: widget.isAuth,
        isDownloaded: isDownloaded,
      ),
    );
  }

  Widget _buildCoverHero(BookModel book, ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background
        book.coverUrl != null
            ? CachedNetworkImage(
                imageUrl: book.coverUrl!,
                fit: BoxFit.cover,
                color: Colors.black54,
                colorBlendMode: BlendMode.darken,
              )
            : Container(
                color: theme.colorScheme.primaryContainer,
              ),
        // Centered cover card
        Center(
          child: Container(
            width: 140,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: book.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: book.coverUrl!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: theme.colorScheme.primaryContainer,
                    child: Center(
                      child: Icon(
                        book.format == BookFormat.audio
                            ? Icons.headphones
                            : Icons.menu_book,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 56,
                      ),
                    ),
                  ),
          ),
        ),
        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  theme.colorScheme.surface,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showRemoveDownloadDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Downloaded Book'),
        content: Text(
          'Do you want to delete "${widget.book.title}" from local storage? This will remove the offline copy from your device and return the book to online mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final uid = widget.userId ?? 'guest';
              await ref
                  .read(downloadsNotifierProvider.notifier)
                  .removeDownload(widget.book.id, uid);
              ref.invalidate(isBookDownloadedProvider(widget.book.id));
              ref.invalidate(downloadedBooksStreamProvider);
              ref.invalidate(allDownloadsStreamProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Deleted "${widget.book.title}" from local storage. Switched back to online mode.',
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

  void _showDownloadedBookOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('Open in Device File App'),
                subtitle:
                    const Text('View with your preferred reader or file manager'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (widget.userId != null) {
                    ref.read(booksRepositoryProvider).openDownloadedFile(
                          book: widget.book,
                          userId: widget.userId!,
                        );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share Downloaded File'),
                subtitle: const Text('Send or export file to other apps'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (widget.userId != null) {
                    ref.read(booksRepositoryProvider).shareDownloadedFile(
                          book: widget.book,
                          userId: widget.userId!,
                        );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Remove from In-App Library',
                    style: TextStyle(color: Colors.red)),
                subtitle: const Text(
                    'Files in device Downloads folder will be kept intact'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRemoveDownloadDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartialDownloadBanner(ThemeData theme, BookModel book) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Colors.amber.withAlpha(isDark ? 40 : 25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.amber.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partial Download',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Book is safely saved in your app library, but export to your device Downloads folder failed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              if (widget.userId != null) {
                ref
                    .read(downloadsNotifierProvider.notifier)
                    .exportInAppToDevice(book, widget.userId!);
              }
            },
            child: const Text('Retry Export', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _BookInfoHeader extends StatelessWidget {
  final BookModel book;
  final ThemeData theme;
  const _BookInfoHeader({required this.book, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            book.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (book.author != null && book.author!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'by ${book.author}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetaBadge(book.format.name.toUpperCase(), theme,
                  icon: Icons.description_outlined),
              _MetaBadge(book.language.name, theme,
                  icon: Icons.language),
              if (book.isDictionary)
                _MetaBadge('መዝገበ ቃላት', theme,
                    icon: Icons.translate_rounded),
              if (book.pageCount != null)
                _MetaBadge('${book.pageCount} pages', theme,
                    icon: Icons.menu_book_outlined),
              if (book.publishedYear != null)
                _MetaBadge('${book.publishedYear}', theme,
                    icon: Icons.calendar_today_outlined),
              if (book.categoryName != null)
                _MetaBadge(book.categoryName!, theme,
                    icon: Icons.folder_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final ThemeData theme;
  final IconData icon;
  const _MetaBadge(this.label, this.theme, {required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final BookModel book;
  final bool expanded;
  final VoidCallback onExpand;
  const _DetailsTab(
      {required this.book, required this.expanded, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // Dictionary details card
        if (book.isDictionary) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.translate_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'መዝገበ ቃላት (Dictionary Mode)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (book.dictionaryConfig != null) ...[
                  Text(
                    'Dictionary: ${book.dictionaryConfig!.dictionaryName}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Language Pair: ',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                      Text(
                        '${book.dictionaryConfig!.sourceLanguage?.name ?? ''} → ${book.dictionaryConfig!.targetLanguage?.name ?? ''}',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (book.dictionaryConfig!.totalEntries > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Indexed Entries: ${book.dictionaryConfig!.totalEntries}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
        if (book.description != null && book.description!.isNotEmpty) ...[
          Text('About', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            book.description!,
            maxLines: expanded ? null : 4,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium
                ?.copyWith(height: 1.6, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
          ),
          TextButton(
            onPressed: onExpand,
            child: Text(expanded ? 'Show less' : 'Read more'),
          ),
          const Divider(),
        ],
        if (book.publisher != null)
          _DetailRow('Publisher', book.publisher!, theme),
        if (book.translator != null)
          _DetailRow('Translator', book.translator!, theme),
        if (book.edition != null)
          _DetailRow('Edition', book.edition!, theme),
        if (book.isbn != null)
          _DetailRow('ISBN', book.isbn!, theme),
        if (book.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Tags',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: book.tags
                .map((t) => Chip(label: Text(t), padding: EdgeInsets.zero))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  const _DetailRow(this.label, this.value, this.theme);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ChaptersTab extends ConsumerWidget {
  final BookModel book;
  final bool isDownloaded;
  const _ChaptersTab({required this.book, required this.isDownloaded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: book.chapters.length,
      itemBuilder: (_, i) {
        final ch = book.chapters[i];
        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            child: Text('${ch.order + 1}',
                style: const TextStyle(fontSize: 12)),
          ),
          title: Text(ch.title, style: theme.textTheme.bodyMedium),
          subtitle: ch.durationSeconds != null
              ? Text(
                  '${(ch.durationSeconds! ~/ 60)}m ${ch.durationSeconds! % 60}s',
                  style: theme.textTheme.bodySmall,
                )
              : null,
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () {
            context.push('/books/${book.id}/read',
                extra: {'startChapter': ch.order, 'isDownloaded': isDownloaded});
          },
        );
      },
    );
  }
}

class _AttachmentsTab extends ConsumerWidget {
  final List<BookAttachmentModel> attachments;
  final BookModel book;

  const _AttachmentsTab({
    required this.attachments,
    required this.book,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: attachments.length,
      itemBuilder: (ctx, index) {
        final att = attachments[index];
        final (IconData icon, Color color, String typeLabel) =
            switch (att.mediaType) {
          AttachmentMediaType.document => (
              Icons.description_rounded,
              Colors.blue,
              'Document',
            ),
          AttachmentMediaType.image => (
              Icons.image_rounded,
              Colors.teal,
              'Image',
            ),
          AttachmentMediaType.audio => (
              Icons.headphones_rounded,
              Colors.purple,
              'Audio',
            ),
          AttachmentMediaType.video => (
              Icons.videocam_rounded,
              Colors.orange,
              'Video',
            ),
          AttachmentMediaType.other => (
              Icons.attach_file_rounded,
              Colors.blueGrey,
              'File',
            ),
        };

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 50 : 25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        att.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color.withAlpha(80)),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          if (att.fileSizeBytes != null &&
                              att.fileSizeBytes! > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              _formatBytes(att.fileSizeBytes),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (att.url != null)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      att.mediaType == AttachmentMediaType.audio
                          ? Icons.play_arrow_rounded
                          : (att.mediaType == AttachmentMediaType.video
                              ? Icons.play_circle_outline_rounded
                              : Icons.open_in_new_rounded),
                      size: 16,
                    ),
                    label: Text(
                      att.mediaType == AttachmentMediaType.audio ||
                              att.mediaType == AttachmentMediaType.video
                          ? 'Play'
                          : 'Open',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      _openAttachment(context, att);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAttachment(BuildContext context, BookAttachmentModel att) {
    if (att.url == null) return;
    if (att.mediaType == AttachmentMediaType.image) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              child: Image.network(
                att.url!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image,
                    size: 64, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening ${att.displayName}...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ReadButton extends ConsumerWidget {
  final BookModel book;
  final bool isAuth;
  final bool isDownloaded;
  const _ReadButton(
      {required this.book, required this.isAuth, required this.isDownloaded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(progressProvider(book.id));
    final hasProgress = progress.valueOrNull?.percentComplete != null &&
        (progress.valueOrNull!.percentComplete) > 0;

    if (!book.hasContent) {
      return const SizedBox.shrink();
    }

    // External link
    if (book.format == BookFormat.externalLink && book.externalUrl != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () {
              // Open external URL through url_launcher or go_router
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open External Link'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasProgress)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: LinearProgressIndicator(
                  value: (progress.valueOrNull!.percentComplete) / 100,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  valueColor:
                      AlwaysStoppedAnimation(theme.colorScheme.primary),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            FilledButton.icon(
              onPressed: () {
                context.push('/books/${book.id}/read',
                    extra: {'isDownloaded': isDownloaded});
              },
              icon: Icon(
                isDownloaded ? Icons.check_circle_rounded : Icons.menu_book,
              ),
              label: Text(hasProgress ? 'Continue Reading' : 'Read Book'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
