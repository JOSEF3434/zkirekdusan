// lib/features/calendar/presentation/widgets/mesbak_popup_dialog.dart
import 'package:abushakir/abushakir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/admin/presentation/widgets/manage_mesbak_dialog.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_events_provider.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/add_note_sheet.dart';
import 'package:mobile/features/calendar/presentation/widgets/day_notes_sheet.dart';

class MesbakPopupDialog extends ConsumerStatefulWidget {
  const MesbakPopupDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final isWide = MediaQuery.of(context).size.width > 600;
    if (isWide) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
            child: const MesbakPopupDialog(),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const MesbakPopupDialog(),
        ),
      );
    }
  }

  @override
  ConsumerState<MesbakPopupDialog> createState() => _MesbakPopupDialogState();
}

class _MesbakPopupDialogState extends ConsumerState<MesbakPopupDialog> {
  // 0 = Today Mesbak, 1 = Today Synaxarium, 2 = This Week, 3 = This Month, 4 = Filter / Range
  int _activeTabIndex = 0;

  // Synaxarium Tab (Tab 1) state:
  late EtDatetime _synaxariumDate;
  int _synaxariumMode = 0; // 0 = በአንድ ቀን (Specific Day), 1 = በቀናት ክልል (Range of Days)
  late int _synaxRangeStartMonth;
  late int _synaxRangeStartDay;
  late int _synaxRangeEndMonth;
  late int _synaxRangeEndDay;
  bool _synaxRangeSearched = false;

  // Filter mode (Tab 4): 0 = Single Day, 1 = Range
  int _filterMode = 0;
  // In Single Day mode: 0 = Mesbak, 1 = Synaxarium (ስንክሳር)
  int _singleDayTab = 0;
  // In Range mode: 0 = Synaxarium (ስንክሳር), 1 = Mesbak (ምስባክ), 2 = Both (ሁሉም)
  int _rangeType = 0;

  late EtDatetime _today;
  late int _selectedYear;
  late int _filterSingleMonth;
  late int _filterSingleDay;

  late int _rangeStartMonth;
  late int _rangeStartDay;
  late int _rangeEndMonth;
  late int _rangeEndDay;
  bool _rangeSearched = false;

  @override
  void initState() {
    super.initState();
    _today = EthiopianCalendarUtil.now();
    _selectedYear = _today.year;

    _synaxariumDate = _today;
    _synaxRangeStartMonth = _today.month;
    _synaxRangeStartDay = (_today.day - 7).clamp(1, 30);
    _synaxRangeEndMonth = _today.month;
    _synaxRangeEndDay = _today.day;

    _filterSingleMonth = _today.month;
    _filterSingleDay = _today.day;

    _rangeStartMonth = _today.month;
    _rangeStartDay = (_today.day - 7).clamp(1, 30);
    _rangeEndMonth = _today.month;
    _rangeEndDay = _today.day;
  }

  EtDatetime _addDaysToEtDatetime(EtDatetime date, int days) {
    final gDate = EthiopianCalendarUtil.toGregorian(date).add(Duration(days: days));
    return EthiopianCalendarUtil.fromGregorian(gDate);
  }

