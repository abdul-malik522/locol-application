import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/payment/data/datasources/invoices_datasource.dart';
import 'package:localtrade/features/payment/data/datasources/payment_methods_datasource.dart';
import 'package:localtrade/features/payment/data/datasources/payments_datasource.dart';
import 'package:localtrade/features/payment/data/datasources/payouts_datasource.dart';
import 'package:localtrade/features/payment/data/datasources/wallet_datasource.dart';
import 'package:localtrade/features/payment/data/models/invoice_model.dart';
import 'package:localtrade/features/payment/data/models/payment_method_model.dart';
import 'package:localtrade/features/payment/data/models/payment_model.dart';
import 'package:localtrade/features/payment/data/models/payout_model.dart';
import 'package:localtrade/features/payment/data/models/wallet_model.dart';

// Payment Methods Providers
final paymentMethodsDataSourceProvider =
    Provider<PaymentMethodsDataSource>((ref) => PaymentMethodsDataSource.instance);

final paymentMethodsProvider =
    FutureProvider.family<List<PaymentMethodModel>, String>((ref, userId) {
  final dataSource = ref.watch(paymentMethodsDataSourceProvider);
  return dataSource.getPaymentMethods(userId);
});

final defaultPaymentMethodProvider =
    FutureProvider.family<PaymentMethodModel?, String>((ref, userId) {
  final dataSource = ref.watch(paymentMethodsDataSourceProvider);
  return dataSource.getDefaultPaymentMethod(userId);
});

// Payments Providers
final paymentsDataSourceProvider =
    Provider<PaymentsDataSource>((ref) => PaymentsDataSource.instance);

final paymentsProvider =
    FutureProvider.family<List<PaymentModel>, String>((ref, userId) {
  final dataSource = ref.watch(paymentsDataSourceProvider);
  return dataSource.getPaymentsByUser(userId);
});

final paymentByOrderIdProvider =
    FutureProvider.family<PaymentModel?, String>((ref, orderId) {
  final dataSource = ref.watch(paymentsDataSourceProvider);
  return dataSource.getPaymentByOrderId(orderId);
});

// Wallet Providers
final walletDataSourceProvider =
    Provider<WalletDataSource>((ref) => WalletDataSource.instance);

final walletProvider =
    FutureProvider.family<WalletModel?, String>((ref, userId) {
  final dataSource = ref.watch(walletDataSourceProvider);
  return dataSource.getWallet(userId);
});

final walletTransactionsProvider =
    FutureProvider.family<List<WalletTransactionModel>, String>((ref, userId) {
  final dataSource = ref.watch(walletDataSourceProvider);
  return dataSource.getTransactions(userId);
});

// Payouts Providers
final payoutsDataSourceProvider =
    Provider<PayoutsDataSource>((ref) => PayoutsDataSource.instance);

final payoutsProvider =
    FutureProvider.family<List<PayoutModel>, String>((ref, userId) {
  final dataSource = ref.watch(payoutsDataSourceProvider);
  return dataSource.getPayouts(userId);
});

// Invoices Providers
final invoicesDataSourceProvider =
    Provider<InvoicesDataSource>((ref) => InvoicesDataSource.instance);

final invoicesProvider =
    FutureProvider.family<List<InvoiceModel>, String>((ref, userId) {
  final dataSource = ref.watch(invoicesDataSourceProvider);
  return dataSource.getInvoicesByUser(userId);
});

final invoiceByOrderIdProvider =
    FutureProvider.family<InvoiceModel?, String>((ref, orderId) {
  final dataSource = ref.watch(invoicesDataSourceProvider);
  return dataSource.getInvoiceByOrderId(orderId);
});

