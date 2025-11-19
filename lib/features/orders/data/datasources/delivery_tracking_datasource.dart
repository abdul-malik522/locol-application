import 'dart:async';
import 'dart:math';

import 'package:localtrade/features/orders/data/models/delivery_tracking_model.dart';
import 'package:uuid/uuid.dart';

class DeliveryTrackingDataSource {
  DeliveryTrackingDataSource._();
  static final DeliveryTrackingDataSource instance = DeliveryTrackingDataSource._();
  final _uuid = const Uuid();
  final _random = Random();

  final Map<String, DeliveryTrackingModel> _tracking = {};
  final Map<String, StreamController<DeliveryTrackingModel>> _streamControllers = {};

  /// Get tracking information for an order
  Future<DeliveryTrackingModel?> getTracking(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tracking[orderId];
  }

  /// Start tracking for an order (creates initial tracking entry)
  Future<DeliveryTrackingModel> startTracking(
    String orderId,
    double destinationLat,
    double destinationLon,
    String destinationAddress,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Get seller location (mock - in real app, this would come from seller profile)
    final sellerLat = 37.7749 + (_random.nextDouble() - 0.5) * 0.1;
    final sellerLon = -122.4194 + (_random.nextDouble() - 0.5) * 0.1;

    final tracking = DeliveryTrackingModel(
      orderId: orderId,
      status: DeliveryStatus.preparing,
      currentLocation: DeliveryLocation(
        latitude: sellerLat,
        longitude: sellerLon,
        timestamp: DateTime.now(),
        address: 'Seller Location',
      ),
      estimatedDeliveryTime: DateTime.now().add(const Duration(hours: 2)),
      deliveryPersonName: 'John Delivery',
      deliveryPersonPhone: '+1 (555) 123-4567',
    );

    _tracking[orderId] = tracking;
    return tracking;
  }

  /// Update tracking status and location
  Future<DeliveryTrackingModel> updateTracking(
    String orderId,
    DeliveryStatus newStatus,
    double? lat,
    double? lon,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final existing = _tracking[orderId];
    if (existing == null) {
      throw Exception('Tracking not found for order');
    }

    final updated = existing.copyWith(
      status: newStatus,
      currentLocation: lat != null && lon != null
          ? DeliveryLocation(
              latitude: lat,
              longitude: lon,
              timestamp: DateTime.now(),
            )
          : existing.currentLocation,
      actualDeliveryTime: newStatus == DeliveryStatus.delivered
          ? DateTime.now()
          : existing.actualDeliveryTime,
    );

    _tracking[orderId] = updated;

    // Notify stream listeners
    final controller = _streamControllers[orderId];
    if (controller != null && !controller.isClosed) {
      controller.add(updated);
    }

    return updated;
  }

  /// Simulate delivery progress (for mock/demo purposes)
  Future<void> simulateDeliveryProgress(String orderId) async {
    final tracking = _tracking[orderId];
    if (tracking == null || tracking.isDelivered) return;

    // Simulate status progression
    final statuses = DeliveryStatus.values;
    final currentIndex = statuses.indexOf(tracking.status);
    if (currentIndex < statuses.length - 2) {
      final nextStatus = statuses[currentIndex + 1];
      await updateTracking(orderId, nextStatus, null, null);
    }
  }

  /// Get real-time tracking stream
  Stream<DeliveryTrackingModel> watchTracking(String orderId) {
    if (!_streamControllers.containsKey(orderId)) {
      _streamControllers[orderId] = StreamController<DeliveryTrackingModel>.broadcast();
      final tracking = _tracking[orderId];
      if (tracking != null) {
        _streamControllers[orderId]!.add(tracking);
      }
    }
    return _streamControllers[orderId]!.stream;
  }

  /// Stop tracking stream
  void stopTracking(String orderId) {
    final controller = _streamControllers[orderId];
    if (controller != null && !controller.isClosed) {
      controller.close();
      _streamControllers.remove(orderId);
    }
  }

  /// Get route waypoints (mock route for visualization)
  List<DeliveryLocation> getRouteWaypoints(String orderId) {
    final tracking = _tracking[orderId];
    if (tracking == null) return [];

    // Mock waypoints between current location and destination
    // In a real app, this would use a routing service
    return [
      tracking.currentLocation,
      // Add intermediate points (simplified)
    ];
  }
}

