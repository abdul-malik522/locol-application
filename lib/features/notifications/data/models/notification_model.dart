import 'package:flutter/material.dart';

enum NotificationType {
  like,
  comment,
  order,
  message,
  system,
  follow,
  review,
}

@immutable
class NotificationModel {
  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.relatedId,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  IconData get icon {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.order:
        return Icons.shopping_bag;
      case NotificationType.message:
        return Icons.chat_bubble;
      case NotificationType.system:
        return Icons.notifications;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.review:
        return Icons.star;
    }
  }

  Color get iconColor {
    switch (type) {
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

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationType.values.firstWhere(
        (type) => type.name == (json['type'] as String),
        orElse: () => NotificationType.system,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      relatedId: json['relatedId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

