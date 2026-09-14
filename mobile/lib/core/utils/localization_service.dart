import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';

final localizationServiceProvider = Provider<LocalizationService>((ref) {
  throw UnimplementedError('localizationServiceProvider must be initialized');
});

class LocalizationService {
  final Map<String, Map<String, dynamic>> _localizedStrings = {};
  String _currentLang = 'en';

  LocalizationService();

  Future<void> init() async {
    final jsonString = await rootBundle.loadString(
      'assets/lang/language_togle.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    jsonMap.forEach((key, value) {
      _localizedStrings[key] = value as Map<String, dynamic>;
    });
  }

  void updateLanguage(String langCode) {
    if (_localizedStrings.containsKey(langCode)) {
      _currentLang = langCode;
    }
  }

  String translate(String key, [Map<String, dynamic>? args]) {
    String text = '';
    final langMap = _localizedStrings[_currentLang];
    if (langMap != null && langMap.containsKey(key)) {
      final val = langMap[key]?.toString() ?? '';
      if (val.isNotEmpty) {
        text = val;
      }
    }
    // Fallback to english if value is missing or empty (specifically for Ge'ez)
    if (text.isEmpty) {
      final enMap = _localizedStrings['en'];
      if (enMap != null && enMap.containsKey(key)) {
        text = enMap[key]?.toString() ?? key;
      } else {
        text = key;
      }
    }
    if (args != null && args.isNotEmpty) {
      args.forEach((k, v) {
        text = text.replaceAll('{$k}', v.toString());
      });
    }
    return text;
  }
}

// Global helper for easiest usage if we have context to ref, but Riverpod is preferred.
// Best to expose a simple provider that watches preferences and returns a closure or class.

final trProvider = Provider<String Function(String, [Map<String, dynamic>?])>((ref) {
  final service = ref.watch(localizationServiceProvider);
  final langCode = ref.watch(preferencesProvider.select((s) => s.languageCode));
  service.updateLanguage(langCode);
  return service.translate;
});
