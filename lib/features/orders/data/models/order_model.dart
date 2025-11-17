import 'package:flutter/material.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/theme/app_colors.dart';

@immutable
class OrderModel {
  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.postId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    this.deliveryDate,
    this.notes,
    this.rating,
    this.review,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String orderNumber;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String postId;
  final String productName;
  final String? productImage;
  final String quantity;
  final double price;
  final double totalAmount;
  final OrderStatus status;
  final String deliveryAddress;
  final DateTime? deliveryDate;
  final String? notes;
  final double? rating;
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get statusText => status.label;

  Color get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.accepted:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  bool get canCancel => status == OrderStatus.pending;

  bool get canRate => status == OrderStatus.completed && rating == null;

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? sellerName,
    String? postId,
    String? productName,
    String? productImage,
    String? quantity,
    double? price,
    double? totalAmount,
    OrderStatus? status,
    String? deliveryAddress,
    DateTime? deliveryDate,
    String? notes,
    double? rating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      postId: postId ?? this.postId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      buyerId: json['buyerId'] as String,
      buyerName: json['buyerName'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      postId: json['postId'] as String,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String?,
      quantity: json['quantity'] as String,
      price: (json['price'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == (json['status'] as String),
        orElse: () => OrderStatus.pending,
      ),
      deliveryAddress: json['deliveryAddress'] as String,
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'] as String)
          : null,
      notes: json['notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'postId': postId,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'price': price,
      'totalAmount': totalAmount,
      'status': status.name,
      'deliveryAddress': deliveryAddress,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'notes': notes,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

