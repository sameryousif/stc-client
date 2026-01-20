import 'package:flutter/material.dart';
import '../managers/invoice_manager.dart';
import '../models/invoice_item.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceManager manager;

  bool isLoading = false;
  String? lastInvoiceId;

  InvoiceProvider({required this.manager});

  Future<void> generateAndSendInvoice({
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required Map<String, String> supplierInfo,
    required Map<String, String> customerInfo,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      // Use the new unified flow that generates, signs, and saves invoice
      final finalXmlPath = await manager.generateAndSignInvoice(
        invoiceNumber: invoiceNumber,
        items: items,
        supplierInfo: supplierInfo,
        customerInfo: customerInfo,
      );

      // The signature path for submission (OpenSSL output)

      // Prepare DTO
      final dto = await manager.prepareInvoiceSubmission(xmlPath: finalXmlPath);

      // Send to server
      final response = await manager.sendInvoice(dto);
      lastInvoiceId = invoiceNumber;

      print('Server response: $response');
    } catch (e) {
      print('Error generating/sending invoice: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
