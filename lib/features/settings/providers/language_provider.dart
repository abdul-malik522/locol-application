import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:localtrade/features/settings/data/models/app_language.dart';

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english) {
    _loadLanguage();
  }

  static const String _languageKey = 'app_language';

  /// Load saved language preference
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      if (languageCode != null) {
        final language = AppLanguage.fromLocaleCode(languageCode);
        if (language != null) {
          state = language;
        }
      }
    } catch (e) {
      // If loading fails, use default (English)
      print('Failed to load language preference: $e');
    }
  }

  /// Set app language
  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.localeCode);
    } catch (e) {
      print('Failed to save language preference: $e');
    }
  }

  /// Get current locale
  Locale get currentLocale => state.locale;
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

/// Provider for current locale (used by MaterialApp)
final localeProvider = Provider<Locale>((ref) {
  return ref.watch(languageProvider.notifier).currentLocale;
});

