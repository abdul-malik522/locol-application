import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/inventory/data/models/pre_order_model.dart';
import 'package:localtrade/features/inventory/providers/pre_orders_provider.dart';
import 'package:uuid/uuid.dart';

class PreOrdersScreen extends ConsumerStatefulWidget {
  const PreOrdersScreen({super.key});

  @override
  ConsumerState<PreOrdersScreen> createState() => _PreOrdersScreenState();
}

class _PreOrdersScreenState extends ConsumerState<PreOrdersScreen> {
  bool _showAsBuyer = true;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Pre-Orders'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final preOrdersAsync = _showAsBuyer
        ? ref.watch(preOrdersAsBuyerProvider(currentUser.id))
        : ref.watch(preOrdersAsSellerProvider(currentUser.id));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Pre-Orders',
        actions: [
          IconButton(
            icon: Icon(_showAsBuyer ? Icons.shopping_cart : Icons.store),
            onPressed: () {
              setState(() {
                _showAsBuyer = !_showAsBuyer;
              });
            },
            tooltip: _showAsBuyer ? 'Switch to Seller View' : 'Switch to Buyer View',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(context),
          Expanded(
            child: preOrdersAsync.when(
              data: (preOrders) {
                if (preOrders.isEmpty) {
                  return EmptyState(
                    icon: Icons.schedule,
                    title: 'No Pre-Orders',
                    message: _showAsBuyer
                        ? 'Your pre-orders will appear here.'
                        : 'Pre-orders from buyers will appear here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: preOrders.length,
                  itemBuilder: (context, index) {
                    final preOrder = preOrders[index];
                    return _buildPreOrderCard(context, ref, preOrder, currentUser.id);
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorView(
                error: error.toString(),
                onRetry: () {
                  if (_showAsBuyer) {
                    ref.invalidate(preOrdersAsBuyerProvider(currentUser.id));
                  } else {
                    ref.invalidate(preOrdersAsSellerProvider(currentUser.id));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            _showAsBuyer ? 'My Pre-Orders' : 'Received Pre-Orders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreOrderCard(
    BuildContext context,
    WidgetRef ref,
    PreOrderModel preOrder,
    String userId,
  ) {
    final isBuyer = preOrder.buyerId == userId;
    final isSeller = preOrder.sellerId == userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: preOrder.status.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(preOrder.status.icon, color: preOrder.status.color),
        ),
        title: Text(preOrder.productName),
        subtitle: Text(
          '${preOrder.quantity} • ${timeago.format(preOrder.createdAt)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Status', preOrder.status.label),
                _buildInfoRow(context, isBuyer ? 'Seller' : 'Buyer', isBuyer ? preOrder.sellerName : preOrder.buyerName),
                _buildInfoRow(context, 'Quantity', preOrder.quantity),
                _buildInfoRow(
                  context,
                  'Expected Availability',
                  DateFormat('MMM dd, yyyy').format(preOrder.expectedAvailabilityDate),
                ),
                if (preOrder.price != null)
                  _buildInfoRow(context, 'Price', Formatters.formatCurrency(preOrder.price!)),
                if (preOrder.totalAmount != null)
                  _buildInfoRow(context, 'Total', Formatters.formatCurrency(preOrder.totalAmount!)),
                if (preOrder.notes != null && preOrder.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(preOrder.notes!),
                ],
                const SizedBox(height: 16),
                if (isSeller && preOrder.isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Confirm',
                          onPressed: () => _confirmPreOrder(context, ref, preOrder, userId),
                          variant: CustomButtonVariant.filled,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () => _cancelPreOrder(context, ref, preOrder, userId),
                          variant: CustomButtonVariant.outlined,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isSeller && preOrder.isConfirmed) ...[
                  CustomButton(
                    text: 'Mark as Fulfilled',
                    onPressed: () => _fulfillPreOrder(context, ref, preOrder, userId),
                    fullWidth: true,
                  ),
                ],
                if (isBuyer && preOrder.isPending) ...[
                  CustomButton(
                    text: 'Cancel Pre-Order',
                    onPressed: () => _cancelPreOrder(context, ref, preOrder, userId),
                    variant: CustomButtonVariant.outlined,
                    fullWidth: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPreOrder(
    BuildContext context,
    WidgetRef ref,
    PreOrderModel preOrder,
    String userId,
  ) async {
    try {
      final dataSource = ref.read(preOrdersDataSourceProvider);
      await dataSource.updatePreOrder(
        preOrder.copyWith(status: PreOrderStatus.confirmed),
      );
      ref.invalidate(preOrdersAsSellerProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pre-order confirmed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fulfillPreOrder(
    BuildContext context,
    WidgetRef ref,
    PreOrderModel preOrder,
    String userId,
  ) async {
    try {
      final dataSource = ref.read(preOrdersDataSourceProvider);
      await dataSource.updatePreOrder(
        preOrder.copyWith(
          status: PreOrderStatus.fulfilled,
          fulfilledAt: DateTime.now(),
        ),
      );
      ref.invalidate(preOrdersAsSellerProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pre-order marked as fulfilled')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fulfill: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _cancelPreOrder(
    BuildContext context,
    WidgetRef ref,
    PreOrderModel preOrder,
    String userId,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Pre-Order'),
        content: const Text('Are you sure you want to cancel this pre-order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final dataSource = ref.read(preOrdersDataSourceProvider);
                await dataSource.updatePreOrder(
                  preOrder.copyWith(status: PreOrderStatus.cancelled),
                );
                if (preOrder.buyerId == userId) {
                  ref.invalidate(preOrdersAsBuyerProvider(userId));
                } else {
                  ref.invalidate(preOrdersAsSellerProvider(userId));
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pre-order cancelled')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

