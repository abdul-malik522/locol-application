import 'dart:async';

import 'package:localtrade/features/search/data/models/search_alert_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class SearchAlertsDataSource {
  SearchAlertsDataSource._();
  static final SearchAlertsDataSource instance = SearchAlertsDataSource._();

  static const String _alertsKeyPrefix = 'search_alerts_';

  String _getAlertsKey(String userId) => '$_alertsKeyPrefix$userId';

  Future<List<SearchAlertModel>> getSearchAlerts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? alertsJson = prefs.getString(_getAlertsKey(userId));
    if (alertsJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(alertsJson) as List<dynamic>;
      return decoded
          .map((e) => SearchAlertModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Future<SearchAlertModel?> getSearchAlertById(String alertId, String userId) async {
    final alerts = await getSearchAlerts(userId);
    try {
      return alerts.firstWhere((a) => a.id == alertId);
    } catch (_) {
      return null;
    }
  }

  Future<SearchAlertModel> createSearchAlert(SearchAlertModel alert) async {
    final prefs = await SharedPreferences.getInstance();
    final List<SearchAlertModel> existingAlerts = await getSearchAlerts(alert.userId);
    existingAlerts.add(alert);
    final String encoded = json.encode(existingAlerts.map((e) => e.toJson()).toList());
    await prefs.setString(_getAlertsKey(alert.userId), encoded);
    return alert;
  }

  Future<SearchAlertModel> updateSearchAlert(SearchAlertModel alert) async {
    final prefs = await SharedPreferences.getInstance();
    final List<SearchAlertModel> existingAlerts = await getSearchAlerts(alert.userId);
    final index = existingAlerts.indexWhere((a) => a.id == alert.id);
    if (index == -1) throw Exception('Search alert not found');
    existingAlerts[index] = alert;
    final String encoded = json.encode(existingAlerts.map((e) => e.toJson()).toList());
    await prefs.setString(_getAlertsKey(alert.userId), encoded);
    return alert;
  }

  Future<void> deleteSearchAlert(String alertId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<SearchAlertModel> existingAlerts = await getSearchAlerts(userId);
    existingAlerts.removeWhere((a) => a.id == alertId);
    final String encoded = json.encode(existingAlerts.map((e) => e.toJson()).toList());
    await prefs.setString(_getAlertsKey(userId), encoded);
  }

  Future<List<SearchAlertModel>> getActiveAlerts(String userId) async {
    final alerts = await getSearchAlerts(userId);
    return alerts.where((a) => a.isActive).toList();
  }
}

