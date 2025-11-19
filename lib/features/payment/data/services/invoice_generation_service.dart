import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:localtrade/features/payment/data/models/invoice_model.dart';

class InvoiceGenerationService {
  InvoiceGenerationService._();
  static final InvoiceGenerationService instance = InvoiceGenerationService._();

  /// Generate PDF invoice from invoice model
  Future<String> generateInvoicePDF(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final numberFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Invoice #: ${invoice.invoiceNumber}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Issue Date: ${dateFormat.format(invoice.issueDate)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Due Date: ${dateFormat.format(invoice.dueDate)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 40),

            // Bill To / From
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill To:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(invoice.buyerName, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'From:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(invoice.sellerName, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                // Items
                ...invoice.items.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.quantity, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(numberFormat.format(item.unitPrice), style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(numberFormat.format(item.totalPrice), style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 20),

            // Totals
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.SizedBox(width: 100),
                        pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(width: 20),
                        pw.Text(numberFormat.format(invoice.subtotal), style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    if (invoice.discountAmount != null && invoice.discountAmount! > 0) ...[
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.SizedBox(width: 100),
                          pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(width: 20),
                          pw.Text(numberFormat.format(-invoice.discountAmount!), style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                    if (invoice.shippingAmount != null && invoice.shippingAmount! > 0) ...[
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.SizedBox(width: 100),
                          pw.Text('Shipping:', style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(width: 20),
                          pw.Text(numberFormat.format(invoice.shippingAmount!), style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.SizedBox(width: 100),
                        pw.Text('Tax:', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(width: 20),
                        pw.Text(numberFormat.format(invoice.taxAmount), style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.SizedBox(width: 100),
                        pw.Text(
                          'Total:',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Text(
                          numberFormat.format(invoice.totalAmount),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Text(
                'Notes:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                invoice.notes!,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  Future<void> shareInvoice(String filePath) async {
    final file = XFile(filePath);
    await Share.shareXFiles([file], text: 'Invoice');
  }
}

