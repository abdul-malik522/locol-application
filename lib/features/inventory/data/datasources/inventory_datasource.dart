import 'dart:async';

import 'package:localtrade/features/inventory/data/models/inventory_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class InventoryDataSource {
  InventoryDataSource._();
  static final InventoryDataSource instance = InventoryDataSource._();
  final _uuid = const Uuid();

  static const String _inventoryKeyPrefix = 'inventory_';
  static const String _alertsKeyPrefix = 'stock_alerts_';
  static const String _calendarKeyPrefix = 'availability_calendar_';

  String _getInventoryKey(String userId) => '$_inventoryKeyPrefix$userId';
  String _getAlertsKey(String userId) => '$_alertsKeyPrefix$userId';
  String _getCalendarKey(String userId) => '$_calendarKeyPrefix$userId';

  // Inventory Items
  Future<List<InventoryItemModel>> getInventoryItems(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? inventoryJson = prefs.getString(_getInventoryKey(userId));
    if (inventoryJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(inventoryJson) as List<dynamic>;
      return decoded
          .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<InventoryItemModel?> getInventoryItemByPostId(String postId, String userId) async {
    final items = await getInventoryItems(userId);
    try {
      return items.firstWhere((item) => item.postId == postId);
    } catch (_) {
      return null;
    }
  }

  Future<InventoryItemModel> createInventoryItem(InventoryItemModel item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<InventoryItemModel> existingItems = await getInventoryItems(item.postId.split('_')[0]); // Extract userId from postId if needed
    existingItems.add(item);
    final String encoded = json.encode(existingItems.map((e) => e.toJson()).toList());
    await prefs.setString(_getInventoryKey(item.postId.split('_')[0]), encoded);
    return item;
  }

  Future<InventoryItemModel> updateInventoryItem(InventoryItemModel item) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = item.postId.split('_')[0]; // Extract userId
    final List<InventoryItemModel> existingItems = await getInventoryItems(userId);
    final index = existingItems.indexWhere((i) => i.id == item.id);
    if (index == -1) throw Exception('Inventory item not found');

    // Update status based on stock level
    StockStatus newStatus = item.status;
    if (item.currentStock <= 0) {
      newStatus = StockStatus.outOfStock;
    } else if (item.isLowStock) {
      newStatus = StockStatus.lowStock;
    } else {
      newStatus = StockStatus.inStock;
    }

    final updated = item.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    existingItems[index] = updated;
    final String encoded = json.encode(existingItems.map((e) => e.toJson()).toList());
    await prefs.setString(_getInventoryKey(userId), encoded);
    return updated;
  }

  Future<void> deleteInventoryItem(String itemId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<InventoryItemModel> existingItems = await getInventoryItems(userId);
    existingItems.removeWhere((i) => i.id == itemId);
    final String encoded = json.encode(existingItems.map((e) => e.toJson()).toList());
    await prefs.setString(_getInventoryKey(userId), encoded);
  }

  // Stock Alerts
  Future<List<StockAlertModel>> getStockAlerts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? alertsJson = prefs.getString(_getAlertsKey(userId));
    if (alertsJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(alertsJson) as List<dynamic>;
      return decoded
          .map((e) => StockAlertModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Future<StockAlertModel> createStockAlert(StockAlertModel alert) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = alert.postId.split('_')[0]; // Extract userId
    final List<StockAlertModel> existingAlerts = await getStockAlerts(userId);
    existingAlerts.add(alert);
    final String encoded = json.encode(existingAlerts.map((e) => e.toJson()).toList());
    await prefs.setString(_getAlertsKey(userId), encoded);
    return alert;
  }

  Future<StockAlertModel> updateStockAlert(StockAlertModel alert) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = alert.postId.split('_')[0]; // Extract userId
    final List<StockAlertModel> existingAlerts = await getStockAlerts(userId);
    final index = existingAlerts.indexWhere((a) => a.id == alert.id);
    if (index == -1) throw Exception('Stock alert not found');
    existingAlerts[index] = alert;
    final String encoded = json.encode(existingAlerts.map((e) => e.toJson()).toList());
    await prefs.setString(_getAlertsKey(userId), encoded);
    return alert;
  }

  Future<void> deleteStockAlert(String alertId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StockAlertModel> existingAlerts = await getStockAlerts(userId);
    existingAlerts.removeWhere((a) => a.id == alertId);
    final String encoded = json.encode(existingAlerts.map((e) => e.toJson()).toList());
    await prefs.setString(_getAlertsKey(userId), encoded);
  }

  // Availability Calendar
  Future<List<AvailabilityCalendarModel>> getAvailabilityCalendars(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? calendarJson = prefs.getString(_getCalendarKey(userId));
    if (calendarJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(calendarJson) as List<dynamic>;
      return decoded
          .map((e) => AvailabilityCalendarModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<AvailabilityCalendarModel?> getAvailabilityCalendarByPostId(String postId, String userId) async {
    final calendars = await getAvailabilityCalendars(userId);
    try {
      return calendars.firstWhere((cal) => cal.postId == postId);
    } catch (_) {
      return null;
    }
  }

  Future<AvailabilityCalendarModel> createAvailabilityCalendar(AvailabilityCalendarModel calendar) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = calendar.postId.split('_')[0]; // Extract userId
    final List<AvailabilityCalendarModel> existingCalendars = await getAvailabilityCalendars(userId);
    existingCalendars.add(calendar);
    final String encoded = json.encode(existingCalendars.map((e) => e.toJson()).toList());
    await prefs.setString(_getCalendarKey(userId), encoded);
    return calendar;
  }

  Future<AvailabilityCalendarModel> updateAvailabilityCalendar(AvailabilityCalendarModel calendar) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = calendar.postId.split('_')[0]; // Extract userId
    final List<AvailabilityCalendarModel> existingCalendars = await getAvailabilityCalendars(userId);
    final index = existingCalendars.indexWhere((c) => c.id == calendar.id);
    if (index == -1) throw Exception('Availability calendar not found');
    existingCalendars[index] = calendar;
    final String encoded = json.encode(existingCalendars.map((e) => e.toJson()).toList());
    await prefs.setString(_getCalendarKey(userId), encoded);
    return calendar;
  }

  Future<void> deleteAvailabilityCalendar(String calendarId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<AvailabilityCalendarModel> existingCalendars = await getAvailabilityCalendars(userId);
    existingCalendars.removeWhere((c) => c.id == calendarId);
    final String encoded = json.encode(existingCalendars.map((e) => e.toJson()).toList());
    await prefs.setString(_getCalendarKey(userId), encoded);
  }
}

