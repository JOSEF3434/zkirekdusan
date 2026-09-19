// lib/features/calendar/presentation/calendar_note_detail_screen.dart
// Premium full-screen detail view for a single Calendar Note.
// Navigated to via GoRouter path: /calendar/note/:noteId

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/add_note_sheet.dart';
import 'package:abushakir/abushakir.dart';

// ─── Provider: fetch single note by ID ────────────────────────────────────────

final _calendarNoteByIdProvider =
    FutureProvider.family<CalendarNoteModel?, String>((ref, noteId) async {
  // We search across currently cached notes from all month providers.
  // The cheapest approach is to look it up via the offline repository.
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Collapsible App Bar ──────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: hasMedia ? 280 : 160,
          pinned: true,
          stretch: true,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            // Edit action
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              onPressed: () => _editNote(etDate, note),
            ),
            // Delete action
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
              ),
              onPressed: () => _confirmDelete(note),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: hasMedia
                ? _buildMediaHero(theme, note)
                : _buildDateHero(theme, etDateStr, grDateStr),
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date chips
                if (hasMedia) ...[
                  _DateChipRow(etDateStr: etDateStr, grDateStr: grDateStr),
                  const SizedBox(height: 20),
                ],

                // Title
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

                // Content
                if (note.content != null && note.content!.isNotEmpty) ...[
                  Text(
                    note.content!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Reminder card
                if (hasReminder) _ReminderCard(note: note, theme: theme),

                // Media gallery (thumbnail strip if header is a hero for 1st image)
                if (hasMedia && note.media.length > 1) ...[
                  const SizedBox(height: 8),
                  _MediaGalleryStrip(note: note, theme: theme),
                ],

                const SizedBox(height: 40),

                // Metadata footer
                _MetadataFooter(note: note, theme: theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero backgrounds ────────────────────────────────────────────────────────

  Widget _buildMediaHero(ThemeData theme, CalendarNoteModel note) {
    final firstMedia = note.media.first;
    final url = firstMedia.file?['url'] as String?;
    if (url == null) return _buildGradientHero(theme);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildGradientHero(theme),
        ),
        // Gradient overlay for readability
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateHero(
    ThemeData theme,
    String etDateStr,
    String grDateStr,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.85),
            theme.colorScheme.tertiary.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 20, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etDateStr,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                grDateStr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientHero(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.7),
            theme.colorScheme.secondary.withValues(alpha: 0.5),
          ],
        ),
      ),
    );
  }

  // ── Error / not found states ────────────────────────────────────────────────

  Widget _buildError(
    BuildContext context,
    String Function(String) tr,
    Object error,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text('Failed to load note', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('$error', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          FilledButton(onPressed: () => context.pop(), child: const Text('Go Back')),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context, String Function(String) tr) {
    final theme = Theme.of(context);
    return Center(
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
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _editNote(
    EtDatetime etDate,
    CalendarNoteModel note,
  ) async {
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
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
      margin: const EdgeInsets.only(bottom: 24),
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
                      color: theme.colorScheme.onTertiaryContainer
                          .withValues(alpha: 0.75),
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

class _MediaGalleryStrip extends StatelessWidget {
  final CalendarNoteModel note;
  final ThemeData theme;

  const _MediaGalleryStrip({required this.note, required this.theme});

  @override
  Widget build(BuildContext context) {
    // Show remaining media (skip first which is shown in hero)
    final remaining = note.media.skip(1).toList();
    if (remaining.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More attachments (${remaining.length})',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: remaining.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final media = remaining[index];
              final url = media.file?['url'] as String?;
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: url != null
                    ? Image.network(
                        url,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 100,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.attach_file,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
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
        _metaRow(
          'Created',
          _formatDateTime(note.createdAt),
        ),
        const SizedBox(height: 6),
        _metaRow(
          'Last updated',
          _formatDateTime(note.updatedAt),
        ),
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
