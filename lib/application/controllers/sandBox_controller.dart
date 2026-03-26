import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/enrollment_controller.dart';
import 'package:stc_client/services/api_service.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';

class SandboxController {
  final EnrollmentController enrollmentController;

  final enrollResponse = ValueNotifier<String>("");
  final submitResponse = ValueNotifier<String>("");

  bool isEnrolling = false;

  SandboxController({required this.enrollmentController});

  /// ENROLL
  Future<void> enroll(String csr, String token) async {
    if (csr.isEmpty || token.isEmpty) {
      enrollResponse.value = "CSR and Token are required";
      return;
    }

    isEnrolling = true;
    enrollResponse.value = "Enrolling...";

    try {
      final csrFile = await _writeCsrToFile(csr);

      final result = await ApiService.sendCsr(
        csrFile: csrFile,
        token: token,
        sandbox: true,
      );

      // ✅ HANDLE SUCCESS RESPONSE
      if (result != null) {
        enrollResponse.value = result;
      }
    } catch (e) {
      enrollResponse.value = "❌ ENROLL FAILED\n$e";
    } finally {
      isEnrolling = false;
    }
  }

  /// CLEAR
  Future<void> clearInvoice(InvoiceProvider provider, String invoice) async {
    if (invoice.isEmpty) {
      submitResponse.value = "Invoice is empty";
      return;
    }

    try {
      provider.signedXml = invoice;
      final result = await provider.clearInvoice();
      submitResponse.value = result.message;
    } catch (e) {
      submitResponse.value = "CLEAR FAILED\n$e";
    }
  }

  /// REPORT
  Future<void> reportInvoice(InvoiceProvider provider, String invoice) async {
    if (invoice.isEmpty) {
      submitResponse.value = "Invoice is empty";
      return;
    }

    try {
      provider.signedXml = invoice;
      final result = await provider.reportInvoice();
      submitResponse.value = result.message;
    } catch (e) {
      submitResponse.value = "REPORT FAILED\n$e";
    }
  }

  Future<File> _writeCsrToFile(String csr) async {
    try {
      // Create a temporary directory for the CSR
      final tempDir = await Directory.systemTemp.createTemp('csr_');

      // Create a file inside that directory
      final file = File('${tempDir.path}/request.csr');

      // Write the CSR content into the file
      await file.writeAsString(csr);

      // Return the File object
      return file;
    } catch (e) {
      debugPrint('Error writing CSR to file: $e');
      return null!; // Return null on failure
    }
  }
}
