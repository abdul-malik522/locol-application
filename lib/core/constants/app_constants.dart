import 'package:flutter/material.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'LocalTrade';
  static const double defaultSearchRadiusKm = 50.0;
  static const int maxImageSizeBytes = 5 * 1024 * 1024;
  static const int paginationLimit = 20;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration defaultDebounceDuration = Duration(milliseconds: 500);
  static const int maxMessageLength = 1000;
  static const int maxPostDescriptionLength = 500;
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  static const List<String> categories = [
    'Vegetables',
    'Fruits',
    'Meat',
    'Dairy',
    'Spices',
    'Grains',
    'Herbs',
    'Seafood',
    'Beverages',
    'Bakery',
    'Condiments',
    'Prepared Meals',
  ];
}

enum UserRole {
  seller,
  restaurant,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.seller:
        return 'Seller';
      case UserRole.restaurant:
        return 'Restaurant';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.seller:
        return Icons.store;
      case UserRole.restaurant:
        return Icons.restaurant;
    }
  }
}

enum OrderStatus {
  pending,
  accepted,
  completed,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum PostType {
  product,
  request,
}

