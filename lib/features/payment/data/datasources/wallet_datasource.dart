import 'dart:async';

import 'package:localtrade/features/payment/data/models/wallet_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class WalletDataSource {
  WalletDataSource._();
  static final WalletDataSource instance = WalletDataSource._();
  final _uuid = const Uuid();

  static const String _walletsKeyPrefix = 'wallets_';
  static const String _transactionsKeyPrefix = 'wallet_transactions_';

  String _getWalletKey(String userId) => '$_walletsKeyPrefix$userId';
  String _getTransactionsKey(String userId) => '$_transactionsKeyPrefix$userId';

  Future<WalletModel?> getWallet(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? walletJson = prefs.getString(_getWalletKey(userId));
    if (walletJson == null) {
      // Create default wallet
      final defaultWallet = WalletModel(
        userId: userId,
        balance: 0.0,
        currency: 'USD',
      );
      await saveWallet(defaultWallet);
      return defaultWallet;
    }
    try {
      final decoded = json.decode(walletJson) as Map<String, dynamic>;
      return WalletModel.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveWallet(WalletModel wallet) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(wallet.toJson());
    await prefs.setString(_getWalletKey(wallet.userId), encoded);
  }

  Future<List<WalletTransactionModel>> getTransactions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsJson = prefs.getString(_getTransactionsKey(userId));
    if (transactionsJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(transactionsJson) as List<dynamic>;
      return decoded
          .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Future<WalletTransactionModel> addTransaction(WalletTransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final List<WalletTransactionModel> existingTransactions = await getTransactions(transaction.userId);
    existingTransactions.add(transaction);
    final String encoded = json.encode(existingTransactions.map((e) => e.toJson()).toList());
    await prefs.setString(_getTransactionsKey(transaction.userId), encoded);

    // Update wallet balance
    final wallet = await getWallet(transaction.userId);
    if (wallet != null) {
      double newBalance = wallet.balance;
      if (transaction.type == WalletTransactionType.deposit || 
          transaction.type == WalletTransactionType.refund) {
        newBalance += transaction.amount;
      } else if (transaction.type == WalletTransactionType.payment ||
                 transaction.type == WalletTransactionType.withdrawal ||
                 transaction.type == WalletTransactionType.payout) {
        newBalance -= transaction.amount;
      }
      await saveWallet(wallet.copyWith(balance: newBalance));
    }

    return transaction;
  }

  Future<WalletTransactionModel> updateTransaction(WalletTransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final List<WalletTransactionModel> existingTransactions = await getTransactions(transaction.userId);
    final index = existingTransactions.indexWhere((t) => t.id == transaction.id);
    if (index == -1) throw Exception('Transaction not found');
    existingTransactions[index] = transaction;
    final String encoded = json.encode(existingTransactions.map((e) => e.toJson()).toList());
    await prefs.setString(_getTransactionsKey(transaction.userId), encoded);
    return transaction;
  }
}

