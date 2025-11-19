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
    this.deliveryInstructions,
    this.deliveryDate,
    this.scheduledDate,
    this.recurringOrderId,
    this.notes,
    this.cancellationReason,
    this.disputeId,
    this.trackingId,
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
  final String? deliveryInstructions; // Special instructions for delivery (e.g., "Leave at back door", "Ring doorbell")
  final DateTime? deliveryDate;
  final DateTime? scheduledDate;
  final String? recurringOrderId; // Link to recurring order configuration
  final String? notes;
  final String? cancellationReason; // Reason for cancellation (if cancelled)
  final String? disputeId; // Link to dispute if one has been filed
  final String? trackingId; // Link to delivery tracking if tracking is active
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

  bool get isScheduled => scheduledDate != null && scheduledDate!.isAfter(DateTime.now());

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
    String? deliveryInstructions,
    DateTime? deliveryDate,
    DateTime? scheduledDate,
    String? recurringOrderId,
    String? notes,
    String? cancellationReason,
    String? disputeId,
    String? trackingId,
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
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      recurringOrderId: recurringOrderId ?? this.recurringOrderId,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      disputeId: disputeId ?? this.disputeId,
      trackingId: trackingId ?? this.trackingId,
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
      deliveryInstructions: json['deliveryInstructions'] as String?,
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'] as String)
          : null,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      recurringOrderId: json['recurringOrderId'] as String?,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      disputeId: json['disputeId'] as String?,
      trackingId: json['trackingId'] as String?,
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
      'deliveryInstructions': deliveryInstructions,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'recurringOrderId': recurringOrderId,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'disputeId': disputeId,
      'trackingId': trackingId,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

