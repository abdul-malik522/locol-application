import 'dart:io';

import 'package:localtrade/core/constants/app_constants.dart';

class DraftPostModel {
  const DraftPostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.price,
    this.quantity,
    this.category,
    this.imagePaths = const [],
    this.location,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final double? price;
  final String? quantity;
  final String? category;
  final List<String> imagePaths; // Local file paths
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  DraftPostModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? price,
    String? quantity,
    String? category,
    List<String>? imagePaths,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DraftPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      imagePaths: imagePaths ?? this.imagePaths,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'price': price,
      'quantity': quantity,
      'category': category,
      'imagePaths': imagePaths,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DraftPostModel.fromJson(Map<String, dynamic> json) {
    return DraftPostModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num?)?.toDouble(),
      quantity: json['quantity'] as String?,
      category: json['category'] as String?,
      imagePaths: (json['imagePaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  bool get isEmpty {
    return title.isEmpty &&
        description.isEmpty &&
        price == null &&
        quantity == null &&
        category == null &&
        imagePaths.isEmpty &&
        location == null;
  }
}

