import 'dart:async';

import 'package:localtrade/features/analytics/data/models/analytics_model.dart';
import 'package:localtrade/features/home/data/datasources/posts_mock_datasource.dart';
import 'package:localtrade/features/orders/data/datasources/orders_mock_datasource.dart';
import 'package:localtrade/features/profile/data/datasources/follows_datasource.dart';

class AnalyticsMockDataSource {
  AnalyticsMockDataSource._();
  static final AnalyticsMockDataSource instance = AnalyticsMockDataSource._();

  Future<SellerAnalytics> getSellerAnalytics(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

            // Get user's posts
            final postsDataSource = PostsMockDataSource.instance;
            final allPosts = postsDataSource.getAllPosts();
            final userPosts = allPosts.where((p) => p.userId == userId).toList();

    // Calculate post analytics
    final postAnalytics = userPosts.map((post) {
      final views = post.likeCount * 3 + post.commentCount * 2; // Mock views
      final engagementRate = views > 0
          ? ((post.likeCount + post.commentCount) / views * 100)
          : 0.0;
      return PostAnalytics(
        postId: post.id,
        views: views,
        likes: post.likeCount,
        comments: post.commentCount,
        shares: 0, // Mock
        engagementRate: engagementRate,
      );
    }).toList();

    // Get order analytics
    final ordersDataSource = OrdersMockDataSource.instance;
    final allOrders = await ordersDataSource.getAllOrders();
    final sellerOrders = allOrders.where((o) => o.sellerId == userId).toList();

    final totalOrders = sellerOrders.length;
    final totalRevenue = sellerOrders
        .where((o) => o.status.name == 'completed')
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final completedOrders = sellerOrders.where((o) => o.status.name == 'completed').length;
    final completionRate = totalOrders > 0 ? (completedOrders / totalOrders * 100) : 0.0;

    final orderAnalytics = OrderAnalytics(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      averageOrderValue: averageOrderValue,
      completionRate: completionRate,
      pendingOrders: sellerOrders.where((o) => o.status.name == 'pending').length,
      acceptedOrders: sellerOrders.where((o) => o.status.name == 'accepted').length,
      completedOrders: completedOrders,
      cancelledOrders: sellerOrders.where((o) => o.status.name == 'cancelled').length,
    );

    // Get customer analytics
    final uniqueBuyers = sellerOrders.map((o) => o.buyerId).toSet();
    final newCustomers = uniqueBuyers.length; // Simplified
    final returningCustomers = 0; // Would need order history analysis
    final customerRetentionRate = newCustomers > 0 ? (returningCustomers / newCustomers * 100) : 0.0;

    final customerAnalytics = CustomerAnalytics(
      totalCustomers: uniqueBuyers.length,
      newCustomers: newCustomers,
      returningCustomers: returningCustomers,
      customerRetentionRate: customerRetentionRate,
      averageCustomerLifetimeValue: totalRevenue / (uniqueBuyers.length > 0 ? uniqueBuyers.length : 1),
    );

    // Get profile analytics
    final followsDataSource = FollowsDataSource.instance;
    final followers = await followsDataSource.getFollowerCount(userId);
    final following = await followsDataSource.getFollowingCount(userId);
    final followerGrowth = 0.0; // Would need historical data

    final profileAnalytics = ProfileAnalytics(
      profileViews: followers * 5, // Mock
      followers: followers,
      following: following,
      followerGrowth: followerGrowth,
      searchAppearances: followers * 2, // Mock
    );

    return SellerAnalytics(
      postAnalytics: postAnalytics,
      orderAnalytics: orderAnalytics,
      customerAnalytics: customerAnalytics,
      profileAnalytics: profileAnalytics,
    );
  }

  Future<RestaurantAnalytics> getRestaurantAnalytics(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Get discovery analytics
    final followsDataSource = FollowsDataSource.instance;
    final followers = await followsDataSource.getFollowerCount(userId);
    
    final discoveryAnalytics = DiscoveryAnalytics(
      searchAppearances: followers * 3, // Mock
      profileViews: followers * 5, // Mock
      postViewsFromSearch: followers * 2, // Mock
      clicksToProfile: followers, // Mock
    );

    // Get order analytics
    final ordersDataSource = OrdersMockDataSource.instance;
    // Get all orders for restaurant
    final allOrders = await ordersDataSource.getAllOrders();
    final restaurantOrders = allOrders.where((o) => o.buyerId == userId).toList();

    final totalOrders = restaurantOrders.length;
    final totalRevenue = restaurantOrders
        .where((o) => o.status.name == 'completed')
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final completedOrders = restaurantOrders.where((o) => o.status.name == 'completed').length;
    final completionRate = totalOrders > 0 ? (completedOrders / totalOrders * 100) : 0.0;

    final orderAnalytics = OrderAnalytics(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      averageOrderValue: averageOrderValue,
      completionRate: completionRate,
      pendingOrders: restaurantOrders.where((o) => o.status.name == 'pending').length,
      acceptedOrders: restaurantOrders.where((o) => o.status.name == 'accepted').length,
      completedOrders: completedOrders,
      cancelledOrders: restaurantOrders.where((o) => o.status.name == 'cancelled').length,
    );

    // Get engagement analytics
    final engagementAnalytics = EngagementAnalytics(
      messagesSent: 0, // Would need messages data
      messagesReceived: 0, // Would need messages data
      averageResponseTime: 0.0, // Would need messages data
      activeConversations: 0, // Would need messages data
    );

    return RestaurantAnalytics(
      discoveryAnalytics: discoveryAnalytics,
      orderAnalytics: orderAnalytics,
      engagementAnalytics: engagementAnalytics,
    );
  }
}

