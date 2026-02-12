import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:stc_client/services/api_service.dart';
import 'file_service.dart';

/// Service responsible for managing certificate enrollment and validation
class CertEnrollService {
  final FileService fileService;

  CertEnrollService({required this.fileService});

  Future<bool> isCertificateValid() async {
    return fileService.isCertificateStillValid();
  }

  Future<void> enrollCertificate({
    required File csrFile,
    required String token,
  }) async {
    if (await isCertificateValid()) {
      return;
    }

    final String certificatePem = await ApiService.sendCsr(
      csrFile: csrFile,
      token: token,
    );

    final Uint8List certBytes = pemToDer(certificatePem);
    await fileService.saveCertificate(certBytes);
  }

  Uint8List pemToDer(String pem) {
    final cleaned = pem
        .replaceAll('-----BEGIN CERTIFICATE-----', '')
        .replaceAll('-----END CERTIFICATE-----', '')
        .replaceAll(RegExp(r'\s+'), '');

    return base64Decode(cleaned);
  }
}
