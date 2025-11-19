import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:localtrade/features/delivery/data/models/delivery_model.dart';

class RouteOptimizationService {
  RouteOptimizationService._();
  static final RouteOptimizationService instance = RouteOptimizationService._();
  final _random = Random();

  /// Optimize delivery route using nearest neighbor algorithm (simplified TSP)
  /// In a real app, this would use a proper routing API like Google Maps Directions API
  Future<OptimizedRouteResult> optimizeRoute({
    required Map<String, double> startLocation,
    required List<DeliveryLocation> deliveryLocations,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (deliveryLocations.isEmpty) {
      return OptimizedRouteResult(
        optimizedSequence: [],
        estimatedDuration: const Duration(minutes: 0),
        totalDistance: 0.0,
      );
    }

    // Simple nearest neighbor algorithm
    final optimizedSequence = <DeliveryLocation>[];
    final remaining = List<DeliveryLocation>.from(deliveryLocations);
    var currentLat = startLocation['lat']!;
    var currentLon = startLocation['lon']!;

    while (remaining.isNotEmpty) {
      DeliveryLocation? nearest;
      double minDistance = double.infinity;

      for (final location in remaining) {
        final distance = _calculateDistance(
          currentLat,
          currentLon,
          location.latitude,
          location.longitude,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearest = location;
        }
      }

      if (nearest != null) {
        optimizedSequence.add(nearest);
        remaining.remove(nearest);
        currentLat = nearest.latitude;
        currentLon = nearest.longitude;
      }
    }

    // Calculate total distance and estimated duration
    double totalDistance = 0.0;
    currentLat = startLocation['lat']!;
    currentLon = startLocation['lon']!;

    for (final location in optimizedSequence) {
      totalDistance += _calculateDistance(
        currentLat,
        currentLon,
        location.latitude,
        location.longitude,
      );
      currentLat = location.latitude;
      currentLon = location.longitude;
    }

    // Estimate duration: assume average speed of 30 km/h
    final estimatedMinutes = (totalDistance / 30 * 60).round();
    final estimatedDuration = Duration(minutes: estimatedMinutes);

    return OptimizedRouteResult(
      optimizedSequence: optimizedSequence,
      estimatedDuration: estimatedDuration,
      totalDistance: totalDistance,
    );
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}

@immutable
class OptimizedRouteResult {
  const OptimizedRouteResult({
    required this.optimizedSequence,
    required this.estimatedDuration,
    required this.totalDistance,
  });

  final List<DeliveryLocation> optimizedSequence;
  final Duration estimatedDuration;
  final double totalDistance; // in kilometers
}

@immutable
class DeliveryLocation {
  DeliveryLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  DeliveryLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    DateTime? timestamp,
  }) {
    return DeliveryLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

