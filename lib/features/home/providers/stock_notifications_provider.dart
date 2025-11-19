import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/home/data/datasources/stock_notifications_datasource.dart';
import 'package:localtrade/features/home/data/models/stock_notification_model.dart';

class StockNotificationsState {
  const StockNotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  final List<StockNotificationModel> notifications;
  final bool isLoading;
  final String? error;

  StockNotificationsState copyWith({
    List<StockNotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return StockNotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final stockNotificationsDataSourceProvider =
    Provider<StockNotificationsDataSource>(
        (ref) => StockNotificationsDataSource.instance);

final stockNotificationsProvider = StateNotifierProvider.family<
    StockNotificationsNotifier, StockNotificationsState, String>((ref, userId) {
  final dataSource = ref.watch(stockNotificationsDataSourceProvider);
  return StockNotificationsNotifier(dataSource, userId);
});

class StockNotificationsNotifier
    extends StateNotifier<StockNotificationsState> {
  StockNotificationsNotifier(this._dataSource, this._userId)
      : super(const StockNotificationsState()) {
    loadNotifications();
  }

  final StockNotificationsDataSource _dataSource;
  final String _userId;

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _dataSource.getNotifications(_userId);
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: ${e.toString()}',
      );
    }
  }

  Future<void> createNotification(StockNotificationModel notification) async {
    try {
      await _dataSource.createNotification(notification);
      await loadNotifications();
    } catch (e) {
      state = state.copyWith(
          error: 'Failed to create notification: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dataSource.deleteNotification(notificationId, _userId);
      await loadNotifications();
    } catch (e) {
      state = state.copyWith(
          error: 'Failed to delete notification: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> updateNotification(StockNotificationModel notification) async {
    try {
      await _dataSource.updateNotification(notification);
      await loadNotifications();
    } catch (e) {
      state = state.copyWith(
          error: 'Failed to update notification: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> hasNotificationForPost(String postId) async {
    final notifications = await _dataSource.getNotifications(_userId);
    return notifications.any((n) => n.postId == postId && n.isActive);
  }
}

