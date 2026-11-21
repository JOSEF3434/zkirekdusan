// lib/features/admin/presentation/screens/admin_mesbaks_screen.dart
import 'package:abushakir/abushakir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_confirmation_dialog.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_search_bar.dart';
import 'package:mobile/features/admin/presentation/widgets/manage_mesbak_dialog.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';

class AdminMesbaksScreen extends ConsumerStatefulWidget {
  const AdminMesbaksScreen({super.key});

  @override
  ConsumerState<AdminMesbaksScreen> createState() => _AdminMesbaksScreenState();
}

class _AdminMesbaksScreenState extends ConsumerState<AdminMesbaksScreen> {
  String _searchQuery = '';
  int _selectedMonth = 0; // 0 = All, 1-13 = specific month
  late EtDatetime _today;

  @override
  void initState() {
    super.initState();
    _today = EthiopianCalendarUtil.now();
    _selectedMonth = _today.month; // Default to current Ethiopian month
  }

  void _refresh() {
    ref.invalidate(calendarNotesForMonthProvider);
    ref.invalidate(calendarNotesForDateProvider);
    ref.invalidate(calendarNotesForRangeProvider);
    ref.invalidate(calendarNotesForCurrentWeekProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    // Watch notes for selected month or range
    final notesAsync = _selectedMonth == 0
        ? ref.watch(
            calendarNotesForRangeProvider((
              startYear: _today.year,
              startMonth: 1,
              startDay: 1,
              endYear: _today.year,
              endMonth: 13,
              endDay: 30,
              from: null,
              to: null,
            )),
          )
        : ref.watch(
            calendarNotesForMonthProvider((
              year: _today.year,
              month: _selectedMonth,
            )),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('admin.mesbaks', {'fallback': 'የምስባክ አስተዳደር'}),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamilyFallback: ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: tr('common.retry', {'fallback': 'አድስ'}),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ManageMesbakDialog.show(
            context,
            prefillYear: _today.year,
            prefillMonth: _selectedMonth == 0 ? _today.month : _selectedMonth,
            prefillDay: _today.day,
          ).then((_) => _refresh());
        },
        icon: const Icon(Icons.add),
        label: Text(
          tr('admin.add_mesbak', {'fallback': 'አዲስ ምስባክ መዝግብ'}),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamilyFallback: ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
          ),
        ),
      ),
      body: AdminResponsiveLayout(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AdminSearchBar(
                hintText: 'በርእስ ወይም በቃላት ፈልግ...',
                onSearch: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ),

            // Month Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('ሁሉም ወራት'),
                      selected: _selectedMonth == 0,
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedMonth = 0);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(13, (i) {
                      final m = i + 1;
                      final isCurrent = m == _today.month;
                      final name = EthiopianCalendarUtil.getMonthName(m);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            isCurrent ? '$name (የአሁኑ)' : name,
                            style: const TextStyle(
                              fontFamilyFallback: ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                            ),
                          ),
                          selected: _selectedMonth == m,
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedMonth = m);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Content List
            Expanded(
              child: notesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${tr('common.error')}: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: Text(tr('common.retry', {'fallback': 'እንደገና ሞክር'})),
                      ),
                    ],
                  ),
                ),
                data: (notes) {
                  final filtered = notes.where((n) {
                    if (n.deletedAt != null) return false;
                    if (_selectedMonth != 0 && n.ethiopianMonth != _selectedMonth) {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty) {
                      final matchTitle = n.title?.toLowerCase().contains(_searchQuery) ?? false;
                      final matchContent = n.content?.toLowerCase().contains(_searchQuery) ?? false;
                      return matchTitle || matchContent;
                    }
                    return true;
                  }).toList();

                  // Check if today has a mesbak
                  final hasTodayMesbak = notes.any(
                    (n) =>
                        n.deletedAt == null &&
                        n.ethiopianYear == _today.year &&
                        n.ethiopianMonth == _today.month &&
                        n.ethiopianDay == _today.day,
                  );

                  return RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      children: [
                        // Quick Add Banner for Today if not yet created
                        if (!hasTodayMesbak && (_selectedMonth == 0 || _selectedMonth == _today.month))
                          Card(
                            color: const Color(0xFFFFF8E7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFE5A93C), width: 1.2),
                            ),
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE5A93C),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'የዛሬ ምስባክ አልተመዘገበም',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF6B4500),
                                            fontFamilyFallback: ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ዛሬ ${_today.day} ${EthiopianCalendarUtil.getMonthName(_today.month)} ${_today.year} ዓ.ም. ነው',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF8C5B00),
                                            fontFamilyFallback: ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFB8860B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: () {
                                      ManageMesbakDialog.show(
                                        context,
                                        prefillYear: _today.year,
                                        prefillMonth: _today.month,
                                        prefillDay: _today.day,
                                      ).then((_) => _refresh());
                                    },
                                    child: const Text('አሁን መዝግብ'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (filtered.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  Text(
                                    'ምንም የተመዘገበ ምስባክ አልተገኘም',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontFamilyFallback: ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...filtered.map((note) => _buildMesbakItem(context, theme, note)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMesbakItem(BuildContext context, ThemeData theme, CalendarNoteModel note) {
    final monthName = EthiopianCalendarUtil.getMonthName(note.ethiopianMonth);
    final isToday = note.ethiopianYear == _today.year &&
        note.ethiopianMonth == _today.month &&
        note.ethiopianDay == _today.day;

    return Card(
      elevation: isToday ? 2.5 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isToday
              ? const Color(0xFFD4AF37)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isToday ? 1.8 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFD4AF37)
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$monthName ${note.ethiopianDay}፣ ${note.ethiopianYear}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isToday
                          ? Colors.black87
                          : theme.colorScheme.onPrimaryContainer,
                      fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                    ),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'የዛሬ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'አስተካክል',
                  onPressed: () {
                    ManageMesbakDialog.show(
                      context,
                      existingNote: note,
                      prefillYear: note.ethiopianYear,
                      prefillMonth: note.ethiopianMonth,
                      prefillDay: note.ethiopianDay,
                    ).then((_) => _refresh());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  tooltip: 'ሰርዝ',
                  onPressed: () => _confirmDelete(context, note),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Title
            if (note.title != null && note.title!.isNotEmpty) ...[
              Text(
                note.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Content snippet
            if (note.content != null && note.content!.isNotEmpty) ...[
              Text(
                note.content!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Metadata Badges
            Row(
              children: [
                if (note.allowDownload)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.download_rounded, size: 14),
                      label: const Text('ማውረድ ይቻላል', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                if (note.isAutoPublishEnabled)
                  Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.schedule_rounded, size: 14),
                    label: const Text('Auto-Publish', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CalendarNoteModel note) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await AdminConfirmationDialog.show(
      context,
      title: 'ምስባክ ሰርዝ',
      message: 'ይህንን ምስባክ (${note.title ?? "ምስባክ"}) መሰረዝ ይፈልጋሉ? ይህ ድርጊት አይመለስም።',
      confirmLabel: 'ሰርዝ',
      confirmColor: Colors.red,
    );
    if (confirmed != null && mounted) {
      try {
        await ref.read(deleteCalendarNoteProvider)(note.id);
        _refresh();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('ምስባኩ በተሳካ ሁኔታ ተሰርዟል')),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('መሰረዝ አልተቻለም: $e')),
        );
      }
    }
  }
}
