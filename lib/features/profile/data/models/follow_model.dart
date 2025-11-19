import 'package:flutter/material.dart';

@immutable
class FollowModel {
  FollowModel({
    required this.followerId,
    required this.followingId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String followerId; // User who is following
  final String followingId; // User being followed
  final DateTime createdAt;

  FollowModel copyWith({
    String? followerId,
    String? followingId,
    DateTime? createdAt,
  }) {
    return FollowModel(
      followerId: followerId ?? this.followerId,
      followingId: followingId ?? this.followingId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      followerId: json['followerId'] as String,
      followingId: json['followingId'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FollowModel &&
        other.followerId == followerId &&
        other.followingId == followingId;
  }

  @override
  int get hashCode => followerId.hashCode ^ followingId.hashCode;
}

