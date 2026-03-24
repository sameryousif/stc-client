import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stc_client/core/certificate/cert_info.dart';
import 'package:stc_client/utils/paths/app_paths.dart';
import 'package:stc_client/utils/paths/tools_paths.dart';
import '../../services/invoicePrepService.dart';
import '../../services/api_service.dart';
import '../../services/invoice_processing_service.dart';
import '../../core/invoice/invoice_item.dart';

class InvoiceResult {
  final bool success;
  final String message;

  InvoiceResult({required this.success, required this.message});
}

class InvoiceProvider extends ChangeNotifier {
  final InvoicePrepService prepService;

  InvoiceProvider({required this.prepService});

  bool isGenerating = false;
  bool isSendingClear = false;
  bool isSendingReport = false;
  bool isGeneratingDto = false;
  String? qrString;
  String? qrValue;
  String? signedXml;
  String? currentInvoiceNumber;
  Map<String, String>? invoiceData;
  Map<String, String>? lastDto;
  bool showJson = false;

  /// Generate and sign invoice
  Future<InvoiceResult> generateAndSign({
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required Map<String, String> supplierInfo,
    required Map<String, String> customerInfo,
  }) async {
    isGenerating = true;
    lastDto = null;
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

  /// Generate DTO from current signed XML
  Future<void> generateDtoFromXml() async {
    if (signedXml == null || signedXml!.isEmpty) return;

    isGeneratingDto = true;
    notifyListeners();

    try {
      final dto = await prepService.sendSignedInvoice(
        xmlContent: signedXml!,
        uuid: currentInvoiceNumber!,
      );
      lastDto = dto;
    } catch (e) {
      debugPrint("Error generating DTO: $e");
    } finally {
      isGeneratingDto = false;
      notifyListeners();
    }
  }

  /// Send invoice to server and process cleared invoice
  Future<InvoiceResult> clearInvoice() async {
    if (signedXml == null || signedXml!.isEmpty) {
      return InvoiceResult(success: false, message: "No invoice to send");
    }

    isSendingClear = true;
    notifyListeners();

    try {
      final dto = await prepService.sendSignedInvoice(
        xmlContent: signedXml!,
        uuid: currentInvoiceNumber!,
      );
      lastDto = dto; // store DTO for later preview

      final response = await ApiService.clearInvoiceDto(dto);
      if (response?.statusCode == 200) {
        final body = response?.data;

        if (body is! Map) {
          throw Exception('Invalid response format');
        }

        final innerData = body['data'];

        if (innerData == null || innerData is! Map) {
          throw Exception('Missing data field');
        }

        final base64Invoice = innerData['cleared_invoice'];

        if (base64Invoice == null) {
          throw Exception('cleared_invoice missing');
        }

        final base64InvoiceStr = base64Invoice.toString();

        //  qrValue = await extractQr(base64InvoiceStr);

        /* if (qrValue != null) {
          final parsedInvoice = parseQr(qrValue!);
          invoiceData = parsedInvoice;
          qrString = parsedInvoice.toString();
        }*/

        final entityId = await extractSerial(
          opensslPath: await ToolPaths.opensslPath,
          certPath: await AppPaths.certPath(),
        );

        await DBService.processClearedInvoice(
          base64InvoiceStr,
          prepService,
          entityId!,
        );

        return InvoiceResult(
          success: true,
          message: "Invoice cleared and saved successfully!",
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
      isSendingClear = false;
      notifyListeners();
    }
  }

  Future<InvoiceResult> reportInvoice() async {
    if (signedXml == null || signedXml!.isEmpty) {
      return InvoiceResult(success: false, message: "No invoice to send");
    }

    isSendingReport = true;
    notifyListeners();

    try {
      final dto = await prepService.sendSignedInvoice(
        xmlContent: signedXml!,
        uuid: currentInvoiceNumber!,
      );
      lastDto = dto; // store DTO for later preview

      final response = await ApiService.reportInvoiceDto(dto);
      if (response?.statusCode == 200 || response?.statusCode == 202) {
        final body = response?.data;

        if (body is! Map) {
          throw Exception('Invalid response format');
        }

        final invoice = body['data'];

        /* if (innerData == null || innerData is! Map) {
          throw Exception('Missing data field');
        }*/
        /*
        if (qrValue != null) {
          final parsedInvoice = parseQr(qrValue!);
          invoiceData = parsedInvoice;
          qrString = parsedInvoice.toString();
        }
*/
        final entityId = await extractSerial(
          opensslPath: await ToolPaths.opensslPath,
          certPath: await AppPaths.certPath(),
        );

        await DBService.processReportedInvoice(invoice, prepService, entityId!);

        return InvoiceResult(
          success: true,
          message: "Invoice reported and saved successfully!",
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
      isSendingReport = false;
      notifyListeners();
    }
  }

  void refreshInvoice() {
    signedXml = null;
    qrString = null;
    qrValue = null;
    invoiceData = null;
    lastDto = null;
    isGenerating = false;
    isSendingReport = false;
    isSendingClear = false;
    isCheckingQr = false;
    showJson = false;

    notifyListeners();
  }

  bool isCheckingQr = false;

  Future<InvoiceResult> checkQrValidity() async {
    if (qrValue == null || qrValue!.isEmpty) {
      return InvoiceResult(success: false, message: "No QR available");
    }

    isCheckingQr = true;
    notifyListeners();

    try {
      await ApiService.sendQr(qrbase64: qrValue!);

      return InvoiceResult(success: true, message: "QR is valid");
    } catch (e) {
      return InvoiceResult(success: false, message: "QR validation failed: $e");
    } finally {
      isCheckingQr = false;
      notifyListeners();
    }
  }
}
