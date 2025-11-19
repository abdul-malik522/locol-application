import 'package:flutter/material.dart';

enum PayoutStatus {
  pending('Pending', Icons.hourglass_empty, Colors.orange),
  processing('Processing', Icons.sync, Colors.blue),
  completed('Completed', Icons.check_circle, Colors.green),
  failed('Failed', Icons.error, Colors.red),
  cancelled('Cancelled', Icons.cancel, Colors.grey);

  const PayoutStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum PayoutMethod {
  bankTransfer('Bank Transfer', Icons.account_balance, Colors.blue),
  paypal('PayPal', Icons.payment, Colors.indigo),
  stripe('Stripe', Icons.credit_card, Colors.purple);

  const PayoutMethod(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class PayoutModel {
  const PayoutModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    this.bankAccountNumber,
    this.bankName,
    this.accountHolderName,
    this.routingNumber,
    this.paypalEmail,
    this.stripeAccountId,
    this.transactionId,
    this.failureReason,
    this.processedAt,
    DateTime? requestedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : requestedAt = requestedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PayoutMethod method;
  final PayoutStatus status;
  final String? bankAccountNumber; // Masked
  final String? bankName;
  final String? accountHolderName;
  final String? routingNumber;
  final String? paypalEmail;
  final String? stripeAccountId;
  final String? transactionId; // External transaction ID
  final String? failureReason;
  final DateTime? processedAt;
  final DateTime requestedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PayoutModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    PayoutMethod? method,
    PayoutStatus? status,
    String? bankAccountNumber,
    String? bankName,
    String? accountHolderName,
    String? routingNumber,
    String? paypalEmail,
    String? stripeAccountId,
    String? transactionId,
    String? failureReason,
    DateTime? processedAt,
    DateTime? requestedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      status: status ?? this.status,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      routingNumber: routingNumber ?? this.routingNumber,
      paypalEmail: paypalEmail ?? this.paypalEmail,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      transactionId: transactionId ?? this.transactionId,
      failureReason: failureReason ?? this.failureReason,
      processedAt: processedAt ?? this.processedAt,
      requestedAt: requestedAt ?? this.requestedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      method: PayoutMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PayoutMethod.bankTransfer,
      ),
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PayoutStatus.pending,
      ),
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankName: json['bankName'] as String?,
      accountHolderName: json['accountHolderName'] as String?,
      routingNumber: json['routingNumber'] as String?,
      paypalEmail: json['paypalEmail'] as String?,
      stripeAccountId: json['stripeAccountId'] as String?,
      transactionId: json['transactionId'] as String?,
      failureReason: json['failureReason'] as String?,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'method': method.name,
      'status': status.name,
      'bankAccountNumber': bankAccountNumber,
      'bankName': bankName,
      'accountHolderName': accountHolderName,
      'routingNumber': routingNumber,
      'paypalEmail': paypalEmail,
      'stripeAccountId': stripeAccountId,
      'transactionId': transactionId,
      'failureReason': failureReason,
      'processedAt': processedAt?.toIso8601String(),
      'requestedAt': requestedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isCompleted => status == PayoutStatus.completed;
  bool get isPending => status == PayoutStatus.pending || status == PayoutStatus.processing;
  bool get isFailed => status == PayoutStatus.failed;
}

