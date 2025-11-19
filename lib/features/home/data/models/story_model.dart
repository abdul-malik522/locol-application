import 'package:flutter/material.dart';

import 'package:localtrade/core/constants/app_constants.dart';

@immutable
class StoryModel {
  const StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.userRole,
    required this.imageUrl,
    this.text,
    this.textColor,
    this.textPosition,
    DateTime? createdAt,
    DateTime? expiresAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? (createdAt ?? DateTime.now()).add(const Duration(hours: 24));

  final String id;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final UserRole userRole;
  final String imageUrl; // Story image URL
  final String? text; // Optional text overlay
  final Color? textColor; // Text color for overlay
  final TextPosition? textPosition; // Position of text overlay
  final DateTime createdAt;
  final DateTime expiresAt; // Stories expire after 24 hours

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExpiringSoon => expiresAt.difference(DateTime.now()).inHours < 6;
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  StoryModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImage,
    UserRole? userRole,
    String? imageUrl,
    String? text,
    Color? textColor,
    TextPosition? textPosition,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      userRole: userRole ?? this.userRole,
      imageUrl: imageUrl ?? this.imageUrl,
      text: text ?? this.text,
      textColor: textColor ?? this.textColor,
      textPosition: textPosition ?? this.textPosition,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userProfileImage: json['userProfileImage'] as String?,
      userRole: UserRole.values.firstWhere(
        (e) => e.name == json['userRole'],
        orElse: () => UserRole.seller,
      ),
      imageUrl: json['imageUrl'] as String,
      text: json['text'] as String?,
      textColor: json['textColor'] != null
          ? Color(json['textColor'] as int)
          : null,
      textPosition: json['textPosition'] != null
          ? TextPosition.values.firstWhere(
              (e) => e.name == json['textPosition'],
              orElse: () => TextPosition.center,
            )
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'userRole': userRole.name,
      'imageUrl': imageUrl,
      'text': text,
      'textColor': textColor?.value,
      'textPosition': textPosition?.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

enum TextPosition {
  top,
  center,
  bottom,
}

