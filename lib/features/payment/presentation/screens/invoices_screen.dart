import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/payment/data/models/invoice_model.dart';
import 'package:localtrade/features/payment/data/services/invoice_generation_service.dart';
import 'package:localtrade/features/payment/providers/payment_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Invoices'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final invoicesAsync = ref.watch(invoicesProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Invoices'),
      body: invoicesAsync.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long,
              title: 'No Invoices',
              message: 'Your invoices will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return _buildInvoiceCard(context, ref, invoice);
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(invoicesProvider(currentUser.id)),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) {
    final isOverdue = invoice.isOverdue;
    final isPaid = invoice.isPaid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          isPaid ? Icons.check_circle : Icons.receipt_long,
          color: isPaid ? Colors.green : (isOverdue ? Colors.red : Colors.blue),
        ),
        title: Text(invoice.invoiceNumber),
        subtitle: Text(
          '${Formatters.formatCurrency(invoice.totalAmount)} • ${timeago.format(invoice.createdAt)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Order ID', invoice.orderId),
                _buildInfoRow(context, 'Buyer', invoice.buyerName),
                _buildInfoRow(context, 'Seller', invoice.sellerName),
                _buildInfoRow(context, 'Subtotal', Formatters.formatCurrency(invoice.subtotal)),
                if (invoice.discountAmount != null && invoice.discountAmount! > 0)
                  _buildInfoRow(context, 'Discount', Formatters.formatCurrency(-invoice.discountAmount!)),
                if (invoice.shippingAmount != null && invoice.shippingAmount! > 0)
                  _buildInfoRow(context, 'Shipping', Formatters.formatCurrency(invoice.shippingAmount!)),
                _buildInfoRow(context, 'Tax', Formatters.formatCurrency(invoice.taxAmount)),
                _buildInfoRow(context, 'Total', Formatters.formatCurrency(invoice.totalAmount)),
                _buildInfoRow(context, 'Issue Date', DateFormat('MMM dd, yyyy').format(invoice.issueDate)),
                _buildInfoRow(context, 'Due Date', DateFormat('MMM dd, yyyy').format(invoice.dueDate)),
                if (invoice.paidDate != null)
                  _buildInfoRow(context, 'Paid Date', DateFormat('MMM dd, yyyy').format(invoice.paidDate!)),
                if (isOverdue) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Overdue',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF'),
                    onPressed: () => _downloadInvoice(context, ref, invoice),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View Order'),
                    onPressed: () => context.push('/order/${invoice.orderId}'),
                  ),
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
            width: 100,
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

  Future<void> _downloadInvoice(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final invoiceService = InvoiceGenerationService.instance;
      final filePath = await invoiceService.generateInvoicePDF(invoice);

      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invoice Generated'),
            content: Text('Invoice saved to:\n${filePath.split('/').last}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await invoiceService.shareInvoice(filePath);
                },
                child: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate invoice: ${e.toString()}')),
        );
      }
    }
  }
}

