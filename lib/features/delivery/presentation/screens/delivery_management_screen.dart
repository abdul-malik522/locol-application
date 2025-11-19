import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/delivery/data/models/delivery_model.dart';
import 'package:localtrade/features/delivery/providers/delivery_provider.dart';

class DeliveryManagementScreen extends ConsumerStatefulWidget {
  const DeliveryManagementScreen({super.key});

  @override
  ConsumerState<DeliveryManagementScreen> createState() => _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState extends ConsumerState<DeliveryManagementScreen> {
  DeliveryStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(deliveriesProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Delivery Management'),
      body: Column(
        children: [
          _buildStatusFilter(context),
          Expanded(
            child: deliveriesAsync.when(
              data: (deliveries) {
                final filtered = _selectedStatus == null
                    ? deliveries
                    : deliveries.where((d) => d.status == _selectedStatus).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.local_shipping,
                    title: 'No Deliveries',
                    message: _selectedStatus == null
                        ? 'No deliveries found.'
                        : 'No deliveries with this status.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final delivery = filtered[index];
                    return _buildDeliveryCard(context, ref, delivery);
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorView(
                error: error.toString(),
                onRetry: () => ref.invalidate(deliveriesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(context, 'All', null),
          const SizedBox(width: 8),
          ...DeliveryStatus.values.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(context, status.label, status),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, DeliveryStatus? status) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context,
    WidgetRef ref,
    DeliveryModel delivery,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(delivery.method.icon, color: delivery.method.color),
        title: Text('Order #${delivery.orderId.substring(0, 8)}'),
        subtitle: Text('${delivery.status.label} • ${timeago.format(delivery.createdAt)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Method', delivery.method.label),
                _buildInfoRow(context, 'Status', delivery.status.label),
                _buildInfoRow(context, 'Address', delivery.deliveryAddress),
                if (delivery.pickupLocation != null)
                  _buildInfoRow(context, 'Pickup Location', delivery.pickupLocation!),
                if (delivery.scheduledDate != null)
                  _buildInfoRow(
                    context,
                    'Scheduled',
                    DateFormat('MMM dd, yyyy HH:mm').format(delivery.scheduledDate!),
                  ),
                if (delivery.estimatedDeliveryTime != null)
                  _buildInfoRow(
                    context,
                    'Estimated Delivery',
                    DateFormat('MMM dd, yyyy HH:mm').format(delivery.estimatedDeliveryTime!),
                  ),
                if (delivery.driverName != null)
                  _buildInfoRow(context, 'Driver', delivery.driverName!),
                if (delivery.trackingNumber != null)
                  _buildInfoRow(context, 'Tracking', delivery.trackingNumber!),
                if (delivery.deliveryInstructions != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Instructions:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(delivery.deliveryInstructions!),
                ],
                const SizedBox(height: 16),
                if (delivery.status != DeliveryStatus.delivered &&
                    delivery.status != DeliveryStatus.cancelled)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Update Status'),
                          onPressed: () => _showUpdateStatusDialog(context, ref, delivery),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.map),
                          label: const Text('Track'),
                          onPressed: () => context.push('/tracking/${delivery.orderId}'),
                        ),
                      ),
                    ],
                  ),
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

  Future<void> _showUpdateStatusDialog(
    BuildContext context,
    WidgetRef ref,
    DeliveryModel delivery,
  ) async {
    DeliveryStatus? selectedStatus = delivery.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Delivery Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...DeliveryStatus.values.map((status) {
                return RadioListTile<DeliveryStatus>(
                  title: Text(status.label),
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedStatus == null) return;

                try {
                  final dataSource = ref.read(deliveryDataSourceProvider);
                  await dataSource.updateDelivery(
                    delivery.copyWith(
                      status: selectedStatus,
                      actualDeliveryTime: selectedStatus == DeliveryStatus.delivered
                          ? DateTime.now()
                          : delivery.actualDeliveryTime,
                    ),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(deliveriesProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delivery status updated')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

