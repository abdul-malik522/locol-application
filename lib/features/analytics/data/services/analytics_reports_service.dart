import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/analytics/data/models/analytics_model.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';

class AnalyticsReportsService {
  AnalyticsReportsService._();
  static final AnalyticsReportsService instance = AnalyticsReportsService._();

  /// Export sales report to PDF
  Future<String> exportSalesReportToPDF({
    required SellerAnalytics analytics,
    required List<OrderModel> orders,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final numberFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateRange = startDate != null && endDate != null
        ? '${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}'
        : 'All Time';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Sales Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Period: $dateRange',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Orders: ${analytics.orderAnalytics.totalOrders}'),
                      pw.Text('Total Revenue: ${numberFormat.format(analytics.orderAnalytics.totalRevenue)}'),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Average Order Value: ${numberFormat.format(analytics.orderAnalytics.averageOrderValue)}'),
                      pw.Text('Completion Rate: ${analytics.orderAnalytics.completionRate.toStringAsFixed(1)}%'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Order Breakdown
            pw.Text(
              'Order Status Breakdown',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Count', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                _buildTableRow('Pending', analytics.orderAnalytics.pendingOrders.toString()),
                _buildTableRow('Accepted', analytics.orderAnalytics.acceptedOrders.toString()),
                _buildTableRow('Completed', analytics.orderAnalytics.completedOrders.toString()),
                _buildTableRow('Cancelled', analytics.orderAnalytics.cancelledOrders.toString()),
              ],
            ),
            pw.SizedBox(height: 20),

            // Customer Analytics
            pw.Text(
              'Customer Analytics',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Customers: ${analytics.customerAnalytics.totalCustomers}'),
                  pw.Text('New Customers: ${analytics.customerAnalytics.newCustomers}'),
                  pw.Text('Returning Customers: ${analytics.customerAnalytics.returningCustomers}'),
                  pw.Text('Customer Retention Rate: ${analytics.customerAnalytics.customerRetentionRate.toStringAsFixed(1)}%'),
                  pw.Text('Average Customer Lifetime Value: ${numberFormat.format(analytics.customerAnalytics.averageCustomerLifetimeValue)}'),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/sales_report_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Export sales report to CSV
  Future<String> exportSalesReportToCSV({
    required List<OrderModel> orders,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final buffer = StringBuffer();

    // Write CSV header
    buffer.writeln(
      'Order Number,Product Name,Quantity,Price,Total Amount,Status,Buyer Name,Created Date,Completed Date,Rating',
    );

    // Filter by date range if provided
    var filteredOrders = orders;
    if (startDate != null) {
      filteredOrders = filteredOrders.where((o) => o.createdAt.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      filteredOrders = filteredOrders.where((o) => o.createdAt.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }

    // Write order data
    for (final order in filteredOrders) {
      buffer.writeln(
        '"${order.orderNumber}",'
        '"${order.productName}",'
        '"${order.quantity}",'
        '${order.price.toStringAsFixed(2)},'
        '${order.totalAmount.toStringAsFixed(2)},'
        '"${order.status.label}",'
        '"${order.buyerName}",'
        '"${dateFormat.format(order.createdAt)}",'
        '"${order.status.name == 'completed' ? (order.updatedAt != null ? dateFormat.format(order.updatedAt) : '') : ''}",'
        '${order.rating?.toStringAsFixed(1) ?? ""}',
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/sales_report_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  /// Export customer report to PDF
  Future<String> exportCustomerReportToPDF({
    required CustomerAnalytics analytics,
    required List<OrderModel> orders,
  }) async {
    final pdf = pw.Document();
    final numberFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Customer Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Customer Statistics',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Total Customers: ${analytics.totalCustomers}'),
                  pw.Text('New Customers: ${analytics.newCustomers}'),
                  pw.Text('Returning Customers: ${analytics.returningCustomers}'),
                  pw.Text('Customer Retention Rate: ${analytics.customerRetentionRate.toStringAsFixed(1)}%'),
                  pw.Text('Average Customer Lifetime Value: ${numberFormat.format(analytics.averageCustomerLifetimeValue)}'),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/customer_report_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }
}

