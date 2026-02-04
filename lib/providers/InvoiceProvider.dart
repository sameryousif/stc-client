import 'dart:io';
import 'package:flutter/material.dart';

import '../managers/invoice_manager.dart';
import '../models/invoice_item.dart';
import '../services/api_service.dart';

class InvoiceResult {
  final bool success;
  final String message;

  InvoiceResult({required this.success, required this.message});
}

class InvoiceProvider extends ChangeNotifier {
  final InvoiceManager manager;

  InvoiceProvider({required this.manager});

  bool isGenerating = false;
  bool isSending = false;

  String? signedXml;

  String? qrBase64;
  Map<String, String>? decodedQrFields;
  String? currentInvoiceNumber;

  /// generate and sign invoice
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
      final signedPath = await manager.generateAndSignInvoice(
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

  // Send Invoice to Server API
  Future<InvoiceResult> sendInvoice() async {
    if (signedXml == null || signedXml!.isEmpty) {
      return InvoiceResult(success: false, message: "No invoice to send");
    }

    isSending = true;
    notifyListeners();

    try {
      final dto = await manager.sendSignedInvoice(
        xmlContent: signedXml!,
        uuid: currentInvoiceNumber!,
      );
      final response = await ApiService.sendToServerDto(dto);

      if (response?.statusCode == 200) {
        return InvoiceResult(
          success: true,
          message: "Invoice sent successfully!",
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
    qrBase64 = null;
    decodedQrFields = null;
    isGenerating = false;
    notifyListeners();
  }
}
