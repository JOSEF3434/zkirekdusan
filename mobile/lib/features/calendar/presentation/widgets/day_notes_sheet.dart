import 'package:abushakir/abushakir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/media_watermark_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_download_settings_provider.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/add_note_sheet.dart';

class DayNotesSheet extends ConsumerWidget {
  final EtDatetime selectedDate;

  const DayNotesSheet({super.key, required this.selectedDate});

  bool _canManage(WidgetRef ref) {
    final role = ref.watch(authProvider).user?.role ?? '';
    return role == 'SUPER_ADMIN' || role == 'ADMIN';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notesAsync = ref.watch(
      calendarNotesForDateProvider((
        year: selectedDate.year,
        month: selectedDate.month,
        day: selectedDate.day,
      )),
    );
    final canManage = _canManage(ref);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        EthiopianCalendarUtil.formatEthiopianDate(selectedDate),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamilyFallback: const [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        EthiopianCalendarUtil.formatGregorianDate(
                          EthiopianCalendarUtil.toGregorian(selectedDate),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Notes list
          Flexible(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return _buildEmptyState(context, canManage);
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notes.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _NoteListItem(
                      note: note,
                      selectedDate: selectedDate,
                      canManage: canManage,
                      onDeleted: () {
                        ref.invalidate(
                          calendarNotesForDateProvider((
                            year: selectedDate.year,
                            month: selectedDate.month,
                            day: selectedDate.day,
                          )),
                        );
                        ref.invalidate(
                          calendarNotesForMonthProvider((
                            year: selectedDate.year,
                            month: selectedDate.month,
                          )),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading notes: $error',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
          ),

          // Add note button — admin only
          if (canManage) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _showAddNoteSheet(context, ref, selectedDate),
                icon: const Icon(Icons.add),
                label: Consumer(
                  builder: (_, ref, _) =>
                      Text(ref.watch(trProvider)('calendar.add_note')),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool canManage) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No notes for this day',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: 8),
              Text(
                'Tap "Add Note" to create one',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddNoteSheet(
    BuildContext context,
    WidgetRef ref,
    EtDatetime date, {
    CalendarNoteModel? existingNote,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          AddNoteSheet(selectedDate: date, existingNote: existingNote),
    );

    if (result == true) {
      ref.invalidate(
        calendarNotesForDateProvider((
          year: date.year,
          month: date.month,
          day: date.day,
        )),
      );
      ref.invalidate(
        calendarNotesForMonthProvider((year: date.year, month: date.month)),
      );
    }
  }
}

// ─── Note list item ───────────────────────────────────────────────────────────

class _NoteListItem extends ConsumerWidget {
  final CalendarNoteModel note;
  final EtDatetime selectedDate;
  final bool canManage;
  final VoidCallback onDeleted;

  const _NoteListItem({
    required this.note,
    required this.selectedDate,
    required this.canManage,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasMedia = note.media.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: note.title != null && note.title!.isNotEmpty
              ? Text(
                  note.title!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          subtitle: note.content != null && note.content!.isNotEmpty
              ? Text(
                  note.content!,
                  maxLines: note.title != null ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleAction(context, ref, action),
            itemBuilder: (context) {
              final globalDownloadEnabled = ref.read(calendarDownloadEnabledProvider);
              final canDownload = globalDownloadEnabled && note.allowDownload && note.media.isNotEmpty;
              return [
              // ── Admin-only actions ──
              if (canManage) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ],
              // ── All users ──
              if (note.content != null && note.content!.isNotEmpty)
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_outlined),
                      SizedBox(width: 12),
                      Text('Copy text'),
                    ],
                  ),
                ),
              if (canDownload)
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download_outlined),
                      SizedBox(width: 12),
                      Text('Download media'),
                    ],
                  ),
                ),
            ];
            },
          ),
          // Tap → navigate to detail
          onTap: () {
            Navigator.of(context).pop(); // close sheet first
            context.push('/calendar/note/${note.id}');
          },
        ),

