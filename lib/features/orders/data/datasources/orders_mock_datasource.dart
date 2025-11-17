import 'dart:async';
import 'dart:math';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';
import 'package:uuid/uuid.dart';

class OrdersMockDataSource {
  OrdersMockDataSource._() {
    _initializeMockData();
  }
  static final OrdersMockDataSource instance = OrdersMockDataSource._();
  final _uuid = const Uuid();
  final _random = Random();

  final List<OrderModel> _orders = [];

  void _initializeMockData() {
    final now = DateTime.now();

    _orders.addAll([
      OrderModel(
        id: 'order-001',
        orderNumber: 'ORD-1001',
        buyerId: 'user-004',
        buyerName: 'Lena Rivers',
        sellerId: 'user-001',
        sellerName: 'Amelia Fields',
        postId: 'post-001',
        productName: 'Fresh Organic Tomatoes',
        productImage: 'https://picsum.photos/200/200?random=1',
        quantity: '5 kg',
        price: 4.50,
        totalAmount: 22.50,
        status: OrderStatus.pending,
        deliveryAddress: '88 Cherry Ln, Seattle',
        notes: 'Please deliver in the morning',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      OrderModel(
        id: 'order-002',
        orderNumber: 'ORD-1002',
        buyerId: 'user-005',
        buyerName: 'Marco Bianchi',
        sellerId: 'user-002',
        sellerName: 'Carlos Green',
        postId: 'post-002',
        productName: 'Mixed Leafy Greens Bundle',
        productImage: 'https://picsum.photos/200/200?random=3',
        quantity: '2 bundles',
        price: 6.00,
        totalAmount: 12.00,
        status: OrderStatus.accepted,
        deliveryAddress: '77 Olive St, Boston',
        deliveryDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      OrderModel(
        id: 'order-003',
        orderNumber: 'ORD-1003',
        buyerId: 'user-006',
        buyerName: 'Derrick Cole',
        sellerId: 'user-003',
        sellerName: 'Rita Stone',
        postId: 'post-004',
        productName: 'Free-Range Chicken - Whole Birds',
        productImage: 'https://picsum.photos/200/200?random=5',
        quantity: '3 whole birds',
        price: 18.00,
        totalAmount: 54.00,
        status: OrderStatus.completed,
        deliveryAddress: '310 Pine St, Denver',
        deliveryDate: now.subtract(const Duration(days: 2)),
        rating: 4.8,
        review: 'Excellent quality! The chicken was fresh and delicious.',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      OrderModel(
        id: 'order-004',
        orderNumber: 'ORD-1004',
        buyerId: 'user-010',
        buyerName: 'Jonah Reed',
        sellerId: 'user-007',
        sellerName: 'Tara Bloom',
        postId: 'post-007',
        productName: 'Raw Local Honey',
        productImage: 'https://picsum.photos/200/200?random=9',
        quantity: '2 jars (500g each)',
        price: 15.00,
        totalAmount: 30.00,
        status: OrderStatus.completed,
        deliveryAddress: '220 Ocean Ave, Miami',
        deliveryDate: now.subtract(const Duration(days: 7)),
        rating: 5.0,
        review: 'Amazing honey! Will definitely order again.',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      OrderModel(
        id: 'order-005',
        orderNumber: 'ORD-1005',
        buyerId: 'user-009',
        buyerName: 'Sakura Watanabe',
        sellerId: 'user-012',
        sellerName: 'Priya Nair',
        postId: 'post-010',
        productName: 'Premium Spice Blend - Garam Masala',
        productImage: 'https://picsum.photos/200/200?random=13',
        quantity: '3 jars (100g each)',
        price: 8.50,
        totalAmount: 25.50,
        status: OrderStatus.cancelled,
        deliveryAddress: '950 Sunset Blvd, Los Angeles',
        notes: 'Cancelled by buyer',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      OrderModel(
        id: 'order-006',
        orderNumber: 'ORD-1006',
        buyerId: 'user-004',
        buyerName: 'Lena Rivers',
        sellerId: 'user-008',
        sellerName: 'Nora Fields',
        postId: 'post-005',
        productName: 'Artisan Cheddar Cheese',
        productImage: 'https://picsum.photos/200/200?random=7',
        quantity: '2 blocks (500g each)',
        price: 12.50,
        totalAmount: 25.00,
        status: OrderStatus.accepted,
        deliveryAddress: '88 Cherry Ln, Seattle',
        deliveryDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      OrderModel(
        id: 'order-007',
        orderNumber: 'ORD-1007',
        buyerId: 'user-005',
        buyerName: 'Marco Bianchi',
        sellerId: 'user-001',
        sellerName: 'Amelia Fields',
        postId: 'post-001',
        productName: 'Fresh Organic Tomatoes',
        productImage: 'https://picsum.photos/200/200?random=1',
        quantity: '10 kg',
        price: 4.50,
        totalAmount: 45.00,
        status: OrderStatus.completed,
        deliveryAddress: '77 Olive St, Boston',
        deliveryDate: now.subtract(const Duration(days: 1)),
        rating: 4.5,
        review: 'Great tomatoes, very fresh!',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      OrderModel(
        id: 'order-008',
        orderNumber: 'ORD-1008',
        buyerId: 'user-006',
        buyerName: 'Derrick Cole',
        sellerId: 'user-011',
        sellerName: 'Luca Martinez',
        postId: 'post-012',
        productName: 'Organic Whole Wheat Flour',
        productImage: 'https://picsum.photos/200/200?random=15',
        quantity: '5 kg bag',
        price: 7.25,
        totalAmount: 7.25,
        status: OrderStatus.pending,
        deliveryAddress: '310 Pine St, Denver',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ]);
  }

  Future<List<OrderModel>> getOrders(String userId, OrderStatus? status) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var orders = _orders.where((order) {
      return order.buyerId == userId || order.sellerId == userId;
    }).toList();

    if (status != null) {
      orders = orders.where((order) => order.status == status).toList();
    }

    // Sort by created date (newest first)
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orders;
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _orders.insert(0, order);
    return order;
  }

  Future<OrderModel> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final order = _orders[index];
    final updated = order.copyWith(
      status: newStatus,
      deliveryDate: newStatus == OrderStatus.accepted
          ? DateTime.now().add(const Duration(days: 1))
          : order.deliveryDate,
    );

    _orders[index] = updated;
    return updated;
  }

  Future<OrderModel> cancelOrder(String orderId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final order = _orders[index];
    final updated = order.copyWith(
      status: OrderStatus.cancelled,
      notes: reason,
    );

    _orders[index] = updated;
    return updated;
  }

  Future<OrderModel> rateOrder(
    String orderId,
    double rating,
    String review,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final order = _orders[index];
    final updated = order.copyWith(
      rating: rating,
      review: review,
    );

    _orders[index] = updated;
    return updated;
  }

  Future<OrderModel> reorder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final originalOrder = _orders.firstWhere((order) => order.id == orderId);

    final newOrder = originalOrder.copyWith(
      id: _uuid.v4(),
      orderNumber: 'ORD-${1000 + _orders.length + 1}',
      status: OrderStatus.pending,
      deliveryDate: null,
      rating: null,
      review: null,
      notes: null,
    );

    _orders.insert(0, newOrder);
    return newOrder;
  }
}

