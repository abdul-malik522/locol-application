import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/inventory/data/models/inventory_model.dart';
import 'package:localtrade/features/inventory/providers/inventory_provider.dart';
import 'package:uuid/uuid.dart';

class StockAlertsScreen extends ConsumerStatefulWidget {
  const StockAlertsScreen({super.key});

  @override
  ConsumerState<StockAlertsScreen> createState() => _StockAlertsScreenState();
}

class _StockAlertsScreenState extends ConsumerState<StockAlertsScreen> {
  StockAlertType? _filterType;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Stock Alerts'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final alertsAsync = ref.watch(stockAlertsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Stock Alerts'),
      body: Column(
        children: [
          _buildFilterChips(context),
          Expanded(
            child: alertsAsync.when(
              data: (alerts) {
                final filtered = _filterType == null
                    ? alerts
                    : alerts.where((a) => a.alertType == _filterType).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.notifications_outlined,
                    title: 'No Stock Alerts',
                    message: 'Your stock alerts will appear here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final alert = filtered[index];
                    return _buildAlertCard(context, ref, alert, currentUser.id);
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorView(
                error: error.toString(),
                onRetry: () => ref.invalidate(stockAlertsProvider(currentUser.id)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_alert),
        label: const Text('Create Alert'),
        onPressed: () => _showCreateAlertDialog(context, ref, currentUser.id),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(context, 'All', null),
          const SizedBox(width: 8),
          ...StockAlertType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(context, type.label, type),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, StockAlertType? type) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = selected ? type : null;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    WidgetRef ref,
    StockAlertModel alert,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alert.isActive ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            alert.alertType.icon,
            color: alert.isActive ? Colors.orange : Colors.grey,
          ),
        ),
        title: Text(alert.productName),
        subtitle: Text(
          '${alert.alertType.label} • Threshold: ${alert.threshold}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alert.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle') {
                  _toggleAlert(context, ref, alert, userId);
                } else if (value == 'delete') {
                  _deleteAlert(context, ref, alert, userId);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(alert.isActive ? 'Deactivate' : 'Activate'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAlert(
    BuildContext context,
    WidgetRef ref,
    StockAlertModel alert,
    String userId,
  ) async {
    try {
      final dataSource = ref.read(inventoryDataSourceProvider);
      await dataSource.updateStockAlert(alert.copyWith(isActive: !alert.isActive));
      ref.invalidate(stockAlertsProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(alert.isActive ? 'Alert deactivated' : 'Alert activated'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update alert: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAlert(
    BuildContext context,
    WidgetRef ref,
    StockAlertModel alert,
    String userId,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: const Text('Are you sure you want to delete this stock alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final dataSource = ref.read(inventoryDataSourceProvider);
                await dataSource.deleteStockAlert(alert.id, userId);
                ref.invalidate(stockAlertsProvider(userId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateAlertDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final postIdController = TextEditingController();
    final productNameController = TextEditingController();
    final thresholdController = TextEditingController();
    StockAlertType? selectedType = StockAlertType.lowStock;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Stock Alert'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: postIdController,
                  label: 'Post ID',
                  hint: 'Enter post ID',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: productNameController,
                  label: 'Product Name',
                  hint: 'Enter product name',
                ),
                const SizedBox(height: 16),
                Text(
                  'Alert Type',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ...StockAlertType.values.map((type) {
                  return RadioListTile<StockAlertType>(
                    title: Text(type.label),
                    value: type,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                      });
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: thresholdController,
                  label: 'Threshold',
                  hint: 'Enter threshold value',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final threshold = double.tryParse(thresholdController.text.trim());
                if (threshold == null || threshold <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid threshold')),
                  );
                  return;
                }

                try {
                  final dataSource = ref.read(inventoryDataSourceProvider);
                  final alert = StockAlertModel(
                    id: const Uuid().v4(),
                    inventoryItemId: '', // Would link to inventory item
                    postId: postIdController.text.trim(),
                    productName: productNameController.text.trim(),
                    alertType: selectedType!,
                    threshold: threshold,
                    isActive: true,
                  );
                  await dataSource.createStockAlert(alert);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(stockAlertsProvider(userId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stock alert created')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create alert: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

