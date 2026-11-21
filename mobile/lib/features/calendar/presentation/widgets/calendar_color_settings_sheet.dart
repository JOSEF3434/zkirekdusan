// lib/features/calendar/presentation/widgets/calendar_color_settings_sheet.dart
// Modern & advanced Ethiopian calendar fasting and holiday color customization sheet with live preview and reset.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/domain/calendar_theme_colors.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_theme_colors_provider.dart';

class CalendarColorSettingsSheet extends ConsumerStatefulWidget {
  const CalendarColorSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CalendarColorSettingsSheet(),
    );
  }

  @override
  ConsumerState<CalendarColorSettingsSheet> createState() =>
      _CalendarColorSettingsSheetState();
}

class _CalendarColorSettingsSheetState
    extends ConsumerState<CalendarColorSettingsSheet> {
  // 0 = Fasting, 1 = Major Holiday, 2 = Feast & Markers
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String Function(String, [Map<String, dynamic>?]) tr;
    try {
      tr = ref.watch(trProvider);
    } catch (_) {
      tr = (key, [args]) => args?['fallback']?.toString() ?? key;
    }
    final themeColors = ref.watch(calendarThemeColorsProvider);
    final notifier = ref.read(calendarThemeColorsProvider.notifier);

    final isDefault = themeColors.isDefault;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header with Title & Reset Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColors.fastColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: themeColors.fastColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('calendar.customize_colors', {'fallback': 'የቀን መቁጠሪያ ቀለሞች'}),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(
                        'calendar.customize_colors_sub',
                        {'fallback': 'የጾም እና የበዓላት መለያ ቀለሞችን ያብጁ'},
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Reset to Default Button
              TextButton.icon(
                onPressed: isDefault
                    ? null
                    : () async {
                        await notifier.resetToDefault();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr(
                                  'calendar.colors_reset_success',
                                  {'fallback': 'የቀን መቁጠሪያ ቀለሞች ወደ ነባሪ ተመልሰዋል'},
                                ),
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: isDefault ? null : const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(
                  tr('calendar.reset_colors_default', {'fallback': 'ወደ ነባሪ'}),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Scrollable settings body
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. Live Calendar Preview Box ─────────────────────────────
                  _buildLivePreview(theme, isDark, themeColors, tr),

                  const SizedBox(height: 18),

                  // ── 2. Preset Themes Section ─────────────────────────────────
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tr(
                          'calendar.color_presets_title',
                          {'fallback': 'የተዘጋጁ የቀለም ቅንብሮች (Presets)'},
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPresetsList(themeColors, notifier),

                  const SizedBox(height: 18),

                  // ── 3. Category Selector (Segmented Button) ─────────────────
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment<int>(
                        value: 0,
                        icon: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: themeColors.fastColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        label: Text(
                          tr('calendar.color_fasting_title', {'fallback': 'ጾም'}),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        icon: Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: themeColors.holidayColor,
                        ),
                        label: Text(
                          tr('calendar.color_holiday_title', {'fallback': 'ዓቢይ በዓል'}),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        icon: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: themeColors.feastColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        label: Text(
                          tr('calendar.color_feast_title', {'fallback': 'መግቢያ/ልዩ'}),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                    selected: {_selectedCategoryIndex},
                    onSelectionChanged: (set) {
                      setState(() => _selectedCategoryIndex = set.first);
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── 4. Category Swatches & Custom Hex Picker ─────────────────
                  _buildCategorySwatchesSection(
                    context,
                    theme,
                    themeColors,
                    notifier,
                    tr,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Done Button
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              tr('common.done', {'fallback': 'ተከናውኗል'}),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Live Calendar Cell Preview displaying 3 realistic day cells
  Widget _buildLivePreview(
    ThemeData theme,
    bool isDark,
    CalendarThemeColors colors,
    String Function(String, [Map<String, dynamic>?]) tr,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151522) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                tr('calendar.preview_title', {'fallback': 'የቀን መቁጠሪያ የቀጥታ ቅድመ-ዕይታ (Live Preview)'}),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Fasting Day Preview (Day 15)
              _buildPreviewCell(
                theme: theme,
                dayNumber: '15',
                label: 'የጾም ዕለት',
                backgroundColor: colors.fastColor.withValues(alpha: isDark ? 0.05 : 0.07),
                borderColor: colors.fastColor.withValues(alpha: isDark ? 0.28 : 0.32),
                textColor: colors.getFastTextColor(isDark),
                dotColor: colors.fastColor,
              ),

              // 2. Major Holiday Preview (Day 3)
              _buildPreviewCell(
                theme: theme,
                dayNumber: '3',
                label: 'ዓቢይ በዓል',
                backgroundColor: Colors.transparent,
                borderColor: null,
                textColor: theme.textTheme.bodyLarge?.color,
                badgeWidget: Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: colors.holidayColor,
                ),
                dotColor: colors.fastColor, // fasting + holiday overlay dot
              ),

              // 3. Fast Ending / Season Marker Preview (Day 28)
              _buildPreviewCell(
                theme: theme,
                dayNumber: '28',
                label: 'ጾም መጨረሻ',
                backgroundColor: colors.fastColor.withValues(alpha: isDark ? 0.05 : 0.07),
                borderColor: colors.fastColor.withValues(alpha: isDark ? 0.28 : 0.32),
                textColor: colors.getFastTextColor(isDark),
                badgeWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: colors.feastColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'መጨረሻ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 6.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                dotColor: colors.feastColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCell({
    required ThemeData theme,
    required String dayNumber,
    required String label,
    required Color backgroundColor,
    required Color? borderColor,
    required Color? textColor,
    Widget? badgeWidget,
    Color? dotColor,
  }) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1)
                : Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
          ),
          child: Stack(
            children: [
              if (badgeWidget != null)
                Positioned(
                  top: 2,
                  left: 2,
                  child: badgeWidget,
                ),
              Center(
                child: Text(
                  dayNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              if (dotColor != null)
                Positioned(
                  bottom: 3,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 4.5,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// Preset Themes Horizontal Selector
  Widget _buildPresetsList(
    CalendarThemeColors currentColors,
    CalendarThemeColorsNotifier notifier,
  ) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CalendarThemeColors.presets.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final preset = CalendarThemeColors.presets[index];
          final isSelected =
              currentColors.fastColorHex.toUpperCase() ==
                  preset.fastColorHex.toUpperCase() &&
              currentColors.holidayColorHex.toUpperCase() ==
                  preset.holidayColorHex.toUpperCase() &&
              currentColors.feastColorHex.toUpperCase() ==
                  preset.feastColorHex.toUpperCase();

          return InkWell(
            onTap: () => notifier.applyPreset(preset),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 140,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF59E0B)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Fasting color circle
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: preset.fastColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Holiday color circle
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: preset.holidayColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Feast color circle
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: preset.feastColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: Color(0xFFF59E0B),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Swatches & Custom Hex Picker for the active category
  Widget _buildCategorySwatchesSection(
    BuildContext context,
    ThemeData theme,
    CalendarThemeColors colors,
    CalendarThemeColorsNotifier notifier,
    String Function(String, [Map<String, dynamic>?]) tr,
  ) {
    late String currentHex;
    late List<String> swatches;
    late String categoryDescription;
    late void Function(String) onColorSelected;

    switch (_selectedCategoryIndex) {
      case 0:
        currentHex = colors.fastColorHex;
        swatches = CalendarThemeColors.availableFastColors;
        categoryDescription =
            'በቀን መቁጠሪያው ላይ ለሚታዩ አጽዋማት (ባለቀለም ዳራ፣ ድንበር እና ክብ ነጥብ) የሚውል መለያ ቀለም';
        onColorSelected = notifier.setFastColor;
        break;
      case 1:
        currentHex = colors.holidayColorHex;
        swatches = CalendarThemeColors.availableHolidayColors;
        categoryDescription =
            'ለዓበይት በዓላት (ቀይ ኮከብ እና የበዓል መለያ ነጥብ) የሚውል ቀለም';
        onColorSelected = notifier.setHolidayColor;
        break;
      case 2:
      default:
        currentHex = colors.feastColorHex;
        swatches = CalendarThemeColors.availableFeastColors;
        categoryDescription =
            'የጾም መግቢያ፣ መጨረሻ (ባጅ) እና ልዩ በዓላት መለያ የሚውል ቀለም';
        onColorSelected = notifier.setFeastColor;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 12),

        // Swatches Grid
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: swatches.map((hex) {
            final color = CalendarThemeColors.parseHex(hex, Colors.grey);
            final isSelected = hex.toUpperCase() == currentHex.toUpperCase();

            return GestureDetector(
              onTap: () => onColorSelected(hex),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // Custom Hex Code Row
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showCustomHexDialog(
                context,
                initialHex: currentHex,
                onHexConfirmed: onColorSelected,
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.colorize_rounded, size: 16),
              label: Text(
                'ብጁ ሄክስ ቀለም (#HEX)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'የአሁኑ፡ $currentHex',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Dialog allowing users to type any valid custom 6-digit hex code
  void _showCustomHexDialog(
    BuildContext context, {
    required String initialHex,
    required void Function(String) onHexConfirmed,
  }) {
    final controller = TextEditingController(text: initialHex.replaceAll('#', ''));
    Color previewColor = CalendarThemeColors.parseHex(initialHex, Colors.amber);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('ብጁ ሄክስ ቀለም (Hex Code)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: previewColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          maxLength: 6,
                          autofocus: true,
                          decoration: const InputDecoration(
                            prefixText: '# ',
                            labelText: 'የቀለም ኮድ (e.g. FF8800)',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          onChanged: (val) {
                            if (val.trim().length == 6) {
                              try {
                                final c = Color(
                                  int.parse('FF${val.trim()}', radix: 16),
                                );
                                setDlgState(() => previewColor = c);
                              } catch (_) {}
                            }
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
                    final clean = controller.text.replaceAll('#', '').trim();
                    if (clean.length == 6) {
                      onHexConfirmed('#${clean.toUpperCase()}');
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('ተግብር'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
