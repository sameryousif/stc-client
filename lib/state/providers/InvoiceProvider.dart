import 'dart:convert';
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

  bool isGeneratingB2B = false;
  bool isGeneratingB2C = false;
  bool isSendingClear = false;
  bool isSendingReport = false;
  bool isGeneratingDto = false;
  String? qrString;
  String? qrValue;
  String? signedXml;
  String? currentInvoiceNumber;
  Map<String, String>? invoiceData;
  Map<String, dynamic>? lastDto;
  bool showJson = false;
  bool isSandBox = false;
  String? sandboxJson;

  /// Generate and sign invoice
  Future<InvoiceResult> generateAndSign({
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required Map<String, String> supplierInfo,
    required Map<String, String> customerInfo,
    required bool clearance,
  }) async {
    if (clearance) {
      isGeneratingB2B = true;
    } else {
      isGeneratingB2C = true;
    }

    lastDto = null;
    notifyListeners();

    try {
      currentInvoiceNumber = invoiceNumber;

      final signedPath = await prepService.generateAndSignInvoice(
        invoiceNumber: invoiceNumber,
        items: items,
        supplierInfo: supplierInfo,
        customerInfo: customerInfo,
        clearance: clearance,
      );

      final file = File(signedPath);
      signedXml = await file.readAsString();

      return InvoiceResult(success: true, message: "Invoice ready for preview");
    } catch (e) {
      return InvoiceResult(success: false, message: "Failed: $e");
    } finally {
      if (clearance) {
        isGeneratingB2B = false;
      } else {
        isGeneratingB2C = false;
      }

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
  Future<InvoiceResult> clearInvoice({required bool isSandBox}) async {
    isSendingClear = true;
    notifyListeners();

    try {
      Map<String, dynamic> dto;

      if (isSandBox) {
        if (sandboxJson == null || sandboxJson!.isEmpty) {
          return InvoiceResult(success: false, message: "No JSON provided");
        }

        try {
          dto = jsonDecode(sandboxJson!);
        } catch (e) {
          return InvoiceResult(success: false, message: "Invalid JSON format");
        }

        lastDto = dto;
      } else {
        if (signedXml == null || signedXml!.isEmpty) {
          return InvoiceResult(success: false, message: "No invoice to send");
        }

        if (currentInvoiceNumber == null) {
          return InvoiceResult(
            success: false,
            message: "Missing invoice number",
          );
        }

        dto = await prepService.sendSignedInvoice(
          xmlContent: signedXml!,
          uuid: currentInvoiceNumber!,
        );

        lastDto = dto;
      }

      final response = await ApiService.sendClear(dto, isSandbox: isSandBox);

      //  SANDBOX → just return response
      if (isSandBox) {
        return InvoiceResult(
          success: true,
          message:
              "Response code: ${response?.statusCode}\nBody:\n${const JsonEncoder.withIndent('  ').convert(response?.data)}",
        );
      }

      if (response?.statusCode == 200) {
        final body = response?.data;

        final innerData = body['data'];
        final base64Invoice = innerData['cleared_invoice'];

        final entityId = await extractSerial(
          opensslPath: await ToolPaths.opensslPath,
          certPath: await AppPaths.certPath(),
        );

        if (entityId == null) {
          return InvoiceResult(
            success: false,
            message: "Failed to extract entity ID",
          );
        }

        await InvoiceProcessingService.processClearedInvoice(
          base64Invoice,
          prepService,
          entityId,
        );

        return InvoiceResult(
          success: true,
          message:
              "STATUS CODE:${response?.statusCode}\nBODY:${response?.data}",
        );
      } else {
        return InvoiceResult(
          success: false,
          message: "HTTP ${response?.statusCode}\n${response?.data}",
        );
      }
    } catch (e) {
      return InvoiceResult(success: false, message: "Send failed: $e");
    } finally {
      isSendingClear = false;
      notifyListeners();
    }
  }

  ///report invoice
  Future<InvoiceResult> reportInvoice({required bool isSandBox}) async {
    isSendingReport = true;
    notifyListeners();

    try {
      Map<String, dynamic> dto;

      if (isSandBox) {
        // Sandbox: use user-provided JSON
        if (sandboxJson == null || sandboxJson!.isEmpty) {
          return InvoiceResult(success: false, message: "No JSON provided");
        }

        try {
          dto = jsonDecode(sandboxJson!);
        } catch (e) {
          return InvoiceResult(success: false, message: "Invalid JSON format");
        }

        lastDto = dto;
      } else {
        // Production: generate DTO from signed XML
        if (signedXml == null || signedXml!.isEmpty) {
          return InvoiceResult(success: false, message: "No invoice to send");
        }

        if (currentInvoiceNumber == null) {
          return InvoiceResult(
            success: false,
            message: "Missing invoice number",
          );
        }

        dto = await prepService.sendSignedInvoice(
          xmlContent: signedXml!,
          uuid: currentInvoiceNumber!,
        );

        lastDto = dto; // store DTO for preview
      }

      // Send report request
      final response = await ApiService.sendReport(dto, isSandbox: isSandBox);

      // SANDBOX: skip processing, just return response
      if (isSandBox) {
        return InvoiceResult(
          success: true,
          message:
              "Response code: ${response?.statusCode}\nBody:\n${const JsonEncoder.withIndent('  ').convert(response?.data)}",
        );
      }

      // PRODUCTION: process reported invoice if response is OK
      if (response?.statusCode == 200) {
        final invoiceString = signedXml!;
        final invoiceBase64 = base64.encode(utf8.encode(invoiceString));

        final entityId = await extractSerial(
          opensslPath: await ToolPaths.opensslPath,
          certPath: await AppPaths.certPath(),
        );

        if (entityId == null) {
          return InvoiceResult(
            success: false,
            message: "Failed to extract entity ID",
          );
        }

        await InvoiceProcessingService.processReportedInvoice(
          invoiceBase64,
          prepService,
          entityId,
        );

        return InvoiceResult(
          success: true,
          message:
              "Response code: ${response?.statusCode}\nBody:\n${const JsonEncoder.withIndent('  ').convert(response?.data)}",
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
    isGeneratingB2B = false;
    isGeneratingB2C = false;
    isSendingReport = false;
    isSendingClear = false;
    isCheckingQr = false;
    showJson = false;

    notifyListeners();
  }

  bool isCheckingQr = false;

  /* Future<InvoiceResult> checkQrValidity() async {
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
  }*/
}
