import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/features/orders/data/models/cancellation_reason.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// Import CustomButtonVariant

class OrderCard extends ConsumerWidget {
  const OrderCard({
    required this.order,
    required this.currentUserId,
    super.key,
  });

  final OrderModel order;
  final String currentUserId;

  bool get isBuyer => order.buyerId == currentUserId;
  bool get isSeller => order.sellerId == currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/order/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const Divider(height: 24),
              _buildProductInfo(context),
              const Divider(height: 24),
              _buildOrderInfo(context),
              if (_shouldShowActions()) ...[
                const Divider(height: 24),
                _buildActions(context, ref),
              ],
              if (order.status == OrderStatus.completed &&
                  order.rating != null) ...[
                const Divider(height: 24),
                _buildRating(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.orderNumber,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                timeago.format(order.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
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
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedImage(
            imageUrl: order.productImage ?? 'https://picsum.photos/60/60',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.productName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quantity: ${order.quantity}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.formatCurrency(order.totalAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              isBuyer ? 'Seller: ${order.sellerName}' : 'Buyer: ${order.buyerName}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order.deliveryAddress,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (order.deliveryDate != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Delivery: ${Formatters.formatDate(order.deliveryDate!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _shouldShowActions() {
    if (order.status == OrderStatus.pending && isBuyer) return true;
    if (order.status == OrderStatus.completed && isBuyer && order.rating == null) {
      return true;
    }
    return false;
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    if (order.status == OrderStatus.pending && isBuyer) {
      return CustomButton(
        text: 'Cancel Order',
        variant: CustomButtonVariant.outlined,
        onPressed: () => _showCancelDialog(context, ref),
        fullWidth: true,
      );
    }

    if (order.status == OrderStatus.completed && isBuyer && order.rating == null) {
      return CustomButton(
        text: 'Rate Order',
        onPressed: () => _showRatingDialog(context, ref),
        fullWidth: true,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRating(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Rating',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            RatingBarIndicator(
              rating: order.rating!,
              itemBuilder: (context, index) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              itemCount: 5,
              itemSize: 20,
            ),
            const SizedBox(width: 8),
            Text(
              order.rating!.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        if (order.review != null) ...[
          const SizedBox(height: 8),
          Text(
            order.review!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order cancelled')),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to cancel order: ${e.toString()}')),
                        );
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

  void _showRatingDialog(BuildContext context, WidgetRef ref) {
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
}

