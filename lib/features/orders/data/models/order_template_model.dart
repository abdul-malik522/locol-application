import 'package:flutter/material.dart';

@immutable
class OrderTemplateModel {
  OrderTemplateModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.postId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.price,
    required this.deliveryAddress,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String name; // User-friendly name for the template
  final String postId; // Reference to the original post
  final String productName;
  final String? productImage;
  final String quantity;
  final double price;
  final String deliveryAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalAmount => price; // For templates, we'll calculate based on quantity when creating order

  OrderTemplateModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? postId,
    String? productName,
    String? productImage,
    String? quantity,
    double? price,
    String? deliveryAddress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderTemplateModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      postId: postId ?? this.postId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory OrderTemplateModel.fromJson(Map<String, dynamic> json) {
    return OrderTemplateModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      postId: json['postId'] as String,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String?,
      quantity: json['quantity'] as String,
      price: (json['price'] as num).toDouble(),
      deliveryAddress: json['deliveryAddress'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'postId': postId,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'price': price,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

