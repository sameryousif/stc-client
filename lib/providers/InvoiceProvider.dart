import 'package:flutter/material.dart';
import 'package:stc_client/services/api_service.dart';
import '../managers/invoice_manager.dart';
import '../models/invoice_item.dart';

class InvoiceResult {
  final bool success;
  final String message;

  InvoiceResult({required this.success, required this.message});
}

class InvoiceProvider extends ChangeNotifier {
  final InvoiceManager manager;

  bool isLoading = false;
  String? lastInvoiceId;

  InvoiceProvider({required this.manager});

  /// Generates, signs, canonicalizes, and sends the invoice
  /// Returns InvoiceResult for UI
  Future<InvoiceResult> generateAndSendInvoice({
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required Map<String, String> supplierInfo,
    required Map<String, String> customerInfo,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      // Generate, sign, canonicalize, submit invoice
      final submissionDto = await manager.generateSignAndSubmitInvoice(
        invoiceNumber: invoiceNumber,
        items: items,
        supplierInfo: supplierInfo,
        customerInfo: customerInfo,
      );

      // Send to server
      final response = await ApiService.sendToServerDto(submissionDto);

      if (response == null) {
        return InvoiceResult(
          success: false,
          message: "No response from server",
        );
      }

      // Check HTTP status code
      if (response.statusCode == 200) {
        lastInvoiceId = invoiceNumber;
        return InvoiceResult(
          success: true,
          message: "Invoice $invoiceNumber submitted successfully!",
        );
      } else {
        // Handle 4xx / 5xx errors
        return InvoiceResult(
          success: false,
          message:
              "Invoice submission failed (HTTP ${response.statusCode}): ${response.data}",
        );
      }
    } catch (e, s) {
      debugPrint('Invoice error: $e');
      debugPrint('$s');
      return InvoiceResult(
        success: false,
        message: "Invoice submission failed: $e",
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
