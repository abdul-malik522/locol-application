import 'dart:async';

import 'package:localtrade/features/delivery/data/models/delivery_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class DeliveryDataSource {
  DeliveryDataSource._();
  static final DeliveryDataSource instance = DeliveryDataSource._();
  final _uuid = const Uuid();

  static const String _deliveriesKey = 'deliveries';
  static const String _routesKey = 'delivery_routes';

  // Deliveries
  Future<List<DeliveryModel>> getAllDeliveries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? deliveriesJson = prefs.getString(_deliveriesKey);
    if (deliveriesJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(deliveriesJson) as List<dynamic>;
      return decoded
          .map((e) => DeliveryModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Future<DeliveryModel?> getDeliveryByOrderId(String orderId) async {
    final allDeliveries = await getAllDeliveries();
    try {
      return allDeliveries.firstWhere((d) => d.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<DeliveryModel?> getDeliveryById(String deliveryId) async {
    final allDeliveries = await getAllDeliveries();
    try {
      return allDeliveries.firstWhere((d) => d.id == deliveryId);
    } catch (_) {
      return null;
    }
  }

  Future<List<DeliveryModel>> getDeliveriesByStatus(DeliveryStatus status) async {
    final allDeliveries = await getAllDeliveries();
    return allDeliveries.where((d) => d.status == status).toList();
  }

  Future<DeliveryModel> createDelivery(DeliveryModel delivery) async {
    final prefs = await SharedPreferences.getInstance();
    final List<DeliveryModel> existingDeliveries = await getAllDeliveries();
    existingDeliveries.add(delivery);
    final String encoded = json.encode(existingDeliveries.map((e) => e.toJson()).toList());
    await prefs.setString(_deliveriesKey, encoded);
    return delivery;
  }

  Future<DeliveryModel> updateDelivery(DeliveryModel delivery) async {
    final prefs = await SharedPreferences.getInstance();
    final List<DeliveryModel> existingDeliveries = await getAllDeliveries();
    final index = existingDeliveries.indexWhere((d) => d.id == delivery.id);
    if (index == -1) throw Exception('Delivery not found');
    existingDeliveries[index] = delivery;
    final String encoded = json.encode(existingDeliveries.map((e) => e.toJson()).toList());
    await prefs.setString(_deliveriesKey, encoded);
    return delivery;
  }

  // Delivery Routes
  Future<List<DeliveryRouteModel>> getAllRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? routesJson = prefs.getString(_routesKey);
    if (routesJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(routesJson) as List<dynamic>;
      return decoded
          .map((e) => DeliveryRouteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<DeliveryRouteModel?> getRouteById(String routeId) async {
    final allRoutes = await getAllRoutes();
    try {
      return allRoutes.firstWhere((r) => r.id == routeId);
    } catch (_) {
      return null;
    }
  }

  Future<DeliveryRouteModel> createRoute(DeliveryRouteModel route) async {
    final prefs = await SharedPreferences.getInstance();
    final List<DeliveryRouteModel> existingRoutes = await getAllRoutes();
    existingRoutes.add(route);
    final String encoded = json.encode(existingRoutes.map((e) => e.toJson()).toList());
    await prefs.setString(_routesKey, encoded);
    return route;
  }

  Future<DeliveryRouteModel> updateRoute(DeliveryRouteModel route) async {
    final prefs = await SharedPreferences.getInstance();
    final List<DeliveryRouteModel> existingRoutes = await getAllRoutes();
    final index = existingRoutes.indexWhere((r) => r.id == route.id);
    if (index == -1) throw Exception('Route not found');
    existingRoutes[index] = route;
    final String encoded = json.encode(existingRoutes.map((e) => e.toJson()).toList());
    await prefs.setString(_routesKey, encoded);
    return route;
  }
}

