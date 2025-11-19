import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:localtrade/features/orders/data/datasources/disputes_datasource.dart';
import 'package:localtrade/features/orders/data/models/cancellation_reason.dart';
import 'package:localtrade/features/orders/data/models/dispute_model.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';
import 'package:localtrade/features/orders/data/models/order_template_model.dart';
import 'package:localtrade/features/orders/data/models/recurring_order_model.dart';
import 'package:localtrade/features/orders/data/services/order_receipt_service.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({
    required this.orderId,
    super.key,
  });

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Order Details'),
        body: Center(child: Text('Please login to view order details')),
      );
    }

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Order Details'),
            body: const ErrorView(error: 'Order not found'),
          );
        }

        final isBuyer = order.buyerId == currentUser.id;
        final isSeller = order.sellerId == currentUser.id;

        return _buildOrderDetail(context, order, isBuyer, isSeller);
      },
      loading: () => const Scaffold(
        appBar: CustomAppBar(title: 'Order Details'),
        body: LoadingIndicator(),
      ),
      error: (error, _) => Scaffold(
        appBar: const CustomAppBar(title: 'Order Details'),
        body: ErrorView(error: error.toString()),
      ),
    );
  }

  Widget _buildOrderDetail(
    BuildContext context,
    OrderModel order,
    bool isBuyer,
    bool isSeller,
  ) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Order Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share order feature coming soon')),
              );
            },
            tooltip: 'Share Order',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(context, order),
            _buildOrderHeader(context, order),
            _buildProductSection(context, order),
            _buildOrderInfoSection(context, order, isBuyer, isSeller),
            _buildPricingSection(context, order),
            _buildNotesSection(context, order, isBuyer, isSeller),
            if (order.rating != null) _buildRatingSection(context, order),
            _buildTimelineSection(context, order),
            _buildActionsSection(context, order, isBuyer, isSeller),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: order.statusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: order.statusColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(order.status),
            color: order.statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.statusText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: order.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(order.status),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: order.statusColor.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending_outlined;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Waiting for seller to accept your order';
      case OrderStatus.accepted:
        return 'Order has been accepted and is being prepared';
      case OrderStatus.completed:
        return 'Order has been completed successfully';
      case OrderStatus.cancelled:
        return 'This order has been cancelled';
    }
  }

  Widget _buildOrderHeader(BuildContext context, OrderModel order) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Number',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.orderNumber,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: order.statusColor),
                ),
                child: Text(
                  order.statusText,
                  style: TextStyle(
                    color: order.statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.calendar_today_outlined,
            'Order Date',
            Formatters.formatDateTime(order.createdAt),
          ),
          if (order.updatedAt != order.createdAt)
            _buildInfoRow(
              context,
              Icons.update_outlined,
              'Last Updated',
              '${timeago.format(order.updatedAt)}',
            ),
        ],
      ),
    );
  }

  Widget _buildProductSection(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImage(
                  imageUrl: order.productImage ?? 'https://picsum.photos/100/100',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      Icons.inventory_2_outlined,
                      'Quantity',
                      order.quantity,
                      compact: true,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      Icons.attach_money,
                      'Unit Price',
                      Formatters.formatCurrency(order.price),
                      compact: true,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => context.push('/post/${order.postId}'),
                      child: Row(
                        children: [
                          Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View Original Post',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoSection(
    BuildContext context,
    OrderModel order,
    bool isBuyer,
    bool isSeller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (isBuyer)
            _buildUserInfoRow(
              context,
              'Seller',
              order.sellerName,
              () => context.push('/profile/${order.sellerId}'),
            )
          else
            _buildUserInfoRow(
              context,
              'Buyer',
              order.buyerName,
              () => context.push('/profile/${order.buyerId}'),
            ),
          const Divider(height: 24),
          _buildInfoRow(
            context,
            Icons.location_on_outlined,
            'Delivery Address',
            order.deliveryAddress,
          ),
          if (order.deliveryInstructions != null && order.deliveryInstructions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.delivery_dining,
              'Delivery Instructions',
              order.deliveryInstructions!,
            ),
          ],
          if (order.status == OrderStatus.pending && isBuyer) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _editDeliveryInstructions(context, order),
              icon: Icon(
                order.deliveryInstructions != null && order.deliveryInstructions!.isNotEmpty
                    ? Icons.edit
                    : Icons.add,
              ),
              label: Text(
                order.deliveryInstructions != null && order.deliveryInstructions!.isNotEmpty
                    ? 'Edit Delivery Instructions'
                    : 'Add Delivery Instructions',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ],
          if (order.scheduledDate != null) ...[
            const Divider(height: 24),
            _buildScheduledDateRow(context, order, isBuyer, isSeller),
          ],
          if (order.deliveryDate != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              context,
              Icons.calendar_today_outlined,
              'Delivery Date',
              Formatters.formatDate(order.deliveryDate!),
            ),
          ],
          if (order.trackingId != null && 
              (order.status == OrderStatus.accepted || order.status == OrderStatus.completed)) ...[
            const Divider(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.push('/tracking/${order.id}'),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Track Delivery'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
          if (order.status == OrderStatus.cancelled &&
              order.cancellationReason != null &&
              order.cancellationReason!.isNotEmpty) ...[
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 20,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cancellation Reason',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.cancellationReason!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unit Price',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                Formatters.formatCurrency(order.price),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                order.quantity,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                Formatters.formatCurrency(order.totalAmount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(
    BuildContext context,
    OrderModel order,
    bool isBuyer,
    bool isSeller,
  ) {
    final canEditNotes = (isBuyer || isSeller) &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.accepted);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Order Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (canEditNotes)
                TextButton.icon(
                  onPressed: () => _showEditNotesDialog(context, order),
                  icon: Icon(
                    order.notes != null && order.notes!.isNotEmpty
                        ? Icons.edit_outlined
                        : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    order.notes != null && order.notes!.isNotEmpty
                        ? 'Edit'
                        : 'Add Note',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (order.notes != null && order.notes!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      canEditNotes
                          ? 'No notes added yet. Tap "Add Note" to add special instructions.'
                          : 'No notes for this order.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_outlined,
                size: 20,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Rating',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RatingBarIndicator(
                rating: order.rating!,
                itemBuilder: (context, index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                itemCount: 5,
                itemSize: 24,
              ),
              const SizedBox(width: 8),
              Text(
                order.rating!.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          if (order.review != null && order.review!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.review!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineSection(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            context,
            'Order Placed',
            order.createdAt,
            true,
            Icons.shopping_cart_outlined,
          ),
          if (order.status != OrderStatus.pending)
            _buildTimelineItem(
              context,
              order.status == OrderStatus.accepted
                  ? 'Order Accepted'
                  : order.status == OrderStatus.completed
                      ? 'Order Completed'
                      : 'Order Cancelled',
              order.updatedAt,
              order.status == OrderStatus.completed || order.status == OrderStatus.cancelled,
              order.status == OrderStatus.accepted
                  ? Icons.check_circle_outline
                  : order.status == OrderStatus.completed
                      ? Icons.done_all
                      : Icons.cancel_outlined,
            ),
          if (order.scheduledDate != null)
            _buildTimelineItem(
              context,
              'Scheduled For',
              order.scheduledDate!,
              order.scheduledDate!.isBefore(DateTime.now()),
              Icons.schedule,
            ),
          if (order.deliveryDate != null)
            _buildTimelineItem(
              context,
              'Scheduled Delivery',
              order.deliveryDate!,
              false,
              Icons.local_shipping_outlined,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    DateTime date,
    bool isCompleted,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted
                  ? Colors.white
                  : Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.secondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatDateTime(date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    OrderModel order,
    bool isBuyer,
    bool isSeller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (order.status == OrderStatus.pending && isBuyer)
            CustomButton(
              text: 'Cancel Order',
              variant: CustomButtonVariant.outlined,
              onPressed: () => _showCancelDialog(context, order),
              fullWidth: true,
            ),
          if (order.status == OrderStatus.pending && isSeller) ...[
            CustomButton(
              text: 'Accept Order',
              onPressed: () => _acceptOrder(context, order),
              fullWidth: true,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Reject Order',
              variant: CustomButtonVariant.outlined,
              onPressed: () => _rejectOrder(context, order),
              fullWidth: true,
            ),
          ],
          if (order.status == OrderStatus.accepted && isSeller)
            CustomButton(
              text: 'Mark as Completed',
              onPressed: () => _completeOrder(context, order),
              fullWidth: true,
            ),
          if (order.status == OrderStatus.completed && isBuyer && order.rating == null)
            CustomButton(
              text: 'Rate Order',
              onPressed: () => _showRatingDialog(context, order),
              fullWidth: true,
            ),
          if (order.status == OrderStatus.completed || order.status == OrderStatus.accepted) ...[
            OutlinedButton.icon(
              onPressed: () => _generateReceipt(context, order),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Download Receipt'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (order.status == OrderStatus.completed) ...[
            CustomButton(
              text: 'Reorder',
              variant: CustomButtonVariant.outlined,
              onPressed: () => _reorder(context, order),
              fullWidth: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSetupRecurringOrderDialog(context, order),
                    icon: const Icon(Icons.repeat),
                    label: const Text('Recurring'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _saveAsTemplate(context, order),
                    icon: const Icon(Icons.bookmark),
                    label: const Text('Save Template'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if ((order.status == OrderStatus.accepted ||
                  order.status == OrderStatus.completed) &&
              order.disputeId == null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showFileDisputeDialog(context, order),
              icon: const Icon(Icons.gavel),
              label: const Text('File Dispute'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: Colors.orange,
              ),
            ),
          ],
          if (order.disputeId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gavel,
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A dispute has been filed for this order',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to dispute detail
                      context.push('/dispute/${order.disputeId}');
                    },
                    child: const Text('View Dispute'),
                  ),
                ],
              ),
            ),
          ],
          if (order.recurringOrderId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order is part of a recurring order',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to recurring orders screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Recurring orders management coming soon')),
                      );
                    },
                    child: const Text('View'),
                  ),
                ],
              ),
            ),
          ],
          if (order.status == OrderStatus.pending && isBuyer) ...[
            const SizedBox(height: 12),
            if (order.scheduledDate == null)
              OutlinedButton.icon(
                onPressed: () => _showScheduleOrderDialog(context, order),
                icon: const Icon(Icons.schedule),
                label: const Text('Schedule Order'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _cancelScheduleOrder(context, order),
                icon: const Icon(Icons.cancel_schedule_send),
                label: const Text('Cancel Schedule'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: Colors.red,
                ),
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // Navigate to chat with the other party
              final otherUserId = isBuyer ? order.sellerId : order.buyerId;
              // In a real app, you'd get the chat ID from the order or create one
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat feature coming soon')),
              );
            },
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Contact ${isBuyer ? 'Seller' : 'Buyer'}'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: compact ? 16 : 20,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          if (!compact) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ] else
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(
    BuildContext context,
    String label,
    String name,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, OrderModel order) {
    CancellationReason? selectedReason;
    String? customReason;
    bool showCustomField = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cancel Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select a reason for cancelling this order. This helps us improve our service.',
                ),
                const SizedBox(height: 16),
                ...CancellationReason.values.map((reason) {
                  return RadioListTile<CancellationReason>(
                    title: Row(
                      children: [
                        Icon(reason.icon, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(reason.label)),
                      ],
                    ),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                        showCustomField = value == CancellationReason.other;
                        if (!showCustomField) customReason = null;
                      });
                    },
                  );
                }),
                if (showCustomField) ...[
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Please specify the reason',
                      hintText: 'Enter cancellation reason',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    maxLength: 200,
                    onChanged: (value) {
                      setState(() => customReason = value.trim());
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null ||
                      (selectedReason == CancellationReason.other &&
                          (customReason == null || customReason!.isEmpty))
                  ? null
                  : () async {
                      final reason = selectedReason == CancellationReason.other
                          ? customReason!
                          : selectedReason!.label;

                      try {
                        await ref.read(ordersProvider.notifier).cancelOrder(
                              order.id,
                              reason,
                            );
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order cancelled')),
                          );
                          context.pop(); // Go back to orders list
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to cancel order: ${e.toString()}')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptOrder(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Order'),
        content: const Text('Are you sure you want to accept this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(ordersProvider.notifier).updateOrderStatus(
                    order.id,
                    OrderStatus.accepted,
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order accepted')),
              );
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _rejectOrder(BuildContext context, OrderModel order) {
    CancellationReason? selectedReason;
    String? customReason;
    bool showCustomField = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reject Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select a reason for rejecting this order. This helps us improve our service.',
                ),
                const SizedBox(height: 16),
                ...CancellationReason.values.map((reason) {
                  return RadioListTile<CancellationReason>(
                    title: Row(
                      children: [
                        Icon(reason.icon, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(reason.label)),
                      ],
                    ),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                        showCustomField = value == CancellationReason.other;
                        if (!showCustomField) customReason = null;
                      });
                    },
                  );
                }),
                if (showCustomField) ...[
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Please specify the reason',
                      hintText: 'Enter rejection reason',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    maxLength: 200,
                    onChanged: (value) {
                      setState(() => customReason = value.trim());
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null ||
                      (selectedReason == CancellationReason.other &&
                          (customReason == null || customReason!.isEmpty))
                  ? null
                  : () async {
                      final reason = selectedReason == CancellationReason.other
                          ? customReason!
                          : selectedReason!.label;

                      try {
                        await ref.read(ordersProvider.notifier).cancelOrder(
                              order.id,
                              reason,
                            );
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order rejected')),
                          );
                          context.pop(); // Go back to orders list
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to reject order: ${e.toString()}')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject Order'),
            ),
          ],
        ),
      ),
    );
  }

  void _completeOrder(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Order'),
        content: const Text('Mark this order as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(ordersProvider.notifier).updateOrderStatus(
                    order.id,
                    OrderStatus.completed,
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order marked as completed')),
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, OrderModel order) {
    double rating = 5.0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar(
                initialRating: rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 40,
                ratingWidget: RatingWidget(
                  full: const Icon(Icons.star, color: Colors.amber),
                  half: const Icon(Icons.star_half, color: Colors.amber),
                  empty: const Icon(Icons.star_border, color: Colors.grey),
                ),
                onRatingUpdate: (value) {
                  setState(() => rating = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  labelText: 'Review (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(ordersProvider.notifier).rateOrder(
                      order.id,
                      rating,
                      reviewController.text.trim(),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your rating!')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNotesDialog(BuildContext context, OrderModel order) {
    final notesController = TextEditingController(text: order.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Notes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add special instructions or notes for this order. These notes will be visible to both buyer and seller.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'e.g., Please deliver in the morning, Leave at back door, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (order.notes != null && order.notes!.isNotEmpty)
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(ordersProvider.notifier).updateOrderNotes(
                        order.id,
                        null,
                      );
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notes removed')),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to remove notes: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () async {
              final notes = notesController.text.trim();
              try {
                await ref.read(ordersProvider.notifier).updateOrderNotes(
                      order.id,
                      notes.isEmpty ? null : notes,
                    );
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        notes.isEmpty ? 'Notes removed' : 'Notes updated',
                      ),
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update notes: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledDateRow(
    BuildContext context,
    OrderModel order,
    bool isBuyer,
    bool isSeller,
  ) {
    final canEditSchedule = (isBuyer || isSeller) && order.status == OrderStatus.pending;
    final isOverdue = order.scheduledDate!.isBefore(DateTime.now());

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 20,
          color: isOverdue
              ? Colors.red
              : Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scheduled For',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Formatters.formatDateTime(order.scheduledDate!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isOverdue
                                ? Colors.red
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Overdue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (canEditSchedule)
          TextButton.icon(
            onPressed: () => _showScheduleOrderDialog(context, order),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
      ],
    );
  }

  void _showScheduleOrderDialog(BuildContext context, OrderModel order) {
    DateTime selectedDate = order.scheduledDate ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = order.scheduledDate != null
        ? TimeOfDay.fromDateTime(order.scheduledDate!)
        : const TimeOfDay(hour: 9, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Schedule Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select when this order should be placed. The seller will be notified when the scheduled time arrives.',
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(Formatters.formatDate(selectedDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        picked.hour,
                        picked.minute,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order will be automatically placed on ${Formatters.formatDateTime(selectedDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (order.scheduledDate != null)
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(ordersProvider.notifier).cancelScheduledOrder(order.id);
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Schedule cancelled')),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to cancel schedule: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: const Text('Cancel Schedule', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a future date and time')),
                  );
                  return;
                }

                try {
                  await ref.read(ordersProvider.notifier).scheduleOrder(order.id, selectedDate);
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order scheduled for ${Formatters.formatDateTime(selectedDate)}'),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to schedule order: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelScheduleOrder(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Schedule'),
        content: const Text('Are you sure you want to cancel the scheduled date for this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(ordersProvider.notifier).cancelScheduledOrder(order.id);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Schedule cancelled')),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel schedule: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _reorder(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder'),
        content: const Text('Create a new order with the same details?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(ordersProvider.notifier).reorder(order.id);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New order created')),
                );
                context.pop(); // Go back to orders list
              }
            },
            child: const Text('Reorder'),
          ),
        ],
      ),
    );
  }

  void _showSetupRecurringOrderDialog(BuildContext context, OrderModel order) {
    RecurrenceFrequency selectedFrequency = RecurrenceFrequency.weekly;
    DateTime? selectedEndDate;
    int? maxOccurrences;
    bool useEndDate = false;
    bool useMaxOccurrences = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Up Recurring Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automatically create new orders based on this completed order.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Frequency',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...RecurrenceFrequency.values.map((frequency) {
                  return RadioListTile<RecurrenceFrequency>(
                    title: Row(
                      children: [
                        Icon(frequency.icon, size: 20),
                        const SizedBox(width: 8),
                        Text(frequency.label),
                      ],
                    ),
                    value: frequency,
                    groupValue: selectedFrequency,
                    onChanged: (value) {
                      setState(() => selectedFrequency = value!);
                    },
                  );
                }),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Set end date'),
                  value: useEndDate,
                  onChanged: (value) {
                    setState(() {
                      useEndDate = value ?? false;
                      if (!useEndDate) selectedEndDate = null;
                    });
                  },
                ),
                if (useEndDate) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      selectedEndDate != null
                          ? Formatters.formatDate(selectedEndDate!)
                          : 'Select end date',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedEndDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => selectedEndDate = picked);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Set maximum occurrences'),
                  value: useMaxOccurrences,
                  onChanged: (value) {
                    setState(() {
                      useMaxOccurrences = value ?? false;
                      if (!useMaxOccurrences) maxOccurrences = null;
                    });
                  },
                ),
                if (useMaxOccurrences) ...[
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Maximum occurrences',
                      hintText: 'e.g., 10',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        maxOccurrences = int.tryParse(value);
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (useEndDate && selectedEndDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an end date')),
                  );
                  return;
                }
                if (useMaxOccurrences && (maxOccurrences == null || maxOccurrences! < 1)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid maximum occurrences')),
                  );
                  return;
                }

                try {
                  final recurringDataSource = ref.read(recurringOrdersDataSourceProvider);
                  final nextDate = _calculateNextDate(selectedFrequency, DateTime.now());
                  
                  final recurringOrder = RecurringOrderModel(
                    id: const Uuid().v4(),
                    orderId: order.id,
                    buyerId: order.buyerId,
                    sellerId: order.sellerId,
                    postId: order.postId,
                    frequency: selectedFrequency,
                    nextOrderDate: nextDate,
                    endDate: useEndDate ? selectedEndDate : null,
                    maxOccurrences: useMaxOccurrences ? maxOccurrences : null,
                  );

                  await recurringDataSource.createRecurringOrder(recurringOrder);
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Recurring order set up! Next order will be created on ${Formatters.formatDate(nextDate)}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to set up recurring order: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Set Up'),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _calculateNextDate(RecurrenceFrequency frequency, DateTime currentDate) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return currentDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return currentDate.add(const Duration(days: 7));
      case RecurrenceFrequency.biWeekly:
        return currentDate.add(const Duration(days: 14));
      case RecurrenceFrequency.monthly:
        return DateTime(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day,
        );
      case RecurrenceFrequency.custom:
        return currentDate.add(const Duration(days: 7));
    }
  }

  void _saveAsTemplate(BuildContext context, OrderModel order) {
    final nameController = TextEditingController(text: order.productName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save this order configuration as a template for quick reordering.'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g., Weekly Tomatoes Order',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Template will include:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildTemplatePreviewItem('Product', order.productName),
                  _buildTemplatePreviewItem('Quantity', order.quantity),
                  _buildTemplatePreviewItem('Price', Formatters.formatCurrency(order.price)),
                  _buildTemplatePreviewItem('Delivery', order.deliveryAddress),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _buildTemplatePreviewItem('Notes', order.notes!),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a template name')),
                );
                return;
              }

              try {
                final currentUser = ref.read(currentUserProvider);
                if (currentUser == null) return;

                final dataSource = ref.read(orderTemplatesDataSourceProvider);
                final template = OrderTemplateModel(
                  id: const Uuid().v4(),
                  userId: currentUser.id,
                  name: nameController.text.trim(),
                  postId: order.postId,
                  productName: order.productName,
                  productImage: order.productImage,
                  quantity: order.quantity,
                  price: order.price,
                  deliveryAddress: order.deliveryAddress,
                  notes: order.notes,
                );

                await dataSource.saveTemplate(template);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Template "${template.name}" saved successfully!'),
                      action: SnackBarAction(
                        label: 'View',
                        onPressed: () => context.push('/order-templates'),
                      ),
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save template: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _editDeliveryInstructions(BuildContext context, OrderModel order) {
    final instructionsController = TextEditingController(
      text: order.deliveryInstructions ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Instructions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add special instructions for delivery (e.g., "Leave at back door", "Ring doorbell", "Call when arriving").',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                hintText: 'e.g., Leave at back door, Ring doorbell twice',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.delivery_dining),
              ),
              maxLines: 4,
              maxLength: 200,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These instructions will be visible to the seller when delivering your order.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (order.deliveryInstructions != null && order.deliveryInstructions!.isNotEmpty)
            TextButton(
              onPressed: () async {
                try {
                  final updated = order.copyWith(deliveryInstructions: null);
                  await ref.read(ordersProvider.notifier).updateOrder(updated);
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delivery instructions removed')),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () async {
              try {
                final instructions = instructionsController.text.trim();
                final updated = order.copyWith(
                  deliveryInstructions: instructions.isEmpty ? null : instructions,
                );
                await ref.read(ordersProvider.notifier).updateOrder(updated);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        instructions.isEmpty
                            ? 'Delivery instructions removed'
                            : 'Delivery instructions updated',
                      ),
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFileDisputeDialog(BuildContext context, OrderModel order) {
    DisputeReason? selectedReason;
    String? customDescription;
    final descriptionController = TextEditingController();
    bool showCustomField = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('File Dispute'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please provide details about the issue with this order. Our support team will review your dispute.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reason',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...DisputeReason.values.map((reason) {
                  return RadioListTile<DisputeReason>(
                    title: Row(
                      children: [
                        Icon(reason.icon, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(reason.label)),
                      ],
                    ),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                        showCustomField = value == DisputeReason.other;
                        if (!showCustomField) customDescription = null;
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Describe the issue in detail',
                    hintText: 'Please provide as much detail as possible...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  maxLength: 500,
                  onChanged: (value) {
                    setState(() => customDescription = value.trim());
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Disputes are reviewed by our support team. You will be notified of the resolution.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null ||
                      descriptionController.text.trim().isEmpty
                  ? null
                  : () async {
                      try {
                        final currentUser = ref.read(currentUserProvider);
                        if (currentUser == null) return;

                        final disputesDataSource = ref.read(disputesDataSourceProvider);
                        final isBuyer = currentUser.id == order.buyerId;
                        final otherParty = isBuyer ? order.sellerId : order.buyerId;
                        final otherPartyName = isBuyer ? order.sellerName : order.buyerName;

                        final dispute = DisputeModel(
                          id: const Uuid().v4(),
                          orderId: order.id,
                          filedBy: currentUser.id,
                          filedByName: currentUser.name,
                          opposingParty: otherParty,
                          opposingPartyName: otherPartyName,
                          reason: selectedReason!,
                          description: descriptionController.text.trim(),
                          status: DisputeStatus.pending,
                        );

                        await disputesDataSource.fileDispute(dispute);

                        // Update order with dispute ID
                        final updatedOrder = order.copyWith(disputeId: dispute.id);
                        await ref.read(ordersProvider.notifier).updateOrder(updatedOrder);

                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dispute filed successfully. Our team will review it.'),
                            ),
                          );
                          context.push('/dispute/${dispute.id}');
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to file dispute: ${e.toString()}')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('File Dispute'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReceipt(BuildContext context, OrderModel order) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final receiptService = OrderReceiptService.instance;
      final filePath = await receiptService.generateReceipt(order);

      Navigator.pop(context); // Close loading

      // Show success dialog with share option
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Receipt Generated'),
            content: Text(
              'Receipt has been generated successfully:\n${filePath.split('/').last}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await receiptService.shareReceipt(filePath);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Receipt'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate receipt: ${e.toString()}')),
        );
      }
    }
  }
}

