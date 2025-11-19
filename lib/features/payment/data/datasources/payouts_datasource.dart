import 'dart:async';

import 'package:localtrade/features/payment/data/models/payout_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class PayoutsDataSource {
  PayoutsDataSource._();
  static final PayoutsDataSource instance = PayoutsDataSource._();
  final _uuid = const Uuid();

  static const String _payoutsKeyPrefix = 'payouts_';

  String _getPayoutsKey(String userId) => '$_payoutsKeyPrefix$userId';

  Future<List<PayoutModel>> getPayouts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? payoutsJson = prefs.getString(_getPayoutsKey(userId));
    if (payoutsJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(payoutsJson) as List<dynamic>;
      return decoded
          .map((e) => PayoutModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Future<PayoutModel?> getPayoutById(String payoutId, String userId) async {
    final payouts = await getPayouts(userId);
    try {
      return payouts.firstWhere((p) => p.id == payoutId);
    } catch (_) {
      return null;
    }
  }

  Future<PayoutModel> createPayout(PayoutModel payout) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PayoutModel> existingPayouts = await getPayouts(payout.userId);
    existingPayouts.add(payout);
    final String encoded = json.encode(existingPayouts.map((e) => e.toJson()).toList());
    await prefs.setString(_getPayoutsKey(payout.userId), encoded);
    return payout;
  }

  Future<PayoutModel> updatePayout(PayoutModel payout) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PayoutModel> existingPayouts = await getPayouts(payout.userId);
    final index = existingPayouts.indexWhere((p) => p.id == payout.id);
    if (index == -1) throw Exception('Payout not found');
    existingPayouts[index] = payout;
    final String encoded = json.encode(existingPayouts.map((e) => e.toJson()).toList());
    await prefs.setString(_getPayoutsKey(payout.userId), encoded);
    return payout;
  }
}

