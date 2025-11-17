import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/features/notifications/data/datasources/notifications_mock_datasource.dart';
import 'package:localtrade/features/notifications/data/models/notification_model.dart';

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final notificationsMockDataSourceProvider = Provider<NotificationsMockDataSource>(
  (ref) => NotificationsMockDataSource.instance,
);

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._dataSource) : super(const NotificationsState());

  final NotificationsMockDataSource _dataSource;

  Future<void> loadNotifications(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _dataSource.getNotifications(userId);
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: ${e.toString()}',
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _dataSource.markAsRead(notificationId);
      final index = state.notifications
          .indexWhere((notif) => notif.id == notificationId);
      if (index != -1) {
        final updatedNotifications = List<NotificationModel>.from(
          state.notifications,
        );
        updatedNotifications[index] =
            updatedNotifications[index].copyWith(isRead: true);
        state = state.copyWith(notifications: updatedNotifications);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to mark as read: ${e.toString()}',
      );
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _dataSource.markAllAsRead(userId);
      final updatedNotifications = state.notifications
          .map((notif) => notif.copyWith(isRead: true))
          .toList();
      state = state.copyWith(notifications: updatedNotifications);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to mark all as read: ${e.toString()}',
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dataSource.deleteNotification(notificationId);
      state = state.copyWith(
        notifications: state.notifications
            .where((notif) => notif.id != notificationId)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete notification: ${e.toString()}',
      );
    }
  }

  Future<void> clearAll(String userId) async {
    try {
      await _dataSource.clearAll(userId);
      state = state.copyWith(notifications: []);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to clear all: ${e.toString()}',
      );
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final dataSource = ref.watch(notificationsMockDataSourceProvider);
  return NotificationsNotifier(dataSource);
});

final unreadNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final state = ref.watch(notificationsProvider);
  return state.notifications.where((notif) => !notif.isRead).toList();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final unread = ref.watch(unreadNotificationsProvider);
  return unread.length;
});

