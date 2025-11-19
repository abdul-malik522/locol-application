import 'dart:async';

import 'package:localtrade/features/payment/data/models/invoice_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class InvoicesDataSource {
  InvoicesDataSource._();
  static final InvoicesDataSource instance = InvoicesDataSource._();
  final _uuid = const Uuid();

  static const String _invoicesKey = 'invoices';
  int _invoiceCounter = 1;

  Future<List<InvoiceModel>> getAllInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? invoicesJson = prefs.getString(_invoicesKey);
    if (invoicesJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(invoicesJson) as List<dynamic>;
      return decoded
          .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Future<List<InvoiceModel>> getInvoicesByUser(String userId, {bool? asBuyer}) async {
    final allInvoices = await getAllInvoices();
    if (asBuyer == true) {
      return allInvoices.where((i) => i.buyerId == userId).toList();
    } else if (asBuyer == false) {
      return allInvoices.where((i) => i.sellerId == userId).toList();
    }
    return allInvoices.where((i) => i.buyerId == userId || i.sellerId == userId).toList();
  }

  Future<InvoiceModel?> getInvoiceByOrderId(String orderId) async {
    final allInvoices = await getAllInvoices();
    try {
      return allInvoices.firstWhere((i) => i.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<InvoiceModel?> getInvoiceById(String invoiceId) async {
    final allInvoices = await getAllInvoices();
    try {
      return allInvoices.firstWhere((i) => i.id == invoiceId);
    } catch (_) {
      return null;
    }
  }

  Future<String> generateInvoiceNumber() async {
    final year = DateTime.now().year;
    final number = _invoiceCounter++;
    return 'INV-$year-${number.toString().padLeft(6, '0')}';
  }

  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    final prefs = await SharedPreferences.getInstance();
    final List<InvoiceModel> existingInvoices = await getAllInvoices();
    
    // Generate invoice number if not provided
    final invoiceNumber = invoice.invoiceNumber.isEmpty 
        ? await generateInvoiceNumber()
        : invoice.invoiceNumber;
    
    final newInvoice = invoice.copyWith(invoiceNumber: invoiceNumber);
    existingInvoices.add(newInvoice);
    final String encoded = json.encode(existingInvoices.map((e) => e.toJson()).toList());
    await prefs.setString(_invoicesKey, encoded);
    return newInvoice;
  }

  Future<InvoiceModel> updateInvoice(InvoiceModel invoice) async {
    final prefs = await SharedPreferences.getInstance();
    final List<InvoiceModel> existingInvoices = await getAllInvoices();
    final index = existingInvoices.indexWhere((i) => i.id == invoice.id);
    if (index == -1) throw Exception('Invoice not found');
    existingInvoices[index] = invoice;
    final String encoded = json.encode(existingInvoices.map((e) => e.toJson()).toList());
    await prefs.setString(_invoicesKey, encoded);
    return invoice;
  }
}

