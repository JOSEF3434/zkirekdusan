// lib/features/books/presentation/screens/book_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import '../../data/models/book_model.dart';
import '../providers/books_providers.dart';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(e.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(bookDetailProvider(bookId)),
                child: const Text('Retry'),
              ),
            ],
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

  @override
  void initState() {
    super.initState();
    final hasTabs =
        widget.book.chapters.isNotEmpty || widget.book.description != null;
    _tabController =
        TabController(length: hasTabs ? 2 : 1, vsync: this);
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
    final isDownloaded = isDownloadedAsync.valueOrNull ?? false;

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
              // Download / remove button
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
                                  color: Colors.green.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.offline_pin,
                                    color: Colors.white, size: 18),
                              ),
                              onPressed: () =>
                                  _showRemoveDownloadDialog(context, ref),
                            )
                          : IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.download_outlined,
                                    color: Colors.white, size: 18),
                              ),
                              onPressed: () {
                                if (widget.userId != null) {
                                  ref
                                      .read(downloadsNotifierProvider.notifier)
                                      .startDownload(book, widget.userId!);
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

            // Tabs
            if (book.chapters.isNotEmpty || book.description != null)
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                indicatorColor: theme.colorScheme.primary,
                tabs: [
                  const Tab(text: 'Details'),
                  if (book.chapters.isNotEmpty)
                    Tab(text: 'Chapters (${book.chapters.length})'),
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
                ],
              ),
            ),
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
      builder: (_) => AlertDialog(
        title: const Text('Remove Download'),
        content: const Text(
            'Remove the downloaded file? You can re-download it anytime. This will not delete the book from the library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.userId != null) {
                ref
                    .read(downloadsNotifierProvider.notifier)
                    .removeDownload(widget.book.id, widget.userId!);
                ref.invalidate(isBookDownloadedProvider(widget.book.id));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
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
                isDownloaded ? Icons.offline_pin : Icons.menu_book,
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
