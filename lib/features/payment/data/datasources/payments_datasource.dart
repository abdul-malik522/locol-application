import 'dart:async';

import 'package:localtrade/features/payment/data/models/payment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class PaymentsDataSource {
  PaymentsDataSource._();
  static final PaymentsDataSource instance = PaymentsDataSource._();
  final _uuid = const Uuid();

  static const String _paymentsKey = 'payments';

  Future<List<PaymentModel>> getAllPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? paymentsJson = prefs.getString(_paymentsKey);
    if (paymentsJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(paymentsJson) as List<dynamic>;
      return decoded
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Future<List<PaymentModel>> getPaymentsByUser(String userId) async {
    final allPayments = await getAllPayments();
    return allPayments.where((p) => p.userId == userId).toList();
  }

  Future<PaymentModel?> getPaymentByOrderId(String orderId) async {
    final allPayments = await getAllPayments();
    try {
      return allPayments.firstWhere((p) => p.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final allPayments = await getAllPayments();
    try {
      return allPayments.firstWhere((p) => p.id == paymentId);
    } catch (_) {
      return null;
    }
  }

  Future<PaymentModel> createPayment(PaymentModel payment) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PaymentModel> existingPayments = await getAllPayments();
    existingPayments.add(payment);
    final String encoded = json.encode(existingPayments.map((e) => e.toJson()).toList());
    await prefs.setString(_paymentsKey, encoded);
    return payment;
  }

  Future<PaymentModel> updatePayment(PaymentModel payment) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PaymentModel> existingPayments = await getAllPayments();
    final index = existingPayments.indexWhere((p) => p.id == payment.id);
    if (index == -1) throw Exception('Payment not found');
    existingPayments[index] = payment;
    final String encoded = json.encode(existingPayments.map((e) => e.toJson()).toList());
    await prefs.setString(_paymentsKey, encoded);
    return payment;
  }
}

