import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/orders/data/models/order_template_model.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';

class OrderTemplatesScreen extends ConsumerStatefulWidget {
  const OrderTemplatesScreen({super.key});

  @override
  ConsumerState<OrderTemplatesScreen> createState() => _OrderTemplatesScreenState();
}

class _OrderTemplatesScreenState extends ConsumerState<OrderTemplatesScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Order Templates'),
        body: Center(child: Text('Please login to view templates')),
      );
    }

    final templatesAsync = ref.watch(orderTemplatesProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Order Templates'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(orderTemplatesProvider(currentUser.id));
        },
        child: templatesAsync.when(
          data: (templates) {
            if (templates.isEmpty) {
              return const EmptyState(
                icon: Icons.bookmark_border,
                title: 'No Templates Yet',
                message: 'Save order configurations as templates for quick reordering.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _buildTemplateCard(context, ref, template, currentUser.id);
              },
            );
          },
          loading: () => const LoadingIndicator(),
          error: (error, _) => ErrorView(
            error: error.toString(),
            onRetry: () => ref.invalidate(orderTemplatesProvider(currentUser.id)),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    WidgetRef ref,
    OrderTemplateModel template,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _useTemplate(context, ref, template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (template.productImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImage(
                    imageUrl: template.productImage!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.productName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          template.quantity,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.attach_money,
                          size: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.formatCurrency(template.price),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            template.deliveryAddress,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Updated ${timeago.format(template.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'use') {
                    _useTemplate(context, ref, template);
                  } else if (value == 'edit') {
                    _editTemplate(context, ref, template, userId);
                  } else if (value == 'delete') {
                    _deleteTemplate(context, ref, template.id, userId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'use',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart),
                        SizedBox(width: 8),
                        Text('Use Template'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _useTemplate(
    BuildContext context,
    WidgetRef ref,
    OrderTemplateModel template,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${template.productName}'),
            const SizedBox(height: 8),
            Text('Quantity: ${template.quantity}'),
            const SizedBox(height: 8),
            Text('Price: ${Formatters.formatCurrency(template.price)}'),
            const SizedBox(height: 8),
            Text('Delivery: ${template.deliveryAddress}'),
            const SizedBox(height: 16),
            const Text(
              'This will create a new order with the template details. You can modify the order before placing it.',
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
              Navigator.pop(context);
              // Navigate to post detail or create order flow
              // For now, show a message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Creating order from template: ${template.name}'),
                  ),
                );
                // Navigate to post detail to create order
                context.push('/post/${template.postId}');
              }
            },
            child: const Text('Create Order'),
          ),
        ],
      ),
    );
  }

  void _editTemplate(
    BuildContext context,
    WidgetRef ref,
    OrderTemplateModel template,
    String userId,
  ) {
    final nameController = TextEditingController(text: template.name);
    final quantityController = TextEditingController(text: template.quantity);
    final priceController = TextEditingController(text: template.price.toStringAsFixed(2));
    final addressController = TextEditingController(text: template.deliveryAddress);
    final notesController = TextEditingController(text: template.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Template'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
            onPressed: () async {
              final price = double.tryParse(priceController.text);
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a template name')),
                );
                return;
              }
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid price')),
                );
                return;
              }

              try {
                final dataSource = ref.read(orderTemplatesDataSourceProvider);
                final updated = template.copyWith(
                  name: nameController.text.trim(),
                  quantity: quantityController.text.trim(),
                  price: price,
                  deliveryAddress: addressController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                await dataSource.saveTemplate(updated);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template updated')),
                  );
                  ref.invalidate(orderTemplatesProvider(userId));
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update template: ${e.toString()}')),
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

  void _deleteTemplate(
    BuildContext context,
    WidgetRef ref,
    String templateId,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: const Text('Are you sure you want to delete this template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final dataSource = ref.read(orderTemplatesDataSourceProvider);
                await dataSource.deleteTemplate(templateId, userId);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template deleted')),
                  );
                  ref.invalidate(orderTemplatesProvider(userId));
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete template: ${e.toString()}')),
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
}

