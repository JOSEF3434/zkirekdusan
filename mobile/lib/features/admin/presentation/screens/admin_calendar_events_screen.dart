// lib/features/admin/presentation/screens/admin_calendar_events_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_confirmation_dialog.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_search_bar.dart';
import 'package:mobile/features/admin/presentation/widgets/manage_calendar_event_dialog.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_events_provider.dart';

class AdminCalendarEventsScreen extends ConsumerStatefulWidget {
  const AdminCalendarEventsScreen({super.key});

  @override
  ConsumerState<AdminCalendarEventsScreen> createState() =>
      _AdminCalendarEventsScreenState();
}

class _AdminCalendarEventsScreenState
    extends ConsumerState<AdminCalendarEventsScreen> {
  String _searchQuery = '';
  int _selectedTypeIndex = 0; // 0 = All, 1 = Fasts, 2 = Holidays

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final eventsState = ref.watch(adminCalendarEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('admin.calendar_events', {'fallback': 'የአጽዋማትና በዓላት አስተዳደር'}),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamilyFallback: [
              'Noto Serif Ethiopic',
              'Noto Sans Ethiopic',
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: tr('common.retry', {'fallback': 'አድስ'}),
            onPressed: () {
              ref.read(adminCalendarEventsProvider.notifier).loadEvents();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ManageCalendarEventDialog.show(context);
        },
        icon: const Icon(Icons.add),
        label: Text(
          tr('admin.add_event', {'fallback': 'አዲስ መዝግብ'}),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamilyFallback: [
              'Noto Serif Ethiopic',
              'Noto Sans Ethiopic',
            ],
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
                hintText: 'በስም ወይም በመግለጫ ፈልግ...',
                onSearch: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ),

            // Filter Chips & Month selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(tr('calendar.all_events', {'fallback': 'ሁሉም'})),
                      selected: _selectedTypeIndex == 0,
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedTypeIndex = 0);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(tr('calendar.only_fasts', {'fallback': 'አጽዋማት'})),
                      selected: _selectedTypeIndex == 1,
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedTypeIndex = 1);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(tr('calendar.only_holidays', {'fallback': 'በዓላት'})),
                      selected: _selectedTypeIndex == 2,
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedTypeIndex = 2);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(tr('calendar.only_special_events', {'fallback': 'ልዩ ክስተቶች'})),
                      selected: _selectedTypeIndex == 3,
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedTypeIndex = 3);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Events List
            Expanded(
              child: eventsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${tr('common.error')}: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(adminCalendarEventsProvider.notifier)
                              .loadEvents();
                        },
                        child: Text(tr('common.retry', {'fallback': 'እንደገና ሞክር'})),
                      ),
                    ],
                  ),
                ),
                data: (events) {
                  final filtered = events.where((e) {
                    if (_selectedTypeIndex == 1 && !e.isFast) return false;
                    if (_selectedTypeIndex == 2 && !e.isHoliday) return false;
                    if (_selectedTypeIndex == 3 && !e.isSpecialEvent) return false;
                    if (_searchQuery.isNotEmpty) {
                      final matchName =
                          e.name.toLowerCase().contains(_searchQuery);
                      final matchEn = e.nameEn?.toLowerCase().contains(_searchQuery) ?? false;
                      final matchDesc = e.description?.toLowerCase().contains(_searchQuery) ?? false;
                      return matchName || matchEn || matchDesc;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'ምንም የተመዘገበ በዓል ወይም ጾም አልተገኘም',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(adminCalendarEventsProvider.notifier)
                          .loadEvents();
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final event = filtered[index];
                        return _buildAdminCard(context, theme, tr, event);
                      },
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

  Widget _buildAdminCard(
    BuildContext context,
    ThemeData theme,
    String Function(String, [Map<String, dynamic>?]) tr,
    CalendarEventModel event,
  ) {
    final eventColor = _parseColor(event.effectiveColorHex) ??
        (event.isFast
            ? const Color(0xFFF59E0B)
            : (event.isMajorHoliday ? const Color(0xFFDC2626) : const Color(0xFF16A34A)));

    String dateStr = '';
    if (event.startMonth == event.endMonth) {
      if (event.startDay == event.endDay) {
        dateStr =
            '${event.startDay} ${EthiopianCalendarUtil.getMonthName(event.startMonth)}';
      } else {
        dateStr =
            'ከ ${event.startDay} - ${event.endDay} ${EthiopianCalendarUtil.getMonthName(event.startMonth)}';
      }
    } else {
      dateStr =
          'ከ ${event.startDay} ${EthiopianCalendarUtil.getMonthName(event.startMonth)} እስከ ${event.endDay} ${EthiopianCalendarUtil.getMonthName(event.endMonth)}';
    }

    final yearTag = event.isRecurring
        ? 'በየዓመቱ (Recurring)'
        : '${event.ethiopianYear ?? ""} ዓ.ም';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
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
                      if (event.nameEn != null && event.nameEn!.isNotEmpty)
                        Text(
                          event.nameEn!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                ),
                // Active status toggle switch
                Switch(
                  value: event.isActive,
                  onChanged: (val) {
                    ref
                        .read(adminCalendarEventsProvider.notifier)
                        .toggleStatus(event.id);
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(
                    event.isFast ? 'ጾም' : 'በዓል',
                    style: TextStyle(
                      fontSize: 11,
                      color: eventColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: eventColor.withValues(alpha: 0.1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                Chip(
                  label: Text(
                    yearTag,
                    style: const TextStyle(fontSize: 11),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                if (event.isMajor)
                  const Chip(
                    label: Text(
                      'ዓቢይ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Color(0x22F59E0B),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                if (event.durationDays > 1)
                  Chip(
                    label: Text(
                      '${event.durationDays} ቀናት',
                      style: const TextStyle(fontSize: 11),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              dateStr,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamilyFallback: const [
                  'Noto Serif Ethiopic',
                  'Noto Sans Ethiopic',
                ],
              ),
            ),

            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                event.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                ),
              ),
            ],

            const SizedBox(height: 8),
            const Divider(height: 1),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: tr('admin.edit_event', {'fallback': 'አስተካክል'}),
                  onPressed: () {
                    ManageCalendarEventDialog.show(context, event: event);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: theme.colorScheme.error),
                  tooltip: tr('admin.delete_event', {'fallback': 'ሰርዝ'}),
                  onPressed: () async {
                    final confirm = await AdminConfirmationDialog.show(
                      context,
                      title: tr('admin.delete_event', {'fallback': 'ሰርዝ'}),
                      message:
                          '${event.name} የተባለውን መዝገብ መሰረዝ ይፈልጋሉ? ይህ ድርጊት አይቀለበስም።',
                      confirmLabel: tr('common.delete', {'fallback': 'ሰርዝ'}),
                      confirmColor: theme.colorScheme.error,
                    );
                    if (confirm != null) {
                      await ref
                          .read(adminCalendarEventsProvider.notifier)
                          .deleteEvent(event.id);
                    }
                  },
                ),
              ],
            ),
          ],
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