        // ── Scrollable media strip ──
        if (hasMedia)
          SizedBox(
            height: 88,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: note.media.length,
              itemBuilder: (context, index) {
                final media = note.media[index];
                final url = media.file?['url'] as String?;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _openFullscreen(
                      context,
                      ref,
                      note.media,
                      index,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: url != null
                          ? Image.network(
                              url,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _mediaTile(theme),
                            )
                          : _mediaTile(theme),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _mediaTile(ThemeData theme) => Container(
    width: 80,
    height: 80,
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icon(
      Icons.attach_file,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
    ),
  );

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        final etDate = selectedDate;
        final result = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (_) =>
              AddNoteSheet(selectedDate: etDate, existingNote: note),
        );
        if (result == true) onDeleted();
      case 'delete':
        await _confirmDelete(context, ref);
      case 'copy':
        final text = [
          if (note.title != null && note.title!.isNotEmpty) note.title!,
          if (note.content != null && note.content!.isNotEmpty) note.content!,
        ].join('\n\n');
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Text copied to clipboard')),
          );
        }
      case 'download':
        await _downloadAllMedia(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Consumer(
          builder: (_, ref, _) => Text(ref.watch(trProvider)('common.delete')),
        ),
        content: Consumer(
          builder: (_, ref, _) =>
              Text(ref.watch(trProvider)('admin.confirm.delete_msg')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Consumer(
              builder: (_, ref, _) =>
                  Text(ref.watch(trProvider)('common.cancel')),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Consumer(
              builder: (_, ref, _) =>
                  Text(ref.watch(trProvider)('common.delete')),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deleteNote = ref.read(deleteCalendarNoteProvider);
        await deleteNote(note.id);
        onDeleted();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Note deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
        }
      }
    }
  }

  Future<void> _downloadAllMedia(BuildContext context) async {
    final urls = note.media
        .map((m) => m.file?['url'] as String?)
        .whereType<String>()
        .toList();
    if (urls.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No downloadable media found')),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading ${urls.length} file(s)…')),
      );
    }
    try {
      int done = 0;
      for (final url in urls) {
        await MediaWatermarkService.instance.downloadAndWatermark(url: url);
        done++;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$done media file(s) saved to internal storage with ዝክረ ቅዱሳን mark',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  void _openFullscreen(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> media,
    int initialIndex,
  ) {
    final globalDownloadEnabled = ref.read(calendarDownloadEnabledProvider);
    final canDownload = globalDownloadEnabled && note.allowDownload;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenMediaView(
          media: media,
          initialIndex: initialIndex,
          canDownload: canDownload,
        ),
      ),
    );
  }
}

// ─── Fullscreen media viewer ──────────────────────────────────────────────────

class _FullscreenMediaView extends StatefulWidget {
  final List<dynamic> media;
  final int initialIndex;
  final bool canDownload;

  const _FullscreenMediaView({
    required this.media,
    required this.initialIndex,
    this.canDownload = false,
  });

  @override
  State<_FullscreenMediaView> createState() => _FullscreenMediaViewState();
}

class _FullscreenMediaViewState extends State<_FullscreenMediaView> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _getMediaUrl(dynamic item) {
    if (item is CalendarNoteMedia) {
      return item.file?['url'] as String?;
    }
    if (item is Map) {
      final file = item['file'];
      if (file is Map) return file['url'] as String?;
      return item['url'] as String?;
    }
    return null;
  }

  Future<void> _downloadCurrent() async {
    final currentItem = widget.media[_currentIndex];
    final url = _getMediaUrl(currentItem);
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot download this media')),
      );
      return;
    }

    setState(() => _isDownloading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Applying ዝክረ ቅዱሳን mark and saving…')),
    );

    try {
      await MediaWatermarkService.instance.downloadAndWatermark(url: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Media saved to internal storage with ዝክረ ቅዱሳን mark'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable media pages
          PageView.builder(
            controller: _pageController,
            itemCount: widget.media.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final item = widget.media[index];
              final url = _getMediaUrl(item) ?? '';
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (widget.media.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.media.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (widget.canDownload)
                    IconButton(
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download, color: Colors.white),
                      tooltip: 'Download with ዝክረ ቅዱሳን mark',
                      onPressed: _isDownloading ? null : _downloadCurrent,
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // Dot indicator
          if (widget.media.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.media.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentIndex ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentIndex ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
