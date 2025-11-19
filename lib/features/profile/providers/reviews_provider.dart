import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/profile/data/datasources/reviews_datasource.dart';
import 'package:localtrade/features/profile/data/models/review_model.dart';

final reviewsDataSourceProvider =
    Provider<ReviewsDataSource>((ref) => ReviewsDataSource.instance);

/// Provider for getting reviews received by a user
final reviewsForUserProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, userId) async {
  final dataSource = ref.watch(reviewsDataSourceProvider);
  return await dataSource.getReviewsForUser(userId);
});

/// Provider for getting reviews written by a user
final reviewsByUserProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, userId) async {
  final dataSource = ref.watch(reviewsDataSourceProvider);
  return await dataSource.getReviewsByUser(userId);
});

