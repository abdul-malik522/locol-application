import 'package:flutter/material.dart';

enum RecurrenceFrequency {
  daily('Daily', Icons.today),
  weekly('Weekly', Icons.date_range),
  biWeekly('Bi-Weekly', Icons.calendar_view_week),
  monthly('Monthly', Icons.calendar_month),
  custom('Custom', Icons.settings);

  const RecurrenceFrequency(this.label, this.icon);
  final String label;
  final IconData icon;
}

@immutable
class RecurringOrderModel {
  RecurringOrderModel({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.postId,
    required this.frequency,
    required this.nextOrderDate,
    this.endDate,
    this.maxOccurrences,
    this.occurrenceCount = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String orderId; // Reference to the original order
  final String buyerId;
  final String sellerId;
  final String postId;
  final RecurrenceFrequency frequency;
  final DateTime nextOrderDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final int occurrenceCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime? get nextOccurrence {
    if (!isActive) return null;
    if (endDate != null && nextOrderDate.isAfter(endDate!)) return null;
    if (maxOccurrences != null && occurrenceCount >= maxOccurrences!) return null;
    return nextOrderDate;
  }

  bool get canCreateNextOrder {
    if (!isActive) return false;
    if (endDate != null && nextOrderDate.isAfter(endDate!)) return false;
    if (maxOccurrences != null && occurrenceCount >= maxOccurrences!) return false;
    return nextOrderDate.isBefore(DateTime.now()) || nextOrderDate.isAtSameMomentAs(DateTime.now());
  }

  RecurringOrderModel copyWith({
    String? id,
    String? orderId,
    String? buyerId,
    String? sellerId,
    String? postId,
    RecurrenceFrequency? frequency,
    DateTime? nextOrderDate,
    DateTime? endDate,
    int? maxOccurrences,
    int? occurrenceCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringOrderModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      postId: postId ?? this.postId,
      frequency: frequency ?? this.frequency,
      nextOrderDate: nextOrderDate ?? this.nextOrderDate,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory RecurringOrderModel.fromJson(Map<String, dynamic> json) {
    return RecurringOrderModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      buyerId: json['buyerId'] as String,
      sellerId: json['sellerId'] as String,
      postId: json['postId'] as String,
      frequency: RecurrenceFrequency.values.firstWhere(
        (f) => f.name == (json['frequency'] as String),
        orElse: () => RecurrenceFrequency.weekly,
      ),
      nextOrderDate: DateTime.parse(json['nextOrderDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      maxOccurrences: json['maxOccurrences'] as int?,
      occurrenceCount: json['occurrenceCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'postId': postId,
      'frequency': frequency.name,
      'nextOrderDate': nextOrderDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'occurrenceCount': occurrenceCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DateTime calculateNextDate(DateTime currentDate) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return currentDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return currentDate.add(const Duration(days: 7));
      case RecurrenceFrequency.biWeekly:
        return currentDate.add(const Duration(days: 14));
      case RecurrenceFrequency.monthly:
        return DateTime(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day,
        );
      case RecurrenceFrequency.custom:
        return currentDate.add(const Duration(days: 7)); // Default to weekly
    }
  }
}

