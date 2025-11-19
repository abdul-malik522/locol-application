import 'package:flutter/material.dart';

@immutable
class PostAnalytics {
  const PostAnalytics({
    required this.postId,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.engagementRate,
  });

  final String postId;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final double engagementRate; // Percentage
}

@immutable
class OrderAnalytics {
  const OrderAnalytics({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.completionRate,
    required this.pendingOrders,
    required this.acceptedOrders,
    required this.completedOrders,
    required this.cancelledOrders,
  });

  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final double completionRate; // Percentage
  final int pendingOrders;
  final int acceptedOrders;
  final int completedOrders;
  final int cancelledOrders;
}

@immutable
class CustomerAnalytics {
  const CustomerAnalytics({
    required this.totalCustomers,
    required this.newCustomers,
    required this.returningCustomers,
    required this.customerRetentionRate,
    required this.averageCustomerLifetimeValue,
  });

  final int totalCustomers;
  final int newCustomers;
  final int returningCustomers;
  final double customerRetentionRate; // Percentage
  final double averageCustomerLifetimeValue;
}

@immutable
class ProfileAnalytics {
  const ProfileAnalytics({
    required this.profileViews,
    required this.followers,
    required this.following,
    required this.followerGrowth,
    required this.searchAppearances,
  });

  final int profileViews;
  final int followers;
  final int following;
  final double followerGrowth; // Percentage change
  final int searchAppearances;
}

@immutable
class DiscoveryAnalytics {
  const DiscoveryAnalytics({
    required this.searchAppearances,
    required this.profileViews,
    required this.postViewsFromSearch,
    required this.clicksToProfile,
  });

  final int searchAppearances;
  final int profileViews;
  final int postViewsFromSearch;
  final int clicksToProfile;
}

@immutable
class EngagementAnalytics {
  const EngagementAnalytics({
    required this.messagesSent,
    required this.messagesReceived,
    required this.averageResponseTime, // in minutes
    required this.activeConversations,
  });

  final int messagesSent;
  final int messagesReceived;
  final double averageResponseTime;
  final int activeConversations;
}

@immutable
class SellerAnalytics {
  const SellerAnalytics({
    required this.postAnalytics,
    required this.orderAnalytics,
    required this.customerAnalytics,
    required this.profileAnalytics,
  });

  final List<PostAnalytics> postAnalytics;
  final OrderAnalytics orderAnalytics;
  final CustomerAnalytics customerAnalytics;
  final ProfileAnalytics profileAnalytics;
}

@immutable
class RestaurantAnalytics {
  const RestaurantAnalytics({
    required this.discoveryAnalytics,
    required this.orderAnalytics,
    required this.engagementAnalytics,
  });

  final DiscoveryAnalytics discoveryAnalytics;
  final OrderAnalytics orderAnalytics;
  final EngagementAnalytics engagementAnalytics;
}

