import 'package:flutter/material.dart';

enum DeliveryMethod {
  pickup('Pickup', Icons.store, Colors.blue),
  delivery('Delivery', Icons.local_shipping, Colors.green),
  thirdParty('Third-Party Delivery', Icons.delivery_dining, Colors.orange);

  const DeliveryMethod(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum DeliveryStatus {
  scheduled('Scheduled', Icons.schedule, Colors.blue),
  preparing('Preparing', Icons.restaurant, Colors.orange),
  ready('Ready for Pickup', Icons.check_circle_outline, Colors.green),
  inTransit('In Transit', Icons.local_shipping, Colors.purple),
  delivered('Delivered', Icons.done_all, Colors.green),
  failed('Delivery Failed', Icons.error, Colors.red),
  cancelled('Cancelled', Icons.cancel, Colors.grey);

  const DeliveryStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class DeliveryModel {
  DeliveryModel({
    required this.id,
    required this.orderId,
    required this.method,
    required this.status,
    required this.deliveryAddress,
    this.pickupLocation,
    this.scheduledDate,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.deliveryInstructions,
    this.driverName,
    this.driverPhone,
    this.trackingNumber,
    this.proofOfDeliveryPhoto,
    this.failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String orderId;
  final DeliveryMethod method;
  final DeliveryStatus status;
  final String deliveryAddress;
  final String? pickupLocation; // For pickup method
  final DateTime? scheduledDate; // When delivery is scheduled
  final DateTime? estimatedDeliveryTime; // Estimated delivery time
  final DateTime? actualDeliveryTime; // Actual delivery time
  final String? deliveryInstructions; // Special delivery instructions
  final String? driverName; // Delivery driver name (for third-party)
  final String? driverPhone; // Delivery driver phone (for third-party)
  final String? trackingNumber; // Tracking number for third-party delivery
  final String? proofOfDeliveryPhoto; // Photo path for proof of delivery
  final String? failureReason; // Reason if delivery failed
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryModel copyWith({
    String? id,
    String? orderId,
    DeliveryMethod? method,
    DeliveryStatus? status,
    String? deliveryAddress,
    String? pickupLocation,
    DateTime? scheduledDate,
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    String? deliveryInstructions,
    String? driverName,
    String? driverPhone,
    String? trackingNumber,
    String? proofOfDeliveryPhoto,
    String? failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      method: method ?? this.method,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      proofOfDeliveryPhoto: proofOfDeliveryPhoto ?? this.proofOfDeliveryPhoto,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      method: DeliveryMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => DeliveryMethod.delivery,
      ),
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeliveryStatus.scheduled,
      ),
      deliveryAddress: json['deliveryAddress'] as String,
      pickupLocation: json['pickupLocation'] as String?,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'] as String)
          : null,
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.parse(json['actualDeliveryTime'] as String)
          : null,
      deliveryInstructions: json['deliveryInstructions'] as String?,
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      proofOfDeliveryPhoto: json['proofOfDeliveryPhoto'] as String?,
      failureReason: json['failureReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'method': method.name,
      'status': status.name,
      'deliveryAddress': deliveryAddress,
      'pickupLocation': pickupLocation,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'actualDeliveryTime': actualDeliveryTime?.toIso8601String(),
      'deliveryInstructions': deliveryInstructions,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'trackingNumber': trackingNumber,
      'proofOfDeliveryPhoto': proofOfDeliveryPhoto,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isDelivered => status == DeliveryStatus.delivered;
  bool get isInTransit => status == DeliveryStatus.inTransit;
  bool get isScheduled => status == DeliveryStatus.scheduled;
}

@immutable
class DeliveryRouteModel {
  DeliveryRouteModel({
    required this.id,
    required this.driverId,
    required this.deliveries,
    required this.startLocation,
    required this.optimizedRoute,
    this.estimatedDuration,
    this.actualDuration,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String driverId;
  final List<String> deliveries; // List of delivery IDs in this route
  final Map<String, double> startLocation; // {lat: 0.0, lon: 0.0}
  final List<Map<String, double>> optimizedRoute; // Optimized sequence of delivery locations
  final Duration? estimatedDuration;
  final Duration? actualDuration;
  final DateTime createdAt;

  DeliveryRouteModel copyWith({
    String? id,
    String? driverId,
    List<String>? deliveryIds,
    Map<String, double>? startLocation,
    List<Map<String, double>>? optimizedRoute,
    Duration? estimatedDuration,
    Duration? actualDuration,
    DateTime? createdAt,
  }) {
    return DeliveryRouteModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      deliveries: deliveries ?? this.deliveries,
      startLocation: startLocation ?? this.startLocation,
      optimizedRoute: optimizedRoute ?? this.optimizedRoute,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DeliveryRouteModel.fromJson(Map<String, dynamic> json) {
    return DeliveryRouteModel(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      deliveries: (json['deliveries'] as List<dynamic>).map((e) => e as String).toList(),
      startLocation: Map<String, double>.from(json['startLocation'] as Map),
      optimizedRoute: (json['optimizedRoute'] as List<dynamic>)
          .map((e) => Map<String, double>.from(e as Map))
          .toList(),
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(seconds: json['estimatedDuration'] as int)
          : null,
      actualDuration: json['actualDuration'] != null
          ? Duration(seconds: json['actualDuration'] as int)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'deliveries': deliveries,
      'startLocation': startLocation,
      'optimizedRoute': optimizedRoute,
      'estimatedDuration': estimatedDuration?.inSeconds,
      'actualDuration': actualDuration?.inSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

