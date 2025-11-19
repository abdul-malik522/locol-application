import 'package:flutter/material.dart';

import 'package:localtrade/features/payment/data/models/payment_method_model.dart';

@immutable
class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    this.transactionId,
    this.gatewayResponse,
    this.failureReason,
    this.refundAmount,
    this.refundReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        completedAt = completedAt;

  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String currency; // e.g., "USD", "EUR"
  final PaymentMethodModel method;
  final PaymentStatus status;
  final String? transactionId; // Gateway transaction ID
  final String? gatewayResponse; // Raw response from payment gateway
  final String? failureReason;
  final double? refundAmount;
  final String? refundReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? amount,
    String? currency,
    PaymentMethodModel? method,
    PaymentStatus? status,
    String? transactionId,
    String? gatewayResponse,
    String? failureReason,
    double? refundAmount,
    String? refundReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      gatewayResponse: gatewayResponse ?? this.gatewayResponse,
      failureReason: failureReason ?? this.failureReason,
      refundAmount: refundAmount ?? this.refundAmount,
      refundReason: refundReason ?? this.refundReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      method: PaymentMethodModel.fromJson(json['method'] as Map<String, dynamic>),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: json['transactionId'] as String?,
      gatewayResponse: json['gatewayResponse'] as String?,
      failureReason: json['failureReason'] as String?,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      refundReason: json['refundReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'method': method.toJson(),
      'status': status.name,
      'transactionId': transactionId,
      'gatewayResponse': gatewayResponse,
      'failureReason': failureReason,
      'refundAmount': refundAmount,
      'refundReason': refundReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.processing;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isRefunded => status == PaymentStatus.refunded;
}

