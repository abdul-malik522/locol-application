import 'dart:async';

import 'package:localtrade/features/notifications/data/models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationsMockDataSource {
  NotificationsMockDataSource._() {
    _initializeMockData();
  }
  static final NotificationsMockDataSource instance =
      NotificationsMockDataSource._();
  final _uuid = const Uuid();

  final List<NotificationModel> _notifications = [];

  void _initializeMockData() {
    final now = DateTime.now();

    _notifications.addAll([
      NotificationModel(
        id: 'notif-001',
        userId: 'user-001',
        type: NotificationType.like,
        title: 'New Like',
        body: 'Lena Rivers liked your post "Fresh Organic Tomatoes"',
        imageUrl: 'https://i.pravatar.cc/150?img=20',
        relatedId: 'post-001',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      NotificationModel(
        id: 'notif-002',
        userId: 'user-001',
        type: NotificationType.comment,
        title: 'New Comment',
        body: 'Marco Bianchi commented on your post',
        imageUrl: 'https://i.pravatar.cc/150?img=14',
        relatedId: 'post-001',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'notif-003',
        userId: 'user-001',
        type: NotificationType.order,
        title: 'New Order',
        body: 'You received a new order #ORD-1001',
        imageUrl: null,
        relatedId: 'order-001',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'notif-004',
        userId: 'user-004',
        type: NotificationType.message,
        title: 'New Message',
        body: 'Amelia Fields sent you a message',
        imageUrl: 'https://i.pravatar.cc/150?img=5',
        relatedId: 'chat-001',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        id: 'notif-005',
        userId: 'user-002',
        type: NotificationType.order,
        title: 'Order Accepted',
        body: 'Your order #ORD-1002 has been accepted',
        imageUrl: null,
        relatedId: 'order-002',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: 'notif-006',
        userId: 'user-003',
        type: NotificationType.like,
        title: 'New Like',
        body: 'Derrick Cole liked your post "Free-Range Chicken"',
        imageUrl: 'https://i.pravatar.cc/150?img=16',
        relatedId: 'post-004',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      NotificationModel(
        id: 'notif-007',
        userId: 'user-005',
        type: NotificationType.order,
        title: 'Order Completed',
        body: 'Your order #ORD-1003 has been completed',
        imageUrl: null,
        relatedId: 'order-003',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      NotificationModel(
        id: 'notif-008',
        userId: 'user-001',
        type: NotificationType.system,
        title: 'Welcome to LocalTrade!',
        body: 'Start connecting with local sellers and restaurants',
        imageUrl: null,
        relatedId: null,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      NotificationModel(
        id: 'notif-009',
        userId: 'user-004',
        type: NotificationType.comment,
        title: 'New Comment',
        body: 'Amelia Fields commented on your request',
        imageUrl: 'https://i.pravatar.cc/150?img=5',
        relatedId: 'post-003',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      NotificationModel(
        id: 'notif-010',
        userId: 'user-006',
        type: NotificationType.message,
        title: 'New Message',
        body: 'Rita Stone sent you a message',
        imageUrl: 'https://i.pravatar.cc/150?img=9',
        relatedId: 'chat-003',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
      ),
    ]);
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final notifications = _notifications
        .where((notif) => notif.userId == userId)
        .toList();
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index =
        _notifications.indexWhere((notif) => notif.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _notifications.removeWhere((notif) => notif.id == notificationId);
  }

  Future<void> clearAll(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _notifications.removeWhere((notif) => notif.userId == userId);
  }
}

