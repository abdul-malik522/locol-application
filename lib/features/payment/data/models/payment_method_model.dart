import 'package:flutter/material.dart';

enum PaymentMethodType {
  creditCard('Credit Card', Icons.credit_card, Colors.blue),
  debitCard('Debit Card', Icons.credit_card, Colors.green),
  bankTransfer('Bank Transfer', Icons.account_balance, Colors.purple),
  wallet('Wallet', Icons.account_balance_wallet, Colors.orange),
  cash('Cash on Delivery', Icons.money, Colors.grey);

  const PaymentMethodType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum PaymentStatus {
  pending('Pending', Icons.hourglass_empty, Colors.orange),
  processing('Processing', Icons.sync, Colors.blue),
  completed('Completed', Icons.check_circle, Colors.green),
  failed('Failed', Icons.error, Colors.red),
  refunded('Refunded', Icons.refresh, Colors.purple),
  cancelled('Cancelled', Icons.cancel, Colors.grey);

  const PaymentStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class PaymentMethodModel {
  const PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.label,
    this.cardLast4,
    this.cardBrand,
    this.bankName,
    this.accountNumber,
    this.isDefault = false,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final PaymentMethodType type;
  final String label; // e.g., "Visa ending in 1234"
  final String? cardLast4; // Last 4 digits of card
  final String? cardBrand; // Visa, Mastercard, etc.
  final String? bankName; // For bank transfers
  final String? accountNumber; // Masked account number
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethodModel copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? label,
    String? cardLast4,
    String? cardBrand,
    String? bankName,
    String? accountNumber,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      label: label ?? this.label,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardBrand: cardBrand ?? this.cardBrand,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentMethodType.creditCard,
      ),
      label: json['label'] as String,
      cardLast4: json['cardLast4'] as String?,
      cardBrand: json['cardBrand'] as String?,
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'label': label,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

