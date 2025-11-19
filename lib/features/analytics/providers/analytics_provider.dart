import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/analytics/data/datasources/analytics_mock_datasource.dart';
import 'package:localtrade/features/analytics/data/models/analytics_model.dart';

final analyticsDataSourceProvider =
    Provider<AnalyticsMockDataSource>((ref) => AnalyticsMockDataSource.instance);

final sellerAnalyticsProvider =
    FutureProvider.family<SellerAnalytics, String>((ref, userId) {
  final dataSource = ref.watch(analyticsDataSourceProvider);
  return dataSource.getSellerAnalytics(userId);
});

final restaurantAnalyticsProvider =
    FutureProvider.family<RestaurantAnalytics, String>((ref, userId) {
  final dataSource = ref.watch(analyticsDataSourceProvider);
  return dataSource.getRestaurantAnalytics(userId);
});

