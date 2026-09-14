import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsState = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Text(
                          tr('app.name'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('onboarding.welcome'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          tr('settings.language'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SelectionCard(
                                title: 'English',
                                isSelected: prefsState.languageCode == 'en',
                                onTap: () =>
                                    prefsNotifier.setLanguageCode('en'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SelectionCard(
                                title: 'አማርኛ',
                                isSelected: prefsState.languageCode == 'am',
                                onTap: () =>
                                    prefsNotifier.setLanguageCode('am'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SelectionCard(
                                title: 'ግእዝ',
                                isSelected: prefsState.languageCode == 'gez',
                                onTap: () =>
                                    prefsNotifier.setLanguageCode('gez'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          tr('settings.appearance'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SelectionCard(
                                title: tr('onboarding.theme.system'),
                                icon: Icons.brightness_auto,
                                isSelected:
                                    prefsState.themeMode == ThemeMode.system,
                                onTap: () => prefsNotifier.setThemeMode(
                                  ThemeMode.system,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SelectionCard(
                                title: tr('onboarding.theme.light'),
                                icon: Icons.light_mode,
                                isSelected:
                                    prefsState.themeMode == ThemeMode.light,
                                onTap: () =>
                                    prefsNotifier.setThemeMode(ThemeMode.light),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SelectionCard(
                                title: tr('onboarding.theme.dark'),
                                icon: Icons.dark_mode,
                                isSelected:
                                    prefsState.themeMode == ThemeMode.dark,
                                onTap: () =>
                                    prefsNotifier.setThemeMode(ThemeMode.dark),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () async {
                            await prefsNotifier.completeFirstLaunch();
                            if (context.mounted) {
                              context.go('/');
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            tr('onboarding.continue'),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
