// lib/features/books/presentation/widgets/book_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/app_network_image.dart';
import '../../../../core/utils/media_url_resolver.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import '../../data/models/book_model.dart';
import '../providers/books_providers.dart';

class BookCard extends ConsumerWidget {
  final BookModel book;
  final VoidCallback? onCoverTap;
  final VoidCallback? onDetailTap;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDeleteDownload;
  final bool compact;

  const BookCard({
    super.key,
    required this.book,
    this.onCoverTap,
    this.onDetailTap,
    this.onTap,
    this.onDownload,
    this.onDeleteDownload,
    this.compact = false,
    this.isDownloadedTab = false,
  });

  final bool isDownloadedTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final downloadState = ref.watch(downloadsNotifierProvider);
    final isActiveDownload = downloadState.activeProgress.containsKey(book.id);
    final progress = downloadState.activeProgress[book.id] ?? 0.0;
    final isDownloadedAsync = ref.watch(isBookDownloadedProvider(book.id));
    final isJustDownloaded = downloadState.lastResults[book.id]?.success == true;
    final isDownloaded = isDownloadedTab ||
        isJustDownloaded ||
        (isDownloadedAsync.valueOrNull ?? false);
    final deleteAction = onDeleteDownload ??
        () => _confirmRemoveDownload(context, ref, book);

    final resolvedCover = MediaUrlResolver.resolve(book.coverUrl);
    final hasCover = resolvedCover != null && resolvedCover.isNotEmpty;

    final coverTap = onCoverTap ?? onTap;
    final detailTap = onDetailTap ?? onTap;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover - Clicking opens the book reader
          Expanded(
            child: MouseRegion(
              cursor: coverTap != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: coverTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: (hasCover)
                          ? AppNetworkImage(
                              imageUrl: resolvedCover,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => _PlaceholderCover(book: book),
                              errorWidget: (_, _, _) => _PlaceholderCover(book: book),
                            )
                          : _PlaceholderCover(book: book),
                    ),
                  ),

                  // Format badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _FormatBadge(format: book.format),
                  ),

                  // Dictionary badge
                  if (book.isDictionary)
                    Positioned(
                      top: 32,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B21A8).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.translate_rounded, size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              book.dictionaryConfig != null
                                  ? '${book.dictionaryConfig!.sourceLanguage?.code.toUpperCase() ?? ''}→${book.dictionaryConfig!.targetLanguage?.code.toUpperCase() ?? ''}'
                                  : 'መዝገበ ቃላት',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Download / status badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: isActiveDownload
                        ? CircularPercentIndicator(
                            radius: 18,
                            lineWidth: 3,
                            percent: progress,
                            backgroundColor: Colors.white24,
                            progressColor: theme.colorScheme.primary,
                            center: const Icon(Icons.downloading, size: 14, color: Colors.white),
                          )
                        : isDownloaded
                            ? _DownloadedBadge(onDelete: deleteAction)
                            : _OnlineBadge(
                                onDownload: onDownload,
                                isReadable: book.isReadable,
                              ),
                  ),

                  // Progress indicator at bottom
                  if (book.myProgress != null && book.myProgress!.percentComplete > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: book.myProgress!.percentComplete / 100,
                        backgroundColor: Colors.black26,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        minHeight: 3,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Info - Clicking opens the book details
        MouseRegion(
          cursor: detailTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: detailTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 12 : 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.isDictionary) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'መዝገበ ቃላት',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (book.author != null && book.author!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      book.author!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: compact ? 10 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
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
              final userId = auth.user?.id ?? 'guest';
              await ref
                  .read(downloadsNotifierProvider.notifier)
                  .removeDownload(book.id, userId);
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

class _PlaceholderCover extends StatelessWidget {
  final BookModel book;
  const _PlaceholderCover({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              book.format == BookFormat.audio ? Icons.headphones : Icons.menu_book,
              color: theme.colorScheme.onPrimaryContainer,
              size: 40,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                book.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  final BookFormat format;
  const _FormatBadge({required this.format});

  String get _label {
    switch (format) {
      case BookFormat.pdf: return 'PDF';
      case BookFormat.epub: return 'EPUB';
      case BookFormat.text: return 'TEXT';
      case BookFormat.audio: return 'AUDIO';
      case BookFormat.externalLink: return 'LINK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DownloadedBadge extends StatelessWidget {
  final VoidCallback? onDelete;
  const _DownloadedBadge({this.onDelete});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF059669),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 12),
          SizedBox(width: 3),
          Text(
            'Downloaded',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onDelete != null) {
      return Semantics(
        button: true,
        label: 'Delete downloaded book from local storage',
        child: Tooltip(
          message: 'Downloaded • Tap to delete from local storage',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: badge,
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Downloaded • Tap to delete from local storage',
      child: badge,
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  final VoidCallback? onDownload;
  final bool isReadable;

  const _OnlineBadge({
    this.onDownload,
    this.isReadable = true,
  });

  @override
  Widget build(BuildContext context) {
    final canDownload = onDownload != null && isReadable;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            canDownload ? Icons.cloud_download_outlined : Icons.cloud_outlined,
            color: const Color(0xFF38BDF8),
            size: 11,
          ),
          const SizedBox(width: 3),
          const Text(
            'Online',
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (canDownload) {
      return Semantics(
        button: true,
        label: 'Download book for offline reading',
        child: Tooltip(
          message: 'Online • Tap to Download',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDownload,
            child: content,
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Online Only',
      child: content,
    );
  }
}
