import 'package:flutter/material.dart';

enum PreOrderStatus {
  pending('Pending', Icons.hourglass_empty, Colors.orange),
  confirmed('Confirmed', Icons.check_circle, Colors.green),
  fulfilled('Fulfilled', Icons.done_all, Colors.blue),
  cancelled('Cancelled', Icons.cancel, Colors.red);

  const PreOrderStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class PreOrderModel {
  const PreOrderModel({
    required this.id,
    required this.postId,
    required this.productName,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.quantity,
    required this.expectedAvailabilityDate,
    required this.status,
    this.quantityRequested,
    this.price,
    this.totalAmount,
    this.notes,
    this.fulfilledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String postId;
  final String productName;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String quantity;
  final DateTime expectedAvailabilityDate; // When product will be available
  final PreOrderStatus status;
  final String? quantityRequested; // Specific quantity requested
  final double? price; // Agreed price (may differ from post price)
  final double? totalAmount;
  final String? notes; // Special notes or requirements
  final DateTime? fulfilledAt; // When pre-order was fulfilled
  final DateTime createdAt;
  final DateTime updatedAt;

  PreOrderModel copyWith({
    String? id,
    String? postId,
    String? productName,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? sellerName,
    String? quantity,
    DateTime? expectedAvailabilityDate,
    PreOrderStatus? status,
    String? quantityRequested,
    double? price,
    double? totalAmount,
    String? notes,
    DateTime? fulfilledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PreOrderModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      productName: productName ?? this.productName,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      quantity: quantity ?? this.quantity,
      expectedAvailabilityDate: expectedAvailabilityDate ?? this.expectedAvailabilityDate,
      status: status ?? this.status,
      quantityRequested: quantityRequested ?? this.quantityRequested,
      price: price ?? this.price,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory PreOrderModel.fromJson(Map<String, dynamic> json) {
    return PreOrderModel(
      id: json['id'] as String,
      postId: json['postId'] as String,
      productName: json['productName'] as String,
      buyerId: json['buyerId'] as String,
      buyerName: json['buyerName'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      quantity: json['quantity'] as String,
      expectedAvailabilityDate: DateTime.parse(json['expectedAvailabilityDate'] as String),
      status: PreOrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PreOrderStatus.pending,
      ),
      quantityRequested: json['quantityRequested'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      fulfilledAt: json['fulfilledAt'] != null
          ? DateTime.parse(json['fulfilledAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'productName': productName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'quantity': quantity,
      'expectedAvailabilityDate': expectedAvailabilityDate.toIso8601String(),
      'status': status.name,
      'quantityRequested': quantityRequested,
      'price': price,
      'totalAmount': totalAmount,
      'notes': notes,
      'fulfilledAt': fulfilledAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == PreOrderStatus.pending;
  bool get isConfirmed => status == PreOrderStatus.confirmed;
  bool get isFulfilled => status == PreOrderStatus.fulfilled;
  bool get isCancelled => status == PreOrderStatus.cancelled;
}

