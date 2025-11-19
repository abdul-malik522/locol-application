import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/notifications/data/models/notification_settings_model.dart';
import 'package:localtrade/features/notifications/data/services/push_notification_service.dart';
import 'package:localtrade/features/notifications/providers/notification_settings_provider.dart';

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) => PushNotificationService.instance);

final pushNotificationStatusProvider =
    StateNotifierProvider<PushNotificationStatusNotifier, PushNotificationStatus>(
  (ref) {
    final service = ref.watch(pushNotificationServiceProvider);
    return PushNotificationStatusNotifier(service, ref);
  },
);

class PushNotificationStatus {
  const PushNotificationStatus({
    this.isInitialized = false,
    this.hasPermission = false,
    this.deviceToken,
    this.isRegistering = false,
    this.error,
  });

  final bool isInitialized;
  final bool hasPermission;
  final String? deviceToken;
  final bool isRegistering;
  final String? error;

  PushNotificationStatus copyWith({
    bool? isInitialized,
    bool? hasPermission,
    String? deviceToken,
    bool? isRegistering,
    String? error,
  }) {
    return PushNotificationStatus(
      isInitialized: isInitialized ?? this.isInitialized,
      hasPermission: hasPermission ?? this.hasPermission,
      deviceToken: deviceToken ?? this.deviceToken,
      isRegistering: isRegistering ?? this.isRegistering,
      error: error,
    );
  }
}

class PushNotificationStatusNotifier extends StateNotifier<PushNotificationStatus> {
  PushNotificationStatusNotifier(this._service, this._ref)
      : super(const PushNotificationStatus()) {
    _initialize();
    _listenToNotifications();
  }

  final PushNotificationService _service;
  final Ref _ref;
  StreamSubscription<PushNotificationPayload>? _notificationSubscription;

  Future<void> _initialize() async {
    try {
      await _service.initialize();
      final token = await _service.getDeviceToken();
      
      state = state.copyWith(
        isInitialized: _service.isInitialized,
        hasPermission: _service.hasPermission,
        deviceToken: token,
      );

      // Auto-register token if user is logged in
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser != null && token != null) {
        await _registerToken(currentUser.id, token);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> requestPermission() async {
    try {
      final granted = await _service.requestPermission();
      state = state.copyWith(hasPermission: granted);
      
      if (granted) {
        final token = await _service.getDeviceToken();
        state = state.copyWith(deviceToken: token);
        
        // Register token if user is logged in
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser != null && token != null) {
          await _registerToken(currentUser.id, token);
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _registerToken(String userId, String token) async {
    if (state.isRegistering) return;
    
    state = state.copyWith(isRegistering: true, error: null);
    try {
      // Check notification settings to see if push is enabled
      final settingsAsync = _ref.read(notificationSettingsProvider(userId));
      final settings = settingsAsync.value;
      
      if (settings != null && settings.enableAll && settings.pushEnabled) {
        await _service.registerToken(userId, token);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isRegistering: false);
    }
  }

  Future<void> unregisterToken(String userId) async {
    try {
      await _service.unregisterToken(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _listenToNotifications() {
    _notificationSubscription = _service.notificationStream.listen(
      (payload) {
        // Handle notification based on settings
        _handleNotification(payload);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  Future<void> _handleNotification(PushNotificationPayload payload) async {
    // Check if push notifications are enabled in settings
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return;

    final settingsAsync = _ref.read(notificationSettingsProvider(currentUser.id));
    final settings = settingsAsync.value;

    // Check if notifications are enabled
    if (settings == null || !settings.enableAll || !settings.pushEnabled) {
      return; // Don't show notification if disabled
    }

    // Check quiet hours
    if (settings.quietHours.enabled && settings.quietHours.isCurrentlyQuiet()) {
      return; // Don't show notification during quiet hours
    }

    // In production, this would show a local notification
    // For now, we'll just print it (in a real app, use flutter_local_notifications)
    if (kDebugMode) {
      print('Push notification received: ${payload.title} - ${payload.body}');
    }

    // TODO: Show local notification using flutter_local_notifications
    // This would require adding the package and implementing notification display
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}

