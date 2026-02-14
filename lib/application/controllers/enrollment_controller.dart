import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stc_client/core/enrollment_result.dart';
import 'package:stc_client/core/enrollment_subject.dart';
import 'package:stc_client/services/certificateEnrollService.dart';
import 'package:stc_client/services/enrollment_service.dart';

/// Controller responsible for managing the enrollment process, including generating the CSR, enrolling for the certificate, and loading initial data such as the existing certificate, private key, and CSR if they exist, while also providing ValueNotifiers to update the UI with the current state of the enrollment data
class EnrollmentController {
  final EnrollmentService enrollmentService;
  final CertEnrollService certEnrollService;

  final ValueNotifier<String> privateKey = ValueNotifier('');
  final ValueNotifier<String> csr = ValueNotifier('');
  final ValueNotifier<String> certificate = ValueNotifier('');

  EnrollmentController(this.enrollmentService, this.certEnrollService);

  /// Generate private key + CSR
  Future<EnrollmentResult> generateCsr(EnrollmentSubject subject) async {
    final csrBase64 = await enrollmentService.generateCsr(subject);
    final privateKey = await enrollmentService.loadPrivateKey();

    return EnrollmentResult(csrBase64: csrBase64, privateKey: privateKey);
  }

  /// Enroll certificate using existing CSR
  Future<void> enrollCertificate(String token) async {
    final csrFile = await enrollmentService.getCsrFile();
    if (csrFile == null) return;

    await certEnrollService.enrollCertificate(csrFile: csrFile, token: token);

    final cert = await enrollmentService.loadCertificate();
    certificate.value = cert ?? '';
  }

  Future<void> loadInitialData() async {
    try {
      final cert = await enrollmentService.loadCertificate();
      final key = await enrollmentService.loadPrivateKey();
      final csrFile = await enrollmentService.getCsrFile();

      String csrBase64 = '';

      if (csrFile != null) {
        final csrBytes = await csrFile.readAsBytes();
        csrBase64 = base64Encode(csrBytes);
      }

      certificate.value = cert ?? '';
      privateKey.value = key;
      csr.value = csrBase64;
    } catch (e) {
      certificate.value = '';
      privateKey.value = '';
      csr.value = '';
    }
  }
}
