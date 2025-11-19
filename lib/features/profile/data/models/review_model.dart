import 'package:flutter/material.dart';

@immutable
class ReviewModel {
  ReviewModel({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewedUserId,
    required this.reviewedUserName,
    required this.rating,
    this.review,
    required this.productName,
    this.productImage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String orderId;
  final String orderNumber;
  final String reviewerId;
  final String reviewerName;
  final String reviewedUserId;
  final String reviewedUserName;
  final double rating;
  final String? review;
  final String productName;
  final String? productImage;
  final DateTime createdAt;

  ReviewModel copyWith({
    String? id,
    String? orderId,
    String? orderNumber,
    String? reviewerId,
    String? reviewerName,
    String? reviewedUserId,
    String? reviewedUserName,
    double? rating,
    String? review,
    String? productName,
    String? productImage,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewedUserId: reviewedUserId ?? this.reviewedUserId,
      reviewedUserName: reviewedUserName ?? this.reviewedUserName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String,
      reviewerId: json['reviewerId'] as String,
      reviewerName: json['reviewerName'] as String,
      reviewedUserId: json['reviewedUserId'] as String,
      reviewedUserName: json['reviewedUserName'] as String,
      rating: (json['rating'] as num).toDouble(),
      review: json['review'] as String?,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewedUserId': reviewedUserId,
      'reviewedUserName': reviewedUserName,
      'rating': rating,
      'review': review,
      'productName': productName,
      'productImage': productImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

