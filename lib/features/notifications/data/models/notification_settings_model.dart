import 'package:flutter/material.dart';

import 'package:localtrade/features/notifications/data/models/notification_model.dart';

enum NotificationChannel {
  push('Push Notifications', Icons.notifications_active),
  email('Email', Icons.email),
  inApp('In-App', Icons.notifications_outlined);

  const NotificationChannel(this.label, this.icon);
  final String label;
  final IconData icon;
}

@immutable
class QuietHoursModel {
  const QuietHoursModel({
    this.enabled = false,
    this.startTime,
    this.endTime,
  });

  final bool enabled;
  final TimeOfDay? startTime; // Start of quiet hours (e.g., 10:00 PM)
  final TimeOfDay? endTime; // End of quiet hours (e.g., 8:00 AM)

  /// Check if current time is within quiet hours
  bool isCurrentlyQuiet() {
    if (!enabled || startTime == null || endTime == null) return false;

    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    // Handle case where quiet hours span midnight (e.g., 10 PM - 8 AM)
    if (endTime!.hour < startTime!.hour) {
      // Quiet hours span midnight
      return currentTime.hour >= startTime!.hour ||
          currentTime.hour < endTime!.hour ||
          (currentTime.hour == endTime!.hour && currentTime.minute < endTime!.minute);
    } else {
      // Normal case: same day
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final startMinutes = startTime!.hour * 60 + startTime!.minute;
      final endMinutes = endTime!.hour * 60 + endTime!.minute;
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  QuietHoursModel copyWith({
    bool? enabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return QuietHoursModel(
      enabled: enabled ?? this.enabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  factory QuietHoursModel.fromJson(Map<String, dynamic> json) {
    return QuietHoursModel(
      enabled: json['enabled'] as bool? ?? false,
      startTime: json['startTime'] != null
          ? TimeOfDay(
              hour: json['startTime']['hour'] as int,
              minute: json['startTime']['minute'] as int,
            )
          : null,
      endTime: json['endTime'] != null
          ? TimeOfDay(
              hour: json['endTime']['hour'] as int,
              minute: json['endTime']['minute'] as int,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'startTime': startTime != null
          ? {
              'hour': startTime!.hour,
              'minute': startTime!.minute,
            }
          : null,
      'endTime': endTime != null
          ? {
              'hour': endTime!.hour,
              'minute': endTime!.minute,
            }
          : null,
    };
  }
}

@immutable
class NotificationSettingsModel {
  NotificationSettingsModel({
    required this.userId,
    this.enableAll = true,
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.inAppEnabled = true,
    QuietHoursModel? quietHours,
    this.likeNotifications = const NotificationChannelSettings(),
    this.commentNotifications = const NotificationChannelSettings(),
    this.orderNotifications = const NotificationChannelSettings(),
    this.messageNotifications = const NotificationChannelSettings(),
    this.systemNotifications = const NotificationChannelSettings(),
    this.followNotifications = const NotificationChannelSettings(),
    this.reviewNotifications = const NotificationChannelSettings(),
    DateTime? updatedAt,
  })  : quietHours = quietHours ?? const QuietHoursModel(),
        updatedAt = updatedAt ?? DateTime.now();

  final String userId;
  final bool enableAll; // Master toggle for all notifications
  final bool pushEnabled; // Master toggle for push notifications
  final bool emailEnabled; // Master toggle for email notifications
  final bool inAppEnabled; // Master toggle for in-app notifications
  final QuietHoursModel quietHours; // Quiet hours settings
  final NotificationChannelSettings likeNotifications;
  final NotificationChannelSettings commentNotifications;
  final NotificationChannelSettings orderNotifications;
  final NotificationChannelSettings messageNotifications;
  final NotificationChannelSettings systemNotifications;
  final NotificationChannelSettings followNotifications;
  final NotificationChannelSettings reviewNotifications;
  final DateTime updatedAt;

  NotificationSettingsModel copyWith({
    String? userId,
    bool? enableAll,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? inAppEnabled,
    QuietHoursModel? quietHours,
    NotificationChannelSettings? likeNotifications,
    NotificationChannelSettings? commentNotifications,
    NotificationChannelSettings? orderNotifications,
    NotificationChannelSettings? messageNotifications,
    NotificationChannelSettings? systemNotifications,
    NotificationChannelSettings? followNotifications,
    NotificationChannelSettings? reviewNotifications,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      userId: userId ?? this.userId,
      enableAll: enableAll ?? this.enableAll,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      quietHours: quietHours ?? this.quietHours,
      likeNotifications: likeNotifications ?? this.likeNotifications,
      commentNotifications: commentNotifications ?? this.commentNotifications,
      orderNotifications: orderNotifications ?? this.orderNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      followNotifications: followNotifications ?? this.followNotifications,
      reviewNotifications: reviewNotifications ?? this.reviewNotifications,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      userId: json['userId'] as String,
      enableAll: json['enableAll'] as bool? ?? true,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      inAppEnabled: json['inAppEnabled'] as bool? ?? true,
      quietHours: json['quietHours'] != null
          ? QuietHoursModel.fromJson(json['quietHours'] as Map<String, dynamic>)
          : const QuietHoursModel(),
      likeNotifications: json['likeNotifications'] != null
          ? NotificationChannelSettings.fromJson(
              json['likeNotifications'] as Map<String, dynamic>)
          : const NotificationChannelSettings(),
      commentNotifications: json['commentNotifications'] != null
          ? NotificationChannelSettings.fromJson(
              json['commentNotifications'] as Map<String, dynamic>)
          : const NotificationChannelSettings(),
      orderNotifications: json['orderNotifications'] != null
          ? NotificationChannelSettings.fromJson(
              json['orderNotifications'] as Map<String, dynamic>)
          : const NotificationChannelSettings(),
      messageNotifications: json['messageNotifications'] != null
          ? NotificationChannelSettings.fromJson(
              json['messageNotifications'] as Map<String, dynamic>)
          : const NotificationChannelSettings(),
      systemNotifications: json['systemNotifications'] != null
          ? NotificationChannelSettings.fromJson(
              json['systemNotifications'] as Map<String, dynamic>)
          : const NotificationChannelSettings(),
      followNotifications: json['followNotifications'] != null
          ? NotificationChannelSettings.fromJson(
              json['followNotifications'] as Map<String, dynamic>)
          : const NotificationChannelSettings(),
      reviewNotifications: json['reviewNotifications'] != null
          ? NotificationChannelSettings.fromJson(
              json['reviewNotifications'] as Map<String, dynamic>)
          : const NotificationChannelSettings(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'enableAll': enableAll,
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'inAppEnabled': inAppEnabled,
      'quietHours': quietHours.toJson(),
      'likeNotifications': likeNotifications.toJson(),
      'commentNotifications': commentNotifications.toJson(),
      'orderNotifications': orderNotifications.toJson(),
      'messageNotifications': messageNotifications.toJson(),
      'systemNotifications': systemNotifications.toJson(),
      'followNotifications': followNotifications.toJson(),
      'reviewNotifications': reviewNotifications.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Check if a specific notification type is enabled for a channel
  bool isEnabledForChannel(NotificationType type, NotificationChannel channel) {
    if (!enableAll) return false;
    if (quietHours.enabled && quietHours.isCurrentlyQuiet()) return false;

    final typeSettings = _getTypeSettings(type);
    if (typeSettings == null) return false;

    switch (channel) {
      case NotificationChannel.push:
        return pushEnabled && typeSettings.pushEnabled;
      case NotificationChannel.email:
        return emailEnabled && typeSettings.emailEnabled;
      case NotificationChannel.inApp:
        return inAppEnabled && typeSettings.inAppEnabled;
    }
  }

  NotificationChannelSettings? _getTypeSettings(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return likeNotifications;
      case NotificationType.comment:
        return commentNotifications;
      case NotificationType.order:
        return orderNotifications;
      case NotificationType.message:
        return messageNotifications;
      case NotificationType.system:
        return systemNotifications;
      case NotificationType.follow:
        return followNotifications;
      case NotificationType.review:
        return reviewNotifications;
    }
  }
}

@immutable
class NotificationChannelSettings {
  const NotificationChannelSettings({
    this.enabled = true,
    this.pushEnabled = true,
    this.emailEnabled = false,
    this.inAppEnabled = true,
  });

  final bool enabled; // Master toggle for this notification type
  final bool pushEnabled; // Push notifications for this type
  final bool emailEnabled; // Email notifications for this type
  final bool inAppEnabled; // In-app notifications for this type

  NotificationChannelSettings copyWith({
    bool? enabled,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? inAppEnabled,
  }) {
    return NotificationChannelSettings(
      enabled: enabled ?? this.enabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
    );
  }

  factory NotificationChannelSettings.fromJson(Map<String, dynamic> json) {
    return NotificationChannelSettings(
      enabled: json['enabled'] as bool? ?? true,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? false,
      inAppEnabled: json['inAppEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'inAppEnabled': inAppEnabled,
    };
  }
}

// Extension for NotificationType to add display properties
extension NotificationTypeExtension on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.like:
        return 'Likes';
      case NotificationType.comment:
        return 'Comments';
      case NotificationType.order:
        return 'Orders';
      case NotificationType.message:
        return 'Messages';
      case NotificationType.system:
        return 'System';
      case NotificationType.follow:
        return 'Follows';
      case NotificationType.review:
        return 'Reviews';
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.order:
        return Colors.green;
      case NotificationType.message:
        return Colors.purple;
      case NotificationType.system:
        return Colors.orange;
      case NotificationType.follow:
        return Colors.teal;
      case NotificationType.review:
        return Colors.amber;
    }
  }
}

// Additional notification types for settings (not in main enum yet)
enum ExtendedNotificationType {
  follow('Follows', Icons.person_add, Colors.teal),
  review('Reviews', Icons.star, Colors.amber);

  const ExtendedNotificationType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

