// lib/features/books/presentation/widgets/book_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../data/models/book_model.dart';
import '../providers/books_providers.dart';

class BookCard extends ConsumerWidget {
  final BookModel book;
  final VoidCallback? onCoverTap;
  final VoidCallback? onDetailTap;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final bool compact;

  const BookCard({
    super.key,
    required this.book,
    this.onCoverTap,
    this.onDetailTap,
    this.onTap,
    this.onDownload,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final downloadState = ref.watch(downloadsNotifierProvider);
    final isActiveDownload = downloadState.activeProgress.containsKey(book.id);
    final progress = downloadState.activeProgress[book.id] ?? 0.0;
    final isDownloadedAsync = ref.watch(isBookDownloadedProvider(book.id));
    final isDownloaded = isDownloadedAsync.valueOrNull ?? false;

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
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: book.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => _PlaceholderCover(book: book),
                            errorWidget: (_, _, _) => _PlaceholderCover(book: book),
                          )
                        : _PlaceholderCover(book: book),
                  ),

                  // Format badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _FormatBadge(format: book.format),
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
                            ? _StatusBadge(icon: Icons.offline_pin, color: Colors.green)
                            : onDownload != null
                                ? _DownloadButton(onTap: onDownload!)
                                : const SizedBox.shrink(),
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
}

class _PlaceholderCover extends StatelessWidget {
  final BookModel book;
  const _PlaceholderCover({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
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

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _StatusBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DownloadButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.download_outlined, color: Colors.white, size: 14),
      ),
    );
  }
}
