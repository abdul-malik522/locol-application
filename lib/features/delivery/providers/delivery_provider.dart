import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/delivery/data/datasources/delivery_datasource.dart';
import 'package:localtrade/features/delivery/data/models/delivery_model.dart';

final deliveryDataSourceProvider =
    Provider<DeliveryDataSource>((ref) => DeliveryDataSource.instance);

final deliveriesProvider =
    FutureProvider<List<DeliveryModel>>((ref) {
  final dataSource = ref.watch(deliveryDataSourceProvider);
  return dataSource.getAllDeliveries();
});

final deliveryByOrderIdProvider =
    FutureProvider.family<DeliveryModel?, String>((ref, orderId) {
  final dataSource = ref.watch(deliveryDataSourceProvider);
  return dataSource.getDeliveryByOrderId(orderId);
});

final deliveriesByStatusProvider =
    FutureProvider.family<List<DeliveryModel>, DeliveryStatus>((ref, status) {
  final dataSource = ref.watch(deliveryDataSourceProvider);
  return dataSource.getDeliveriesByStatus(status);
});

final deliveryRoutesProvider =
    FutureProvider<List<DeliveryRouteModel>>((ref) {
  final dataSource = ref.watch(deliveryDataSourceProvider);
  return dataSource.getAllRoutes();
});

final routeByIdProvider =
    FutureProvider.family<DeliveryRouteModel?, String>((ref, routeId) {
  final dataSource = ref.watch(deliveryDataSourceProvider);
  return dataSource.getRouteById(routeId);
});

final deliveryByIdProvider =
    FutureProvider.family<DeliveryModel?, String>((ref, deliveryId) {
  final dataSource = ref.watch(deliveryDataSourceProvider);
  return dataSource.getDeliveryById(deliveryId);
});

