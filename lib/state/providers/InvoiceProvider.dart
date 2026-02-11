import 'dart:io';

import 'package:flutter/material.dart';
import '../../services/invoicePrepService.dart';
import '../../services/api_service.dart';
import '../../services/invoice_processing_service.dart';
import '../../domain/invoice/invoice_item.dart';

class InvoiceResult {
  final bool success;
  final String message;

  InvoiceResult({required this.success, required this.message});
}

class InvoiceProvider extends ChangeNotifier {
  final InvoicePrepService prepService;

  InvoiceProvider({required this.prepService});

  bool isGenerating = false;
  bool isSending = false;

  String? signedXml;
  String? currentInvoiceNumber;

  /// Generate and sign invoice
  Future<InvoiceResult> generateAndSign({
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required Map<String, String> supplierInfo,
    required Map<String, String> customerInfo,
  }) async {
    isGenerating = true;
    notifyListeners();

    try {
      currentInvoiceNumber = invoiceNumber;
      final signedPath = await prepService.generateAndSignInvoice(
        invoiceNumber: invoiceNumber,
        items: items,
        supplierInfo: supplierInfo,
        customerInfo: customerInfo,
      );

      final file = File(signedPath);
      signedXml = await file.readAsString();
      return InvoiceResult(success: true, message: "Invoice ready for preview");
    } catch (e) {
      return InvoiceResult(success: false, message: "Failed: $e");
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  /// Send invoice to server and process cleared invoice
  Future<InvoiceResult> sendInvoice() async {
    if (signedXml == null || signedXml!.isEmpty) {
      return InvoiceResult(success: false, message: "No invoice to send");
    }

    isSending = true;
    notifyListeners();

    try {
      final dto = await prepService.sendSignedInvoice(
        xmlContent: signedXml!,
        uuid: currentInvoiceNumber!,
      );

      final response = await ApiService.sendInvoiceDto(dto);

      if (response?.statusCode == 200) {
        final base64Invoice = response?.data['clearedInvoice'] as String;

        // Delegate processing to separate service
        await DBService.processClearedInvoice(base64Invoice, prepService);

        await DBService().printAllInvoices();

        return InvoiceResult(
          success: true,
          message: "Invoice sent and saved successfully!",
        );
      } else {
        return InvoiceResult(
          success: false,
          message:
              "Send failed (HTTP ${response?.statusCode}): ${response?.data}",
        );
      }
    } catch (e) {
      return InvoiceResult(success: false, message: "Send failed: $e");
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  void refreshInvoice() {
    signedXml = null;
    isGenerating = false;
    notifyListeners();
  }
}
