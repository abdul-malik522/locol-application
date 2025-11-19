import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';

class OrderExportService {
  OrderExportService._();
  static final OrderExportService instance = OrderExportService._();

  /// Export orders to CSV file
  Future<String> exportToCSV(List<OrderModel> orders) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final buffer = StringBuffer();

    // Write CSV header
    buffer.writeln(
      'Order Number,Product Name,Quantity,Price,Total Amount,Status,Buyer,Seller,Delivery Address,Created Date,Updated Date,Rating,Review',
    );

    // Write order data
    for (final order in orders) {
      final review = (order.review ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
      buffer.writeln(
        '"${order.orderNumber}",'
        '"${order.productName}",'
        '"${order.quantity}",'
        '${order.price.toStringAsFixed(2)},'
        '${order.totalAmount.toStringAsFixed(2)},'
        '"${order.status.label}",'
        '"${order.buyerName}",'
        '"${order.sellerName}",'
        '"${order.deliveryAddress}",'
        '"${dateFormat.format(order.createdAt)}",'
        '"${dateFormat.format(order.updatedAt)}",'
        '${order.rating?.toStringAsFixed(1) ?? ""},'
        '"$review"',
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/orders_export_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  /// Export orders to PDF file
  Future<String> exportToPDF(List<OrderModel> orders) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final numberFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Order History Export',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${dateFormat.format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary
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
                      pw.Text('Total Orders: ${orders.length}'),
                      pw.Text(
                        'Total Amount: ${numberFormat.format(orders.fold<double>(0, (sum, order) => sum + order.totalAmount))}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Orders List
            ...orders.map((order) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          order.orderNumber,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
                            color: _getStatusColor(order.status),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(3),
                            ),
                          ),
                          child: pw.Text(
                            order.status.label,
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      order.productName,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Quantity: ${order.quantity}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Price: ${numberFormat.format(order.price)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Total: ${numberFormat.format(order.totalAmount)}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Buyer: ${order.buyerName} | Seller: ${order.sellerName}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Address: ${order.deliveryAddress}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Created: ${dateFormat.format(order.createdAt)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    if (order.rating != null) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Rating: ${order.rating!.toStringAsFixed(1)}/5.0',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (order.review != null && order.review!.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Review: ${order.review}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/orders_export_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Share exported file
  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Order History Export',
    );
  }

  /// Get status color for PDF
  PdfColor _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return PdfColors.orange;
      case OrderStatus.accepted:
        return PdfColors.blue;
      case OrderStatus.completed:
        return PdfColors.green;
      case OrderStatus.cancelled:
        return PdfColors.red;
    }
  }
}

