import 'package:flutter/material.dart';

enum WalletTransactionType {
  deposit('Deposit', Icons.add_circle, Colors.green),
  withdrawal('Withdrawal', Icons.remove_circle, Colors.red),
  payment('Payment', Icons.payment, Colors.blue),
  refund('Refund', Icons.refresh, Colors.purple),
  payout('Payout', Icons.account_balance_wallet, Colors.orange);

  const WalletTransactionType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum WalletTransactionStatus {
  pending('Pending', Icons.hourglass_empty, Colors.orange),
  processing('Processing', Icons.sync, Colors.blue),
  completed('Completed', Icons.check_circle, Colors.green),
  failed('Failed', Icons.error, Colors.red),
  cancelled('Cancelled', Icons.cancel, Colors.grey);

  const WalletTransactionStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class WalletModel {
  const WalletModel({
    required this.userId,
    required this.balance,
    required this.currency,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  final String userId;
  final double balance;
  final String currency; // e.g., "USD"
  final DateTime lastUpdated;

  WalletModel copyWith({
    String? userId,
    double? balance,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return WalletModel(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: json['userId'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'balance': balance,
      'currency': currency,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

@immutable
class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    this.description,
    this.orderId,
    this.paymentId,
    this.referenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final WalletTransactionType type;
  final double amount;
  final String currency;
  final WalletTransactionStatus status;
  final String? description;
  final String? orderId; // Related order if applicable
  final String? paymentId; // Related payment if applicable
  final String? referenceId; // External reference (e.g., bank transaction ID)
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletTransactionModel copyWith({
    String? id,
    String? userId,
    WalletTransactionType? type,
    double? amount,
    String? currency,
    WalletTransactionStatus? status,
    String? description,
    String? orderId,
    String? paymentId,
    String? referenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      description: description ?? this.description,
      orderId: orderId ?? this.orderId,
      paymentId: paymentId ?? this.paymentId,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: WalletTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WalletTransactionType.payment,
      ),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: WalletTransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WalletTransactionStatus.pending,
      ),
      description: json['description'] as String?,
      orderId: json['orderId'] as String?,
      paymentId: json['paymentId'] as String?,
      referenceId: json['referenceId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'description': description,
      'orderId': orderId,
      'paymentId': paymentId,
      'referenceId': referenceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isCompleted => status == WalletTransactionStatus.completed;
  bool get isPending => status == WalletTransactionStatus.pending || status == WalletTransactionStatus.processing;
}

