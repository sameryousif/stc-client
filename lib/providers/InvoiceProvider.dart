import 'package:flutter/material.dart';
import 'package:stc_client/utils/constants.dart';
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
      final xml = await manager.generateInvoiceXml(
        invoiceNumber: invoiceNumber,
        items: items,
        supplierInfo: supplierInfo,
        customerInfo: customerInfo,
      );

      final xmlPath = await manager.saveInvoiceXml(xml, invoiceNumber);
      final signaturePath = await manager.signInvoice(xmlPath);
      final dto = await manager.prepareInvoiceSubmission(
        xmlPath: xmlPath,
        signaturePath: signaturePath,
        certificatePath: Constants.certPath,
      );

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
