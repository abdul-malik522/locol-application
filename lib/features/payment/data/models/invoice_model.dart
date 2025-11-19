import 'package:flutter/material.dart';

import 'package:localtrade/features/orders/data/models/order_model.dart';

@immutable
class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.orderId,
    required this.invoiceNumber,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    this.discountAmount,
    this.shippingAmount,
    this.notes,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? paidDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : issueDate = issueDate ?? DateTime.now(),
        dueDate = dueDate ?? DateTime.now().add(const Duration(days: 30)),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        paidDate = paidDate;

  final String id;
  final String orderId;
  final String invoiceNumber; // e.g., "INV-2024-001"
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double? discountAmount;
  final double? shippingAmount;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final String? notes;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvoiceModel copyWith({
    String? id,
    String? orderId,
    String? invoiceNumber,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? sellerName,
    List<InvoiceItem>? items,
    double? subtotal,
    double? discountAmount,
    double? shippingAmount,
    double? taxAmount,
    double? totalAmount,
    String? currency,
    String? notes,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? paidDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingAmount: shippingAmount ?? this.shippingAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      buyerId: json['buyerId'] as String,
      buyerName: json['buyerName'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      shippingAmount: (json['shippingAmount'] as num?)?.toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      notes: json['notes'] as String?,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'invoiceNumber': invoiceNumber,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'shippingAmount': shippingAmount,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'notes': notes,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPaid => paidDate != null;
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);
}

@immutable
class InvoiceItem {
  const InvoiceItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.description,
  });

  final String productName;
  final String? description;
  final String quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceItem copyWith({
    String? productName,
    String? description,
    String? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return InvoiceItem(
      productName: productName ?? this.productName,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      productName: json['productName'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

