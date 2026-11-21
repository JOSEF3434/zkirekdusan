// lib/features/home/presentation/widgets/today_mesbak_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/presentation/widgets/mesbak_popup_dialog.dart';

class TodayMesbakButton extends ConsumerWidget {
  const TodayMesbakButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return Container(
      width: 76,
      margin: const EdgeInsets.only(left: 4, right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: tr('calendar.today_mesbak', {'fallback': 'የእለቱ ምስባክ'}),
            child: InkWell(
              onTap: () {
                final now = EthiopianCalendarUtil.now();
                ref.read(sharedPreferencesProvider).setString(
                  'last_seen_mesbak_date',
                  '${now.year}-${now.month}-${now.day}',
                );
                MesbakPopupDialog.show(context);
              },
              borderRadius: BorderRadius.circular(34),
              child: Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFDF7A),
                      Color(0xFFE5A93C),
                      Color(0xFFB8860B),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB8860B).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                              theme.colorScheme.surface,
                            ],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.menu_book_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            tr('calendar.today_mesbak', {'fallback': 'የእለቱ ምስባክ'}),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              color: theme.colorScheme.onSurface,
              fontFamilyFallback: const [
                'Noto Serif Ethiopic',
                'Noto Sans Ethiopic',
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
