import 'dart:async';
import 'package:flutter/foundation.dart';

/// Mock Push Notification Service
/// In production, this would use Firebase Cloud Messaging (FCM) or similar
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final StreamController<PushNotificationPayload> _notificationController =
      StreamController<PushNotificationPayload>.broadcast();
  
  String? _deviceToken;
  bool _isInitialized = false;
  bool _hasPermission = false;

  /// Stream of incoming push notifications
  Stream<PushNotificationPayload> get notificationStream =>
      _notificationController.stream;

  /// Get current device token
  String? get deviceToken => _deviceToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if permission is granted
  bool get hasPermission => _hasPermission;

  /// Initialize push notification service
  /// In production, this would:
  /// - Request notification permissions
  /// - Initialize FCM
  /// - Get device token
  /// - Set up notification handlers
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Simulate permission request
      await Future.delayed(const Duration(seconds: 1));
      
      // In production, use permission_handler or FCM's requestPermission
      // For mock, we'll assume permission is granted
      _hasPermission = true;
      
      // Simulate getting device token
      await Future.delayed(const Duration(milliseconds: 500));
      _deviceToken = _generateMockToken();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('Push Notification Service initialized');
        print('Device Token: $_deviceToken');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize push notifications: $e');
      }
      rethrow;
    }
  }

  /// Request notification permissions
  /// In production, this would use permission_handler or FCM
  Future<bool> requestPermission() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // In production, check actual permission status
      _hasPermission = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to request permission: $e');
      }
      return false;
    }
  }

  /// Get device token for push notifications
  /// In production, this would get the actual FCM token
  Future<String?> getDeviceToken() async {
    if (_deviceToken != null) return _deviceToken;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    return _deviceToken;
  }

  /// Register device token with backend
  /// In production, this would send token to your backend API
  Future<void> registerToken(String userId, String token) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      // In production, make API call to register token
      if (kDebugMode) {
        print('Token registered for user $userId: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register token: $e');
      }
      rethrow;
    }
  }

  /// Unregister device token
  /// In production, this would remove token from backend
  Future<void> unregisterToken(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      // In production, make API call to unregister token
      if (kDebugMode) {
        print('Token unregistered for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to unregister token: $e');
      }
      rethrow;
    }
  }

  /// Handle foreground notification
  /// In production, this would be called by FCM when app is in foreground
  void handleForegroundNotification(PushNotificationPayload payload) {
    _notificationController.add(payload);
  }

  /// Handle background notification
  /// In production, this would be a top-level function for FCM background handler
  static Future<void> handleBackgroundNotification(
    PushNotificationPayload payload,
  ) async {
    // In production, handle background notification
    // This is a static method because it's called from a top-level function
    if (kDebugMode) {
      print('Background notification received: ${payload.title}');
    }
  }

  /// Simulate receiving a push notification (for testing)
  /// In production, notifications come from FCM
  void simulateNotification(PushNotificationPayload payload) {
    if (!_isInitialized || !_hasPermission) {
      if (kDebugMode) {
        print('Push notifications not initialized or permission not granted');
      }
      return;
    }
    
    _notificationController.add(payload);
  }

  /// Generate a mock device token
  String _generateMockToken() {
    // In production, this would be the actual FCM token
    return 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Dispose resources
  void dispose() {
    _notificationController.close();
  }
}

/// Push notification payload model
@immutable
class PushNotificationPayload {
  const PushNotificationPayload({
    required this.title,
    required this.body,
    this.data,
    this.imageUrl,
    this.sound,
    this.badge,
  });

  final String title;
  final String body;
  final Map<String, dynamic>? data; // Custom data payload
  final String? imageUrl; // Notification image
  final String? sound; // Notification sound
  final int? badge; // Badge count

  /// Create from JSON (for FCM payload)
  factory PushNotificationPayload.fromJson(Map<String, dynamic> json) {
    return PushNotificationPayload(
      title: json['notification']?['title'] as String? ?? json['title'] as String? ?? '',
      body: json['notification']?['body'] as String? ?? json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      imageUrl: json['notification']?['image'] as String?,
      sound: json['notification']?['sound'] as String?,
      badge: json['notification']?['badge'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'data': data,
      'imageUrl': imageUrl,
      'sound': sound,
      'badge': badge,
    };
  }
}

