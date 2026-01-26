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
      // ✅ 1️⃣ Generate, sign, canonicalize, and submit invoice in one go
      final dto = await manager.generateSignAndSubmitInvoice(
        invoiceNumber: invoiceNumber,
        items: items,
        supplierInfo: supplierInfo,
        customerInfo: customerInfo,
      );

      lastInvoiceId = invoiceNumber;
      debugPrint('Invoice submitted successfully!');
      debugPrint('Submission DTO: $dto');
    } catch (e, s) {
      debugPrint('Invoice error: $e');
      debugPrint('$s');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
