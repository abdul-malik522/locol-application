import 'dart:async';

import 'package:localtrade/features/home/data/models/stock_notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class StockNotificationsDataSource {
  StockNotificationsDataSource._();
  static final StockNotificationsDataSource instance = StockNotificationsDataSource._();
  final _uuid = const Uuid();

  static const String _notificationsKeyPrefix = 'stock_notifications_';

  String _getNotificationsKey(String userId) => '$_notificationsKeyPrefix$userId';

  Future<List<StockNotificationModel>> getNotifications(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_getNotificationsKey(userId));
    if (notificationsJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(notificationsJson) as List<dynamic>;
      return decoded
          .map((e) => StockNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createNotification(StockNotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StockNotificationModel> existing = await getNotifications(notification.userId);
    
    // Check if notification already exists for this post
    final existingIndex = existing.indexWhere((n) => n.postId == notification.postId);
    if (existingIndex != -1) {
      existing[existingIndex] = notification; // Update existing
    } else {
      existing.add(notification); // Add new
    }

    final String encoded = json.encode(existing.map((e) => e.toJson()).toList());
    await prefs.setString(_getNotificationsKey(notification.userId), encoded);
  }

  Future<void> deleteNotification(String notificationId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StockNotificationModel> existing = await getNotifications(userId);
    existing.removeWhere((n) => n.id == notificationId);

    final String encoded = json.encode(existing.map((e) => e.toJson()).toList());
    await prefs.setString(_getNotificationsKey(userId), encoded);
  }

  Future<void> updateNotification(StockNotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StockNotificationModel> existing = await getNotifications(notification.userId);
    final index = existing.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      existing[index] = notification;
      final String encoded = json.encode(existing.map((e) => e.toJson()).toList());
      await prefs.setString(_getNotificationsKey(notification.userId), encoded);
    }
  }

  Future<List<StockNotificationModel>> getActiveNotifications(String userId) async {
    final notifications = await getNotifications(userId);
    return notifications.where((n) => n.isActive).toList();
  }
}

