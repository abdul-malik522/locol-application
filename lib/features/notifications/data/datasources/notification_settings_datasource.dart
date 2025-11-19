import 'dart:convert';

import 'package:localtrade/features/notifications/data/models/notification_settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsDataSource {
  NotificationSettingsDataSource._();
  static final NotificationSettingsDataSource instance =
      NotificationSettingsDataSource._();

  static const String _settingsKeyPrefix = 'notification_settings_';

  String _getSettingsKey(String userId) => '$_settingsKeyPrefix$userId';

  Future<NotificationSettingsModel> getSettings(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString(_getSettingsKey(userId));
    
    if (settingsJson == null) {
      // Return default settings
      return NotificationSettingsModel(userId: userId);
    }

    try {
      final Map<String, dynamic> decoded =
          json.decode(settingsJson) as Map<String, dynamic>;
      return NotificationSettingsModel.fromJson(decoded);
    } catch (e) {
      // If parsing fails, return default settings
      return NotificationSettingsModel(userId: userId);
    }
  }

  Future<void> saveSettings(NotificationSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(settings.toJson());
    await prefs.setString(_getSettingsKey(settings.userId), encoded);
  }

  Future<void> resetSettings(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getSettingsKey(userId));
  }
}

