import 'dart:async';

import 'package:localtrade/features/home/data/models/price_alert_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class PriceAlertsDataSource {
  PriceAlertsDataSource._();
  static final PriceAlertsDataSource instance = PriceAlertsDataSource._();
  final _uuid = const Uuid();

  static const String _alertsKeyPrefix = 'price_alerts_';

  String _getAlertsKey(String userId) => '$_alertsKeyPrefix$userId';

  Future<List<PriceAlertModel>> getAlerts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? alertsJson = prefs.getString(_getAlertsKey(userId));
    if (alertsJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(alertsJson) as List<dynamic>;
      return decoded
          .map((e) => PriceAlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createAlert(PriceAlertModel alert) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PriceAlertModel> existingAlerts = await getAlerts(alert.userId);
    
    // Check if alert already exists for this post
    final existingIndex = existingAlerts.indexWhere((a) => a.postId == alert.postId);
    if (existingIndex != -1) {
      existingAlerts[existingIndex] = alert; // Update existing
    } else {
      existingAlerts.add(alert); // Add new
    }

    final String encoded = json.encode(existingAlerts.map((e) => e.toJson()).toList());
    await prefs.setString(_getAlertsKey(alert.userId), encoded);
  }

  Future<void> deleteAlert(String alertId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PriceAlertModel> existingAlerts = await getAlerts(userId);
    existingAlerts.removeWhere((a) => a.id == alertId);

    final String encoded = json.encode(existingAlerts.map((e) => e.toJson()).toList());
    await prefs.setString(_getAlertsKey(userId), encoded);
  }

  Future<void> updateAlert(PriceAlertModel alert) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PriceAlertModel> existingAlerts = await getAlerts(alert.userId);
    final index = existingAlerts.indexWhere((a) => a.id == alert.id);
    if (index != -1) {
      existingAlerts[index] = alert;
      final String encoded = json.encode(existingAlerts.map((e) => e.toJson()).toList());
      await prefs.setString(_getAlertsKey(alert.userId), encoded);
    }
  }

  Future<List<PriceAlertModel>> getActiveAlerts(String userId) async {
    final alerts = await getAlerts(userId);
    return alerts.where((a) => a.isActive).toList();
  }
}

