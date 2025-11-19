import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/inventory/data/datasources/inventory_datasource.dart';
import 'package:localtrade/features/inventory/data/models/inventory_model.dart';

final inventoryDataSourceProvider =
    Provider<InventoryDataSource>((ref) => InventoryDataSource.instance);

final inventoryItemsProvider =
    FutureProvider.family<List<InventoryItemModel>, String>((ref, userId) {
  final dataSource = ref.watch(inventoryDataSourceProvider);
  return dataSource.getInventoryItems(userId);
});

final inventoryItemByPostIdProvider =
    FutureProvider.family<InventoryItemModel?, String>((ref, postId) {
  final dataSource = ref.watch(inventoryDataSourceProvider);
  // Extract userId from postId - in a real app, you'd pass userId separately
  final userId = postId.split('_').first;
  return dataSource.getInventoryItemByPostId(postId, userId);
});

final stockAlertsProvider =
    FutureProvider.family<List<StockAlertModel>, String>((ref, userId) {
  final dataSource = ref.watch(inventoryDataSourceProvider);
  return dataSource.getStockAlerts(userId);
});

final availabilityCalendarsProvider =
    FutureProvider.family<List<AvailabilityCalendarModel>, String>((ref, userId) {
  final dataSource = ref.watch(inventoryDataSourceProvider);
  return dataSource.getAvailabilityCalendars(userId);
});

final availabilityCalendarByPostIdProvider =
    FutureProvider.family<AvailabilityCalendarModel?, String>((ref, postId) {
  final dataSource = ref.watch(inventoryDataSourceProvider);
  final userId = postId.split('_').first;
  return dataSource.getAvailabilityCalendarByPostId(postId, userId);
});

