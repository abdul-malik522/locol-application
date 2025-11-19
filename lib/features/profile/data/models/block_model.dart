import 'package:flutter/material.dart';

@immutable
class BlockModel {
  BlockModel({
    required this.blockerId,
    required this.blockedId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String blockerId;
  final String blockedId;
  final DateTime createdAt;

  BlockModel copyWith({
    String? blockerId,
    String? blockedId,
    DateTime? createdAt,
  }) {
    return BlockModel(
      blockerId: blockerId ?? this.blockerId,
      blockedId: blockedId ?? this.blockedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      blockerId: json['blockerId'] as String,
      blockedId: json['blockedId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

