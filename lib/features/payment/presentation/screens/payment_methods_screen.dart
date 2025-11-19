import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/payment/data/models/payment_method_model.dart';
import 'package:localtrade/features/payment/providers/payment_provider.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Payment Methods'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final methodsAsync = ref.watch(paymentMethodsProvider(currentUser.id));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Payment Methods',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-payment-method'),
            tooltip: 'Add Payment Method',
          ),
        ],
      ),
      body: methodsAsync.when(
        data: (methods) {
          if (methods.isEmpty) {
            return const EmptyState(
              icon: Icons.credit_card,
              title: 'No Payment Methods',
              message: 'Add a payment method to make purchases faster.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return _buildPaymentMethodCard(context, ref, method, currentUser.id);
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(paymentMethodsProvider(currentUser.id)),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    WidgetRef ref,
    PaymentMethodModel method,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(method.type.icon, color: method.type.color),
        title: Text(method.label),
        subtitle: Text(method.type.label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (method.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Default',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'set_default') {
                  _setAsDefault(context, ref, method, userId);
                } else if (value == 'delete') {
                  _deleteMethod(context, ref, method, userId);
                }
              },
              itemBuilder: (context) => [
                if (!method.isDefault)
                  const PopupMenuItem(
                    value: 'set_default',
                    child: Text('Set as Default'),
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

  Future<void> _setAsDefault(
    BuildContext context,
    WidgetRef ref,
    PaymentMethodModel method,
    String userId,
  ) async {
    try {
      final dataSource = ref.read(paymentMethodsDataSourceProvider);
      await dataSource.updatePaymentMethod(method.copyWith(isDefault: true));
      ref.invalidate(paymentMethodsProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method set as default')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteMethod(
    BuildContext context,
    WidgetRef ref,
    PaymentMethodModel method,
    String userId,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: const Text('Are you sure you want to delete this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final dataSource = ref.read(paymentMethodsDataSourceProvider);
                await dataSource.deletePaymentMethod(method.id, userId);
                ref.invalidate(paymentMethodsProvider(userId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment method deleted')),
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
}

