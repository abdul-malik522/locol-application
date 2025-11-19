import 'package:flutter/material.dart';

enum DeliveryStatus {
  preparing('Preparing Order', Icons.inventory_2, Colors.orange),
  pickedUp('Picked Up', Icons.shopping_bag, Colors.blue),
  inTransit('In Transit', Icons.local_shipping, Colors.purple),
  outForDelivery('Out for Delivery', Icons.delivery_dining, Colors.amber),
  delivered('Delivered', Icons.check_circle, Colors.green),
  failed('Delivery Failed', Icons.error, Colors.red);

  const DeliveryStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class DeliveryLocation {
  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.address,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? address;
}

@immutable
class DeliveryTrackingModel {
  DeliveryTrackingModel({
    required this.orderId,
    required this.status,
    required this.currentLocation,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.deliveryPersonName,
    this.deliveryPersonPhone,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String orderId;
  final DeliveryStatus status;
  final DeliveryLocation currentLocation;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final String? deliveryPersonName;
  final String? deliveryPersonPhone;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDelivered => status == DeliveryStatus.delivered;
  bool get isInTransit => status == DeliveryStatus.inTransit ||
      status == DeliveryStatus.outForDelivery ||
      status == DeliveryStatus.pickedUp;

  DeliveryTrackingModel copyWith({
    String? orderId,
    DeliveryStatus? status,
    DeliveryLocation? currentLocation,
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    String? deliveryPersonName,
    String? deliveryPersonPhone,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryTrackingModel(
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      deliveryPersonName: deliveryPersonName ?? this.deliveryPersonName,
      deliveryPersonPhone: deliveryPersonPhone ?? this.deliveryPersonPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory DeliveryTrackingModel.fromJson(Map<String, dynamic> json) {
    return DeliveryTrackingModel(
      orderId: json['orderId'] as String,
      status: DeliveryStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String),
        orElse: () => DeliveryStatus.preparing,
      ),
      currentLocation: DeliveryLocation(
        latitude: (json['currentLocation']['latitude'] as num).toDouble(),
        longitude: (json['currentLocation']['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['currentLocation']['timestamp'] as String),
        address: json['currentLocation']['address'] as String?,
      ),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'] as String)
          : null,
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.parse(json['actualDeliveryTime'] as String)
          : null,
      deliveryPersonName: json['deliveryPersonName'] as String?,
      deliveryPersonPhone: json['deliveryPersonPhone'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'status': status.name,
      'currentLocation': {
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
        'timestamp': currentLocation.timestamp.toIso8601String(),
        'address': currentLocation.address,
      },
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'actualDeliveryTime': actualDeliveryTime?.toIso8601String(),
      'deliveryPersonName': deliveryPersonName,
      'deliveryPersonPhone': deliveryPersonPhone,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

