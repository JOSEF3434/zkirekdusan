// lib/features/calendar/presentation/widgets/monthly_fasts_holidays_summary.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_events_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/calendar_event_details_dialog.dart';

class MonthlyFastsHolidaysSummary extends ConsumerWidget {
  final int year;
  final int month;

  const MonthlyFastsHolidaysSummary({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final eventsAsync = ref.watch(
      calendarEventsForMonthProvider((year: year, month: month)),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.event_note_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(
                          'calendar.fasts_and_holidays',
                          {'fallback': 'የዚህ ወር አጽዋማት እና በዓላት'},
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamilyFallback: const [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                      Text(
                        '${EthiopianCalendarUtil.getMonthName(month)} $year',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                          fontFamilyFallback: const [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Events List or States
          eventsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tr('common.error')}: $err',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
            data: (events) {
              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          size: 32,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                            'calendar.no_events_this_month',
                            {'fallback': 'በዚህ ወር የተመዘገበ ጾም ወይም በዓል የለም'},
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                            fontFamilyFallback: const [
                              'Noto Serif Ethiopic',
                              'Noto Sans Ethiopic',
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: events.length,
                separatorBuilder: (_, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventTile(context, theme, tr, event);
                },
              );
            },
          ),

          const Divider(height: 1),

          // Footer Button: View All Fasts & Holidays of the Year
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_view_month_rounded, size: 18),
                label: Text(
                  tr(
                    'calendar.view_all_yearly_events',
                    {'fallback': 'የዓመቱ አጽዋማትና በዓላት በሙሉ'},
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  context.push('/calendar/yearly-events?year=$year');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(
    BuildContext context,
    ThemeData theme,
    String Function(String, [Map<String, dynamic>?]) tr,
    CalendarEventModel event,
  ) {
    final eventColor = _parseColor(event.primaryColor) ??
        (event.isFast
            ? Colors.purple.shade700
            : (event.isMajor ? Colors.amber.shade800 : Colors.teal.shade700));

    final isStartInThisMonth =
        event.coverage?.isStartMonth ?? (event.startMonth == month);
    final isEndInThisMonth =
        event.coverage?.isEndMonth ?? (event.endMonth == month);

    String dateSubtitle = '';
    if (event.startMonth == event.endMonth) {
      if (event.startDay == event.endDay) {
        dateSubtitle = '${event.startDay} ${EthiopianCalendarUtil.getMonthName(month)}';
      } else {
        dateSubtitle =
            'ከ ${event.startDay} - ${event.endDay} ${EthiopianCalendarUtil.getMonthName(month)}';
      }
    } else {
      final startM = EthiopianCalendarUtil.getMonthName(event.startMonth);
      final endM = EthiopianCalendarUtil.getMonthName(event.endMonth);
      dateSubtitle = 'ከ ${event.startDay} $startM እስከ ${event.endDay} $endM';
    }

    String? multiMonthNote;
    if (event.startMonth != event.endMonth) {
      if (isStartInThisMonth && !isEndInThisMonth) {
        multiMonthNote =
            'ይህ ጾም እስከ ${EthiopianCalendarUtil.getMonthName(event.endMonth)} ${event.endDay} ይቀጥላል';
      } else if (!isStartInThisMonth && isEndInThisMonth) {
        multiMonthNote =
            'ከ ${EthiopianCalendarUtil.getMonthName(event.startMonth)} ${event.startDay} የቀጠለ';
      } else if (!isStartInThisMonth && !isEndInThisMonth) {
        multiMonthNote = 'በዚህ ወር ሙሉ የሚቀጥል';
      }
    }

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          CalendarEventDetailsDialog.show(
            context,
            event: event,
            selectedMonth: month,
            selectedYear: year,
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: eventColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamilyFallback: const [
                                'Noto Serif Ethiopic',
                                'Noto Sans Ethiopic',
                              ],
                            ),
                          ),
                        ),
                        if (event.durationDays > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: eventColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${event.durationDays} ቀናት',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: eventColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.8),
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                    if (multiMonthNote != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        multiMonthNote,
                        style: TextStyle(
                          fontSize: 11,
                          color: eventColor,
                          fontWeight: FontWeight.w500,
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
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
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
