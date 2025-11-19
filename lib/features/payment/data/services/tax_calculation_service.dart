import 'dart:async';
import 'dart:math';

class TaxCalculationService {
  TaxCalculationService._();
  static final TaxCalculationService instance = TaxCalculationService._();
  final _random = Random();

  /// Calculate tax based on location and amount
  /// In a real app, this would use actual tax rates from a tax service
  Future<TaxCalculationResult> calculateTax({
    required double amount,
    required String country,
    String? state,
    String? city,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock tax rates (in a real app, fetch from tax service)
    double taxRate = 0.0;
    
    // Simulate different tax rates by country/state
    if (country == 'US') {
      taxRate = state == 'CA' ? 0.0875 : 0.06; // California 8.75%, others 6%
    } else if (country == 'CA') {
      taxRate = 0.13; // Canada GST/HST
    } else if (country == 'UK') {
      taxRate = 0.20; // UK VAT
    } else {
      taxRate = 0.10; // Default 10%
    }

    final taxAmount = amount * taxRate;
    final totalAmount = amount + taxAmount;

    return TaxCalculationResult(
      subtotal: amount,
      taxRate: taxRate,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      currency: 'USD',
      breakdown: {
        'Subtotal': amount,
        'Tax (${(taxRate * 100).toStringAsFixed(2)}%)': taxAmount,
        'Total': totalAmount,
      },
    );
  }
}

@immutable
class TaxCalculationResult {
  const TaxCalculationResult({
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    required this.breakdown,
  });

  final double subtotal;
  final double taxRate; // As decimal (e.g., 0.0875 for 8.75%)
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final Map<String, double> breakdown; // Detailed breakdown
}

