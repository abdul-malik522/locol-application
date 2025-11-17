import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/orders/presentation/widgets/order_card.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        _loadOrders(currentUser.id, null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final status = _getStatusForIndex(_tabController.index);
        _loadOrders(currentUser.id, status);
      }
    }
  }

  OrderStatus? _getStatusForIndex(int index) {
    switch (index) {
      case 0:
        return OrderStatus.pending;
      case 1:
        return OrderStatus.accepted;
      case 2:
        return OrderStatus.completed;
      case 3:
        return OrderStatus.cancelled;
      default:
        return null;
    }
  }

  Future<void> _loadOrders(String userId, OrderStatus? status) async {
    await ref.read(ordersProvider.notifier).loadOrders(userId, status);
  }

  Future<void> _onRefresh() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final status = _getStatusForIndex(_tabController.index);
      await _loadOrders(currentUser.id, status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final currentUser = ref.watch(currentUserProvider);
    final stats = ref.watch(orderStatsProvider);

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'My Orders'),
        body: Center(child: Text('Please login to view orders')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (stats['totalOrders'] > 0)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    'Total',
                    stats['totalOrders'].toString(),
                    Icons.shopping_bag_outlined,
                  ),
                  _buildStatItem(
                    context,
                    'Pending',
                    stats['pendingCount'].toString(),
                    Icons.pending_outlined,
                  ),
                  _buildStatItem(
                    context,
                    'Completed',
                    stats['completedCount'].toString(),
                    Icons.check_circle_outline,
                  ),
                  _buildStatItem(
                    context,
                    'Spent',
                    Formatters.formatCurrency(stats['totalSpent'] as double),
                    Icons.attach_money,
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(ordersState, currentUser.id),
                  _buildOrdersList(ordersState, currentUser.id),
                  _buildOrdersList(ordersState, currentUser.id),
                  _buildOrdersList(ordersState, currentUser.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildOrdersList(OrdersState state, String currentUserId) {
    if (state.isLoading && state.orders.isEmpty) {
      return const LoadingIndicator();
    }

    if (state.error != null && state.orders.isEmpty) {
      return ErrorView(
        error: state.error!,
        onRetry: () => _loadOrders(currentUserId, state.selectedStatus),
      );
    }

    if (state.orders.isEmpty) {
      final status = state.selectedStatus;
      final statusText = status?.label ?? 'orders';
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No $statusText Orders',
        message: status == null
            ? 'You haven\'t placed any orders yet'
            : 'You don\'t have any $statusText orders',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.orders.length,
      itemBuilder: (context, index) {
        final order = state.orders[index];
        return OrderCard(
          order: order,
          currentUserId: currentUserId,
        );
      },
    );
  }
}
