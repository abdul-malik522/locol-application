import 'package:flutter/material.dart';

import 'package:localtrade/core/constants/app_constants.dart';

@immutable
class PriceAlertModel {
  const PriceAlertModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.postTitle,
    required this.currentPrice,
    required this.targetPrice,
    this.isActive = true,
    this.notifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId; // User who set the alert
  final String postId;
  final String postTitle;
  final double currentPrice; // Price when alert was set
  final double targetPrice; // Price threshold to trigger alert
  final bool isActive;
  final DateTime? notifiedAt; // When the alert was last triggered
  final DateTime createdAt;
  final DateTime updatedAt;

  bool shouldTrigger(double newPrice) {
    return isActive && newPrice <= targetPrice && newPrice < currentPrice;
  }

  PriceAlertModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? postTitle,
    double? currentPrice,
    double? targetPrice,
    bool? isActive,
    DateTime? notifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PriceAlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      currentPrice: currentPrice ?? this.currentPrice,
      targetPrice: targetPrice ?? this.targetPrice,
      isActive: isActive ?? this.isActive,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory PriceAlertModel.fromJson(Map<String, dynamic> json) {
    return PriceAlertModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      postId: json['postId'] as String,
      postTitle: json['postTitle'] as String,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      targetPrice: (json['targetPrice'] as num).toDouble(),
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
      'currentPrice': currentPrice,
      'targetPrice': targetPrice,
      'isActive': isActive,
      'notifiedAt': notifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

