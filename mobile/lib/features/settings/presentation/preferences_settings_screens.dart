import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsState = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.appearance'))),
      body: RadioGroup<ThemeMode>(
        groupValue: prefsState.themeMode,
        onChanged: (mode) => prefsNotifier.setThemeMode(mode!),
        child: ListView(
          children: const [
            RadioListTile<ThemeMode>(
              title: Text('System Default'),
              value: ThemeMode.system,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Light Mode'),
              value: ThemeMode.light,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Dark Mode'),
              value: ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsState = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.language'))),
      body: RadioGroup<String>(
        groupValue: prefsState.languageCode,
        onChanged: (code) => prefsNotifier.setLanguageCode(code!),
        child: ListView(
          children: const [
            RadioListTile<String>(title: Text('English'), value: 'en'),
            RadioListTile<String>(title: Text('አማርኛ'), value: 'am'),
            RadioListTile<String>(title: Text('ግእዝ'), value: 'gez'),
          ],
        ),
      ),
    );
  }
}
