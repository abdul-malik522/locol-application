import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/notifications/data/datasources/notification_settings_datasource.dart';
import 'package:localtrade/features/notifications/data/models/notification_model.dart';
import 'package:localtrade/features/notifications/data/models/notification_settings_model.dart';

final notificationSettingsDataSourceProvider =
    Provider<NotificationSettingsDataSource>(
        (ref) => NotificationSettingsDataSource.instance);

final notificationSettingsProvider =
    StateNotifierProvider.family<NotificationSettingsNotifier,
        AsyncValue<NotificationSettingsModel>, String>(
  (ref, userId) {
    final dataSource = ref.watch(notificationSettingsDataSourceProvider);
    return NotificationSettingsNotifier(dataSource, userId);
  },
);

class NotificationSettingsNotifier
    extends StateNotifier<AsyncValue<NotificationSettingsModel>> {
  NotificationSettingsNotifier(this._dataSource, this._userId)
      : super(const AsyncValue.loading()) {
    loadSettings();
  }

  final NotificationSettingsDataSource _dataSource;
  final String _userId;

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _dataSource.getSettings(_userId);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSettings(NotificationSettingsModel settings) async {
    try {
      await _dataSource.saveSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateEnableAll(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(enableAll: enabled);
    await updateSettings(updated);
  }

  Future<void> updateChannelMaster(
    NotificationChannel channel,
    bool enabled,
  ) async {
    final current = state.value;
    if (current == null) return;

    final updated = switch (channel) {
      NotificationChannel.push => current.copyWith(pushEnabled: enabled),
      NotificationChannel.email => current.copyWith(emailEnabled: enabled),
      NotificationChannel.inApp => current.copyWith(inAppEnabled: enabled),
    };
    await updateSettings(updated);
  }

  Future<void> updateQuietHours(QuietHoursModel quietHours) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(quietHours: quietHours);
    await updateSettings(updated);
  }

  Future<void> updateTypeSettings(
    NotificationType type,
    NotificationChannelSettings settings,
  ) async {
    final current = state.value;
    if (current == null) return;

    final updated = switch (type) {
      NotificationType.like =>
        current.copyWith(likeNotifications: settings),
      NotificationType.comment =>
        current.copyWith(commentNotifications: settings),
      NotificationType.order =>
        current.copyWith(orderNotifications: settings),
      NotificationType.message =>
        current.copyWith(messageNotifications: settings),
      NotificationType.system =>
        current.copyWith(systemNotifications: settings),
      NotificationType.follow =>
        current.copyWith(followNotifications: settings),
      NotificationType.review =>
        current.copyWith(reviewNotifications: settings),
    };
    await updateSettings(updated);
  }

  Future<void> updateExtendedTypeSettings(
    ExtendedNotificationType type,
    NotificationChannelSettings settings,
  ) async {
    final current = state.value;
    if (current == null) return;

    final updated = switch (type) {
      ExtendedNotificationType.follow =>
        current.copyWith(followNotifications: settings),
      ExtendedNotificationType.review =>
        current.copyWith(reviewNotifications: settings),
    };
    await updateSettings(updated);
  }

  Future<void> resetToDefaults() async {
    try {
      await _dataSource.resetSettings(_userId);
      await loadSettings();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

