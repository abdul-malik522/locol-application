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
import 'package:localtrade/features/payment/data/models/wallet_model.dart';
import 'package:localtrade/features/payment/providers/payment_provider.dart';
import 'package:uuid/uuid.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Wallet'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final walletAsync = ref.watch(walletProvider(currentUser.id));
    final transactionsAsync = ref.watch(walletTransactionsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Wallet'),
      body: walletAsync.when(
        data: (wallet) {
          if (wallet == null) {
            return const LoadingIndicator();
          }
          return Column(
            children: [
              _buildWalletBalance(context, wallet),
              Expanded(
                child: transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const EmptyState(
                        icon: Icons.account_balance_wallet,
                        title: 'No Transactions',
                        message: 'Your wallet transaction history will appear here.',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _buildTransactionCard(context, transaction);
                      },
                    );
                  },
                  loading: () => const LoadingIndicator(),
                  error: (error, stack) => ErrorView(
                    error: error.toString(),
                    onRetry: () => ref.invalidate(walletTransactionsProvider(currentUser.id)),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(walletProvider(currentUser.id)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Money'),
        onPressed: () => _showAddMoneyDialog(context, ref, currentUser.id),
      ),
    );
  }

  Widget _buildWalletBalance(BuildContext context, WalletModel wallet) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Wallet Balance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(wallet.balance),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            wallet.currency,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, WalletTransactionModel transaction) {
    final isPositive = transaction.type == WalletTransactionType.deposit ||
        transaction.type == WalletTransactionType.refund;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: transaction.type.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(transaction.type.icon, color: transaction.type.color),
        ),
        title: Text(transaction.type.label),
        subtitle: Text(
          timeago.format(transaction.createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : '-'}${Formatters.formatCurrency(transaction.amount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: transaction.status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transaction.status.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: transaction.status.color,
                      fontSize: 10,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMoneyDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money to Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: amountController,
              label: 'Amount',
              hint: 'Enter amount',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.attach_money,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
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
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              try {
                final walletDataSource = ref.read(walletDataSourceProvider);
                final transaction = WalletTransactionModel(
                  id: const Uuid().v4(),
                  userId: userId,
                  type: WalletTransactionType.deposit,
                  amount: amount,
                  currency: 'USD',
                  status: WalletTransactionStatus.completed,
                  description: 'Wallet deposit',
                );
                await walletDataSource.addTransaction(transaction);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(walletProvider(userId));
                  ref.invalidate(walletTransactionsProvider(userId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${Formatters.formatCurrency(amount)} to wallet')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add money: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

