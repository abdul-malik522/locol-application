import 'dart:async';

import 'package:localtrade/features/payment/data/models/payment_method_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class PaymentMethodsDataSource {
  PaymentMethodsDataSource._();
  static final PaymentMethodsDataSource instance = PaymentMethodsDataSource._();
  final _uuid = const Uuid();

  static const String _methodsKeyPrefix = 'payment_methods_';

  String _getMethodsKey(String userId) => '$_methodsKeyPrefix$userId';

  Future<List<PaymentMethodModel>> getPaymentMethods(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? methodsJson = prefs.getString(_getMethodsKey(userId));
    if (methodsJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(methodsJson) as List<dynamic>;
      return decoded
          .map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addPaymentMethod(PaymentMethodModel method) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PaymentMethodModel> existingMethods = await getPaymentMethods(method.userId);
    
    // If this is set as default, unset others
    if (method.isDefault) {
      existingMethods.forEach((m) {
        if (m.isDefault) {
          existingMethods[existingMethods.indexOf(m)] = m.copyWith(isDefault: false);
        }
      });
    }
    
    existingMethods.add(method);
    final String encoded = json.encode(existingMethods.map((e) => e.toJson()).toList());
    await prefs.setString(_getMethodsKey(method.userId), encoded);
  }

  Future<void> updatePaymentMethod(PaymentMethodModel method) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PaymentMethodModel> existingMethods = await getPaymentMethods(method.userId);
    final index = existingMethods.indexWhere((m) => m.id == method.id);
    if (index == -1) throw Exception('Payment method not found');

    // If this is set as default, unset others
    if (method.isDefault) {
      for (int i = 0; i < existingMethods.length; i++) {
        if (i != index && existingMethods[i].isDefault) {
          existingMethods[i] = existingMethods[i].copyWith(isDefault: false);
        }
      }
    }

    existingMethods[index] = method;
    final String encoded = json.encode(existingMethods.map((e) => e.toJson()).toList());
    await prefs.setString(_getMethodsKey(method.userId), encoded);
  }

  Future<void> deletePaymentMethod(String methodId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PaymentMethodModel> existingMethods = await getPaymentMethods(userId);
    existingMethods.removeWhere((m) => m.id == methodId);
    final String encoded = json.encode(existingMethods.map((e) => e.toJson()).toList());
    await prefs.setString(_getMethodsKey(userId), encoded);
  }

  Future<PaymentMethodModel?> getDefaultPaymentMethod(String userId) async {
    final methods = await getPaymentMethods(userId);
    try {
      return methods.firstWhere((m) => m.isDefault && m.isActive);
    } catch (_) {
      return null;
    }
  }
}

