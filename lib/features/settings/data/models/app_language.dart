import 'package:flutter/material.dart';

enum AppLanguage {
  english('English', 'en', '🇺🇸'),
  spanish('Español', 'es', '🇪🇸'),
  french('Français', 'fr', '🇫🇷'),
  german('Deutsch', 'de', '🇩🇪'),
  italian('Italiano', 'it', '🇮🇹'),
  portuguese('Português', 'pt', '🇵🇹'),
  chinese('中文', 'zh', '🇨🇳'),
  japanese('日本語', 'ja', '🇯🇵'),
  korean('한국어', 'ko', '🇰🇷'),
  arabic('العربية', 'ar', '🇸🇦'),
  hindi('हिन्दी', 'hi', '🇮🇳'),
  russian('Русский', 'ru', '🇷🇺');

  const AppLanguage(this.displayName, this.localeCode, this.flag);

  final String displayName;
  final String localeCode; // ISO 639-1 language code
  final String flag; // Flag emoji for visual representation

  /// Get Locale object for this language
  Locale get locale {
    // Handle special cases for locale codes
    switch (this) {
      case AppLanguage.chinese:
        return const Locale('zh', 'CN'); // Simplified Chinese
      case AppLanguage.portuguese:
        return const Locale('pt', 'BR'); // Brazilian Portuguese
      default:
        return Locale(localeCode);
    }
  }

  /// Get language from locale code
  static AppLanguage? fromLocaleCode(String localeCode) {
    try {
      return AppLanguage.values.firstWhere(
        (lang) => lang.localeCode == localeCode.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get language from Locale object
  static AppLanguage? fromLocale(Locale locale) {
    return fromLocaleCode(locale.languageCode);
  }
}

