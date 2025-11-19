import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/inventory/data/datasources/pre_orders_datasource.dart';
import 'package:localtrade/features/inventory/data/models/pre_order_model.dart';

final preOrdersDataSourceProvider =
    Provider<PreOrdersDataSource>((ref) => PreOrdersDataSource.instance);

final preOrdersProvider =
    FutureProvider.family<List<PreOrderModel>, String>((ref, userId) {
  final dataSource = ref.watch(preOrdersDataSourceProvider);
  return dataSource.getPreOrders(userId);
});

final preOrdersAsBuyerProvider =
    FutureProvider.family<List<PreOrderModel>, String>((ref, userId) {
  final dataSource = ref.watch(preOrdersDataSourceProvider);
  return dataSource.getPreOrders(userId, asBuyer: true);
});

final preOrdersAsSellerProvider =
    FutureProvider.family<List<PreOrderModel>, String>((ref, userId) {
  final dataSource = ref.watch(preOrdersDataSourceProvider);
  return dataSource.getPreOrders(userId, asSeller: true);
});

final preOrderByIdProvider =
    FutureProvider.family<PreOrderModel?, String>((ref, preOrderId) {
  final dataSource = ref.watch(preOrdersDataSourceProvider);
  // Note: In a real app, you'd need userId separately
  // For now, we'll need to pass it differently or modify the API
  return dataSource.getPreOrderById(preOrderId, '');
});

