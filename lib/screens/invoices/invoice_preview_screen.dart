
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../services/invoice_service.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final String invoiceId;
  final String invoiceNumber;

  const InvoicePreviewScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
  });

  static const Color _background = Color(0xFF090B10);
  static const Color _accent = Color(0xFF00D68F);

  @override
  Widget build(BuildContext context) {
    final invoiceService = InvoiceService();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF151922),
        title: const Text(
          'Invoice Preview',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: PdfPreview(
        build: (format) {
          return invoiceService.buildInvoicePdf(
            invoiceId,
            pageFormat: format,
          );
        },
        pdfFileName: '$invoiceNumber.pdf',
        canChangePageFormat: false,
        canChangeOrientation: false,
        allowPrinting: true,
        allowSharing: true,
        useActions: true,
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: _accent),
        ),
        pdfPreviewPageDecoration: const BoxDecoration(
          color: Colors.white,
        ),
        actionBarTheme: const PdfActionBarTheme(
          backgroundColor: Color(0xFF151922),
          iconColor: _accent,
          textStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
