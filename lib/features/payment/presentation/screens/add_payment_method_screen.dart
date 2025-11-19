import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/payment/data/models/payment_method_model.dart';
import 'package:localtrade/features/payment/providers/payment_provider.dart';
import 'package:uuid/uuid.dart';

class AddPaymentMethodScreen extends ConsumerStatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  ConsumerState<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends ConsumerState<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  
  PaymentMethodType? _selectedType;
  bool _isDefault = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method type')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      String label;
      String? cardLast4;
      String? cardBrand;
      String? bankName;
      String? accountNumber;

      if (_selectedType == PaymentMethodType.creditCard || 
          _selectedType == PaymentMethodType.debitCard) {
        cardLast4 = _cardNumberController.text.trim().length >= 4
            ? _cardNumberController.text.trim().substring(_cardNumberController.text.trim().length - 4)
            : null;
        cardBrand = _detectCardBrand(_cardNumberController.text.trim());
        label = '${cardBrand ?? "Card"} ending in ${cardLast4 ?? "****"}';
      } else if (_selectedType == PaymentMethodType.bankTransfer) {
        bankName = _bankNameController.text.trim();
        accountNumber = _accountNumberController.text.trim();
        label = '$bankName ••••${accountNumber.length >= 4 ? accountNumber.substring(accountNumber.length - 4) : "****"}';
      } else {
        label = _selectedType!.label;
      }

      final method = PaymentMethodModel(
        id: const Uuid().v4(),
        userId: currentUser.id,
        type: _selectedType!,
        label: label,
        cardLast4: cardLast4,
        cardBrand: cardBrand,
        bankName: bankName,
        accountNumber: accountNumber,
        isDefault: _isDefault,
      );

      final dataSource = ref.read(paymentMethodsDataSourceProvider);
      await dataSource.addPaymentMethod(method);

      if (mounted) {
        ref.invalidate(paymentMethodsProvider(currentUser.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method added successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add payment method: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _detectCardBrand(String cardNumber) {
    final number = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'Mastercard';
    if (number.startsWith('3')) return 'American Express';
    if (number.startsWith('6')) return 'Discover';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Add Payment Method'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Payment Method Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...PaymentMethodType.values.map((type) {
                return RadioListTile<PaymentMethodType>(
                  title: Text(type.label),
                  subtitle: Text(_getTypeDescription(type)),
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                  secondary: Icon(type.icon, color: type.color),
                );
              }).toList(),
              const SizedBox(height: 24),
              if (_selectedType == PaymentMethodType.creditCard ||
                  _selectedType == PaymentMethodType.debitCard) ...[
                CustomTextField(
                  controller: _cardNumberController,
                  label: 'Card Number',
                  hint: '1234 5678 9012 3456',
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.validateRequired(value, 'card number'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _cardHolderController,
                  label: 'Cardholder Name',
                  hint: 'John Doe',
                  validator: (value) => Validators.validateRequired(value, 'cardholder name'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _expiryController,
                        label: 'Expiry Date',
                        hint: 'MM/YY',
                        keyboardType: TextInputType.number,
                        validator: (value) => Validators.validateRequired(value, 'expiry date'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _cvvController,
                        label: 'CVV',
                        hint: '123',
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        validator: (value) => Validators.validateRequired(value, 'CVV'),
                      ),
                    ),
                  ],
                ),
              ],
              if (_selectedType == PaymentMethodType.bankTransfer) ...[
                CustomTextField(
                  controller: _bankNameController,
                  label: 'Bank Name',
                  hint: 'Enter bank name',
                  validator: (value) => Validators.validateRequired(value, 'bank name'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _accountNumberController,
                  label: 'Account Number',
                  hint: 'Enter account number',
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.validateRequired(value, 'account number'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _routingNumberController,
                  label: 'Routing Number',
                  hint: 'Enter routing number',
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.validateRequired(value, 'routing number'),
                ),
              ],
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Set as Default Payment Method'),
                subtitle: const Text('Use this method for future purchases'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value;
                  });
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Add Payment Method',
                onPressed: _isSubmitting ? null : _submit,
                isLoading: _isSubmitting,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeDescription(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'Pay with credit card';
      case PaymentMethodType.debitCard:
        return 'Pay with debit card';
      case PaymentMethodType.bankTransfer:
        return 'Direct bank transfer';
      case PaymentMethodType.wallet:
        return 'Pay from your wallet';
      case PaymentMethodType.cash:
        return 'Pay when you receive the order';
    }
  }
}

