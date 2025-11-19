import 'dart:async';

import 'package:localtrade/features/orders/data/datasources/orders_mock_datasource.dart';
import 'package:localtrade/features/profile/data/models/review_model.dart';

class ReviewsDataSource {
  ReviewsDataSource._();
  static final ReviewsDataSource instance = ReviewsDataSource._();

  /// Get all reviews for a specific user (reviews they received)
  /// For sellers, these are reviews from restaurants (buyers)
  /// For restaurants, these are reviews from sellers
  Future<List<ReviewModel>> getReviewsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Get all orders from the orders datasource
    final ordersDataSource = OrdersMockDataSource.instance;
    final allOrders = await ordersDataSource.getAllOrders();

    // Filter orders that have ratings and are for the specified user
    final reviews = <ReviewModel>[];
    for (final order in allOrders) {
      // Check if this order has a rating
      if (order.rating == null) continue;

      // Determine who was reviewed based on the order structure
      // If the user is the seller, they were reviewed by the buyer
      // If the user is the buyer, they were reviewed by the seller
      final isSeller = order.sellerId == userId;
      final isBuyer = order.buyerId == userId;

      if (isSeller) {
        // Seller was reviewed by buyer
        reviews.add(ReviewModel(
          id: 'review-${order.id}',
          orderId: order.id,
          orderNumber: order.orderNumber,
          reviewerId: order.buyerId,
          reviewerName: order.buyerName,
          reviewedUserId: order.sellerId,
          reviewedUserName: order.sellerName,
          rating: order.rating!,
          review: order.review,
          productName: order.productName,
          productImage: order.productImage,
          createdAt: order.updatedAt,
        ));
      } else if (isBuyer) {
        // Buyer was reviewed by seller (less common, but possible)
        reviews.add(ReviewModel(
          id: 'review-${order.id}',
          orderId: order.id,
          orderNumber: order.orderNumber,
          reviewerId: order.sellerId,
          reviewerName: order.sellerName,
          reviewedUserId: order.buyerId,
          reviewedUserName: order.buyerName,
          rating: order.rating!,
          review: order.review,
          productName: order.productName,
          productImage: order.productImage,
          createdAt: order.updatedAt,
        ));
      }
    }

    // Sort by most recent first
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return reviews;
  }

  /// Get all reviews written by a specific user
  Future<List<ReviewModel>> getReviewsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Get all orders from the orders datasource
    final ordersDataSource = OrdersMockDataSource.instance;
    final allOrders = await ordersDataSource.getAllOrders();

    // Filter orders that have ratings and were written by the specified user
    final reviews = <ReviewModel>[];
    for (final order in allOrders) {
      // Check if this order has a rating
      if (order.rating == null) continue;

      // Determine who wrote the review based on the order structure
      final isBuyer = order.buyerId == userId;
      final isSeller = order.sellerId == userId;

      if (isBuyer) {
        // Buyer reviewed the seller
        reviews.add(ReviewModel(
          id: 'review-${order.id}',
          orderId: order.id,
          orderNumber: order.orderNumber,
          reviewerId: order.buyerId,
          reviewerName: order.buyerName,
          reviewedUserId: order.sellerId,
          reviewedUserName: order.sellerName,
          rating: order.rating!,
          review: order.review,
          productName: order.productName,
          productImage: order.productImage,
          createdAt: order.updatedAt,
        ));
      } else if (isSeller) {
        // Seller reviewed the buyer (less common)
        reviews.add(ReviewModel(
          id: 'review-${order.id}',
          orderId: order.id,
          orderNumber: order.orderNumber,
          reviewerId: order.sellerId,
          reviewerName: order.sellerName,
          reviewedUserId: order.buyerId,
          reviewedUserName: order.buyerName,
          rating: order.rating!,
          review: order.review,
          productName: order.productName,
          productImage: order.productImage,
          createdAt: order.updatedAt,
        ));
      }
    }

    // Sort by most recent first
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return reviews;
  }
}

