import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/payment/data/models/payout_model.dart';
import 'package:localtrade/features/payment/providers/payment_provider.dart';
import 'package:uuid/uuid.dart';

class PayoutsScreen extends ConsumerStatefulWidget {
  const PayoutsScreen({super.key});

  @override
  ConsumerState<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends ConsumerState<PayoutsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Payouts'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final payoutsAsync = ref.watch(payoutsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Payouts'),
      body: payoutsAsync.when(
        data: (payouts) {
          if (payouts.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet,
              title: 'No Payouts',
              message: 'Your payout history will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payouts.length,
            itemBuilder: (context, index) {
              final payout = payouts[index];
              return _buildPayoutCard(context, payout);
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(payoutsProvider(currentUser.id)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.send),
        label: const Text('Request Payout'),
        onPressed: () => _showRequestPayoutDialog(context, ref, currentUser.id),
      ),
    );
  }

  Widget _buildPayoutCard(BuildContext context, PayoutModel payout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(payout.method.icon, color: payout.method.color),
        title: Text(Formatters.formatCurrency(payout.amount)),
        subtitle: Text('${payout.method.label} • ${timeago.format(payout.createdAt)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Status', payout.status.label),
                _buildInfoRow(context, 'Method', payout.method.label),
                if (payout.bankName != null)
                  _buildInfoRow(context, 'Bank', payout.bankName!),
                if (payout.accountNumber != null)
                  _buildInfoRow(context, 'Account', '••••${payout.accountNumber!.substring(payout.accountNumber!.length - 4)}'),
                if (payout.transactionId != null)
                  _buildInfoRow(context, 'Transaction ID', payout.transactionId!),
                if (payout.processedAt != null)
                  _buildInfoRow(context, 'Processed', DateFormat('MMM dd, yyyy').format(payout.processedAt!)),
                if (payout.failureReason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Failure: ${payout.failureReason}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                    ),
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

  Future<void> _showRequestPayoutDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final amountController = TextEditingController();
    PayoutMethod? selectedMethod = PayoutMethod.bankTransfer;
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final routingNumberController = TextEditingController();
    final accountHolderController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Payout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: amountController,
                  label: 'Amount',
                  hint: 'Enter amount',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                const SizedBox(height: 16),
                Text(
                  'Payout Method',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ...PayoutMethod.values.map((method) {
                  return RadioListTile<PayoutMethod>(
                    title: Text(method.label),
                    value: method,
                    groupValue: selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedMethod = value;
                      });
                    },
                  );
                }).toList(),
                if (selectedMethod == PayoutMethod.bankTransfer) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: bankNameController,
                    label: 'Bank Name',
                    hint: 'Enter bank name',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: accountNumberController,
                    label: 'Account Number',
                    hint: 'Enter account number',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: routingNumberController,
                    label: 'Routing Number',
                    hint: 'Enter routing number',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: accountHolderController,
                    label: 'Account Holder Name',
                    hint: 'Enter account holder name',
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
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                try {
                  final payoutsDataSource = ref.read(payoutsDataSourceProvider);
                  final payout = PayoutModel(
                    id: const Uuid().v4(),
                    userId: userId,
                    amount: amount,
                    currency: 'USD',
                    method: selectedMethod!,
                    status: PayoutStatus.pending,
                    bankName: bankNameController.text.trim().isNotEmpty
                        ? bankNameController.text.trim()
                        : null,
                    accountNumber: accountNumberController.text.trim().isNotEmpty
                        ? accountNumberController.text.trim()
                        : null,
                    routingNumber: routingNumberController.text.trim().isNotEmpty
                        ? routingNumberController.text.trim()
                        : null,
                    accountHolderName: accountHolderController.text.trim().isNotEmpty
                        ? accountHolderController.text.trim()
                        : null,
                  );
                  await payoutsDataSource.createPayout(payout);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(payoutsProvider(userId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payout request submitted')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to request payout: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Request'),
            ),
          ],
        ),
      ),
    );
  }
}

