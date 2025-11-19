import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';
import 'package:localtrade/features/payment/data/models/payment_method_model.dart';
import 'package:localtrade/features/payment/data/models/payment_model.dart';
import 'package:localtrade/features/payment/data/services/payment_gateway_service.dart';
import 'package:localtrade/features/payment/data/services/tax_calculation_service.dart';
import 'package:localtrade/features/payment/providers/payment_provider.dart';
import 'package:uuid/uuid.dart';

class PaymentProcessingScreen extends ConsumerStatefulWidget {
  const PaymentProcessingScreen({
    required this.order,
    super.key,
  });

  final OrderModel order;

  @override
  ConsumerState<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends ConsumerState<PaymentProcessingScreen> {
  PaymentMethodModel? _selectedMethod;
  PaymentGateway? _selectedGateway;
  bool _isProcessing = false;
  double? _taxAmount;
  double? _totalWithTax;

  @override
  void initState() {
    super.initState();
    _calculateTax();
    _loadDefaultPaymentMethod();
  }

  Future<void> _calculateTax() async {
    final taxService = TaxCalculationService.instance;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Mock location - in real app, get from user profile
    final result = await taxService.calculateTax(
      amount: widget.order.totalAmount,
      country: 'US',
      state: 'CA',
    );

    setState(() {
      _taxAmount = result.taxAmount;
      _totalWithTax = result.totalAmount;
    });
  }

  Future<void> _loadDefaultPaymentMethod() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final defaultMethod = await ref.read(defaultPaymentMethodProvider(currentUser.id).future);
    if (defaultMethod != null) {
      setState(() {
        _selectedMethod = defaultMethod;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (_selectedGateway == null && _selectedMethod!.type != PaymentMethodType.wallet && 
        _selectedMethod!.type != PaymentMethodType.cash) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment gateway')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final paymentsDataSource = ref.read(paymentsDataSourceProvider);
      final paymentGatewayService = PaymentGatewayService.instance;

      // Create payment record
      final payment = PaymentModel(
        id: const Uuid().v4(),
        orderId: widget.order.id,
        userId: currentUser.id,
        amount: _totalWithTax ?? widget.order.totalAmount,
        currency: 'USD',
        method: _selectedMethod!,
        status: PaymentStatus.processing,
      );

      PaymentModel processedPayment;

      // Process payment based on method
      if (_selectedMethod!.type == PaymentMethodType.wallet) {
        // Handle wallet payment
        final wallet = await ref.read(walletProvider(currentUser.id).future);
        if (wallet == null || wallet.balance < payment.amount) {
          throw Exception('Insufficient wallet balance');
        }
        // In a real app, deduct from wallet here
        processedPayment = payment.copyWith(
          status: PaymentStatus.completed,
          transactionId: 'WALLET_${const Uuid().v4().substring(0, 8).toUpperCase()}',
          completedAt: DateTime.now(),
        );
      } else if (_selectedMethod!.type == PaymentMethodType.cash) {
        // Cash on delivery - no processing needed
        processedPayment = payment.copyWith(
          status: PaymentStatus.pending,
          transactionId: 'COD_${const Uuid().v4().substring(0, 8).toUpperCase()}',
        );
      } else {
        // Process through payment gateway
        final gateway = _selectedGateway!;
        processedPayment = await paymentGatewayService.processPayment(
          payment: payment,
          gateway: gateway,
        );
      }

      // Save payment
      await paymentsDataSource.createPayment(processedPayment);

      if (mounted) {
        if (processedPayment.isCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful!')),
          );
          context.pop(true); // Return success
        } else if (processedPayment.isFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${processedPayment.failureReason ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Pending (e.g., cash on delivery)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment will be collected on delivery')),
          );
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Payment'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final methodsAsync = ref.watch(paymentMethodsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Payment'),
      body: methodsAsync.when(
        data: (methods) {
          if (methods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.credit_card, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No payment methods available'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/add-payment-method'),
                    child: const Text('Add Payment Method'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummary(context),
                const SizedBox(height: 24),
                Text(
                  'Select Payment Method',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ...methods.map((method) {
                  return RadioListTile<PaymentMethodModel>(
                    title: Text(method.label),
                    subtitle: Text(method.type.label),
                    value: method,
                    groupValue: _selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value;
                        _selectedGateway = null; // Reset gateway when method changes
                      });
                    },
                    secondary: Icon(method.type.icon, color: method.type.color),
                  );
                }).toList(),
                if (_selectedMethod != null &&
                    _selectedMethod!.type != PaymentMethodType.wallet &&
                    _selectedMethod!.type != PaymentMethodType.cash) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Select Payment Gateway',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...PaymentGateway.values.map((gateway) {
                    return RadioListTile<PaymentGateway>(
                      title: Text(gateway.name),
                      value: gateway,
                      groupValue: _selectedGateway,
                      onChanged: (value) {
                        setState(() {
                          _selectedGateway = value;
                        });
                      },
                      secondary: Icon(gateway.icon),
                    );
                  }).toList(),
                ],
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Pay ${Formatters.formatCurrency(_totalWithTax ?? widget.order.totalAmount)}',
                  onPressed: _isProcessing ? null : _processPayment,
                  isLoading: _isProcessing,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/payment-methods'),
                  child: const Text('Manage Payment Methods'),
                ),
              ],
            ),
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

  Widget _buildOrderSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(context, 'Subtotal', Formatters.formatCurrency(widget.order.totalAmount)),
            if (_taxAmount != null)
              _buildSummaryRow(context, 'Tax', Formatters.formatCurrency(_taxAmount!)),
            const Divider(),
            _buildSummaryRow(
              context,
              'Total',
              Formatters.formatCurrency(_totalWithTax ?? widget.order.totalAmount),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}

