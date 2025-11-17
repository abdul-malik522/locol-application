import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/orders/data/datasources/orders_mock_datasource.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';

class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
  });

  final List<OrderModel> orders;
  final bool isLoading;
  final String? error;
  final OrderStatus? selectedStatus;

  OrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? error,
    OrderStatus? selectedStatus,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus,
    );
  }
}

final ordersMockDataSourceProvider =
    Provider<OrdersMockDataSource>((ref) => OrdersMockDataSource.instance);

class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier(this._dataSource) : super(const OrdersState());

  final OrdersMockDataSource _dataSource;

  Future<void> loadOrders(String userId, OrderStatus? status) async {
    state = state.copyWith(isLoading: true, error: null, selectedStatus: status);
    try {
      final orders = await _dataSource.getOrders(userId, status);
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load orders: ${e.toString()}',
      );
    }
  }

  Future<void> setStatusFilter(OrderStatus? status) async {
    // Filter is handled in loadOrders
    state = state.copyWith(selectedStatus: status);
  }

  Future<void> createOrder(OrderModel order) async {
    try {
      final created = await _dataSource.createOrder(order);
      state = state.copyWith(
        orders: [created, ...state.orders],
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to create order: ${e.toString()}',
      );
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final updated = await _dataSource.updateOrderStatus(orderId, newStatus);
      final index = state.orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrders = List<OrderModel>.from(state.orders);
        updatedOrders[index] = updated;
        state = state.copyWith(orders: updatedOrders);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update order: ${e.toString()}',
      );
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      final updated = await _dataSource.cancelOrder(orderId, reason);
      final index = state.orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrders = List<OrderModel>.from(state.orders);
        updatedOrders[index] = updated;
        state = state.copyWith(orders: updatedOrders);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to cancel order: ${e.toString()}',
      );
    }
  }

  Future<void> rateOrder(String orderId, double rating, String review) async {
    try {
      final updated = await _dataSource.rateOrder(orderId, rating, review);
      final index = state.orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrders = List<OrderModel>.from(state.orders);
        updatedOrders[index] = updated;
        state = state.copyWith(orders: updatedOrders);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to rate order: ${e.toString()}',
      );
    }
  }

  Future<void> reorder(String orderId) async {
    try {
      final newOrder = await _dataSource.reorder(orderId);
      state = state.copyWith(
        orders: [newOrder, ...state.orders],
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to reorder: ${e.toString()}',
      );
    }
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final dataSource = ref.watch(ordersMockDataSourceProvider);
  return OrdersNotifier(dataSource);
});

final filteredOrdersProvider = Provider<List<OrderModel>>((ref) {
  final state = ref.watch(ordersProvider);
  return state.orders;
});

final orderByIdProvider = Provider.family<OrderModel?, String>((ref, orderId) {
  final orders = ref.watch(filteredOrdersProvider);
  try {
    return orders.firstWhere((order) => order.id == orderId);
  } catch (_) {
    return null;
  }
});

final orderStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final orders = ref.watch(filteredOrdersProvider);
  final totalOrders = orders.length;
  final pendingCount = orders.where((o) => o.status == OrderStatus.pending).length;
  final completedCount =
      orders.where((o) => o.status == OrderStatus.completed).length;
  final totalSpent = orders
      .where((o) => o.status == OrderStatus.completed)
      .fold<double>(0, (sum, order) => sum + order.totalAmount);

  return {
    'totalOrders': totalOrders,
    'pendingCount': pendingCount,
    'completedCount': completedCount,
    'totalSpent': totalSpent,
  };
});

