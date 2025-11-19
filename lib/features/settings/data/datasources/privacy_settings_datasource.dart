import 'dart:convert';

import 'package:localtrade/features/settings/data/models/privacy_settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsDataSource {
  PrivacySettingsDataSource._();
  static final PrivacySettingsDataSource instance =
      PrivacySettingsDataSource._();

  static const String _settingsKeyPrefix = 'privacy_settings_';

  String _getSettingsKey(String userId) => '$_settingsKeyPrefix$userId';

  Future<PrivacySettingsModel> getSettings(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString(_getSettingsKey(userId));

    if (settingsJson == null) {
      // Return default settings
      return PrivacySettingsModel(userId: userId);
    }

    try {
      final Map<String, dynamic> decoded =
          json.decode(settingsJson) as Map<String, dynamic>;
      return PrivacySettingsModel.fromJson(decoded);
    } catch (e) {
      // If parsing fails, return default settings
      return PrivacySettingsModel(userId: userId);
    }
  }

  Future<void> saveSettings(PrivacySettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(settings.toJson());
    await prefs.setString(_getSettingsKey(settings.userId), encoded);
  }

  Future<void> resetSettings(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getSettingsKey(userId));
  }
}

