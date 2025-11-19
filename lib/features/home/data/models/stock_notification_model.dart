import 'package:flutter/material.dart';

@immutable
class StockNotificationModel {
  const StockNotificationModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.postTitle,
    required this.wasOutOfStock,
    this.isActive = true,
    this.notifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId; // User who set the notification
  final String postId;
  final String postTitle;
  final bool wasOutOfStock; // Whether item was out of stock when notification was set
  final bool isActive;
  final DateTime? notifiedAt; // When the notification was last triggered
  final DateTime createdAt;
  final DateTime updatedAt;

  bool shouldTrigger(bool isNowInStock) {
    return isActive && wasOutOfStock && isNowInStock;
  }

  StockNotificationModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? postTitle,
    bool? wasOutOfStock,
    bool? isActive,
    DateTime? notifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockNotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      wasOutOfStock: wasOutOfStock ?? this.wasOutOfStock,
      isActive: isActive ?? this.isActive,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory StockNotificationModel.fromJson(Map<String, dynamic> json) {
    return StockNotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      postId: json['postId'] as String,
      postTitle: json['postTitle'] as String,
      wasOutOfStock: json['wasOutOfStock'] as bool,
      isActive: json['isActive'] as bool? ?? true,
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.parse(json['notifiedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'postTitle': postTitle,
      'wasOutOfStock': wasOutOfStock,
      'isActive': isActive,
      'notifiedAt': notifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

