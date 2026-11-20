// lib/features/calendar/presentation/yearly_fasts_holidays_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_events_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/calendar_event_details_dialog.dart';

class YearlyFastsHolidaysScreen extends ConsumerStatefulWidget {
  final int initialYear;

  const YearlyFastsHolidaysScreen({
    super.key,
    required this.initialYear,
  });

  @override
  ConsumerState<YearlyFastsHolidaysScreen> createState() =>
      _YearlyFastsHolidaysScreenState();
}

class _YearlyFastsHolidaysScreenState
    extends ConsumerState<YearlyFastsHolidaysScreen> {
  late int _selectedYear;
  int _selectedFilterIndex = 0; // 0 = All, 1 = Fasts, 2 = Holidays

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final eventsAsync = ref.watch(calendarEventsForYearProvider(_selectedYear));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('calendar.yearly_title', {'fallback': 'የዓመቱ አጽዋማት እና በዓላት'}),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamilyFallback: [
              'Noto Serif Ethiopic',
              'Noto Sans Ethiopic',
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Year Navigator Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous Year',
                      onPressed: () {
                        setState(() {
                          _selectedYear -= 1;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$_selectedYear ዓ.ም',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontFamilyFallback: const [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next Year',
                      onPressed: () {
                        setState(() {
                          _selectedYear += 1;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Filter Chips: All, Fasts, Wed & Fri, Major Holidays, Saints
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(tr('calendar.all_events', {'fallback': 'ሁሉም'})),
                      selected: _selectedFilterIndex == 0,
                      onSelected: (_) => setState(() => _selectedFilterIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFF59E0B)),
                      label: Text(tr('calendar.only_fasts', {'fallback': 'አጽዋማት'})),
                      selected: _selectedFilterIndex == 1,
                      onSelected: (_) => setState(() => _selectedFilterIndex = 1),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFD97706)),
                      label: Text(tr('calendar.wed_fri_fasts', {'fallback': 'ረቡዕና ዓርብ ጾም'})),
                      selected: _selectedFilterIndex == 2,
                      onSelected: (_) => setState(() => _selectedFilterIndex = 2),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.star_rounded, size: 16, color: Color(0xFFDC2626)),
                      label: Text(tr('calendar.major_holidays', {'fallback': 'ዐበይት በዓላት'})),
                      selected: _selectedFilterIndex == 3,
                      onSelected: (_) => setState(() => _selectedFilterIndex = 3),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF16A34A)),
                      label: Text(tr('calendar.saints_feasts', {'fallback': 'የቅዱሳን በዓላት'})),
                      selected: _selectedFilterIndex == 4,
                      onSelected: (_) => setState(() => _selectedFilterIndex = 4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('${tr('common.error')}: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(calendarEventsForYearProvider(_selectedYear));
                },
                child: Text(tr('common.retry', {'fallback': 'እንደገና ሞክር'})),
              ),
            ],
          ),
        ),
        data: (allEvents) {
          final filtered = allEvents.where((e) {
            if (_selectedFilterIndex == 1) {
              // Fasts except the recurring wed-fri rule
              return e.isFast && !e.name.contains('የረቡዕ እና የዓርብ');
            }
            if (_selectedFilterIndex == 2) {
              // Wed & Fri fast rule
              return e.name.contains('የረቡዕ እና የዓርብ');
            }
            if (_selectedFilterIndex == 3) {
              // Major holidays
              return e.isHoliday && (e.isMajorHoliday || e.isMajor);
            }
            if (_selectedFilterIndex == 4) {
              // Saints and other religious commemorations
              return (e.isHoliday && !e.isMajorHoliday) || e.isSpecialEvent;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr(
                    'calendar.no_events_this_month',
                    {'fallback': 'በዚህ ዓመት የተመዘገበ ዝርዝር የለም'},
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    fontFamilyFallback: const [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                ),
              ),
            );
          }

          // Group by starting month (1-13)
          final Map<int, List<CalendarEventModel>> grouped = {};
          for (final event in filtered) {
            grouped.putIfAbsent(event.startMonth, () => []).add(event);
          }

          final sortedMonths = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sortedMonths.length,
            itemBuilder: (context, idx) {
              final month = sortedMonths[idx];
              final monthEvents = grouped[month]!;
              final monthName = EthiopianCalendarUtil.getMonthName(month);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Header
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          monthName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontFamilyFallback: const [
                              'Noto Serif Ethiopic',
                              'Noto Sans Ethiopic',
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${monthEvents.length})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cards for each event in this month
                  ...monthEvents.map((event) => _buildEventCard(context, theme, tr, event)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    ThemeData theme,
    String Function(String, [Map<String, dynamic>?]) tr,
    CalendarEventModel event,
  ) {
    final eventColor = _parseColor(event.effectiveColorHex) ??
        (event.isFast
            ? const Color(0xFFF59E0B)
            : (event.isMajor ? const Color(0xFFDC2626) : const Color(0xFF16A34A)));

    final isWedFri = event.id.contains('wed-fri') ||
        event.name.contains('ድኅነት') ||
        event.name.contains('የረቡዕ እና የዓርብ') ||
        (event.nameEn != null && event.nameEn!.contains('Wednesday & Friday'));

    String dateRangeStr = '';
    if (isWedFri) {
      dateRangeStr = 'ዓመቱን ሙሉ በየሳምንቱ (ረቡዕ እና ዓርብ)';
    } else if (event.startMonth == event.endMonth) {
      if (event.startDay == event.endDay) {
        dateRangeStr =
            '${event.startDay} ${EthiopianCalendarUtil.getMonthName(event.startMonth)}';
      } else {
        dateRangeStr =
            'ከ ${event.startDay} - ${event.endDay} ${EthiopianCalendarUtil.getMonthName(event.startMonth)}';
      }
    } else {
      dateRangeStr =
          'ከ ${event.startDay} ${EthiopianCalendarUtil.getMonthName(event.startMonth)} እስከ ${event.endDay} ${EthiopianCalendarUtil.getMonthName(event.endMonth)}';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: InkWell(
        onTap: () {
          CalendarEventDetailsDialog.show(
            context,
            event: event,
            selectedYear: _selectedYear,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      event.isFast
                          ? Icons.hourglass_top_rounded
                          : (event.isMajor
                              ? Icons.stars_rounded
                              : Icons.celebration_rounded),
                      color: eventColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamilyFallback: const [
                              'Noto Serif Ethiopic',
                              'Noto Sans Ethiopic',
                            ],
                          ),
                        ),
                        if (event.nameEn != null && event.nameEn!.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            event.nameEn!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isWedFri)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ሳምንታዊ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: eventColor,
                        ),
                      ),
                    )
                  else if (event.durationDays > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${event.durationDays} ቀናት',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: eventColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 15,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dateRangeStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  event.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.8),
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
      ),
    );
  }

  Color? _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return null;
  }
}
