import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/inventory/data/models/inventory_model.dart';
import 'package:localtrade/features/inventory/providers/inventory_provider.dart';
import 'package:uuid/uuid.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Inventory'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final inventoryAsync = ref.watch(inventoryItemsProvider(currentUser.id));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Inventory',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-inventory-item'),
            tooltip: 'Add Inventory Item',
          ),
        ],
      ),
      body: inventoryAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2,
              title: 'No Inventory Items',
              message: 'Add inventory items to track your stock levels.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildInventoryCard(context, ref, item, currentUser.id);
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(inventoryItemsProvider(currentUser.id)),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(
    BuildContext context,
    WidgetRef ref,
    InventoryItemModel item,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.status.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.status.icon, color: item.status.color),
        ),
        title: Text(item.productName),
        subtitle: Text('${item.currentStock} ${item.unit} available'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Current Stock', '${item.currentStock} ${item.unit}'),
                _buildInfoRow(context, 'Min Stock Level', '${item.minStockLevel} ${item.unit}'),
                _buildInfoRow(context, 'Max Stock Level', '${item.maxStockLevel} ${item.unit}'),
                _buildInfoRow(context, 'Status', item.status.label),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: item.stockPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(item.status.color),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.stockPercentage.toStringAsFixed(1)}% of max capacity',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (item.lastRestockedAt != null)
                  _buildInfoRow(
                    context,
                    'Last Restocked',
                    DateFormat('MMM dd, yyyy').format(item.lastRestockedAt!),
                  ),
                if (item.lastSoldAt != null)
                  _buildInfoRow(
                    context,
                    'Last Sold',
                    DateFormat('MMM dd, yyyy').format(item.lastSoldAt!),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () => context.push('/edit-inventory-item/${item.id}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Restock'),
                        onPressed: () => _showRestockDialog(context, ref, item, userId),
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
            width: 120,
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

  Future<void> _showRestockDialog(
    BuildContext context,
    WidgetRef ref,
    InventoryItemModel item,
    String userId,
  ) async {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restock Inventory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current stock: ${item.currentStock} ${item.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity to add',
                hintText: 'Enter quantity',
                suffixText: item.unit,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final quantity = double.tryParse(quantityController.text.trim());
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity')),
                );
                return;
              }

              try {
                final dataSource = ref.read(inventoryDataSourceProvider);
                final updated = item.copyWith(
                  currentStock: item.currentStock + quantity,
                  lastRestockedAt: DateTime.now(),
                );
                await dataSource.updateInventoryItem(updated);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(inventoryItemsProvider(userId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restocked ${quantity} ${item.unit}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to restock: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }
}

