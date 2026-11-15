
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
class InvoiceService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch the invoice belonging to a particular order.
  // Returns null if the order has not been confirmed yet.
  Future<Map<String, dynamic>?> getInvoiceForOrder(
    String orderId,
  ) async {
    final response = await _client
        .from('invoices')
        .select('*, invoice_items(*)')
        .eq('order_id', orderId)
        .maybeSingle();

    if (response == null) return null;

    return Map<String, dynamic>.from(response);
  }

  // Fetch a saved invoice using its invoice ID.
  Future<Map<String, dynamic>> getInvoiceDetails(
    String invoiceId,
  ) async {
    final response = await _client
        .from('invoices')
        .select('*, invoice_items(*)')
        .eq('id', invoiceId)
        .single();

    return Map<String, dynamic>.from(response);
  }

  double _amount(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return 'INR ${_amount(value).toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) return 'Date unavailable';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  // Generate the PDF from the saved invoice record.
  Future<Uint8List> buildInvoicePdf(
    String invoiceId, {
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final invoice = await getInvoiceDetails(invoiceId);

    final items = List<Map<String, dynamic>>.from(
      invoice['invoice_items'] ?? [],
    );

    final pdf = pw.Document();

    final invoiceStatus =
        (invoice['status'] ?? 'issued').toString().toUpperCase();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SYNCORA',
                      style: pw.TextStyle(
                        fontSize: 27,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Smart Inventory & Order Management',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 23,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      invoice['invoice_number']?.toString() ?? '',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Date: ${_formatDate(invoice['invoice_date'])}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 22),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 15),

            pw.Text(
              'BILL TO',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Text(
              invoice['customer_name']?.toString() ?? 'Customer',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            if ((invoice['customer_email'] ?? '').toString().isNotEmpty)
              pw.Text(
                invoice['customer_email'].toString(),
                style: const pw.TextStyle(fontSize: 10),
              ),

            if ((invoice['customer_phone'] ?? '').toString().isNotEmpty)
              pw.Text(
                invoice['customer_phone'].toString(),
                style: const pw.TextStyle(fontSize: 10),
              ),

            if ((invoice['customer_address'] ?? '').toString().isNotEmpty)
              pw.Text(
                invoice['customer_address'].toString(),
                style: const pw.TextStyle(fontSize: 10),
              ),

            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Order: ${invoice['order_id']}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Status: $invoiceStatus',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: invoiceStatus == 'CANCELLED'
                          ? PdfColors.red
                          : PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.5),
                1: const pw.FlexColumnWidth(1.3),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.7),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    _tableCell('Product', bold: true),
                    _tableCell('Qty', bold: true),
                    _tableCell('Unit Price', bold: true),
                    _tableCell('Total', bold: true),
                  ],
                ),

                ...items.map((item) {
                  return pw.TableRow(
                    children: [
                      _tableCell(
                        item['product_name']?.toString() ?? 'Product',
                      ),
                      _tableCell(item['quantity']?.toString() ?? '0'),
                      _tableCell(_money(item['unit_price'])),
                      _tableCell(_money(item['line_total'])),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal', invoice['subtotal']),
                    _totalRow('Tax', invoice['tax_amount']),
                    pw.Divider(color: PdfColors.grey500),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Grand Total',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _money(invoice['total']),
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            pw.SizedBox(height: 35),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 10),

            pw.Center(
              child: pw.Text(
                'Thank you for choosing SYNCORA.',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 6),

            pw.Center(
              child: pw.Text(
                'This invoice is not a payment receipt. '
                'Payment status is not recorded by SYNCORA.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _tableCell(
    String value, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            _money(value),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
