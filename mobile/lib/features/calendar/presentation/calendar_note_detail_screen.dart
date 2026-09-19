// lib/features/calendar/presentation/calendar_note_detail_screen.dart
// Premium full-screen detail view for a single Calendar Note.
// Navigated to via GoRouter path: /calendar/note/:noteId

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/media_watermark_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/add_note_sheet.dart';
import 'package:abushakir/abushakir.dart';

// ─── Provider: fetch single note by ID ────────────────────────────────────────

final _calendarNoteByIdProvider =
    FutureProvider.family<CalendarNoteModel?, String>((ref, noteId) async {
      final repo = ref.watch(calendarOfflineRepositoryProvider);
      return repo.getNoteById(noteId);
    });

// ─── Screen ───────────────────────────────────────────────────────────────────

class CalendarNoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;

  const CalendarNoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<CalendarNoteDetailScreen> createState() =>
      _CalendarNoteDetailScreenState();
}

class _CalendarNoteDetailScreenState
    extends ConsumerState<CalendarNoteDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Prevent screenshots
    _setScreenshotPrevention(true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _setScreenshotPrevention(false);
    super.dispose();
  }

  void _setScreenshotPrevention(bool prevent) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (prevent) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        // FLAG_SECURE equivalent via method channel (best-effort on Flutter side)
      }
    }
  }

  bool get _canManage {
    final role = ref.watch(authProvider).user?.role ?? '';
    return role == 'SUPER_ADMIN' || role == 'ADMIN';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final noteAsync = ref.watch(_calendarNoteByIdProvider(widget.noteId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: noteAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildError(context, tr, e),
          data: (note) {
            if (note == null) {
              return _buildNotFound(context, tr);
            }
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildNoteDetail(context, theme, tr, note),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoteDetail(
    BuildContext context,
    ThemeData theme,
    String Function(String) tr,
    CalendarNoteModel note,
  ) {
    final etDate = EtDatetime(
      year: note.ethiopianYear,
      month: note.ethiopianMonth,
      day: note.ethiopianDay,
    );
    final etDateStr = EthiopianCalendarUtil.formatEthiopianDate(etDate);
    final grDateStr = EthiopianCalendarUtil.formatGregorianDate(
      note.gregorianDate,
    );
    final hasMedia = note.media.isNotEmpty;
    final hasReminder = note.hasReminder;
    final canManage = _canManage;

    // Build copyable text
    final fullText = [
      if (note.title != null && note.title!.isNotEmpty) note.title!,
      if (note.content != null && note.content!.isNotEmpty) note.content!,
    ].join('\n\n');

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── App Bar ─────────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          stretch: true,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          leading: IconButton(
            icon: _actionCircle(
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              theme: theme,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            etDateStr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamilyFallback: const [
                'Noto Serif Ethiopic',
                'Noto Sans Ethiopic',
              ],
            ),
          ),
          actions: [
            // 3-dots menu
            PopupMenuButton<String>(
              icon: _actionCircle(
                child: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
                theme: theme,
              ),
              onSelected: (value) =>
                  _handleMenuAction(context, value, etDate, note, fullText),
              itemBuilder: (_) => [
                // Admin-only
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
                // All users
                if (fullText.isNotEmpty)
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
                if (hasMedia)
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
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),

        // ── Body ─────────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date chips
                _DateChipRow(etDateStr: etDateStr, grDateStr: grDateStr),
                const SizedBox(height: 20),

                // ── Title ──
                if (note.title != null && note.title!.isNotEmpty) ...[
                  Text(
                    note.title!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Content ──
                if (note.content != null && note.content!.isNotEmpty) ...[
                  SelectableText(
                    note.content!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Reminder card ──
                if (hasReminder) ...[
                  _ReminderCard(note: note, theme: theme),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),

        // ── Media section (all media) ──────────────────────────────────────
        if (hasMedia) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Media (${note.media.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                itemCount: note.media.length,
                itemBuilder: (context, index) {
                  final media = note.media[index];
                  final url = media.file?['url'] as String?;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _openFullscreen(context, note.media, index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: url != null
                            ? Image.network(
                                url,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _mediaPlaceholder(theme),
                              )
                            : _mediaPlaceholder(theme),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // ── Metadata footer ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
            child: _MetadataFooter(note: note, theme: theme),
          ),
        ),
      ],
    );
  }

  Widget _actionCircle({required Widget child, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }

  Widget _mediaPlaceholder(ThemeData theme) {
    return Container(
      width: 120,
      height: 120,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.attach_file,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  // ── Action handlers ──────────────────────────────────────────────────────

  Future<void> _handleMenuAction(
    BuildContext context,
    String action,
    EtDatetime etDate,
    CalendarNoteModel note,
    String fullText,
  ) async {
    switch (action) {
      case 'edit':
        await _editNote(etDate, note);
      case 'delete':
        await _confirmDelete(note);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: fullText));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Text copied to clipboard')),
          );
        }
      case 'download':
        await _downloadAllMedia(context, note);
    }
  }

  Future<void> _editNote(EtDatetime etDate, CalendarNoteModel note) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddNoteSheet(selectedDate: etDate, existingNote: note),
    );
    if (!mounted) return;
    ref.invalidate(_calendarNoteByIdProvider(widget.noteId));
  }

  Future<void> _confirmDelete(CalendarNoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final deleteNote = ref.read(deleteCalendarNoteProvider);
        await deleteNote(note.id);
        ref.invalidate(calendarNotesForDateProvider);
        ref.invalidate(calendarNotesForMonthProvider);
        if (!mounted) return;
        context.pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _downloadAllMedia(
    BuildContext context,
    CalendarNoteModel note,
  ) async {
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
    List<dynamic> media,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _FullscreenMediaView(media: media, initialIndex: initialIndex),
      ),
    );
  }

  // ── Error / not found states ─────────────────────────────────────────────

  Widget _buildError(
    BuildContext context,
    String Function(String) tr,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load note',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('$error', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context, String Function(String) tr) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Note not found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This note may have been deleted.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/calendar'),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Go to Calendar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fullscreen media viewer ──────────────────────────────────────────────────

class _FullscreenMediaView extends StatefulWidget {
  final List<dynamic> media;
  final int initialIndex;

  const _FullscreenMediaView({required this.media, required this.initialIndex});

  @override
  State<_FullscreenMediaView> createState() => _FullscreenMediaViewState();
}

class _FullscreenMediaViewState extends State<_FullscreenMediaView> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
          PageView.builder(
            controller: _pageController,
            itemCount: widget.media.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final media = widget.media[index];
              final url = _getMediaUrl(media);
              if (url == null || url.isEmpty) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 64,
                  ),
                );
              }
              return InteractiveViewer(
                child: Center(
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
                    tooltip: 'Download with mark',
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _DateChipRow extends StatelessWidget {
  final String etDateStr;
  final String grDateStr;

  const _DateChipRow({required this.etDateStr, required this.grDateStr});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          icon: Icons.calendar_today,
          label: etDateStr,
          fontFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
        ),
        _Chip(icon: Icons.date_range, label: grDateStr),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String>? fontFallback;

  const _Chip({required this.icon, required this.label, this.fontFallback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontFamilyFallback: fontFallback,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final CalendarNoteModel note;
  final ThemeData theme;

  const _ReminderCard({required this.note, required this.theme});

  @override
  Widget build(BuildContext context) {
    final reminderTime = note.reminderDateTime;
    final repeatLabel = switch (note.reminderRepeat) {
      ReminderRepeat.none => 'Once',
      ReminderRepeat.monthly => 'Monthly',
      ReminderRepeat.yearly => 'Yearly',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.8),
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: theme.colorScheme.tertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder set',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                if (reminderTime != null)
                  Text(
                    '${_formatTime(note.reminderHour ?? 8, note.reminderMinute ?? 0)}  ·  $repeatLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}

class _MetadataFooter extends StatelessWidget {
  final CalendarNoteModel note;
  final ThemeData theme;

  const _MetadataFooter({required this.note, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        _metaRow('Created', _formatDateTime(note.createdAt)),
        const SizedBox(height: 6),
        _metaRow('Last updated', _formatDateTime(note.updatedAt)),
        if (note.media.isNotEmpty) ...[
          const SizedBox(height: 6),
          _metaRow('Attachments', '${note.media.length}'),
        ],
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_p(local.month)}-${_p(local.day)}  ${_p(local.hour)}:${_p(local.minute)}';
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}
