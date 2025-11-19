import 'package:flutter/material.dart';

enum StockStatus {
  inStock('In Stock', Icons.check_circle, Colors.green),
  lowStock('Low Stock', Icons.warning, Colors.orange),
  outOfStock('Out of Stock', Icons.cancel, Colors.red),
  preOrder('Pre-Order', Icons.schedule, Colors.blue);

  const StockStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class InventoryItemModel {
  const InventoryItemModel({
    required this.id,
    required this.postId,
    required this.productName,
    required this.currentStock,
    required this.minStockLevel,
    required this.maxStockLevel,
    required this.unit,
    this.status = StockStatus.inStock,
    this.lastRestockedAt,
    this.lastSoldAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String postId;
  final String productName;
  final double currentStock;
  final double minStockLevel; // Alert when stock falls below this
  final double maxStockLevel; // Maximum stock capacity
  final String unit; // e.g., "kg", "pieces", "liters"
  final StockStatus status;
  final DateTime? lastRestockedAt;
  final DateTime? lastSoldAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItemModel copyWith({
    String? id,
    String? postId,
    String? productName,
    double? currentStock,
    double? minStockLevel,
    double? maxStockLevel,
    String? unit,
    StockStatus? status,
    DateTime? lastRestockedAt,
    DateTime? lastSoldAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      productName: productName ?? this.productName,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      lastRestockedAt: lastRestockedAt ?? this.lastRestockedAt,
      lastSoldAt: lastSoldAt ?? this.lastSoldAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String,
      postId: json['postId'] as String,
      productName: json['productName'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
      minStockLevel: (json['minStockLevel'] as num).toDouble(),
      maxStockLevel: (json['maxStockLevel'] as num).toDouble(),
      unit: json['unit'] as String,
      status: StockStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StockStatus.inStock,
      ),
      lastRestockedAt: json['lastRestockedAt'] != null
          ? DateTime.parse(json['lastRestockedAt'] as String)
          : null,
      lastSoldAt: json['lastSoldAt'] != null
          ? DateTime.parse(json['lastSoldAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'productName': productName,
      'currentStock': currentStock,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'unit': unit,
      'status': status.name,
      'lastRestockedAt': lastRestockedAt?.toIso8601String(),
      'lastSoldAt': lastSoldAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isLowStock => currentStock <= minStockLevel && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  double get stockPercentage => maxStockLevel > 0 ? (currentStock / maxStockLevel * 100) : 0;
}

@immutable
class StockAlertModel {
  const StockAlertModel({
    required this.id,
    required this.inventoryItemId,
    required this.postId,
    required this.productName,
    required this.alertType,
    required this.threshold,
    required this.isActive,
    this.notifiedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String inventoryItemId;
  final String postId;
  final String productName;
  final StockAlertType alertType;
  final double threshold;
  final bool isActive;
  final DateTime? notifiedAt;
  final DateTime createdAt;

  StockAlertModel copyWith({
    String? id,
    String? inventoryItemId,
    String? postId,
    String? productName,
    StockAlertType? alertType,
    double? threshold,
    bool? isActive,
    DateTime? notifiedAt,
    DateTime? createdAt,
  }) {
    return StockAlertModel(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      postId: postId ?? this.postId,
      productName: productName ?? this.productName,
      alertType: alertType ?? this.alertType,
      threshold: threshold ?? this.threshold,
      isActive: isActive ?? this.isActive,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StockAlertModel.fromJson(Map<String, dynamic> json) {
    return StockAlertModel(
      id: json['id'] as String,
      inventoryItemId: json['inventoryItemId'] as String,
      postId: json['postId'] as String,
      productName: json['productName'] as String,
      alertType: StockAlertType.values.firstWhere(
        (e) => e.name == json['alertType'],
        orElse: () => StockAlertType.lowStock,
      ),
      threshold: (json['threshold'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.parse(json['notifiedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryItemId': inventoryItemId,
      'postId': postId,
      'productName': productName,
      'alertType': alertType.name,
      'threshold': threshold,
      'isActive': isActive,
      'notifiedAt': notifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum StockAlertType {
  lowStock('Low Stock Alert', Icons.warning),
  outOfStock('Out of Stock Alert', Icons.cancel),
  restocked('Restocked Alert', Icons.inventory_2);

  const StockAlertType(this.label, this.icon);
  final String label;
  final IconData icon;
}

@immutable
class AvailabilityCalendarModel {
  const AvailabilityCalendarModel({
    required this.id,
    required this.postId,
    required this.productName,
    required this.availableDates,
    this.seasonalStart,
    this.seasonalEnd,
    this.isSeasonal = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String postId;
  final String productName;
  final List<DateTime> availableDates; // Specific dates when product is available
  final DateTime? seasonalStart; // Start of seasonal availability
  final DateTime? seasonalEnd; // End of seasonal availability
  final bool isSeasonal; // Whether product is seasonal
  final DateTime createdAt;
  final DateTime updatedAt;

  AvailabilityCalendarModel copyWith({
    String? id,
    String? postId,
    String? productName,
    List<DateTime>? availableDates,
    DateTime? seasonalStart,
    DateTime? seasonalEnd,
    bool? isSeasonal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilityCalendarModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      productName: productName ?? this.productName,
      availableDates: availableDates ?? this.availableDates,
      seasonalStart: seasonalStart ?? this.seasonalStart,
      seasonalEnd: seasonalEnd ?? this.seasonalEnd,
      isSeasonal: isSeasonal ?? this.isSeasonal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory AvailabilityCalendarModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityCalendarModel(
      id: json['id'] as String,
      postId: json['postId'] as String,
      productName: json['productName'] as String,
      availableDates: (json['availableDates'] as List<dynamic>)
          .map((e) => DateTime.parse(e as String))
          .toList(),
      seasonalStart: json['seasonalStart'] != null
          ? DateTime.parse(json['seasonalStart'] as String)
          : null,
      seasonalEnd: json['seasonalEnd'] != null
          ? DateTime.parse(json['seasonalEnd'] as String)
          : null,
      isSeasonal: json['isSeasonal'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'productName': productName,
      'availableDates': availableDates.map((e) => e.toIso8601String()).toList(),
      'seasonalStart': seasonalStart?.toIso8601String(),
      'seasonalEnd': seasonalEnd?.toIso8601String(),
      'isSeasonal': isSeasonal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool isAvailableOn(DateTime date) {
    if (isSeasonal && seasonalStart != null && seasonalEnd != null) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final startOnly = DateTime(seasonalStart!.year, seasonalStart!.month, seasonalStart!.day);
      final endOnly = DateTime(seasonalEnd!.year, seasonalEnd!.month, seasonalEnd!.day);
      if (dateOnly.isBefore(startOnly) || dateOnly.isAfter(endOnly)) {
        return false;
      }
    }
    if (availableDates.isNotEmpty) {
      return availableDates.any((availableDate) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        final availableOnly = DateTime(availableDate.year, availableDate.month, availableDate.day);
        return dateOnly == availableOnly;
      });
    }
    return true; // If no restrictions, assume always available
  }
}

