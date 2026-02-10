import 'dart:convert';
import 'dart:typed_data';

import 'package:stc_client/services/api_service.dart';
import '../services/file_service.dart';
import '../services/crypto_service.dart';
import 'dart:io';

class CertificateManager {
  final FileService fileService;

  final CryptoService cryptoService;

  CertificateManager({required this.fileService, required this.cryptoService});

  /// Checks certificate validity
  Future<bool> isCertificateValid() async {
    return fileService.isCertificateStillValid();
  }

  /// Main enrollment logic
  Future<void> enrollCertificate(String tokenCtrl) async {
    //  Check certificate first
    if (await isCertificateValid()) {
      print(' Existing certificate still valid. No need to re-enroll.');
      return;
    }

    //  Get CSR file
    final File? csrFile = await cryptoService.getCsrFile();

    if (csrFile == null) {
      throw Exception('CSR file could not be generated.');
    }

    //  Send CSR to server and get new certificate
    final String certificateContent = await ApiService.sendCsr(
      csrFile: csrFile,
      token: tokenCtrl,
    );

    //  Save the certificate as PEM
    final Uint8List certBytes = pemToDer(certificateContent);
    await fileService.saveCertificate(certBytes);
    print(' New certificate saved successfully.');
  }

  Uint8List pemToDer(String pem) {
    final cleaned = pem
        .replaceAll('-----BEGIN CERTIFICATE-----', '')
        .replaceAll('-----END CERTIFICATE-----', '')
        .replaceAll(RegExp(r'\s+'), '');

    return base64Decode(cleaned);
  }
}