  Future<void> _pickDateForSynaxarium(BuildContext context) async {
    int tempYear = _synaxariumDate.year;
    int tempMonth = _synaxariumDate.month;
    int tempDay = _synaxariumDate.day;

    final selected = await showDialog<EtDatetime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final daysInMonth = EthiopianCalendarUtil.getDaysInMonth(tempYear, tempMonth);
          if (tempDay > daysInMonth) tempDay = daysInMonth;

          return AlertDialog(
            title: const Text(
              'ቀን ይምረጡ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        initialValue: tempMonth,
                        decoration: const InputDecoration(
                          labelText: 'ወር',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: List.generate(13, (i) {
                          final m = i + 1;
                          return DropdownMenuItem(
                            value: m,
                            child: Text(EthiopianCalendarUtil.getMonthName(m)),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              tempMonth = val;
                              final maxDays = EthiopianCalendarUtil.getDaysInMonth(tempYear, val);
                              if (tempDay > maxDays) tempDay = maxDays;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        initialValue: tempDay,
                        decoration: const InputDecoration(
                          labelText: 'ቀን',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: List.generate(daysInMonth, (i) {
                          final d = i + 1;
                          return DropdownMenuItem(value: d, child: Text('$d'));
                        }),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => tempDay = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('ይቅር'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop(EtDatetime(year: tempYear, month: tempMonth, day: tempDay));
                },
                child: const Text('ቀን ቀይር'),
              ),
            ],
          );
        },
      ),
    );

    if (selected != null) {
      setState(() {
        _synaxariumDate = selected;
      });
    }
  }

  void _refreshAll() {
    ref.invalidate(calendarNotesForDateProvider);
    ref.invalidate(calendarNotesForMonthProvider);
    ref.invalidate(calendarNotesForCurrentWeekProvider);
    ref.invalidate(calendarNotesForRangeProvider);
    ref.invalidate(calendarEventsForDayProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final perms = ref.watch(adminPermissionsProvider);

    final String dayName = EthiopianCalendarUtil.getWeekdayName(_today.weekday);
    final String monthName = EthiopianCalendarUtil.getMonthName(_today.month);
    final String dateString = '$dayName፣ ${_today.day} $monthName ${_today.year} ዓ.ም.';

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle (on mobile)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 12, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFDF7A), Color(0xFFD4AF37)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF4A3400),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('calendar.mesbak_title', {'fallback': 'የእለቱ ስንክሳርና ምስባክ'}),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamilyFallback: const [
                              'Noto Serif Ethiopic',
                              'Noto Sans Ethiopic',
                            ],
                          ),
                        ),
                        Text(
                          dateString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamilyFallback: const [
                              'Noto Serif Ethiopic',
                              'Noto Sans Ethiopic',
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (perms.canManageCalendar)
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      tooltip: tr('admin.mesbaks', {'fallback': 'የምስባክ አስተዳደር'}),
                      color: theme.colorScheme.primary,
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/admin/mesbaks');
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: tr('common.refresh', {'fallback': 'አድስ'}),
                    onPressed: _refreshAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Navigation Tabs (Today Mesbak | Today Synaxarium | This Week | This Month | Filter & Range)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildTabChip(
                      index: 0,
                      label: tr('calendar.today', {'fallback': 'የዛሬ ምስባክ'}),
                      icon: Icons.today_rounded,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      index: 1,
                      label: tr('calendar.today_synaxarium', {'fallback': 'የዕለቱ ስንክሳር'}),
                      icon: Icons.auto_stories_rounded,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      index: 2,
                      label: tr('calendar.this_week', {'fallback': 'የዚህ ሳምንት'}),
                      icon: Icons.view_week_rounded,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      index: 3,
                      label: tr('calendar.this_month', {'fallback': 'የዚህ ወር'}),
                      icon: Icons.calendar_month_rounded,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      index: 4,
                      label: tr('calendar.filter_range', {'fallback': 'በቀን / በክልል'}),
                      icon: Icons.tune_rounded,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Content Body for active tab
            Expanded(
              child: switch (_activeTabIndex) {
                0 => _buildTodayView(context, theme, perms),
                1 => _buildSynaxariumTab(context, theme, perms),
                2 => _buildThisWeekView(context, theme, perms),
                3 => _buildThisMonthView(context, theme, perms),
                4 => _buildFilterRangeView(context, theme, perms),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip({
    required int index,
    required String label,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = _activeTabIndex == index;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _activeTabIndex = index);
      },
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontFamilyFallback: const [
            'Noto Serif Ethiopic',
            'Noto Sans Ethiopic',
          ],
        ),
      ),
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. TODAY'S MESBAK VIEW
  // ─────────────────────────────────────────────────────────────
  Widget _buildTodayView(BuildContext context, ThemeData theme, AdminPermissions perms) {
    final tr = ref.watch(trProvider);
    final notesAsync = ref.watch(
      calendarNotesForDateProvider((
        year: _today.year,
        month: _today.month,
        day: _today.day,
      )),
    );

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.orange),
              const SizedBox(height: 12),
              Text('${tr('common.error')}: $err', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(
                  calendarNotesForDateProvider((
                    year: _today.year,
                    month: _today.month,
                    day: _today.day,
                  )),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(tr('common.retry', {'fallback': 'እንደገና ሞክር'})),
              ),
            ],
          ),
        ),
      ),
      data: (notes) {
        if (notes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      size: 48,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ለዛሬ ቀን (${_today.day} ${EthiopianCalendarUtil.getMonthName(_today.month)}) የተመዘገበ ምስባክ የለም',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamilyFallback: const [
                        'Noto Serif Ethiopic',
                        'Noto Sans Ethiopic',
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'አስተዳዳሪው ለዚህ ቀን ምስባክ ሲለጥፍ እዚህ ይታያል።',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamilyFallback: const [
                        'Noto Serif Ethiopic',
                        'Noto Sans Ethiopic',
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (perms.canManageCalendar) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        ManageMesbakDialog.show(
                          context,
                          prefillYear: _today.year,
                          prefillMonth: _today.month,
                          prefillDay: _today.day,
                        ).then((_) => _refreshAll());
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        tr('calendar.add_today_mesbak', {'fallback': 'የዛሬውን ምስባክ መዝግብ'}),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return _buildMesbakCard(
              context: context,
              theme: theme,
              note: note,
              isToday: true,
              perms: perms,
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1.2 SYNAXARIUM (DAY NOTES) VIEW
  // ─────────────────────────────────────────────────────────────
  Widget _buildSynaxariumTab(BuildContext context, ThemeData theme, AdminPermissions perms) {
    final isToday = _synaxariumDate.year == _today.year &&
        _synaxariumDate.month == _today.month &&
        _synaxariumDate.day == _today.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode selector: በአንድ ቀን (Specific Day) vs በቀናት ክልል (Range of Days)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 0,
                label: Text('በአንድ ቀን'),
                icon: Icon(Icons.today_rounded, size: 16),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('በቀናት ክልል'),
                icon: Icon(Icons.date_range_rounded, size: 16),
              ),
            ],
            selected: {_synaxariumMode},
            onSelectionChanged: (set) {
              setState(() {
                _synaxariumMode = set.first;
              });
            },
          ),
        ),

        const SizedBox(height: 2),

        if (_synaxariumMode == 0) ...[
          // Specific Day Navigation Bar
          Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    tooltip: 'ቀዳሚ ቀን',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _synaxariumDate = _addDaysToEtDatetime(_synaxariumDate, -1);
                      });
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDateForSynaxarium(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    EthiopianCalendarUtil.formatEthiopianDate(_synaxariumDate),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontFamilyFallback: const [
                                        'Noto Serif Ethiopic',
                                        'Noto Sans Ethiopic',
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ዛሬ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ቀን ለመቀየር ይጫኑ • ${EthiopianCalendarUtil.getWeekdayName(_synaxariumDate.weekday)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    tooltip: 'ቀጣይ ቀን',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _synaxariumDate = _addDaysToEtDatetime(_synaxariumDate, 1);
                      });
                    },
                  ),
                  if (!isToday)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        setState(() {
                          _synaxariumDate = _today;
                        });
                      },
                      child: const Text('ዛሬ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: DayNotesSheet(selectedDate: _synaxariumDate, isEmbedded: true),
          ),
        ] else ...[
          // Synaxarium Range Filter Bar
          Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('ከ፡', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _synaxRangeStartMonth,
                          decoration: const InputDecoration(
                            labelText: 'ወር',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: List.generate(13, (i) {
                            final m = i + 1;
                            return DropdownMenuItem<int>(
                              value: m,
                              child: Text(EthiopianCalendarUtil.getMonthName(m), style: const TextStyle(fontSize: 13)),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) setState(() => _synaxRangeStartMonth = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: DropdownButtonFormField<int>(
                          initialValue: _synaxRangeStartDay,
                          decoration: const InputDecoration(
                            labelText: 'ቀን',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: List.generate(30, (i) => DropdownMenuItem<int>(value: i + 1, child: Text('${i + 1}'))),
                          onChanged: (val) {
                            if (val != null) setState(() => _synaxRangeStartDay = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('እስከ፡', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _synaxRangeEndMonth,
                          decoration: const InputDecoration(
                            labelText: 'ወር',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: List.generate(13, (i) {
                            final m = i + 1;
                            return DropdownMenuItem<int>(
                              value: m,
                              child: Text(EthiopianCalendarUtil.getMonthName(m), style: const TextStyle(fontSize: 13)),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) setState(() => _synaxRangeEndMonth = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: DropdownButtonFormField<int>(
                          initialValue: _synaxRangeEndDay,
                          decoration: const InputDecoration(
                            labelText: 'ቀን',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: List.generate(30, (i) => DropdownMenuItem<int>(value: i + 1, child: Text('${i + 1}'))),
                          onChanged: (val) {
                            if (val != null) setState(() => _synaxRangeEndDay = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      onPressed: () => setState(() => _synaxRangeSearched = true),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('ስንክሳር ፈልግ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _buildSynaxariumRangeView(
              context: context,
              theme: theme,
              perms: perms,
              startYear: _selectedYear,
              startMonth: _synaxRangeStartMonth,
              startDay: _synaxRangeStartDay,
              endYear: _selectedYear,
              endMonth: _synaxRangeEndMonth,
              endDay: _synaxRangeEndDay,
              searched: _synaxRangeSearched,
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. THIS WEEK'S MESBAK VIEW
  // ─────────────────────────────────────────────────────────────
  Widget _buildThisWeekView(BuildContext context, ThemeData theme, AdminPermissions perms) {
    final tr = ref.watch(trProvider);
    final weekAsync = ref.watch(calendarNotesForCurrentWeekProvider);

    return weekAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${tr('common.error')}: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(calendarNotesForCurrentWeekProvider),
                child: Text(tr('common.retry', {'fallback': 'እንደገና ሞክር'})),
              ),
            ],
          ),
        ),
      ),
      data: (weekDays) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: weekDays.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = weekDays[index];
            final d = item.date;
            final note = item.note;
            final isToday = d.year == _today.year && d.month == _today.month && d.day == _today.day;
            final weekdayName = EthiopianCalendarUtil.getWeekdayName(d.weekday);
            final monthName = EthiopianCalendarUtil.getMonthName(d.month);

            return Card(
              elevation: isToday ? 3 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                    // Day header row
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
                            '$weekdayName፣ ${d.day} $monthName',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isToday
                                  ? Colors.black87
                                  : theme.colorScheme.onPrimaryContainer,
                              fontFamilyFallback: const [
                                'Noto Serif Ethiopic',
                                'Noto Sans Ethiopic',
                              ],
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
                              'ዛሬ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (note != null) ...[
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'ቅዳ',
                            onPressed: () => _copyNoteToClipboard(context, note),
                          ),
                        ],
                        if (perms.canManageCalendar)
                          IconButton(
                            icon: Icon(
                              note != null ? Icons.edit_outlined : Icons.add_circle_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            tooltip: note != null ? 'አስተካክል' : 'ምስባክ መዝግብ',
                            onPressed: () {
                              ManageMesbakDialog.show(
                                context,
                                existingNote: note,
                                prefillYear: d.year,
                                prefillMonth: d.month,
                                prefillDay: d.day,
                              ).then((_) => _refreshAll());
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Content
                    if (note != null) ...[
                      if (note.title != null && note.title!.isNotEmpty) ...[
                        Text(
                          note.title!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontFamilyFallback: const [
                              'Noto Serif Ethiopic',
                              'Noto Sans Ethiopic',
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (note.content != null && note.content!.isNotEmpty)
                        Text(
                          note.content!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            fontFamilyFallback: const [
                              'Noto Serif Ethiopic',
                              'Noto Sans Ethiopic',
                            ],
                          ),
                        ),
                    ] else ...[
                      Text(
                        'ለዚህ ቀን የተመዘገበ ምስባክ የለም',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamilyFallback: const [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. THIS MONTH'S MESBAK VIEW (Expandable)
  // ─────────────────────────────────────────────────────────────
  Widget _buildThisMonthView(BuildContext context, ThemeData theme, AdminPermissions perms) {
    final tr = ref.watch(trProvider);
    final monthNotesAsync = ref.watch(
      calendarNotesForMonthProvider((
        year: _today.year,
        month: _today.month,
      )),
    );

    final monthName = EthiopianCalendarUtil.getMonthName(_today.month);
    final daysInMonth = EthiopianCalendarUtil.getDaysInMonth(_today.year, _today.month);

    return monthNotesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${tr('common.error')}: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                  calendarNotesForMonthProvider((
                    year: _today.year,
                    month: _today.month,
                  )),
                ),
                child: Text(tr('common.retry', {'fallback': 'እንደገና ሞክር'})),
              ),
            ],
          ),
        ),
      ),
      data: (notes) {
        // Map notes by day
        final Map<int, List<CalendarNoteModel>> notesByDay = {};
        for (final n in notes) {
          notesByDay.putIfAbsent(n.ethiopianDay, () => []).add(n);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    'የ$monthName ወር ምስባካት (${notes.length} የተመዘገቡ)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamilyFallback: const [
                        'Noto Serif Ethiopic',
                        'Noto Sans Ethiopic',
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (perms.canManageCalendar)
                    TextButton.icon(
                      onPressed: () {
                        ManageMesbakDialog.show(
                          context,
                          prefillYear: _today.year,
                          prefillMonth: _today.month,
                        ).then((_) => _refreshAll());
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('አዲስ ምስባክ'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final dayNotes = notesByDay[day] ?? [];
                  final hasNotes = dayNotes.isNotEmpty;
                  final isToday = day == _today.day;

                  return Card(
                    elevation: isToday ? 2 : 0.5,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isToday
                            ? const Color(0xFFD4AF37)
                            : (hasNotes
                                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: isToday,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isToday
                              ? const Color(0xFFD4AF37)
                              : (hasNotes
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isToday
                                  ? Colors.black87
                                  : (hasNotes
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              '$monthName $day',
                              style: TextStyle(
                                fontWeight: hasNotes || isToday ? FontWeight.bold : FontWeight.w500,
                                fontFamilyFallback: const [
                                  'Noto Serif Ethiopic',
                                  'Noto Sans Ethiopic',
                                ],
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ዛሬ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: hasNotes
                            ? Text(
                                dayNotes.first.title ?? 'ምስባክ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontFamilyFallback: const [
                                    'Noto Serif Ethiopic',
                                    'Noto Sans Ethiopic',
                                  ],
                                ),
                              )
                            : Text(
                                'ምስባክ አልተመዘገበም',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFamilyFallback: const [
                                    'Noto Serif Ethiopic',
                                    'Noto Sans Ethiopic',
                                  ],
                                ),
                              ),
                        children: [
                          if (hasNotes) ...[
                            for (final note in dayNotes)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    if (note.title != null && note.title!.isNotEmpty)
                                      Text(
                                        note.title!,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontFamilyFallback: const [
                                            'Noto Serif Ethiopic',
                                            'Noto Sans Ethiopic',
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    if (note.content != null && note.content!.isNotEmpty)
                                      Text(
                                        note.content!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          height: 1.5,
                                          fontFamilyFallback: const [
                                            'Noto Serif Ethiopic',
                                            'Noto Sans Ethiopic',
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _copyNoteToClipboard(context, note),
                                          icon: const Icon(Icons.copy_rounded, size: 16),
                                          label: const Text('ቅዳ'),
                                        ),
                                        if (perms.canManageCalendar)
                                          TextButton.icon(
                                            onPressed: () {
                                              ManageMesbakDialog.show(
                                                context,
                                                existingNote: note,
                                                prefillYear: _today.year,
                                                prefillMonth: _today.month,
                                                prefillDay: day,
                                              ).then((_) => _refreshAll());
                                            },
                                            icon: const Icon(Icons.edit_outlined, size: 16),
                                            label: const Text('አስተካክል'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ለዚህ ቀን የተመዘገበ ምስባክ የለም',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (perms.canManageCalendar)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () {
                                        ManageMesbakDialog.show(
                                          context,
                                          prefillYear: _today.year,
                                          prefillMonth: _today.month,
                                          prefillDay: day,
                                        ).then((_) => _refreshAll());
                                      },
                                      icon: const Icon(Icons.add, size: 14),
                                      label: const Text('መዝግብ'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. FILTER / DATE & RANGE SEARCH VIEW
  // ─────────────────────────────────────────────────────────────
  Widget _buildFilterRangeView(BuildContext context, ThemeData theme, AdminPermissions perms) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Mode Selector (Single Day vs Range)
          SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 0,
                label: Text('በአንድ ቀን'),
                icon: Icon(Icons.calendar_today_rounded, size: 16),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('በቀናት ክልል'),
                icon: Icon(Icons.date_range_rounded, size: 16),
              ),
            ],
            selected: {_filterMode},
            onSelectionChanged: (set) {
              setState(() {
                _filterMode = set.first;
                _rangeSearched = false;
              });
            },
          ),

          const SizedBox(height: 12),

          // Controls for Selected Mode
          if (_filterMode == 0) ...[
            // Single day picker
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: _filterSingleMonth,
                    decoration: InputDecoration(
                      labelText: 'ወር',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(13, (i) {
                      final m = i + 1;
                      return DropdownMenuItem<int>(
                        value: m,
                        child: Text(
                          EthiopianCalendarUtil.getMonthName(m),
                          style: const TextStyle(
                            fontFamilyFallback: ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                          ),
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) setState(() => _filterSingleMonth = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _filterSingleDay,
                    decoration: InputDecoration(
                      labelText: 'ቀን',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(
                      EthiopianCalendarUtil.getDaysInMonth(_selectedYear, _filterSingleMonth),
                      (i) => DropdownMenuItem<int>(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _filterSingleDay = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('ምስባክ'),
                    icon: Icon(Icons.menu_book_rounded, size: 16),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('ስንክሳር'),
                    icon: Icon(Icons.auto_stories_rounded, size: 16),
                  ),
                ],
                selected: {_singleDayTab},
                onSelectionChanged: (set) {
                  setState(() => _singleDayTab = set.first);
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _singleDayTab == 0
                  ? _buildSingleDayResult(
                      context,
                      theme,
                      _selectedYear,
                      _filterSingleMonth,
                      _filterSingleDay,
                      perms,
                    )
                  : DayNotesSheet(
                      selectedDate: EtDatetime(
                        year: _selectedYear,
                        month: _filterSingleMonth,
                        day: _filterSingleDay,
                      ),
                      isEmbedded: true,
                    ),
            ),
          ] else ...[
            // Range pickers
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('ከ፡', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _rangeStartMonth,
                            decoration: const InputDecoration(
                              labelText: 'ወር',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            items: List.generate(13, (i) {
                              final m = i + 1;
                              return DropdownMenuItem<int>(
                                value: m,
                                child: Text(EthiopianCalendarUtil.getMonthName(m), style: const TextStyle(fontSize: 13)),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) setState(() => _rangeStartMonth = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: DropdownButtonFormField<int>(
                            initialValue: _rangeStartDay,
                            decoration: const InputDecoration(
                              labelText: 'ቀን',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            items: List.generate(30, (i) => DropdownMenuItem<int>(value: i + 1, child: Text('${i + 1}'))),
                            onChanged: (val) {
                              if (val != null) setState(() => _rangeStartDay = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('እስከ፡', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _rangeEndMonth,
                            decoration: const InputDecoration(
                              labelText: 'ወር',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            items: List.generate(13, (i) {
                              final m = i + 1;
                              return DropdownMenuItem<int>(
                                value: m,
                                child: Text(EthiopianCalendarUtil.getMonthName(m), style: const TextStyle(fontSize: 13)),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) setState(() => _rangeEndMonth = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: DropdownButtonFormField<int>(
                            initialValue: _rangeEndDay,
                            decoration: const InputDecoration(
                              labelText: 'ቀን',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            items: List.generate(30, (i) => DropdownMenuItem<int>(value: i + 1, child: Text('${i + 1}'))),
                            onChanged: (val) {
                              if (val != null) setState(() => _rangeEndDay = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 0,
                          label: Text('ስንክሳር'),
                          icon: Icon(Icons.auto_stories_rounded, size: 16),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          label: Text('ምስባክ'),
                          icon: Icon(Icons.menu_book_rounded, size: 16),
                        ),
                        ButtonSegment<int>(
                          value: 2,
                          label: Text('ሁሉም'),
                          icon: Icon(Icons.apps_rounded, size: 16),
                        ),
                      ],
                      selected: {_rangeType},
                      onSelectionChanged: (set) {
                        setState(() => _rangeType = set.first);
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        onPressed: () => setState(() => _rangeSearched = true),
                        icon: const Icon(Icons.search, size: 18),
                        label: Text(
                          _rangeType == 0
                              ? 'ስንክሳር ፈልግ'
                              : (_rangeType == 1 ? 'ምስባካትን ፈልግ' : 'ሁሉንም ፈልግ'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _rangeType == 0
                  ? _buildSynaxariumRangeView(
                      context: context,
                      theme: theme,
                      perms: perms,
                      startYear: _selectedYear,
                      startMonth: _rangeStartMonth,
                      startDay: _rangeStartDay,
                      endYear: _selectedYear,
                      endMonth: _rangeEndMonth,
                      endDay: _rangeEndDay,
                      searched: _rangeSearched,
                    )
                  : (_rangeType == 1
                      ? _buildRangeResult(context, theme, perms)
                      : _buildCombinedRangeResult(context, theme, perms)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleDayResult(
    BuildContext context,
    ThemeData theme,
    int year,
    int month,
    int day,
    AdminPermissions perms,
  ) {
    final notesAsync = ref.watch(
      calendarNotesForDateProvider((
        year: year,
        month: month,
        day: day,
      )),
    );

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('ስህተት: $err')),
      data: (notes) {
        if (notes.isEmpty) {
          final mName = EthiopianCalendarUtil.getMonthName(month);
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined, size: 40, color: theme.colorScheme.outline),
                const SizedBox(height: 10),
                Text(
                  'ለ$mName $day የተመዘገበ ምስባክ የለም',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                  ),
                ),
                if (perms.canManageCalendar) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ManageMesbakDialog.show(
                        context,
                        prefillYear: year,
                        prefillMonth: month,
                        prefillDay: day,
                      ).then((_) => _refreshAll());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('ምስባክ መዝግብ'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return _buildMesbakCard(
              context: context,
              theme: theme,
              note: notes[index],
              isToday: false,
              perms: perms,
            );
          },
        );
      },
    );
  }

  Widget _buildRangeResult(BuildContext context, ThemeData theme, AdminPermissions perms) {
    if (!_rangeSearched) {
      return Center(
        child: Text(
          'ክልሉን መርጠው "ምስባካትን ፈልግ" የሚለውን ይጫኑ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
          ),
        ),
      );
    }

    final rangeAsync = ref.watch(
      calendarNotesForRangeProvider((
        startYear: _selectedYear,
        startMonth: _rangeStartMonth,
        startDay: _rangeStartDay,
        endYear: _selectedYear,
        endMonth: _rangeEndMonth,
        endDay: _rangeEndDay,
        from: null,
        to: null,
      )),
    );

    return rangeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('ስህተት: $err')),
      data: (notes) {
        final mesbaks = notes.where((n) => n.category == 'MESBAK').toList();
        if (mesbaks.isEmpty) {
          return Center(
            child: Text(
              'በተመረጠው ክልል ውስጥ የተመዘገበ ምስባክ አልተገኘም',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: mesbaks.length,
          itemBuilder: (context, index) {
            return _buildMesbakCard(
              context: context,
              theme: theme,
              note: mesbaks[index],
              isToday: false,
              perms: perms,
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SYNAXARIUM RANGE VIEW & ITEMS
  // ─────────────────────────────────────────────────────────────
  Widget _buildSynaxariumRangeView({
    required BuildContext context,
    required ThemeData theme,
    required AdminPermissions perms,
    required int startYear,
    required int startMonth,
    required int startDay,
    required int endYear,
    required int endMonth,
    required int endDay,
    required bool searched,
  }) {
    if (!searched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'የቀናት ክልሉን መርጠው "ስንክሳር ፈልግ" የሚለውን ይጫኑ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final rangeAsync = ref.watch(
      calendarNotesForRangeProvider((
        startYear: startYear,
        startMonth: startMonth,
        startDay: startDay,
        endYear: endYear,
        endMonth: endMonth,
        endDay: endDay,
        from: null,
        to: null,
      )),
    );

    return rangeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('ስህተት: $err'),
        ),
      ),
      data: (allNotes) {
        // Filter to notes that are Synaxarium / day notes (not MESBAK)
        final synaxNotes = allNotes.where((n) => n.category != 'MESBAK').toList();

        if (synaxNotes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 48,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'በተመረጠው የቀናት ክልል ውስጥ የተመዘገበ ስንክሳር አልተገኘም',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Group notes by date
        final Map<String, List<CalendarNoteModel>> grouped = {};
        for (final note in synaxNotes) {
          final key = '${note.ethiopianYear}-${note.ethiopianMonth}-${note.ethiopianDay}';
          grouped.putIfAbsent(key, () => []).add(note);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: grouped.keys.length,
          itemBuilder: (context, index) {
            final key = grouped.keys.elementAt(index);
            final dayNotes = grouped[key]!;
            final first = dayNotes.first;
            final date = EtDatetime(
              year: first.ethiopianYear,
              month: first.ethiopianMonth,
              day: first.ethiopianDay,
            );
            final isToday = date.year == _today.year && date.month == _today.month && date.day == _today.day;
            final weekday = EthiopianCalendarUtil.getWeekdayName(date.weekday);
            final monthName = EthiopianCalendarUtil.getMonthName(date.month);

            return Card(
              elevation: isToday ? 2.5 : 1,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  width: isToday ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$weekday፣ ${date.day} $monthName ${date.year}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: isToday
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onPrimaryContainer,
                              fontFamilyFallback: const [
                                'Noto Serif Ethiopic',
                                'Noto Sans Ethiopic',
                              ],
                            ),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ዛሬ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '${dayNotes.length} ስንክሳር',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Notes for this day
                    for (int i = 0; i < dayNotes.length; i++) ...[
                      if (i > 0) const Divider(height: 16),
                      _buildSynaxNoteItem(context, theme, dayNotes[i], date, perms),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSynaxNoteItem(
    BuildContext context,
    ThemeData theme,
    CalendarNoteModel note,
    EtDatetime date,
    AdminPermissions perms,
  ) {
    final hasTitle = note.title != null && note.title!.trim().isNotEmpty;
    final hasContent = note.content != null && note.content!.trim().isNotEmpty;
    final hasMedia = note.media.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTitle) ...[
          Text(
            note.title!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontFamilyFallback: const [
                'Noto Serif Ethiopic',
                'Noto Sans Ethiopic',
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (hasContent) ...[
          Text(
            note.content!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              fontFamilyFallback: const [
                'Noto Serif Ethiopic',
                'Noto Sans Ethiopic',
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Media thumbnail strip
        if (hasMedia) ...[
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: note.media.length,
              itemBuilder: (ctx, mIdx) {
                final media = note.media[mIdx];
                final rawUrl = media.file?['url'] as String?;
                final resolved = MediaUrlResolver.resolve(rawUrl);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: resolved != null
                        ? AppNetworkImage(
                            imageUrl: resolved,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.attachment, size: 20),
                          ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/calendar/note/${note.id}');
              },
              icon: const Icon(Icons.chrome_reader_mode_outlined, size: 15),
              label: const Text('ሙሉውን አንብብ', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              tooltip: 'ቅዳ',
              visualDensity: VisualDensity.compact,
              onPressed: () => _copyNoteToClipboard(context, note),
            ),
            if (perms.canManageCalendar) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 17),
                tooltip: 'አስተካክል',
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddNoteSheet(selectedDate: date, existingNote: note),
                  );
                  _refreshAll();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 17, color: Colors.red),
                tooltip: 'ሰርዝ',
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmDeleteSynaxNote(context, note),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCombinedRangeResult(BuildContext context, ThemeData theme, AdminPermissions perms) {
    if (!_rangeSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'የቀናት ክልሉን መርጠው "ሁሉንም ፈልግ" የሚለውን ይጫኑ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
            ),
          ),
        ),
      );
    }

    final rangeAsync = ref.watch(
      calendarNotesForRangeProvider((
        startYear: _selectedYear,
        startMonth: _rangeStartMonth,
        startDay: _rangeStartDay,
        endYear: _selectedYear,
        endMonth: _rangeEndMonth,
        endDay: _rangeEndDay,
        from: null,
        to: null,
      )),
    );

    return rangeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('ስህተት: $err')),
      data: (allNotes) {
        if (allNotes.isEmpty) {
          return Center(
            child: Text(
              'በተመረጠው ክልል ውስጥ የተመዘገበ ምስባክ ወይም ስንክሳር አልተገኘም',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: allNotes.length,
          itemBuilder: (context, index) {
            final note = allNotes[index];
            final isMesbak = note.category == 'MESBAK';
            if (isMesbak) {
              return _buildMesbakCard(
                context: context,
                theme: theme,
                note: note,
                isToday: false,
                perms: perms,
              );
            }
            final date = EtDatetime(
              year: note.ethiopianYear,
              month: note.ethiopianMonth,
              day: note.ethiopianDay,
            );
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ስንክሳር • ${note.ethiopianDay} ${EthiopianCalendarUtil.getMonthName(note.ethiopianMonth)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: theme.colorScheme.onTertiaryContainer,
                              fontFamilyFallback: const ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSynaxNoteItem(context, theme, note, date, perms),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteSynaxNote(BuildContext context, CalendarNoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ስንክሳር ሰርዝ'),
        content: Text('ይህንን ስንክሳር (${note.title ?? "ማስታወሻ"}) መሰረዝ ይፈልጋሉ? ይህ ድርጊት አይመለስም።'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ይቅር'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ሰርዝ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deleteNote = ref.read(deleteCalendarNoteProvider);
        await deleteNote(note.id);
        _refreshAll();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ስንክሳሩ ተሰርዟል')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ስህተት ተከስቷል: $e')),
          );
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REUSABLE MESBAK CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildMesbakCard({
    required BuildContext context,
    required ThemeData theme,
    required CalendarNoteModel note,
    required bool isToday,
    required AdminPermissions perms,
  }) {
    final monthName = EthiopianCalendarUtil.getMonthName(note.ethiopianMonth);

    return Card(
      elevation: isToday ? 2.5 : 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isToday
              ? const Color(0xFFD4AF37)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isToday ? 1.8 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book, size: 14, color: Color(0xFF8C6B00)),
                      const SizedBox(width: 6),
                      Text(
                        '$monthName ${note.ethiopianDay}፣ ${note.ethiopianYear}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF6B5100),
                          fontFamilyFallback: ['Noto Serif Ethiopic', 'Noto Sans Ethiopic'],
                        ),
                      ),
                    ],
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
                      'ዛሬ',
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
                  icon: const Icon(Icons.copy_rounded, size: 19),
                  tooltip: 'ቅዳ',
                  onPressed: () => _copyNoteToClipboard(context, note),
                ),
                if (perms.canManageCalendar)
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary),
                    tooltip: 'አስተካክል',
                    onPressed: () {
                      ManageMesbakDialog.show(
                        context,
                        existingNote: note,
                        prefillYear: note.ethiopianYear,
                        prefillMonth: note.ethiopianMonth,
                        prefillDay: note.ethiopianDay,
                      ).then((_) => _refreshAll());
                    },
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            if (note.title != null && note.title!.isNotEmpty) ...[
              Text(
                note.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Content (Psalm text & translation)
            if (note.content != null && note.content!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: SelectableText(
                  note.content!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.65,
                    fontSize: 15,
                    fontFamilyFallback: const [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyNoteToClipboard(BuildContext context, CalendarNoteModel note) {
    final buffer = StringBuffer();
    if (note.title != null && note.title!.isNotEmpty) {
      buffer.writeln(note.title);
      buffer.writeln();
    }
    if (note.content != null && note.content!.isNotEmpty) {
      buffer.writeln(note.content);
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ምስባኩ ወደ ቅንጥብ ሰሌዳ ተቀድቷል'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
