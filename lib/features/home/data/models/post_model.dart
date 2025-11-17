import 'package:flutter/material.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/utils/location_helper.dart';

@immutable
class PostModel {
  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.userRole,
    required this.postType,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.category,
    this.price,
    this.quantity,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final UserRole userRole;
  final PostType postType;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String category;
  final double? price;
  final String? quantity;
  final String location;
  final double latitude;
  final double longitude;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  double? distanceFromUser(double userLat, double userLon) {
    return LocationHelper.calculateDistance(
      userLat,
      userLon,
      latitude,
      longitude,
    );
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImage,
    UserRole? userRole,
    PostType? postType,
    String? title,
    String? description,
    List<String>? imageUrls,
    String? category,
    double? price,
    String? quantity,
    String? location,
    double? latitude,
    double? longitude,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      userRole: userRole ?? this.userRole,
      postType: postType ?? this.postType,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userProfileImage: json['userProfileImage'] as String?,
      userRole: UserRole.values.firstWhere(
        (role) => role.name == (json['userRole'] as String),
        orElse: () => UserRole.seller,
      ),
      postType: PostType.values.firstWhere(
        (type) => type.name == (json['postType'] as String),
        orElse: () => PostType.product,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      category: json['category'] as String,
      price: (json['price'] as num?)?.toDouble(),
      quantity: json['quantity'] as String?,
      location: json['location'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'userRole': userRole.name,
      'postType': postType.name,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'category': category,
      'price': price,
      'quantity': quantity,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

