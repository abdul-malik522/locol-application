import 'dart:async';

import 'package:localtrade/features/inventory/data/models/pre_order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class PreOrdersDataSource {
  PreOrdersDataSource._();
  static final PreOrdersDataSource instance = PreOrdersDataSource._();
  final _uuid = const Uuid();

  static const String _preOrdersKeyPrefix = 'pre_orders_';

  String _getPreOrdersKey(String userId) => '$_preOrdersKeyPrefix$userId';

  Future<List<PreOrderModel>> getPreOrders(String userId, {bool? asBuyer, bool? asSeller}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? preOrdersJson = prefs.getString(_getPreOrdersKey(userId));
    if (preOrdersJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(preOrdersJson) as List<dynamic>;
      final allPreOrders = decoded
          .map((e) => PreOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (asBuyer == true) {
        return allPreOrders.where((p) => p.buyerId == userId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else if (asSeller == true) {
        return allPreOrders.where((p) => p.sellerId == userId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return allPreOrders..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Future<PreOrderModel?> getPreOrderById(String preOrderId, String userId) async {
    final preOrders = await getPreOrders(userId);
    try {
      return preOrders.firstWhere((p) => p.id == preOrderId);
    } catch (_) {
      return null;
    }
  }

  Future<PreOrderModel> createPreOrder(PreOrderModel preOrder) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PreOrderModel> existingPreOrders = await getPreOrders(preOrder.sellerId);
    existingPreOrders.add(preOrder);
    final String encoded = json.encode(existingPreOrders.map((e) => e.toJson()).toList());
    await prefs.setString(_getPreOrdersKey(preOrder.sellerId), encoded);
    return preOrder;
  }

  Future<PreOrderModel> updatePreOrder(PreOrderModel preOrder) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PreOrderModel> existingPreOrders = await getPreOrders(preOrder.sellerId);
    final index = existingPreOrders.indexWhere((p) => p.id == preOrder.id);
    if (index == -1) throw Exception('Pre-order not found');
    existingPreOrders[index] = preOrder;
    final String encoded = json.encode(existingPreOrders.map((e) => e.toJson()).toList());
    await prefs.setString(_getPreOrdersKey(preOrder.sellerId), encoded);
    return preOrder;
  }

  Future<void> deletePreOrder(String preOrderId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PreOrderModel> existingPreOrders = await getPreOrders(userId);
    existingPreOrders.removeWhere((p) => p.id == preOrderId);
    final String encoded = json.encode(existingPreOrders.map((e) => e.toJson()).toList());
    await prefs.setString(_getPreOrdersKey(userId), encoded);
  }
}

