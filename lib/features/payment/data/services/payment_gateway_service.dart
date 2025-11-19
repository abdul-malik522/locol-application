import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:localtrade/features/payment/data/models/payment_method_model.dart';
import 'package:localtrade/features/payment/data/models/payment_model.dart';
import 'package:uuid/uuid.dart';

enum PaymentGateway {
  stripe('Stripe', Icons.credit_card),
  paypal('PayPal', Icons.payment),
  square('Square', Icons.square);

  const PaymentGateway(this.name, this.icon);
  final String name;
  final IconData icon;
}

class PaymentGatewayService {
  PaymentGatewayService._();
  static final PaymentGatewayService instance = PaymentGatewayService._();
  final _uuid = const Uuid();
  final _random = Random();

  /// Process payment through a payment gateway
  Future<PaymentModel> processPayment({
    required PaymentModel payment,
    required PaymentGateway gateway,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2 + _random.nextInt(3)));

    // Mock payment processing
    // In a real app, this would call the actual payment gateway API
    final transactionId = '${gateway.name.toUpperCase()}_${_uuid.v4().substring(0, 8).toUpperCase()}';
    
    // Simulate success/failure (90% success rate for demo)
    final isSuccess = _random.nextDouble() > 0.1;

    if (isSuccess) {
      return payment.copyWith(
        status: PaymentStatus.completed,
        transactionId: transactionId,
        gatewayResponse: 'Payment processed successfully via ${gateway.name}',
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      return payment.copyWith(
        status: PaymentStatus.failed,
        transactionId: transactionId,
        gatewayResponse: 'Payment failed via ${gateway.name}',
        failureReason: 'Insufficient funds or card declined',
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Refund a payment
  Future<PaymentModel> refundPayment({
    required PaymentModel payment,
    required double refundAmount,
    String? reason,
  }) async {
    await Future.delayed(Duration(seconds: 2));

    if (payment.status != PaymentStatus.completed) {
      throw Exception('Can only refund completed payments');
    }

    final refundTransactionId = 'REFUND_${_uuid.v4().substring(0, 8).toUpperCase()}';
    
    return payment.copyWith(
      status: PaymentStatus.refunded,
      refundAmount: refundAmount,
      refundReason: reason,
      transactionId: '${payment.transactionId}_$refundTransactionId',
      gatewayResponse: 'Refund processed successfully',
      updatedAt: DateTime.now(),
    );
  }

  /// Verify payment status with gateway
  Future<PaymentStatus> verifyPaymentStatus(String transactionId) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock: randomly return completed or processing
    return _random.nextBool() ? PaymentStatus.completed : PaymentStatus.processing;
  }
}

